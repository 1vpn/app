// The recurring paywall's throttle. One stored timestamp is the whole of
// its state.
//
// Two absolutes: never for an entitled user, and never twice inside the
// interval. An unconfirmed optimistic grant counts as entitled. A buyer who
// has paid is never asked to pay again.

import 'package:shared_preferences/shared_preferences.dart';

/// How long the recurring paywall stays away after it has shown.
const Duration kOneVpnPaywallCadence = Duration(hours: 12);

/// Decides whether the recurring paywall is due, and stamps when it is.
class OneVpnPaywallCadence {
  OneVpnPaywallCadence({
    SharedPreferencesAsync? preferences,
    DateTime Function()? now,
    this.interval = kOneVpnPaywallCadence,
  }) : _preferences = preferences ?? SharedPreferencesAsync(),
       _now = now ?? DateTime.now;

  final SharedPreferencesAsync _preferences;
  final DateTime Function() _now;

  /// The shortest gap between two automatic showings.
  final Duration interval;

  /// The fork's own key. It holds milliseconds since the epoch in UTC. The
  /// gap stays fixed across time zones.
  static const lastShownKey = 'onevpn.paywallLastShownAt';

  /// Whether to show the recurring paywall now, stamping the clock when
  /// the answer is yes.
  ///
  /// [entitled] includes a pending grant. It short-circuits before the
  /// stamp. The interval measures between showings, not between checks.
  ///
  /// The first ever check is due.
  ///
  /// A stamp in the future reads as due. A device clock that moved
  /// backwards never suppresses the paywall.
  Future<bool> consumeDue({required bool entitled}) async {
    if (entitled) return false;

    final now = _now().toUtc();
    final last = await _lastShownAt();
    if (last != null) {
      final since = now.difference(last);
      if (!since.isNegative && since < interval) return false;
    }

    try {
      await _preferences.setInt(lastShownKey, now.millisecondsSinceEpoch);
    } catch (_) {
      // A refused write costs one repeat showing. A throw here would take
      // down the connect screen.
    }
    return true;
  }

  Future<DateTime?> _lastShownAt() async {
    try {
      final stored = await _preferences.getInt(lastShownKey);
      return stored == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(stored, isUtc: true);
    } catch (_) {
      // An unreadable stamp reads as never shown.
      return null;
    }
  }
}
