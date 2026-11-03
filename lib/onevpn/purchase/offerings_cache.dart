import 'package:onexray/onevpn/purchase/purchase_service.dart';

/// How long a shared load may run before it answers unreachable.
const Duration kOneVpnOfferingsDeadline = Duration(seconds: 8);

/// The plan offerings of one purchase service, kept in memory.
///
/// The paywall reads [loaded] on its first frame, so the plan prices show with
/// no wait. [refresh] fetches fresh offerings. A launch warm-up calls it once
/// before the paywall exists.
class OneVpnOfferingsCache {
  OneVpnOfferingsCache._(this._service);

  static final Expando<OneVpnOfferingsCache> _caches =
      Expando<OneVpnOfferingsCache>('onevpn offerings cache');

  /// The cache for [service]. One service always answers the same cache.
  static OneVpnOfferingsCache forService(OneVpnPurchaseService service) =>
      _caches[service] ??= OneVpnOfferingsCache._(service);

  /// Starts a [refresh] for [service] and ignores its result. Never throws.
  static Future<void> warm(OneVpnPurchaseService service) async {
    try {
      await forService(service).refresh();
    } catch (_) {
      // A failed warm-up leaves the paywall to load on open.
    }
  }

  final OneVpnPurchaseService _service;
  OneVpnOfferings? _loaded;
  Future<OneVpnOfferingsResult>? _inFlight;

  /// The offerings of the last successful load, or null before one.
  OneVpnOfferings? get loaded => _loaded;

  /// Loads the offerings from the service.
  ///
  /// A call while a load runs shares it. A loaded result replaces [loaded]. An
  /// unavailable or unreachable result keeps the previous [loaded].
  ///
  /// A load that outlasts [kOneVpnOfferingsDeadline] answers unreachable to
  /// every caller sharing it, and the next call starts its own load. The
  /// stalled request keeps running, and a late result still fills [loaded].
  Future<OneVpnOfferingsResult> refresh() {
    final running = _inFlight;
    if (running != null) return running;
    late final Future<OneVpnOfferingsResult> next;
    next = _load()
        .timeout(
          kOneVpnOfferingsDeadline,
          onTimeout: () => const OneVpnOfferingsUnreachable(),
        )
        .whenComplete(() {
          if (identical(_inFlight, next)) _inFlight = null;
        });
    return _inFlight = next;
  }

  Future<OneVpnOfferingsResult> _load() async {
    final result = await _service.loadOfferings();
    if (result is OneVpnOfferingsLoaded) _loaded = result.offerings;
    return result;
  }
}
