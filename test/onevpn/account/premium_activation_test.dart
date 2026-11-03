// The optimistic premium grant and its confirmation poll.
//
// Two ordering rules are pinned here. The grant runs only against a session
// that has already flipped signed in. It is skipped when that session
// already reports premium.
//
// The suite pins the poll's bounds, its cooldown bypass, and both endings.
// One ending is confirmed. In the other, the window closes on a grant that
// the grace then carries.
//
// The delays are injected, so the suite runs the whole minute in no
// wall-clock time. The schedule holds offsets from the grant, so the poll
// sleeps the differences between them.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/account/outcomes.dart';
import 'package:onexray/onevpn/account/premium_activation.dart';
import 'package:onexray/onevpn/model/user_data.dart';
import 'package:onexray/onevpn/net/api_transport.dart';

import 'support.dart';

/// An account seam that answers from a script and records every call.
class _ScriptedAccount implements OneVpnPremiumAccount {
  _ScriptedAccount(OneVpnAccountState initial)
    : _state = ValueNotifier<OneVpnAccountState>(initial);

  final ValueNotifier<OneVpnAccountState> _state;

  @override
  ValueListenable<OneVpnAccountState> get state => _state;

  /// Every call in order, so the marker-before-poll ordering is assertable.
  final List<String> calls = <String>[];

  /// Outcomes for successive refreshes. The last one repeats.
  List<OneVpnRefreshOutcome> refreshOutcomes = const <OneVpnRefreshOutcome>[];

  /// Whether the marker write is accepted.
  bool markSucceeds = true;

  int _refreshes = 0;

  @override
  Future<bool> markPremiumPending() async {
    calls.add('markPremiumPending');
    final current = _state.value;
    if (current is! OneVpnAccountSignedIn || !markSucceeds) return false;
    _state.value = OneVpnAccountSignedIn(
      current.session.copyWith(premiumPendingSince: DateTime.utc(2026, 9, 21)),
    );
    return true;
  }

  @override
  Future<OneVpnRefreshOutcome> refresh({required bool manual}) async {
    calls.add('refresh(manual:$manual)');
    if (refreshOutcomes.isEmpty) return const OneVpnNoSession();
    final index = _refreshes < refreshOutcomes.length
        ? _refreshes
        : refreshOutcomes.length - 1;
    _refreshes++;
    final outcome = refreshOutcomes[index];
    if (outcome is OneVpnRefreshed) {
      _state.value = OneVpnAccountSignedIn(outcome.session);
    }
    return outcome;
  }
}

OneVpnRefreshOutcome _refreshed({required bool isPremium}) => OneVpnRefreshed(
  session: testSession(isPremium: isPremium),
  serverSentNoLocations: false,
  premiumUnconfirmed: !isPremium,
);

OneVpnRefreshOutcome _kept() => OneVpnKept(
  session: testSession(isPremium: false),
  reason: OneVpnKeptReason.unreachable,
  detail: 'no domain answered',
);

/// The wall-clock time a poll spent, which is what the last offset pins.
Duration _elapsed(List<Duration> gaps) =>
    gaps.fold(Duration.zero, (total, gap) => total + gap);

void main() {
  late List<Duration> waited;

  setUp(() => waited = <Duration>[]);

  OneVpnPremiumActivator activator(
    _ScriptedAccount account, {
    List<Duration>? schedule,
  }) => OneVpnPremiumActivator(
    account: account,
    schedule: schedule ?? kOneVpnPremiumConfirmSchedule,
    delay: (delay) async => waited.add(delay),
  );

  group('the await-then-guard ordering', () {
    test('records nothing against a session that has not flipped', () async {
      final account = _ScriptedAccount(const OneVpnAccountSignedOut());

      final result = await activator(account).activate();

      // The marker would be a no-op, so neither it nor the poll runs.
      expect(account.calls, isEmpty);
      expect(result.signedIn, isFalse);
      expect(result.markedPending, isFalse);
      expect(result.attempts, 0);
    });

    test('records nothing while the session is still restoring', () async {
      final account = _ScriptedAccount(const OneVpnAccountRestoring());

      final result = await activator(account).activate();

      expect(account.calls, isEmpty);
      expect(result.signedIn, isFalse);
    });

    test(
      'skips the marker when the adopted session is already premium',
      () async {
        // markPremiumPending has no premium guard of its own, so skipping
        // it is the caller's job.
        final account = _ScriptedAccount(
          OneVpnAccountSignedIn(testSession(isPremium: true)),
        );

        final result = await activator(account).activate();

        expect(account.calls, isEmpty);
        expect(result.alreadyPremium, isTrue);
        expect(result.markedPending, isFalse);
        expect(result.confirmed, isTrue);
        expect(result.attempts, 0);
        expect(waited, isEmpty);
      },
    );

    test('marks pending, before any poll, when the adopted session is '
        'not premium', () async {
      final account = _ScriptedAccount(
        OneVpnAccountSignedIn(testSession(isPremium: false)),
      )..refreshOutcomes = [_refreshed(isPremium: true)];

      final result = await activator(account).activate();

      expect(account.calls.first, 'markPremiumPending');
      expect(
        account.calls.where((call) => call == 'markPremiumPending').length,
        1,
      );
      expect(result.markedPending, isTrue);
      expect(result.alreadyPremium, isFalse);
    });

    test('the marker makes the session read as entitled at once', () async {
      final account = _ScriptedAccount(
        OneVpnAccountSignedIn(testSession(isPremium: false)),
      )..refreshOutcomes = [_refreshed(isPremium: false)];

      final entitled = <bool>[];
      account.state.addListener(() {
        final state = account.state.value;
        if (state is OneVpnAccountSignedIn) {
          entitled.add(state.session.isPremiumEntitled);
        }
      });

      await activator(account).activate();

      // The first state the buyer can observe after paying is entitled. The
      // UI never flashes Free between the purchase and the confirmation.
      expect(entitled.first, isTrue);
    });
  });

  group('the confirmation poll', () {
    test('stops at the attempt the server confirms', () async {
      final account =
          _ScriptedAccount(OneVpnAccountSignedIn(testSession(isPremium: false)))
            ..refreshOutcomes = [
              _refreshed(isPremium: false),
              _refreshed(isPremium: true),
              _refreshed(isPremium: true),
            ];

      final result = await activator(account).activate();

      expect(result.confirmed, isTrue);
      expect(result.unconfirmed, isFalse);
      expect(result.attempts, 2);
      expect(waited, const [Duration(seconds: 3), Duration(seconds: 5)]);
      // Attempt two lands on its own offset, 8s from the grant.
      expect(_elapsed(waited), kOneVpnPremiumConfirmSchedule[1]);
    });

    test(
      'spends the whole schedule and leaves the grant unconfirmed',
      () async {
        final account = _ScriptedAccount(
          OneVpnAccountSignedIn(testSession(isPremium: false)),
        )..refreshOutcomes = [_refreshed(isPremium: false)];

        final result = await activator(account).activate();

        expect(result.attempts, kOneVpnPremiumConfirmSchedule.length);
        expect(result.confirmed, isFalse);
        // The grant stands. The service's grace carries it from here.
        expect(result.unconfirmed, isTrue);
        // The gaps between the five offsets, not the offsets themselves.
        expect(waited, const [
          Duration(seconds: 3),
          Duration(seconds: 5),
          Duration(seconds: 10),
          Duration(seconds: 17),
          Duration(seconds: 20),
        ]);
        expect(_elapsed(waited), const Duration(seconds: 55));
        expect(_elapsed(waited), kOneVpnPremiumConfirmSchedule.last);
      },
    );

    test('a refresh that reached no verdict burns an attempt and the poll '
        'continues', () async {
      final account = _ScriptedAccount(
        OneVpnAccountSignedIn(testSession(isPremium: false)),
      )..refreshOutcomes = [_kept(), _kept(), _refreshed(isPremium: true)];

      final result = await activator(account).activate();

      expect(result.attempts, 3);
      expect(result.confirmed, isTrue);
    });

    test('every attempt bypasses the refresh cooldown', () async {
      final account = _ScriptedAccount(
        OneVpnAccountSignedIn(testSession(isPremium: false)),
      )..refreshOutcomes = [_refreshed(isPremium: false)];

      await activator(account).activate();

      final refreshes = account.calls.where(
        (call) => call.startsWith('refresh'),
      );
      expect(refreshes, isNotEmpty);
      expect(refreshes.every((call) => call == 'refresh(manual:true)'), isTrue);
    });

    test('the schedule stays inside the endpoint budget', () {
      // The account endpoint allows ten calls a minute, and other refreshes
      // share that budget. The last entry is the whole window: the entries
      // are offsets from the grant.
      expect(kOneVpnPremiumConfirmSchedule, hasLength(5));
      expect(
        kOneVpnPremiumConfirmSchedule.last,
        lessThanOrEqualTo(const Duration(seconds: 60)),
      );
      for (var i = 1; i < kOneVpnPremiumConfirmSchedule.length; i++) {
        expect(
          kOneVpnPremiumConfirmSchedule[i],
          greaterThan(kOneVpnPremiumConfirmSchedule[i - 1]),
          reason: 'the schedule must space attempts out, not tighten them',
        );
      }
    });

    test('polls even when the marker was refused', () async {
      // A refused marker costs the buyer the unlocked UI. The poll is what
      // fetches real premium, so it still runs.
      final account =
          _ScriptedAccount(OneVpnAccountSignedIn(testSession(isPremium: false)))
            ..markSucceeds = false
            ..refreshOutcomes = [_refreshed(isPremium: true)];

      final result = await activator(account).activate();

      expect(result.markedPending, isFalse);
      expect(result.attempts, 1);
      expect(result.confirmed, isTrue);
    });

    test('a session that ends mid-poll stops the poll', () async {
      final account =
          _ScriptedAccount(OneVpnAccountSignedIn(testSession(isPremium: false)))
            ..refreshOutcomes = [
              _refreshed(isPremium: false),
              OneVpnSignedOut(
                OneVpnSignOutReport(
                  tunnelStopped: true,
                  sessionCleared: true,
                  nodesSwept: true,
                  filesNotCleared: false,
                  cooldownCleared: true,
                  reachabilityStampCleared: true,
                ),
              ),
            ];

      final result = await activator(account).activate();

      expect(result.attempts, 2);
      expect(result.confirmed, isFalse);
    });
  });

  group('against the real account service', () {
    late List<String> log;
    late RecordingStore store;
    late ScriptedApi api;
    late FakeClock clock;

    setUp(() {
      log = <String>[];
      store = RecordingStore(log);
      api = ScriptedApi();
      clock = FakeClock(DateTime.utc(2026, 9, 21, 12));
    });

    Future<OneVpnAccountService> signedInFree() async {
      await store.inner.write(testSession(isPremium: false));
      final service = OneVpnAccountService(
        store: store,
        api: api,
        now: clock.call,
        stopTunnel: () async => true,
        sweepProvisioned: () async => OneVpnSweepResult.unwired,
        clearReachabilityStamp: () async {},
      );
      await service.restore();
      return service;
    }

    test(
      'a confirming poll clears the marker and leaves real premium',
      () async {
        final service = await signedInFree();
        api.rotated = const OneVpnApiSuccess<String>('token-new');
        api.userData = OneVpnApiSuccess<OneVpnUserData>(
          testUserData(isPremium: false),
        );

        final result = await OneVpnPremiumActivator(
          account: OneVpnServicePremiumAccount(service: service),
          delay: (delay) async {
            waited.add(delay);
            // The webhook lands between the second and third attempts.
            if (waited.length == 3) {
              api.userData = OneVpnApiSuccess<OneVpnUserData>(testUserData());
            }
          },
        ).activate();

        expect(result.markedPending, isTrue);
        expect(result.confirmed, isTrue);
        expect(result.attempts, 3);
        expect(service.session!.isPremium, isTrue);
        expect(service.session!.premiumPendingSince, isNull);
      },
    );

    test('the window closing leaves the grant on the grace, which then '
        'rolls it back', () async {
      final service = await signedInFree();
      api.rotated = const OneVpnApiSuccess<String>('token-new');
      api.userData = OneVpnApiSuccess<OneVpnUserData>(
        testUserData(isPremium: false),
      );

      final result = await OneVpnPremiumActivator(
        account: OneVpnServicePremiumAccount(service: service),
        delay: (delay) async => waited.add(delay),
      ).activate();

      // The poll spends every attempt and confirms nothing. The buyer still
      // reads as entitled, because the grace carries the grant.
      expect(result.unconfirmed, isTrue);
      expect(result.attempts, kOneVpnPremiumConfirmSchedule.length);
      expect(_elapsed(waited), kOneVpnPremiumConfirmSchedule.last);
      expect(service.session!.premiumPendingSince, isNotNull);
      expect(service.session!.isPremium, isFalse);
      expect(service.session!.isPremiumEntitled, isTrue);

      // Still inside the grace, an ordinary refresh keeps it.
      clock.advance(const Duration(hours: 47));
      await service.refresh(manual: true);
      expect(service.session!.isPremiumEntitled, isTrue);

      // Past the grace the service revokes it. No surface promises the
      // confirmation will arrive.
      clock.advance(const Duration(hours: 2));
      await service.refresh(manual: true);
      expect(service.session!.premiumPendingSince, isNull);
      expect(service.session!.isPremiumEntitled, isFalse);
    });
  });
}
