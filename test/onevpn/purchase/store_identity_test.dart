// The store identity state. A recording SDK stands in for the store. The
// tests pin when a request reaches the SDK, the anonymous guard on log out,
// the check before a purchase, the reset of pending purchases, and that no
// SDK failure escapes.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/purchase/revenuecat_purchase_service.dart';

import 'store_identity_support.dart';

void main() {
  late RecordingIdentitySdk sdk;
  late OneVpnStoreIdentity identity;

  setUp(() {
    sdk = RecordingIdentitySdk();
    identity = OneVpnStoreIdentity(sdk: sdk);
  });

  group('before the store is configured', () {
    test('a request only records the wanted customer', () async {
      await identity.identify('account-a');

      expect(sdk.calls, isEmpty);
      expect(identity.appUserId, 'account-a');
    });

    test('the configure applies the recorded customer', () async {
      await identity.identify('account-a');

      await identity.markReady();

      expect(sdk.calls, ['appUserId', 'logIn:account-a']);
    });

    test('the configure applies the latest request only', () async {
      await identity.identify('account-a');
      await identity.forget();
      await identity.identify('account-b');

      await identity.markReady();

      expect(sdk.calls, ['appUserId', 'logIn:account-b']);
    });

    test('a forget recorded before the configure logs an identified '
        'customer out', () async {
      sdk.anonymous = false;
      await identity.forget();

      await identity.markReady();

      expect(sdk.calls, ['isAnonymous', 'logOut']);
    });

    test('a configure with no request calls nothing', () async {
      await identity.markReady();

      expect(sdk.calls, isEmpty);
    });
  });

  group('after the store is configured', () {
    setUp(() => identity.markReady());

    test('applying the id the SDK already holds makes no log in', () async {
      sdk.appUserIdValue = 'account-a';

      await identity.identify('account-a');

      expect(sdk.calls, ['appUserId']);
    });

    test('applying a different id logs in', () async {
      sdk.appUserIdValue = 'account-a';

      await identity.identify('account-b');

      expect(sdk.calls, ['appUserId', 'logIn:account-b']);
    });

    test('identify logs in at once', () async {
      await identity.identify('account-a');

      expect(sdk.calls, ['appUserId', 'logIn:account-a']);
    });

    test('forget logs an identified customer out', () async {
      await identity.identify('account-a');
      sdk.calls.clear();

      await identity.forget();

      expect(sdk.calls, ['isAnonymous', 'logOut']);
      expect(identity.appUserId, isNull);
    });

    test('forget on an anonymous customer calls nothing more', () async {
      await identity.forget();

      expect(sdk.calls, ['isAnonymous']);
    });

    test('requests apply one at a time, in order', () async {
      final hold = Completer<void>();
      sdk.holdLogIn = hold;

      final first = identity.identify('account-a');
      final second = identity.forget();
      await pumpEventQueue();
      expect(sdk.calls, ['appUserId', 'logIn:account-a']);

      hold.complete();
      await Future.wait<void>(<Future<void>>[first, second]);

      expect(sdk.calls, [
        'appUserId',
        'logIn:account-a',
        'isAnonymous',
        'logOut',
      ]);
    });

    test('a throwing SDK never surfaces and the next request still '
        'applies', () async {
      sdk.throwOnLogIn = true;
      await expectLater(identity.identify('account-a'), completes);

      sdk
        ..throwOnLogIn = false
        ..anonymous = false
        ..throwOnLogOut = true;
      await expectLater(identity.forget(), completes);

      sdk.throwOnLogOut = false;
      await identity.identify('account-b');

      expect(sdk.calls, [
        'appUserId',
        'logIn:account-a',
        'isAnonymous',
        'logOut',
        'appUserId',
        'logIn:account-b',
      ]);
    });
  });

  group('the check before a purchase', () {
    setUp(() => identity.markReady());

    test('a stale identified customer logs in with the wanted id', () async {
      await identity.identify('account-b');
      sdk.appUserIdValue = 'account-a';
      sdk.calls.clear();

      expect(await identity.assertForPurchase(), isTrue);
      expect(sdk.calls, ['appUserId', 'logIn:account-b']);
    });

    test('an identified customer with no request logs out', () async {
      // A log out that failed before the app was killed leaves the store
      // identified on a signed-out launch.
      sdk.anonymous = false;

      expect(await identity.assertForPurchase(), isTrue);
      expect(sdk.calls, ['isAnonymous', 'logOut']);
    });

    test('a matching customer costs one read', () async {
      await identity.identify('account-a');
      sdk.calls.clear();

      expect(await identity.assertForPurchase(), isTrue);
      expect(sdk.calls, ['appUserId']);
    });

    test('an anonymous customer with no id wanted costs one read', () async {
      expect(await identity.assertForPurchase(), isTrue);
      expect(sdk.calls, ['isAnonymous']);
    });

    test('any SDK failure answers false without throwing', () async {
      sdk.throwOnAppUserId = true;
      await identity.identify('account-a');
      expect(await identity.assertForPurchase(), isFalse);

      sdk
        ..throwOnAppUserId = false
        ..appUserIdValue = 'account-z'
        ..throwOnLogIn = true;
      expect(await identity.assertForPurchase(), isFalse);

      sdk
        ..throwOnLogIn = false
        ..anonymous = false
        ..throwOnLogOut = true;
      await identity.forget();
      expect(await identity.assertForPurchase(), isFalse);
    });

    test('the check runs after a request still in flight', () async {
      final hold = Completer<void>();
      sdk.holdLogIn = hold;
      final pending = identity.identify('account-a');
      final checked = identity.assertForPurchase();
      await pumpEventQueue();
      expect(sdk.calls, ['appUserId', 'logIn:account-a']);

      hold.complete();
      await pending;

      expect(await checked, isTrue);
      expect(sdk.calls, ['appUserId', 'logIn:account-a', 'appUserId']);
    });
  });

  group('the reset of pending purchases', () {
    setUp(() => identity.markReady());

    test('logs the store customer out, then in as the wanted '
        'customer', () async {
      await identity.identify('account-a');
      sdk.calls.clear();

      expect(await identity.reset(), isTrue);

      expect(sdk.calls, ['logOut', 'logIn:account-a']);
      expect(sdk.appUserIdValue, 'account-a');
    });

    test('with no customer wanted, answers false and calls nothing', () async {
      expect(await identity.reset(), isFalse);
      expect(sdk.calls, isEmpty);

      // Anti-vacuity guard. A wanted customer resets.
      await identity.identify('account-a');
      sdk.calls.clear();
      expect(await identity.reset(), isTrue);
      expect(sdk.calls, ['logOut', 'logIn:account-a']);
    });

    test('a sign-out recorded during the reset applies after it, and the '
        'reset answers false', () async {
      await identity.identify('account-a');
      sdk.calls.clear();
      final hold = Completer<void>();
      sdk.holdLogIn = hold;

      final reset = identity.reset();
      await pumpEventQueue();
      expect(sdk.calls, ['logOut', 'logIn:account-a']);
      final signedOut = identity.forget();
      hold.complete();

      expect(await reset, isFalse);
      await signedOut;
      expect(sdk.calls, ['logOut', 'logIn:account-a', 'isAnonymous', 'logOut']);
      expect(sdk.anonymous, isTrue);
    });

    test('a sign-out recorded before a queued reset runs leaves the reset '
        'with no SDK call', () async {
      // An earlier apply holds the queue in its log in.
      final hold = Completer<void>();
      sdk.holdLogIn = hold;
      final applying = identity.identify('account-a');
      await pumpEventQueue();
      expect(sdk.calls, ['appUserId', 'logIn:account-a']);

      final reset = identity.reset();
      final signedOut = identity.forget();
      hold.complete();

      expect(await reset, isFalse);
      await applying;
      await signedOut;
      // No log in of the signed-out customer after the sign-out.
      expect(sdk.calls, [
        'appUserId',
        'logIn:account-a',
        'isAnonymous',
        'logOut',
      ]);
      expect(sdk.anonymous, isTrue);
    });
  });
}
