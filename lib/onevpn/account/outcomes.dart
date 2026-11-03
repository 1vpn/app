// The sealed results of a refresh and of a sign-out.
//
// Every account failure is a value here. Nothing in this layer reports a
// failure by logging it or by doing nothing.

import 'package:onexray/onevpn/account/session.dart';

/// Why a refresh left the stored session in place.
enum OneVpnKeptReason {
  /// No domain answered. This is the censorship signal. On its own it
  /// never ends a session.
  unreachable,

  /// A domain answered and rejected the call with a status other than
  /// 401. The account is not implicated.
  rejected,

  /// A domain answered with a body this client could not use.
  malformed,

  /// The cooldown had not elapsed, so no call was made.
  cooldown,

  /// The server answered and the store refused the rewritten document.
  /// The rotated session stands in memory until the process ends. The
  /// session on disk holds the retired token. A background refresh in this
  /// process still waits on the stamp cooldown. The next refresh that runs
  /// rewrites the document. A launch before that rewrite presents the
  /// retired token. The server answers 401 and the session ends.
  unstored,
}

/// The result of one refresh: exactly four outcomes. A caller must handle
/// all four.
sealed class OneVpnRefreshOutcome {
  const OneVpnRefreshOutcome();
}

/// The server answered and the session document was rewritten.
final class OneVpnRefreshed extends OneVpnRefreshOutcome {
  const OneVpnRefreshed({
    required this.session,
    required this.serverSentNoLocations,
    required this.premiumUnconfirmed,
  });

  /// The rewritten document: rotated token, server entitlement, and the
  /// merged locations.
  final OneVpnSession session;

  /// The server sent an empty locations list and the cached catalogue was
  /// kept. An empty payload never erases what the user already had.
  final bool serverSentNoLocations;

  /// The server reported not premium inside the pending grant's
  /// confirmation window. The grant survived this refresh.
  final bool premiumUnconfirmed;
}

/// The refresh failed in a way that says nothing about the account. The
/// session stands, and the cooldown stays unstamped.
final class OneVpnKept extends OneVpnRefreshOutcome {
  const OneVpnKept({
    required this.session,
    required this.reason,
    required this.detail,
  });

  /// The session in memory after the refresh. For
  /// [OneVpnKeptReason.unstored] it is the rotated session. For every
  /// other reason it is the stored session, unchanged.
  final OneVpnSession session;

  final OneVpnKeptReason reason;

  /// One line naming the failure, safe to show and to paste into a
  /// report.
  final String detail;
}

/// The server rejected the stored token with a 401 and the sign-out flow
/// ran.
final class OneVpnSignedOut extends OneVpnRefreshOutcome {
  const OneVpnSignedOut(this.report);

  final OneVpnSignOutReport report;
}

/// There was nothing to refresh, and no call was made.
final class OneVpnNoSession extends OneVpnRefreshOutcome {
  const OneVpnNoSession();
}

/// What the provisioned-node and runtime-file sweep managed to do.
class OneVpnSweepResult {
  const OneVpnSweepResult({
    required this.nodesSwept,
    required this.filesCleared,
    this.detail,
  });

  /// True when the provisioned rows were removed.
  final bool nodesSwept;

  /// True when the runtime files were removed.
  final bool filesCleared;

  /// One line naming what the sweep did or could not do.
  final String? detail;

  /// The sweep of a build with no provisioner bound to the seam. It
  /// reports both steps as not done.
  static const unwired = OneVpnSweepResult(
    nodesSwept: false,
    filesCleared: false,
    detail: 'no provisioner is bound: nodes and runtime files are untouched',
  );
}

/// What a sign-out achieved, step by step.
///
/// Sign-out never fails: the service goes signed out whatever the steps
/// did. The report tells a caller what each step left behind.
class OneVpnSignOutReport {
  OneVpnSignOutReport({
    required this.tunnelStopped,
    required this.sessionCleared,
    required this.nodesSwept,
    required this.filesNotCleared,
    required this.cooldownCleared,
    required this.reachabilityStampCleared,
    List<String> detail = const <String>[],
  }) : detail = List.unmodifiable(detail);

  /// True when the tunnel stop completed. The tunnel stops first: it uses
  /// the credentials that sign-out deletes.
  final bool tunnelStopped;

  /// True when the session document, marker included, was removed.
  final bool sessionCleared;

  /// True when the provisioned rows were removed.
  final bool nodesSwept;

  /// True when the runtime files are still on disk.
  final bool filesNotCleared;

  /// True when the refresh stamp was removed.
  final bool cooldownCleared;

  /// True when the launch reachability stamp was removed. The remembered
  /// failover domain is never removed.
  final bool reachabilityStampCleared;

  /// One line per step that did not complete, in step order.
  final List<String> detail;

  /// True when every step completed.
  bool get clean =>
      tunnelStopped &&
      sessionCleared &&
      nodesSwept &&
      !filesNotCleared &&
      cooldownCleared &&
      reachabilityStampCleared;

  /// The API has no logout endpoint. Sign-out is client side. The
  /// server-side token stands until it expires or is revoked.
  bool get tokenMayRemain => true;
}
