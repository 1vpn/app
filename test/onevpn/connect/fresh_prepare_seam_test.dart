// The coordinator's fresh-connect seam. A connect from disconnected runs
// the fresh prepare. A fork change that restarts a connected tunnel runs it
// too, never the default. With no fresh prepare set, a connect runs the
// default. The seam is pinned whole, and every fork apply that can start a
// core passes a prepare. An apply that disconnects starts no core. An
// in-place reload runs the prepare its change passes in place of the
// policy's own.

import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/core/db/database/database.dart';
import 'package:onexray/core/model/tun_json.dart';
import 'package:onexray/core/pigeon/messages.g.dart';
import 'package:onexray/core/pigeon/model.dart';
import 'package:onexray/onevpn/app/held_tunnel.dart';
import 'package:onexray/onevpn/handover/handover.g.dart';
import 'package:onexray/onevpn/handover/handover_host.dart';
import 'package:onexray/onevpn/handover/reload_policy.dart';
import 'package:onexray/onevpn/routing/direct_regions_apply.dart';
import 'package:onexray/service/connect/compiler.dart';
import 'package:onexray/service/connect/coordinator.dart';
import 'package:onexray/service/connect/runtime.dart';
import 'package:onexray/service/connect/runtime_host.dart';
import 'package:onexray/service/connect/settings.dart';

import '../support/reload_fakes.dart';

const _coordinatorPath = 'lib/service/connect/coordinator.dart';

/// The connect-from-disconnected path, normalized. Any statement added,
/// removed, or reordered changes this string.
const _pinnedConnectOnce =
    'Future<void> _connectOnce() async { await initialize(); if '
    '(_commandActive) return; final current = await _inspect(await '
    '_known()); if (current.status != VpnStatus.disconnected) { '
    '_publish(current); return; } await apply( await configuration, '
    'connect: true, prepare: freshConnectPrepare, ); }';

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
    if (index > start && line == '  }') {
      return body.join('\n').replaceAll(RegExp(r'\s+'), ' ').trim();
    }
  }
  fail('$path: $signaturePrefix never closes at its indent');
}

/// A scripted native host that starts and stops at once.
class _Host {
  VpnStatus status = VpnStatus.disconnected;
  ConnectionRuntime? active;

  Future<HostConnection> inspect(Iterable<ConnectionRuntime> _) async =>
      HostConnection(status, runtime: active);

  Future<HostConnection> start(ConnectionRuntime runtime) async {
    status = VpnStatus.connected;
    active = runtime;
    return HostConnection(status, runtime: runtime);
  }

  Future<HostConnection> stop() async {
    status = VpnStatus.disconnected;
    active = null;
    return HostConnection(status);
  }
}

void main() {
  late AppDatabase db;
  late _Host host;
  late List<String> prepared;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    host = _Host();
    prepared = [];
  });

  Future<ConnectionCoordinator> mount({bool fresh = true}) async {
    var count = 0;
    final coordinator = ConnectionCoordinator(
      database: db,
      readRuntime: () async => host.active,
      inspect: host.inspect,
      inspectObserved: (_, observed) async =>
          HostConnection(observed, runtime: host.active),
      prepare: (_, _) async {
        prepared.add('default');
        return _runtime('${count++}');
      },
      start: host.start,
      stop: host.stop,
    );
    if (fresh) {
      coordinator.freshConnectPrepare = (_, _) async {
        prepared.add('fresh');
        return _runtime('${count++}');
      };
    }
    addTearDown(coordinator.dispose);
    await coordinator.initialize(observe: false);
    return coordinator;
  }

  test('a connect from disconnected runs the fresh prepare', () async {
    final coordinator = await mount();

    await coordinator.connect();

    expect(prepared, ['fresh']);
    expect(coordinator.state.value.phase, ConnectionPhase.connected);
  });

  test('a fork restart of a connected tunnel runs the fresh prepare, never '
      'the default', () async {
    final coordinator = await mount();
    await coordinator.connect();
    final service = OneVpnDirectRegionsApplyService(
      coordinator: coordinator,
      held: OneVpnHeldTunnel(read: () async => false, supported: false),
      reloadPolicy: OneVpnReloadPolicy(supported: false),
    );

    final outcome = await service.apply(
      regionCode: 'IR',
      confirmReconnect: () async => true,
    );

    expect(outcome, OneVpnDirectRegionsOutcome.applied);
    expect(prepared, ['fresh', 'fresh']);
    expect(coordinator.state.value.phase, ConnectionPhase.connected);
  });

  test('a connect runs the default with no fresh prepare set', () async {
    final coordinator = await mount(fresh: false);

    await coordinator.connect();

    expect(prepared, ['default']);
  });

  test('the connect path passes the fresh prepare, and every fork apply '
      'that can start a core passes a prepare', () {
    final connectOnce = _normalizedMember(
      _coordinatorPath,
      'Future<void> _connectOnce(',
    );
    expect(connectOnce, contains('apply('));
    expect(connectOnce, _pinnedConnectOnce);
    // Each field is its seam's only other mention.
    final source = File(_coordinatorPath).readAsStringSync();
    expect(RegExp(r'\bfreshConnectPrepare\b').allMatches(source), hasLength(2));
    expect(RegExp(r'\bdefaultResolver\b').allMatches(source), hasLength(2));
    // A fork apply commits alone, stops the tunnel, or names the prepare it
    // runs.
    var applies = 0;
    for (final file in Directory('lib/onevpn').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final text = file.readAsStringSync().replaceAll(RegExp(r'\s+'), ' ');
      for (final call in RegExp(
        r'coordinator\.apply\(([^;]*?)\);',
      ).allMatches(text)) {
        applies++;
        final arguments = call.group(1)!;
        expect(
          arguments.contains('affectsRuntime: false') ||
              arguments.contains('disconnect: true') ||
              arguments.contains('prepare: '),
          isTrue,
          reason: '${file.path}: coordinator.apply($arguments)',
        );
      }
    }
    expect(applies, greaterThanOrEqualTo(4));
  });

  test('the in-place reload runs the prepare its change passes', () async {
    final coordinator = await mount();
    await coordinator.connect();
    final reloadHost = FakeReloadHost()
      ..onReload = (_) async => ReloadResult.rolledBack;
    final policy = OneVpnReloadPolicy(
      host: reloadHost,
      events: OneVpnHandoverEvents(),
      supported: true,
      prepare: (_, _, _) async {
        prepared.add('policy');
        return _runtime('8', tun: host.active!.request.tun);
      },
      validate: (_) async => '',
      stage: MemoryReloadStage(),
      withFiles: (action) => action(),
      held: OneVpnHeldTunnel(read: () async => false, supported: true),
    );
    addTearDown(policy.state.dispose);
    final current = (await coordinator.configuration).encode();

    await policy.applyInPlace(
      coordinator,
      await coordinator.configuration,
      expectedConfiguration: current,
      prepare: (_, _, _) async {
        prepared.add('passed');
        return _runtime('9', tun: host.active!.request.tun);
      },
    );
    await policy.applyInPlace(
      coordinator,
      await coordinator.configuration,
      expectedConfiguration: current,
    );

    expect(prepared, ['fresh', 'passed', 'policy']);
    expect(reloadHost.requests, hasLength(2));
  });
}

ConnectionRuntime _runtime(String digit, {TunJson? tun}) {
  final configuration = ConnectionConfiguration(
    connection: ConnectionSettings(selection: const ServerSelection.server(1)),
  );
  final entries = [
    ResolvedServer(
      id: 1,
      sourceId: 7,
      outbound: const {'protocol': 'freedom', 'tag': 'server-1'},
    ),
  ];
  final compiled = CompiledConnection(
    xrayJson: jsonEncode({
      'outbounds': [for (final entry in entries) entry.outbound],
    }),
    entries: entries,
    finalExit: null,
    nodeTags: const {},
  );
  final invoke = LibXrayInvokeRequest(
    method: LibXrayMethod.runXray,
    payload: RunXrayRequest(compiled.xrayJson).toJson(),
  );
  return ConnectionRuntime.create(
    configuration: configuration,
    compiled: compiled,
    platform: ConnectionPlatform.android,
    request: StartVpnRequest(
      tun,
      null,
      '1800$digit',
      jsonEncode(invoke.toJson()),
    ),
  );
}
