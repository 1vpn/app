// The Support page: the five links and the version line in one capped
// column, in portrait and landscape, with no overflow. At 800x360 the links
// sit two to a row under the capped width, centered. The version line reads
// the label, the version, and the build number when the platform reports one.
// The Manage subscription row shows with no account read and opens the Play
// subscriptions page for this app. Off Android the row is absent.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/l10n/localizations/app_localizations.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations_en.dart';
import 'package:onexray/onevpn/shell/layout.dart';
import 'package:onexray/onevpn/shell/links.dart';
import 'package:onexray/onevpn/shell/support_page.dart';
import 'package:onexray/onevpn/theme/card.dart';
import 'package:onexray/pages/theme/theme.dart';
import 'package:package_info_plus/package_info_plus.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:url_launcher_platform_interface/link.dart';
// ignore: depend_on_referenced_packages
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../support/ink.dart';
import '../support/localizations.dart';
import '../support/viewports.dart';

/// Records each launch request and opens every one.
class _RecordingLauncher extends UrlLauncherPlatform {
  final launches = <String>[];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> supportsMode(PreferredLaunchMode mode) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launches.add(url);
    return true;
  }
}

Future<void> _pump(
  WidgetTester tester,
  Size size, {
  Future<PackageInfo?>? packageInfo,
}) async {
  await setViewport(tester, size);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('en'),
      localizationsDelegates: oneVpnLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: OneVpnSupportPage(packageInfo: packageInfo),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final l = OneVpnLocalizationsEn();

  for (final size in [kPortraitViewport, kLandscapeViewport]) {
    final name = '${size.width.toInt()}x${size.height.toInt()}';
    testWidgets('at $name the links sit in one capped column', (tester) async {
      await _pump(tester, size);
      expect(tester.takeException(), isNull);
      expect(find.byKey(OneVpnConstrainedBody.stackedKey), findsOneWidget);
      expect(find.byKey(OneVpnAdaptiveBody.splitKey), findsNothing);
      for (final link in [
        l.onevpnFaq,
        l.onevpnContactUs,
        l.onevpnPrivacyPolicy,
        l.onevpnTermsOfService,
        l.onevpnRefundPolicy,
      ]) {
        expect(find.text(link), findsOneWidget);
      }
    });
  }

  for (final size in [kPortraitViewport, kLandscapeViewport]) {
    final name = '${size.width.toInt()}x${size.height.toInt()}';
    testWidgets('at $name the links keep their order', (tester) async {
      await _pump(tester, size);
      // Reading order is top to bottom, then start to end.
      final spots = [
        for (final link in [
          l.onevpnFaq,
          l.onevpnContactUs,
          l.onevpnPrivacyPolicy,
          l.onevpnTermsOfService,
          l.onevpnRefundPolicy,
        ])
          tester.getTopLeft(find.text(link)),
      ];
      final sorted = [...spots]
        ..sort(
          (a, b) => a.dy != b.dy ? a.dy.compareTo(b.dy) : a.dx.compareTo(b.dx),
        );
      expect(spots, sorted);
      expect(spots.toSet(), hasLength(5));
    });
  }

  testWidgets(
    'at 800x360 the links sit two to a row under the capped width, centered',
    (tester) async {
      await _pump(tester, kLandscapeViewport);
      final rows = [
        for (final link in [
          l.onevpnFaq,
          l.onevpnContactUs,
          l.onevpnPrivacyPolicy,
          l.onevpnTermsOfService,
          l.onevpnRefundPolicy,
        ])
          tester.getRect(
            find
                .ancestor(of: find.text(link), matching: find.byType(InkWell))
                .first,
          ),
      ];
      // Two cards share each row, split evenly across the capped width.
      const gap = 12.0;
      const column = (OneVpnLayout.listCap - 2 * OneVpnCard.margin - gap) / 2;
      for (final row in rows) {
        expect(row.width, column);
      }
      expect(rows[0].top, rows[1].top);
      expect(rows[1].left, rows[0].right + gap);
      expect(rows[2].top, rows[3].top);
      expect(rows[3].left, rows[2].right + gap);
      expect(rows[4].top, greaterThan(rows[2].bottom));
      expect(rows[4].left, rows[0].left);
      // The pair of columns is centered.
      expect((rows[0].left + rows[1].right) / 2, kLandscapeViewport.width / 2);
    },
  );

  testWidgets('the link rows leave focus and hover to the theme and show '
      'nothing when pressed', (tester) async {
    await _pump(tester, kPortraitViewport);

    expectQuietInk(tester, [
      find.text(l.onevpnFaq),
      find.text(l.onevpnContactUs),
      find.text(l.onevpnPrivacyPolicy),
      find.text(l.onevpnTermsOfService),
      find.text(l.onevpnRefundPolicy),
    ]);
  });

  PackageInfo info({required String version, required String buildNumber}) =>
      PackageInfo(
        appName: '1VPN',
        packageName: 'onevpn',
        version: version,
        buildNumber: buildNumber,
      );

  testWidgets('the version line reads the label, the version, and the build '
      'number', (tester) async {
    await _pump(
      tester,
      kPortraitViewport,
      packageInfo: Future.value(info(version: '3.0.0', buildNumber: '1000')),
    );
    expect(find.text('${l.onevpnAppVersion} · 3.0.0 (1000)'), findsOneWidget);
  });

  testWidgets('without a build number the version line reads the label and '
      'the version', (tester) async {
    await _pump(
      tester,
      kPortraitViewport,
      packageInfo: Future.value(info(version: '3.0.0', buildNumber: '')),
    );
    expect(find.text('${l.onevpnAppVersion} · 3.0.0'), findsOneWidget);
  });

  testWidgets('without a version the version line is empty', (tester) async {
    await _pump(
      tester,
      kPortraitViewport,
      packageInfo: Future.value(info(version: '', buildNumber: '1000')),
    );
    expect(find.textContaining(l.onevpnAppVersion), findsNothing);
  });

  testWidgets('the Manage subscription row opens the Play subscriptions page '
      'for this app', (tester) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final launcher = _RecordingLauncher();
    final previous = UrlLauncherPlatform.instance;
    UrlLauncherPlatform.instance = launcher;
    addTearDown(() => UrlLauncherPlatform.instance = previous);
    await _pump(tester, kPortraitViewport);

    // The row follows the refund policy.
    expect(
      tester.getTopLeft(find.text(l.onevpnManageSubscription)).dy,
      greaterThan(tester.getTopLeft(find.text(l.onevpnRefundPolicy)).dy),
    );
    await tester.tap(find.text(l.onevpnManageSubscription));
    await tester.pumpAndSettle();

    expect(launcher.launches, [
      'https://play.google.com/store/account/subscriptions'
          '?package=com.one.vpnapp',
    ]);
    expect(
      OneVpnStoreLinks.playSubscriptions.queryParameters['package'],
      OneVpnStoreLinks.packageId,
    );
  });

  testWidgets('off Android the page has no Manage subscription row', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await _pump(tester, kPortraitViewport);
    expect(find.text(l.onevpnManageSubscription), findsNothing);
    expect(find.text(l.onevpnRefundPolicy), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });
}
