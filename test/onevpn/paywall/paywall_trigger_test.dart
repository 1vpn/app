// The recurring paywall's trigger: what the connect screen asks, and when.
//
// Three rules carry it. The session restore is awaited before anything is
// decided. The route has to still be topmost when the showing lands. The
// cadence answers at most once per interval.
//
// The audience and the clock are both injected, so no test waits on real
// time or a real screen.

import 'dart:async';

// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/account/credential_store.dart';
import 'package:onexray/onevpn/account/session.dart';
import 'package:onexray/onevpn/model/user_data.dart';
import 'package:onexray/onevpn/paywall/paywall_cadence.dart';
import 'package:onexray/onevpn/paywall/paywall_trigger.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// An audience whose restore the test opens by hand.
class _Audience implements OneVpnPaywallAudience {
  _Audience({this.entitled = false});

  final Completer<void> restore = Completer<void>();

  @override
  bool entitled;

  @override
  Future<void> whenRestored() => restore.future;
}

OneVpnSession _session({bool isPremium = false, DateTime? pendingSince}) =>
    OneVpnSession(
      sessionAuthToken: 'token',
      username: 'someone',
      email: 'someone@example.invalid',
      isPremium: isPremium,
      credentials: const OneVpnCredentials(
        uuid: 'u',
        publicKey: 'p',
        shortId: 's',
      ),
      locations: const <OneVpnApiLocation>[],
      premiumPendingSince: pendingSince,
    );

void main() {
  late DateTime now;
  late int shown;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    now = DateTime.utc(2026, 9, 21, 9);
    shown = 0;
  });

  OneVpnPaywallTrigger trigger(OneVpnPaywallAudience audience) =>
      OneVpnPaywallTrigger(
        cadence: OneVpnPaywallCadence(now: () => now),
        audience: audience,
      );

  Future<bool> run(OneVpnPaywallTrigger subject, {bool topmost = true}) =>
      subject.run(isTopmost: () => topmost, show: () => shown++);

  test('nothing is shown while the session is still restoring', () async {
    final audience = _Audience();
    final subject = trigger(audience);

    final pending = run(subject);
    await pumpEventQueue();

    // A premium account reads as signed out until the store answers. A
    // showing in that gap goes to someone who has already paid.
    expect(shown, 0);

    audience.restore.complete();
    expect(await pending, isTrue);
    expect(shown, 1);
  });

  test('a due free session is shown the paywall exactly once', () async {
    final audience = _Audience()..restore.complete();
    final subject = trigger(audience);

    expect(await run(subject), isTrue);
    expect(await run(subject), isFalse);
    expect(shown, 1);

    // Due again only once the interval has passed.
    now = now.add(kOneVpnPaywallCadence);
    expect(await run(subject), isTrue);
    expect(shown, 2);
  });

  test('an entitled session is shown nothing, and spends no stamp', () async {
    final audience = _Audience(entitled: true)..restore.complete();
    final subject = trigger(audience);

    expect(await run(subject), isFalse);
    expect(shown, 0);

    // The interval measures between showings, so a downgrade is due at
    // once.
    audience.entitled = false;
    now = now.add(const Duration(minutes: 1));
    expect(await run(subject), isTrue);
    expect(shown, 1);
  });

  test('a route that is no longer topmost is shown nothing', () async {
    final audience = _Audience()..restore.complete();
    final subject = trigger(audience);

    expect(await run(subject, topmost: false), isFalse);
    expect(shown, 0);

    // The run spends no stamp, so the first moment the screen is back on
    // top is still due.
    expect(await run(subject), isTrue);
    expect(shown, 1);
  });

  test('a route left during the restore is shown nothing', () async {
    final audience = _Audience();
    var topmost = true;
    final subject = trigger(audience);

    final pending = subject.run(isTopmost: () => topmost, show: () => shown++);
    // The user opens the picker before the restore lands.
    topmost = false;
    audience.restore.complete();

    expect(await pending, isFalse);
    expect(shown, 0);
  });

  test('two overlapping runs show the paywall once', () async {
    final audience = _Audience();
    final subject = trigger(audience);

    // Entry and a resume can both be in flight. Two showings would spend
    // one due window twice.
    final first = run(subject);
    final second = run(subject);
    audience.restore.complete();

    expect(await first, isTrue);
    expect(await second, isFalse);
    expect(shown, 1);
  });

  group('the account-service audience', () {
    Future<OneVpnPaywallAudience> audienceFor(OneVpnSession? session) async {
      final store = OneVpnEphemeralCredentialStore();
      if (session != null) await store.write(session);
      final service = OneVpnAccountService(store: store);
      final audience = OneVpnServicePaywallAudience(service: service);
      await audience.whenRestored();
      return audience;
    }

    test('a signed-out session is not entitled', () async {
      expect((await audienceFor(null)).entitled, isFalse);
    });

    test('a free session is not entitled', () async {
      expect((await audienceFor(_session())).entitled, isFalse);
    });

    test('a premium session is entitled', () async {
      expect((await audienceFor(_session(isPremium: true))).entitled, isTrue);
    });

    test('a pending grant counts as entitled', () async {
      // The buyer has paid, and the server has yet to confirm. The paywall
      // never asks again inside that window.
      final audience = await audienceFor(
        _session(pendingSince: DateTime.utc(2026, 9, 21, 8)),
      );

      expect(audience.entitled, isTrue);
    });
  });

  group('the launch check', () {
    test(
      'a first launch for a free user is due and spends the window',
      () async {
        final audience = _Audience()..restore.complete();
        final subject = trigger(audience);

        expect(await subject.dueAtLaunch(), isTrue);
        // The connect screen's entry check then finds nothing due.
        expect(await run(subject), isFalse);
        expect(shown, 0);
      },
    );

    test('an entitled account is never due', () async {
      final audience = _Audience(entitled: true)..restore.complete();
      expect(await trigger(audience).dueAtLaunch(), isFalse);
    });

    test('a launch inside the interval is not due', () async {
      final audience = _Audience()..restore.complete();
      expect(await trigger(audience).dueAtLaunch(), isTrue);
      now = now.add(const Duration(hours: 1));
      expect(await trigger(audience).dueAtLaunch(), isFalse);
    });

    test(
      'a restore past the deadline answers false and spends nothing',
      () async {
        final audience = _Audience();
        final subject = trigger(audience);

        expect(
          await subject.dueAtLaunch(restoreDeadline: Duration.zero),
          isFalse,
        );
        audience.restore.complete();
        expect(await run(subject), isTrue);
        expect(shown, 1);
      },
    );

    test('the restore deadline is 2s', () {
      expect(kOneVpnLaunchPaywallRestoreDeadline, const Duration(seconds: 2));
    });

    for (final (settle, due) in [
      (const Duration(milliseconds: 1900), true),
      (const Duration(milliseconds: 2100), false),
    ]) {
      test('a restore that settles at ${settle.inMilliseconds}ms answers '
          '$due', () {
        fakeAsync((async) {
          final audience = _Audience();
          final subject = trigger(audience);
          bool? answer;
          subject.dueAtLaunch().then((value) => answer = value);
          async.elapse(settle);
          audience.restore.complete();
          async.flushMicrotasks();
          expect(answer, due);

          // Only a due answer stamps the cadence.
          bool? dueAgain;
          subject.cadence
              .consumeDue(entitled: false)
              .then((value) => dueAgain = value);
          async.flushMicrotasks();
          expect(dueAgain, !due);
        });
      });
    }
  });
}
