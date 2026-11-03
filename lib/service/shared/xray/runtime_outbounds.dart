import 'package:onexray/core/model/xray_json.dart';
import 'package:onexray/onevpn/net/dns_resolver.dart';

XrayOutbound createFreedomOutbound({
  required String tag,
  String? interfaceName,
}) => XrayOutbound(
  tag: tag,
  protocol: 'freedom',
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
