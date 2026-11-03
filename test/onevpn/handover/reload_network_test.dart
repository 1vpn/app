// The reload policy and the network reloads the native side runs on its
// own. A network reload leaves the state connected. Its events are dropped.
// A network reload during a settings change leaves the change its state. A
// settings change that finds no core over a held TUN takes the
// double-failure landing. A network reload commits nothing and calls no
// host method. The policy never retries. A double failure lands in the
// hold through the native status alone. The native retry returns the
// tunnel to connected the same way.

import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/core/db/database/database.dart';
import 'package:onexray/core/pigeon/messages.g.dart';
import 'package:onexray/onevpn/app/held_tunnel.dart';
import 'package:onexray/onevpn/handover/handover.g.dart';
import 'package:onexray/onevpn/handover/handover_host.dart';
import 'package:onexray/onevpn/handover/reload_policy.dart';
import 'package:onexray/onevpn/shell/connect_control.dart';
import 'package:onexray/service/connect/coordinator.dart';
import 'package:onexray/service/connect/runtime.dart';
import 'package:onexray/service/connect/runtime_host.dart';
import 'package:onexray/service/connect/settings.dart';

import '../support/reload_fakes.dart';

ReloadEvent _started(String id, {ReloadTrigger? trigger}) => ReloadEvent(
  requestId: id,
  trigger: trigger ?? ReloadTrigger.network,
  phase: ReloadPhase.started,
);

ReloadEvent _finished(
  String id, {
  ReloadResult result = ReloadResult.applied,
  ReloadTrigger? trigger,
}) => ReloadEvent(
  requestId: id,
  trigger: trigger ?? ReloadTrigger.network,
  phase: ReloadPhase.finished,
  result: result,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ConnectionRuntime running;
  late ConnectionRuntime prepared;
  late FakeReloadHost host;
  late OneVpnHandoverEvents events;
  late ConnectionCoordinator coordinator;
  late StreamController<VpnStatus> statuses;
  late List<OneVpnReloadState> states;
  var status = VpnStatus.connected;
  var held = false;
  var stops = 0;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    running = reloadRuntime(
      reloadConfiguration(const ServerSelection.location('1vpn·free·ams')),
      metricsPort: '18001',
    );
    prepared = reloadRuntime(
      reloadConfiguration(const ServerSelection.location('1vpn·free·fra')),
      metricsPort: '18002',
      entryId: 2,
    );
    status = VpnStatus.connected;
    held = false;
    stops = 0;
    host = FakeReloadHost();
    events = OneVpnHandoverEvents();
    addTearDown(events.close);
    statuses = StreamController<VpnStatus>.broadcast();
    addTearDown(statuses.close);
    states = [];
    coordinator = ConnectionCoordinator(
      database: db,
      readRuntime: () async => running,
      inspect: (_) async => HostConnection(
        status,
        runtime: status == VpnStatus.disconnected ? null : running,
      ),
      inspectObserved: (_, observed) async => HostConnection(
        observed,
        runtime: observed == VpnStatus.disconnected ? null : running,
      ),
      stop: () async {
        stops++;
        status = VpnStatus.disconnected;
        return const HostConnection(VpnStatus.disconnected);
      },
      statusEvents: statuses.stream,
      observeStatus: () async {},
      disposeStatus: () {},
    );
    addTearDown(coordinator.dispose);
    await coordinator.initialize();
    await db.connectionConfigDao.commit(
      configurationJson: running.configuration.encode(),
    );
  });

  OneVpnReloadPolicy policy() {
    final value = OneVpnReloadPolicy(
      host: host,
      events: events,
      supported: true,
      prepare: (_, _, _) async => prepared,
      validate: (_) async => '',
      stage: MemoryReloadStage(),
      withFiles: (action) => action(),
      held: OneVpnHeldTunnel(read: () async => held, supported: true),
    );
    value.state.addListener(() => states.add(value.state.value));
    value.attach();
    addTearDown(() => value.state.dispose());
    return value;
  }

  Future<void> send(ReloadEvent event) async {
    await events.reloadEvent(event);
    await pumpEventQueue();
  }

  bool red() =>
      OneVpnConnectControlState.of(coordinator.state.value, held: held) ==
      OneVpnConnectControlState.noConnection;

  test('a network reload leaves the state connected and calls no host '
      'method', () async {
    final reloads = policy();

    await send(_started('network-1-1'));
    expect(reloads.state.value, OneVpnReloadState.connected);
    await send(_finished('network-1-1'));

    expect(states, isEmpty);
    expect(reloads.lastEvent.value, isNull);
    expect(host.supportQueries, 0);
    expect(host.requests, isEmpty);
    expect(stops, 0);
    expect(coordinator.state.value.phase, ConnectionPhase.connected);
    expect(
      (await coordinator.configuration).encode(),
      running.configuration.encode(),
    );
  });

  test('a network reload during a settings change leaves the change its '
      'state', () async {
    final reloads = policy();
    final reply = Completer<ReloadResult>();
    final sent = Completer<void>();
    host.onReload = (_) {
      sent.complete();
      return reply.future;
    };

    final change = reloads.applyInPlace(
      coordinator,
      prepared.configuration,
      expectedConfiguration: (await coordinator.configuration).encode(),
    );
    await sent.future;
    await send(_started('network-1-1'));
    expect(states, [OneVpnReloadState.reloading]);

    running = prepared;
    reply.complete(ReloadResult.applied);
    final result = await change;
    expect(result.outcome, OneVpnReloadOutcome.applied);
    expect(reloads.state.value, OneVpnReloadState.connected);

    await send(_finished('network-1-1'));

    expect(states, [OneVpnReloadState.reloading, OneVpnReloadState.connected]);
  });

  test('a network double failure during a settings change lands the change '
      'red and commits nothing', () async {
    final reloads = policy();
    final reply = Completer<ReloadResult>();
    final sent = Completer<void>();
    host.onReload = (_) {
      sent.complete();
      return reply.future;
    };

    final change = reloads.applyInPlace(
      coordinator,
      prepared.configuration,
      expectedConfiguration: (await coordinator.configuration).encode(),
    );
    await sent.future;
    // The network reload runs first on the native executor and fails twice.
    await send(_started('network-1-1'));
    status = VpnStatus.disconnected;
    held = true;
    statuses.add(VpnStatus.disconnected);
    await send(_finished('network-1-1', result: ReloadResult.failed));
    expect(reloads.state.value, OneVpnReloadState.reloading);

    // The queued settings reload then finds no core.
    reply.complete(ReloadResult.notRunning);
    expect((await change).outcome, OneVpnReloadOutcome.held);

    expect(states, [
      OneVpnReloadState.reloading,
      OneVpnReloadState.failed,
      OneVpnReloadState.connected,
    ]);
    expect(red(), isTrue);
    expect(stops, 0);
    expect(
      (await coordinator.configuration).encode(),
      running.configuration.encode(),
    );

    // The native retry's start clears the red state: nothing latched it.
    status = VpnStatus.connected;
    held = false;
    statuses.add(VpnStatus.connected);
    await pumpEventQueue();
    expect(coordinator.state.value.phase, ConnectionPhase.connected);
    expect(red(), isFalse);
  });

  test('a network double failure lands red through the native status alone, '
      'and the policy never retries', () async {
    final reloads = policy();
    final views = <ConnectionView>[];
    coordinator.state.addListener(() => views.add(coordinator.state.value));

    await send(_started('network-1-1'));
    // The service's failStart holds the TUN, and the not-running status
    // arrives before the finished event.
    status = VpnStatus.disconnected;
    held = true;
    statuses.add(VpnStatus.disconnected);
    await pumpEventQueue();
    await send(_finished('network-1-1', result: ReloadResult.failed));

    expect(reloads.state.value, OneVpnReloadState.connected);
    expect(red(), isTrue);
    expect(
      OneVpnConnectControlState.failureLine(
        coordinator.state.value,
        held: held,
      ),
      isTrue,
    );
    expect(coordinator.state.value.phase, ConnectionPhase.disconnected);
    expect(
      views.where((view) => view.phase == ConnectionPhase.failed),
      isEmpty,
    );

    // The next network change starts the service over the held TUN.
    status = VpnStatus.connected;
    held = false;
    statuses.add(VpnStatus.connected);
    await pumpEventQueue();

    expect(coordinator.state.value.phase, ConnectionPhase.connected);
    expect(coordinator.state.value.runtime?.identity, running.identity);
    expect(red(), isFalse);
    expect(reloads.state.value, OneVpnReloadState.connected);
    // The policy never retries: no host call, no stop, no commit.
    expect(host.supportQueries, 0);
    expect(host.requests, isEmpty);
    expect(stops, 0);
    expect(
      (await coordinator.configuration).encode(),
      running.configuration.encode(),
    );
  });
}
