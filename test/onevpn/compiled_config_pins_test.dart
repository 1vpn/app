// Pins the compiled resolver surface. The DoH servers lead in fallback
// order and ride the tunnel in every traffic mode. So do the raw rewrite
// target and the dns outbound's tunnel dial. The TUN push matches the
// rewrite target, and the port-53/853 delivery rules outrank the mode
// rules. Only Android compiles the direct DNS server, and only for a mode
// with direct domains. It follows the DoH pair and carries a loopback
// placeholder that the native side fills. Names the routing proxies or
// blocks resolve at the DoH pair, whose fallback ends their lookup. GitHub
// and ad names never reach the direct server. Every managed inbound sniffs
// route-only, and the direct outbound carries no domain strategy, so a
// direct dial keeps the address the app resolved. No Google resolver, no
// localhost server, and no FakeDNS surface compiles.
//
// This suite also pins the DoT refusal. Where the direct server compiles,
// TCP port 853 to the tunnel resolver goes to the block outbound. DoT to any
// other address still rides the proxy balancer.
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

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/core/ffi/windows/mode.dart';
import 'package:onexray/onevpn/catalogue/free_floor.dart';
import 'package:onexray/onevpn/catalogue/free_node_ips.dart';
import 'package:onexray/onevpn/catalogue/location.dart';
import 'package:onexray/onevpn/connect/native_auto_contracts.dart';
import 'package:onexray/onevpn/model/user_data.dart';
import 'package:onexray/onevpn/net/dns_resolver.dart';
import 'package:onexray/onevpn/net/tunnel_dot_refusal.dart';
import 'package:onexray/onevpn/provision/outbound_builder.dart';
import 'package:onexray/service/connect/compiler.dart';
import 'package:onexray/service/connect/routing/custom/state.dart';
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
/// Smart carries a direct region. The entry is a TEST-NET socks proxy.
List<(String, Map<String, dynamic>)> _compiledModes() => [
  for (final platform in [ConnectionPlatform.android, ConnectionPlatform.linux])
    for (final mode in TrafficMode.values)
      (
        '${platform.name} ${mode.name}',
        ConnectionCompiler.compile(
          settings: ConnectionSettings(
            trafficMode: mode,
            smart: SmartRoutingSettings(directRegions: const ['CN']),
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

/// A smart configuration with the CN region opted in and a stored direct
/// address that must never compile.
ConnectionSettings _regionOptIn({bool directWindows = true}) =>
    ConnectionSettings(
      trafficMode: TrafficMode.smart,
      smart: SmartRoutingSettings(
        directRegions: const ['CN'],
        directWindows: directWindows,
        directDnsAddress: '192.0.2.53',
      ),
    );

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
        // Hijacked A/AAAA resolve over DoH in fallback order: Quad9
        // unfiltered first, then Cloudflare. The Cloudflare URL is an IP
        // literal and needs no resolution of its own.
        expect(servers[0]['address'], 'https://dns10.quad9.net/dns-query');
        expect(servers[1]['address'], 'https://1.1.1.1/dns-query');
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
        expect(dnsOutbound['settings']['rewriteAddress'], '9.9.9.10');
        expect(dnsOutbound['settings']['rewritePort'], 53);
        expect(
          dnsOutbound['streamSettings']['sockopt']['dialerProxy'],
          'app-entry-0',
        );
        expect(dnsOutbound['settings']['rules'], [
          {'action': 'hijack', 'qType': '1,28'},
          {'action': 'direct'},
        ]);
        // No Google resolver anywhere, in any compiled traffic mode.
        expect(plan.xrayJson, isNot(contains('8.8.8.8')));
        expect(plan.xrayJson, isNot(contains('2001:4860:4860::8888')));
        expect(plan.xrayJson, isNot(contains('dns.google')));
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
        'domains': [
          'geosite:PRIVATE',
          'geosite:APPLE',
          'geosite:MICROSOFT',
          'geosite:BING',
          'geosite:CN',
        ],
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
    // unscoped.
    final linux = _servers(
      ConnectionCompiler.compile(
        settings: _regionOptIn(),
        entries: [compilerNode(1)],
        regions: compilerCatalog,
        options: compilerOptions(
          platform: ConnectionPlatform.linux,
          interfaceName: 'selected-interface',
        ),
      ).config,
    );
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

  test('the TUN push aligns to the raw rewrite target', () {
    // The OS resolver push and the raw rewrite target are the same
    // address. Port-53 traffic to either address is hijacked into the
    // dns outbound. The push rides upstream's configurable tunnel-DNS
    // mechanism. The compiler emits options.tunDns*, and the fixture
    // feeds the resolver constants the way preparation does.
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
        expect(inbound['settings']['dns'], [
          '9.9.9.10',
          if (ipv6) '2620:fe::10',
        ]);
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
    // Where the direct server compiles, the DoT refusal stands just ahead
    // of app-tunnel-dot.
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
          if (direct) tunnelDotRefusalTag,
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
  test('the DoT refusal compiles exactly where the direct server does', () {
    final withDirectDomain = RoutingProfileState(
      name: 'Pinned direct domain',
      rules: [
        RoutingRuleState(
          ruleTag: 'cn',
          domain: const ['geosite:CN'],
          action: RoutingRuleAction.direct,
        ),
      ],
    );
    final cases = [
      for (final (platform, interfaceName) in _platforms)
        for (final mode in TrafficMode.values)
          for (final custom in [_customProfile(), withDirectDomain])
            if (mode == TrafficMode.custom || custom == withDirectDomain)
              (platform, interfaceName, mode, custom),
    ];
    var refused = 0;
    for (final (platform, interfaceName, mode, custom) in cases) {
      final label = '${platform.name} ${mode.name} ${custom.name}';
      final config = ConnectionCompiler.compile(
        settings: ConnectionSettings(
          trafficMode: mode,
          smart: _regionOptIn().smart,
        ),
        entries: [compilerNode(1)],
        custom: mode == TrafficMode.custom ? custom : null,
        regions: compilerCatalog,
        options: compilerOptions(
          platform: platform,
          interfaceName: interfaceName,
        ),
      ).config;
      final rules = (config['routing']['rules'] as List).cast<Map>();
      final direct = _servers(config)
          .any((server) => server['tag'] == ConnectionCompiler.dnsDirect);
      final refusals = rules.where(
        (rule) => rule['ruleTag'] == tunnelDotRefusalTag,
      );
      expect(refusals, hasLength(direct ? 1 : 0), reason: label);
      if (direct) refused++;
    }
    // Android smart and Android custom with a direct domain.
    expect(refused, 2);
  });

  test('the DoT refusal blocks TCP 853 to the tunnel resolver only', () {
    for (final ipv6 in [true, false]) {
      final config = ConnectionCompiler.compile(
        settings: _regionOptIn(),
        entries: [compilerNode(1)],
        regions: compilerCatalog,
        options: compilerOptions(ipv6: ipv6),
      ).config;
      final rules = (config['routing']['rules'] as List).cast<Map>();
      final tags = rules.map((rule) => rule['ruleTag']).toList();

      // The whole rule body. Both resolver addresses compile with or
      // without IPv6.
      expect(
        rules.singleWhere((rule) => rule['ruleTag'] == tunnelDotRefusalTag),
        {
          'ruleTag': tunnelDotRefusalTag,
          'inboundTag': ['tunIn'],
          'ip': [dnsResolverAddress, dnsResolverIpv6Address],
          'port': '853',
          'network': 'tcp',
          'outboundTag': 'block',
        },
      );
      expect(dnsResolverAddress, '9.9.9.10');
      expect(dnsResolverIpv6Address, '2620:fe::10');

      // Must stand ahead of app-tunnel-dot: the first matching rule wins.
      expect(
        tags.indexOf(tunnelDotRefusalTag) + 1,
        tags.indexOf('app-tunnel-dot'),
      );
      final block = (config['outbounds'] as List).cast<Map>().singleWhere(
        (outbound) => outbound['tag'] == 'block',
      );
      expect(block['protocol'], 'blackhole');

      // The first delivery rule that a TUN flow on port 853 matches.
      String? first(String address, String network) {
        for (final rule in rules) {
          if (rule['domain'] != null) continue;
          if (!((rule['inboundTag'] as List?)?.contains('tunIn') ?? true)) {
            continue;
          }
          if (rule['port'] != null && rule['port'] != '853') continue;
          if (rule['network'] != null && rule['network'] != network) continue;
          final ips = rule['ip'] as List?;
          if (ips != null && !ips.contains(address)) continue;
          return rule['ruleTag'] as String;
        }
        return null;
      }

      expect(first('9.9.9.10', 'tcp'), tunnelDotRefusalTag);
      expect(first('2620:fe::10', 'tcp'), tunnelDotRefusalTag);
      // Strict Private DNS providers keep the balancer route. TEST-NET
      // addresses stand in for a chosen provider.
      for (final provider in const [
        '1.1.1.1',
        '192.0.2.53',
        '198.51.100.53',
        '2001:db8::53',
      ]) {
        expect(first(provider, 'tcp'), 'app-tunnel-dot', reason: provider);
      }
      // UDP to the tunnel resolver keeps the balancer route.
      expect(first('9.9.9.10', 'udp'), 'app-tunnel-dot');
    }
  });
}
