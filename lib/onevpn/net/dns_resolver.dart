/// The resolvers a normal (non-Raw) configuration compiles.
///
/// `RoutingDns.compile` resolves hijacked A/AAAA lookups over DoH: Quad9
/// unfiltered first, then Cloudflare. Both servers carry the proxy DNS tag.
/// The app-default rule routes that tag through the proxy balancer. Other
/// query types leave through the dns outbound's rewrite to
/// [dnsResolverAddress].
///
/// On Android, the direct domains resolve first at the direct server. It
/// carries the direct DNS tag and a placeholder address. At each core start,
/// the native side writes the underlying network's resolver into it. It
/// removes the server under Private DNS or when no resolver is usable. Other
/// platforms compile no direct server. A stored direct address never
/// compiles.
///
/// With a direct server, the tunnel domains resolve at the DoH pair first.
/// The Cloudflare server ends their lookup. A proxied or blocked name never
/// reaches the direct server.
///
/// No FakeDNS server compiles. The `fakeDns` argument is accepted and
/// ignored.
library;

/// Primary resolver for hijacked A/AAAA lookups: Quad9 unfiltered DoH.
const dnsDohPrimary = 'https://dns10.quad9.net/dns-query';

/// Fallback resolver: Cloudflare DoH. The URL is an IP literal, so the
/// fallback resolves without any bootstrap lookup.
const dnsDohFallback = 'https://1.1.1.1/dns-query';

/// The in-tunnel raw resolver: Quad9 unfiltered over plain port 53. The dns
/// outbound rewrites every forwarded query to this target. The tunnel also
/// pushes this address to the OS as the TUN resolver.
const dnsResolverAddress = '9.9.9.10';

/// The IPv6 pair of [dnsResolverAddress]. The tunnel pushes it where the
/// TUN stack wants an IPv6 nameserver. Routing hijacks port-53 traffic to
/// either address into the dns outbound.
const dnsResolverIpv6Address = '2620:fe::10';

/// The port for [dnsResolverAddress] rewrites.
const dnsResolverPort = 53;

/// The TLS name that authenticates [dnsResolverAddress] and
/// [dnsResolverIpv6Address] when the Apple policy enables DNS over TLS.
const dnsResolverTlsName = 'dns10.quad9.net';
