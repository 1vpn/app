// Compiler fixtures shared by the fork-owned compiled-config suites. The
// shapes mirror the upstream compiler test, so pins here assert the same
// compiled output that suite exercises.

import 'package:onexray/core/ffi/windows/mode.dart';
import 'package:onexray/onevpn/net/dns_resolver.dart';
import 'package:onexray/service/connect/compiler.dart';
import 'package:onexray/service/connect/routing/region_catalog.dart';
import 'package:onexray/service/connect/settings.dart';

/// Region catalog with a minimal geosite/geoip census. Region codes feed
/// the smart direct rules. The values are catalog data, not endpoints.
final compilerCatalog = RegionCatalog.fromJson(
  {
    'geosite': {
      'CN': ['CN'],
      'RU': ['CATEGORY-RU'],
    },
    'geoip': {
      'CN': ['CN'],
      'RU': ['RU'],
      'US': ['US'],
    },
  },
  geositeCodes: ['CN', 'CATEGORY-RU'],
  geoipCodes: ['CN', 'RU', 'US'],
);

/// Runtime options for a test compile. They feed upstream's configurable
/// tunnel-DNS mechanism the resolver constants that preparation takes from
/// the platform policy. Windows and Linux compiles need a non-empty
/// [interfaceName].
RuntimeOptions compilerOptions({
  ConnectionPlatform platform = ConnectionPlatform.android,
  WindowsMode windowsMode = WindowsMode.exe,
  bool ipv6 = true,
  String interfaceName = '',
}) => RuntimeOptions(
  platform: platform,
  windowsMode: windowsMode,
  sessionDirectory: '/unused-session',
  metricsPort: 18186,
  socksPort: 18187,
  ipv6: ipv6,
  interfaceName: interfaceName,
  tunDnsIpv4Address: dnsResolverAddress,
  tunDnsIpv6Address: dnsResolverIpv6Address,
);

/// A resolved server. Without [address] it compiles as a freedom outbound.
/// With one, it compiles as a socks outbound. Callers pass TEST-NET
/// addresses only.
ResolvedServer compilerNode(int id, {String? address}) => ResolvedServer(
  id: id,
  sourceId: 1,
  outbound: {
    'tag': 'Same user tag',
    'protocol': address == null ? 'freedom' : 'socks',
    if (address != null) 'settings': {'address': address, 'port': 12345},
  },
);
