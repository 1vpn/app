import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations.dart';
import 'package:onexray/onevpn/shell/close_app_bar.dart';
import 'package:onexray/onevpn/shell/edge_route.dart';
import 'package:onexray/onevpn/shell/layout.dart';
import 'package:onexray/onevpn/shell/routes.dart';
import 'package:onexray/onevpn/theme/backdrop.dart';
import 'package:onexray/onevpn/theme/button.dart';
import 'package:onexray/onevpn/theme/card.dart';
import 'package:onexray/onevpn/theme/headline_card.dart';
import 'package:onexray/pages/theme/color.dart';
import 'package:onexray/pages/theme/font.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The once-ever gate for the first-connect explainer. It records that the
/// explainer has fired in the fork's own preference namespace, never
/// upstream's. The flag stamps on the first connect, whatever the user does
/// with the page. The explainer shows exactly once per install.
class OneVpnFirstConnectExplainer {
  OneVpnFirstConnectExplainer({
    SharedPreferencesAsync? preferences,
    this.enabled = enabledByDefault,
  }) : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  /// The fork once-ever key. It is distinct from the first-boot privacy flag.
  /// That flag stamps on first boot, and this key stamps on first connect.
  static const seenKey = 'onevpn.firstConnectExplainerSeen';

  /// Whether the app shows the explainer on the first connect. While false,
  /// every connect proceeds with no page and the flag stays unstamped.
  static const enabledByDefault = false;

  /// Whether this gate shows the explainer. Defaults to [enabledByDefault].
  /// Tests enable it.
  final bool enabled;

  /// Resolves true on the first connect only, while [enabled]. It stamps the
  /// flag, so every later connect resolves false. The flag stamps whether or
  /// not the caller then shows the page. An interrupted first connect never
  /// re-shows the explainer. A read or a stamp that throws resolves false: a
  /// store that fails never shows the explainer and never fails the connect.
  Future<bool> consumeFirstConnect() async {
    if (!enabled) return false;
    try {
      if (await _preferences.getBool(seenKey) ?? false) return false;
      await _preferences.setBool(seenKey, true);
      return true;
    } catch (_) {
      // Reads as seen. An unstampable flag would show the explainer on every
      // connect.
      return false;
    }
  }
}

/// Opens the non-blocking first-connect explainer as a full page. It
/// introduces the domestic-direct regions and discloses that a direct region
/// routes from the real IP. The primary button routes to the Direct-regions
/// picker, which comes up from the bottom edge over connect. Not now and back
/// return, and the caller proceeds to connect.
Future<void> showOneVpnFirstConnectExplainer(BuildContext context) async {
  final chooseRegion = await context.push<bool>(kOneVpnFirstConnectRoute);
  if (chooseRegion == true && context.mounted) {
    context.push(kOneVpnDirectRegionsRoute, extra: OneVpnStackedEdge.bottom);
  }
}

/// The first-connect explainer page. It pops true for the primary button.
///
/// It comes up from the bottom edge under a close app bar that names Direct
/// regions. The headline card names what a full tunnel can break. Two points
/// follow on the card's content inset. One says a direct region routes from the
/// real IP. The other says everything else stays protected. The primary button
/// sits over an outlined Not now. Stacked, one capped column scrolls. Split,
/// the card and the points fill the start pane. The buttons center in the end
/// pane, so Not now always shows. The close button, a swipe, and Not now return
/// with no region. With no route beneath, each button goes to the connect
/// shell.
class OneVpnFirstConnectPage extends StatelessWidget {
  const OneVpnFirstConnectPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = OneVpnLocalizations.of(context)!;
    final palette = ColorManager.palette(context);
    final card = OneVpnHeadlineCard(
      icon: LucideIcons.route,
      title: l.onevpnFirstConnectTitle,
      body: l.onevpnFirstConnectPointBreaks,
    );
    final points = [
      _point(palette, LucideIcons.route, l.onevpnFirstConnectPointDirect),
      _point(
        palette,
        LucideIcons.shieldCheck,
        l.onevpnFirstConnectPointProtected,
      ),
    ];
    return Scaffold(
      appBar: oneVpnCloseAppBar(context, l.onevpnDirectRegions),
      body: SafeArea(
        child: OneVpnLayout.isSplit(context)
            ? OneVpnAdaptiveBody(
                start: Padding(
                  padding: const EdgeInsets.all(OneVpnCard.margin),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      card,
                      const SizedBox(height: OneVpnCard.margin),
                      ...points,
                    ],
                  ),
                ),
                end: Padding(
                  padding: const EdgeInsets.all(OneVpnCard.margin),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _buttons(context, l),
                  ),
                ),
              )
            : OneVpnConstrainedBody(
                maxWidth: OneVpnLayout.listCap,
                scrollable: true,
                child: Padding(
                  padding: const EdgeInsets.all(OneVpnCard.margin),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      card,
                      const SizedBox(height: OneVpnCard.margin),
                      ...points,
                      const SizedBox(height: OneVpnCard.margin - 14),
                      ..._buttons(context, l),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  /// One point: [icon] on a backdrop square, then [text]. It sits on the card's
  /// content inset. The square lines up under the card's medallion, and the
  /// text lines up under its title.
  Widget _point(AppPalette palette, IconData icon, String text) => Padding(
    padding: EdgeInsets.fromLTRB(
      OneVpnCard.outline + OneVpnCard.padding.left,
      0,
      OneVpnCard.outline + OneVpnCard.padding.right,
      14,
    ),
    child: Row(
      children: [
        OneVpnBackdropSquare(
          color: OneVpnBackdrop.tint(palette),
          child: Icon(
            icon,
            size: OneVpnBackdropSquare.glyphSize,
            color: palette.primary,
          ),
        ),
        const SizedBox(width: OneVpnCard.leadingGap),
        Expanded(child: Text(text, style: AppTypography.settingsSelect)),
      ],
    ),
  );

  List<Widget> _buttons(BuildContext context, OneVpnLocalizations l) => [
    FilledButton(
      style: OneVpnButton.style,
      onPressed: () => oneVpnPopOrConnect(context, true),
      child: Text(l.onevpnFirstConnectChooseRegion),
    ),
    const SizedBox(height: OneVpnButton.stackGap),
    OutlinedButton(
      style: OneVpnButton.style,
      onPressed: () => oneVpnPopOrConnect(context, false),
      child: Text(l.onevpnFirstConnectDismiss),
    ),
  ];
}
