// The recurring paywall's twelve-hour throttle.
//
// Two absolutes: never for an entitled user, and never twice inside the
// interval. A stored purchase that waits for its account suppresses it too
// while the account is signed out. A signed-in free account still sees it,
// and the paywall is due again once the record clears. The clock, the
// account state and the preference store are injected, so no test waits on
// real time.
//
// This covers the throttle alone. The trigger and connect-screen suites pin
// who asks it, and when.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/account/session.dart';
import 'package:onexray/onevpn/model/user_data.dart';
import 'package:onexray/onevpn/paywall/paywall_cadence.dart';
import 'package:onexray/onevpn/paywall/pending_purchase.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _buyer = 'buyer@example.invalid';
const _other = 'other@example.invalid';

OneVpnAccountSignedIn _signedIn(String email) => OneVpnAccountSignedIn(
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

void main() {
  late DateTime now;

  OneVpnPaywallCadence cadence() => OneVpnPaywallCadence(now: () => now);

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    now = DateTime.utc(2026, 9, 21, 9);
  });

  test('the interval is twelve hours', () {
    expect(kOneVpnPaywallCadence, const Duration(hours: 12));
    expect(cadence().interval, kOneVpnPaywallCadence);
  });

  test('a fresh install is due, and stamps', () async {
    final controller = cadence();

    // Anti-vacuity: nothing has been stamped yet.
    expect(
      await SharedPreferencesAsync().getInt(OneVpnPaywallCadence.lastShownKey),
      isNull,
    );

    expect(await controller.consumeDue(entitled: false), isTrue);
    expect(
      await SharedPreferencesAsync().getInt(OneVpnPaywallCadence.lastShownKey),
      now.millisecondsSinceEpoch,
    );
  });

  test('a second entry inside the interval is suppressed', () async {
    final controller = cadence();
    expect(await controller.consumeDue(entitled: false), isTrue);

    now = now.add(const Duration(hours: 11, minutes: 59));
    expect(await controller.consumeDue(entitled: false), isFalse);
  });

  test('the boundary is due exactly at twelve hours', () async {
    final controller = cadence();
    expect(await controller.consumeDue(entitled: false), isTrue);

    now = now.add(kOneVpnPaywallCadence);
    expect(await controller.consumeDue(entitled: false), isTrue);
  });

  test('the interval is measured from the last showing', () async {
    final controller = cadence();
    expect(await controller.consumeDue(entitled: false), isTrue);

    now = now.add(const Duration(hours: 13));
    expect(await controller.consumeDue(entitled: false), isTrue);
    // The stamp moves with the showing. The next twelve hours count from
    // here, not from the first showing.
    now = now.add(const Duration(hours: 11));
    expect(await controller.consumeDue(entitled: false), isFalse);
    now = now.add(const Duration(hours: 2));
    expect(await controller.consumeDue(entitled: false), isTrue);
  });

  test('an entitled user is never shown the paywall', () async {
    final controller = cadence();

    expect(await controller.consumeDue(entitled: true), isFalse);
    // A check that shows nothing spends no stamp, so the interval still
    // measures between showings.
    expect(
      await SharedPreferencesAsync().getInt(OneVpnPaywallCadence.lastShownKey),
      isNull,
    );
  });

  test('an entitled user who later downgrades is due at once', () async {
    final controller = cadence();
    expect(await controller.consumeDue(entitled: true), isFalse);

    now = now.add(const Duration(minutes: 1));
    expect(await controller.consumeDue(entitled: false), isTrue);
  });

  group('a purchase that waits for its account', () {
    late ValueNotifier<OneVpnAccountState> account;

    OneVpnPaywallCadence watching() =>
        OneVpnPaywallCadence(now: () => now, account: account);

    setUp(() {
      account = ValueNotifier<OneVpnAccountState>(
        const OneVpnAccountSignedOut(),
      );
    });

    test('suppresses a due paywall while signed out, and the paywall is due '
        'once the record clears', () async {
      final pending = OneVpnPendingPurchase();
      await pending.record(_buyer);
      final controller = watching();

      expect(await controller.consumeDue(entitled: false), isFalse);
      // A suppressed check spends no stamp.
      expect(
        await SharedPreferencesAsync().getInt(
          OneVpnPaywallCadence.lastShownKey,
        ),
        isNull,
      );

      await pending.clear();
      expect(await controller.consumeDue(entitled: false), isTrue);
    });

    test('suppresses a paywall that is due again after its interval', () async {
      final controller = watching();
      expect(await controller.consumeDue(entitled: false), isTrue);
      await OneVpnPendingPurchase().record(_buyer);

      now = now.add(const Duration(hours: 13));
      expect(await controller.consumeDue(entitled: false), isFalse);
    });

    test('shows to a signed-in free account while the record is set', () async {
      await OneVpnPendingPurchase().record(_buyer);
      account.value = _signedIn(_other);

      expect(await watching().consumeDue(entitled: false), isTrue);
    });

    test('stays suppressed after that account signs out', () async {
      await OneVpnPendingPurchase().record(_buyer);
      account.value = _signedIn(_other);
      final controller = watching();
      expect(await controller.consumeDue(entitled: false), isTrue);

      account.value = const OneVpnAccountSignedOut();
      now = now.add(const Duration(hours: 13));
      expect(await controller.consumeDue(entitled: false), isFalse);
    });
  });

  test('a stamp in the future reads as due', () async {
    // The device clock moves backwards. A future stamp never suppresses
    // the paywall until the clock catches up.
    await SharedPreferencesAsync().setInt(
      OneVpnPaywallCadence.lastShownKey,
      now.add(const Duration(days: 400)).millisecondsSinceEpoch,
    );

    expect(await cadence().consumeDue(entitled: false), isTrue);
    expect(
      await SharedPreferencesAsync().getInt(OneVpnPaywallCadence.lastShownKey),
      now.millisecondsSinceEpoch,
    );
  });

  test('the stamp round-trips as an instant', () async {
    // The clock hands back local time. The gap is measured across the
    // store, so what comes back is the instant that went in.
    final grant = DateTime.utc(2026, 9, 21, 9);
    var reading = grant.toLocal();
    final controller = OneVpnPaywallCadence(now: () => reading);

    expect(await controller.consumeDue(entitled: false), isTrue);
    expect(
      await SharedPreferencesAsync().getInt(OneVpnPaywallCadence.lastShownKey),
      grant.millisecondsSinceEpoch,
    );

    // Eleven hours on the same clock is still inside the interval.
    reading = grant.add(const Duration(hours: 11)).toLocal();
    expect(await controller.consumeDue(entitled: false), isFalse);

    // Twelve is due, measured from the stored instant rather than from
    // this process's first check.
    reading = grant.add(kOneVpnPaywallCadence).toLocal();
    expect(await controller.consumeDue(entitled: false), isTrue);
  });
}
