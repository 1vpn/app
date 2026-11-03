// Structural pin: the account transport owns a bare Dio and never
// reaches for the shared HTTP client of the tree.
//
// `NetClient` is the geodata downloader. It is one process-wide singleton
// with a 60 s receive timeout and a download user agent. The account API
// sends small, latency-sensitive requests before any tunnel exists. The
// transport walks each request across four domains, with a per-attempt
// bound from its own constant. The shared client would hand those requests
// the downloader's timeouts. It would also couple two unrelated network
// surfaces through one mutable singleton.
//
// That coupling fails silently: the calls still succeed, with the wrong
// bounds. This sweep makes it a failing check.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The files that make up the account transport, pinned by path. A new
/// file in the transport layer joins this list by hand.
const _transportFiles = <String>[
  'lib/onevpn/net/failover_domains.dart',
  'lib/onevpn/net/api_transport.dart',
  'lib/onevpn/data/account_api.dart',
  'lib/onevpn/model/user_data.dart',
];

/// Import and export directives in [source], as written.
final _directivePattern = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

Iterable<String> _directiveTargets(String source) =>
    _directivePattern.allMatches(source).map((m) => m.group(1)!);

void main() {
  late Map<String, String> sources;

  setUpAll(() {
    sources = <String, String>{
      for (final path in _transportFiles) path: File(path).readAsStringSync(),
    };
  });

  // Anti-vacuity guard: the sweep reads real files with real directives
  // before any negative below counts.
  test('the sweep reads the transport files it guards', () {
    for (final entry in sources.entries) {
      expect(entry.value.length, greaterThan(500), reason: entry.key);
    }
    expect(
      _directiveTargets(sources['lib/onevpn/net/api_transport.dart']!),
      containsAll(<String>[
        'package:dio/dio.dart',
        'package:shared_preferences/shared_preferences.dart',
        'package:onexray/onevpn/net/failover_domains.dart',
      ]),
    );
    expect(
      _directiveTargets(sources['lib/onevpn/data/account_api.dart']!),
      contains('package:onexray/onevpn/net/api_transport.dart'),
    );
    // The banned target is a real file, so the check below guards a live
    // name.
    expect(File('lib/core/network/client.dart').existsSync(), isTrue);
    expect(
      File('lib/core/network/client.dart').readAsStringSync(),
      contains('class NetClient'),
    );
  });

  test('no transport file imports the shared HTTP client layer', () {
    final violations = <String>[];
    for (final entry in sources.entries) {
      for (final target in _directiveTargets(entry.value)) {
        if (target.contains('core/network/')) {
          violations.add('${entry.key}: $target');
        }
      }
    }

    expect(violations, isEmpty);
  });

  test('no transport file names NetClient at all', () {
    // The ban covers every reference to NetClient, not only the import.
    final violations = <String>[
      for (final entry in sources.entries)
        if (RegExp(r'\bNetClient\b').hasMatch(_uncommented(entry.value)))
          entry.key,
    ];

    expect(violations, isEmpty);
  });
}

/// [source] with `//` comments removed. A comment that explains why the
/// transport skips the shared client never counts as a use of it.
String _uncommented(String source) => source
    .split('\n')
    .map((line) {
      final marker = line.indexOf('//');
      return marker < 0 ? line : line.substring(0, marker);
    })
    .join('\n');
