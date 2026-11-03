// The purchase seam. A recording bridge with no store SDK drives the real
// service. The tests pin the setEmail-before-purchase ordering, the outcome
// passthrough, the identity calls, and the identity check before a
// purchase. An unfinished purchase first finishes the sheets an earlier
// purchase left behind and runs once more, with no reset. With no sheet
// left, it resets the store customer once and runs again, signed in only. A
// sheet restore asks the bridge. The clean-room fake serves canned
// offerings and scripted outcomes.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/purchase/fake_purchase_service.dart';
import 'package:onexray/onevpn/purchase/purchase_service.dart';
import 'package:onexray/onevpn/purchase/revenuecat_purchase_service.dart';

import 'store_identity_support.dart';

/// A store bridge that records call order and never touches the SDK.
class _RecordingBridge implements OneVpnRevenueCatBridge {
  _RecordingBridge({
    this.offeringsResult = const OneVpnOfferingsUnavailable(),
    this.outcome = const OneVpnPurchaseSucceeded(),
  });

  OneVpnOfferingsResult offeringsResult;
  OneVpnPurchaseOutcome outcome;

  /// The outcomes [purchasePackage] answers first, one per call. [outcome]
  /// answers once they run out.
  final List<OneVpnPurchaseOutcome> outcomes = <OneVpnPurchaseOutcome>[];

  /// When true, the identity calls throw.
  bool throwOnIdentity = false;

  final List<String> calls = <String>[];
  String? email;
  Object? handle;

  @override
  Future<OneVpnOfferingsResult> loadOfferings() async {
    calls.add('loadOfferings');
    return offeringsResult;
  }

  @override
  Future<void> setEmail(String email) async {
    calls.add('setEmail');
    this.email = email;
  }

  @override
  Future<OneVpnPurchaseOutcome> purchasePackage(Object? storeHandle) async {
    calls.add('purchasePackage');
    handle = storeHandle;
    return outcomes.isEmpty ? outcome : outcomes.removeAt(0);
  }

  @override
  Future<bool> resetPurchases() async {
    calls.add('resetPurchases');
    return true;
  }

  /// The answer [restorePurchaseSheet] gives.
  bool sheetRestored = false;

  @override
  Future<bool> restorePurchaseSheet() async {
    calls.add('restorePurchaseSheet');
    return sheetRestored;
  }

  /// The answer [finishPurchaseSheets] gives.
  bool sheetsFinished = false;

  @override
  Future<bool> finishPurchaseSheets() async {
    calls.add('finishPurchaseSheets');
    return sheetsFinished;
  }

  @override
  Future<void> logIn(String appUserId) async {
    calls.add('logIn:$appUserId');
    if (throwOnIdentity) throw StateError('logIn sabotaged');
  }

  @override
  Future<void> logOut() async {
    calls.add('logOut');
    if (throwOnIdentity) throw StateError('logOut sabotaged');
  }

  /// Matches without a store call, so the order pins read only the
  /// purchase steps.
  @override
  Future<bool> assertIdentity() async => true;
}

/// A recording bridge whose identity check runs the real identity state
/// over a recording SDK. Both write into one call log.
class _IdentityBridge extends _RecordingBridge {
  _IdentityBridge() {
    sdk = RecordingIdentitySdk(calls);
    identity = OneVpnStoreIdentity(sdk: sdk);
  }

  late final RecordingIdentitySdk sdk;
  late final OneVpnStoreIdentity identity;

  @override
  Future<void> logIn(String appUserId) => identity.identify(appUserId);

  @override
  Future<bool> assertIdentity() => identity.assertForPurchase();

  @override
  Future<bool> resetPurchases() => identity.reset();
}

const _package = OneVpnPurchasePackage(
  identifier: 'yearly',
  term: OneVpnPurchaseTerm.yearly,
  priceString: r'$39.99',
  storeHandle: 'handle',
);

const _unfinished = OneVpnPurchaseFailed(
  'purchase failed',
  reason: OneVpnPurchaseFailureReason.unfinished,
);

void main() {
  group('OneVpnRevenueCatPurchaseService', () {
    test('sets the email before purchasing the package', () async {
      final bridge = _RecordingBridge();
      final service = OneVpnRevenueCatPurchaseService(bridge: bridge);

      await service.purchase(package: _package, email: 'buyer@example.invalid');

      expect(bridge.calls, ['setEmail', 'purchasePackage']);
      expect(bridge.email, 'buyer@example.invalid');
      expect(bridge.handle, 'handle');
    });

    group('the identity check before a purchase', () {
      late _IdentityBridge bridge;
      late OneVpnRevenueCatPurchaseService service;

      setUp(() async {
        bridge = _IdentityBridge();
        service = OneVpnRevenueCatPurchaseService(bridge: bridge);
        await bridge.identity.markReady();
      });

      Future<OneVpnPurchaseOutcome> buy() =>
          service.purchase(package: _package, email: 'buyer@example.invalid');

      test('a stale identified customer logs in with the wanted id before '
          'the email is set', () async {
        await bridge.identity.identify('account-b');
        bridge.sdk.appUserIdValue = 'account-a';
        bridge.calls.clear();

        await buy();

        expect(bridge.calls, [
          'appUserId',
          'logIn:account-b',
          'setEmail',
          'purchasePackage',
        ]);
      });

      test('a signed-out purchase on an identified customer logs out before '
          'the email is set', () async {
        bridge.sdk.anonymous = false;

        await buy();

        expect(bridge.calls, [
          'isAnonymous',
          'logOut',
          'setEmail',
          'purchasePackage',
        ]);
      });

      test('a matching customer makes no extra call', () async {
        await bridge.identity.identify('account-a');
        bridge.calls.clear();

        await buy();

        expect(bridge.calls, ['appUserId', 'setEmail', 'purchasePackage']);
      });

      test('an id the store refuses fails the check rather than purchase on '
          'the previous customer', () async {
        await service.identify('account-a');
        bridge.sdk.refuses = (appUserId) => appUserId.contains('/');
        await service.identify('bad/id');
        bridge.calls.clear();

        final outcome = await buy();

        expect(bridge.sdk.appUserIdValue, 'account-a');
        expect(outcome, isA<OneVpnPurchaseFailed>());
        expect((outcome as OneVpnPurchaseFailed).detail, 'purchase failed');
        expect(bridge.calls, ['appUserId', 'logIn:bad/id']);
      });

      test(
        'a failed check returns the store error and never purchases',
        () async {
          await bridge.identity.identify('account-b');
          bridge.sdk
            ..appUserIdValue = 'account-a'
            ..throwOnLogIn = true;
          bridge.calls.clear();

          final outcome = await buy();

          expect(outcome, isA<OneVpnPurchaseFailed>());
          expect((outcome as OneVpnPurchaseFailed).detail, 'purchase failed');
          expect(bridge.calls, ['appUserId', 'logIn:account-b']);
        },
      );
    });

    group('an unfinished purchase', () {
      late _IdentityBridge bridge;
      late OneVpnRevenueCatPurchaseService service;

      /// The lines the service logged during the test.
      late List<String> logged;

      setUp(() async {
        bridge = _IdentityBridge();
        service = OneVpnRevenueCatPurchaseService(bridge: bridge);
        await bridge.identity.markReady();
        logged = <String>[];
        final previous = debugPrint;
        debugPrint = (message, {wrapWidth}) => logged.add(message ?? '');
        addTearDown(() => debugPrint = previous);
      });

      Future<OneVpnPurchaseOutcome> buy() =>
          service.purchase(package: _package, email: 'buyer@example.invalid');

      test('signed in with no sheet left behind, resets the store customer '
          'once and purchases again', () async {
        await bridge.identity.identify('account-a');
        bridge.calls.clear();
        bridge.outcomes.add(_unfinished);

        final outcome = await buy();

        expect(outcome, isA<OneVpnPurchaseSucceeded>());
        expect(bridge.calls, [
          'appUserId',
          'setEmail',
          'purchasePackage',
          'finishPurchaseSheets',
          'logOut',
          'logIn:account-a',
          'appUserId',
          'setEmail',
          'purchasePackage',
        ]);
        // One line for the reset. It names no customer.
        expect(logged, ['OneVpnPurchase reset']);
      });

      test('a second unfinished outcome ends unfinished with no third '
          'purchase', () async {
        await bridge.identity.identify('account-a');
        bridge.calls.clear();
        bridge.outcomes.addAll([_unfinished, _unfinished]);

        final outcome = await buy();

        expect(outcome, isA<OneVpnPurchaseFailed>());
        expect(
          (outcome as OneVpnPurchaseFailed).reason,
          OneVpnPurchaseFailureReason.unfinished,
        );
        expect(bridge.calls.where((call) => call == 'purchasePackage'), [
          'purchasePackage',
          'purchasePackage',
        ]);
        expect(bridge.calls.where((call) => call == 'logOut'), ['logOut']);
      });

      test('signed out, never resets', () async {
        bridge.outcomes.add(_unfinished);

        final outcome = await buy();

        expect(
          (outcome as OneVpnPurchaseFailed).reason,
          OneVpnPurchaseFailureReason.unfinished,
        );
        expect(bridge.calls, [
          'isAnonymous',
          'setEmail',
          'purchasePackage',
          'finishPurchaseSheets',
        ]);
        expect(logged, isEmpty);

        // Anti-vacuity guard. The same outcome signed in resets.
        await bridge.identity.identify('account-a');
        bridge.calls.clear();
        bridge.outcomes.add(_unfinished);
        await buy();
        expect(bridge.calls, contains('logOut'));
      });

      test('a finished sheet runs the purchase once more with no '
          'reset', () async {
        await bridge.identity.identify('account-a');
        bridge
          ..calls.clear()
          ..sheetsFinished = true
          ..outcomes.add(_unfinished);

        final outcome = await buy();

        expect(outcome, isA<OneVpnPurchaseSucceeded>());
        expect(bridge.calls, [
          'appUserId',
          'setEmail',
          'purchasePackage',
          'finishPurchaseSheets',
          'appUserId',
          'setEmail',
          'purchasePackage',
        ]);
        expect(logged, isEmpty);
      });

      test('after a finished sheet, a second unfinished outcome stands with '
          'no reset', () async {
        await bridge.identity.identify('account-a');
        bridge
          ..calls.clear()
          ..sheetsFinished = true
          ..outcomes.addAll([_unfinished, _unfinished]);

        final outcome = await buy();

        expect(
          (outcome as OneVpnPurchaseFailed).reason,
          OneVpnPurchaseFailureReason.unfinished,
        );
        expect(bridge.calls.where((call) => call == 'purchasePackage'), [
          'purchasePackage',
          'purchasePackage',
        ]);
        expect(bridge.calls, isNot(contains('logOut')));
        expect(logged, isEmpty);
      });

      test('signed out, a finished sheet still runs the purchase once '
          'more', () async {
        bridge
          ..sheetsFinished = true
          ..outcomes.add(_unfinished);

        final outcome = await buy();

        expect(outcome, isA<OneVpnPurchaseSucceeded>());
        expect(bridge.calls, [
          'isAnonymous',
          'setEmail',
          'purchasePackage',
          'finishPurchaseSheets',
          'isAnonymous',
          'setEmail',
          'purchasePackage',
        ]);
      });
    });

    test('passes a success outcome through', () async {
      final bridge = _RecordingBridge(outcome: const OneVpnPurchaseSucceeded());
      final service = OneVpnRevenueCatPurchaseService(bridge: bridge);
      final outcome = await service.purchase(
        package: _package,
        email: 'buyer@example.invalid',
      );
      expect(outcome, isA<OneVpnPurchaseSucceeded>());
    });

    test('passes a cancellation through', () async {
      final bridge = _RecordingBridge(outcome: const OneVpnPurchaseCancelled());
      final service = OneVpnRevenueCatPurchaseService(bridge: bridge);
      final outcome = await service.purchase(
        package: _package,
        email: 'buyer@example.invalid',
      );
      expect(outcome, isA<OneVpnPurchaseCancelled>());
    });

    test('passes a failure through', () async {
      final bridge = _RecordingBridge(
        outcome: const OneVpnPurchaseFailed('nope'),
      );
      final service = OneVpnRevenueCatPurchaseService(bridge: bridge);
      final outcome = await service.purchase(
        package: _package,
        email: 'buyer@example.invalid',
      );
      expect(outcome, isA<OneVpnPurchaseFailed>());
    });

    test('delegates loadOfferings to the bridge', () async {
      const offerings = OneVpnOfferings(yearly: _package);
      final bridge = _RecordingBridge(
        offeringsResult: const OneVpnOfferingsLoaded(offerings),
      );
      final service = OneVpnRevenueCatPurchaseService(bridge: bridge);
      final loaded = await service.loadOfferings();
      expect(loaded, isA<OneVpnOfferingsLoaded>());
      expect((loaded as OneVpnOfferingsLoaded).offerings, same(offerings));
      expect(bridge.calls, ['loadOfferings']);
    });

    test('identify logs the store customer in', () async {
      final bridge = _RecordingBridge();
      final service = OneVpnRevenueCatPurchaseService(bridge: bridge);

      await service.identify('account@example.invalid');

      expect(bridge.calls, ['logIn:account@example.invalid']);
    });

    test('forget logs the store customer out', () async {
      final bridge = _RecordingBridge();
      final service = OneVpnRevenueCatPurchaseService(bridge: bridge);

      await service.forget();

      expect(bridge.calls, ['logOut']);
    });

    test('a sheet restore asks the bridge and answers its reply', () async {
      final bridge = _RecordingBridge()..sheetRestored = true;
      final service = OneVpnRevenueCatPurchaseService(bridge: bridge);

      expect(await service.restorePurchaseSheet(), isTrue);
      expect(bridge.calls, ['restorePurchaseSheet']);

      bridge.sheetRestored = false;
      expect(await service.restorePurchaseSheet(), isFalse);
    });

    test('a throwing bridge never surfaces from identify or forget', () async {
      final bridge = _RecordingBridge()..throwOnIdentity = true;
      final service = OneVpnRevenueCatPurchaseService(bridge: bridge);

      await expectLater(service.identify('account@example.invalid'), completes);
      await expectLater(service.forget(), completes);
      expect(bridge.calls, ['logIn:account@example.invalid', 'logOut']);
    });
  });

  group('OneVpnFakePurchaseService', () {
    test('returns canned offerings for both terms by default', () async {
      final result = await OneVpnFakePurchaseService().loadOfferings();
      expect(result, isA<OneVpnOfferingsLoaded>());
      final offerings = (result as OneVpnOfferingsLoaded).offerings;
      expect(offerings.yearly, isNotNull);
      expect(offerings.monthly, isNotNull);
      expect(offerings.yearly!.priceString, isNotEmpty);
    });

    test(
      'returns the scripted failure when offerings are unavailable',
      () async {
        final fake = OneVpnFakePurchaseService(offeringsAvailable: false);
        expect(await fake.loadOfferings(), isA<OneVpnOfferingsUnavailable>());
        fake.loadFailure = const OneVpnOfferingsUnreachable();
        expect(await fake.loadOfferings(), isA<OneVpnOfferingsUnreachable>());
      },
    );

    test(
      'records the email and package and returns the scripted outcome',
      () async {
        final fake = OneVpnFakePurchaseService(
          outcome: const OneVpnPurchaseCancelled(),
        );
        final outcome = await fake.purchase(
          package: _package,
          email: 'buyer@example.invalid',
        );
        expect(outcome, isA<OneVpnPurchaseCancelled>());
        expect(fake.lastEmail, 'buyer@example.invalid');
        expect(fake.lastPackage, same(_package));
        expect(fake.calls, contains('purchase'));
      },
    );

    test('records identify and forget in the call log', () async {
      final fake = OneVpnFakePurchaseService();

      await fake.identify('account@example.invalid');
      await fake.forget();

      expect(fake.calls, ['identify:account@example.invalid', 'forget']);
      expect(fake.lastAppUserId, 'account@example.invalid');
    });
  });
}
