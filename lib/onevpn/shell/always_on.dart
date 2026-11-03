import 'package:flutter/foundation.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/onevpn/app/platform_channel.dart';
import 'package:onexray/onevpn/feedback/failure_message.dart';
import 'package:onexray/onevpn/feedback/notice.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations.dart';
import 'package:onexray/onevpn/shell/close_app_bar.dart';
import 'package:onexray/onevpn/shell/layout.dart';
import 'package:onexray/onevpn/shell/routes.dart';
import 'package:onexray/onevpn/theme/backdrop.dart';
import 'package:onexray/onevpn/theme/button.dart';
import 'package:onexray/onevpn/theme/card.dart';
import 'package:onexray/onevpn/theme/headline_card.dart';
import 'package:onexray/pages/theme/color.dart';
import 'package:onexray/pages/theme/font.dart';

/// True on Android, the one platform where the menu shows the always-on VPN
/// guidance row.
bool get oneVpnAlwaysOnGuidanceAvailable =>
    defaultTargetPlatform == TargetPlatform.android;

/// Opens the system VPN settings screen. A screen that fails to open shows a
/// failure notice on [context].
Future<void> openOneVpnAlwaysOnSettings(BuildContext context) async {
  final opened = await OneVpnPlatformChannel.openVpnSettings();
  if (!opened && context.mounted) {
    OneVpnNotice.error(
      context,
      oneVpnAppFailureMessage(OneVpnLocalizations.of(context)!, null),
    );
  }
}

/// The always-on VPN guidance as a full page, pushed from the menu.
///
/// The AppBar names the topic. A headline card states that the tunnel stays up
/// when the app closes. It states that always-on reconnects the tunnel after a
/// restart or an app update. A numbered list walks the user through the system
/// VPN list. The button pops true. The menu closes, and its caller opens the
/// system VPN settings screen. The close button, system back, and predictive
/// back pop to the menu. With no route beneath, the button goes to the connect
/// shell.
///
/// Stacked, one column capped at [OneVpnLayout.listCap] holds the card over the
/// steps. In split, the card fills the start pane. The steps and button fill
/// the end pane from the top.
class OneVpnAlwaysOnPage extends StatelessWidget {
  const OneVpnAlwaysOnPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = OneVpnLocalizations.of(context)!;
    final palette = ColorManager.palette(context);
    final card = OneVpnHeadlineCard(
      icon: LucideIcons.info,
      body: l.onevpnAlwaysOnIntro,
    );
    final details = _details(context, l, palette);
    return Scaffold(
      appBar: oneVpnCloseAppBar(context, l.onevpnAlwaysOnTitle),
      body: SafeArea(
        child: OneVpnLayout.isSplit(context)
            ? OneVpnAdaptiveBody(
                start: Padding(
                  padding: const EdgeInsets.all(OneVpnCard.margin),
                  child: card,
                ),
                end: Padding(
                  padding: const EdgeInsets.all(OneVpnCard.margin),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: details,
                  ),
                ),
                endAlignment: Alignment.topCenter,
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
                      ...details,
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  /// The numbered steps and the settings button.
  List<Widget> _details(
    BuildContext context,
    OneVpnLocalizations l,
    AppPalette palette,
  ) {
    final steps = [
      l.onevpnAlwaysOnStep1,
      l.onevpnAlwaysOnStep2,
      l.onevpnAlwaysOnStep3,
      l.onevpnAlwaysOnStep4,
    ];
    return [
      for (final (index, step) in steps.indexed)
        _step(palette, index + 1, step),
      const SizedBox(height: OneVpnCard.margin),
      FilledButton(
        style: OneVpnButton.style,
        onPressed: () => oneVpnPopOrConnect(context, true),
        child: Text(l.onevpnAlwaysOnOpenSettings),
      ),
    ];
  }

  /// One step: the step [number] on a code square, then [text]. It sits on the
  /// card's content inset. The square lines up under the card's medallion, and
  /// the text lines up under its title.
  Widget _step(AppPalette palette, int number, String text) => Padding(
    padding: EdgeInsets.fromLTRB(
      OneVpnCard.outline + OneVpnCard.padding.left,
      0,
      OneVpnCard.outline + OneVpnCard.padding.right,
      14,
    ),
    child: Row(
      children: [
        OneVpnBackdropSquare(
          color: palette.muted,
          border: palette.border,
          child: Text('$number', style: AppTypography.routingRegionCode),
        ),
        const SizedBox(width: OneVpnCard.leadingGap),
        Expanded(child: Text(text, style: AppTypography.settingsSelect)),
      ],
    ),
  );
}
