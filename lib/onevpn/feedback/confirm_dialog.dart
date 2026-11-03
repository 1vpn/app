// The confirm dialog for fork screens, and the reconnect confirm built on it.

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations.dart';
import 'package:onexray/onevpn/theme/button.dart';
import 'package:onexray/onevpn/theme/card.dart';
import 'package:onexray/pages/theme/color.dart';
import 'package:onexray/pages/theme/font.dart';

/// Shows a centered confirm dialog. Resolves true when the user confirms.
///
/// Cancel, a barrier tap, Esc, and back all resolve false. [detail] sits
/// between [body] and the buttons. The dialog takes the same shape in every
/// orientation and on every platform.
Future<bool> showOneVpnConfirmDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  required String cancelLabel,
  String? body,
  Widget? detail,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => OneVpnConfirmDialog(
        title: title,
        body: body,
        detail: detail,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
      ),
    ) ??
    false;

/// Asks before a settings change reconnects the tunnel. [label] names what
/// the tunnel will use after the change.
Future<bool> showOneVpnReconnectDialog(
  BuildContext context, {
  required String label,
}) {
  final l = OneVpnLocalizations.of(context)!;
  final palette = ColorManager.palette(context);
  return showOneVpnConfirmDialog(
    context,
    title: l.onevpnApplyChange,
    body: l.onevpnReconnectNotice,
    detail: Container(
      decoration: BoxDecoration(
        color: palette.muted,
        borderRadius: BorderRadius.circular(OneVpnCard.radius),
        border: Border.all(color: palette.border, width: OneVpnCard.outline),
      ),
      padding: OneVpnCard.padding,
      child: Row(
        children: [
          Icon(LucideIcons.refreshCw, color: palette.mutedForeground),
          const SizedBox(width: OneVpnCard.leadingGap),
          Expanded(
            child: Text(
              l.onevpnWillUseName(label),
              style: AppTypography.settingsRow,
            ),
          ),
        ],
      ),
    ),
    confirmLabel: l.onevpnApplyAndReconnect,
    cancelLabel: l.onevpnCancel,
  );
}

/// The confirm dialog's surface: a title, an optional body and detail, and
/// the confirm button over the cancel button. It pops true or false.
class OneVpnConfirmDialog extends StatelessWidget {
  const OneVpnConfirmDialog({
    super.key,
    required this.title,
    required this.confirmLabel,
    required this.cancelLabel,
    this.body,
    this.detail,
  });

  /// The widest the dialog grows.
  static const double maxWidth = 420;

  final String title;
  final String? body;
  final Widget? detail;
  final String confirmLabel;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    final palette = ColorManager.palette(context);
    final body = this.body;
    final detail = this.detail;
    return Dialog(
      backgroundColor: palette.card,
      insetPadding: const EdgeInsets.all(OneVpnCard.margin),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(OneVpnCard.headlineRadius),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth),
        // The dialog names its route for screen readers.
        child: Semantics(
          scopesRoute: true,
          namesRoute: true,
          explicitChildNodes: true,
          label: title,
          child: SingleChildScrollView(
            padding: OneVpnCard.headlinePadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: AppTypography.panelTitle.copyWith(fontSize: 18),
                ),
                if (body != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    body,
                    style: AppTypography.settingsValueLabel.copyWith(
                      color: palette.mutedForeground,
                    ),
                  ),
                ],
                if (detail != null) ...[const SizedBox(height: 16), detail],
                const SizedBox(height: OneVpnCard.margin),
                FilledButton(
                  style: OneVpnButton.style,
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(confirmLabel),
                ),
                const SizedBox(height: OneVpnButton.stackGap),
                OutlinedButton(
                  style: OneVpnButton.style,
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(cancelLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
