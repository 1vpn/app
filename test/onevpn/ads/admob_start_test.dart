// The AdMob gateway's SDK start over mocked plugin channels. A consent pass
// that allows ads makes one start attempt. A start that throws leaves the SDK
// unstarted, and the next pass starts it again. Passes that overlap a start
// wait for it and share its outcome.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/ads/admob_ad_gateway.dart';

/// The plugin's consent channel. A pass with no form sends it calls without
/// arguments, so the standard codec decodes them.
const _consent = MethodChannel('plugins.flutter.io/google_mobile_ads/ump');

/// The plugin's ads channel.
const _ads = MethodChannel('plugins.flutter.io/google_mobile_ads');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    messenger.setMockMethodCallHandler(
      _consent,
      (call) async => switch (call.method) {
        // Obtained under both platforms' numbering, so no form shows.
        'ConsentInformation#getConsentStatus' => 3,
        'ConsentInformation#canRequestAds' => true,
        _ => null,
      },
    );
  });

  tearDown(() {
    messenger
      ..setMockMethodCallHandler(_consent, null)
      ..setMockMethodCallHandler(_ads, null);
  });

  test('a thrown initialize runs again on the next consent pass', () async {
    var initializes = 0;
    messenger.setMockMethodCallHandler(_ads, (call) async {
      if (call.method != 'MobileAds#initialize') return null;
      initializes++;
      throw PlatformException(code: 'initialize');
    });
    final gateway = OneVpnAdMobAdGateway(live: true);

    expect(await gateway.gatherConsent(), isFalse);
    expect(initializes, 1);

    expect(await gateway.gatherConsent(), isFalse);
    expect(initializes, 2);
  });

  test('passes that overlap a start share its outcome', () async {
    final release = Completer<void>();
    var initializes = 0;
    messenger.setMockMethodCallHandler(_ads, (call) async {
      if (call.method != 'MobileAds#initialize') return null;
      initializes++;
      await release.future;
      throw PlatformException(code: 'initialize');
    });
    final gateway = OneVpnAdMobAdGateway(live: true);

    final first = gateway.gatherConsent();
    final second = gateway.gatherConsent();
    await pumpEventQueue();
    expect(initializes, 1);

    release.complete();
    expect(await first, isFalse);
    expect(await second, isFalse);

    // The failed start is cleared, so the next pass initializes again.
    expect(await gateway.gatherConsent(), isFalse);
    expect(initializes, 2);
  });
}
