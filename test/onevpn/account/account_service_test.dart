// The account state machine: the four sealed refresh outcomes, the
// cooldown, dedup, epoch fencing, the pending-premium marker lifecycle,
// the sign-out contract, and the purchase identity calls.
//
// Nothing here touches a network or a device. The clock, the endpoint
// client, the store, the three sign-out seams and the purchase service are
// all injected.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/account/credential_store.dart';
import 'package:onexray/onevpn/account/outcomes.dart';
import 'package:onexray/onevpn/account/session.dart';
import 'package:onexray/onevpn/data/account_api.dart';
import 'package:onexray/onevpn/model/user_data.dart';
import 'package:onexray/onevpn/net/api_transport.dart';

import 'support.dart';

void main() {
  late List<String> log;
  late RecordingStore store;
  late ScriptedApi api;
  late SignOutSeams seams;
  late FakeClock clock;
  late IdentitySeam identity;

  setUp(() {
    log = <String>[];
    store = RecordingStore(log);
    api = ScriptedApi();
    seams = SignOutSeams(log);
    clock = FakeClock(DateTime.utc(2026, 9, 15, 12));
    identity = IdentitySeam();
  });

  OneVpnAccountService build() => OneVpnAccountService(
    store: store,
    api: api,
    now: clock.call,
    stopTunnel: seams.stopTunnel,
    sweepProvisioned: seams.sweepProvisioned,
    clearReachabilityStamp: seams.clearReachabilityStamp,
    purchases: identity,
  );

  Future<OneVpnAccountService> signedIn({
    OneVpnSession? session,
    DateTime? stampedAt,
  }) async {
    await store.inner.write(session ?? testSession());
    if (stampedAt != null) await store.inner.writeLastRefreshAt(stampedAt);
    final service = build();
    await service.restore();
    expect(service.isSignedIn, isTrue);
    log.clear();
    api.calls.clear();
    identity.calls.clear();
    return service;
  }

  group('restore', () {
    test('no document settles signed out', () async {
      final service = build();
      expect(service.state.value, isA<OneVpnAccountRestoring>());

      await service.restore();

      expect(service.state.value, isA<OneVpnAccountSignedOut>());
      expect(service.session, isNull);
      expect(service.isSignedIn, isFalse);
    });

    test('a stored document settles signed in', () async {
      await store.inner.write(testSession());
      final service = build();

      await service.restore();

      expect(service.state.value, isA<OneVpnAccountSignedIn>());
      expect(service.session!.sessionAuthToken, 'token-old');
    });

    // Signed out hands the user the free catalogue and discards a paid
    // session. An unreadable document is not a signed-out user.
    test(
      'an unreadable document settles unreadable, never signed out',
      () async {
        store.inner.document = 'not json at all';
        final service = build();

        await service.restore();

        expect(service.state.value, isA<OneVpnAccountUnreadable>());
        expect(service.state.value, isNot(isA<OneVpnAccountSignedOut>()));
        expect(service.isSignedIn, isFalse);
        // Non-destructive: the document nobody could read is still there.
        expect(store.inner.document, 'not json at all');
      },
    );

    test(
      'a throwing store settles unreadable and still opens the gate',
      () async {
        store.throwOnRead = true;
        final service = build();

        await service.restore().timeout(const Duration(seconds: 5));

        expect(service.state.value, isA<OneVpnAccountUnreadable>());
        expect(
          (service.state.value as OneVpnAccountUnreadable).detail,
          contains('threw'),
        );
      },
    );

    test('restore reads the store once however many callers await', () async {
      final service = build();

      await Future.wait<void>(<Future<void>>[
        service.restore(),
        service.whenRestored(),
        service.restore(),
      ]);

      expect(log.where((entry) => entry == 'read'), hasLength(1));
    });

    test('whenRestored opens a gate nobody else started', () async {
      final service = build();

      await service.whenRestored().timeout(const Duration(seconds: 5));

      expect(service.state.value, isA<OneVpnAccountSignedOut>());
    });
  });

  group('refresh outcomes', () {
    test('a 401 signs the session out', () async {
      final service = await signedIn();
      api.userData = const OneVpnApiRejected<OneVpnUserData>(
        status: 401,
        message: 'unauthorised',
      );

      final outcome = await service.refresh(manual: true);

      expect(outcome, isA<OneVpnSignedOut>());
      expect(service.state.value, isA<OneVpnAccountSignedOut>());
      expect(store.inner.document, isNull);
      expect((outcome as OneVpnSignedOut).report.sessionCleared, isTrue);
    });

    // A blocked domain is not evidence that somebody stopped paying.
    test('no domain answering keeps the session', () async {
      final service = await signedIn();
      api.userData = const OneVpnApiUnreachable<OneVpnUserData>(
        <OneVpnApiAttempt>[
          OneVpnApiAttempt(domain: '1vpn.org', reason: 'timeout'),
        ],
      );

      final outcome = await service.refresh(manual: true);

      expect(outcome, isA<OneVpnKept>());
      expect((outcome as OneVpnKept).reason, OneVpnKeptReason.unreachable);
      expect(outcome.detail, contains('unreachable'));
      expect(service.isSignedIn, isTrue);
      expect(service.session!.sessionAuthToken, 'token-old');
    });

    test('a rejection that is not a 401 keeps the session', () async {
      final service = await signedIn();
      api.userData = const OneVpnApiRejected<OneVpnUserData>(
        status: 503,
        message: 'unavailable',
      );

      final outcome = await service.refresh(manual: true);

      expect(outcome, isA<OneVpnKept>());
      expect((outcome as OneVpnKept).reason, OneVpnKeptReason.rejected);
      expect(service.isSignedIn, isTrue);
    });

    test('a body that will not decode keeps the session', () async {
      final service = await signedIn();
      api.userData = const OneVpnApiMalformed<OneVpnUserData>('no isPremium');

      final outcome = await service.refresh(manual: true);

      expect(outcome, isA<OneVpnKept>());
      expect((outcome as OneVpnKept).reason, OneVpnKeptReason.malformed);
      expect(service.isSignedIn, isTrue);
    });

    test('a signed-out user refreshes nothing and dials nothing', () async {
      final service = build();
      await service.restore();

      final outcome = await service.refresh(manual: true);

      expect(outcome, isA<OneVpnNoSession>());
      expect(api.calls, isEmpty);
    });

    test(
      'an unreadable document refreshes nothing and is not erased',
      () async {
        store.inner.document = 'not json at all';
        final service = build();
        await service.restore();

        final outcome = await service.refresh(manual: true);

        expect(outcome, isA<OneVpnNoSession>());
        expect(api.calls, isEmpty);
        expect(store.inner.document, 'not json at all');
      },
    );

    test('a refresh rewrites the document with the rotated token', () async {
      final service = await signedIn();
      api.userData = OneVpnApiSuccess<OneVpnUserData>(testUserData());
      api.rotated = const OneVpnApiSuccess<String>('token-new');

      final outcome = await service.refresh(manual: true);

      expect(outcome, isA<OneVpnRefreshed>());
      expect(
        (outcome as OneVpnRefreshed).session.sessionAuthToken,
        'token-new',
      );
      expect(service.session!.sessionAuthToken, 'token-new');
      final stored = await store.inner.read() as OneVpnSessionRestored;
      expect(stored.session.sessionAuthToken, 'token-new');
    });

    // Both calls carry the token the session was started with. Rotating
    // before the document is rewritten would retire the stored token on
    // every path that then keeps the session.
    test('entitlement is read before the token rotates, both on the old '
        'token', () async {
      final service = await signedIn();
      api.userData = OneVpnApiSuccess<OneVpnUserData>(testUserData());
      api.rotated = const OneVpnApiSuccess<String>('token-new');

      await service.refresh(manual: true);

      expect(api.calls, <String>[
        'fetchUserData:token-old',
        'refreshToken:token-old',
      ]);
    });

    test('a failed rotation keeps the session and writes nothing', () async {
      final service = await signedIn();
      api.userData = OneVpnApiSuccess<OneVpnUserData>(testUserData());
      api.rotated = const OneVpnApiUnreachable<String>(<OneVpnApiAttempt>[
        OneVpnApiAttempt(domain: '1vpn.org', reason: 'timeout'),
      ]);

      final outcome = await service.refresh(manual: true);

      expect(outcome, isA<OneVpnKept>());
      expect((outcome as OneVpnKept).reason, OneVpnKeptReason.unreachable);
      expect(log, isNot(contains('write')));
      final stored = await store.inner.read() as OneVpnSessionRestored;
      expect(stored.session.sessionAuthToken, 'token-old');
    });

    test('a 401 on the rotation signs the session out', () async {
      final service = await signedIn();
      api.userData = OneVpnApiSuccess<OneVpnUserData>(testUserData());
      api.rotated = const OneVpnApiRejected<String>(
        status: 401,
        message: 'unauthorised',
      );

      expect(await service.refresh(manual: true), isA<OneVpnSignedOut>());
      expect(service.state.value, isA<OneVpnAccountSignedOut>());
    });

    // A rotation the server applied can still lose its answer. The rotation
    // goes to one domain, so the retired token never reaches a backup, and
    // the backup's 401 never ends the session.
    test('a rotation that times out keeps the session and the token', () async {
      await store.inner.write(testSession());
      final adapter = _HostAdapter((options) async {
        if (options.uri.path.endsWith('/get_user_data_api/')) {
          return _jsonBody(200, _userDataJson);
        }
        if (options.uri.host == '1vpn.org') {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.receiveTimeout,
          );
        }
        return _jsonBody(401, <String, dynamic>{'detail': 'Invalid token.'});
      });
      final service = OneVpnAccountService(
        store: store,
        api: OneVpnAccountApi(
          transport: OneVpnApiTransport(
            memory: OneVpnEphemeralDomainMemory(),
            reachabilityStamp: OneVpnEphemeralReachabilityStamp(),
            dio: Dio()..httpClientAdapter = adapter,
          ),
        ),
        now: clock.call,
        stopTunnel: seams.stopTunnel,
        sweepProvisioned: seams.sweepProvisioned,
        clearReachabilityStamp: seams.clearReachabilityStamp,
        purchases: identity,
      );
      await service.restore();
      log.clear();

      final outcome = await service.refresh(manual: true);

      expect(adapter.requests, <String>[
        '1vpn.org/api/get_user_data_api/',
        '1vpn.org/api/refresh_token/',
      ]);
      expect(outcome, isA<OneVpnKept>());
      expect((outcome as OneVpnKept).reason, OneVpnKeptReason.unreachable);
      expect(service.session!.sessionAuthToken, 'token-old');
      final stored = await store.inner.read() as OneVpnSessionRestored;
      expect(stored.session.sessionAuthToken, 'token-old');
      expect(log, isNot(contains('stopTunnel')));
      expect(log, isNot(contains('writeLastRefreshAt')));
    });

    // The rotation retires the presented token on the server. A refused
    // write must not leave the session on the retired token.
    test(
      'a store that refuses the rewrite keeps the rotated token in memory',
      () async {
        final service = await signedIn();
        api.userData = OneVpnApiSuccess<OneVpnUserData>(testUserData());
        api.rotated = const OneVpnApiSuccess<String>('token-new');
        store.throwOnWrite = true;

        final outcome = await service.refresh(manual: true);

        expect(outcome, isA<OneVpnKept>());
        expect((outcome as OneVpnKept).reason, OneVpnKeptReason.unstored);
        expect(outcome.session.sessionAuthToken, 'token-new');
        expect(service.session!.sessionAuthToken, 'token-new');
        expect(log, isNot(contains('writeLastRefreshAt')));
        final stored = await store.inner.read() as OneVpnSessionRestored;
        expect(stored.session.sessionAuthToken, 'token-old');

        // The next refresh presents the rotated token and persists.
        store.throwOnWrite = false;
        api.calls.clear();
        api.rotated = const OneVpnApiSuccess<String>('token-newer');

        expect(await service.refresh(manual: true), isA<OneVpnRefreshed>());
        expect(api.calls, <String>[
          'fetchUserData:token-new',
          'refreshToken:token-new',
        ]);
        final persisted = await store.inner.read() as OneVpnSessionRestored;
        expect(persisted.session.sessionAuthToken, 'token-newer');
      },
    );
  });

  group('the locations merge rule', () {
    // An empty payload never erases what the user already had.
    test('an empty locations payload keeps the cached catalogue', () async {
      final service = await signedIn();
      api.userData = OneVpnApiSuccess<OneVpnUserData>(
        testUserData(isPremium: false, locations: const <OneVpnApiLocation>[]),
      );
      api.rotated = const OneVpnApiSuccess<String>('token-new');

      final outcome = await service.refresh(manual: true) as OneVpnRefreshed;

      expect(outcome.serverSentNoLocations, isTrue);
      expect(outcome.session.locations, hasLength(1));
      expect(outcome.session.locations.single.countryCode, 'SL');
      // The token and the entitlement still update.
      expect(outcome.session.sessionAuthToken, 'token-new');
      expect(outcome.session.isPremium, isFalse);
    });

    test(
      'a populated locations payload replaces the cached catalogue',
      () async {
        final service = await signedIn();
        api.userData = OneVpnApiSuccess<OneVpnUserData>(
          testUserData(
            locations: const <OneVpnApiLocation>[
              OneVpnApiLocation(country: 'Elsewhere', countryCode: 'EL'),
              OneVpnApiLocation(country: 'Otherplace', countryCode: 'OP'),
            ],
          ),
        );
        api.rotated = const OneVpnApiSuccess<String>('token-new');

        final outcome = await service.refresh(manual: true) as OneVpnRefreshed;

        expect(outcome.serverSentNoLocations, isFalse);
        expect(outcome.session.locations, hasLength(2));
        expect(outcome.session.locations.first.countryCode, 'EL');
      },
    );
  });

  group('the cooldown', () {
    test('a background refresh inside the window dials nothing', () async {
      final service = await signedIn(
        stampedAt: clock.now.subtract(const Duration(hours: 1)),
      );

      final outcome = await service.refresh(manual: false);

      expect(outcome, isA<OneVpnKept>());
      expect((outcome as OneVpnKept).reason, OneVpnKeptReason.cooldown);
      expect(api.calls, isEmpty);
    });

    test('a background refresh past the window dials', () async {
      final service = await signedIn(
        stampedAt: clock.now.subtract(const Duration(hours: 25)),
      );
      api.userData = OneVpnApiSuccess<OneVpnUserData>(testUserData());
      api.rotated = const OneVpnApiSuccess<String>('token-new');

      expect(await service.refresh(manual: false), isA<OneVpnRefreshed>());
      expect(api.calls, isNotEmpty);
    });

    // A pending grant bypasses the cooldown, so a background refresh confirms
    // it without the daily wait.
    test(
      'a pending grant makes a background refresh inside the window dial',
      () async {
        final service = await signedIn(
          session: testSession(isPremium: false, pendingSince: clock.now),
          stampedAt: clock.now.subtract(const Duration(hours: 1)),
        );
        api.userData = OneVpnApiSuccess<OneVpnUserData>(testUserData());
        api.rotated = const OneVpnApiSuccess<String>('token-new');

        expect(await service.refresh(manual: false), isA<OneVpnRefreshed>());
        expect(api.calls, isNotEmpty);
      },
    );

    // The cooldown limits app polling. It never blocks a manual refresh.
    test('a manual refresh inside the window dials and stamps', () async {
      final service = await signedIn(
        stampedAt: clock.now.subtract(const Duration(hours: 1)),
      );
      api.userData = OneVpnApiSuccess<OneVpnUserData>(testUserData());
      api.rotated = const OneVpnApiSuccess<String>('token-new');

      expect(await service.refresh(manual: true), isA<OneVpnRefreshed>());
      expect(await service.lastRefreshAt(), clock.now);
    });

    test('a refreshed outcome stamps the cooldown', () async {
      final service = await signedIn();
      api.userData = OneVpnApiSuccess<OneVpnUserData>(testUserData());
      api.rotated = const OneVpnApiSuccess<String>('token-new');

      await service.refresh(manual: true);

      expect(await service.lastRefreshAt(), clock.now);
    });

    test('a kept refresh must not burn the cooldown', () async {
      final service = await signedIn();
      api.userData = const OneVpnApiUnreachable<OneVpnUserData>(
        <OneVpnApiAttempt>[
          OneVpnApiAttempt(domain: '1vpn.org', reason: 'timeout'),
        ],
      );

      expect(await service.refresh(manual: true), isA<OneVpnKept>());

      expect(await service.lastRefreshAt(), isNull);
      expect(log, isNot(contains('writeLastRefreshAt')));
    });

    // The sign-in answer is fresh user data. Adoption stamps the cooldown,
    // so a background refresh right after a sign-in dials nothing.
    test('adopting a session stamps the cooldown', () async {
      final service = build();
      await service.restore();
      log.clear();

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

      expect(await service.lastRefreshAt(), clock.now);
      expect(log, contains('writeLastRefreshAt'));
      expect(log, isNot(contains('clearLastRefreshAt')));
      final outcome = await service.refresh(manual: false);
      expect(outcome, isA<OneVpnKept>());
      expect((outcome as OneVpnKept).reason, OneVpnKeptReason.cooldown);
      expect(api.calls, isEmpty);
    });
  });

  group('dedup and epoch fencing', () {
    // Two triggers in flight against a rotating token would persist a token
    // the server already retired.
    test('concurrent triggers share one refresh and rotate once', () async {
      final service = await signedIn();
      final gate = Completer<void>();
      api.beforeFetch = () => gate.future;
      api.userData = OneVpnApiSuccess<OneVpnUserData>(testUserData());
      api.rotated = const OneVpnApiSuccess<String>('token-new');

      final first = service.refresh(manual: true);
      final second = service.refresh(manual: true);
      await pumpEventQueue();
      gate.complete();
      final outcomes = await Future.wait(<Future<OneVpnRefreshOutcome>>[
        first,
        second,
      ]);

      expect(api.calls, <String>[
        'fetchUserData:token-old',
        'refreshToken:token-old',
      ]);
      expect(outcomes.first, isA<OneVpnRefreshed>());
      expect(identical(outcomes.first, outcomes.last), isTrue);
      expect(log.where((entry) => entry == 'write'), hasLength(1));
    });

    test(
      'a later trigger starts a fresh refresh once the first finished',
      () async {
        final service = await signedIn();
        api.userData = OneVpnApiSuccess<OneVpnUserData>(testUserData());
        api.rotated = const OneVpnApiSuccess<String>('token-new');

        await service.refresh(manual: true);
        await service.refresh(manual: true);

        expect(
          api.calls.where((c) => c.startsWith('refreshToken')),
          hasLength(2),
        );
      },
    );

    // A refresh must never resurrect signedIn after a sign-out. The user
    // ended that session.
    test('a refresh held open across a sign-out drops its result', () async {
      final service = await signedIn();
      final gate = Completer<void>();
      api.beforeFetch = () => gate.future;
      api.userData = OneVpnApiSuccess<OneVpnUserData>(testUserData());
      api.rotated = const OneVpnApiSuccess<String>('token-new');

      final held = service.refresh(manual: true);
      await pumpEventQueue();
      await service.signOut();
      gate.complete();

      expect(await held, isA<OneVpnNoSession>());
      expect(service.state.value, isA<OneVpnAccountSignedOut>());
      expect(store.inner.document, isNull);
    });

    test('a failure landing after a sign-out drops its result too', () async {
      final service = await signedIn();
      final gate = Completer<void>();
      api.beforeFetch = () => gate.future;
      api.userData = const OneVpnApiRejected<OneVpnUserData>(
        status: 401,
        message: 'unauthorised',
      );

      final held = service.refresh(manual: true);
      await pumpEventQueue();
      await service.signOut();
      gate.complete();

      expect(await held, isA<OneVpnNoSession>());
    });

    test(
      'adopting a session fences a refresh started against the old one',
      () async {
        final service = await signedIn();
        final gate = Completer<void>();
        api.beforeFetch = () => gate.future;
        api.userData = OneVpnApiSuccess<OneVpnUserData>(testUserData());
        api.rotated = const OneVpnApiSuccess<String>('token-new');

        final held = service.refresh(manual: true);
        await pumpEventQueue();
        await service.adoptSession(
          OneVpnUserData(
            username: 'other',
            email: 'other@example.invalid',
            isPremium: false,
            sessionAuthToken: 'token-adopted',
            credentials: testCredentials,
            locations: const <OneVpnApiLocation>[],
          ),
        );
        gate.complete();

        expect(await held, isA<OneVpnNoSession>());
        expect(service.session!.sessionAuthToken, 'token-adopted');
      },
    );

    // A refresh that starts after the sign-out's epoch bump captures the
    // bumped epoch, so the epoch fence passes. It reads signedIn only while
    // the state flip lags the bump. If it read signedIn, it would re-publish
    // the ended session to disk. Sign-out flips the state at the bump, so
    // the refresh reads signed out and drops. This test pins that alignment.
    // It starts the refresh from the sweep seam. It releases the refresh in
    // the domain-forget seam, between the store clear and where a lagging
    // flip would sit.
    test(
      'a refresh landing mid-sign-out cannot resurrect the session',
      () async {
        await store.inner.write(testSession());
        final gate = Completer<void>();
        api.beforeFetch = () => gate.future;
        api.userData = OneVpnApiSuccess<OneVpnUserData>(testUserData());
        api.rotated = const OneVpnApiSuccess<String>('token-new');

        late OneVpnAccountService service;
        Future<OneVpnRefreshOutcome>? held;
        service = OneVpnAccountService(
          store: store,
          api: api,
          now: clock.call,
          stopTunnel: seams.stopTunnel,
          // Runs after the epoch bump. The refresh started here captures the
          // bumped epoch and holds at its first await.
          sweepProvisioned: () async {
            held ??= service.refresh(manual: true);
            await pumpEventQueue();
            return OneVpnSweepResult.unwired;
          },
          // Runs after the store clear. Releasing the refresh here lands its
          // commit in the window a lagging state flip would leave open.
          clearReachabilityStamp: () async {
            gate.complete();
            await held;
          },
        );
        await service.restore();

        await service.signOut();

        expect(await held, isA<OneVpnNoSession>());
        expect(service.state.value, isA<OneVpnAccountSignedOut>());
        expect(store.inner.document, isNull);
      },
    );

    // Sign-out bumps the epoch only after the tunnel stop. A commit parked
    // on a store write across that bump must not re-publish signed in.
    test(
      'a refresh held on the session write across a sign-out ends signed out',
      () async {
        final service = await signedIn();
        final gate = Completer<void>();
        store.afterWrite = () => gate.future;
        api.userData = OneVpnApiSuccess<OneVpnUserData>(testUserData());
        api.rotated = const OneVpnApiSuccess<String>('token-new');

        final held = service.refresh(manual: true);
        await pumpEventQueue();
        expect(log, contains('write'));
        await service.signOut();
        gate.complete();

        expect(await held, isA<OneVpnNoSession>());
        expect(service.state.value, isA<OneVpnAccountSignedOut>());
        expect(store.inner.document, isNull);
        expect(await store.inner.readLastRefreshAt(), isNull);
        expect(log, isNot(contains('writeLastRefreshAt')));
      },
    );

    // A write refused after a sign-out must not publish the rotated session
    // over the sign-out.
    test('a session write held across a sign-out that then throws ends signed '
        'out', () async {
      final service = await signedIn();
      final gate = Completer<void>();
      store.afterWrite = () async {
        await gate.future;
        throw StateError('write refused after the hold');
      };
      api.userData = OneVpnApiSuccess<OneVpnUserData>(testUserData());
      api.rotated = const OneVpnApiSuccess<String>('token-new');

      final held = service.refresh(manual: true);
      await pumpEventQueue();
      expect(log, contains('write'));
      await service.signOut();
      gate.complete();

      expect(await held, isA<OneVpnNoSession>());
      expect(service.state.value, isA<OneVpnAccountSignedOut>());
      expect(service.session, isNull);
      expect(store.inner.document, isNull);
    });

    test(
      'a refresh held on the stamp write across a sign-out ends signed out',
      () async {
        final service = await signedIn();
        final gate = Completer<void>();
        store.afterWriteStamp = () => gate.future;
        api.userData = OneVpnApiSuccess<OneVpnUserData>(testUserData());
        api.rotated = const OneVpnApiSuccess<String>('token-new');

        final held = service.refresh(manual: true);
        await pumpEventQueue();
        expect(log, contains('writeLastRefreshAt'));
        await service.signOut();
        gate.complete();

        expect(await held, isA<OneVpnNoSession>());
        expect(service.state.value, isA<OneVpnAccountSignedOut>());
        expect(store.inner.document, isNull);
      },
    );

    test(
      'a grant held on the store write across a sign-out ends signed out',
      () async {
        final service = await signedIn(session: testSession(isPremium: false));
        final gate = Completer<void>();
        store.afterWrite = () => gate.future;

        final held = service.markPremiumPending();
        await pumpEventQueue();
        expect(log, contains('write'));
        await service.signOut();
        gate.complete();

        expect(await held, isFalse);
        expect(service.state.value, isA<OneVpnAccountSignedOut>());
        expect(store.inner.document, isNull);
      },
    );

    // Sign-in must not throw back at its caller. A refused persist costs
    // the disk copy, not the in-memory session.
    test('adopting a session survives a refused store write', () async {
      final service = await signedIn();
      store.throwOnWrite = true;

      await expectLater(
        service.adoptSession(
          OneVpnUserData(
            username: 'other',
            email: 'other@example.invalid',
            isPremium: false,
            sessionAuthToken: 'token-adopted',
            credentials: testCredentials,
            locations: const <OneVpnApiLocation>[],
          ),
        ),
        completes,
      );

      expect(service.session!.sessionAuthToken, 'token-adopted');
      expect(service.state.value, isA<OneVpnAccountSignedIn>());
    });
  });

  group('the pending premium marker', () {
    test('a signed-out user never grants locally', () async {
      final service = build();
      await service.restore();

      expect(await service.markPremiumPending(), isFalse);
      expect(store.inner.document, isNull);
      expect(log, isNot(contains('write')));
    });

    test('an unreadable document never grants locally', () async {
      store.inner.document = 'not json at all';
      final service = build();
      await service.restore();

      expect(await service.markPremiumPending(), isFalse);
      expect(store.inner.document, 'not json at all');
    });

    test('a signed-in grant is written and reads as entitled', () async {
      final service = await signedIn(session: testSession(isPremium: false));

      expect(await service.markPremiumPending(), isTrue);

      expect(service.session!.premiumPendingSince, clock.now);
      expect(service.session!.isPremium, isFalse);
      expect(service.session!.isPremiumEntitled, isTrue);
      final stored = await store.inner.read() as OneVpnSessionRestored;
      expect(stored.session.premiumPendingSince, clock.now);
    });

    test(
      'a grant survives a restart because it lives in the document',
      () async {
        final service = await signedIn(session: testSession(isPremium: false));
        await service.markPremiumPending();

        final restarted = build();
        await restarted.restore();

        expect(restarted.session!.premiumPendingSince, clock.now);
        expect(restarted.session!.isPremiumEntitled, isTrue);
      },
    );

    // A grant writes the marker without moving the epoch. A refresh in
    // flight must commit against the live session and carry that marker.
    // It must not rebuild from the pre-network snapshot and erase it.
    test('a grant written during a refresh survives the commit', () async {
      final service = await signedIn(session: testSession(isPremium: false));
      final gate = Completer<void>();
      api.beforeFetch = () => gate.future;
      api.userData = OneVpnApiSuccess<OneVpnUserData>(
        testUserData(isPremium: false),
      );
      api.rotated = const OneVpnApiSuccess<String>('token-new');

      final held = service.refresh(manual: true);
      await pumpEventQueue();
      expect(await service.markPremiumPending(), isTrue);

      gate.complete();
      final outcome = await held as OneVpnRefreshed;

      // The rotation still lands, and the grant is not erased.
      expect(outcome.session.sessionAuthToken, 'token-new');
      expect(outcome.premiumUnconfirmed, isTrue);
      expect(outcome.session.premiumPendingSince, clock.now);
      expect(service.session!.premiumPendingSince, clock.now);
      final stored = await store.inner.read() as OneVpnSessionRestored;
      expect(stored.session.premiumPendingSince, clock.now);
    });

    test('a refresh that confirms premium clears the marker', () async {
      final service = await signedIn(
        session: testSession(isPremium: false, pendingSince: clock.now),
      );
      api.userData = OneVpnApiSuccess<OneVpnUserData>(testUserData());
      api.rotated = const OneVpnApiSuccess<String>('token-new');

      final outcome = await service.refresh(manual: true) as OneVpnRefreshed;

      expect(outcome.premiumUnconfirmed, isFalse);
      expect(outcome.session.premiumPendingSince, isNull);
      expect(outcome.session.isPremium, isTrue);
    });

    test('a not-premium answer inside the window keeps the grant', () async {
      final granted = clock.now;
      final service = await signedIn(
        session: testSession(isPremium: false, pendingSince: granted),
      );
      clock.advance(const Duration(hours: 47));
      api.userData = OneVpnApiSuccess<OneVpnUserData>(
        testUserData(isPremium: false),
      );
      api.rotated = const OneVpnApiSuccess<String>('token-new');

      final outcome = await service.refresh(manual: true) as OneVpnRefreshed;

      expect(outcome.premiumUnconfirmed, isTrue);
      expect(outcome.session.premiumPendingSince, granted);
      expect(outcome.session.isPremiumEntitled, isTrue);
    });

    test('a not-premium answer past the window rolls the grant back', () async {
      final service = await signedIn(
        session: testSession(isPremium: false, pendingSince: clock.now),
      );
      clock.advance(const Duration(hours: 49));
      api.userData = OneVpnApiSuccess<OneVpnUserData>(
        testUserData(isPremium: false),
      );
      api.rotated = const OneVpnApiSuccess<String>('token-new');

      final outcome = await service.refresh(manual: true) as OneVpnRefreshed;

      expect(outcome.premiumUnconfirmed, isFalse);
      expect(outcome.session.premiumPendingSince, isNull);
      expect(outcome.session.isPremiumEntitled, isFalse);
    });

    test('the window boundary rolls back exactly at the grace', () async {
      final service = await signedIn(
        session: testSession(isPremium: false, pendingSince: clock.now),
      );
      clock.advance(kOneVpnPremiumConfirmationGrace);
      api.userData = OneVpnApiSuccess<OneVpnUserData>(
        testUserData(isPremium: false),
      );
      api.rotated = const OneVpnApiSuccess<String>('token-new');

      final outcome = await service.refresh(manual: true) as OneVpnRefreshed;

      expect(outcome.session.premiumPendingSince, isNull);
    });

    // A clock that moved must never roll a paying user back.
    test('a grant timestamped in the future is kept', () async {
      final service = await signedIn(
        session: testSession(
          isPremium: false,
          pendingSince: clock.now.add(const Duration(days: 30)),
        ),
      );
      api.userData = OneVpnApiSuccess<OneVpnUserData>(
        testUserData(isPremium: false),
      );
      api.rotated = const OneVpnApiSuccess<String>('token-new');

      final outcome = await service.refresh(manual: true) as OneVpnRefreshed;

      expect(outcome.premiumUnconfirmed, isTrue);
      expect(outcome.session.premiumPendingSince, isNotNull);
    });

    // A network failure is not evidence about a purchase.
    test('an offline refresh leaves the grant untouched', () async {
      final granted = clock.now;
      final service = await signedIn(
        session: testSession(isPremium: false, pendingSince: granted),
      );
      clock.advance(const Duration(days: 30));
      api.userData = const OneVpnApiUnreachable<OneVpnUserData>(
        <OneVpnApiAttempt>[
          OneVpnApiAttempt(domain: '1vpn.org', reason: 'timeout'),
        ],
      );

      final outcome = await service.refresh(manual: true);

      expect(outcome, isA<OneVpnKept>());
      expect((outcome as OneVpnKept).session.premiumPendingSince, granted);
      expect(service.session!.isPremiumEntitled, isTrue);
    });

    test(
      'a sign-out clears the grant with the document, in one write',
      () async {
        final service = await signedIn(
          session: testSession(isPremium: false, pendingSince: clock.now),
        );

        await service.signOut();

        expect(store.inner.document, isNull);
        // The marker implies a session: no path leaves a marker behind.
        expect(await store.inner.read(), isA<OneVpnSessionAbsent>());
      },
    );

    test('a 401 clears the grant with the document', () async {
      final service = await signedIn(
        session: testSession(isPremium: false, pendingSince: clock.now),
      );
      api.userData = const OneVpnApiRejected<OneVpnUserData>(
        status: 401,
        message: 'unauthorised',
      );

      expect(await service.refresh(manual: true), isA<OneVpnSignedOut>());
      expect(store.inner.document, isNull);
    });

    test('adopting a fresh sign-in carries no grant', () async {
      final service = await signedIn(
        session: testSession(isPremium: false, pendingSince: clock.now),
      );

      await service.adoptSession(
        OneVpnUserData(
          username: 'someone',
          email: 'someone@example.invalid',
          isPremium: false,
          sessionAuthToken: 'token-adopted',
          credentials: testCredentials,
          locations: const <OneVpnApiLocation>[],
        ),
      );

      expect(service.session!.premiumPendingSince, isNull);
    });
  });

  // The grant, the refresh commit and the adoption run one at a time.
  group('the mutation chain', () {
    // One gate per session write, in call order. Later writes pass at once.
    List<Completer<void>> holdWrites(int count) {
      final gates = List<Completer<void>>.generate(
        count,
        (_) => Completer<void>(),
      );
      var calls = 0;
      store.afterWrite = () {
        final call = calls++;
        return call < count ? gates[call].future : Future<void>.value();
      };
      return gates;
    }

    Future<OneVpnSession> stored() async =>
        (await store.inner.read() as OneVpnSessionRestored).session;

    // The first call of the activator's next confirmation poll.
    Future<String> nextPollCall(OneVpnAccountService service) async {
      api.calls.clear();
      await service.refresh(manual: true);
      return api.calls.first;
    }

    OneVpnUserData adopted() => OneVpnUserData(
      username: 'other',
      email: 'other@example.invalid',
      isPremium: false,
      sessionAuthToken: 'token-adopted',
      credentials: testCredentials,
      locations: const <OneVpnApiLocation>[],
    );

    void answerNotPremium() {
      api.userData = OneVpnApiSuccess<OneVpnUserData>(
        testUserData(isPremium: false),
      );
      api.rotated = const OneVpnApiSuccess<String>('token-new');
    }

    // A grant that reads the session before the commit publishes marks the
    // retired token on disk.
    test('a grant made while a commit holds on its session write marks the '
        'rotated token', () async {
      final service = await signedIn(session: testSession(isPremium: false));
      answerNotPremium();
      final stamp = Completer<void>();
      store.afterWriteStamp = () => stamp.future;
      final writes = holdWrites(2);

      final refreshed = service.refresh(manual: true);
      await pumpEventQueue();
      expect(log.where((entry) => entry == 'write'), hasLength(1));
      final granted = service.markPremiumPending();
      await pumpEventQueue();
      writes[0].complete();
      await pumpEventQueue();
      writes[1].complete();
      await pumpEventQueue();
      stamp.complete();

      expect(await refreshed, isA<OneVpnRefreshed>());
      expect(await granted, isTrue);
      expect(service.session!.sessionAuthToken, 'token-new');
      expect(service.session!.premiumPendingSince, clock.now);
      final disk = await stored();
      expect(disk.sessionAuthToken, 'token-new');
      expect(disk.premiumPendingSince, clock.now);
      expect(await nextPollCall(service), 'fetchUserData:token-new');
    });

    // A grant that publishes after the commit puts the retired token back.
    // The next poll presents it. The 401 signs the buyer out.
    test('a grant made while a commit holds on its stamp write marks the '
        'rotated token', () async {
      final service = await signedIn(session: testSession(isPremium: false));
      answerNotPremium();
      final stamp = Completer<void>();
      store.afterWriteStamp = () => stamp.future;

      final refreshed = service.refresh(manual: true);
      await pumpEventQueue();
      expect(log, contains('writeLastRefreshAt'));
      final writes = holdWrites(1);
      final granted = service.markPremiumPending();
      await pumpEventQueue();
      stamp.complete();
      expect(await refreshed, isA<OneVpnRefreshed>());
      writes[0].complete();

      expect(await granted, isTrue);
      expect(service.session!.sessionAuthToken, 'token-new');
      expect(service.session!.premiumPendingSince, clock.now);
      final disk = await stored();
      expect(disk.sessionAuthToken, 'token-new');
      expect(disk.premiumPendingSince, clock.now);
      expect(await nextPollCall(service), 'fetchUserData:token-new');
    });

    // A commit that reads the session before the grant publishes drops the
    // marker. The resume path then waits out the cooldown.
    test(
      'a commit that lands while a grant writes carries the marker',
      () async {
        final service = await signedIn(session: testSession(isPremium: false));
        answerNotPremium();
        final writes = holdWrites(2);

        final granted = service.markPremiumPending();
        await pumpEventQueue();
        expect(log.where((entry) => entry == 'write'), hasLength(1));
        final refreshed = service.refresh(manual: true);
        await pumpEventQueue();
        writes[0].complete();
        expect(await granted, isTrue);
        writes[1].complete();
        final outcome = await refreshed as OneVpnRefreshed;

        expect(outcome.premiumUnconfirmed, isTrue);
        expect(outcome.session.sessionAuthToken, 'token-new');
        expect(outcome.session.premiumPendingSince, clock.now);
        expect(service.session!.sessionAuthToken, 'token-new');
        expect(service.session!.isPremiumPending, isTrue);
        final disk = await stored();
        expect(disk.sessionAuthToken, 'token-new');
        expect(disk.premiumPendingSince, clock.now);
        expect(await nextPollCall(service), 'fetchUserData:token-new');
      },
    );

    // A refresh that starts while the adoption writes still reads the old
    // session. Its commit must not land the old account over the adopted
    // one, in memory or on disk.
    test(
      'a refresh started while an adoption writes leaves the adopted session',
      () async {
        final service = await signedIn();
        api.userData = OneVpnApiSuccess<OneVpnUserData>(testUserData());
        api.rotated = const OneVpnApiSuccess<String>('token-new');
        final writes = holdWrites(1);

        final adopting = service.adoptSession(adopted());
        await pumpEventQueue();
        final refreshed = service.refresh(manual: true);
        await pumpEventQueue();
        writes[0].complete();
        await adopting;

        expect(await refreshed, isA<OneVpnNoSession>());
        expect(service.session!.sessionAuthToken, 'token-adopted');
        expect(service.session!.email, 'other@example.invalid');
        final disk = await stored();
        expect(disk.sessionAuthToken, 'token-adopted');
        expect(disk.email, 'other@example.invalid');
        expect(identity.calls, ['identify:other@example.invalid']);
        expect(await nextPollCall(service), 'fetchUserData:token-adopted');
      },
    );

    // A background refresh reads the session, then awaits the cooldown
    // stamp. An adoption that flips inside that await ends the refresh
    // before it dials.
    test(
      'a background refresh whose cooldown read spans an adoption leaves the '
      'adopted session',
      () async {
        final service = await signedIn();
        api.userData = OneVpnApiSuccess<OneVpnUserData>(testUserData());
        api.rotated = const OneVpnApiSuccess<String>('token-new');
        final stampRead = Completer<void>();
        store.afterReadStamp = () => stampRead.future;

        final refreshed = service.refresh(manual: false);
        await pumpEventQueue();
        expect(log, contains('readLastRefreshAt'));
        await service.adoptSession(adopted());
        stampRead.complete();

        expect(await refreshed, isA<OneVpnNoSession>());
        expect(api.calls, isEmpty);
        expect(service.session!.sessionAuthToken, 'token-adopted');
        expect(service.session!.email, 'other@example.invalid');
        final disk = await stored();
        expect(disk.sessionAuthToken, 'token-adopted');
        expect(disk.email, 'other@example.invalid');
      },
    );

    // Inside the cooldown, the same read must not report the replaced
    // session as kept.
    test(
      'a background refresh inside the cooldown whose read spans an adoption '
      'reports no session',
      () async {
        final service = await signedIn(
          stampedAt: clock.now.subtract(const Duration(hours: 1)),
        );
        final stampRead = Completer<void>();
        store.afterReadStamp = () => stampRead.future;

        final refreshed = service.refresh(manual: false);
        await pumpEventQueue();
        expect(log, contains('readLastRefreshAt'));
        await service.adoptSession(adopted());
        stampRead.complete();

        expect(await refreshed, isA<OneVpnNoSession>());
        expect(api.calls, isEmpty);
        expect(service.session!.sessionAuthToken, 'token-adopted');
      },
    );

    // A refresh in flight against the replaced session can fail after the
    // adoption starts. Its 401 must not sign the adopted session out.
    test('a 401 that lands while an adoption writes reports no session and '
        'signs nothing out', () async {
      final service = await signedIn();
      final fetch = Completer<void>();
      api.beforeFetch = () => fetch.future;
      api.userData = const OneVpnApiRejected<OneVpnUserData>(
        status: 401,
        message: 'unauthorised',
      );
      final writes = holdWrites(1);

      final refreshed = service.refresh(manual: true);
      await pumpEventQueue();
      final adopting = service.adoptSession(adopted());
      await pumpEventQueue();
      expect(log, contains('write'));
      fetch.complete();
      expect(await refreshed, isA<OneVpnNoSession>());
      writes[0].complete();
      await adopting;

      expect(service.session!.sessionAuthToken, 'token-adopted');
      expect((await stored()).sessionAuthToken, 'token-adopted');
      for (final step in <String>[
        'stopTunnel',
        'sweepProvisioned',
        'clear',
        'clearReachabilityStamp',
      ]) {
        expect(log, isNot(contains(step)));
      }
      expect(identity.calls, ['identify:other@example.invalid']);
    });

    // A sabotaged clock throws inside the grant's section.
    test('a section that throws hands its error to its caller and the next '
        'section runs', () async {
      await store.inner.write(testSession(isPremium: false));
      var clockThrows = true;
      final service = OneVpnAccountService(
        store: store,
        api: api,
        now: () =>
            clockThrows ? throw StateError('clock sabotaged') : clock.now,
        stopTunnel: seams.stopTunnel,
        sweepProvisioned: seams.sweepProvisioned,
        clearReachabilityStamp: seams.clearReachabilityStamp,
        purchases: identity,
      );
      await service.restore();

      await expectLater(service.markPremiumPending(), throwsStateError);
      clockThrows = false;

      expect(
        await service.markPremiumPending().timeout(const Duration(seconds: 5)),
        isTrue,
      );
      expect(service.session!.premiumPendingSince, clock.now);
      expect((await stored()).premiumPendingSince, clock.now);
    });
  });

  group('sign-out', () {
    // The tunnel stops first because it is the thing using the
    // credentials being deleted.
    test('the steps run in the pinned order', () async {
      final service = await signedIn(stampedAt: clock.now);

      await service.signOut();

      expect(log, <String>[
        'stopTunnel',
        'sweepProvisioned',
        'clear',
        'clearLastRefreshAt',
        'clearReachabilityStamp',
      ]);
    });

    // The bump fences an in-flight refresh, so it must land before the
    // awaited sweep, not at the last step. Reading the epoch from inside
    // the sweep seam proves it already moved.
    test('the epoch advances before the sweep, not at the last step', () async {
      await store.inner.write(testSession());
      late OneVpnAccountService service;
      int? epochAtSweep;
      service = OneVpnAccountService(
        store: store,
        api: api,
        now: clock.call,
        stopTunnel: seams.stopTunnel,
        sweepProvisioned: () async {
          epochAtSweep = service.epoch;
          return OneVpnSweepResult.unwired;
        },
        clearReachabilityStamp: seams.clearReachabilityStamp,
      );
      await service.restore();
      final epochBefore = service.epoch;

      await service.signOut();

      expect(epochAtSweep, isNotNull);
      expect(epochAtSweep, greaterThan(epochBefore));
    });

    test('a clean sweep reports every step and still says the token may '
        'remain', () async {
      final service = await signedIn();
      seams.sweep = const OneVpnSweepResult(
        nodesSwept: true,
        filesCleared: true,
      );

      final report = await service.signOut();

      expect(report.tunnelStopped, isTrue);
      expect(report.sessionCleared, isTrue);
      expect(report.nodesSwept, isTrue);
      expect(report.filesNotCleared, isFalse);
      expect(report.cooldownCleared, isTrue);
      expect(report.reachabilityStampCleared, isTrue);
      expect(report.clean, isTrue);
      expect(report.detail, isEmpty);
      // The API has no logout endpoint.
      expect(report.tokenMayRemain, isTrue);
    });

    test(
      'with no provisioner bound the report says the nodes stayed',
      () async {
        final service = await signedIn();

        final report = await service.signOut();

        expect(report.nodesSwept, isFalse);
        expect(report.filesNotCleared, isTrue);
        expect(report.clean, isFalse);
        expect(report.detail, contains(OneVpnSweepResult.unwired.detail));
        // The session is still cleared. Clearing it must not depend on an
        // unfilled seam.
        expect(report.sessionCleared, isTrue);
        expect(service.state.value, isA<OneVpnAccountSignedOut>());
      },
    );

    test(
      'a throwing tunnel stop does not skip the rest of the sweep',
      () async {
        final service = await signedIn();
        seams.throwOnTunnel = true;

        final report = await service.signOut();

        expect(report.tunnelStopped, isFalse);
        expect(report.detail.first, contains('tunnel stop threw'));
        expect(
          log,
          containsAllInOrder(<String>[
            'stopTunnel',
            'clear',
            'clearReachabilityStamp',
          ]),
        );
        expect(report.sessionCleared, isTrue);
        expect(service.state.value, isA<OneVpnAccountSignedOut>());
      },
    );

    test(
      'a tunnel stop that reports failure is recorded, not assumed',
      () async {
        final service = await signedIn();
        seams.tunnelStops = false;

        final report = await service.signOut();

        expect(report.tunnelStopped, isFalse);
        expect(report.detail.first, contains('reported failure'));
      },
    );

    test(
      'a throwing store clear does not skip the rest of the sweep',
      () async {
        final service = await signedIn();
        store.throwOnClear = true;

        final report = await service.signOut();

        expect(report.sessionCleared, isFalse);
        expect(report.cooldownCleared, isTrue);
        expect(report.reachabilityStampCleared, isTrue);
        expect(log, contains('clearReachabilityStamp'));
        // Sign-out never fails, whatever the steps did.
        expect(service.state.value, isA<OneVpnAccountSignedOut>());
      },
    );

    test('a throwing sweep does not skip the rest', () async {
      final service = await signedIn();
      seams.throwOnSweep = true;

      final report = await service.signOut();

      expect(report.nodesSwept, isFalse);
      expect(report.detail.first, contains('node sweep threw'));
      expect(report.sessionCleared, isTrue);
    });

    test('a throwing stamp clear is recorded and the user still signs '
        'out', () async {
      final service = await signedIn();
      seams.throwOnStampClear = true;

      final report = await service.signOut();

      expect(report.reachabilityStampCleared, isFalse);
      expect(report.detail.last, contains('reachability stamp clear threw'));
      expect(service.state.value, isA<OneVpnAccountSignedOut>());
    });

    test('the cooldown stamp and the reachability stamp both go', () async {
      final service = await signedIn(stampedAt: clock.now);

      final report = await service.signOut();

      expect(await store.inner.readLastRefreshAt(), isNull);
      expect(report.reachabilityStampCleared, isTrue);
      expect(log, contains('clearReachabilityStamp'));
    });

    test('signing out while restoring waits for the gate', () async {
      await store.inner.write(testSession());
      final service = build();

      final report = await service.signOut();

      expect(report.sessionCleared, isTrue);
      expect(service.state.value, isA<OneVpnAccountSignedOut>());
      expect(store.inner.document, isNull);
    });
  });

  group('the purchase identity', () {
    OneVpnUserData adopted({String username = 'adopted-uuid'}) =>
        OneVpnUserData(
          username: username,
          email: 'other@example.invalid',
          isPremium: false,
          sessionAuthToken: 'token-adopted',
          credentials: testCredentials,
          locations: const <OneVpnApiLocation>[],
        );

    test('restoring a stored session identifies its email', () async {
      await store.inner.write(testSession());
      final service = build();

      await service.restore();

      expect(identity.calls, ['identify:someone@example.invalid']);
      expect(service.isSignedIn, isTrue);
    });

    test('restoring with no stored session calls nothing', () async {
      final service = build();

      await service.restore();

      expect(identity.calls, isEmpty);
    });

    test('restoring an unreadable document calls nothing', () async {
      store.inner.document = 'not json at all';
      final service = build();

      await service.restore();

      expect(identity.calls, isEmpty);
    });

    test('adopting a session identifies it after the state flips', () async {
      final service = build();
      await service.restore();
      String? emailAtCall;
      identity.onCall = (_) => emailAtCall = service.session?.email;

      await service.adoptSession(adopted());

      expect(identity.calls, ['identify:other@example.invalid']);
      expect(emailAtCall, 'other@example.invalid');
    });

    test('identify names the session email, never the username', () async {
      await store.inner.write(
        testSession().copyWith(
          username: 'stored-handle',
          email: 'holder@example.invalid',
        ),
      );
      final service = build();

      await service.restore();
      await service.adoptSession(adopted());

      expect(identity.calls, [
        'identify:holder@example.invalid',
        'identify:other@example.invalid',
      ]);
      expect(identity.calls, isNot(contains('identify:stored-handle')));
      expect(identity.calls, isNot(contains('identify:adopted-uuid')));
    });

    test('sign-out forgets after the epoch bump', () async {
      final service = await signedIn();
      final epochBefore = service.epoch;
      int? epochAtCall;
      OneVpnAccountState? stateAtCall;
      identity.onCall = (_) {
        epochAtCall = service.epoch;
        stateAtCall = service.state.value;
      };

      await service.signOut();

      expect(identity.calls, ['forget']);
      expect(epochAtCall, greaterThan(epochBefore));
      expect(stateAtCall, isA<OneVpnAccountSignedOut>());
    });

    test('a 401 refresh forgets once, through sign-out', () async {
      final service = await signedIn();
      api.userData = const OneVpnApiRejected<OneVpnUserData>(
        status: 401,
        message: 'unauthorised',
      );

      await service.refresh(manual: true);

      expect(identity.calls, ['forget']);
    });

    test('a throwing forget still leaves the state signed out', () async {
      for (final sync in <bool>[false, true]) {
        identity
          ..throwSync = false
          ..throwAsync = false;
        final service = await signedIn();
        identity
          ..throwSync = sync
          ..throwAsync = !sync;

        final report = await service.signOut();
        await pumpEventQueue();

        expect(service.state.value, isA<OneVpnAccountSignedOut>());
        expect(report.sessionCleared, isTrue);
        expect(report.detail.where((line) => line.contains('forget')), isEmpty);
        expect(identity.calls, ['forget']);
      }
    });

    test('a throwing identify changes no account state', () async {
      for (final sync in <bool>[false, true]) {
        identity
          ..calls.clear()
          ..throwSync = sync
          ..throwAsync = !sync;
        await store.inner.write(testSession());
        final service = build();

        await service.restore();
        await service.adoptSession(adopted());
        await pumpEventQueue();

        expect(service.state.value, isA<OneVpnAccountSignedIn>());
        expect(service.session!.username, 'adopted-uuid');
        expect(identity.calls, [
          'identify:someone@example.invalid',
          'identify:other@example.invalid',
        ]);
      }
    });
  });

  group('the session-change signal', () {
    test('every settled state reaches a listener', () async {
      await store.inner.write(testSession());
      final service = build();
      final seen = <OneVpnAccountState>[];
      service.state.addListener(() => seen.add(service.state.value));

      await service.restore();
      api.userData = OneVpnApiSuccess<OneVpnUserData>(testUserData());
      api.rotated = const OneVpnApiSuccess<String>('token-new');
      await service.refresh(manual: true);
      await service.signOut();

      expect(seen.map((state) => state.runtimeType).toList(), <Type>[
        OneVpnAccountSignedIn,
        OneVpnAccountSignedIn,
        OneVpnAccountSignedOut,
      ]);
    });
  });
}

/// Answers each request from [handler] and records its host and path.
final class _HostAdapter implements HttpClientAdapter {
  _HostAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;
  final List<String> requests = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add('${options.uri.host}${options.uri.path}');
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonBody(int status, Object body) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: <String, List<String>>{
    Headers.contentTypeHeader: <String>[Headers.jsonContentType],
  },
);

const Map<String, dynamic> _userDataJson = <String, dynamic>{
  'username': 'someone',
  'email': 'someone@example.invalid',
  'isPremium': true,
  'uuid': 'uuid-1',
  'publicKey': 'pbk-1',
  'shortId': 'sid-1',
  'locations': <dynamic>[],
};
