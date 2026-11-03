// The live bridge at the session boundary. A recording configure stands in
// for the store memo, and a recording SDK for the store. Log in and log out
// record the wanted customer before they configure. A configure that answers
// false only records. The paywall calls configure first. A failed configure
// with a key fails the identity check. On Google Play, a store error on the
// purchase channel maps to its failure reason, and the debug line names the
// reason and the code. Every other platform maps every store error to the
// unknown reason and never resets. A code that is no store error number
// fails with the unknown reason. A reset of pending purchases configures
// first. A store sheet left behind comes back, or finishes, through the fork
// channel on Google Play only. A finish answers once the cancel of an open
// purchase lands, or after 3 s. Code 15 with a finished sheet purchases once
// more and never resets.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/app/platform_channel.dart';
import 'package:onexray/onevpn/purchase/purchase_config.dart';
import 'package:onexray/onevpn/purchase/purchase_service.dart';
import 'package:onexray/onevpn/purchase/revenuecat_purchase_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart'
    show Package, PackageType, PresentedOfferingContext, StoreProduct;

import 'store_identity_support.dart';

/// Every call the store SDK makes leaves the Dart side through this
/// channel. A handler on it counts what the bridge touched.
const MethodChannel _storeChannel = MethodChannel('purchases_flutter');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RecordingIdentitySdk sdk;
  late OneVpnStoreIdentity identity;
  late OneVpnLivePurchasesBridge bridge;

  /// A bridge for [config] over the recording configure and identity.
  late OneVpnLivePurchasesBridge Function(OneVpnPurchaseConfig config)
  bridgeFor;

  /// The answer the recording configure gives.
  late bool configures;

  /// The wanted customer at each configure, one entry per configure.
  late List<String?> wantedAtConfigure;

  /// The SDK method names the bridge reached for.
  late List<String> storeCalls;

  setUp(() {
    sdk = RecordingIdentitySdk();
    identity = OneVpnStoreIdentity(sdk: sdk);
    configures = true;
    wantedAtConfigure = <String?>[];
    storeCalls = <String>[];
    bridgeFor = (config) => OneVpnLivePurchasesBridge(
      config: config,
      configure: (_) async {
        wantedAtConfigure.add(identity.appUserId);
        if (!configures) return false;
        // As the memo does: a configured store starts the apply and returns.
        unawaited(identity.markReady());
        return true;
      },
      identity: identity,
    );
    bridge = bridgeFor(const OneVpnPurchaseConfig(apiKey: 'sk'));
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_storeChannel, (call) async {
      storeCalls.add(call.method);
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(_storeChannel, null));
  });

  group('log in and log out', () {
    test('log in records the wanted customer, then configures', () async {
      await bridge.logIn('account-a');

      expect(wantedAtConfigure, ['account-a']);
    });

    test('log out records the anonymous customer, then configures', () async {
      await identity.identify('account-a');

      await bridge.logOut();

      expect(wantedAtConfigure, [null]);
    });

    test('a configure that answers false leaves the record for a later '
        'configure', () async {
      configures = false;

      await bridge.logIn('account-a');
      await pumpEventQueue();

      expect(wantedAtConfigure, ['account-a']);
      expect(sdk.calls, isEmpty);
      expect(identity.appUserId, 'account-a');

      await identity.markReady();

      expect(sdk.calls, ['appUserId', 'logIn:account-a']);
    });

    test('a configure that answers true applies the log in at once', () async {
      await bridge.logIn('account-a');
      await pumpEventQueue();

      expect(sdk.calls, ['appUserId', 'logIn:account-a']);
    });

    test('a configure that answers true applies the log out at once', () async {
      sdk
        ..anonymous = false
        ..appUserIdValue = 'account-a';

      await bridge.logOut();
      await pumpEventQueue();

      expect(sdk.calls, ['isAnonymous', 'logOut']);
    });

    test('an id the store already holds makes no second log in', () async {
      // A signed-in launch restores the session the store already holds.
      sdk
        ..anonymous = false
        ..appUserIdValue = 'account-a';

      await bridge.logIn('account-a');
      await pumpEventQueue();

      expect(sdk.calls, ['appUserId']);
    });

    test('a request on a configured store applies at once', () async {
      await bridge.logIn('account-a');
      await pumpEventQueue();
      sdk.calls.clear();

      await bridge.logOut();

      expect(wantedAtConfigure, ['account-a', null]);
      expect(sdk.calls, ['isAnonymous', 'logOut']);
    });
  });

  group('the paywall calls configure first', () {
    setUp(() => configures = false);

    test('loading the offering unconfigured reads no offering', () async {
      expect(await bridge.loadOfferings(), isA<OneVpnOfferingsUnavailable>());

      expect(wantedAtConfigure, [null]);
      expect(storeCalls, isEmpty);
    });

    test('setting the email unconfigured sets nothing', () async {
      await bridge.setEmail('buyer@example.invalid');

      expect(wantedAtConfigure, [null]);
      expect(storeCalls, isEmpty);
    });

    test('an empty email never configures', () async {
      await bridge.setEmail('');

      expect(wantedAtConfigure, isEmpty);
      expect(storeCalls, isEmpty);
    });

    test(
      'a purchase unconfigured fails with the not-configured reason',
      () async {
        final outcome = await bridge.purchasePackage(null);

        expect(outcome, isA<OneVpnPurchaseFailed>());
        expect(
          (outcome as OneVpnPurchaseFailed).detail,
          'the store is not configured',
        );
        expect(wantedAtConfigure, [null]);
        expect(storeCalls, isEmpty);
      },
    );

    test('a build with no key passes the identity check with no SDK '
        'call', () async {
      final keyless = bridgeFor(const OneVpnPurchaseConfig());

      expect(await keyless.assertIdentity(), isTrue);

      expect(wantedAtConfigure, [null]);
      expect(sdk.calls, isEmpty);
      expect(storeCalls, isEmpty);
    });

    test('a failed configure with a key fails the identity check, and the '
        'purchase never runs', () async {
      final service = OneVpnRevenueCatPurchaseService(bridge: bridge);

      expect(await bridge.assertIdentity(), isFalse);
      final outcome = await service.purchase(
        package: const OneVpnPurchasePackage(
          identifier: 'yearly',
          term: OneVpnPurchaseTerm.yearly,
          priceString: r'$39.99',
        ),
        email: 'buyer@example.invalid',
      );

      // The identity check fails the purchase. The email set and the
      // purchase never configure.
      expect(outcome, isA<OneVpnPurchaseFailed>());
      expect((outcome as OneVpnPurchaseFailed).detail, 'purchase failed');
      expect(wantedAtConfigure, [null, null]);
      expect(sdk.calls, isEmpty);
      expect(storeCalls, isEmpty);
    });

    test('no paywall call records a wanted customer', () async {
      configures = true;

      await bridge.loadOfferings();
      await bridge.setEmail('buyer@example.invalid');
      await bridge.purchasePackage(null);
      await bridge.assertIdentity();

      expect(wantedAtConfigure, [null, null, null, null]);
      expect(identity.appUserId, isNull);
    });
  });

  group('a store error names its failure reason', () {
    /// A store package. Only its type reaches the purchase call.
    const package = Package(
      'monthly',
      PackageType.monthly,
      StoreProduct('monthly', 'Monthly', 'Monthly', 6.99, r'$6.99', 'USD'),
      PresentedOfferingContext('default', null, null),
    );

    /// Play's debug text for a changed account stamp, as the SDK carries it.
    const mismatch =
        'Error updating purchases. DebugMessage: Account identifiers '
        "don't match the previous subscription. ErrorCode: DEVELOPER_ERROR.";

    /// The lines the bridge logged during the test.
    late List<String> logged;

    setUp(() {
      logged = <String>[];
      final previous = debugPrint;
      debugPrint = (message, {wrapWidth}) => logged.add(message ?? '');
      addTearDown(() => debugPrint = previous);
    });

    /// Purchases [package] against a store that refuses with [code] and the
    /// error [details].
    Future<OneVpnPurchaseOutcome> refusedWith(
      String code,
      Map<String, Object?>? details,
    ) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_storeChannel, (call) async {
            storeCalls.add(call.method);
            throw PlatformException(
              code: code,
              message: 'refused',
              details: details,
            );
          });
      return bridge.purchasePackage(package);
    }

    for (final (name, code, details, reason)
        in <
          (String, String, Map<String, Object?>?, OneVpnPurchaseFailureReason)
        >[
          (
            "code 4 with Play's account text",
            '4',
            {'underlyingErrorMessage': mismatch},
            OneVpnPurchaseFailureReason.otherAccount,
          ),
          (
            'code 4 with other text',
            '4',
            {
              'underlyingErrorMessage':
                  'Error updating purchases. DebugMessage: . '
                  'ErrorCode: DEVELOPER_ERROR.',
            },
            OneVpnPurchaseFailureReason.unknown,
          ),
          ('code 6', '6', null, OneVpnPurchaseFailureReason.owned),
          ('code 7', '7', null, OneVpnPurchaseFailureReason.otherAccount),
          ('code 15', '15', null, OneVpnPurchaseFailureReason.unfinished),
          ('code 2', '2', null, OneVpnPurchaseFailureReason.storeProblem),
          ('code 10', '10', null, OneVpnPurchaseFailureReason.unknown),
        ]) {
      test('$name maps to ${reason.name}', () async {
        final outcome = await refusedWith(code, details);

        expect(storeCalls, ['purchasePackage']);
        expect(outcome, isA<OneVpnPurchaseFailed>());
        expect((outcome as OneVpnPurchaseFailed).reason, reason);
        expect(logged, [
          'OneVpnPurchase failed reason=${reason.name} code=$code',
        ]);
      });
    }

    test('a code that is no store error number fails with the unknown '
        'reason', () async {
      // The embedding reports a native exception with the code "error".
      for (final code in ['error', '-1']) {
        logged.clear();
        final outcome = await refusedWith(code, null);

        expect(outcome, isA<OneVpnPurchaseFailed>(), reason: code);
        expect(
          (outcome as OneVpnPurchaseFailed).reason,
          OneVpnPurchaseFailureReason.unknown,
          reason: code,
        );
        expect(logged, ['OneVpnPurchase failed reason=unknown'], reason: code);
      }
    });

    for (final platform in TargetPlatform.values.where(
      (platform) => platform != TargetPlatform.android,
    )) {
      test('on ${platform.name}, every store error maps to unknown', () async {
        debugDefaultTargetPlatformOverride = platform;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);

        for (final (code, details) in <(String, Map<String, Object?>?)>[
          ('4', {'underlyingErrorMessage': mismatch}),
          ('6', null),
          ('7', null),
          ('15', null),
          ('2', null),
        ]) {
          logged.clear();
          final outcome = await refusedWith(code, details);

          expect(
            (outcome as OneVpnPurchaseFailed).reason,
            OneVpnPurchaseFailureReason.unknown,
            reason: code,
          );
          expect(logged, [
            'OneVpnPurchase failed reason=unknown code=$code',
          ], reason: code);
        }
      });
    }

    test('only Google Play finishes a sheet or resets on code 15', () async {
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final service = OneVpnRevenueCatPurchaseService(bridge: bridge);
      await bridge.logIn('account-a');
      await pumpEventQueue();
      final forkCalls = <String>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      const fork = MethodChannel(OneVpnPlatformChannel.name);
      messenger.setMockMethodCallHandler(fork, (call) async {
        forkCalls.add(call.method);
        return false;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(fork, null));

      /// Purchases against a store that answers code 15 on [platform], and
      /// returns the identity SDK calls.
      Future<List<String>> buyOn(TargetPlatform platform) async {
        debugDefaultTargetPlatformOverride = platform;
        sdk.calls.clear();
        logged.clear();
        forkCalls.clear();
        messenger.setMockMethodCallHandler(_storeChannel, (call) async {
          throw PlatformException(code: '15', message: 'refused');
        });
        final outcome = await service.purchase(
          package: const OneVpnPurchasePackage(
            identifier: 'monthly',
            term: OneVpnPurchaseTerm.monthly,
            priceString: r'$6.99',
            storeHandle: package,
          ),
          email: 'buyer@example.invalid',
        );
        debugDefaultTargetPlatformOverride = null;
        expect(outcome, isA<OneVpnPurchaseFailed>());
        return List.of(sdk.calls);
      }

      // The identity check only. No finish call and no reset line.
      expect(await buyOn(TargetPlatform.iOS), ['appUserId']);
      expect(forkCalls, isEmpty);
      expect(logged, ['OneVpnPurchase failed reason=unknown code=15']);

      // Anti-vacuity guard. On Android, the finish finds no sheet, and the
      // same refusal resets.
      expect(await buyOn(TargetPlatform.android), contains('logOut'));
      expect(forkCalls, ['finishBillingTasks']);
      expect(logged, contains('OneVpnPurchase reset'));
    });
  });

  group('the reset of pending purchases', () {
    test('configures, then logs the wanted customer out and back in', () async {
      await bridge.logIn('account-a');
      await pumpEventQueue();
      sdk.calls.clear();

      expect(await bridge.resetPurchases(), isTrue);

      expect(wantedAtConfigure, ['account-a', 'account-a']);
      expect(sdk.calls, ['logOut', 'logIn:account-a']);
    });

    test('a failed configure answers false with no SDK call', () async {
      await identity.identify('account-a');
      configures = false;

      expect(await bridge.resetPurchases(), isFalse);

      expect(wantedAtConfigure, ['account-a']);
      expect(sdk.calls, isEmpty);
    });
  });

  group('a store sheet left behind', () {
    /// The fork channel methods the bridge reached for.
    late List<String> forkCalls;

    setUp(() {
      forkCalls = <String>[];
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
    });

    /// A fork channel that answers [found] to every billing task call.
    void forkAnswers(bool found) {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      const fork = MethodChannel(OneVpnPlatformChannel.name);
      messenger.setMockMethodCallHandler(fork, (call) async {
        forkCalls.add(call.method);
        return found;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(fork, null));
    }

    test('a restore on Google Play answers what the billing task call '
        'answers', () async {
      forkAnswers(true);
      expect(await bridge.restorePurchaseSheet(), isTrue);

      forkAnswers(false);
      expect(await bridge.restorePurchaseSheet(), isFalse);

      expect(forkCalls, ['restoreBillingTask', 'restoreBillingTask']);
      // The restore never touches the store or its customer.
      expect(storeCalls, isEmpty);
      expect(sdk.calls, isEmpty);
    });

    test('a restore with no fork channel answers false', () async {
      expect(await bridge.restorePurchaseSheet(), isFalse);
    });

    test('off Google Play, a restore answers false with no call', () async {
      forkAnswers(true);
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      expect(await bridge.restorePurchaseSheet(), isFalse);

      expect(forkCalls, isEmpty);
    });

    /// A store package. Only its type reaches the purchase call.
    const package = Package(
      'monthly',
      PackageType.monthly,
      StoreProduct('monthly', 'Monthly', 'Monthly', 6.99, r'$6.99', 'USD'),
      PresentedOfferingContext('default', null, null),
    );

    /// Starts a purchase that the store answers with a cancel only once
    /// [release] completes.
    Future<OneVpnPurchaseOutcome> heldPurchase(Completer<void> release) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_storeChannel, (call) async {
            storeCalls.add(call.method);
            await release.future;
            throw PlatformException(code: '1', message: 'canceled');
          });
      return bridge.purchasePackage(package);
    }

    test('a finish answers what the billing task call answers', () async {
      forkAnswers(false);
      expect(await bridge.finishPurchaseSheets(), isFalse);

      forkAnswers(true);
      expect(await bridge.finishPurchaseSheets(), isTrue);

      expect(forkCalls, ['finishBillingTasks', 'finishBillingTasks']);
      expect(sdk.calls, isEmpty);
    });

    test('a finish answers once the cancel of the open purchase '
        'lands', () async {
      final release = Completer<void>();
      final earlier = heldPurchase(release);
      await pumpEventQueue();
      forkAnswers(true);

      bool? finished;
      final finish = bridge.finishPurchaseSheets().then(
        (value) => finished = value,
      );
      await pumpEventQueue();
      expect(finished, isNull);

      release.complete();
      await finish;

      expect(finished, isTrue);
      expect(await earlier, isA<OneVpnPurchaseCancelled>());
    });

    testWidgets('a finish answers after 3 s when no cancel lands', (
      tester,
    ) async {
      final release = Completer<void>();
      final earlier = heldPurchase(release);
      await tester.pump();
      forkAnswers(true);

      bool? finished;
      unawaited(
        bridge.finishPurchaseSheets().then((value) => finished = value),
      );
      await tester.pump(const Duration(milliseconds: 2900));
      expect(finished, isNull);
      await tester.pump(const Duration(milliseconds: 100));
      expect(finished, isTrue);

      // Ends the open purchase, so no later test waits on it.
      release.complete();
      await tester.pump();
      expect(await earlier, isA<OneVpnPurchaseCancelled>());
    });

    test('off Google Play, a finish answers false with no call', () async {
      forkAnswers(true);
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      expect(await bridge.finishPurchaseSheets(), isFalse);

      expect(forkCalls, isEmpty);
    });

    test('code 15 with a finished sheet purchases once more and never '
        'resets', () async {
      final service = OneVpnRevenueCatPurchaseService(bridge: bridge);
      await bridge.logIn('account-a');
      await pumpEventQueue();
      sdk.calls.clear();
      forkAnswers(true);
      final codes = ['15', '1'];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_storeChannel, (call) async {
            storeCalls.add(call.method);
            if (call.method != 'purchasePackage') return null;
            throw PlatformException(code: codes.removeAt(0), message: 'x');
          });

      final outcome = await service.purchase(
        package: const OneVpnPurchasePackage(
          identifier: 'monthly',
          term: OneVpnPurchaseTerm.monthly,
          priceString: r'$6.99',
          storeHandle: package,
        ),
        email: 'buyer@example.invalid',
      );

      // The rerun reached the store, and its cancel stands.
      expect(outcome, isA<OneVpnPurchaseCancelled>());
      expect(storeCalls.where((call) => call == 'purchasePackage'), [
        'purchasePackage',
        'purchasePackage',
      ]);
      expect(forkCalls, ['finishBillingTasks']);
      expect(sdk.calls, isNot(contains('logOut')));
    });
  });
}
