// The store configuration, and the live bridge's behaviour without a key.
//
// The key is the only configuration input. Everything the live bridge does
// is gated on it. With no key it answers the way it answers an offline
// store, and never reaches the SDK.
//
// Every config here is constructed, never read from the build. A developer
// can hold a real key in env/local.json. The gate answers the same on their
// machine as on CI.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/purchase/purchase_config.dart';
import 'package:onexray/onevpn/purchase/purchase_service.dart';
import 'package:onexray/onevpn/purchase/revenuecat_purchase_service.dart';

/// Every call the store SDK makes leaves the Dart side through this
/// channel. A handler on it counts what the bridge touched.
const MethodChannel _storeChannel = MethodChannel('purchases_flutter');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the configuration', () {
    test('an empty key is not configured', () {
      expect(const OneVpnPurchaseConfig().isConfigured, isFalse);
      expect(const OneVpnPurchaseConfig(apiKey: '').isConfigured, isFalse);
      expect(const OneVpnPurchaseConfig(apiKey: 'sk').isConfigured, isTrue);
    });

    test('both store platforms read the one build key', () {
      // The key is a build input. A developer's env/local.json may hold a
      // real one, so this pins the rule and never the value.
      final android = OneVpnPurchaseConfig.forPlatform(TargetPlatform.android);
      final ios = OneVpnPurchaseConfig.forPlatform(TargetPlatform.iOS);

      expect(android.apiKey, ios.apiKey);
      expect(android.isConfigured, ios.isConfigured);
    });

    test('desktop resolves no key', () {
      // Billing is mobile-only and desktop is a hosted web checkout, so a
      // desktop build has no store path to offer.
      for (final platform in const [
        TargetPlatform.macOS,
        TargetPlatform.linux,
        TargetPlatform.windows,
      ]) {
        expect(
          OneVpnPurchaseConfig.forPlatform(platform).isConfigured,
          isFalse,
          reason: '$platform must not resolve a store key',
        );
      }
    });
  });

  group('the live bridge without a key', () {
    // The test builds the bridge without a key, so these pins hold under
    // any build defines.
    const bridge = OneVpnLivePurchasesBridge(config: OneVpnPurchaseConfig());

    /// The SDK method names the bridge reached for. Empty is the contract.
    late List<String> storeCalls;

    setUp(() {
      storeCalls = <String>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(_storeChannel, (call) async {
        storeCalls.add(call.method);
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(_storeChannel, null),
      );
    });

    test('reads no offering, which is the paywall fallback', () async {
      // An unconfigured store is unavailable, not unreachable. The paywall
      // shows placeholder pricing and stays usable.
      expect(await bridge.loadOfferings(), isA<OneVpnOfferingsUnavailable>());
      expect(storeCalls, isEmpty);
    });

    test('setting the email is a no-op rather than a throw', () async {
      await expectLater(bridge.setEmail('buyer@example.invalid'), completes);
      expect(storeCalls, isEmpty);
    });

    test('the identity check passes and reaches no SDK call', () async {
      expect(await bridge.assertIdentity(), isTrue);
      expect(storeCalls, isEmpty);
    });

    test('log in and log out reach no SDK call', () async {
      await expectLater(bridge.logIn('account@example.invalid'), completes);
      await expectLater(bridge.logOut(), completes);
      expect(storeCalls, isEmpty);
    });

    test('a purchase fails with the not-configured reason', () async {
      final outcome = await bridge.purchasePackage(null);

      // The detail names the branch that answered. Every other failure in
      // this method carries a different one.
      expect(outcome, isA<OneVpnPurchaseFailed>());
      expect(
        (outcome as OneVpnPurchaseFailed).detail,
        'the store is not configured',
      );
      expect(storeCalls, isEmpty);
    });

    test('the composed service degrades the same way end to end', () async {
      const service = OneVpnRevenueCatPurchaseService(bridge: bridge);

      expect(await service.loadOfferings(), isA<OneVpnOfferingsUnavailable>());
      final outcome = await service.purchase(
        package: const OneVpnPurchasePackage(
          identifier: 'yearly',
          term: OneVpnPurchaseTerm.yearly,
          priceString: r'$39.99',
        ),
        email: 'buyer@example.invalid',
      );

      expect(outcome, isA<OneVpnPurchaseFailed>());
      expect(
        (outcome as OneVpnPurchaseFailed).detail,
        'the store is not configured',
      );
      // The email set and the purchase both stop at the gate.
      expect(storeCalls, isEmpty);
    });
  });
}
