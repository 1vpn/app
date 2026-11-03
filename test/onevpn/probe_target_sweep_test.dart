// Pins the liveness probe surface. Probes target the fork's /ping/
// endpoints only. lib/onevpn/net/probe_endpoints.dart derives them from
// the shared domain list in lib/onevpn/net/failover_domains.dart. The
// account transport walks the same list, so the list lives in one place.
// The ping service runs headless, and no page offers a target. The sweep
// fails when a third-party probe target, the removed target picker, or a
// hardcoded target returns through an upstream merge. The sweep reads
// every file the two app entries reach.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/net/probe_endpoints.dart';

import 'support/lib_closure.dart';

/// Source strings only the removed probe surfaces contain. `PingUrl` is the
/// picker's enum. Any reference to it revives the picker surface.
const _banned = ['cp.cloudflare.com', 'generate_204', 'PingUrl'];

void main() {
  final sources = libClosureSources();

  test('the sweep sees the tree it guards', () {
    // A floor and known files guard against a silently empty walk. The
    // positive match proves that reads return file content.
    expect(sources.length, greaterThan(100));
    final paths = sources.map((file) => file.path).toSet();
    expect(paths, contains('lib/service/shared/ping/state.dart'));
    expect(paths, contains('lib/onevpn/net/probe_endpoints.dart'));
    expect(paths, contains('lib/onevpn/net/failover_domains.dart'));
    expect(
      File('lib/onevpn/net/failover_domains.dart').readAsStringSync(),
      contains('1vpn.org'),
    );
    // The URLs are derived. The pin checks what the derivation produces,
    // not the text of the file that builds it.
    expect(ProbeEndpoints.urls.first, 'https://1vpn.org/ping/');
  });

  test('no third-party probe target or picker reference in lib', () {
    final violations = <String>[];
    for (final file in sources) {
      final source = file.readAsStringSync();
      for (final banned in _banned) {
        if (source.contains(banned)) {
          violations.add('${file.path}: $banned');
        }
      }
    }
    expect(violations, isEmpty);
  });

  test('the headless ping state reads its target from the URL list only', () {
    final source = File('lib/service/shared/ping/state.dart')
        .readAsStringSync();
    // The probe URL resolves from the list. The state carries no URL
    // literal, no stored target, and no picker surface.
    expect(source, contains('ProbeEndpoints.resolve()'));
    expect(source, isNot(contains('http')));
    expect(
      Directory('lib/pages/advanced').existsSync(),
      isFalse,
      reason: 'lib/pages/advanced returned a probe target surface',
    );
  });
}
