import 'package:onexray/core/tools/json.dart';
import 'package:onexray/onevpn/connect/native_auto_contracts.dart';
import 'package:onexray/onevpn/net/probe_endpoints.dart';
import 'package:onexray/service/connect/compiler.dart';

/// The keys a measure config copies from the pinned config.
const _pinnedKeys = [
  'env',
  'log',
  'stats',
  'policy',
  'metrics',
  'inbounds',
  'dns',
  'fakedns',
];

/// Builds the measure config that probes [candidates] while it blocks every
/// flow. It matches [OneVpnMeasureConfigBuilder].
///
/// The config copies `env`, `log`, `stats`, `policy`, `metrics`, `inbounds`,
/// `dns` and `fakedns` from [pinned], each where [pinned] carries it. It adds
/// three keys of its own and no others:
///
///  * `outbounds`: `block`, one outbound per candidate in list order, then
///    `direct`. A candidate outbound is the row's outbound without its
///    `name`, under its [OneVpnCandidateTags.tagFor] tag. `block` and
///    `direct` copy from [pinned].
///  * `burstObservatory`: probes [probeUrl] through every candidate with an
///    HTTP HEAD. One round runs at core start. Further rounds follow every
///    [oneVpnMeasureProbeInterval]. A candidate's latest probe decides whether it reads alive.
///  * `routing`: the one rule [oneVpnMeasureBlockRuleTag], which sends every
///    TCP and UDP flow to `block`.
///
/// The result shares no mutable state with [pinned] or [candidates].
///
/// An empty [candidates] throws a [FormatException]. So does a [probeUrl]
/// outside [ProbeEndpoints.urls]. So does a [pinned] without a `block` or a
/// `direct` outbound.
Map<String, dynamic> oneVpnMeasureConfig({
  required Map<String, dynamic> pinned,
  required List<ResolvedServer> candidates,
  required String probeUrl,
}) {
  if (candidates.isEmpty) {
    throw const FormatException('A measure config needs a candidate');
  }
  if (!ProbeEndpoints.urls.contains(probeUrl)) {
    throw const FormatException('The probe URL is not a failover domain');
  }
  final source = JsonTool.copyMap(pinned);
  return {
    for (final key in _pinnedKeys)
      if (source.containsKey(key)) key: source[key],
    'outbounds': [
      _outbound(source, 'block'),
      for (final candidate in candidates)
        candidate.outbound
          ..remove('name')
          ..['tag'] = OneVpnCandidateTags.tagFor(candidate),
      _outbound(source, 'direct'),
    ],
    'burstObservatory': {
      'subjectSelector': [OneVpnCandidateTags.prefix],
      'pingConfig': {
        'destination': probeUrl,
        'interval': '${oneVpnMeasureProbeInterval.inSeconds}s',
        'sampling': 1,
        'timeout': '3s',
        'httpMethod': 'HEAD',
      },
    },
    'routing': {
      'domainStrategy': 'AsIs',
      'rules': [
        {
          'ruleTag': oneVpnMeasureBlockRuleTag,
          'network': 'tcp,udp',
          'outboundTag': 'block',
        },
      ],
    },
  };
}

/// The outbound tagged [tag] in [config].
Map<String, dynamic> _outbound(Map<String, dynamic> config, String tag) {
  final outbounds = config['outbounds'];
  if (outbounds is List) {
    for (final outbound in outbounds) {
      if (outbound is Map<String, dynamic> && outbound['tag'] == tag) {
        return outbound;
      }
    }
  }
  throw FormatException('The pinned config has no $tag outbound');
}
