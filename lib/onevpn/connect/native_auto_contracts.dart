/// The declarations that the parts of native Auto share.
///
/// Native Auto measures every candidate inside one core, then pins the best.
/// The measure config builder, the observatory reader and the connect
/// orchestration reach each other only through these declarations.
library;

import 'package:onexray/onevpn/catalogue/location.dart';
import 'package:onexray/service/connect/compiler.dart';

/// The outbound tags of the candidates in a measure config.
///
/// A candidate tag carries the row's tier and id: `app-cand-acct-17` for an
/// account row, `app-cand-free-3` for a free row.
abstract final class OneVpnCandidateTags {
  /// The prefix of every candidate tag.
  ///
  /// Only candidate outbounds carry it. The burst observatory selects its
  /// subjects by this prefix.
  static const prefix = 'app-cand-';

  static const _account = '${prefix}acct-';
  static const _free = '${prefix}free-';

  /// The candidate tag of [server].
  ///
  /// A row named under [OneVpnLocation.freeRowNamePrefix] takes the free
  /// segment. Every other row takes the account segment.
  static String tagFor(ResolvedServer server) {
    final tier = server.name.startsWith(OneVpnLocation.freeRowNamePrefix)
        ? _free
        : _account;
    return '$tier${server.id}';
  }

  /// The row id that [tagFor] encoded in [tag].
  ///
  /// Returns null for any string that [tagFor] cannot produce.
  static int? idOf(String tag) {
    final String digits;
    if (tag.startsWith(_account)) {
      digits = tag.substring(_account.length);
    } else if (tag.startsWith(_free)) {
      digits = tag.substring(_free.length);
    } else {
      return null;
    }
    final id = int.tryParse(digits);
    return id != null && '$id' == digits ? id : null;
  }

  /// Whether [tag] is the candidate tag of an account row.
  static bool isAccount(String tag) =>
      tag.startsWith(_account) && idOf(tag) != null;
}

/// The time between two probe rounds of a measure core's burst observatory.
const oneVpnMeasureProbeInterval = Duration(seconds: 10);

/// The issue of the failed view that an expired hold publishes.
///
/// The measure core is stopped and the connection is closed. The connect
/// screen reads it as a failed connection that a tap retries.
const oneVpnHoldExpiredIssue = 'holdExpired';

/// The tag of the only routing rule in a measure config.
///
/// The rule sends every TCP and UDP flow to `block`. Observatory probes skip
/// routing, so they still reach each candidate.
const oneVpnMeasureBlockRuleTag = 'app-measure-block';

/// The tag of the last routing rule in every config that
/// [ConnectionCompiler.compile] builds from nodes.
///
/// The rule sends every TCP and UDP flow that no earlier rule matched to the
/// `proxy` balancer.
const oneVpnCatchAllRuleTag = 'app-catch-all';

/// Builds a measure config.
///
/// A measure config probes every candidate while it blocks every flow.
/// [pinned] is the [CompiledConnection.config] that
/// [ConnectionCompiler.compile] returns for one candidate. [candidates] holds
/// every row in scope, account and free. [probeUrl] is one of
/// `ProbeEndpoints.urls`. The result tags each candidate with
/// [OneVpnCandidateTags.tagFor]. An empty [candidates] throws a
/// [FormatException].
typedef OneVpnMeasureConfigBuilder = Map<String, dynamic> Function({
  required Map<String, dynamic> pinned,
  required List<ResolvedServer> candidates,
  required String probeUrl,
});

/// One outbound's entry in the core's observatory.
class OneVpnObservation {
  const OneVpnObservation({
    required this.tag,
    required this.alive,
    required this.delayMs,
    required this.all,
    required this.fail,
  });

  /// The outbound tag that the entry reports.
  final String tag;

  /// Whether the core reports [tag] alive. The core reports a tag alive
  /// while any counted probe succeeded.
  final bool alive;

  /// The mean round trip of the successful probes, in milliseconds. It is 0
  /// when no counted probe succeeded.
  final int delayMs;

  /// The number of probes the core counts for [tag].
  final int all;

  /// The number of counted probes that failed.
  final int fail;
}

/// One read of the core's observatory.
class OneVpnObservationSet {
  OneVpnObservationSet({
    required Map<String, OneVpnObservation> byTag,
    required this.readAt,
  }) : byTag = Map.unmodifiable(byTag);

  /// The observations, keyed by outbound tag. Each key equals its value's
  /// [OneVpnObservation.tag]. A tag absent from the map has not reported.
  final Map<String, OneVpnObservation> byTag;

  /// The time the read finished. A failed read sets it too.
  final DateTime readAt;
}

/// The source of observatory reads for a running core.
abstract interface class OneVpnObservatorySource {
  /// Reads the observatory from the core's metrics endpoint on loopback
  /// [port].
  ///
  /// The future always completes with a set. A failed or malformed read
  /// answers an empty set.
  Future<OneVpnObservationSet> read(int port);
}
