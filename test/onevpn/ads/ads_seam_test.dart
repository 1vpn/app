// Pins the ads seam as source.
//
// Exactly one file in lib imports google_mobile_ads. The connect screen is
// the one caller of the gate's connect hook. The gate runs after the
// permission and before the held-TUN release and the connect. The defaults
// are Google's published test ids. Every Android variant merges the fork
// overlay that carries the app id.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/ads/admob_ad_gateway.dart';

import '../support/lib_closure.dart';

const _gateway = 'lib/onevpn/ads/admob_ad_gateway.dart';
const _testAppId = 'ca-app-pub-3940256099942544~3347511713';
const _testInterstitial = 'ca-app-pub-3940256099942544/1033173712';

void main() {
  test('only the AdMob gateway imports google_mobile_ads', () {
    final sources = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .toList();
    // Anti-vacuity: the sweep reads the real tree.
    expect(sources.length, greaterThan(200));

    final importers = [
      for (final file in sources)
        if (file.readAsStringSync().contains('package:google_mobile_ads/'))
          file.path,
    ];
    expect(importers, [_gateway]);
  });

  test('the connect screen is the one caller of the connect hook', () {
    final callers = [
      for (final file in libClosureSources())
        if (file.readAsStringSync().contains('.beforeConnect(')) file.path,
    ];
    expect(callers, ['lib/onevpn/shell/connect_screen.dart']);
  });

  test('the gate runs after the permission, before the release', () {
    final screen = File('lib/onevpn/shell/connect_screen.dart')
        .readAsStringSync();
    final order = [
      'await AppHostApi().requestPlatformPermission();',
      'await _adGate.beforeConnect(',
      'await _held.release(_coordinator);',
      'await _coordinator.connect();',
    ].map(screen.indexOf).toList();
    expect(order, everyElement(greaterThan(0)));
    expect(order, orderedEquals([...order]..sort()));
  });

  test('the interstitial default is the published test unit', () {
    expect(kOneVpnAdMobTestInterstitialAndroid, _testInterstitial);
    // The suite runs with no defines.
    expect(kOneVpnAdMobInterstitialAndroid, _testInterstitial);
    expect(oneVpnConsentRequestParameters().consentDebugSettings, isNull);
    expect(oneVpnAdsRequestConfiguration(), isNull);
  });

  test('every variant merges the app id overlay', () {
    final build = File('android/app/build.gradle.kts').readAsStringSync();
    final signing = build.indexOf(
      'apply(from = "../../tool/release_signing.gradle")',
    );
    final admob = build.indexOf('apply(from = "../../tool/admob.gradle")');
    expect(signing, greaterThan(0));
    expect(admob, greaterThan(signing));

    final script = File('tool/admob.gradle').readAsStringSync();
    expect(
      script,
      contains("defines['ONEVPN_ADMOB_APP_ID_ANDROID'] ?: testAppId"),
    );
    expect(script, contains("def testAppId = '$_testAppId'"));
    expect(script, contains('androidComponents.selector().all()'));
    expect(script, contains('addStaticManifestFile(overlay)'));

    final overlay = File('tool/admob/AndroidManifest.xml').readAsStringSync();
    expect(
      overlay,
      contains(
        'android:name="com.google.android.gms.ads.APPLICATION_ID"\n'
        r'            android:value="${onevpnAdmobAppId}"',
      ),
    );
  });
}
