/// The resolvers a normal (non-Raw) configuration compiles.
///
/// The tunnel hands the system the tunnel's own DNS pair,
/// [tunnelDnsIpv4Address] and [tunnelDnsIpv6Address]. Only the core
/// answers them: port 53 to either reaches the dns outbound, and routing
/// blocks every other port to them.
///
/// `RoutingDns.compile` resolves hijacked A/AAAA lookups over DoH: Cloudflare
/// first, then Google as the backup. Both servers carry the proxy DNS tag.
/// The app-default rule routes that tag through the proxy balancer. Other
/// query types leave through the dns outbound's rewrite to
/// [dnsResolverAddress], Cloudflare's resolver.
///
/// On Android, the direct domains resolve first at the direct server. It
/// carries the direct DNS tag and a placeholder address. At each core start,
/// the native side writes the underlying network's resolver into it. It
/// removes the server under Private DNS or when no resolver is usable. Other
/// platforms compile no direct server. A stored direct address never
/// compiles.
///
/// With a direct server, the tunnel domains resolve at the DoH pair first.
/// The Google server ends their lookup. A proxied or blocked name never
/// reaches the direct server.
///
/// No FakeDNS server compiles. The `fakeDns` argument is accepted and
/// ignored.
library;

/// Primary resolver for hijacked A/AAAA lookups: Cloudflare DoH. The URL is
/// an IP literal, so the primary resolves without any bootstrap lookup.
const dnsDohPrimary = 'https://1.1.1.1/dns-query';

/// Fallback resolver: Google Public DNS over HTTPS, by its hostname. The
/// core dials the hostname through the proxy balancer, so the exit node
/// resolves it.
const dnsDohFallback = 'https://dns.google/dns-query';

/// The forward target: Cloudflare's secondary IPv4 address over plain port
/// 53. The dns outbound rewrites every forwarded query to this target. On
/// Android the core's own lookups outside the tunnel use the same address,
/// from a native constant that equals this one.
const dnsResolverAddress = '1.0.0.1';

/// The port for [dnsResolverAddress] rewrites.
const dnsResolverPort = 53;

/// The tunnel's own IPv4 resolver: the second host of the TUN interface's
/// IPv4 subnet, after the interface's own address. The tunnel hands it to
/// the system. Nothing outside the tunnel answers it.
const tunnelDnsIpv4Address = '198.18.0.2';

/// The tunnel's own IPv6 resolver: the second host of the TUN interface's
/// IPv6 subnet. The tunnel hands it to the system when IPv6 is on.
const tunnelDnsIpv6Address = 'fc00::2';
