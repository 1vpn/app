import 'package:flutter/foundation.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/onevpn/ads/connect_ad_gate.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations.dart';
import 'package:onexray/onevpn/shell/close_app_bar.dart';
import 'package:onexray/onevpn/shell/layout.dart';
import 'package:onexray/onevpn/shell/links.dart';
import 'package:onexray/onevpn/theme/card.dart';
import 'package:onexray/pages/theme/color.dart';
import 'package:onexray/pages/theme/font.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// The fork Support page: the FAQ, Contact Us, the privacy policy, the
/// terms, and the refund policy, then the app version, in a column capped at
/// [OneVpnLayout.listCap]. Stacked, each link takes its own row. In split,
/// the links sit two to a row.
///
/// Every link hands off to the hosted 1vpn page in the browser. The app keeps
/// no in-app copy of any policy. The version line shows once the platform
/// reports it. It shows nothing when the platform cannot.
///
/// On Android, a Manage subscription row follows the refund policy in every
/// account state. It opens the Google Play subscriptions page for this app.
///
/// A Privacy choices row follows the links while the ads consent platform
/// requires a privacy options entry. It opens the consent platform's privacy
/// options form.
class OneVpnSupportPage extends StatelessWidget {
  const OneVpnSupportPage({super.key, this.packageInfo, this.adGate});

  /// Overrides the platform package info read in tests.
  final Future<PackageInfo?>? packageInfo;

  /// The ad gate whose consent information decides the Privacy choices row.
  /// Defaults to the shared one. Tests inject one.
  final OneVpnConnectAdGate? adGate;

  @override
  Widget build(BuildContext context) {
    final gate = adGate ?? OneVpnConnectAdGate.instance;
    return ValueListenableBuilder<bool>(
      valueListenable: gate.privacyOptionsRequired,
      builder: (context, privacyChoices, _) =>
          _page(context, gate, privacyChoices: privacyChoices),
    );
  }

  Widget _page(
    BuildContext context,
    OneVpnConnectAdGate gate, {
    required bool privacyChoices,
  }) {
    final l = OneVpnLocalizations.of(context)!;
    final palette = ColorManager.palette(context);
    final links = [
      _link(
        context,
        palette,
        LucideIcons.circleHelp,
        l.onevpnFaq,
        () => openExternalLink(context, OneVpnLinks.faq),
      ),
      _link(
        context,
        palette,
        LucideIcons.mail,
        l.onevpnContactUs,
        () => openExternalLink(context, OneVpnLinks.contactUs),
      ),
      _link(
        context,
        palette,
        LucideIcons.shieldCheck,
        l.onevpnPrivacyPolicy,
        () => openExternalLink(context, OneVpnLinks.privacyPolicy),
      ),
      _link(
        context,
        palette,
        LucideIcons.fileText,
        l.onevpnTermsOfService,
        () => openExternalLink(context, OneVpnLinks.termsOfService),
      ),
      _link(
        context,
        palette,
        LucideIcons.creditCardCheck,
        l.onevpnRefundPolicy,
        () => openExternalLink(context, OneVpnLinks.refundPolicy),
      ),
      if (defaultTargetPlatform == TargetPlatform.android)
        _link(
          context,
          palette,
          LucideIcons.wallet,
          l.onevpnManageSubscription,
          () => openExternalLink(context, OneVpnStoreLinks.playSubscriptions),
        ),
      if (privacyChoices)
        _link(
          context,
          palette,
          LucideIcons.slidersHorizontal,
          l.onevpnPrivacyChoices,
          gate.showPrivacyOptions,
        ),
    ];
    final split = OneVpnLayout.isSplit(context);
    final details = [
      if (split)
        for (var i = 0; i < links.length; i += 2)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: links[i]),
              const SizedBox(width: 12),
              Expanded(
                child: i + 1 < links.length ? links[i + 1] : const SizedBox(),
              ),
            ],
          )
      else
        ...links,
      const SizedBox(height: 8),
      _Version(label: l.onevpnAppVersion, packageInfo: packageInfo),
    ];
    return Scaffold(
      appBar: oneVpnCloseAppBar(context, l.onevpnSupport),
      body: SafeArea(
        child: OneVpnConstrainedBody(
          maxWidth: OneVpnLayout.listCap,
          scrollable: true,
          child: Padding(
            padding: const EdgeInsets.all(OneVpnCard.margin),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: details,
            ),
          ),
        ),
      ),
    );
  }

  /// One outlined link row: [icon] and [title]. A tap runs [onTap].
  Widget _link(
    BuildContext context,
    AppPalette palette,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: palette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(OneVpnCard.radius),
        side: BorderSide(color: palette.border, width: OneVpnCard.outline),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(OneVpnCard.radius),
        highlightColor: Colors.transparent,
        splashFactory: OneVpnCard.noSplash,
        onTap: onTap,
        child: Padding(
          padding: OneVpnCard.padding,
          child: Row(
            children: [
              Icon(icon, color: palette.mutedForeground),
              const SizedBox(width: OneVpnCard.leadingGap),
              Expanded(child: Text(title, style: AppTypography.settingsRow)),
            ],
          ),
        ),
      ),
    ),
  );
}

/// The app version line: "[label] · 3.0.0 (1000)" in muted type, with the
/// build number in parentheses. Without a build number it reads
/// "[label] · 3.0.0". It stays empty until the platform reports a version, and
/// when it reports none.
class _Version extends StatelessWidget {
  const _Version({required this.label, this.packageInfo});

  final String label;
  final Future<PackageInfo?>? packageInfo;

  /// The platform package info, read once per process. A platform without the
  /// plugin reports none.
  static final Future<PackageInfo?> _platformInfo = () async {
    try {
      return await PackageInfo.fromPlatform();
    } catch (_) {
      return null;
    }
  }();

  @override
  Widget build(BuildContext context) => FutureBuilder<PackageInfo?>(
    future: packageInfo ?? _platformInfo,
    builder: (context, snapshot) {
      final version = snapshot.data?.version;
      if (version == null || version.isEmpty) return const SizedBox.shrink();
      final build = snapshot.data!.buildNumber;
      return Text(
        build.isEmpty ? '$label · $version' : '$label · $version ($build)',
        textAlign: TextAlign.center,
        style: AppTypography.settingsValueLabel.copyWith(
          color: ColorManager.palette(context).mutedForeground,
        ),
      );
    },
  );
}
