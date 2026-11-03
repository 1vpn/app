import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/onevpn/feedback/failure_message.dart';
import 'package:onexray/onevpn/feedback/notice.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations.dart';
import 'package:onexray/onevpn/net/api_transport.dart';
import 'package:onexray/onevpn/net/failover_domains.dart';
import 'package:url_launcher/url_launcher.dart';

/// Hosted 1vpn pages the fork opens. The site serves each as one canonical
/// page, so no link carries a locale path.
///
/// Each constant is its page on the primary domain. [resolve] moves a page
/// onto the domain the account API reached. The constant is the fallback.
abstract final class OneVpnLinks {
  /// The hosted password reset page. Forgot password on the auth screen
  /// opens it.
  static final Uri passwordReset = Uri.parse(
    'https://1vpn.org/password-reset-request/',
  );

  /// Frequently asked questions, an anchor on the site's landing page. The
  /// Support page opens it.
  static final Uri faq = Uri.parse('https://1vpn.org/#faq');

  /// The hosted terms of service. The Support page opens it.
  static final Uri termsOfService = Uri.parse(
    'https://1vpn.org/terms-of-service/',
  );

  /// The hosted privacy policy. The Support page opens it. The app ships no
  /// in-app copy of the policy.
  static final Uri privacyPolicy = Uri.parse(
    'https://1vpn.org/privacy-policy/',
  );

  /// The hosted contact page. The Support page and the location picker's
  /// unavailable state open it.
  static final Uri contactUs = Uri.parse('https://1vpn.org/contact-us/');

  /// The hosted refund policy. The Support page opens it.
  static final Uri refundPolicy = Uri.parse('https://1vpn.org/refund-policy/');

  /// The hosted account page. The menu's account row opens it to edit
  /// account information.
  static final Uri account = Uri.parse('https://1vpn.org/account/');

  /// [page] on the domain the account API reached, read at call time.
  ///
  /// The result keeps the path and fragment of [page]. It takes the host
  /// from [OneVpnApiTransport.activeBaseUrl], which makes no network call.
  /// With no remembered domain, that host is the primary and the result
  /// equals [page].
  ///
  /// A failed read returns [page] unchanged. So does a base outside
  /// [OneVpnFailoverDomains.all]. A page therefore opens only on a failover
  /// domain. A [page] whose host is outside [OneVpnFailoverDomains.all]
  /// returns unchanged with no read.
  ///
  /// [transport] defaults to [OneVpnApiTransport.instance].
  static Future<Uri> resolve(Uri page, {OneVpnApiTransport? transport}) async {
    if (!OneVpnFailoverDomains.all.contains(page.host)) return page;
    try {
      final base = Uri.parse(
        await (transport ?? OneVpnApiTransport.instance).activeBaseUrl(),
      );
      if (base.scheme == 'https' &&
          OneVpnFailoverDomains.all.contains(base.host)) {
        return page.replace(host: base.host);
      }
    } catch (_) {
      // Falls through to the constant.
    }
    return page;
  }
}

/// Store pages the fork opens. Each names the app by its package id.
abstract final class OneVpnStoreLinks {
  /// The Android application id the Play links name.
  static const packageId = 'com.one.vpnapp';

  /// The Google Play subscriptions page for this app. The Support page's
  /// Manage subscription row opens it.
  static final Uri playSubscriptions = Uri.parse(
    'https://play.google.com/store/account/subscriptions?package=com.one.vpnapp',
  );
}

/// Opens [uri] in the user's own browser, never an app webview. Reports
/// failure through a notice and never throws back at the caller.
///
/// [uri] resolves through [OneVpnLinks.resolve] on each call. A hosted 1vpn
/// page opens on the domain the account API reached. Any other page opens
/// as given.
///
/// The page opens in the platform browser view where one exists: Custom Tabs
/// on Android, SFSafariViewController on iOS. Closing the view returns to the
/// app. Every other case opens the external browser: a platform with no
/// browser view, an Android device with no Custom Tabs provider, or a browser
/// view that fails to open.
Future<void> openExternalLink(BuildContext context, Uri uri) async {
  try {
    final opened = await _launchInBrowser(await OneVpnLinks.resolve(uri));
    if (!opened && context.mounted) {
      OneVpnNotice.error(
        context,
        oneVpnAppFailureMessage(OneVpnLocalizations.of(context)!, null),
      );
    }
  } catch (error) {
    if (context.mounted) {
      OneVpnNotice.error(
        context,
        oneVpnAppFailureMessage(OneVpnLocalizations.of(context)!, error),
      );
    }
  }
}

Future<bool> _launchInBrowser(Uri uri) async {
  // Must check support first: on Android an unsupported browser view falls
  // back to the plugin's own webview.
  if (await supportsLaunchMode(LaunchMode.inAppBrowserView)) {
    try {
      if (await launchUrl(uri, mode: LaunchMode.inAppBrowserView)) {
        return true;
      }
    } on PlatformException {
      // Falls through to the external browser.
    }
  }
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
