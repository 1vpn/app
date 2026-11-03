import 'package:onexray/core/model/xray_json.dart';
import 'package:onexray/onevpn/net/dns_resolver.dart';
import 'package:onexray/service/connect/settings.dart';

abstract final class RoutingDns {
  static const defaultAddress = '8.8.8.8';
  static const proxyTag = 'app-dns-proxy';
  static const directTag = 'app-dns-direct';

  /// The direct server's address until the native side fills it. An unfilled
  /// placeholder keeps direct lookups on the device.
  static const directPlaceholder = '127.0.0.1';

  /// DNS only knows the queried domain, not the later connection's conditions.
  static List<String> directDomains(Iterable<XrayRoutingRule> rules) => {
    for (final rule in rules)
      if (rule.outboundTag == 'direct' &&
          (rule.ip?.isEmpty ?? true) &&
          rule.port == null &&
          rule.network == null &&
          (rule.protocol?.isEmpty ?? true) &&
          (rule.localOS?.isEmpty ?? true) &&
          (rule.inboundTag?.isEmpty ?? true))
        ...?rule.domain,
  }.toList();

  /// The domains that an unconditional rule routes through the proxy
  /// balancer or to the block outbound. A rule qualifies under the same
  /// conditions as in [directDomains].
  static List<String> tunnelDomains(Iterable<XrayRoutingRule> rules) => {
    for (final rule in rules)
      if ((rule.balancerTag == 'proxy' || rule.outboundTag == 'block') &&
          (rule.ip?.isEmpty ?? true) &&
          rule.port == null &&
          rule.network == null &&
          (rule.protocol?.isEmpty ?? true) &&
          (rule.localOS?.isEmpty ?? true) &&
          (rule.inboundTag?.isEmpty ?? true))
        ...?rule.domain,
  }.toList();

  /// [platform] and [directDomains] decide the direct server: Android
  /// compiles it when [directDomains] is non-empty. [tunnelDomains] scope the
  /// DoH pair only when the direct server compiles.
  static XrayDns compile({
    String? directAddress,
    Iterable<String> directDomains = const [],
    bool ipv6 = true,
    bool fakeDns = false,
    ConnectionPlatform? platform,
    Iterable<String> tunnelDomains = const [],
  }) {
    final queryStrategy = ipv6 ? 'UseIP' : 'UseIPv4';
    final direct = platform == ConnectionPlatform.android
        ? directDomains.toSet().toList()
        : const <String>[];
    final tunneled = direct.isEmpty
        ? const <String>[]
        : tunnelDomains.toSet().toList();
    return XrayDns(
      servers: [
        XrayDnsServer(
          address: dnsDohPrimary,
          tag: proxyTag,
          domains: tunneled.isEmpty ? null : tunneled,
          queryStrategy: queryStrategy,
        ),
        XrayDnsServer(
          address: dnsDohFallback,
          tag: proxyTag,
          domains: tunneled.isEmpty ? null : tunneled,
          // Ends every lookup that reaches it: no later server sees the name.
          finalQuery: tunneled.isEmpty ? null : true,
          queryStrategy: queryStrategy,
        ),
        if (direct.isNotEmpty)
          XrayDnsServer(
            address: directPlaceholder,
            tag: directTag,
            domains: direct,
            skipFallback: true,
            queryStrategy: queryStrategy,
          ),
      ],
    );
  }
}
