// Pins the reload policy's seams. The coordinator seam is pinned whole: a
// throw inside the serial queue publishes the host failure with no stop.
// The policy takes the serial queue, then the geodata file lock. It runs
// the change's prepare, or its own without one. The reload path reaches no
// probe. The policy's own prepare is the native connect's reload prepare.
// The native connect hands the shared resolver a probe that throws, or one
// that only records the scope. The shared resolver probes only through that
// parameter. No handover source and no native connect source names the
// ping service. Each request stages to its own temporary file, which the
// policy renames onto the path the native side claims.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/handover/reload_policy.dart';

import '../support/kotlin_source.dart';

const _coordinatorPath = 'lib/service/connect/coordinator.dart';
const _policyPath = 'lib/onevpn/handover/reload_policy.dart';
const _nativeConnectPath = 'lib/onevpn/connect/native_connect.dart';
const _sharedResolverPath = 'lib/service/connect/resolver.dart';
const _nativePath =
    'android/app/src/main/kotlin/net/yuandev/onexray/onevpn/handover/'
    'OneVpnHandoverService.kt';

/// The coordinator seam, normalized. Any statement added, removed, or
/// reordered changes this string.
const _pinnedRunExclusive =
    'Future<void> runExclusive(Future<void> Function() action) => '
    '_run(() async { try { await action(); } catch (error) { await '
    '_publishHostFailure(connectionFailureReason(error), error: error); '
    'rethrow; } });';

/// The member of the class in [path] that starts with [signaturePrefix]
/// after two spaces of indent. It runs through the first line at that
/// indent that closes it. Comment lines are dropped and whitespace
/// collapses.
String _normalizedMember(String path, String signaturePrefix) {
  final lines = File(path).readAsLinesSync();
  final start = lines.indexWhere(
    (line) => line.startsWith('  $signaturePrefix'),
  );
  expect(start, isNot(-1), reason: '$path lacks $signaturePrefix');
  final body = <String>[];
  for (var index = start; index < lines.length; index++) {
    final line = lines[index];
    if (RegExp(r'^\s*//').hasMatch(line)) continue;
    body.add(line);
    if (index > start && (line == '  }' || line == '  });')) {
      return body.join('\n').replaceAll(RegExp(r'\s+'), ' ').trim();
    }
  }
  fail('$path: $signaturePrefix never closes at its indent');
}

void main() {
  test('the coordinator seam performs exactly the pinned statements', () {
    final seam = _normalizedMember(
      _coordinatorPath,
      'Future<void> runExclusive(',
    );
    expect(seam, contains('_publishHostFailure('));
    expect(seam, _pinnedRunExclusive);
    // The failure path inspects and latches. It never stops the host.
    final publish = _normalizedMember(
      _coordinatorPath,
      'Future<void> _publishHostFailure(',
    );
    expect(publish, contains('await _inspect(await _known())'));
    expect(publish, contains('_failureLatched = true;'));
    expect(publish, isNot(contains('_stop(')));
  });

  test('each change takes the serial queue, then the geodata file lock', () {
    final apply = _normalizedMember(
      _policyPath,
      'Future<OneVpnReloadResult> applyInPlace(',
    );
    expect(
      apply,
      contains(
        'await coordinator.runExclusive( () => _withFiles(() async { '
        'result = await _reload( coordinator, next, expectedConfiguration, '
        'prepare ?? _prepare, );',
      ),
    );
  });

  test('the reload path reaches no probe', () {
    final policy = File(_policyPath).readAsStringSync();
    final native = File(_nativeConnectPath).readAsStringSync();
    expect(RegExp(r'ConnectionPreparation\(').allMatches(policy), isEmpty);
    expect(
      policy.replaceAll(RegExp(r'\s+'), ' '),
      contains('_prepare = prepare ?? _nativePrepare,'),
    );
    expect(
      policy.replaceAll(RegExp(r'\s+'), ' '),
      contains(
        '=> OneVpnNativeConnect.instance.reloadPrepare(coordinator, next, '
        'running);',
      ),
    );
    // The ranked resolver's probe throws. The scope resolver's probe only
    // records the candidates.
    final flat = native.replaceAll(RegExp(r'\s+'), ' ');
    expect(RegExp(r'ConnectionResolver\(').allMatches(native), hasLength(2));
    expect(flat, contains('probe: _neverProbe, ).resolve('));
    expect(
      flat,
      contains(
        "static Future<void> _neverProbe(List<int> _) async => "
        "throw StateError('A pin never probes');",
      ),
    );
    expect(flat, contains('probe: (candidates) async => ids = candidates,'));
    // The shared resolver probes only through its probe parameter.
    final shared = File(_sharedResolverPath).readAsStringSync();
    expect(RegExp(r'PingService\(').allMatches(shared), hasLength(1));
    expect(
      shared.replaceAll(RegExp(r'\s+'), ' '),
      contains('_probe = probe ?? PingService().pingConfigIds;'),
    );
    expect(RegExp(r'\b_probe\(').allMatches(shared), hasLength(1));
    final sources = [
      for (final file in Directory('lib/onevpn/handover').listSync())
        if (file is File && file.path.endsWith('.dart')) file,
      File(_nativeConnectPath),
    ];
    for (final file in sources) {
      final source = file.readAsStringSync();
      for (final name in ['PingService', 'pingConfigIds', 'shared/ping/']) {
        expect(source, isNot(contains(name)), reason: '${file.path}: $name');
      }
    }
  });

  test('each request stages through its own temporary file and a rename', () {
    final source = File(_policyPath).readAsStringSync();
    expect(
      source,
      contains(r"final temporary = File('${target.path}.$requestId.tmp');"),
    );
    expect(source, contains('await temporary.rename(target.path);'));
  });

  test('the staged path is the one the native side claims', () {
    expect(
      kotlinSource(_nativePath),
      contains(
        'private const val STAGED_RELATIVE_PATH = '
        '"run/${OneVpnReloadStage.fileName}"',
      ),
    );
    expect(
      File(_policyPath).readAsStringSync(),
      contains('File(p.join(VpnConstants.runDir, fileName))'),
    );
  });
}
