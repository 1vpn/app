/// The product's failover domains, in priority order.
///
/// Four names serve the same infrastructure, because some networks block
/// the service by name. The liveness probe's `/ping/` URLs and the account
/// API's request URLs both derive from this list. The list lives here once,
/// so a new domain reaches both. The account API walks the list in this
/// order.
///
/// All four names currently resolve to one anycast address. The list gives
/// domain diversity against per-name blocking, DNS poisoning, and SNI
/// filtering of a name. It gives no network path diversity.
library;

/// The failover domain list, and the only place lib spells its members.
///
/// `test/onevpn/endpoint_allowlist_test.dart` spells these four hosts
/// independently. That second spelling is the tripwire that fails when any
/// host enters the tree.
abstract final class OneVpnFailoverDomains {
  /// In priority order. The first entry is the primary. The rest are the
  /// censorship fallbacks and are otherwise identical.
  static const all = <String>[
    '1vpn.org',
    '1vpn.co',
    'onevpn.com',
    'cloudlogcdn.com',
  ];
}
