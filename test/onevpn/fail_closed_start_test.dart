// A failed start fails closed when the coordinator keeps the tunnel. The
// coordinator keeps a host that reads disconnected after the failure. The
// failed view stands until a disconnect stops the host. The coordinator
// stops a host that is still starting or already connected. A cancel stops
// the host, including a cancel that arrives during the inspect. Failures
// outside the start window stop the host. A failed start after a change
// from connected lands in the same red state. Without the flag, a failed
// start stops the host.

import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/core/db/database/database.dart';
import 'package:onexray/core/pigeon/messages.g.dart';
import 'package:onexray/core/pigeon/model.dart';
import 'package:onexray/onevpn/shell/connect_control.dart';
import 'package:onexray/service/connect/compiler.dart';
import 'package:onexray/service/connect/coordinator.dart';
import 'package:onexray/service/connect/runtime.dart';
import 'package:onexray/service/connect/runtime_host.dart';
import 'package:onexray/service/connect/settings.dart';

/// A scripted native host. A failed start leaves [status] disconnected,
/// the status a held TUN reads, unless the start sets it.
class _Host {
  VpnStatus status;
  ConnectionRuntime? active;
  int starts = 0;
  int stops = 0;
  int inspects = 0;

  /// The next start's outcome. Null connects.
  Future<HostConnection> Function(ConnectionRuntime)? nextStart;

  /// The next stop's outcome. Null disconnects.
  Future<HostConnection> Function()? nextStop;

  /// Runs inside each inspect, before it answers.
  void Function()? onInspect;

  _Host({this.status = VpnStatus.disconnected, this.active});

  Future<HostConnection> inspect(Iterable<ConnectionRuntime> _) async {
    inspects++;
    onInspect?.call();
    return HostConnection(status, runtime: active);
  }

  Future<HostConnection> start(ConnectionRuntime runtime) async {
    starts++;
    final outcome = nextStart;
    if (outcome != null) return outcome(runtime);
    status = VpnStatus.connected;
    active = runtime;
    return HostConnection(status, runtime: runtime);
  }

  Future<HostConnection> stop() async {
    stops++;
    final outcome = nextStop;
    if (outcome != null) {
      nextStop = null;
      return outcome();
    }
    status = VpnStatus.disconnected;
    active = null;
    return HostConnection(status);
  }
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
  });

  Future<ConnectionCoordinator> mount(
    _Host host,
    ConnectionRuntime next, {
    bool keep = true,
  }) async {
    final coordinator = ConnectionCoordinator(
      database: db,
      readRuntime: () async => host.active,
      inspect: host.inspect,
      inspectObserved: (_, observed) async =>
          HostConnection(observed, runtime: host.active),
      prepare: (_, _) async => next,
      start: host.start,
      stop: host.stop,
    )..keepTunnelOnFailedStart = keep;
    addTearDown(coordinator.dispose);
    await coordinator.initialize(observe: false);
    return coordinator;
  }

  Future<HostConnection> failStart(ConnectionRuntime _) async =>
      throw const ConnectionHostException('startFailed');

  bool red(ConnectionCoordinator coordinator) =>
      OneVpnConnectControlState.of(coordinator.state.value) ==
      OneVpnConnectControlState.noConnection;

  test('the flag defaults to the stop on a failed start', () {
    final coordinator = ConnectionCoordinator(
      database: db,
      statusEvents: const Stream.empty(),
      observeStatus: () async {},
      disposeStatus: () {},
    );
    addTearDown(coordinator.dispose);
    expect(coordinator.keepTunnelOnFailedStart, isFalse);
  });

  test(
    'a failed start keeps the tunnel and stands until a disconnect',
    () async {
      final host = _Host()..nextStart = failStart;
      final coordinator = await mount(host, _runtime('b'));
      final inspectsBefore = host.inspects;

      await expectLater(
        coordinator.connect(),
        throwsA(isA<ConnectionHostException>()),
      );

      expect(host.starts, 1);
      expect(host.stops, 0);
      // The connect inspects before apply. The apply inspects before the
      // stop decision. The keep branch inspects after the failure.
      expect(host.inspects, inspectsBefore + 3);
      expect(coordinator.state.value.phase, ConnectionPhase.failed);
      expect(coordinator.state.value.issue, 'startFailed');
      expect(coordinator.state.value.runtime, isNull);
      expect(red(coordinator), isTrue);

      // Reconciliation keeps the failed view. Only the user clears it.
      await coordinator.refresh();
      await coordinator.refresh(observedStatus: VpnStatus.disconnected);
      expect(coordinator.state.value.phase, ConnectionPhase.failed);
      expect(red(coordinator), isTrue);

      await coordinator.disconnect();

      expect(host.stops, 1);
      expect(coordinator.state.value.phase, ConnectionPhase.disconnected);
      expect(coordinator.state.value.issue, isNull);
      expect(red(coordinator), isFalse);

      // A retry is a fresh connect from disconnected.
      host.nextStart = null;
      await coordinator.connect();
      expect(host.starts, 2);
      expect(coordinator.state.value.phase, ConnectionPhase.connected);
    },
  );

  test(
    'a no-start change after a hold clears the view, not the hold',
    () async {
      final host = _Host()..nextStart = failStart;
      final coordinator = await mount(host, _runtime('b'));
      await expectLater(
        coordinator.connect(),
        throwsA(isA<ConnectionHostException>()),
      );

      await coordinator.apply(ConnectionConfiguration());

      // The coordinator publishes the host's disconnected status. The fork
      // held signal carries red from here, and the change helpers release
      // the hold before they apply.
      expect(host.stops, 0);
      expect(coordinator.state.value.phase, ConnectionPhase.disconnected);
    },
  );

  test('an external stop after a hold keeps the failed view', () async {
    final host = _Host()..nextStart = failStart;
    final coordinator = await mount(host, _runtime('b'));
    await expectLater(
      coordinator.connect(),
      throwsA(isA<ConnectionHostException>()),
    );

    // The notification's Disconnect releases the TUN natively.
    await coordinator.refresh(observedStatus: VpnStatus.disconnected);

    // The latch holds the failed view. The fork held signal reads false
    // and renders it grey.
    expect(host.stops, 0);
    expect(coordinator.state.value.phase, ConnectionPhase.failed);
    expect(coordinator.state.value.runtime, isNull);
  });

  test('an unconfirmed start keeps the tunnel', () async {
    final host = _Host()
      ..nextStart = (_) async => const HostConnection(VpnStatus.disconnected);
    final coordinator = await mount(host, _runtime('b'));

    await expectLater(
      coordinator.connect(),
      throwsA(isA<ConnectionHostException>()),
    );

    expect(host.stops, 0);
    expect(coordinator.state.value.issue, 'startNotConfirmed');
    expect(red(coordinator), isTrue);
  });

  for (final late in [VpnStatus.connecting, VpnStatus.connected]) {
    test('a failed start over a ${late.name} host stops it', () async {
      final runtime = _runtime('b');
      final host = _Host();
      // A command timeout or a lost binding: the host keeps starting.
      host.nextStart = (runtime) async {
        host.status = late;
        host.active = runtime;
        throw const ConnectionHostException('startFailed');
      };
      final coordinator = await mount(host, runtime);

      await expectLater(
        coordinator.connect(),
        throwsA(isA<ConnectionHostException>()),
      );

      expect(host.stops, 1);
      expect(host.status, VpnStatus.disconnected);
      expect(coordinator.state.value.phase, ConnectionPhase.failed);
      expect(coordinator.state.value.runtime, isNull);
    });
  }

  test('a cancel during the start still stops the host', () async {
    final started = Completer<void>();
    final release = Completer<HostConnection>();
    final host = _Host();
    host.nextStart = (runtime) {
      started.complete();
      return release.future;
    };
    final coordinator = await mount(host, _runtime('b'));

    final connect = coordinator.connect();
    await started.future;
    coordinator.cancel();
    release.complete(const HostConnection(VpnStatus.connected));

    await expectLater(connect, throwsA(isA<ConnectionHostException>()));
    expect(host.stops, 1);
    expect(coordinator.state.value.issue, 'cancelled');
    expect(red(coordinator), isFalse);
  });

  test('a cancel during the inspect stops the host', () async {
    final host = _Host()..nextStart = failStart;
    final coordinator = await mount(host, _runtime('b'));
    var failed = false;
    host.nextStart = (runtime) async {
      failed = true;
      throw const ConnectionHostException('startFailed');
    };
    // The inspect after the failure is the keep decision's own.
    host.onInspect = () {
      if (failed) coordinator.cancel();
    };

    await expectLater(
      coordinator.connect(),
      throwsA(isA<ConnectionHostException>()),
    );

    expect(host.stops, 1);
    expect(coordinator.state.value.issue, 'cancelled');
    expect(red(coordinator), isFalse);
  });

  test('a failed start after a change from connected lands red', () async {
    final old = _runtime('a');
    final host = _Host(status: VpnStatus.connected, active: old)
      ..nextStart = failStart;
    final coordinator = await mount(host, _runtime('b', entryIds: const [2]));

    await expectLater(
      coordinator.apply(ConnectionConfiguration()),
      throwsA(isA<ConnectionHostException>()),
    );

    // The change's own stop runs. The failed start adds none.
    expect(host.stops, 1);
    expect(coordinator.state.value.phase, ConnectionPhase.failed);
    expect(red(coordinator), isTrue);
  });

  test('an unconfirmed stop on a change stops the host again', () async {
    final old = _runtime('a');
    final host = _Host(status: VpnStatus.connected, active: old)
      ..nextStop = () async =>
          HostConnection(VpnStatus.connected, runtime: old);
    final coordinator = await mount(host, _runtime('b', entryIds: const [2]));

    await expectLater(
      coordinator.apply(ConnectionConfiguration()),
      throwsA(isA<ConnectionHostException>()),
    );

    expect(host.starts, 0);
    expect(host.stops, 2);
    expect(coordinator.state.value.issue, 'stopNotConfirmed');
  });

  test('a failed commit after a confirmed start stops the host', () async {
    final host = _Host();
    final next = _runtime('b');
    final coordinator = await mount(host, next);

    await expectLater(
      coordinator.apply(
        next.configuration,
        connect: true,
        writeAssets: () async => throw const FormatException('disk full'),
      ),
      throwsFormatException,
    );

    expect(host.starts, 1);
    expect(host.stops, 1);
    expect(host.status, VpnStatus.disconnected);
    expect(coordinator.state.value.phase, ConnectionPhase.failed);
  });

  test('without the flag a failed start stops the host', () async {
    final host = _Host()..nextStart = failStart;
    final coordinator = await mount(host, _runtime('b'), keep: false);

    await expectLater(
      coordinator.connect(),
      throwsA(isA<ConnectionHostException>()),
    );

    expect(host.stops, 1);
    expect(coordinator.state.value.phase, ConnectionPhase.failed);
  });
}

ConnectionRuntime _runtime(String digit, {List<int> entryIds = const [1]}) {
  final configuration = ConnectionConfiguration(
    connection: ConnectionSettings(
      selection: entryIds.length == 1
          ? ServerSelection.server(entryIds.single)
          : const ServerSelection.automatic(),
      smart: SmartRoutingSettings(entryCount: entryIds.length),
    ),
  );
  final entries = [
    for (final id in entryIds)
      ResolvedServer(
        id: id,
        sourceId: 7,
        outbound: {'protocol': 'freedom', 'tag': 'server-$id'},
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
      null,
      null,
      '1800$digit',
      jsonEncode(invoke.toJson()),
    ),
  );
}
