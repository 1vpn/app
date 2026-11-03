// The resume trigger: what it calls, and the three gates it stops at.
//
// The suite drives the observer directly rather than through a device, like
// the upstream lifecycle observer tests.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/account/refresh_cooldown.dart';
import 'package:onexray/onevpn/account/resume_beacon.dart';
import 'package:onexray/onevpn/model/user_data.dart';
import 'package:onexray/onevpn/net/api_transport.dart';

import 'support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> log;
  late RecordingStore store;
  late ScriptedApi api;
  late SignOutSeams seams;
  late FakeClock clock;

  setUp(() {
    log = <String>[];
    store = RecordingStore(log);
    api = ScriptedApi()
      ..userData = OneVpnApiSuccess<OneVpnUserData>(testUserData())
      ..rotated = const OneVpnApiSuccess<String>('token-new');
    seams = SignOutSeams(log);
    clock = FakeClock(DateTime.utc(2026, 9, 15, 12));
  });

  OneVpnAccountService buildService() => OneVpnAccountService(
    store: store,
    api: api,
    now: clock.call,
    stopTunnel: seams.stopTunnel,
    sweepProvisioned: seams.sweepProvisioned,
    clearReachabilityStamp: seams.clearReachabilityStamp,
  );

  Future<OneVpnResumeBeacon> beaconFor(OneVpnAccountService service) async {
    await service.restore();
    api.calls.clear();
    return OneVpnResumeBeacon(service: service, now: clock.call);
  }

  Future<void> resume(OneVpnResumeBeacon beacon) async {
    beacon.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await beacon.pending;
  }

  test('a resume with a due session refreshes it', () async {
    await store.inner.write(testSession());
    final service = buildService();
    final beacon = await beaconFor(service);

    await resume(beacon);

    expect(api.calls, <String>[
      'fetchUserData:token-old',
      'refreshToken:token-old',
    ]);
    expect(service.session!.sessionAuthToken, 'token-new');
  });

  // Free and signed-out users make zero calls on this path. The beacon
  // stops at the state, so it never reads the cooldown stamp.
  test('a resume with no session dials nothing and reads no stamp', () async {
    final service = buildService();
    final beacon = await beaconFor(service);
    log.clear();

    await resume(beacon);

    expect(api.calls, isEmpty);
    expect(log, isEmpty);
  });

  test('a resume with an unreadable document dials nothing and reads no '
      'stamp', () async {
    store.inner.document = 'not json at all';
    final service = buildService();
    final beacon = await beaconFor(service);
    log.clear();

    await resume(beacon);

    expect(api.calls, isEmpty);
    expect(log, isEmpty);
  });

  test('a second resume inside the cooldown dials nothing', () async {
    await store.inner.write(testSession());
    final service = buildService();
    final beacon = await beaconFor(service);

    await resume(beacon);
    expect(api.calls, isNotEmpty);
    api.calls.clear();

    clock.advance(const Duration(minutes: 2));
    await resume(beacon);

    expect(api.calls, isEmpty);
  });

  // The sign-in answer is fresh user data. The first resume after a sign-in
  // is inside the cooldown and dials nothing.
  test('a resume right after a sign-in dials nothing', () async {
    final service = buildService();
    final beacon = await beaconFor(service);
    await service.adoptSession(
      OneVpnUserData(
        username: 'someone',
        email: 'someone@example.invalid',
        isPremium: true,
        sessionAuthToken: 'token-adopted',
        credentials: testCredentials,
        locations: testLocations,
      ),
    );
    clock.advance(const Duration(seconds: 30));

    await resume(beacon);

    expect(api.calls, isEmpty);
    expect(service.session!.sessionAuthToken, 'token-adopted');
  });

  test('a resume past the cooldown refreshes again', () async {
    await store.inner.write(testSession());
    final service = buildService();
    final beacon = await beaconFor(service);

    await resume(beacon);
    api.calls.clear();

    clock.advance(kOneVpnRefreshCooldown + const Duration(minutes: 1));
    await resume(beacon);

    expect(api.calls, isNotEmpty);
  });

  test('lifecycle states other than resumed do nothing', () async {
    await store.inner.write(testSession());
    final service = buildService();
    final beacon = await beaconFor(service);

    for (final state in <AppLifecycleState>[
      AppLifecycleState.inactive,
      AppLifecycleState.paused,
      AppLifecycleState.detached,
      AppLifecycleState.hidden,
    ]) {
      beacon.didChangeAppLifecycleState(state);
    }
    await beacon.pending;

    expect(api.calls, isEmpty);
  });

  // The restoring state is not signed out. Deciding against it would make
  // a signed-in user's first resume do nothing.
  test('a resume before the store answered waits for the gate', () async {
    await store.inner.write(testSession());
    final service = buildService();
    final beacon = OneVpnResumeBeacon(service: service, now: clock.call);

    expect(service.state.value, isA<OneVpnAccountRestoring>());
    await resume(beacon);

    expect(api.calls, <String>[
      'fetchUserData:token-old',
      'refreshToken:token-old',
    ]);
  });

  test('two resumes in the same moment produce one refresh', () async {
    await store.inner.write(testSession());
    final service = buildService();
    final beacon = await beaconFor(service);

    beacon.didChangeAppLifecycleState(AppLifecycleState.resumed);
    beacon.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await beacon.pending;

    expect(api.calls, <String>[
      'fetchUserData:token-old',
      'refreshToken:token-old',
    ]);
  });

  // A failed refresh holds nothing. Each resume during an outage sends one
  // request, and the next resume sends the next one at once.
  test('a failed refresh leaves the next resume due at once', () async {
    await store.inner.write(testSession());
    api.userData = const OneVpnApiUnreachable<OneVpnUserData>(
      <OneVpnApiAttempt>[
        OneVpnApiAttempt(domain: '1vpn.org', reason: 'timeout'),
      ],
    );
    final service = buildService();
    final beacon = await beaconFor(service);

    await resume(beacon);
    expect(api.calls, <String>['fetchUserData:token-old']);
    api.calls.clear();

    await resume(beacon);

    expect(api.calls, <String>['fetchUserData:token-old']);
  });

  // A failure carried forward would stop the beacon for the rest of the
  // session, not for one resume.
  test('a resume that throws leaves the next resume working', () async {
    await store.inner.write(testSession());
    final service = buildService();
    final beacon = await beaconFor(service);
    api.userData = null;

    await resume(beacon);
    expect(api.calls, isNotEmpty);
    api.calls.clear();

    api.userData = OneVpnApiSuccess<OneVpnUserData>(testUserData());
    clock.advance(kOneVpnRefreshCooldown + const Duration(minutes: 1));
    await resume(beacon);

    expect(api.calls, <String>[
      'fetchUserData:token-old',
      'refreshToken:token-old',
    ]);
    expect(service.session!.sessionAuthToken, 'token-new');
  });

  // The framework dispatches the first resumed during boot, before the
  // beacon registers. A signed-in user's first foreground therefore never
  // reaches the observer. Registration treats an already-foregrounded
  // launch as that resume, behind the same gates.
  test('registering after the first foreground still revalidates', () async {
    await store.inner.write(testSession());
    final service = buildService();
    await service.restore();
    api.calls.clear();

    WidgetsBinding.instance.handleAppLifecycleStateChanged(
      AppLifecycleState.resumed,
    );
    final beacon = OneVpnResumeBeacon(service: service, now: clock.call);
    beacon.register();
    await beacon.pending;
    beacon.unregister();

    expect(api.calls, <String>[
      'fetchUserData:token-old',
      'refreshToken:token-old',
    ]);
  });

  // An app open refreshes a signed-in session whatever the cooldown. Only
  // a resume reads it.
  test(
    'registering foregrounded within the cooldown still refreshes',
    () async {
      await store.inner.write(testSession());
      await store.inner.writeLastRefreshAt(
        clock.now.subtract(const Duration(hours: 1)),
      );
      final service = buildService();
      await service.restore();
      api.calls.clear();

      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );
      final beacon = OneVpnResumeBeacon(service: service, now: clock.call);
      beacon.register();
      await beacon.pending;
      beacon.unregister();

      expect(api.calls, <String>[
        'fetchUserData:token-old',
        'refreshToken:token-old',
      ]);
    },
  );

  // A pending grant refreshes on every foreground, cooldown or not, so a
  // slow webhook confirms without the daily wait.
  test('a resume inside the cooldown with a pending grant refreshes', () async {
    await store.inner.write(
      testSession(isPremium: false, pendingSince: clock.now),
    );
    await store.inner.writeLastRefreshAt(
      clock.now.subtract(const Duration(hours: 1)),
    );
    final service = buildService();
    final beacon = await beaconFor(service);

    await resume(beacon);

    expect(api.calls, <String>[
      'fetchUserData:token-old',
      'refreshToken:token-old',
    ]);
  });

  // A cold start is the foregrounded-launch resume. A pending grant makes it
  // fetch even inside the cooldown, so the row does not hang for a day.
  test(
    'registering foregrounded inside the cooldown but pending refreshes',
    () async {
      await store.inner.write(
        testSession(isPremium: false, pendingSince: clock.now),
      );
      await store.inner.writeLastRefreshAt(
        clock.now.subtract(const Duration(hours: 1)),
      );
      final service = buildService();
      await service.restore();
      api.calls.clear();

      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );
      final beacon = OneVpnResumeBeacon(service: service, now: clock.call);
      beacon.register();
      await beacon.pending;
      beacon.unregister();

      expect(api.calls, <String>[
        'fetchUserData:token-old',
        'refreshToken:token-old',
      ]);
    },
  );

  // register attaches exactly one observer however many times it is
  // called. One unregister detaches it. A double-add would survive the
  // unregister and fire on the next resume.
  test('register attaches once and unregister detaches', () async {
    await store.inner.write(testSession());
    final service = buildService();
    await service.restore();
    api.calls.clear();

    // Start from a non-foreground state so registration does not itself
    // fire the initial revalidation.
    WidgetsBinding.instance.handleAppLifecycleStateChanged(
      AppLifecycleState.inactive,
    );
    final beacon = OneVpnResumeBeacon(service: service, now: clock.call);
    beacon.register();
    beacon.register();
    beacon.unregister();

    WidgetsBinding.instance.handleAppLifecycleStateChanged(
      AppLifecycleState.resumed,
    );
    await beacon.pending;

    expect(api.calls, isEmpty);
  });
}
