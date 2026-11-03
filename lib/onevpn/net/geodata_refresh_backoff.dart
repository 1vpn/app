// The geodata refresh's failure backoff. One stored "not before" time is the
// whole of its state.

import 'package:onexray/core/tools/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How long the geodata refresh waits after a failed download.
const Duration kOneVpnGeoDataRetryAfter = Duration(hours: 24);

/// Gates the automatic geodata refresh after a failure.
///
/// A failed refresh stores a "not before" time [retryAfter] ahead. Every
/// refresh before that time is skipped. A refresh that succeeds clears it.
/// The refresh cadence is otherwise the caller's.
class OneVpnGeoDataBackoff {
  OneVpnGeoDataBackoff({
    SharedPreferencesAsync? preferences,
    DateTime Function()? now,
    this.retryAfter = kOneVpnGeoDataRetryAfter,
  }) : _preferences = preferences ?? SharedPreferencesAsync(),
       _now = now ?? DateTime.now;

  /// The backoff the data update service consults.
  static final instance = OneVpnGeoDataBackoff();

  final SharedPreferencesAsync _preferences;
  final DateTime Function() _now;

  /// The wait after a failed refresh.
  final Duration retryAfter;

  /// The fork's own key. It holds the "not before" time in milliseconds
  /// since the epoch in UTC.
  static const notBeforeKey = 'onevpn.geodataRefreshNotBefore';

  /// Runs [refresh] unless a stored "not before" time is still ahead.
  ///
  /// A skipped refresh resolves with no call. A [refresh] that throws stores
  /// a "not before" time [retryAfter] from now, then rethrows. A [refresh]
  /// that completes clears the stored time.
  ///
  /// A stored time more than [retryAfter] ahead reads as passed. A device
  /// clock that moved backwards never blocks the refresh for longer.
  /// Storage errors never block the refresh and never replace its error.
  Future<void> run(Future<void> Function() refresh) async {
    final now = _now().toUtc();
    final notBefore = await _notBefore();
    if (notBefore != null) {
      final wait = notBefore.difference(now);
      if (wait > Duration.zero && wait <= retryAfter) {
        ygLogger('Geodata refresh skipped until $notBefore');
        return;
      }
    }
    try {
      await refresh();
    } catch (_) {
      await _write(now.add(retryAfter));
      rethrow;
    }
    if (notBefore != null) await _write(null);
  }

  Future<DateTime?> _notBefore() async {
    try {
      final stored = await _preferences.getInt(notBeforeKey);
      return stored == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(stored, isUtc: true);
    } catch (_) {
      // An unreadable time reads as none.
      return null;
    }
  }

  Future<void> _write(DateTime? notBefore) async {
    try {
      if (notBefore == null) {
        await _preferences.remove(notBeforeKey);
      } else {
        await _preferences.setInt(
          notBeforeKey,
          notBefore.millisecondsSinceEpoch,
        );
      }
    } catch (_) {
      // A refused write costs one early retry.
    }
  }
}
