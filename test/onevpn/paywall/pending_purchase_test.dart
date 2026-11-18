// Tests the record of a purchase that waits for an account. A signed-out
// launch with the record answers its address. A dismissal hides it for the
// rest of the run and keeps the record. A session on the purchase address
// clears it, at registration and on a later sign-in, in any case. A session
// on another address leaves it. A store read that finds no subscription for
// the customer that made the purchase clears it. A store that cannot tell
// keeps it, and a record with no customer id asks the store nothing.
// Failing preferences never throw.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/account/session.dart';
import 'package:onexray/onevpn/model/user_data.dart';
import 'package:onexray/onevpn/paywall/pending_purchase.dart';
import 'package:onexray/onevpn/paywall/pending_purchase_record.dart';
import 'package:onexray/onevpn/purchase/fake_purchase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/types.dart';

const _buyer = 'buyer@example.invalid';
const _other = 'other@example.invalid';
const _customer = 'customer-a';

OneVpnAccountSignedIn _signedIn([String email = _buyer]) =>
    OneVpnAccountSignedIn(
      OneVpnSession(
        sessionAuthToken: 'token',
        username: 'someone',
        email: email,
        isPremium: false,
        credentials: const OneVpnCredentials(
          uuid: 'u',
          publicKey: 'p',
          shortId: 's',
        ),
        locations: const <OneVpnApiLocation>[],
      ),
    );

/// Preferences whose string reads, writes and removes all throw.
final class _FailingPreferences extends InMemorySharedPreferencesAsync {
  _FailingPreferences() : super.empty();

  @override
  Future<String?> getString(String key, SharedPreferencesOptions options) =>
      Future<String?>.error(StateError('prefs unavailable'));

  @override
  Future<bool> setString(
    String key,
    String value,
    SharedPreferencesOptions options,
  ) => Future<bool>.error(StateError('prefs unavailable'));

  @override
  Future<bool> clear(
    ClearPreferencesParameters parameters,
    SharedPreferencesOptions options,
  ) => Future<bool>.error(StateError('prefs unavailable'));
}

void main() {
  late OneVpnPendingPurchase pending;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    OneVpnPendingPurchase.resetLaunch();
    pending = OneVpnPendingPurchase();
  });

  Future<String?> launch(OneVpnAccountState state) => pending.dueAtLaunch(
    account: ValueNotifier<OneVpnAccountState>(state),
    restored: Future<void>.value(),
  );

  group('the launch check', () {
    test('a signed-out launch with the record answers its address', () async {
      await pending.record(_buyer);

      expect(await launch(const OneVpnAccountSignedOut()), _buyer);
      // The record is the fork's own key.
      expect(
        await SharedPreferencesAsync().getString(
          OneVpnPendingPurchaseRecord.emailKey,
        ),
        _buyer,
      );
    });

    test('a launch with no record opens the shell', () async {
      expect(await launch(const OneVpnAccountSignedOut()), isNull);
    });

    test('an empty address records nothing', () async {
      await pending.record('');

      expect(await pending.read(), isNull);
    });

    test('a signed-in or unreadable account opens the shell', () async {
      await pending.record(_buyer);

      expect(await launch(_signedIn()), isNull);
      expect(await launch(const OneVpnAccountUnreadable('bad')), isNull);
    });

    test('a restore past the deadline opens the shell and keeps the '
        'record', () async {
      await pending.record(_buyer);

      final address = await pending.dueAtLaunch(
        account: ValueNotifier<OneVpnAccountState>(
          const OneVpnAccountRestoring(),
        ),
        restored: Completer<void>().future,
        restoreDeadline: const Duration(milliseconds: 1),
      );

      expect(address, isNull);
      expect(await pending.read(), _buyer);
    });
  });

  test('the signed-out predicate answers the address only while signed '
      'out', () async {
    await pending.record(_buyer);
    final record = OneVpnPendingPurchaseRecord();

    expect(
      await record.heldWhileSignedOut(const OneVpnAccountSignedOut()),
      _buyer,
    );
    expect(await record.heldWhileSignedOut(_signedIn()), isNull);
    expect(await record.heldWhileSignedOut(_signedIn(_other)), isNull);
    expect(
      await record.heldWhileSignedOut(const OneVpnAccountRestoring()),
      isNull,
    );
    expect(
      await record.heldWhileSignedOut(const OneVpnAccountUnreadable('bad')),
      isNull,
    );
  });

  group('a dismissal', () {
    test('hides the screen for the rest of the run and keeps the '
        'record', () async {
      await pending.record(_buyer);

      OneVpnPendingPurchase.dismissForThisLaunch();

      expect(OneVpnPendingPurchase.dismissedThisLaunch, isTrue);
      expect(await launch(const OneVpnAccountSignedOut()), isNull);
      expect(await pending.read(), _buyer);
    });

    test('ends with the run: the next launch shows the screen again', () async {
      await pending.record(_buyer);
      OneVpnPendingPurchase.dismissForThisLaunch();

      // A new run starts with no dismissal.
      OneVpnPendingPurchase.resetLaunch();

      expect(await launch(const OneVpnAccountSignedOut()), _buyer);
    });
  });

  group('a session', () {
    test('on the purchase address clears the record when adopted '
        'later', () async {
      await pending.record(_buyer);
      final account = ValueNotifier<OneVpnAccountState>(
        const OneVpnAccountSignedOut(),
      );
      pending.follow(account);
      await pumpEventQueue();
      expect(await pending.read(), _buyer);

      account.value = _signedIn();
      await pumpEventQueue();

      expect(await pending.read(), isNull);
      // A later sign-out launch finds nothing to remind of.
      expect(await launch(const OneVpnAccountSignedOut()), isNull);
    });

    test('on the purchase address clears the record at registration', () async {
      await pending.record(_buyer);

      pending.follow(ValueNotifier<OneVpnAccountState>(_signedIn()));
      await pumpEventQueue();

      expect(await pending.read(), isNull);
    });

    test('on the purchase address in another case clears the record', () async {
      await pending.record(_buyer);

      pending.follow(
        ValueNotifier<OneVpnAccountState>(_signedIn(_buyer.toUpperCase())),
      );
      await pumpEventQueue();

      expect(await pending.read(), isNull);
    });

    test('on another address leaves the record for the next signed-out '
        'launch', () async {
      await pending.record(_buyer);
      final account = ValueNotifier<OneVpnAccountState>(_signedIn(_other));
      pending.follow(account);
      await pumpEventQueue();

      expect(await pending.read(), _buyer);

      account.value = const OneVpnAccountSignedOut();
      await pumpEventQueue();
      expect(await launch(const OneVpnAccountSignedOut()), _buyer);
    });
  });

  group('the store read', () {
    test('records the buyer and clears the record with it', () async {
      await pending.record(_buyer, customerId: _customer);

      expect(await pending.readCustomer(), _customer);
      expect(
        await SharedPreferencesAsync().getString(
          OneVpnPendingPurchaseRecord.customerKey,
        ),
        _customer,
      );

      await pending.clear();
      expect(await pending.read(), isNull);
      expect(await pending.readCustomer(), isNull);
    });

    test('no subscription for the buyer clears the record', () async {
      await pending.record(_buyer, customerId: _customer);
      final store = OneVpnFakePurchaseService()..subscribed = false;

      await pending.checkStore(store);

      // The read names the customer that made the purchase.
      expect(store.calls, ['holdsSubscription:$_customer']);
      expect(await pending.read(), isNull);
    });

    test('an active subscription keeps the record', () async {
      await pending.record(_buyer, customerId: _customer);

      await pending.checkStore(OneVpnFakePurchaseService()..subscribed = true);

      expect(await pending.read(), _buyer);
    });

    test('a store that cannot tell keeps the record', () async {
      await pending.record(_buyer, customerId: _customer);

      await pending.checkStore(OneVpnFakePurchaseService());

      expect(await pending.read(), _buyer);
    });

    test('a record with no customer id keeps the record and asks the store '
        'nothing', () async {
      // A record written before the buyer's id was stored.
      await pending.record(_buyer);
      final store = OneVpnFakePurchaseService()..subscribed = false;

      await pending.checkStore(store);

      expect(store.calls, isEmpty);
      expect(await pending.read(), _buyer);
    });

    test(
      'a record written again with no customer id drops the old one',
      () async {
        await pending.record(_buyer, customerId: _customer);
        await pending.record(_buyer);

        expect(await pending.readCustomer(), isNull);
      },
    );

    test('a throwing store keeps the record', () async {
      await pending.record(_buyer, customerId: _customer);

      await pending.checkStore(_ThrowingStore());

      expect(await pending.read(), _buyer);
    });
  });

  test('failing preferences never throw and read as no record', () async {
    // The store binds the platform instance at construction.
    SharedPreferencesAsyncPlatform.instance = _FailingPreferences();
    final failing = OneVpnPendingPurchase(
      preferences: SharedPreferencesAsync(),
    );

    await failing.record(_buyer);
    await failing.clear();

    expect(await failing.read(), isNull);
    expect(
      await failing.dueAtLaunch(
        account: ValueNotifier<OneVpnAccountState>(
          const OneVpnAccountSignedOut(),
        ),
        restored: Future<void>.value(),
      ),
      isNull,
    );
  });
}

/// A store whose subscription read throws.
class _ThrowingStore extends OneVpnFakePurchaseService {
  @override
  Future<bool?> holdsSubscription(String customerId) =>
      Future<bool?>.error(StateError('store unavailable'));
}
