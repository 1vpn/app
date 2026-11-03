import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations.dart';
import 'package:onexray/onevpn/l10n/locale_choice.dart';
import 'package:onexray/onevpn/l10n/locales.dart';
import 'package:onexray/onevpn/shell/close_app_bar.dart';
import 'package:onexray/onevpn/shell/layout.dart';
import 'package:onexray/onevpn/theme/card.dart';
import 'package:onexray/pages/theme/color.dart';
import 'package:onexray/pages/theme/font.dart';

/// The app language picker, a full page pushed from the menu.
///
/// One outlined row per choice: System Default, then each locale in
/// [kOneVpnLocales] under its native name, sorted by language tag. The stored
/// choice reads as selected. A tap on another row stores it in the
/// [OneVpnLocaleChoice] above the app. The app then renders in that language
/// and the page stays open on the new selection. A failed store keeps the
/// language.
///
/// One column capped at [OneVpnLayout.listCap] holds the rows.
class OneVpnLanguagePage extends StatefulWidget {
  const OneVpnLanguagePage({super.key});

  @override
  State<OneVpnLanguagePage> createState() => _OneVpnLanguagePageState();
}

class _OneVpnLanguagePageState extends State<OneVpnLanguagePage> {
  /// True while a choice is being stored. The rows ignore taps meanwhile.
  bool _applying = false;

  /// Stores [tag], a fork language tag. Null follows the system language.
  Future<void> _choose(String? tag, String? current) async {
    if (tag == current) return;
    final choice = context.read<OneVpnLocaleChoice>();
    setState(() => _applying = true);
    try {
      await choice.choose(tag);
    } catch (_) {
      // A failed store leaves the stored choice selected.
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = OneVpnLocalizations.of(context)!;
    final current = context.select((OneVpnLocaleChoice choice) => choice.state);
    return Scaffold(
      appBar: oneVpnCloseAppBar(context, l.onevpnLanguage),
      body: SafeArea(
        child: OneVpnConstrainedBody(
          maxWidth: OneVpnLayout.listCap,
          scrollable: true,
          child: Padding(
            padding: const EdgeInsets.all(OneVpnCard.margin),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _row(context, null, l.onevpnLanguageSystem, current),
                for (final locale in kOneVpnLocales)
                  _row(context, locale.tag, locale.nativeName, current),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// One outlined choice row titled [title] for [tag]. A null [tag] is the
  /// system row. The row for [current] reads as selected and ends in a check.
  /// Screen readers announce the rows as one group with the [current] row
  /// selected.
  Widget _row(
    BuildContext context,
    String? tag,
    String title,
    String? current,
  ) {
    final palette = ColorManager.palette(context);
    final selected = tag == current;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        container: true,
        selected: selected,
        inMutuallyExclusiveGroup: true,
        child: Material(
          animationDuration: Duration.zero,
          color: selected ? palette.selectedSurface : palette.card,
          borderRadius: BorderRadius.circular(OneVpnCard.radius),
          child: InkWell(
            borderRadius: BorderRadius.circular(OneVpnCard.radius),
            highlightColor: Colors.transparent,
            splashFactory: OneVpnCard.noSplash,
            onTap: _applying ? null : () => _choose(tag, current),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(OneVpnCard.radius),
                border: Border.all(
                  color: selected ? palette.primary : palette.border,
                  width: OneVpnCard.outline,
                ),
              ),
              padding: OneVpnCard.padding,
              child: Row(
                children: [
                  Expanded(
                    child: Text(title, style: AppTypography.settingsRow),
                  ),
                  // A fixed check slot keeps every row one height.
                  SizedBox.square(
                    dimension: 24,
                    child: selected
                        ? Icon(LucideIcons.check, color: palette.primary)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
