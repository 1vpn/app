// The account state machine over the credential store and the account
// endpoints.
//
// Every refresh returns one of four sealed outcomes and every sign-out
// returns a per-step report. Nothing in here reports a failure by
// throwing out of a call a caller made to learn an answer.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:onexray/onevpn/account/credential_store.dart';
import 'package:onexray/onevpn/account/outcomes.dart';
import 'package:onexray/onevpn/account/refresh_cooldown.dart';
import 'package:onexray/onevpn/account/session.dart';
import 'package:onexray/onevpn/data/account_api.dart';
import 'package:onexray/onevpn/model/user_data.dart';
import 'package:onexray/onevpn/net/api_transport.dart';
import 'package:onexray/onevpn/provision/sign_out_sweep.dart';
import 'package:onexray/onevpn/purchase/purchase_backend.dart';
import 'package:onexray/onevpn/purchase/purchase_service.dart';
import 'package:onexray/service/connect/coordinator.dart';

/// How long an unconfirmed premium grant survives a refresh that reports
/// the account as not premium.
///
/// The server confirms a purchase through a propagation the client
/// cannot observe. Inside this window, a not-premium answer keeps the
/// grant.
const Duration kOneVpnPremiumConfirmationGrace = Duration(hours: 48);

/// Where the account is, as far as this process knows.
sealed class OneVpnAccountState {
  const OneVpnAccountState();
}

/// The store has not answered yet. No decision point may read this as
/// signed out.
final class OneVpnAccountRestoring extends OneVpnAccountState {
  const OneVpnAccountRestoring();
}

/// No session is stored.
final class OneVpnAccountSignedOut extends OneVpnAccountState {
  const OneVpnAccountSignedOut();
}

/// A session is stored and decoded.
final class OneVpnAccountSignedIn extends OneVpnAccountState {
  const OneVpnAccountSignedIn(this.session);

  final OneVpnSession session;
}

/// A document is stored and could not be read. This state is distinct
/// from signed out, and the document stays on disk.
final class OneVpnAccountUnreadable extends OneVpnAccountState {
  const OneVpnAccountUnreadable(this.detail);

  final String detail;
}

/// Stops the tunnel and reports whether the stop completed.
typedef OneVpnTunnelStop = Future<bool> Function();

/// Removes provisioned rows and runtime files, reporting each.
typedef OneVpnProvisionedSweep = Future<OneVpnSweepResult> Function();

/// Clears the launch reachability stamp. The remembered failover domain
/// survives it.
typedef OneVpnReachabilityStampClear = Future<void> Function();

/// Owns the session: restores it, refreshes it, and ends it.
///
/// Every seam is a constructor argument: the clock, the endpoint client,
/// the store, the three sign-out steps, and the purchase service. The whole
/// machine runs offline against fakes.
///
/// The purchase identity follows the session. Restoring or adopting a
/// session identifies it to the purchase service. Sign-out forgets it. Both
/// calls are detached: a purchase service failure never changes the
/// account state.
class OneVpnAccountService {
  OneVpnAccountService({
    this._store = const OneVpnPrefsCredentialStore(),
    OneVpnAccountApi? api,
    DateTime Function()? now,
    OneVpnTunnelStop? stopTunnel,
    OneVpnProvisionedSweep? sweepProvisioned,
    OneVpnReachabilityStampClear? clearReachabilityStamp,
    OneVpnPurchaseService? purchases,
    this.cooldown = kOneVpnRefreshCooldown,
    this.premiumConfirmationGrace = kOneVpnPremiumConfirmationGrace,
  }) : _api = api ?? OneVpnAccountApi(),
       _now = now ?? DateTime.now,
       _stopTunnel = stopTunnel ?? _stopSharedTunnel,
       _sweepProvisioned = sweepProvisioned ?? _sweepNothing,
       _clearReachabilityStamp =
           clearReachabilityStamp ?? _clearSharedReachabilityStamp,
       _purchases = purchases ?? oneVpnPurchaseBackend();

  /// The one instance per process that every fork surface reads. It binds
  /// the real sign-out sweep to step 3. The default constructor leaves
  /// step 3 unwired for isolated tests.
  static final OneVpnAccountService instance = OneVpnAccountService(
    sweepProvisioned: oneVpnSignOutSweep,
  );

  final OneVpnCredentialStore _store;
  final OneVpnAccountApi _api;
  final DateTime Function() _now;
  final OneVpnTunnelStop _stopTunnel;
  final OneVpnProvisionedSweep _sweepProvisioned;
  final OneVpnReachabilityStampClear _clearReachabilityStamp;
  final OneVpnPurchaseService _purchases;

  /// The shortest interval between two background refreshes.
  final Duration cooldown;

  /// How long an unconfirmed premium grant survives a not-premium answer.
  final Duration premiumConfirmationGrace;

  final ValueNotifier<OneVpnAccountState> _state =
      ValueNotifier<OneVpnAccountState>(const OneVpnAccountRestoring());

  Future<void>? _restoring;
  Future<OneVpnRefreshOutcome>? _inFlight;

  /// Advances whenever the stored session stops being the one a running
  /// refresh started against. A refresh that completes across a bump
  /// drops its result. It writes no document for a session that is gone.
  ///
  /// Each flip that replaces or ends the session bumps the epoch in the
  /// same step, with no await between them. An adoption also bumps it at
  /// the call. A refresh reads the epoch in the same step as the session.
  int _epoch = 0;

  /// The completer of the last section queued on the mutation chain. It
  /// completes when that section settles. Null before the first section.
  /// See [_mutate].
  Completer<void>? _tail;

  /// The current fence value. A test reads it to pin one order: sign-out
  /// advances the epoch before the sweep runs.
  @visibleForTesting
  int get epoch => _epoch;

  /// The session-change signal. A caller that reacts to session changes
  /// listens here. The caller decides which changes matter.
  ValueListenable<OneVpnAccountState> get state => _state;

  /// The stored session, or null unless the state is signed in.
  OneVpnSession? get session => switch (_state.value) {
    OneVpnAccountSignedIn(:final session) => session,
    _ => null,
  };

  bool get isSignedIn => _state.value is OneVpnAccountSignedIn;

  /// Reads the store and settles the state. Idempotent: the first call
  /// does the work and every later call awaits the same result.
  Future<void> restore() => _restoring ??= _restore();

  /// The gate every consumer awaits before reading the state. It starts
  /// the restore if nothing has. The gate always opens.
  Future<void> whenRestored() => restore();

  Future<void> _restore() async {
    try {
      final stored = await _store.read();
      _state.value = switch (stored) {
        OneVpnSessionAbsent() => const OneVpnAccountSignedOut(),
        OneVpnSessionRestored(:final session) => OneVpnAccountSignedIn(session),
        OneVpnSessionUnreadable(:final detail) => OneVpnAccountUnreadable(
          detail,
        ),
      };
    } catch (error) {
      // A throwing store reads as unreadable, not signed out. The free
      // tier keeps working.
      _state.value = OneVpnAccountUnreadable(
        'session store threw: ${error.runtimeType}',
      );
    }
    final restored = _state.value;
    if (restored is OneVpnAccountSignedIn) _identify(restored.session);
  }

  /// When a refresh last succeeded or a sign-in adopted the session, or
  /// null when neither has or the stamp cannot be read.
  Future<DateTime?> lastRefreshAt() async {
    try {
      return await _store.readLastRefreshAt();
    } catch (_) {
      return null;
    }
  }

  /// Adopts a session handed over by a completed sign-in.
  ///
  /// Writes the session and flips the state as one section of the mutation
  /// chain. Bumps the epoch at the call: a refresh in flight then drops its
  /// result, a 401 included. Bumps it again at the flip: a refresh that
  /// started before the flip never commits over this session.
  ///
  /// Stamps the cooldown with the adoption time. The sign-in answer is
  /// fresh user data, so a resume inside the cooldown dials nothing. A
  /// launch still refreshes, because it skips the cooldown.
  Future<void> adoptSession(OneVpnUserData data) async {
    await whenRestored();
    final adopted = OneVpnSession.fromUserData(data);
    _epoch++;
    await _mutate(() async {
      try {
        await _store.write(adopted);
      } catch (_) {
        // A refused write costs persistence, not the session. The adopted
        // session stands in memory for this run. The next refresh restamps
        // it. Sign-in never throws back at its caller.
      }
      try {
        await _store.writeLastRefreshAt(_now());
      } catch (_) {
        // A lost stamp costs at most one early background refresh.
      }
      // Must run with the flip: a refresh that read the old session under
      // the call's epoch then drops its result.
      _epoch++;
      _inFlight = null;
      _state.value = OneVpnAccountSignedIn(adopted);
      _identify(adopted);
    });
  }

  /// Records an optimistic premium grant. A completed purchase unlocks
  /// before the server confirms it.
  ///
  /// Grants only while signed in. A signed-out purchase records nothing
  /// locally on any platform. The grant runs as one section of the mutation
  /// chain and marks the live session. A refresh commit queued before it
  /// publishes the rotated token first. A commit queued after it carries
  /// the marker. A sign-out or an adoption that lands between the call and
  /// the publish drops the grant unpublished. Returns whether the grant was
  /// written and published.
  Future<bool> markPremiumPending() async {
    await whenRestored();
    final epoch = _epoch;
    return _mutate(() async {
      final current = _state.value;
      if (_epoch != epoch || current is! OneVpnAccountSignedIn) return false;
      final marked = current.session.copyWith(
        premiumPendingSince: _now().toUtc(),
      );
      try {
        await _store.write(marked);
      } catch (_) {
        return false;
      }
      if (_epoch != epoch) return false;
      _state.value = OneVpnAccountSignedIn(marked);
      return true;
    });
  }

  /// Revalidates the session against the server.
  ///
  /// [manual] is true when the user asked, and on an app open. A manual
  /// refresh ignores the cooldown. It still stamps on success.
  ///
  /// A pending premium grant also bypasses the cooldown. A webhook that
  /// lands after the confirmation poll confirms on the next resume or cold
  /// start.
  ///
  /// Concurrent callers share one in-flight refresh. The token rotates at
  /// most once, however many triggers fire together.
  Future<OneVpnRefreshOutcome> refresh({required bool manual}) async {
    await whenRestored();
    final current = _state.value;
    if (current is! OneVpnAccountSignedIn) return const OneVpnNoSession();
    final session = current.session;
    // Read with the session, before the cooldown read below yields.
    final epoch = _epoch;

    if (!manual &&
        !session.isPremiumPending &&
        !isRefreshDue(await lastRefreshAt(), _now(), cooldown: cooldown) &&
        _epoch == epoch) {
      return OneVpnKept(
        session: session,
        reason: OneVpnKeptReason.cooldown,
        detail: 'the refresh cooldown has not elapsed',
      );
    }
    // An adoption or a sign-out during the cooldown read replaces or ends
    // the session read above.
    if (_epoch != epoch) return const OneVpnNoSession();

    final pending = _inFlight;
    if (pending != null) return pending;

    final started = _run(session, epoch);
    _inFlight = started;
    try {
      return await started;
    } finally {
      if (identical(_inFlight, started)) _inFlight = null;
    }
  }

  /// Fetches outside the mutation chain, then commits inside it.
  Future<OneVpnRefreshOutcome> _run(OneVpnSession session, int epoch) async {
    final token = session.sessionAuthToken;

    // The token rotates only after the entitlement fetch succeeds. A
    // failed fetch keeps the session on a token the server has not retired.
    final fetched = await _api.fetchUserData(authToken: token);
    if (fetched is OneVpnApiFailure<OneVpnUserData>) {
      return _fromFailure(session, fetched, epoch);
    }

    final rotated = await _api.refreshToken(authToken: token);
    if (rotated is OneVpnApiFailure<String>) {
      return _fromFailure(session, rotated, epoch);
    }

    final data = (fetched as OneVpnApiSuccess<OneVpnUserData>).data;
    final rotatedToken = (rotated as OneVpnApiSuccess<String>).data;
    return _mutate(() => _commit(data, rotatedToken, epoch));
  }

  Future<OneVpnRefreshOutcome> _fromFailure<T>(
    OneVpnSession session,
    OneVpnApiFailure<T> failure,
    int epoch,
  ) async {
    // The session this refresh started against is gone. The refresh
    // reports no session.
    if (_epoch != epoch) return const OneVpnNoSession();

    final OneVpnKeptReason reason;
    switch (failure) {
      case OneVpnApiRejected<T>():
        // Only an authoritative 401 ends a session. A timeout, a refused
        // connection, a 5xx, or an undecodable body keeps the session.
        if (failure.isUnauthorised) return OneVpnSignedOut(await signOut());
        reason = OneVpnKeptReason.rejected;
      case OneVpnApiUnreachable<T>():
        reason = OneVpnKeptReason.unreachable;
      case OneVpnApiMalformed<T>():
        reason = OneVpnKeptReason.malformed;
    }
    return OneVpnKept(
      session: session,
      reason: reason,
      detail: failure.description,
    );
  }

  /// The single place the session document is rewritten.
  ///
  /// Commits against the live session, not the snapshot the refresh
  /// started against. A sign-out or an adoption during the round trip
  /// moves the epoch or flips the state. The commit then drops the result
  /// for the gone session. The epoch is read again after each store write,
  /// so a move during a write also drops the result unpublished. The
  /// commit reads the pending-premium marker from the live session. A
  /// marker written while the refresh was in flight survives the commit.
  ///
  /// Runs as one section of the mutation chain. No grant reads or writes
  /// the session between the commit's read and its publish.
  Future<OneVpnRefreshOutcome> _commit(
    OneVpnUserData data,
    String rotatedToken,
    int epoch,
  ) async {
    final current = _state.value;
    if (_epoch != epoch || current is! OneVpnAccountSignedIn) {
      return const OneVpnNoSession();
    }
    final live = current.session;

    final now = _now();

    // An empty locations payload updates the token and the entitlement.
    // The cached catalogue stays.
    final serverSentNoLocations = data.locations.isEmpty;
    final locations = serverSentNoLocations ? live.locations : data.locations;

    var marker = live.premiumPendingSince;
    var premiumUnconfirmed = false;
    if (marker != null) {
      if (data.isPremium) {
        marker = null;
      } else {
        // A marker timestamped in the future has a negative age. It reads
        // as inside the window. A clock change never rolls a paying user
        // back.
        final age = now.difference(marker);
        if (age < premiumConfirmationGrace) {
          premiumUnconfirmed = true;
        } else {
          marker = null;
        }
      }
    }

    final next = OneVpnSession(
      sessionAuthToken: rotatedToken,
      username: data.username,
      email: data.email,
      isPremium: data.isPremium,
      credentials: data.credentials,
      locations: locations,
      premiumPendingSince: marker,
    );

    Object? refused;
    try {
      await _store.write(next);
    } catch (error) {
      refused = error;
    }
    if (_epoch != epoch) return const OneVpnNoSession();
    if (refused != null) {
      // The server retired the presented token. The rotated session stands
      // in memory until the process ends, and the disk keeps the retired
      // token. A background refresh in this process still waits on the
      // stamp cooldown. The next refresh that runs rewrites the document. A
      // launch before that rewrite presents the retired token. The server
      // answers 401 and the session ends.
      _state.value = OneVpnAccountSignedIn(next);
      return OneVpnKept(
        session: next,
        reason: OneVpnKeptReason.unstored,
        detail: 'session store refused the write: ${refused.runtimeType}',
      );
    }

    try {
      await _store.writeLastRefreshAt(now);
    } catch (_) {
      // The refresh happened. A lost stamp costs one early refresh.
    }
    if (_epoch != epoch) return const OneVpnNoSession();

    _state.value = OneVpnAccountSignedIn(next);
    return OneVpnRefreshed(
      session: next,
      serverSentNoLocations: serverSentNoLocations,
      premiumUnconfirmed: premiumUnconfirmed,
    );
  }

  /// Ends the session and reports what each step achieved.
  ///
  /// The order is a contract. The tunnel stops first: it uses the
  /// credentials that the later steps delete. Every step is guarded.
  /// Sign-out records a failing step and runs the next one. The service
  /// goes signed out whatever the steps did.
  ///
  /// Leaves upstream preferences, geodata, user-added servers and the
  /// free catalogue alone. A signed-out device is a working free client.
  ///
  /// Keeps the remembered failover domain and starts no walk. The last
  /// step clears only the launch reachability stamp, so the next
  /// signed-out launch probes.
  ///
  /// Forgets the purchase identity at the epoch bump. The call is detached
  /// and reports nothing.
  Future<OneVpnSignOutReport> signOut() async {
    await whenRestored();
    final detail = <String>[];

    var tunnelStopped = false;
    try {
      tunnelStopped = await _stopTunnel();
      if (!tunnelStopped) detail.add('the tunnel stop reported failure');
    } catch (error) {
      detail.add('the tunnel stop threw: ${error.runtimeType}');
    }

    // The session ends here, at the epoch bump. The bump fences any
    // refresh in flight. Any refresh that starts from here reads signed
    // out. The state flips with the bump, before the sweep. A later flip
    // would let a refresh re-publish the ended session.
    _epoch++;
    _inFlight = null;
    _state.value = const OneVpnAccountSignedOut();
    _detach(_purchases.forget);

    var sweep = const OneVpnSweepResult(nodesSwept: false, filesCleared: false);
    try {
      sweep = await _sweepProvisioned();
    } catch (error) {
      detail.add('the node sweep threw: ${error.runtimeType}');
    }
    final sweepDetail = sweep.detail;
    if (sweepDetail != null) detail.add(sweepDetail);

    var sessionCleared = false;
    try {
      await _store.clear();
      sessionCleared = true;
    } catch (error) {
      detail.add('the session clear threw: ${error.runtimeType}');
    }

    var cooldownCleared = false;
    try {
      await _store.clearLastRefreshAt();
      cooldownCleared = true;
    } catch (error) {
      detail.add('the cooldown clear threw: ${error.runtimeType}');
    }

    var reachabilityStampCleared = false;
    try {
      await _clearReachabilityStamp();
      reachabilityStampCleared = true;
    } catch (error) {
      detail.add('the reachability stamp clear threw: ${error.runtimeType}');
    }

    return OneVpnSignOutReport(
      tunnelStopped: tunnelStopped,
      sessionCleared: sessionCleared,
      nodesSwept: sweep.nodesSwept,
      filesNotCleared: !sweep.filesCleared,
      cooldownCleared: cooldownCleared,
      reachabilityStampCleared: reachabilityStampCleared,
      detail: detail,
    );
  }

  /// Runs [section] as the next section of the mutation chain.
  ///
  /// A section reads the live session, writes the store and publishes the
  /// result. The sections are the premium grant, the refresh commit and the
  /// adoption. They run one at a time, in call order. No section reads a
  /// session that another has written but not yet published. An idle chain
  /// starts [section] at once.
  ///
  /// No network call runs inside the chain. A section awaits only the store.
  /// A section that awaits another section waits on itself and never
  /// settles.
  ///
  /// A section that throws never wedges the chain. Its error reaches its own
  /// caller, and the next section runs.
  ///
  /// Sign-out runs outside the chain and never waits on it. Its epoch bump
  /// fences a grant or a commit that is running or queued.
  Future<T> _mutate<T>(Future<T> Function() section) async {
    final previous = _tail;
    final settled = Completer<void>();
    _tail = settled;
    try {
      // A settled tail is never awaited. An await on a completed future
      // wakes through the zone that created it. That zone may no longer run.
      if (previous != null && !previous.isCompleted) await previous.future;
      return await section();
    } finally {
      settled.complete();
    }
  }

  /// Identifies [session] to the purchase service.
  ///
  /// The app user id is the session's email, as the user-data API returns it.
  /// The v2 app logs in with the same email, so each account keeps one store
  /// customer.
  void _identify(OneVpnSession session) =>
      _detach(() => _purchases.identify(session.email));

  /// Runs [call] without awaiting it and drops any error it raises.
  static void _detach(Future<void> Function() call) {
    try {
      unawaited(
        call().then<void>((_) {}, onError: (Object _, StackTrace _) {}),
      );
    } catch (_) {
      // A synchronous throw is dropped the same way.
    }
  }

  static Future<bool> _stopSharedTunnel() async {
    await ConnectionCoordinator.instance.disconnect();
    return true;
  }

  static Future<OneVpnSweepResult> _sweepNothing() async =>
      OneVpnSweepResult.unwired;

  static Future<void> _clearSharedReachabilityStamp() =>
      OneVpnApiTransport.instance.clearReachabilityStamp();
}
