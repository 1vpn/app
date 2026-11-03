// The build-time IP literals for the free floor's nodes.
//
// The define is a comma-separated list of `host=ip` or `host=ip/ip6` entries.
// Each entry names a free node by its hostname. The parse ignores whitespace
// around each part. Hostnames match in any letter case.

import 'dart:io';

import 'package:onexray/onevpn/model/user_data.dart';

/// The dial literals for one node: an IPv4 address and an optional IPv6 one.
typedef OneVpnNodeLiterals = ({String ip, String? ip6});

/// The parsed define: the literals by hostname, the entries it rejected, and
/// the hostnames no free node carries.
class OneVpnFreeNodeIps {
  const OneVpnFreeNodeIps({
    required this.byHost,
    required this.malformed,
    required this.unknown,
  });

  /// Parses [raw] against the free node [hosts]. Never throws.
  ///
  /// An entry's hostname is its text before the first `=`. An entry with no
  /// `=` is all hostname. Skips a blank entry. Rejects an entry with no
  /// syntactic hostname by its position. Lists a hostname outside [hosts] in
  /// [unknown]. Rejects every entry for a hostname named twice. Rejects an
  /// entry with no `=`, an `ip` that is not IPv4, or an `ip6` that is not
  /// IPv6. A rejected or unknown entry sets no literal.
  static OneVpnFreeNodeIps parse(
    String raw, {
    required Iterable<String> hosts,
  }) {
    final known = <String>{for (final host in hosts) host.toLowerCase()};
    final byHost = <String, OneVpnNodeLiterals>{};
    final malformed = <String>[];
    final unknown = <String>[];
    final seen = <String>{};
    void report(List<String> keys, String key) {
      if (!keys.contains(key)) keys.add(key);
    }

    for (final (index, part) in raw.split(',').indexed) {
      final entry = part.trim();
      if (entry.isEmpty) continue;
      final eq = entry.indexOf('=');
      final host = (eq < 0 ? entry : entry.substring(0, eq))
          .trim()
          .toLowerCase();
      if (!_hostname.hasMatch(host)) {
        report(malformed, 'entry ${index + 1}');
        continue;
      }
      if (!known.contains(host)) {
        report(unknown, host);
        continue;
      }
      if (!seen.add(host)) {
        byHost.remove(host);
        report(malformed, host);
        continue;
      }
      if (eq < 0) {
        report(malformed, host);
        continue;
      }
      final literals = entry.substring(eq + 1).split('/');
      final ip = literals.first.trim();
      final ip6 = literals.length == 2 ? literals.last.trim() : null;
      if (literals.length > 2 ||
          !_isLiteral(ip, InternetAddressType.IPv4) ||
          (ip6 != null && !_isLiteral(ip6, InternetAddressType.IPv6))) {
        report(malformed, host);
        continue;
      }
      byHost[host] = (ip: ip, ip6: ip6);
    }
    return OneVpnFreeNodeIps(
      byHost: Map<String, OneVpnNodeLiterals>.unmodifiable(byHost),
      malformed: List<String>.unmodifiable(malformed),
      unknown: List<String>.unmodifiable(unknown),
    );
  }

  /// The literals, keyed by lowercased hostname. Every key is a parse host.
  final Map<String, OneVpnNodeLiterals> byHost;

  /// The key of each rejected entry, listed once.
  ///
  /// The key is the entry's lowercased hostname. An entry with no syntactic
  /// hostname has the key `entry N`. N counts the comma-separated parts of the
  /// define from 1. No key carries an address.
  final List<String> malformed;

  /// Each lowercased hostname that no parse host matches, listed once. None
  /// of them appears in [malformed].
  final List<String> unknown;

  /// [locations] with the literals set on every server whose host [byHost]
  /// names. The lookup ignores letter case.
  ///
  /// Keeps every other field, the REALITY server name included. A server that
  /// [byHost] does not name comes back unchanged. A teaser keeps its null
  /// server list.
  List<OneVpnApiLocation> applyTo(List<OneVpnApiLocation> locations) =>
      List<OneVpnApiLocation>.unmodifiable(<OneVpnApiLocation>[
        for (final location in locations)
          if (location.servers case final servers?)
            OneVpnApiLocation(
              city: location.city,
              cityCode: location.cityCode,
              country: location.country,
              countryCode: location.countryCode,
              isPremium: location.isPremium,
              servers: List<OneVpnApiServer>.unmodifiable(<OneVpnApiServer>[
                for (final server in servers) _withLiterals(server),
              ]),
            )
          else
            location,
      ]);

  OneVpnApiServer _withLiterals(OneVpnApiServer server) {
    final literals = byHost[server.host.toLowerCase()];
    if (literals == null) return server;
    return OneVpnApiServer(
      host: server.host,
      realityServerName: server.realityServerName,
      ip: literals.ip,
      ip6: literals.ip6,
    );
  }
}

/// A syntactic lowercase hostname. The last label starts with a letter, so an
/// IP literal never matches.
final _hostname = RegExp(
  r'^(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)*[a-z](?:[a-z0-9-]*[a-z0-9])?$',
);

bool _isLiteral(String value, InternetAddressType type) =>
    InternetAddress.tryParse(value)?.type == type;
