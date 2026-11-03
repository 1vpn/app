// The inline email capture on the Get Premium step.
//
// The email is the join key. The backend links a purchase to an account by
// the address the store's initial-purchase event carries. A buyer with no
// account hands one over before the store sheet opens.
//
// The address collected here is the one the sign-up step is locked to. A
// mismatch breaks the link. The funnel never asks twice.
//
// Returns the address, or null when the user backed out.

import 'package:material_ui/material_ui.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations.dart';
import 'package:onexray/onevpn/theme/button.dart';
import 'package:onexray/onevpn/theme/card.dart';
import 'package:onexray/onevpn/theme/field.dart';
import 'package:onexray/pages/theme/color.dart';
import 'package:onexray/pages/theme/font.dart';

/// Matches the auth screen's check: a local part, an @, and a dotted
/// domain. It is permissive: the server is the authority.
final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Asks the buyer for the address their purchase will be linked to.
Future<String?> showOneVpnPurchaseEmailPrompt(
  BuildContext context, {
  String initial = '',
}) => showModalBottomSheet<String>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => _OneVpnPurchaseEmailSheet(initial: initial),
);

class _OneVpnPurchaseEmailSheet extends StatefulWidget {
  const _OneVpnPurchaseEmailSheet({required this.initial});

  final String initial;

  @override
  State<_OneVpnPurchaseEmailSheet> createState() =>
      _OneVpnPurchaseEmailSheetState();
}

class _OneVpnPurchaseEmailSheetState extends State<_OneVpnPurchaseEmailSheet> {
  late final TextEditingController _email = TextEditingController(
    text: widget.initial,
  );
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    final l = OneVpnLocalizations.of(context)!;
    final email = _email.text.trim();
    if (!_emailPattern.hasMatch(email)) {
      setState(() => _error = l.onevpnAuthInvalidEmail);
      return;
    }
    Navigator.pop(context, email);
  }

  @override
  Widget build(BuildContext context) {
    final l = OneVpnLocalizations.of(context)!;
    final palette = ColorManager.palette(context);
    return SafeArea(
      child: SingleChildScrollView(
        // The padding keeps the field and its button above the keyboard.
        // The scroll view fits a short viewport without overflow.
        padding: EdgeInsets.fromLTRB(
          OneVpnCard.margin,
          4,
          OneVpnCard.margin,
          OneVpnCard.margin + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _email,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              style: OneVpnField.text,
              decoration: OneVpnField.decoration(
                palette,
                l.onevpnAuthEmailLabel,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 20),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: AppTypography.settingsSelect.copyWith(
                  color: palette.destructive,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Material(
              color: palette.primarySolid,
              borderRadius: BorderRadius.circular(OneVpnButton.radius),
              child: InkWell(
                borderRadius: BorderRadius.circular(OneVpnButton.radius),
                overlayColor: OneVpnButton.solidOverlay(context),
                onTap: _submit,
                child: Container(
                  height: OneVpnButton.height,
                  alignment: Alignment.center,
                  child: Text(
                    l.onevpnContinue,
                    style: AppTypography.settingsRow.copyWith(
                      color: palette.primaryForeground,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
