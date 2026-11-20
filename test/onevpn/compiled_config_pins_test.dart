// Pins the compiled resolver surface. The DoH servers lead in fallback
// order and ride the tunnel in every traffic mode. So do the raw rewrite
// target and the dns outbound's tunnel dial. The TUN push is the tunnel's
// own DNS pair, apart from the public rewrite target, and the delivery
// rules outrank the mode rules. Only Android compiles the direct DNS server, and only for a mode
// with direct domains. It follows the DoH pair and carries a loopback
// placeholder that the native side fills. Names the routing proxies or
// blocks resolve at the DoH pair, whose fallback ends their lookup. GitHub
// and ad names never reach the direct server. Every managed inbound sniffs
// route-only, and the direct outbound carries no domain strategy, so a
// direct dial keeps the address the app resolved. Google appears only as
// the backup DoH URL. No Quad9 value, no localhost server, and no FakeDNS
// surface compiles.
//
// This suite also pins the backup DoH dial. The backup is addressed by
// hostname. Its dial matches app-default first in every mode, so it rides
// the proxy balancer, and the exit node resolves the hostname.
//
// This suite also pins the guard on the tunnel's own DNS pair. In every
// mode and on every platform, port 53 to the pair reaches the dns outbound
// and every other flow to it goes to the block outbound. No flow to the
// pair reaches a direct rule or the balancer, though the region rules send
// the private ranges direct. The guard decides per flow. The direct
// outbound's final rule blocks the pair per datagram, on every platform and
// in every mode. DoT to any other address still rides the proxy balancer.
//
// This suite also pins the free floor's dial. A free node dials its IP
// literal. Its hostname appears nowhere in the compiled config.
//
// This suite also pins the proxy balancer. The compile emits exactly one
// balancer. Its selector matches a proxy outbound in every mode. The
// strategy and the fallback hold their shipped values. The DoH pair and
// the DoT rule route through the balancer's tag.
//
// This suite also pins the fail-closed shape. The block outbound comes
// first. The core sends any unrouted flow to it. The balancer falls back to
// the block outbound. The catch-all ends the rules. It sends every
// remaining TCP and UDP flow to the balancer.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/core/ffi/windows/mode.dart';
import 'package:onexray/onevpn/catalogue/free_floor.dart';
import 'package:onexray/onevpn/catalogue/free_node_ips.dart';
import 'package:onexray/onevpn/catalogue/location.dart';
import 'package:onexray/onevpn/connect/native_auto_contracts.dart';
import 'package:onexray/onevpn/model/user_data.dart';
import 'package:onexray/onevpn/net/dns_resolver.dart';
import 'package:onexray/onevpn/net/tunnel_dns_guard.dart';
import 'package:onexray/onevpn/provision/outbound_builder.dart';
import 'package:onexray/onevpn/routing/direct_regions_apply.dart';
import 'package:onexray/service/advanced/platform_policy.dart';
import 'package:onexray/service/connect/compiler.dart';
import 'package:onexray/service/connect/routing/custom/state.dart';
import 'package:onexray/service/connect/routing/region_catalog.dart';
import 'package:onexray/service/connect/runtime.dart';
import 'package:onexray/service/connect/settings.dart';

import 'support/compiler_fixtures.dart';

/// A small custom profile so the custom traffic mode compiles.
RoutingProfileState _customProfile({bool fakeDns = false}) =>
    RoutingProfileState(
      name: 'Pinned',
      fakeDns: fakeDns,
      rules: [
        RoutingRuleState(
          ruleTag: 'lan',
          ip: const ['192.0.2.0/24'],
          action: RoutingRuleAction.direct,
        ),
      ],
    );

/// A complete free triple for the compile. Its values are placeholders.
const _freeCredentials = OneVpnCredentials(
  uuid: '00000000-0000-4000-8000-000000000000',
  publicKey: 'test-public-key',
  shortId: 'deadbeef',
);

/// Outbound protocols the app emits for itself. Every other outbound is a
/// proxy outbound that carries traffic to a server.
const _appProtocols = {'freedom', 'blackhole', 'dns'};

/// The blackhole. A balancer that can pick nothing blocks the flow.
const _ruledFallbackTag = 'block';

/// One labelled compiled config per traffic mode on Android and Linux.
/// Smart carries a direct region in the shape a pick writes. The entry is a
/// TEST-NET socks proxy.
List<(String, Map<String, dynamic>)> _compiledModes() => [
  for (final platform in [ConnectionPlatform.android, ConnectionPlatform.linux])
    for (final mode in TrafficMode.values)
      (
        '${platform.name} ${mode.name}',
        ConnectionCompiler.compile(
          settings: ConnectionSettings(
            trafficMode: mode,
            smart: _regionOptIn().smart,
          ),
          entries: [compilerNode(1, address: '192.0.2.1')],
          custom: mode == TrafficMode.custom ? _customProfile() : null,
          regions: compilerCatalog,
          options: compilerOptions(
            platform: platform,
            interfaceName: platform == ConnectionPlatform.linux
                ? 'selected-interface'
                : '',
          ),
        ).config,
      ),
];

/// The compiled balancer. Fails unless the compile emits exactly one.
Map _balancer(Map<String, dynamic> config, String label) {
  final balancers = (config['routing']['balancers'] as List).cast<Map>();
  expect(balancers, hasLength(1), reason: label);
  return balancers.single;
}

/// A smart configuration in the shape a CN pick writes, with the Apple and
/// Windows switches off. [directWindows] turns the Windows switch on. The
/// stored direct address must never compile.
ConnectionSettings _regionOptIn({bool directWindows = false}) =>
    ConnectionSettings(
      trafficMode: TrafficMode.smart,
      smart: SmartRoutingSettings(
        directRegions: const ['CN'],
        directApple: false,
        directWindows: directWindows,
        directDnsAddress: '192.0.2.53',
      ),
    );

/// The direct domains a picked region compiles: the local-network list and
/// that region's own list, from the shipped region mapping.
const _pickedRegionDomains = {
  'CN': ['geosite:PRIVATE', 'geosite:CN'],
  'IR': ['geosite:PRIVATE', 'geosite:CATEGORY-IR'],
  'RU': ['geosite:PRIVATE', 'geosite:CATEGORY-RU'],
  'TM': ['geosite:PRIVATE', 'geosite:CATEGORY-TM'],
};

/// Every platform with the interface its compile requires.
const _platforms = [
  (ConnectionPlatform.android, ''),
  (ConnectionPlatform.ios, ''),
  (ConnectionPlatform.macos, ''),
  (ConnectionPlatform.linux, 'selected-interface'),
  (ConnectionPlatform.windows, 'Ethernet 2'),
];

List<Map> _servers(Map<String, dynamic> config) =>
    (config['dns']['servers'] as List).cast<Map>();

/// The first rule that can match the core's dial to the backup DoH server.
/// The dial carries the proxy DNS tag as its inbound tag, the backup's
/// hostname as its destination, TCP, and port 443. A domain, IP or protocol
/// condition counts as a match, so a rule that could capture the dial ends
/// the walk.
Map _firstDohDialRule(List<Map> rules) {
  for (final rule in rules) {
    final inbound = rule['inboundTag'] as List?;
    if (inbound != null && !inbound.contains(ConnectionCompiler.dnsProxy)) {
      continue;
    }
    final port = rule['port'];
    if (port != null && !ConnectionCompiler.portIncludes(port, 443)) continue;
    final network = rule['network'] as String?;
    if (network != null && !network.split(',').contains('tcp')) continue;
    return rule;
  }
  throw StateError('No rule matches the backup DoH dial');
}

/// Google appears only as the backup DoH URL, and no Quad9 value compiles.
/// Upstream's dormant Google plain-DNS literals never compile.
void _expectResolverOperators(String json, String label) {
  expect('dns.google'.allMatches(json), hasLength(1), reason: label);
  expect(json, contains('"https://dns.google/dns-query"'), reason: label);
  final rest = json
      .replaceAll('https://dns.google/dns-query', '')
      .toLowerCase();
  expect(rest, isNot(contains('google')), reason: label);
  expect(rest, isNot(contains('8.8.8.8')), reason: label);
  expect(rest, isNot(contains('2001:4860:4860::8888')), reason: label);
  for (final quad9 in const ['quad9', '9.9.9.', '149.112.112.', '2620:fe:']) {
    expect(rest, isNot(contains(quad9)), reason: '$label: $quad9');
  }
}

void main() {
  test('resolvers are pinned and every DNS path rides the tunnel', () {
    for (final platform in [
      ConnectionPlatform.android,
      ConnectionPlatform.linux,
    ]) {
      for (final mode in TrafficMode.values) {
        final plan = ConnectionCompiler.compile(
          settings: ConnectionSettings(trafficMode: mode),
          entries: [compilerNode(1)],
          custom: mode == TrafficMode.custom ? _customProfile() : null,
          regions: compilerCatalog,
          options: compilerOptions(
            platform: platform,
            interfaceName: platform == ConnectionPlatform.linux
                ? 'selected-interface'
                : '',
          ),
        );
        final config = plan.config;
        final servers = _servers(config);
        // Hijacked A/AAAA resolve over DoH in fallback order: Cloudflare
        // first, then Google. The Cloudflare URL is an IP literal and needs
        // no resolution of its own.
        expect(servers[0]['address'], 'https://1.1.1.1/dns-query');
        expect(servers[1]['address'], 'https://dns.google/dns-query');
        // Both DoH servers dial as dnsProxy. The app-default rule routes
        // that tag through the proxy balancer.
        expect(servers[0]['tag'], ConnectionCompiler.dnsProxy);
        expect(servers[1]['tag'], ConnectionCompiler.dnsProxy);
        // The direct server follows the DoH pair. Of these fixtures, only
        // Android smart mode carries direct domains.
        expect(servers.map((server) => server['tag']), [
          ConnectionCompiler.dnsProxy,
          ConnectionCompiler.dnsProxy,
          if (platform == ConnectionPlatform.android &&
              mode == TrafficMode.smart)
            ConnectionCompiler.dnsDirect,
        ]);
        expect(plan.xrayJson, isNot(contains('localhost')));
        final appDefault = (config['routing']['rules'] as List)
            .cast<Map>()
            .singleWhere((rule) => rule['ruleTag'] == 'app-default');
        expect(appDefault['inboundTag'], [ConnectionCompiler.dnsProxy]);
        expect(appDefault['balancerTag'], 'proxy');
        final dnsOutbound = (config['outbounds'] as List)
            .cast<Map>()
            .singleWhere(
              (outbound) => outbound['tag'] == ConnectionCompiler.dnsOutbound,
            );
        // Raw non-A/AAAA queries rewrite to one plain-53 target and dial
        // through the tunnel entry in every mode.
        expect(dnsOutbound['settings']['rewriteAddress'], '1.0.0.1');
        expect(dnsOutbound['settings']['rewritePort'], 53);
        expect(
          dnsOutbound['streamSettings']['sockopt']['dialerProxy'],
          'app-entry-0',
        );
        expect(dnsOutbound['settings']['rules'], [
          {'action': 'hijack', 'qType': '1,28'},
          {'action': 'direct'},
        ]);
        _expectResolverOperators(plan.xrayJson, '${platform.name} $mode');
      }
    }
    for (final (label, config) in _compiledModes()) {
      _expectResolverOperators(jsonEncode(config), label);
    }
  });

  test('the backup DoH dial rides the proxy balancer in every mode', () {
    // The core dials a DoH server with the server's tag as the inbound tag
    // and the URL's hostname as the destination. It skips IP resolution for
    // that dial. The first rule the dial matches routes it.
    final backupHost = Uri.parse(dnsDohFallback).host;
    expect(backupHost, 'dns.google');
    expect(Uri.parse(dnsDohPrimary).scheme, 'https');
    expect(Uri.parse(dnsDohFallback).scheme, 'https');
    final pick = OneVpnDirectRegionsApplyService.nextConfiguration(
      ConnectionConfiguration(),
      'CN',
    ).connection;
    // Custom rules that would capture the dial if they came first.
    final capturing = RoutingProfileState(
      name: 'Capturing',
      rules: [
        RoutingRuleState(
          domain: const ['domain:dns.google'],
          action: RoutingRuleAction.direct,
        ),
        RoutingRuleState(
          domain: const ['geosite:GOOGLE'],
          action: RoutingRuleAction.block,
        ),
        RoutingRuleState(
          port: '443',
          network: 'tcp',
          action: RoutingRuleAction.direct,
        ),
      ],
    );
    final modes = [
      ('all-VPN', ConnectionSettings(), null),
      ('region CN', pick, null),
      (
        'region CN with ads and GitHub',
        ConnectionSettings(
          trafficMode: TrafficMode.smart,
          smart: SmartRoutingSettings(
            blockAds: true,
            directRegions: const ['CN'],
          ),
        ),
        null,
      ),
      (
        'custom',
        ConnectionSettings(trafficMode: TrafficMode.custom),
        capturing,
      ),
    ];
    // A node that asks for its own domain strategy. The compile strips it,
    // so the node receives the hostname.
    final node = ResolvedServer(
      id: 1,
      sourceId: 1,
      outbound: {
        'protocol': 'socks',
        'settings': {
          'address': '192.0.2.1',
          'port': 12345,
          'domainStrategy': 'UseIP',
        },
        'streamSettings': {
          'sockopt': {'domainStrategy': 'UseIP'},
        },
      },
    );
    for (final (platform, interfaceName) in _platforms) {
      for (final (mode, settings, custom) in modes) {
        final label = '${platform.name} $mode';
        final config = ConnectionCompiler.compile(
          settings: settings,
          entries: [node],
          custom: custom,
          regions: compilerCatalog,
          options: compilerOptions(
            platform: platform,
            interfaceName: interfaceName,
          ),
        ).config;
        final servers = _servers(config);
        // The backup follows the primary and dials with the same tag.
        expect(servers[0]['address'], dnsDohPrimary, reason: label);
        expect(servers[1]['address'], dnsDohFallback, reason: label);
        expect(
          servers.where((server) => server['address'] == dnsDohFallback),
          hasLength(1),
          reason: label,
        );
        expect(servers[0]['tag'], ConnectionCompiler.dnsProxy, reason: label);
        expect(servers[1]['tag'], ConnectionCompiler.dnsProxy, reason: label);
        // Plain https routes each dial. A local scheme would dial outside
        // routing and skip every rule below.
        for (final server in servers.take(2)) {
          expect(
            Uri.parse(server['address'] as String).scheme,
            'https',
            reason: label,
          );
        }
        // No static host entry answers the backup's hostname.
        expect(config['dns']['hosts'], isNull, reason: label);

        final rules = (config['routing']['rules'] as List).cast<Map>();
        expect(rules.first, {
          'ruleTag': 'app-default',
          'inboundTag': [ConnectionCompiler.dnsProxy],
          'balancerTag': 'proxy',
        }, reason: label);
        expect(_firstDohDialRule(rules), same(rules.first), reason: label);
        final balancer = _balancer(config, label);
        expect(balancer['tag'], 'proxy', reason: label);
        expect(balancer['fallbackTag'], 'block', reason: label);

        // Anti-vacuity guard. Outside all-VPN, the rule the dial would
        // match next sends it direct or blocks it.
        final next = _firstDohDialRule(rules.skip(1).toList());
        if (mode == 'all-VPN') {
          expect(next['ruleTag'], oneVpnCatchAllRuleTag, reason: label);
        } else {
          expect(next['outboundTag'], isIn(['direct', 'block']), reason: label);
        }
        if (mode == 'custom') {
          expect(next['ruleTag'], 'app-custom-0', reason: label);
        }

        // The exit node resolves the hostname. No entry outbound carries
        // a domain strategy, and routing never resolves on demand.
        final entry = (config['outbounds'] as List).cast<Map>().singleWhere(
          (outbound) => outbound['tag'] == 'app-entry-0',
        );
        expect(entry['settings']['domainStrategy'], isNull, reason: label);
        expect(
          entry['streamSettings']?['sockopt']?['domainStrategy'],
          isNull,
          reason: label,
        );
        expect(
          config['routing']['domainStrategy'],
          isNot('IPOnDemand'),
          reason: label,
        );
      }
    }
  });

  test('only Android compiles the direct server, as the loopback '
      'placeholder', () {
    for (final (platform, interfaceName) in _platforms) {
      final plan = ConnectionCompiler.compile(
        settings: _regionOptIn(),
        entries: [compilerNode(1)],
        regions: compilerCatalog,
        options: compilerOptions(
          platform: platform,
          interfaceName: interfaceName,
        ),
      );
      final direct = _servers(plan.config)
          .where((server) => server['tag'] == ConnectionCompiler.dnsDirect);
      // The stored direct address never compiles on any platform.
      expect(plan.xrayJson, isNot(contains('192.0.2.53')));
      if (platform != ConnectionPlatform.android) {
        expect(direct, isEmpty, reason: platform.name);
        continue;
      }
      // The whole server. The native side replaces the address with the
      // underlying network's resolver, or removes the server.
      expect(direct.single, {
        'address': '127.0.0.1',
        'domains': ['geosite:PRIVATE', 'geosite:CN'],
        'skipFallback': true,
        'queryStrategy': 'UseIP',
        'tag': ConnectionCompiler.dnsDirect,
      });
    }
    // Custom mode follows the same rule: its stored address never
    // compiles, and a direct domain rule compiles the placeholder.
    final custom = ConnectionCompiler.compile(
      settings: ConnectionSettings(trafficMode: TrafficMode.custom),
      entries: [compilerNode(1)],
      custom: RoutingProfileState(
        name: 'Pinned',
        directDnsAddress: '192.0.2.54',
        rules: [
          RoutingRuleState(
            domain: const ['domain:direct.test'],
            action: RoutingRuleAction.direct,
          ),
        ],
      ),
      regions: compilerCatalog,
      options: compilerOptions(),
    );
    expect(custom.xrayJson, isNot(contains('192.0.2.54')));
    expect(_servers(custom.config).last, {
      'address': '127.0.0.1',
      'domains': ['domain:direct.test'],
      'skipFallback': true,
      'queryStrategy': 'UseIP',
      'tag': ConnectionCompiler.dnsDirect,
    });
  });

  test('all-VPN compiles no direct server and no direct DNS rule', () {
    for (final (platform, interfaceName) in _platforms) {
      final config = ConnectionCompiler.compile(
        settings: ConnectionSettings(
          trafficMode: TrafficMode.allVpn,
          smart: _regionOptIn().smart,
        ),
        entries: [compilerNode(1)],
        regions: compilerCatalog,
        options: compilerOptions(
          platform: platform,
          interfaceName: interfaceName,
        ),
      ).config;
      expect(_servers(config).map((server) => server['tag']), [
        ConnectionCompiler.dnsProxy,
        ConnectionCompiler.dnsProxy,
      ], reason: platform.name);
      final tags = (config['routing']['rules'] as List).map(
        (rule) => rule['ruleTag'],
      );
      expect(tags, isNot(contains('app-direct-dns')), reason: platform.name);
    }
  });

  test('GitHub names resolve at the DoH pair and never reach the direct '
      'server', () {
    for (final directWindows in [true, false]) {
      final servers = _servers(
        ConnectionCompiler.compile(
          settings: _regionOptIn(directWindows: directWindows),
          entries: [compilerNode(1)],
          regions: compilerCatalog,
          options: compilerOptions(),
        ).config,
      );
      final direct = servers.last;
      expect(direct['tag'], ConnectionCompiler.dnsDirect);
      expect(direct['domains'], isNot(contains('geosite:GITHUB')));
      if (!directWindows) {
        // No GitHub rule compiles, so the DoH pair stays unscoped.
        expect(servers[0].containsKey('domains'), isFalse);
        expect(servers[1].containsKey('domains'), isFalse);
        expect(servers[1].containsKey('finalQuery'), isFalse);
        continue;
      }
      // geosite:MICROSOFT lists GitHub's names, and the routing sends
      // geosite:GITHUB through the proxy ahead of the direct domains. The
      // DNS module tries matching servers in list order, so the DoH pair
      // answers first. The fallback's finalQuery ends the lookup there, an
      // empty AAAA answer included.
      expect(direct['domains'], contains('geosite:MICROSOFT'));
      expect(servers[0]['domains'], ['geosite:GITHUB']);
      expect(servers[1]['domains'], ['geosite:GITHUB']);
      expect(servers[0].containsKey('finalQuery'), isFalse);
      expect(servers[1]['finalQuery'], isTrue);
    }
    // Off Android no direct server compiles, so the DoH pair stays
    // unscoped, the GitHub rule included.
    final linuxConfig = ConnectionCompiler.compile(
      settings: _regionOptIn(directWindows: true),
      entries: [compilerNode(1)],
      regions: compilerCatalog,
      options: compilerOptions(
        platform: ConnectionPlatform.linux,
        interfaceName: 'selected-interface',
      ),
    ).config;
    expect(
      (linuxConfig['routing']['rules'] as List).map((rule) => rule['ruleTag']),
      contains('app-smart-github'),
    );
    final linux = _servers(linuxConfig);
    expect(linux, hasLength(2));
    expect(linux.every((server) => !server.containsKey('domains')), isTrue);
    expect(linux.every((server) => !server.containsKey('finalQuery')), isTrue);
  });

  test('blocked names resolve at the DoH pair and never reach the direct '
      'server', () {
    final servers = _servers(
      ConnectionCompiler.compile(
        settings: ConnectionSettings(
          trafficMode: TrafficMode.smart,
          smart: SmartRoutingSettings(blockAds: true),
        ),
        entries: [compilerNode(1)],
        regions: compilerCatalog,
        options: compilerOptions(),
      ).config,
    );
    // geosite:APPLE and geosite:MICROSOFT list ad names. The routing blocks
    // geosite:CATEGORY-ADS-ALL ahead of the direct domains, so the DoH pair
    // answers first. The fallback's finalQuery ends the lookup there.
    final direct = servers.last;
    expect(direct['tag'], ConnectionCompiler.dnsDirect);
    expect(direct['domains'], contains('geosite:APPLE'));
    expect(direct['domains'], isNot(contains('geosite:CATEGORY-ADS-ALL')));
    for (final server in [servers[0], servers[1]]) {
      expect(server['tag'], ConnectionCompiler.dnsProxy);
      expect(server['domains'], ['geosite:CATEGORY-ADS-ALL', 'geosite:GITHUB']);
    }
    expect(servers[1]['finalQuery'], isTrue);
  });

  test('every managed inbound sniffs route-only', () {
    // The sniffed name selects the route. The connection keeps the
    // address the app resolved, so a direct dial resolves nothing again.
    final cases = [
      for (final (platform, interfaceName) in _platforms)
        (platform, WindowsMode.exe, interfaceName),
      (ConnectionPlatform.windows, WindowsMode.msix, 'Ethernet 2'),
    ];
    for (final (platform, windowsMode, interfaceName) in cases) {
      for (final mode in [TrafficMode.smart, TrafficMode.allVpn]) {
        final inbound =
            (ConnectionCompiler.compile(
                      settings: ConnectionSettings(trafficMode: mode),
                      entries: [compilerNode(1)],
                      regions: compilerCatalog,
                      options: compilerOptions(
                        platform: platform,
                        windowsMode: windowsMode,
                        interfaceName: interfaceName,
                      ),
                    ).config['inbounds']
                    as List)
                .cast<Map>()
                .single;
        expect(inbound['tag'], 'tunIn');
        expect(inbound['sniffing'], {
          'enabled': true,
          'routeOnly': true,
          'destOverride': ['http', 'tls', 'quic'],
        }, reason: '${platform.name} ${windowsMode.name} ${mode.name}');
      }
    }
  });

  test('the direct outbound follows the nodes and carries no domain '
      'strategy', () {
    for (final (platform, interfaceName) in _platforms) {
      final outbounds =
          (ConnectionCompiler.compile(
                    settings: _regionOptIn(),
                    entries: [compilerNode(1)],
                    regions: compilerCatalog,
                    options: compilerOptions(
                      platform: platform,
                      interfaceName: interfaceName,
                    ),
                  ).config['outbounds']
                  as List)
              .cast<Map>();
      expect(outbounds.map((outbound) => outbound['tag']), [
        'block',
        'app-entry-0',
        'direct',
        ConnectionCompiler.dnsOutbound,
      ], reason: platform.name);
      final direct = outbounds.singleWhere(
        (outbound) => outbound['tag'] == 'direct',
      );
      expect(direct['protocol'], 'freedom');
      expect(direct['settings']?['domainStrategy'], isNull);
      expect(direct['streamSettings']?['sockopt']?['domainStrategy'], isNull);
    }
  });

  test('FakeDNS stays dormant in every compiled mode', () {
    // A normal compile emits no FakeDNS server, pool list, or sniffing
    // recovery, even when stored settings request it. The one string
    // 'fakedns' spells the server address, the pool key, and the sniffing
    // destOverride entry, so its absence pins all three at once.
    for (final mode in [TrafficMode.smart, TrafficMode.custom]) {
      final plan = ConnectionCompiler.compile(
        settings: ConnectionSettings(
          trafficMode: mode,
          smart: SmartRoutingSettings(fakeDns: true),
        ),
        entries: [compilerNode(1)],
        custom: mode == TrafficMode.custom
            ? _customProfile(fakeDns: true)
            : null,
        regions: compilerCatalog,
        options: compilerOptions(),
      );
      expect(plan.xrayJson.toLowerCase(), isNot(contains('fakedns')));
      expect(plan.xrayJson, isNot(contains('app-dns-fake')));
      expect(plan.config.containsKey('fakedns'), isFalse);
    }
  });

  test('the TUN push is the tunnel\'s own pair, apart from the rewrite '
      'target', () {
    // The OS resolver push is the tunnel's own DNS pair. The raw rewrite
    // target is Cloudflare's public resolver, which the pair never equals.
    // Port-53 traffic to any address is hijacked into the dns outbound. The
    // push rides upstream's configurable tunnel-DNS mechanism. The compiler
    // emits options.tunDns*, and the fixture feeds the pair the way
    // preparation does.
    expect(tunnelDnsIpv4Address, '198.18.0.2');
    expect(tunnelDnsIpv6Address, 'fc00::2');
    expect(dnsResolverAddress, '1.0.0.1');
    expect([
      tunnelDnsIpv4Address,
      tunnelDnsIpv6Address,
    ], isNot(contains(dnsResolverAddress)));
    for (final ipv6 in [false, true]) {
      for (final (platform, interfaceName) in [
        (ConnectionPlatform.windows, 'Ethernet 2'),
        (ConnectionPlatform.linux, 'selected-interface'),
      ]) {
        final config = ConnectionCompiler.compile(
          settings: ConnectionSettings(),
          entries: [compilerNode(1)],
          regions: compilerCatalog,
          options: compilerOptions(
            platform: platform,
            ipv6: ipv6,
            interfaceName: interfaceName,
          ),
        ).config;
        final inbound = (config['inbounds'] as List).cast<Map>().singleWhere(
          (inbound) => inbound['tag'] == 'tunIn',
        );
        expect(inbound['settings']['dns'], ['198.18.0.2', if (ipv6) 'fc00::2']);
        final dnsOutbound = (config['outbounds'] as List)
            .cast<Map>()
            .singleWhere(
              (outbound) => outbound['tag'] == ConnectionCompiler.dnsOutbound,
            );
        expect(dnsOutbound['settings']['rewriteAddress'], '1.0.0.1');
      }
    }
    // The production feed: preparation reads the policy's pinned
    // resolver values into the mechanism. The platform-policy pins hold
    // those values to the constants. This content anchor holds the wire
    // between them.
    final preparation = File('lib/service/connect/preparation.dart')
        .readAsStringSync();
    expect(preparation, contains('tunDnsIpv4Address: policy.dnsIpv4Address'));
    expect(preparation, contains('tunDnsIpv6Address: policy.dnsIpv6Address'));
  });

  test('the DNS rules lead the mode rules in every mode', () {
    // The dns outbound sees traffic only because app-tunnel-dns hijacks
    // every plain port-53 query out of the TUN into it. app-tunnel-dot
    // forces port-853 DoT through the proxy balancer. Both must stand in
    // every traffic mode and stay ahead of the mode rules: a mode rule
    // that matches a query first dials its own outbound instead. Outside
    // all-VPN, app-direct-dns sends the direct server's queries direct.
    // It matches only that server's tag, so it cannot capture a TUN query.
    // The guard on the tunnel's own DNS pair stands right behind
    // app-tunnel-dns and ahead of app-tunnel-dot in every mode.
    for (final platform in [
      ConnectionPlatform.android,
      ConnectionPlatform.linux,
    ]) {
      for (final mode in TrafficMode.values) {
        final config = ConnectionCompiler.compile(
          settings: ConnectionSettings(trafficMode: mode),
          entries: [compilerNode(1)],
          custom: mode == TrafficMode.custom ? _customProfile() : null,
          regions: compilerCatalog,
          options: compilerOptions(
            platform: platform,
            interfaceName: platform == ConnectionPlatform.linux
                ? 'selected-interface'
                : '',
          ),
        ).config;
        final rules = (config['routing']['rules'] as List).cast<Map>();
        final tags = rules.map((rule) => rule['ruleTag']).toList();
        final direct = _servers(config)
            .any((server) => server['tag'] == ConnectionCompiler.dnsDirect);
        // Anti-vacuity guard. Android smart compiles the direct server.
        expect(
          direct,
          platform == ConnectionPlatform.android && mode == TrafficMode.smart,
        );

        // The app rules lead in this exact order. Every mode rule sits
        // behind them.
        final appRules = [
          'app-default',
          if (mode != TrafficMode.allVpn) 'app-direct-dns',
          'app-tunnel-dns',
          tunnelDnsGuardTag,
          'app-tunnel-dot',
        ];
        expect(tags.take(appRules.length).toList(), appRules);

        // Anti-vacuity guard. The mode rules the app rules must outrank
        // are present behind them.
        if (mode == TrafficMode.smart) {
          expect(tags, contains('app-smart-direct-domain'));
          expect(tags, contains('app-smart-direct-ip'));
        }
        if (mode == TrafficMode.custom) {
          expect(tags, contains('app-custom-0'));
        }

        // The whole rule bodies. A key added, dropped, or changed is a
        // delivery change: inboundTag scopes each rule, port selects the
        // queries, and the target carries them on.
        expect(
          rules.singleWhere((rule) => rule['ruleTag'] == 'app-tunnel-dns'),
          {
            'ruleTag': 'app-tunnel-dns',
            'inboundTag': ['tunIn'],
            'port': '53',
            'outboundTag': ConnectionCompiler.dnsOutbound,
          },
        );
        expect(
          rules.singleWhere((rule) => rule['ruleTag'] == tunnelDnsGuardTag),
          {
            'ruleTag': tunnelDnsGuardTag,
            'inboundTag': ['tunIn'],
            'ip': ['198.18.0.2', 'fc00::2'],
            'outboundTag': 'block',
          },
        );
        expect(
          rules.singleWhere((rule) => rule['ruleTag'] == 'app-tunnel-dot'),
          {
            'ruleTag': 'app-tunnel-dot',
            'inboundTag': ['tunIn'],
            'port': '853',
            'balancerTag': 'proxy',
          },
        );
        if (mode != TrafficMode.allVpn) {
          expect(
            rules.singleWhere((rule) => rule['ruleTag'] == 'app-direct-dns'),
            {
              'ruleTag': 'app-direct-dns',
              'inboundTag': [ConnectionCompiler.dnsDirect],
              'outboundTag': 'direct',
            },
          );
        }
      }
    }
  });

  test('the default posture is fully tunnelled: allVpn emits no carve-out', () {
    // Two shipped-default paths must both land in allVpn. The constructor is
    // the compiler and test fallback. fromJson of an empty map is the
    // fresh-install store path. The DAO returns '{}' until a first write, and
    // the coordinator reads the runtime posture through it. In allVpn the
    // compiler emits no smart rule, no region direct rule, and no Apple,
    // Microsoft, or Bing carve-out. Apple and Microsoft traffic tunnels.
    final defaults = <ConnectionSettings>[
      ConnectionSettings(),
      ConnectionSettings.fromJson(const <String, dynamic>{}),
    ];
    for (final settings in defaults) {
      expect(settings.trafficMode, TrafficMode.allVpn);
      for (final platform in [
        ConnectionPlatform.android,
        ConnectionPlatform.linux,
      ]) {
        final config = ConnectionCompiler.compile(
          settings: settings,
          entries: [compilerNode(1)],
          regions: compilerCatalog,
          options: compilerOptions(
            platform: platform,
            interfaceName: platform == ConnectionPlatform.linux
                ? 'selected-interface'
                : '',
          ),
        ).config;
        final rules = (config['routing']['rules'] as List).cast<Map>();
        final tags = rules.map((rule) => rule['ruleTag']).toList();
        expect(tags, isNot(contains('app-smart-direct-domain')));
        expect(tags, isNot(contains('app-smart-direct-ip')));
        final domains = [
          for (final rule in rules) ...?(rule['domain'] as List?),
        ];
        for (final carveOut in const [
          'geosite:APPLE',
          'geosite:MICROSOFT',
          'geosite:BING',
        ]) {
          expect(domains, isNot(contains(carveOut)));
        }
      }
    }
  });

  test('a selected region compiles to geosite and geoip direct rules', () {
    final config = ConnectionCompiler.compile(
      settings: ConnectionSettings(
        trafficMode: TrafficMode.smart,
        smart: SmartRoutingSettings(directRegions: const ['CN']),
      ),
      entries: [compilerNode(1)],
      regions: compilerCatalog,
      options: compilerOptions(),
    ).config;
    final rules = (config['routing']['rules'] as List).cast<Map>();
    final domain = rules.singleWhere(
      (rule) => rule['ruleTag'] == 'app-smart-direct-domain',
    );
    final ip = rules.singleWhere(
      (rule) => rule['ruleTag'] == 'app-smart-direct-ip',
    );
    expect(domain['domain'], contains('geosite:CN'));
    expect(domain['outboundTag'], 'direct');
    expect(ip['ip'], contains('geoip:CN'));
    expect(ip['outboundTag'], 'direct');
  });

  test('a picked region sends direct only its own names and the '
      'local-network names', () {
    final mapping = jsonDecode(
      File(RegionCatalog.assetPath).readAsStringSync(),
    ) as Map<String, dynamic>;
    List<String> installed(String kind) => [
      for (final categories in (mapping[kind] as Map).values)
        ...(categories as List).cast<String>(),
    ];
    final catalog = RegionCatalog.fromJson(
      mapping,
      geositeCodes: installed('geosite'),
      geoipCodes: installed('geoip'),
    );
    // Anti-vacuity: the shipped mapping offers exactly the picker regions.
    expect(
      (mapping['geosite'] as Map).keys.toSet(),
      _pickedRegionDomains.keys.toSet(),
    );
    // The stored shape before a pick carries the Apple and Windows switches
    // on.
    final stored = ConnectionConfiguration();
    expect(stored.connection.smart.directApple, isTrue);
    expect(stored.connection.smart.directWindows, isTrue);

    for (final MapEntry(key: code, value: domains)
        in _pickedRegionDomains.entries) {
      final settings = OneVpnDirectRegionsApplyService.nextConfiguration(
        stored,
        code,
      ).connection;
      for (final (platform, interfaceName) in _platforms) {
        final label = '$code ${platform.name}';
        final config = ConnectionCompiler.compile(
          settings: settings,
          entries: [compilerNode(1)],
          regions: catalog,
          options: compilerOptions(
            platform: platform,
            interfaceName: interfaceName,
          ),
        ).config;
        final rules = (config['routing']['rules'] as List).cast<Map>();
        expect(
          rules.singleWhere(
            (rule) => rule['ruleTag'] == 'app-smart-direct-domain',
          ),
          {
            'ruleTag': 'app-smart-direct-domain',
            'domain': domains,
            'outboundTag': 'direct',
          },
          reason: label,
        );
        expect(
          rules.singleWhere((rule) => rule['ruleTag'] == 'app-smart-direct-ip'),
          {
            'ruleTag': 'app-smart-direct-ip',
            'ip': ['geoip:PRIVATE', 'geoip:$code'],
            'outboundTag': 'direct',
          },
          reason: label,
        );
        // Beside the direct DNS server's own rule, these two are the only
        // rules that send a flow direct.
        expect(
          [
            for (final rule in rules)
              if (rule['outboundTag'] == 'direct' &&
                  rule['ruleTag'] != 'app-direct-dns')
                rule['ruleTag'],
          ],
          ['app-smart-direct-domain', 'app-smart-direct-ip'],
          reason: label,
        );
        // No rule sends GitHub through the proxy ahead of the direct
        // domains, so the DoH pair stays unscoped.
        expect(
          rules.map((rule) => rule['ruleTag']),
          isNot(contains('app-smart-github')),
          reason: label,
        );
        final servers = _servers(config);
        expect(servers[0].containsKey('domains'), isFalse, reason: label);
        expect(servers[1].containsKey('domains'), isFalse, reason: label);
        // On Android the direct server answers the same names.
        if (platform == ConnectionPlatform.android) {
          expect(servers.last['tag'], ConnectionCompiler.dnsDirect);
          expect(servers.last['domains'], domains, reason: label);
        }
      }
    }
  });

  test('a free node dials its literal and its hostname never compiles', () {
    // A complete define: a TEST-NET literal for every free host.
    final hosts = <String>[
      for (final location in kOneVpnFreeCatalogue)
        for (final server in location.servers ?? const <OneVpnApiServer>[])
          server.host,
    ];
    final ips = OneVpnFreeNodeIps.parse(
      [for (final (i, host) in hosts.indexed) '$host=192.0.2.${i + 1}']
          .join(','),
      hosts: kOneVpnFreeHosts,
    );
    final servers = <OneVpnServer>[
      for (final location in ips.applyTo(kOneVpnFreeCatalogue))
        ...OneVpnLocation.fromApi(location, freeTier: true).servers,
    ];
    expect(servers, hasLength(6));

    for (final server in servers) {
      for (final platform in [
        ConnectionPlatform.android,
        ConnectionPlatform.linux,
      ]) {
        for (final mode in [TrafficMode.smart, TrafficMode.allVpn]) {
          final plan = ConnectionCompiler.compile(
            settings: ConnectionSettings(trafficMode: mode),
            entries: [
              ResolvedServer(
                id: 1,
                sourceId: 1,
                outbound: OneVpnOutboundBuilder.build(
                  server: server,
                  credentials: _freeCredentials,
                ),
              ),
            ],
            regions: compilerCatalog,
            options: compilerOptions(
              platform: platform,
              interfaceName: platform == ConnectionPlatform.linux
                  ? 'selected-interface'
                  : '',
            ),
          );
          final entry = (plan.config['outbounds'] as List)
              .cast<Map>()
              .singleWhere((outbound) => outbound['tag'] == 'app-entry-0');
          expect(entry['protocol'], 'vless');
          expect(entry['settings']['address'], server.ip, reason: server.host);
          // The REALITY server name stays the catalogue's camouflage SNI.
          expect(
            entry['streamSettings']['realitySettings']['serverName'],
            server.sni,
          );
          expect(plan.xrayJson, isNot(contains(server.host)));
        }
      }
    }
  });

  test('the proxy balancer always selects a proxy outbound', () {
    for (final (label, config) in _compiledModes()) {
      final selector = (_balancer(config, label)['selector'] as List)
          .cast<String>();
      final outbounds = (config['outbounds'] as List).cast<Map>();
      final proxyTags = [
        for (final outbound in outbounds)
          if (!_appProtocols.contains(outbound['protocol']))
            outbound['tag'] as String,
      ];
      // Xray selects each outbound whose tag starts with a selector entry.
      // An entry that matches no proxy outbound is a desynced prefix.
      for (final prefix in selector) {
        expect(
          proxyTags.where((tag) => tag.startsWith(prefix)),
          isNotEmpty,
          reason: '$label: $prefix',
        );
      }
      final selected = [
        for (final outbound in outbounds)
          if (selector.any((outbound['tag'] as String).startsWith))
            outbound['protocol'],
      ];
      // The selection is never empty. It holds proxy outbounds only.
      expect(selected, isNotEmpty, reason: label);
      expect(selected, everyElement(isNot(isIn(_appProtocols))), reason: label);
    }
  });

  test('the proxy balancer keeps its strategy and its ruled fallback', () {
    for (final (label, config) in _compiledModes()) {
      final balancer = _balancer(config, label);
      // A strategy that can pick nothing sends traffic to the fallback.
      expect(balancer['strategy']['type'], 'roundRobin', reason: label);
      // roundRobin with a fallback drops each candidate observed dead.
      // An empty observatory observes no candidate.
      expect(config['observatory'], {'subjectSelector': []}, reason: label);
      expect(balancer['fallbackTag'], _ruledFallbackTag, reason: label);
    }
  });

  test('block leads every mode', () {
    final chained = ConnectionCompiler.compile(
      settings: ConnectionSettings(
        trafficMode: TrafficMode.smart,
        smart: SmartRoutingSettings(entryCount: 2, finalExitId: 9),
      ),
      entries: [compilerNode(1), compilerNode(2)],
      finalExit: compilerNode(9),
      regions: compilerCatalog,
      options: compilerOptions(),
    ).config;
    final cases = [
      ..._compiledModes(),
      for (final (platform, interfaceName) in _platforms)
        (
          '${platform.name} all-VPN',
          ConnectionCompiler.compile(
            settings: ConnectionSettings(),
            entries: [compilerNode(1)],
            regions: compilerCatalog,
            options: compilerOptions(
              platform: platform,
              interfaceName: interfaceName,
            ),
          ).config,
        ),
      ('android smart chain', chained),
    ];
    for (final (label, config) in cases) {
      final outbounds = (config['outbounds'] as List).cast<Map>();
      expect(outbounds.first, {
        'tag': 'block',
        'protocol': 'blackhole',
      }, reason: label);
      expect(
        outbounds.where((outbound) => outbound['protocol'] == 'blackhole'),
        hasLength(1),
        reason: label,
      );
    }
  });

  test('the ruled fallback is block', () {
    for (final (label, config) in _compiledModes()) {
      final fallback = _balancer(config, label)['fallbackTag'];
      expect(fallback, 'block', reason: label);
      final outbounds = (config['outbounds'] as List).cast<Map>();
      expect(outbounds.singleWhere((outbound) => outbound['tag'] == fallback), {
        'tag': 'block',
        'protocol': 'blackhole',
      }, reason: label);
    }
  });

  test('the catch-all is last, carries network, and routes to proxy', () {
    final adsAndRegions = ConnectionCompiler.compile(
      settings: ConnectionSettings(
        trafficMode: TrafficMode.smart,
        smart: SmartRoutingSettings(
          blockAds: true,
          directRegions: const ['CN'],
        ),
      ),
      entries: [compilerNode(1)],
      regions: compilerCatalog,
      options: compilerOptions(),
    ).config;
    for (final (label, config) in [
      ..._compiledModes(),
      ('android smart ads', adsAndRegions),
    ]) {
      final rules = (config['routing']['rules'] as List).cast<Map>();
      // The whole rule body. A domain, ip, port or inboundTag key would
      // narrow the match and let a flow fall through.
      expect(rules.last, {
        'ruleTag': oneVpnCatchAllRuleTag,
        'network': 'tcp,udp',
        'balancerTag': 'proxy',
      }, reason: label);
      expect(_balancer(config, label)['tag'], 'proxy', reason: label);
      expect(
        rules.where((rule) => rule['ruleTag'] == oneVpnCatchAllRuleTag),
        hasLength(1),
        reason: label,
      );
    }
  });

  test('All-VPN keeps AsIs and Smart keeps IPIfNonMatch with the '
      'catch-all', () {
    for (final (platform, interfaceName) in _platforms) {
      for (final mode in TrafficMode.values) {
        final label = '${platform.name} ${mode.name}';
        final config = ConnectionCompiler.compile(
          settings: ConnectionSettings(
            trafficMode: mode,
            smart: SmartRoutingSettings(directRegions: const ['CN']),
          ),
          entries: [compilerNode(1)],
          custom: mode == TrafficMode.custom ? _customProfile() : null,
          regions: compilerCatalog,
          options: compilerOptions(
            platform: platform,
            interfaceName: interfaceName,
          ),
        ).config;
        final rules = (config['routing']['rules'] as List).cast<Map>();
        expect(rules.last['ruleTag'], oneVpnCatchAllRuleTag, reason: label);
        expect(
          config['routing']['domainStrategy'],
          mode == TrafficMode.allVpn ? 'AsIs' : 'IPIfNonMatch',
          reason: label,
        );
      }
    }
  });

  test('the DoH pair and the DoT rule route through the balancer', () {
    for (final (label, config) in _compiledModes()) {
      final tag = _balancer(config, label)['tag'];
      final rules = (config['routing']['rules'] as List).cast<Map>();
      final servers = (config['dns']['servers'] as List).cast<Map>();
      expect(servers, isNotEmpty, reason: label);
      final appDefault = rules.singleWhere(
        (rule) => rule['ruleTag'] == 'app-default',
      );
      // Each DoH server dials as an inbound tag that app-default matches.
      // The direct server routes direct. The direct DNS pins above cover it.
      for (final server in servers.where(
        (server) => server['tag'] != ConnectionCompiler.dnsDirect,
      )) {
        expect(
          appDefault['inboundTag'],
          contains(server['tag']),
          reason: label,
        );
      }
      expect(appDefault['balancerTag'], tag, reason: label);
      final dot = rules.singleWhere(
        (rule) => rule['ruleTag'] == 'app-tunnel-dot',
      );
      expect(dot['balancerTag'], tag, reason: label);
    }
  });
  test('the handed pair is the tunnel\'s own on every platform', () {
    // Stored foreign values never reach the push. The pair is the second
    // host of each TUN subnet: never the interface's own address, and
    // inside the reserved benchmarking and unique-local ranges, so never a
    // public operator's address.
    final stored = PlatformPolicy.fromJson({
      'xrayOutboundInterfaceName': 'Ethernet',
      'dnsIpv4Address': '192.0.2.53',
      'dnsIpv6Address': '2001:db8::53',
    });
    for (final platform in ConnectionPlatform.values) {
      final tun = stored.toTun(platform);
      expect(tun.tunDnsIPv4, tunnelDnsIpv4Address, reason: platform.name);
      expect(tun.tunDnsIPv6, tunnelDnsIpv6Address, reason: platform.name);
      expect(tun.tunIPv4, PlatformPolicy.tunIpv4Address);
      expect(tun.tunDnsIPv4, isNot(tun.tunIPv4), reason: platform.name);
      expect(tun.tunDnsIPv6, isNot(PlatformPolicy.tunIpv6Address));
    }
    // The second host of the interface's /15 and of its /64.
    final ipv4 = InternetAddress(tunnelDnsIpv4Address).rawAddress;
    final interface4 = InternetAddress(PlatformPolicy.tunIpv4Address);
    expect(ipv4.sublist(0, 3), interface4.rawAddress.sublist(0, 3));
    expect(ipv4[3], interface4.rawAddress[3] + 1);
    expect(ipv4.sublist(0, 2), [198, 18]);
    final ipv6 = InternetAddress(tunnelDnsIpv6Address).rawAddress;
    final interface6 = InternetAddress(PlatformPolicy.tunIpv6Address);
    expect(ipv6.sublist(0, 15), interface6.rawAddress.sublist(0, 15));
    expect(ipv6[15], interface6.rawAddress[15] + 1);
    expect(ipv6[0], 0xfc);
  });

  test('the guard compiles right behind the port 53 rule in every mode and '
      'on every platform', () {
    for (final (platform, interfaceName) in _platforms) {
      for (final ipv6 in [true, false]) {
        for (final (mode, settings, custom) in _guardModes()) {
          final label = '${platform.name} $mode ipv6=$ipv6';
          final rules = _rules(
            settings,
            custom,
            platform: platform,
            interfaceName: interfaceName,
            ipv6: ipv6,
          );
          final tags = rules.map((rule) => rule['ruleTag']).toList();
          final guard = tags.indexOf(tunnelDnsGuardTag);
          // The whole rule body. Both addresses compile with or without
          // IPv6, and no port or network condition narrows the match.
          expect(rules[guard], {
            'ruleTag': tunnelDnsGuardTag,
            'inboundTag': ['tunIn'],
            'ip': [tunnelDnsIpv4Address, tunnelDnsIpv6Address],
            'outboundTag': 'block',
          }, reason: label);
          expect(tags.where((tag) => tag == tunnelDnsGuardTag), hasLength(1));
          expect(tags.indexOf('app-tunnel-dns') + 1, guard, reason: label);
          expect(tags.indexOf('app-tunnel-dot'), guard + 1, reason: label);
          // Every rule that sends a flow direct or to the balancer stands
          // behind the guard, apart from the two that match only the
          // core's own DNS tags.
          for (final (index, rule) in rules.indexed) {
            final leaves =
                rule['outboundTag'] == 'direct' || rule['balancerTag'] != null;
            if (!leaves) continue;
            if (const {
              'app-default',
              'app-direct-dns',
            }.contains(rule['ruleTag'])) {
              expect(rule['inboundTag'], isNot(contains('tunIn')));
              continue;
            }
            expect(
              index,
              greaterThan(guard),
              reason: '$label ${rule['ruleTag']}',
            );
          }
        }
      }
    }
  });

  test('no flow to the tunnel\'s own pair reaches a direct rule or the '
      'balancer', () {
    // Port 53 reaches the dns outbound. Every other port, on TCP and UDP,
    // reaches the block outbound. The walk counts a geoip list, a range or
    // a domain as a match, so a rule that could capture a flow ends it.
    const ports = [53, 0, 1, 52, 54, 80, 443, 853, 5353, 65535];
    for (final (platform, interfaceName) in _platforms) {
      for (final (mode, settings, custom) in _guardModes()) {
        final rules = _rules(
          settings,
          custom,
          platform: platform,
          interfaceName: interfaceName,
        );
        for (final address in [tunnelDnsIpv4Address, tunnelDnsIpv6Address]) {
          for (final network in ['tcp', 'udp']) {
            for (final port in ports) {
              final label = '${platform.name} $mode $address $network:$port';
              final matching = [
                for (final rule in rules)
                  if (_canMatch(rule, address, port, network)) rule,
              ];
              final first = matching.first;
              if (port == 53) {
                expect(first['ruleTag'], 'app-tunnel-dns', reason: label);
                expect(
                  first['outboundTag'],
                  ConnectionCompiler.dnsOutbound,
                  reason: label,
                );
              } else {
                expect(first['ruleTag'], tunnelDnsGuardTag, reason: label);
                expect(first['outboundTag'], 'block', reason: label);
              }
              // Anti-vacuity guard. Without the guard, a later rule would
              // send the flow direct or to the balancer.
              expect(
                matching
                    .skip(1)
                    .where((rule) => rule['ruleTag'] != tunnelDnsGuardTag)
                    .any(
                      (rule) =>
                          rule['outboundTag'] == 'direct' ||
                          rule['balancerTag'] != null,
                    ),
                isTrue,
                reason: label,
              );
            }
          }
        }
        // The region and custom cases carry a direct rule that covers the
        // pair, so the guard's place is what keeps the flow in.
        if (mode != 'all-VPN' && mode != 'region CN, local network off') {
          final behind = rules.skip(
            rules.indexWhere((rule) => rule['ruleTag'] == tunnelDnsGuardTag) +
                1,
          );
          expect(
            behind.any(
              (rule) =>
                  rule['outboundTag'] == 'direct' &&
                  ((rule['ip'] as List?)?.any(
                        (ip) => ip == 'geoip:PRIVATE' || ip == '198.18.0.0/15',
                      ) ??
                      false),
            ),
            isTrue,
            reason: '${platform.name} $mode',
          );
        }
      }
    }
  });

  test('every direct outbound blocks the tunnel\'s own pair per datagram', () {
    // The guard decides once per flow, and the core routes a UDP socket on
    // its first datagram. The direct outbound's final rule drops a later
    // datagram to the pair. The whole outbound body is pinned: the rule is
    // its one setting, and the desktop interface binding stands as before.
    for (final (platform, interfaceName) in _platforms) {
      for (final ipv6 in [true, false]) {
        for (final (mode, settings, custom) in _guardModes()) {
          final config = ConnectionCompiler.compile(
            settings: settings,
            entries: [compilerNode(1)],
            custom: custom,
            regions: compilerCatalog,
            options: compilerOptions(
              platform: platform,
              interfaceName: interfaceName,
              ipv6: ipv6,
            ),
          ).config;
          final label = '${platform.name} $mode ipv6=$ipv6';
          final direct = [
            for (final outbound in (config['outbounds'] as List).cast<Map>())
              if (outbound['tag'] == 'direct') outbound,
          ];
          expect(direct, hasLength(1), reason: label);
          expect(direct.single, {
            'tag': 'direct',
            'protocol': 'freedom',
            'settings': {
              'finalRules': [
                {
                  'action': 'block',
                  'ip': [tunnelDnsIpv4Address, tunnelDnsIpv6Address],
                },
              ],
            },
            if (interfaceName.isNotEmpty)
              'streamSettings': {
                'sockopt': {'interface': interfaceName},
              },
          }, reason: label);
        }
      }
    }
  });

  test('DoT to any other address rides the balancer in every mode', () {
    // Strict Private DNS providers keep the balancer route. TEST-NET
    // addresses stand in for a chosen provider. Cloudflare's addresses
    // ride it too.
    for (final (platform, interfaceName) in _platforms) {
      for (final (mode, settings, custom) in _guardModes()) {
        final rules = _rules(
          settings,
          custom,
          platform: platform,
          interfaceName: interfaceName,
        );
        for (final provider in const [
          '1.1.1.1',
          '1.0.0.1',
          '192.0.2.53',
          '198.51.100.53',
          '2001:db8::53',
        ]) {
          for (final network in ['tcp', 'udp']) {
            final first = rules.firstWhere(
              (rule) => _canMatch(rule, provider, 853, network),
            );
            expect(
              first['ruleTag'],
              'app-tunnel-dot',
              reason: '${platform.name} $mode $provider $network',
            );
            expect(first['balancerTag'], 'proxy');
          }
        }
      }
    }
  });
}

/// Custom rules that would capture a flow to the tunnel's own pair if they
/// came first.
final _capturingPair = RoutingProfileState(
  name: 'Capturing the pair',
  rules: [
    RoutingRuleState(
      ip: const ['198.18.0.0/15', 'fc00::/7'],
      action: RoutingRuleAction.direct,
    ),
    RoutingRuleState(
      domain: const ['geosite:PRIVATE'],
      action: RoutingRuleAction.direct,
    ),
    RoutingRuleState(port: '1-65535', action: RoutingRuleAction.direct),
  ],
);

/// The modes the guard pins walk: All-VPN, a picked region with the
/// local-network switch on and off, a region with the ad and GitHub rules,
/// and custom.
List<(String, ConnectionSettings, RoutingProfileState?)> _guardModes() => [
  ('all-VPN', ConnectionSettings(), null),
  (
    'region CN',
    OneVpnDirectRegionsApplyService.nextConfiguration(
      ConnectionConfiguration(),
      'CN',
    ).connection,
    null,
  ),
  (
    'region CN, local network off',
    ConnectionSettings(
      trafficMode: TrafficMode.smart,
      smart: SmartRoutingSettings(
        directRegions: const ['CN'],
        directPrivate: false,
      ),
    ),
    null,
  ),
  (
    'region CN with ads and GitHub',
    ConnectionSettings(
      trafficMode: TrafficMode.smart,
      smart: SmartRoutingSettings(blockAds: true, directRegions: const ['CN']),
    ),
    null,
  ),
  (
    'custom',
    ConnectionSettings(trafficMode: TrafficMode.custom),
    _capturingPair,
  ),
];

/// The compiled rules for one mode on one platform.
List<Map> _rules(
  ConnectionSettings settings,
  RoutingProfileState? custom, {
  required ConnectionPlatform platform,
  required String interfaceName,
  bool ipv6 = true,
}) {
  final config = ConnectionCompiler.compile(
    settings: settings,
    entries: [compilerNode(1)],
    custom: custom,
    regions: compilerCatalog,
    options: compilerOptions(
      platform: platform,
      interfaceName: interfaceName,
      ipv6: ipv6,
    ),
  ).config;
  return (config['routing']['rules'] as List).cast<Map>();
}

/// Whether [rule] can match a flow from the TUN to [address] on [port] over
/// [network]. An IP literal matches only itself. A geoip list, a range, a
/// domain and every other condition count as a match, so the walk errs
/// toward a match.
bool _canMatch(Map rule, String address, int port, String network) {
  final inbound = rule['inboundTag'] as List?;
  if (inbound != null && !inbound.contains('tunIn')) return false;
  final ports = rule['port'];
  if (ports != null && !ConnectionCompiler.portIncludes(ports, port)) {
    return false;
  }
  final networks = rule['network'] as String?;
  if (networks != null && !networks.split(',').contains(network)) {
    return false;
  }
  final ips = (rule['ip'] as List?)?.cast<String>();
  if (ips != null &&
      !ips.any(
        (ip) =>
            ip == address ||
            ip.contains('/') ||
            ip.startsWith('geoip:') ||
            ip.startsWith('ext:'),
      )) {
    return false;
  }
  return true;
}
