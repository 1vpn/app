import 'package:material_ui/material_ui.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations.dart';
import 'package:onexray/onevpn/theme/button.dart';
import 'package:onexray/onevpn/theme/card.dart';
import 'package:onexray/pages/theme/color.dart';
import 'package:onexray/pages/theme/font.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The once-ever gate for the censorship warning on the first connect.
///
/// The warning applies to a free account whose app language is Russian,
/// Persian or Chinese, in either script. The app language is the resolved
/// app locale, which follows the language picker. The flag lives in the
/// fork's own preference namespace and stamps when the warning fires. The
/// warning shows at most once per install.
class OneVpnCensorshipWarning {
  OneVpnCensorshipWarning({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  /// The fork once-ever key.
  static const seenKey = 'onevpn.censorshipWarningSeen';

  /// The language codes the warning applies to.
  static const languages = {'ru', 'fa', 'zh'};

  /// Whether the warning applies to [locale] and an account with [premium].
  static bool appliesTo(Locale locale, {required bool premium}) =>
      !premium && languages.contains(locale.languageCode);

  /// Resolves true once ever, on the first connect it applies to. It stamps
  /// the flag before resolving, so an interrupted connect never re-shows the
  /// warning. A connect the warning does not apply to resolves false and
  /// leaves the flag unstamped. A read or a stamp that throws resolves false:
  /// a store that fails never shows the warning and never fails the connect.
  Future<bool> consumeFirstConnect(
    Locale locale, {
    required bool premium,
  }) async {
    if (!appliesTo(locale, premium: premium)) return false;
    try {
      if (await _preferences.getBool(seenKey) ?? false) return false;
      await _preferences.setBool(seenKey, true);
      return true;
    } catch (_) {
      // Reads as seen. An unstampable flag would show the warning on every
      // connect.
      return false;
    }
  }
}

/// Shows the censorship warning dialog. Resolves when the user dismisses it.
Future<void> showOneVpnCensorshipWarning(BuildContext context) =>
    showDialog<void>(
      context: context,
      builder: (_) => const OneVpnCensorshipWarningDialog(),
    );

/// The censorship warning: the centred message over a single Continue
/// button.
///
/// Continue, a barrier tap, Esc, and back all dismiss it. It takes the
/// confirm dialog's shape in every orientation and on every platform.
class OneVpnCensorshipWarningDialog extends StatelessWidget {
  const OneVpnCensorshipWarningDialog({super.key});

  /// The widest the dialog grows.
  static const double maxWidth = 420;

  @override
  Widget build(BuildContext context) {
    final l = OneVpnLocalizations.of(context)!;
    final palette = ColorManager.palette(context);
    return Dialog(
      backgroundColor: palette.card,
      insetPadding: const EdgeInsets.all(OneVpnCard.margin),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(OneVpnCard.headlineRadius),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth),
        // The dialog names its route for screen readers with its message.
        child: Semantics(
          scopesRoute: true,
          namesRoute: true,
          explicitChildNodes: true,
          label: l.onevpnCensorshipWarning,
          child: SingleChildScrollView(
            padding: OneVpnCard.headlinePadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.onevpnCensorshipWarning,
                  textAlign: TextAlign.center,
                  style: AppTypography.settingsSelect,
                ),
                const SizedBox(height: OneVpnCard.margin),
                FilledButton(
                  style: OneVpnButton.style,
                  onPressed: () => Navigator.pop(context),
                  child: Text(l.onevpnContinue),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
