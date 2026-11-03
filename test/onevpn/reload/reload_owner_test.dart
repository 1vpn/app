// Pins the reload owner: the single reactor to account-state change that
// re-provisions the catalogue. It is the in-session trigger for
// re-provisioning. It re-provisions only on a settled transition that
// changes the dialable set. Those transitions are a sign-in, a tier flip, a
// changed location set, and account rows turning dialable. The premium hook
// runs once the account rows turn dialable. A token rotation, the Restoring
// state, and the sign-out transition all leave it silent. The owner logs what
// each reprovision reports. The selection check runs on sign-out, after every
// reprovision, failed or not, and once through checkSelection. A change to
// the account's full location list counts as a change.
// A failed reprovision is retried on the next settled change.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/account/session.dart';
import 'package:onexray/onevpn/model/user_data.dart';
import 'package:onexray/onevpn/provision/node_provisioner.dart';
import 'package:onexray/onevpn/reload/reload_owner.dart';

import '../account/support.dart';

/// A reprovision that wrote nothing and reported nothing.
const _provisioned = OneVpnProvisionResult(nodes: [], errors: []);

void main() {
  late ValueNotifier<OneVpnAccountState> accountState;
  late List<OneVpnSession?> reprovisioned;

  OneVpnReloadOwner build(OneVpnAccountState initial) {
    accountState = ValueNotifier<OneVpnAccountState>(initial);
    reprovisioned = <OneVpnSession?>[];
    return OneVpnReloadOwner(
      accountState: accountState,
      reprovision: (session) async {
        reprovisioned.add(session);
        return _provisioned;
      },
    );
  }

  final premium = OneVpnAccountSignedIn(testSession(isPremium: true));

  tearDown(() => accountState.dispose());

  test('a sign-in re-provisions with the new session', () {
    build(const OneVpnAccountSignedOut()).register();

    accountState.value = premium;

    expect(reprovisioned, hasLength(1));
    expect(reprovisioned.single, premium.session);
  });

  test('a token rotation with the same tier and locations does not '
      're-provision', () {
    build(premium).register();

    // A refresh that only rotates the credential: same tier, same
    // locations, new token.
    accountState.value = OneVpnAccountSignedIn(
      testSession(isPremium: true, token: 'token-new'),
    );

    expect(reprovisioned, isEmpty);
  });

  test('a tier flip re-provisions', () {
    build(premium).register();

    accountState.value = OneVpnAccountSignedIn(testSession(isPremium: false));

    expect(reprovisioned, hasLength(1));
  });

  test('a changed location set with the same presence and tier '
      're-provisions', () {
    build(premium).register();

    // Same signed-in presence and premium tier, a different connectable
    // set. The location set alone drives the rebuild.
    accountState.value = OneVpnAccountSignedIn(
      testSession(
        isPremium: true,
        locations: const <OneVpnApiLocation>[
          OneVpnApiLocation(
            country: 'Otherland',
            countryCode: 'OL',
            servers: <OneVpnApiServer>[
              OneVpnApiServer(host: 'b.example.invalid'),
            ],
          ),
        ],
      ),
    );

    expect(reprovisioned, hasLength(1));
  });

  test('the Restoring state never re-provisions', () {
    build(const OneVpnAccountSignedOut()).register();

    accountState.value = const OneVpnAccountRestoring();

    expect(reprovisioned, isEmpty);
  });

  test('the sign-out transition does not re-provision', () {
    // The account service sweep owns sign-out and runs after the state
    // flips, so re-provisioning here would race it. The free floor stands.
    build(premium).register();

    accountState.value = const OneVpnAccountSignedOut();

    expect(reprovisioned, isEmpty);
  });

  test('register captures the baseline and is idempotent', () {
    build(premium)
      ..register()
      ..register();

    // The baseline is the registered state, so an equal state change is a
    // no-op.
    accountState.value = OneVpnAccountSignedIn(
      testSession(isPremium: true, token: 'token-new'),
    );
    expect(reprovisioned, isEmpty);

    // A real change still re-provisions exactly once, so the double
    // register subscribes only once.
    accountState.value = OneVpnAccountSignedIn(testSession(isPremium: false));
    expect(reprovisioned, hasLength(1));
  });

  test('a reprovision logs every error it reports', () async {
    final logs = <String?>[];
    final previous = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) => logs.add(message);
    addTearDown(() => debugPrint = previous);
    accountState = ValueNotifier<OneVpnAccountState>(
      const OneVpnAccountSignedOut(),
    );
    OneVpnReloadOwner(
      accountState: accountState,
      reprovision: (_) async => const OneVpnProvisionResult(
        nodes: [],
        errors: [
          'The free node free-ams.example.invalid has no IP literal.',
          'No usable credentials for London.',
        ],
      ),
    ).register();

    accountState.value = premium;
    await pumpEventQueue();

    expect(logs, <String>[
      'OneVpnNodeProvisioner: The free node free-ams.example.invalid has no '
          'IP literal.',
      'OneVpnNodeProvisioner: No usable credentials for London.',
    ]);
  });

  group('the premium hook', () {
    late List<String> events;

    /// Whether a reprovision throws. Each reprovision reads it, so a test can
    /// clear it between two changes.
    late bool failing;

    OneVpnReloadOwner buildWithHook(
      OneVpnAccountState initial, {
      bool failReprovision = false,
    }) {
      accountState = ValueNotifier<OneVpnAccountState>(initial);
      reprovisioned = <OneVpnSession?>[];
      events = <String>[];
      failing = failReprovision;
      return OneVpnReloadOwner(
        accountState: accountState,
        reprovision: (session) async {
          reprovisioned.add(session);
          await Future<void>.delayed(Duration.zero);
          if (failing) {
            events.add('failed');
            throw StateError('reprovision failed');
          }
          events.add('reprovisioned');
          return _provisioned;
        },
        onPremium: (session) async =>
            events.add('premium:${session.sessionAuthToken}'),
      );
    }

    test('a flip to premium runs it after the reprovision, with the new '
        'session', () async {
      buildWithHook(const OneVpnAccountSignedOut()).register();

      accountState.value = premium;
      await pumpEventQueue();

      expect(events, ['reprovisioned', 'premium:token-old']);
    });

    test('a flip from free to premium runs it', () async {
      buildWithHook(OneVpnAccountSignedIn(testSession(isPremium: false)))
          .register();

      accountState.value = premium;
      await pumpEventQueue();

      expect(events, ['reprovisioned', 'premium:token-old']);
    });

    test(
      'a free sign-in, a token rotation, and a flip to free skip it',
      () async {
        buildWithHook(const OneVpnAccountSignedOut()).register();
        accountState.value = OneVpnAccountSignedIn(
          testSession(isPremium: false),
        );
        await pumpEventQueue();
        expect(events, ['reprovisioned']);

        accountState.value = premium;
        await pumpEventQueue();
        events.clear();

        accountState.value = OneVpnAccountSignedIn(
          testSession(isPremium: true, token: 'token-new'),
        );
        await pumpEventQueue();
        expect(events, isEmpty);

        accountState.value = OneVpnAccountSignedIn(
          testSession(isPremium: false),
        );
        await pumpEventQueue();
        expect(events, ['reprovisioned']);
      },
    );

    test('a degraded premium catalogue waits for the usable one', () async {
      buildWithHook(const OneVpnAccountSignedOut()).register();

      accountState.value = OneVpnAccountSignedIn(
        testSession(isPremium: true, locations: const []),
      );
      await pumpEventQueue();
      expect(events, ['reprovisioned']);

      accountState.value = premium;
      await pumpEventQueue();
      expect(events, ['reprovisioned', 'reprovisioned', 'premium:token-old']);
    });

    test('a pending grant waits for its confirmation', () async {
      buildWithHook(OneVpnAccountSignedIn(testSession(isPremium: false)))
          .register();

      // A purchase marks the grant pending on the free session, which
      // holds no account credentials.
      accountState.value = OneVpnAccountSignedIn(
        testSession(
          isPremium: false,
          pendingSince: DateTime.utc(2026, 9, 28),
        ).copyWith(
          credentials: const OneVpnCredentials(
            uuid: '',
            publicKey: '',
            shortId: '',
          ),
        ),
      );
      await pumpEventQueue();
      expect(events, ['reprovisioned']);

      accountState.value = premium;
      await pumpEventQueue();
      expect(events, ['reprovisioned', 'reprovisioned', 'premium:token-old']);
    });

    test('a failed reprovision skips it', () async {
      buildWithHook(
        const OneVpnAccountSignedOut(),
        failReprovision: true,
      ).register();

      accountState.value = premium;
      await pumpEventQueue();

      expect(reprovisioned, hasLength(1));
      expect(events, ['failed']);
    });

    test('a failed reprovision is retried by the next change, and the hook '
        'runs once, after the retry', () async {
      buildWithHook(
        const OneVpnAccountSignedOut(),
        failReprovision: true,
      ).register();

      accountState.value = premium;
      await pumpEventQueue();
      failing = false;
      // A token rotation alone. It retries, since the failed reprovision
      // built nothing.
      accountState.value = OneVpnAccountSignedIn(
        testSession(isPremium: true, token: 'token-new'),
      );
      await pumpEventQueue();

      expect(reprovisioned, hasLength(2));
      expect(events, ['failed', 'reprovisioned', 'premium:token-new']);
    });
  });

  group('the selection check', () {
    late List<String> events;

    OneVpnReloadOwner buildWithCheck(
      OneVpnAccountState initial, {
      bool failReprovision = false,
    }) {
      accountState = ValueNotifier<OneVpnAccountState>(initial);
      reprovisioned = <OneVpnSession?>[];
      events = <String>[];
      return OneVpnReloadOwner(
        accountState: accountState,
        reprovision: (session) async {
          reprovisioned.add(session);
          await Future<void>.delayed(Duration.zero);
          if (failReprovision) {
            events.add('failed');
            throw StateError('reprovision failed');
          }
          events.add('reprovisioned');
          return _provisioned;
        },
        onPremium: (_) async => events.add('premium'),
        onSettled: () async => events.add('checked'),
      );
    }

    test('registration runs none, and checkSelection runs it once', () async {
      final owner = buildWithCheck(premium)
        ..register()
        ..register();
      await pumpEventQueue();
      expect(events, isEmpty);

      await owner.checkSelection();

      expect(events, ['checked']);
    });

    test('a location dropped with no server runs it', () async {
      const down = OneVpnApiLocation(
        city: 'Downtown',
        cityCode: 'dwn',
        country: 'Someland',
        countryCode: 'SL',
        servers: <OneVpnApiServer>[],
      );
      buildWithCheck(
        OneVpnAccountSignedIn(
          testSession(
            isPremium: true,
            locations: const [...testLocations, down],
          ),
        ),
      ).register();
      await pumpEventQueue();

      accountState.value = OneVpnAccountSignedIn(testSession(isPremium: true));
      await pumpEventQueue();

      expect(events, ['reprovisioned', 'checked']);
    });

    test('a sign-out runs it with no reprovision', () async {
      buildWithCheck(premium).register();
      await pumpEventQueue();
      events.clear();

      accountState.value = const OneVpnAccountSignedOut();
      await pumpEventQueue();

      expect(reprovisioned, isEmpty);
      expect(events, ['checked']);
    });

    test('a tier flip runs it after the reprovision', () async {
      buildWithCheck(premium).register();
      await pumpEventQueue();
      events.clear();

      accountState.value = OneVpnAccountSignedIn(testSession(isPremium: false));
      await pumpEventQueue();

      expect(events, ['reprovisioned', 'checked']);
    });

    test('a flip to premium runs it after the premium hook', () async {
      buildWithCheck(const OneVpnAccountSignedOut()).register();
      await pumpEventQueue();
      events.clear();

      accountState.value = premium;
      await pumpEventQueue();

      expect(events, ['reprovisioned', 'premium', 'checked']);
    });

    test('a failed reprovision still runs it', () async {
      buildWithCheck(premium, failReprovision: true).register();
      await pumpEventQueue();
      events.clear();

      accountState.value = OneVpnAccountSignedIn(testSession(isPremium: false));
      await pumpEventQueue();

      expect(events, ['failed', 'checked']);
    });

    test('a sign-out after a failed sign-in reprovision runs it', () async {
      buildWithCheck(
        const OneVpnAccountSignedOut(),
        failReprovision: true,
      ).register();

      accountState.value = premium;
      await pumpEventQueue();
      accountState.value = const OneVpnAccountSignedOut();
      await pumpEventQueue();

      expect(reprovisioned, hasLength(1));
      expect(events, ['failed', 'checked', 'checked']);
    });

    test('a token rotation and the Restoring state never run it', () async {
      buildWithCheck(premium).register();
      await pumpEventQueue();
      events.clear();

      accountState.value = OneVpnAccountSignedIn(
        testSession(isPremium: true, token: 'token-new'),
      );
      accountState.value = const OneVpnAccountRestoring();
      await pumpEventQueue();

      expect(events, isEmpty);
    });
  });
}
