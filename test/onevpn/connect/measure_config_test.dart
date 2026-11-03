// Pins the measure config. It blocks every TCP and UDP flow. The burst
// observatory probes each candidate on a failover domain. A candidate
// outbound equals the entry the compiler emits for that row. The inbound,
// DNS, log and metrics values equal the pinned config's.

import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/catalogue/location.dart';
import 'package:onexray/onevpn/connect/measure_config.dart';
import 'package:onexray/onevpn/connect/native_auto_contracts.dart';
import 'package:onexray/onevpn/model/user_data.dart';
import 'package:onexray/onevpn/net/failover_domains.dart';
import 'package:onexray/onevpn/net/probe_endpoints.dart';
import 'package:onexray/onevpn/provision/outbound_builder.dart';
import 'package:onexray/service/connect/compiler.dart';
import 'package:onexray/service/connect/routing/custom/state.dart';
import 'package:onexray/service/connect/settings.dart';

import '../support/compiler_fixtures.dart';

/// The builder under test, held through the shared typedef.
const OneVpnMeasureConfigBuilder _build = oneVpnMeasureConfig;

/// A complete credential triple. Its values are placeholders.
const _credentials = OneVpnCredentials(
  uuid: '00000000-0000-4000-8000-000000000000',
  publicKey: 'test-public-key',
  shortId: 'deadbeef',
);

/// A provisioned row named under [prefix]. Its outbound also carries a
/// legacy `name` key. A null [ip] dials the hostname.
ResolvedServer _row(int id, String prefix, {String? ip}) => ResolvedServer(
  id: id,
  sourceId: 1,
  outbound: {
    'tag': '${prefix}ams·$id',
    'name': 'Amsterdam $id',
    ...OneVpnOutboundBuilder.build(
      server: OneVpnServer(host: 'node-$id.test', sni: 'sni.example', ip: ip),
      credentials: _credentials,
    ),
  },
);

/// Two account rows, one of them dialed by name, and one free row.
final _candidates = [
  _row(17, OneVpnLocation.accountRowNamePrefix, ip: '192.0.2.17'),
  _row(4, OneVpnLocation.accountRowNamePrefix),
  _row(3, OneVpnLocation.freeRowNamePrefix, ip: '192.0.2.3'),
];

/// The mobile platforms the app ships on.
const _platforms = [ConnectionPlatform.android, ConnectionPlatform.ios];

/// The compiled config of [entry] in [mode] on [platform].
Map<String, dynamic> _compiled(
  ResolvedServer entry, {
  TrafficMode mode = TrafficMode.allVpn,
  ConnectionPlatform platform = ConnectionPlatform.android,
}) => ConnectionCompiler.compile(
  settings: ConnectionSettings(
    trafficMode: mode,
    smart: SmartRoutingSettings(directRegions: const ['CN']),
  ),
  entries: [entry],
  custom: mode == TrafficMode.custom
      ? RoutingProfileState(
          name: 'Pinned',
          rules: [
            RoutingRuleState(
              domain: const ['domain:direct.test'],
              action: RoutingRuleAction.direct,
            ),
          ],
        )
      : null,
  regions: compilerCatalog,
  options: compilerOptions(platform: platform),
).config;

/// Every platform and traffic mode, each with the pinned config of the
/// first candidate.
List<(String, Map<String, dynamic>)> _pinnedCases() => [
  for (final platform in _platforms)
    for (final mode in TrafficMode.values)
      (
        '${platform.name} ${mode.name}',
        _compiled(_candidates.first, mode: mode, platform: platform),
      ),
];

List<Map> _outbounds(Map<String, dynamic> config) =>
    (config['outbounds'] as List).cast<Map>();

void main() {
  test('the measure config tags every candidate by id and tier', () {
    final pinned = _compiled(_candidates.first);
    final config = _build(
      pinned: pinned,
      candidates: _candidates,
      probeUrl: ProbeEndpoints.urls.first,
    );
    final outbounds = _outbounds(config);
    expect(outbounds.map((outbound) => outbound['tag']), [
      'block',
      'app-cand-acct-17',
      'app-cand-acct-4',
      'app-cand-free-3',
      'direct',
    ]);
    for (final (index, candidate) in _candidates.indexed) {
      final tag = outbounds[index + 1]['tag'] as String;
      expect(OneVpnCandidateTags.idOf(tag), candidate.id);
      expect(
        OneVpnCandidateTags.isAccount(tag),
        candidate.name.startsWith(OneVpnLocation.accountRowNamePrefix),
      );
    }
    // block and direct are the pinned config's own outbounds.
    expect(
      outbounds.first,
      _outbounds(pinned).singleWhere((outbound) => outbound['tag'] == 'block'),
    );
    expect(
      outbounds.last,
      _outbounds(pinned).singleWhere((outbound) => outbound['tag'] == 'direct'),
    );
  });

  test('a candidate equals its compiled entry', () {
    for (final platform in _platforms) {
      for (final mode in TrafficMode.values) {
        final label = '${platform.name} ${mode.name}';
        final config = _build(
          pinned: _compiled(_candidates.first, mode: mode, platform: platform),
          candidates: _candidates,
          probeUrl: ProbeEndpoints.urls.first,
        );
        for (final candidate in _candidates) {
          final tag = OneVpnCandidateTags.tagFor(candidate);
          final entry = _outbounds(
            _compiled(candidate, mode: mode, platform: platform),
          ).singleWhere((outbound) => outbound['tag'] == 'app-entry-0');
          expect(
            _outbounds(config)
                .singleWhere((outbound) => outbound['tag'] == tag),
            {...entry, 'tag': tag},
            reason: '$label $tag',
          );
        }
      }
    }
  });

  test('the measure config has no observatory key, no balancer and no '
      'dnsOut', () {
    for (final (label, pinned) in _pinnedCases()) {
      final config = _build(
        pinned: pinned,
        candidates: _candidates,
        probeUrl: ProbeEndpoints.urls.first,
      );
      // Anti-vacuity guard. The pinned config carries all three.
      expect(pinned.containsKey('observatory'), isTrue, reason: label);
      expect(pinned['routing']['balancers'], isNotEmpty, reason: label);
      expect(
        _outbounds(pinned).map((outbound) => outbound['tag']),
        contains(ConnectionCompiler.dnsOutbound),
        reason: label,
      );

      expect(config.keys.toSet(), {
        'env',
        'log',
        'stats',
        'policy',
        'metrics',
        'inbounds',
        'dns',
        'outbounds',
        'burstObservatory',
        'routing',
      }, reason: label);
      // The whole routing value. Its one rule sends every TCP and UDP flow
      // to block.
      expect(config['routing'], {
        'domainStrategy': 'AsIs',
        'rules': [
          {
            'ruleTag': oneVpnMeasureBlockRuleTag,
            'network': 'tcp,udp',
            'outboundTag': 'block',
          },
        ],
      }, reason: label);
      expect(
        _outbounds(config).map((outbound) => outbound['protocol']),
        isNot(contains('dns')),
        reason: label,
      );
    }
  });

  test('the burst block pins its five fields', () {
    for (final url in ProbeEndpoints.urls) {
      final config = _build(
        pinned: _compiled(_candidates.first),
        candidates: _candidates,
        probeUrl: url,
      );
      expect(config['burstObservatory'], {
        'subjectSelector': ['app-cand-'],
        'pingConfig': {
          'destination': url,
          'interval': '10s',
          'sampling': 1,
          'timeout': '3s',
          'httpMethod': 'HEAD',
        },
      }, reason: url);
      // The selector matches each candidate and nothing else.
      final selector = (config['burstObservatory']['subjectSelector'] as List)
          .cast<String>();
      for (final outbound in _outbounds(config)) {
        final tag = outbound['tag'] as String;
        expect(
          selector.any(tag.startsWith),
          OneVpnCandidateTags.idOf(tag) != null,
          reason: tag,
        );
      }
    }
  });

  test('the measure inbound and metrics equal the pinned ones', () {
    for (final (label, pinned) in _pinnedCases()) {
      final config = _build(
        pinned: pinned,
        candidates: _candidates,
        probeUrl: ProbeEndpoints.urls.first,
      );
      expect(config['inbounds'], pinned['inbounds'], reason: label);
      expect(
        (config['inbounds'] as List).cast<Map>().single['tag'],
        'tunIn',
        reason: label,
      );
      expect(config['metrics'], pinned['metrics'], reason: label);
      expect(config['metrics'], {'listen': '127.0.0.1:18186'}, reason: label);
      for (final key in ['env', 'log', 'stats', 'policy', 'dns']) {
        expect(config[key], pinned[key], reason: '$label $key');
      }
      // The result shares no mutable state with the pinned config.
      (config['inbounds'] as List).clear();
      (config['dns'] as Map).clear();
      expect(pinned['inbounds'], isNotEmpty, reason: label);
      expect(pinned['dns'], isNotEmpty, reason: label);
    }
  });

  test('the probe URL is a failover domain', () {
    expect(ProbeEndpoints.urls, hasLength(OneVpnFailoverDomains.all.length));
    for (final url in ProbeEndpoints.urls) {
      final destination =
          _build(
                pinned: _compiled(_candidates.first),
                candidates: _candidates,
                probeUrl: url,
              )['burstObservatory']['pingConfig']['destination']
              as String;
      final uri = Uri.parse(destination);
      expect(uri.scheme, 'https', reason: url);
      expect(OneVpnFailoverDomains.all, contains(uri.host), reason: url);
      expect(uri.path, '/ping/', reason: url);
    }
    for (final url in const [
      'https://probe.invalid/ping/',
      'http://1vpn.org/ping/',
      'https://1vpn.org/',
      '',
    ]) {
      expect(
        () => _build(
          pinned: _compiled(_candidates.first),
          candidates: _candidates,
          probeUrl: url,
        ),
        throwsFormatException,
        reason: url,
      );
    }
  });

  test('an empty candidate list throws', () {
    expect(
      () => _build(
        pinned: _compiled(_candidates.first),
        candidates: const [],
        probeUrl: ProbeEndpoints.urls.first,
      ),
      throwsFormatException,
    );
  });

  test('a pinned config without block or direct throws', () {
    for (final tag in ['block', 'direct']) {
      final pinned = _compiled(_candidates.first);
      (pinned['outbounds'] as List).removeWhere(
        (outbound) => (outbound as Map)['tag'] == tag,
      );
      expect(
        () => _build(
          pinned: pinned,
          candidates: _candidates,
          probeUrl: ProbeEndpoints.urls.first,
        ),
        throwsFormatException,
        reason: tag,
      );
    }
  });
}
