// Pins the mapping from the demo defines to the consent request and the ads
// request configuration.
//
// Only `eea` and `other` force a debug geography. The consent test device
// becomes the one test identifier. The ads test device becomes the one test
// device id, and an empty one yields no configuration.

import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:onexray/onevpn/ads/admob_ad_gateway.dart';

// A made-up hash in the shape the consent platform logs.
const _device = '0123456789ABCDEF0123456789ABCDEF';

void main() {
  test('empty defines send no debug settings', () {
    final params = oneVpnConsentRequestParameters(
      geography: '',
      testDevice: '',
    );
    expect(params.consentDebugSettings, isNull);
  });

  test('eea with a device forces the EEA on that device', () {
    final settings = oneVpnConsentRequestParameters(
      geography: 'eea',
      testDevice: _device,
    ).consentDebugSettings!;
    expect(settings.debugGeography, DebugGeography.debugGeographyEea);
    expect(settings.testIdentifiers, [_device]);
  });

  test('other maps to the unregulated geography', () {
    final settings = oneVpnConsentRequestParameters(
      geography: 'other',
      testDevice: _device,
    ).consentDebugSettings!;
    expect(settings.debugGeography, DebugGeography.debugGeographyOther);
    expect(settings.testIdentifiers, [_device]);
  });

  test('an unknown geography sends no debug settings', () {
    for (final geography in const ['EEA', 'us', 'disabled']) {
      final params = oneVpnConsentRequestParameters(
        geography: geography,
        testDevice: _device,
      );
      expect(params.consentDebugSettings, isNull, reason: geography);
    }
  });

  test('the suite runs with no defines, so the default sends none', () {
    expect(oneVpnConsentRequestParameters().consentDebugSettings, isNull);
  });

  test('an empty ads test device yields no configuration', () {
    expect(oneVpnAdsRequestConfiguration(testDevice: ''), isNull);
  });

  test('an ads test device becomes the one test device id', () {
    final configuration = oneVpnAdsRequestConfiguration(testDevice: _device)!;
    expect(configuration.testDeviceIds, [_device]);
  });

  test('the suite runs with no defines, so no ads configuration', () {
    expect(oneVpnAdsRequestConfiguration(), isNull);
  });
}
