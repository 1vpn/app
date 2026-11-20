import 'package:onexray/core/model/xray_json.dart';

/// The tag of the rule that blocks the tunnel's own DNS pair.
const tunnelDnsGuardTag = 'app-tunnel-dns-guard';

/// The rule that sends every flow from the TUN to [ipv4Address] or
/// [ipv6Address] to the block outbound.
///
/// Must stand right after the port 53 rule and ahead of every other
/// delivery rule and every mode rule. Port 53 to the pair then reaches the
/// dns outbound, and any other flow to it is blocked. The region rules send
/// the private ranges direct, and the pair lies in them, so a later place
/// would let a flow to the pair reach the local network.
///
/// The rule decides per flow. The core routes a UDP socket once, on its
/// first datagram. A later datagram to the pair from a socket routed direct
/// meets the direct outbound's final rule instead, which drops it. A later
/// datagram to the pair from a socket routed to the balancer leaves through
/// the node, inside the tunnel. It never reaches the local network. A UDP
/// socket whose first datagram this rule blocks stays blackholed by the
/// core for 30 to 90 s after its last datagram.
///
/// Android's Automatic Private DNS fails its port 853 check against the
/// pair and sends plain queries, which the core answers.
XrayRoutingRule tunnelDnsGuard({
  required String ipv4Address,
  required String ipv6Address,
}) => XrayRoutingRule(
  ruleTag: tunnelDnsGuardTag,
  inboundTag: ['tunIn'],
  ip: [ipv4Address, ipv6Address],
  outboundTag: 'block',
);
