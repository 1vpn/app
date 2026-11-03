import 'package:onexray/core/model/xray_json.dart';
import 'package:onexray/service/connect/routing/dns.dart';

/// The tag of the rule that refuses DoT to the tunnel resolver.
const tunnelDotRefusalTag = 'app-tunnel-dot-refuse';

/// The rule that refuses TCP port 853 from the TUN to [ipv4Address] and
/// [ipv6Address], or no rule.
///
/// The rule compiles only when [dns] carries the direct server. Android's
/// Automatic Private DNS then fails DoT to the tunnel resolver and sends
/// plain queries. The core's DNS module answers them, so direct names reach
/// the direct server. DoT to any other address keeps its own route.
List<XrayRoutingRule> tunnelDotRefusal(
  XrayDns dns, {
  required String ipv4Address,
  required String ipv6Address,
}) => [
  if (dns.servers?.any((server) => server.tag == RoutingDns.directTag) ?? false)
    XrayRoutingRule(
      ruleTag: tunnelDotRefusalTag,
      inboundTag: ['tunIn'],
      ip: [ipv4Address, ipv6Address],
      port: '853',
      network: 'tcp',
      outboundTag: 'block',
    ),
];
