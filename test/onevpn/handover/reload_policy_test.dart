// The reload policy over a fake native side. A connected change reloads in
// place. For each change, the policy asks for support and prepares while
// the old core runs. It then checks the TUN, validates, restages, and
// reloads under a unique id. The reload's own answer decides the outcome.
// Before the commit, the policy confirms an applied reload by the identity
// of the staged bytes the native side promotes. A rollback, a validation
// rejection, and a preparation failure leave the previous core and commit
// nothing. A double failure stays red from the native status through the
// finished event and the reply. The coordinator publishes nothing before
// the reply. An applied reload publishes in the background too. Every other error stays out of the serial queue's failure
// path. A timeout reads the runtime identity. The policy returns to
// connected once each outcome is answered. The policy drops events of any
// reload other than the one in flight. A disconnect tapped during a reload
// runs after it. With no prepare of its own, the policy runs the reload
// prepare of the native connect installed at the call.

import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/core/db/dao/connection_config.dart';
import 'package:onexray/core/db/database/database.dart';
import 'package:onexray/core/pigeon/messages.g.dart';
import 'package:onexray/onevpn/app/held_tunnel.dart';
import 'package:onexray/onevpn/connect/native_auto_contracts.dart';
import 'package:onexray/onevpn/connect/native_connect.dart';
import 'package:onexray/onevpn/handover/handover.g.dart';
import 'package:onexray/onevpn/handover/handover_host.dart';
import 'package:onexray/onevpn/handover/reload_policy.dart';
import 'package:onexray/onevpn/shell/connect_control.dart';
import 'package:onexray/service/connect/coordinator.dart';
import 'package:onexray/service/connect/runtime.dart';
import 'package:onexray/service/connect/runtime_host.dart';
import 'package:onexray/service/connect/settings.dart';

import '../support/reload_fakes.dart';

/// The native side the coordinator and the policy talk to. [start] is the
/// runtime `start.json` names. [held] is the answer of the held signal.
class _Native {
  _Native(this.start);

  ConnectionRuntime? start;
  VpnStatus status = VpnStatus.connected;
  bool held = false;
  int stops = 0;
  final statuses = StreamController<VpnStatus>.broadcast();

  /// Each command in the order the native side saw it.
  final calls = <String>[];

  /// Thrown by the next start.json read when set.
  Object? readError;

  Future<ConnectionRuntime?> readRuntime() async {
    final error = readError;
    if (error != null) {
      readError = null;
      throw error;
    }
    return start;
  }

  Future<HostConnection> inspect(Iterable<ConnectionRuntime> _) async =>
      HostConnection(
        status,
        runtime: status == VpnStatus.disconnected ? null : start,
      );

  Future<HostConnection> stop() async {
    stops++;
    calls.add('stop');
    status = VpnStatus.disconnected;
    held = false;
    start = null;
    return const HostConnection(VpnStatus.disconnected);
  }

  /// The service's failStart over a double failure: the TUN is held with
  /// no core, and the not-running status goes out.
  void holdAfterDoubleFailure() {
    status = VpnStatus.disconnected;
    held = true;
    statuses.add(VpnStatus.disconnected);
  }
}

/// An observatory that never reports.
class _Silent implements OneVpnObservatorySource {
  @override
  Future<OneVpnObservationSet> read(int port) async =>
      OneVpnObservationSet(byTag: const {}, readAt: DateTime(2026));
}

/// A database whose configuration commit throws while [failCommit] is set.
class _Db extends AppDatabase {
  _Db() : super.forTesting(NativeDatabase.memory());

  bool failCommit = false;
  late final _failing = _FailingDao(this);

  @override
  ConnectionConfigDao get connectionConfigDao =>
      failCommit ? _failing : super.connectionConfigDao;
}

class _FailingDao extends ConnectionConfigDao {
  _FailingDao(super.db);

  @override
  Future<void> commit({
    required String configurationJson,
    Future<void> Function()? writeAssets,
  }) async => throw StateError('disk full');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Db db;
  late Directory runDirectory;
  late _Native native;
  late FakeReloadHost host;
  late OneVpnHandoverEvents events;
  late ConnectionCoordinator coordinator;
  late ConnectionRuntime running;
  late ConnectionRuntime prepared;
  late File staged;
  late List<OneVpnReloadState> states;
  late List<String> validated;
  late int prepares;
  Object? prepareError;
  String rejection = '';

  setUp(() async {
    db = _Db();
    addTearDown(db.close);
    runDirectory = await Directory.systemTemp.createTemp('onevpn-reload-');
    addTearDown(() => runDirectory.delete(recursive: true));
    staged = File('${runDirectory.path}/${OneVpnReloadStage.fileName}');
    running = reloadRuntime(
      reloadConfiguration(const ServerSelection.location('1vpn·free·ams')),
      metricsPort: '18001',
      entryId: 1,
    );
    prepared = reloadRuntime(
      reloadConfiguration(const ServerSelection.location('1vpn·free·fra')),
      metricsPort: '18002',
      entryId: 2,
    );
    native = _Native(running);
    host = FakeReloadHost();
    events = OneVpnHandoverEvents();
    addTearDown(events.close);
    states = [];
    validated = [];
    prepares = 0;
    prepareError = null;
    rejection = '';
    coordinator = ConnectionCoordinator(
      database: db,
      readRuntime: native.readRuntime,
      inspect: native.inspect,
      inspectObserved: (_, observed) async => HostConnection(
        observed,
        runtime: observed == VpnStatus.disconnected ? null : native.start,
      ),
      stop: native.stop,
      statusEvents: native.statuses.stream,
      observeStatus: () async {},
      disposeStatus: () {},
    );
    addTearDown(coordinator.dispose);
    await coordinator.initialize();
    await db.connectionConfigDao.commit(
      configurationJson: running.configuration.encode(),
    );
  });

  /// A policy over the fake native side. With [nativePrepare], it takes no
  /// prepare of its own.
  OneVpnReloadPolicy policy({
    bool supported = true,
    bool nativePrepare = false,
  }) {
    final value = OneVpnReloadPolicy(
      host: host,
      events: events,
      supported: supported,
      prepare: nativePrepare
          ? null
          : (_, next, current) async {
              prepares++;
              expect(current.identity, running.identity);
              final error = prepareError;
              if (error != null) throw error;
              return prepared;
            },
      validate: (xrayJson) async {
        validated.add(xrayJson);
        return rejection;
      },
      stage: OneVpnReloadStage(file: staged),
      withFiles: (action) => action(),
      held: OneVpnHeldTunnel(read: () async => native.held, supported: true),
    );
    value.state.addListener(() => states.add(value.state.value));
    value.attach();
    addTearDown(() => value.state.dispose());
    return value;
  }

  Future<OneVpnReloadResult> apply(OneVpnReloadPolicy policy) async =>
      policy.applyInPlace(
        coordinator,
        prepared.configuration,
        expectedConfiguration: (await coordinator.configuration).encode(),
      );

  /// The native side promotes the staged bytes over start.json.
  ReloadResult promote(ReloadResult answer) {
    native.start = promotedRuntime(staged);
    return answer;
  }

  Future<String> stored() async => (await coordinator.configuration).encode();

  /// Every file the run directory holds.
  List<String> runFiles() => [
    for (final entity in runDirectory.listSync()) entity.uri.pathSegments.last,
  ];

  group('an applied reload', () {
    test('confirms the identity of the promoted bytes, commits, and '
        'publishes the new runtime', () async {
      final reloads = policy();
      List<String>? filesAtReload;
      host.onReload = (id) async {
        filesAtReload = runFiles();
        return promote(ReloadResult.applied);
      };

      final result = await apply(reloads);

      expect(result.outcome, OneVpnReloadOutcome.applied);
      expect(native.start!.identity, prepared.identity);
      expect(states, [
        OneVpnReloadState.reloading,
        OneVpnReloadState.connected,
      ]);
      expect(host.supportQueries, 1);
      expect(validated, [prepared.xrayJson]);
      // The temporary file was renamed away before the reload ran.
      expect(filesAtReload, [OneVpnReloadStage.fileName]);
      expect(runFiles(), isEmpty);
      expect(await stored(), prepared.configuration.encode());
      expect(coordinator.state.value.phase, ConnectionPhase.connected);
      expect(coordinator.state.value.runtime?.identity, prepared.identity);
      expect(native.stops, 0);
    });

    test('publishes the new runtime while the app is in the background, '
        'and a rollback there publishes nothing', () async {
      final reloads = policy();
      coordinator.didChangeAppLifecycleState(AppLifecycleState.paused);
      host.onReload = (_) async => ReloadResult.rolledBack;

      expect((await apply(reloads)).outcome, OneVpnReloadOutcome.rolledBack);
      expect(coordinator.state.value.runtime?.identity, running.identity);

      host.onReload = (_) async => promote(ReloadResult.applied);

      expect((await apply(reloads)).outcome, OneVpnReloadOutcome.applied);
      expect(coordinator.state.value.phase, ConnectionPhase.connected);
      expect(coordinator.state.value.runtime?.identity, prepared.identity);
    });

    test('carries the notice of the prepared runtime', () async {
      prepared = reloadRuntime(
        reloadConfiguration(const ServerSelection.automatic()),
        metricsPort: '18002',
        entryId: 2,
        notice: 'selectionReset',
      );
      final reloads = policy();
      host.onReload = (_) async => promote(ReloadResult.applied);

      final result = await apply(reloads);

      expect(result, (
        outcome: OneVpnReloadOutcome.applied,
        notice: 'selectionReset',
      ));
    });

    test(
      'a different identity counts as a rollback and commits nothing',
      () async {
        final reloads = policy();
        final before = await stored();
        host.onReload = (_) async => ReloadResult.applied;

        final result = await apply(reloads);

        expect(result.outcome, OneVpnReloadOutcome.rolledBack);
        expect(states, [
          OneVpnReloadState.reloading,
          OneVpnReloadState.rolledBack,
          OneVpnReloadState.connected,
        ]);
        expect(await stored(), before);
      },
    );

    test('a commit that throws stays out of the failure path and takes the '
        'reconnect path', () async {
      final reloads = policy();
      final views = <ConnectionView>[];
      coordinator.state.addListener(() => views.add(coordinator.state.value));
      host.onReload = (_) async {
        db.failCommit = true;
        return promote(ReloadResult.applied);
      };

      final result = await apply(reloads);
      db.failCommit = false;

      expect(result.outcome, OneVpnReloadOutcome.needsReconnect);
      expect(coordinator.state.value.phase, ConnectionPhase.connected);
      expect(
        views.where((view) => view.phase == ConnectionPhase.failed),
        isEmpty,
      );
      expect(await stored(), running.configuration.encode());
      expect(native.stops, 0);
    });

    test('a confirm read that throws takes the reconnect path', () async {
      final reloads = policy();
      host.onReload = (_) async {
        native.readError = StateError('unreadable');
        return promote(ReloadResult.applied);
      };

      final result = await apply(reloads);

      expect(result.outcome, OneVpnReloadOutcome.needsReconnect);
      expect(coordinator.state.value.phase, ConnectionPhase.connected);
    });
  });

  group('a change that did not apply', () {
    test('a native rollback keeps the previous identity', () async {
      final reloads = policy();
      final before = await stored();
      host.onReload = (_) async => ReloadResult.rolledBack;

      final result = await apply(reloads);

      expect(result.outcome, OneVpnReloadOutcome.rolledBack);
      expect(states, [
        OneVpnReloadState.reloading,
        OneVpnReloadState.rolledBack,
        OneVpnReloadState.connected,
      ]);
      expect(await stored(), before);
      expect(coordinator.state.value.phase, ConnectionPhase.connected);
      expect(coordinator.state.value.runtime?.identity, running.identity);
    });

    test('a testXray rejection never reloads', () async {
      rejection = 'invalid config';
      final reloads = policy();

      final result = await apply(reloads);

      expect(result.outcome, OneVpnReloadOutcome.rolledBack);
      expect(host.requests, isEmpty);
      expect(runFiles(), isEmpty);
      expect(states.last, OneVpnReloadState.connected);
    });

    test('a preparation failure never reloads', () async {
      prepareError = const FormatException('no rows');
      final reloads = policy();

      final result = await apply(reloads);

      expect(result.outcome, OneVpnReloadOutcome.rolledBack);
      expect(validated, isEmpty);
      expect(host.requests, isEmpty);
      expect(coordinator.state.value.phase, ConnectionPhase.connected);
    });

    test('a start.json read that throws before the reload answers '
        'rolledBack', () async {
      final reloads = policy();
      native.readError = StateError('unreadable');

      final result = await apply(reloads);

      expect(result.outcome, OneVpnReloadOutcome.rolledBack);
      expect(prepares, 0);
      expect(coordinator.state.value.phase, ConnectionPhase.connected);
    });

    test('a stored configuration that changed never prepares', () async {
      final reloads = policy();

      final result = await reloads.applyInPlace(
        coordinator,
        prepared.configuration,
        expectedConfiguration: 'stale',
      );

      expect(result.outcome, OneVpnReloadOutcome.rolledBack);
      expect(prepares, 0);
    });
  });

  test('a double failure stays red from the status through the reply, and '
      'the coordinator publishes nothing before the reply', () async {
    final reloads = policy();
    final views = <ConnectionView>[];
    coordinator.state.addListener(() => views.add(coordinator.state.value));
    bool red() =>
        OneVpnConnectControlState.of(
          coordinator.state.value,
          held: native.held,
        ) ==
        OneVpnConnectControlState.noConnection;
    final scenario = <String>[];
    host.onReload = (id) async {
      native.holdAfterDoubleFailure();
      await pumpEventQueue();
      scenario.add('status');
      expect(red(), isTrue);
      expect(views, isEmpty);
      await events.reloadEvent(
        ReloadEvent(
          requestId: id,
          trigger: ReloadTrigger.settings,
          phase: ReloadPhase.finished,
          result: ReloadResult.failed,
        ),
      );
      await pumpEventQueue();
      scenario.add('finished');
      expect(reloads.lastEvent.value?.result, ReloadResult.failed);
      expect(red(), isTrue);
      expect(views, isEmpty);
      scenario.add('reply');
      return ReloadResult.failed;
    };

    await expectLater(
      apply(reloads),
      throwsA(
        isA<ConnectionHostException>().having(
          (error) => error.reason,
          'reason',
          'startFailed',
        ),
      ),
    );
    await pumpEventQueue();

    expect(scenario, ['status', 'finished', 'reply']);
    expect(red(), isTrue);
    // The red state holds before the held answer arrives, too.
    expect(
      OneVpnConnectControlState.failureLine(coordinator.state.value),
      isTrue,
    );
    expect(coordinator.state.value.phase, ConnectionPhase.failed);
    expect(coordinator.state.value.issue, 'startFailed');
    expect(coordinator.state.value.runtime, isNull);
    // Every view after the reply reads the latched failure.
    expect(views, isNotEmpty);
    expect(views.map((view) => (view.phase, view.issue)).toSet(), {
      (ConnectionPhase.failed, 'startFailed'),
    });
    expect(native.stops, 0);
    expect(states, [
      OneVpnReloadState.reloading,
      OneVpnReloadState.failed,
      OneVpnReloadState.connected,
    ]);
    expect(await stored(), running.configuration.encode());
  });

  group('a timeout', () {
    test('with the new identity counts as applied late', () async {
      final reloads = policy();
      host.onReload = (_) async => promote(ReloadResult.timeout);

      final result = await apply(reloads);

      expect(result.outcome, OneVpnReloadOutcome.applied);
      expect(await stored(), prepared.configuration.encode());
    });

    test('with the previous identity takes the reconnect path and drops the '
        'late finished event', () async {
      final reloads = policy();
      final before = await stored();
      late String timedOut;
      host.onReload = (id) async {
        timedOut = id;
        await events.reloadEvent(
          ReloadEvent(
            requestId: id,
            trigger: ReloadTrigger.settings,
            phase: ReloadPhase.started,
          ),
        );
        await pumpEventQueue();
        return ReloadResult.timeout;
      };

      final result = await apply(reloads);
      final lastBefore = reloads.lastEvent.value;
      await events.reloadEvent(
        ReloadEvent(
          requestId: timedOut,
          trigger: ReloadTrigger.settings,
          phase: ReloadPhase.finished,
          result: ReloadResult.applied,
        ),
      );
      await pumpEventQueue();

      expect(result.outcome, OneVpnReloadOutcome.needsReconnect);
      expect(lastBefore?.phase, ReloadPhase.started);
      expect(reloads.lastEvent.value, same(lastBefore));
      expect(states.last, OneVpnReloadState.connected);
      expect(await stored(), before);
      expect(runFiles(), isEmpty);
    });
  });

  for (final (answer, outcome) in [
    (ReloadResult.invalidRequest, OneVpnReloadOutcome.needsReconnect),
    (ReloadResult.notSupported, OneVpnReloadOutcome.needsReconnect),
    (ReloadResult.notRunning, OneVpnReloadOutcome.notRunning),
  ]) {
    test('a native ${answer.name} answers ${outcome.name}', () async {
      final reloads = policy();
      host.onReload = (_) async => answer;

      final result = await apply(reloads);

      expect(result.outcome, outcome);
      expect(states.last, OneVpnReloadState.connected);
      expect(await stored(), running.configuration.encode());
      // An early answer leaves the staged request. The policy clears it.
      expect(runFiles(), isEmpty);
    });
  }

  group('no core over a held TUN', () {
    Future<void> expectRedLanding(
      OneVpnReloadPolicy reloads, {
      required List<OneVpnReloadState> expectedStates,
    }) async {
      final before = await stored();
      final result = await apply(reloads);
      expect(result.outcome, OneVpnReloadOutcome.held);
      // No failure crosses the serial queue: the held signal renders red,
      // so a later connected status clears it.
      expect(coordinator.state.value.phase, isNot(ConnectionPhase.failed));
      expect(
        OneVpnConnectControlState.failureLine(
          coordinator.state.value,
          held: native.held,
        ),
        isTrue,
      );
      expect(
        OneVpnConnectControlState.of(
          coordinator.state.value,
          held: native.held,
        ),
        OneVpnConnectControlState.noConnection,
      );
      expect(native.stops, 0);
      expect(await stored(), before);
      expect(states, expectedStates);
    }

    test('a notRunning answer answers held, lands red, and commits '
        'nothing', () async {
      final reloads = policy();
      host.onReload = (_) async {
        // A network reload failed twice while this change ran.
        native.holdAfterDoubleFailure();
        await pumpEventQueue();
        return ReloadResult.notRunning;
      };

      await expectRedLanding(
        reloads,
        expectedStates: [
          OneVpnReloadState.reloading,
          OneVpnReloadState.failed,
          OneVpnReloadState.connected,
        ],
      );
      expect(runFiles(), isEmpty);
    });

    test('no support answers held before preparing', () async {
      native.holdAfterDoubleFailure();
      await pumpEventQueue();
      host.supported = false;
      final reloads = policy();

      await expectRedLanding(
        reloads,
        expectedStates: [OneVpnReloadState.failed, OneVpnReloadState.connected],
      );
      expect(prepares, 0);
      expect(host.requests, isEmpty);
    });
  });

  test('a superseded reload commits nothing', () async {
    final reloads = policy();
    host.onReload = (_) async => ReloadResult.superseded;

    final result = await apply(reloads);

    expect(result.outcome, OneVpnReloadOutcome.superseded);
    expect(await stored(), running.configuration.encode());
  });

  test('a TUN change takes the reconnect path before any reload', () async {
    prepared = reloadRuntime(
      reloadConfiguration(const ServerSelection.location('1vpn·free·fra')),
      metricsPort: '18002',
      entryId: 2,
      ipv6: true,
    );
    final reloads = policy();

    final result = await apply(reloads);

    expect(result.outcome, OneVpnReloadOutcome.needsReconnect);
    expect(validated, isEmpty);
    expect(host.requests, isEmpty);
    expect(states, [OneVpnReloadState.reloading, OneVpnReloadState.connected]);
  });

  test('no native support answers notRunning before preparing', () async {
    host.supported = false;
    final reloads = policy();

    final result = await apply(reloads);

    expect(result.outcome, OneVpnReloadOutcome.notRunning);
    expect(prepares, 0);
    expect(states, isNot(contains(OneVpnReloadState.reloading)));
  });

  test('an unsupported platform never asks the native side', () async {
    final reloads = policy(supported: false);

    final result = await apply(reloads);

    expect(result.outcome, OneVpnReloadOutcome.needsReconnect);
    expect(host.supportQueries, 0);
    expect(prepares, 0);
  });

  test('support is asked per change and the staged request is rewritten '
      'for every request', () async {
    final reloads = policy();
    final stagedPorts = <String?>[];
    var answers = [ReloadResult.notRunning, ReloadResult.rolledBack];
    host.onReload = (_) async {
      stagedPorts.add(promotedRuntime(staged).request.metricsPort);
      final answer = answers.first;
      answers = answers.skip(1).toList();
      return answer;
    };

    await apply(reloads);
    prepared = reloadRuntime(
      reloadConfiguration(const ServerSelection.location('1vpn·free·fra')),
      metricsPort: '18003',
      entryId: 3,
    );
    await apply(reloads);

    expect(host.supportQueries, 2);
    expect(stagedPorts, ['18002', '18003']);
    expect(host.requests, hasLength(2));
    expect(host.requests.toSet(), hasLength(2));
    for (final id in host.requests) {
      expect(id, startsWith('settings-'));
    }
  });

  test('events of another reload are dropped', () async {
    final reloads = policy();
    host.onReload = (id) async {
      await events.reloadEvent(
        ReloadEvent(
          requestId: 'settings-old',
          trigger: ReloadTrigger.settings,
          phase: ReloadPhase.finished,
          result: ReloadResult.failed,
        ),
      );
      await events.reloadEvent(
        ReloadEvent(trigger: ReloadTrigger.network, phase: ReloadPhase.started),
      );
      await pumpEventQueue();
      expect(reloads.lastEvent.value, isNull);
      await events.reloadEvent(
        ReloadEvent(
          requestId: id,
          trigger: ReloadTrigger.settings,
          phase: ReloadPhase.finished,
          result: ReloadResult.applied,
        ),
      );
      await pumpEventQueue();
      return promote(ReloadResult.applied);
    };

    final result = await apply(reloads);

    expect(result.outcome, OneVpnReloadOutcome.applied);
    expect(reloads.lastEvent.value?.result, ReloadResult.applied);
    expect(states.last, OneVpnReloadState.connected);
  });

  test('a disconnect tapped during a reload runs after it', () async {
    final reloads = policy();
    final reply = Completer<ReloadResult>();
    final sent = Completer<void>();
    host.onReload = (_) {
      native.calls.add('reload');
      sent.complete();
      return reply.future;
    };

    final change = apply(reloads);
    // The policy sends the reload only after the staged request is renamed
    // into place. The reload is then in flight, and the staged file exists.
    await sent.future;
    final disconnect = coordinator.disconnect();
    await pumpEventQueue();
    expect(native.stops, 0);

    reply.complete(promote(ReloadResult.applied));
    await change;
    await disconnect;

    expect(native.calls, ['reload', 'stop']);
    expect(coordinator.state.value.phase, ConnectionPhase.disconnected);
    expect(await stored(), prepared.configuration.encode());
  });

  group('the default preparation', () {
    /// Installs a native connect over [reloads]. Its preparation counts
    /// each call in [prepares] and answers [prepared]. The install outlasts
    /// the test. Every other test in this file passes its own prepare.
    OneVpnNativeConnect install(OneVpnReloadPolicy reloads) {
      final connect = OneVpnNativeConnect(
        coordinator: coordinator,
        reloads: reloads,
        observatory: _Silent(),
        measureConfig: ({
          required pinned,
          required candidates,
          required probeUrl,
        }) => throw StateError('no candidate is in scope'),
        supported: true,
        rows: () => Stream.value(const []),
        preparation: (_, _, {cancelled, onResolved}) async {
          prepares++;
          return prepared;
        },
      );
      OneVpnNativeConnect.install(connect);
      return connect;
    }

    test('runs the native connect installed at the call, which measures a '
        'new selection', () async {
      final reloads = policy(nativePrepare: true);
      final connect = install(reloads);
      host.onReload = (_) async => promote(ReloadResult.applied);

      final result = await apply(reloads);

      expect(result.outcome, OneVpnReloadOutcome.applied);
      expect(prepares, 1);
      expect(connect.measuring.value, isTrue);
    });

    test('keeps an unchanged selection off the measure', () async {
      final reloads = policy(nativePrepare: true);
      final connect = install(reloads);
      host.onReload = (_) async => promote(ReloadResult.applied);
      final region = ConnectionConfiguration(
        connection: ConnectionSettings.fromJson({
          ...running.configuration.connection.toJson(),
          'trafficMode': 'smart',
        }),
      );

      final result = await reloads.applyInPlace(
        coordinator,
        region,
        expectedConfiguration: await stored(),
      );

      expect(result.outcome, OneVpnReloadOutcome.applied);
      expect(prepares, 1);
      expect(connect.measuring.value, isFalse);
    });
  });
}
