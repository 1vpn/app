import 'package:onexray/core/model/xray_json.dart';
import 'package:onexray/onevpn/net/dns_resolver.dart';

/// A freedom outbound named [tag]. [interfaceName] binds its sockets to that
/// interface.
///
/// A final rule blocks the tunnel's own DNS pair. The core checks it at the
/// dial and again for every UDP datagram the outbound writes. A datagram to
/// the pair inside a UDP session that routing sent here is then dropped.
/// Every other IP destination dials and sends as without the rule. A domain
/// destination, which only the Windows system-proxy inbound gives, is looked
/// up once more before the dial.
XrayOutbound createFreedomOutbound({
  required String tag,
  String? interfaceName,
}) => XrayOutbound(
  tag: tag,
  protocol: 'freedom',
  settings: {
    'finalRules': [
      {
        'action': 'block',
        'ip': [tunnelDnsIpv4Address, tunnelDnsIpv6Address],
      },
    ],
  },
  streamSettings: interfaceName == null
      ? null
      : XrayStreamSettings(sockopt: XraySockopt(interface: interfaceName)),
);

XrayOutbound createBlackholeOutbound({required String tag}) =>
    XrayOutbound(tag: tag, protocol: 'blackhole');

XrayOutbound createDnsOutbound({
  required String tag,
  required String dialerProxy,
}) => XrayOutbound(
  tag: tag,
  protocol: 'dns',
  settings: {
    'rules': const [
      XrayOutboundDnsRule(action: 'hijack', qType: '1,28'),
      XrayOutboundDnsRule(action: 'direct'),
    ].map((rule) => rule.toJson()).toList(),
    // Direct-action queries forward byte-transparent to this one target,
    // whatever address the client asked for.
    'rewriteAddress': dnsResolverAddress,
    'rewritePort': dnsResolverPort,
  },
  streamSettings: XrayStreamSettings(
    sockopt: XraySockopt(dialerProxy: dialerProxy),
  ),
);
