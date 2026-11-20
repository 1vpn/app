// Pins the launch refresh. A connected pinned tunnel whose request differs
// from the one the app compiles now for the same stored choices is brought
// up to date once, with no dialog. A difference in the core config alone
// reloads in place. A difference in the TUN settings, or a reload that asks
// for a reconnect, takes one reconnect through the coordinator's apply. The
// reconnect starts the pinned runtime the refresh prepared on the running
// entries. It never runs the fresh-connect prepare, which starts a measure
// core. An equal request, with any metrics port, does nothing, and so does
// a second launch after a refresh. A second run in one launch skips. No
// tunnel, a tunnel that connects or failed, a measure or held core, a held
// TUN, a change in flight, a store that names another selection, mode or
// region, and a prepare that fails or falls back to Automatic change
// nothing. The stored configuration is the one committed, so the selection
// and the regions stay as stored. The region switch correction rides on the
// refresh. A reload that does not apply leaves the tunnel, never throws, and
// the next launch tries again. A start that fails after the stop lands red
// and never throws. A tunnel that stops before the reconnect, and a store
// that changes before it, start nothing.
//
// The real compile of one configuration equals itself across prepares
// with different ports, and differs when a region switch differs.

import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/core/db/database/database.dart';
import 'package:onexray/core/pigeon/messages.g.dart';
import 'package:onexray/core/pigeon/model.dart';
import 'package:onexray/onevpn/app/held_tunnel.dart';
import 'package:onexray/onevpn/connect/native_connect.dart';
import 'package:onexray/onevpn/handover/handover.g.dart';
import 'package:onexray/onevpn/handover/reload_policy.dart';
import 'package:onexray/onevpn/net/dns_resolver.dart';
import 'package:onexray/onevpn/reload/launch_refresh.dart';
import 'package:onexray/onevpn/routing/direct_regions_apply.dart';
import 'package:onexray/service/connect/compiler.dart';
import 'package:onexray/service/connect/coordinator.dart';
import 'package:onexray/service/connect/runtime.dart';
import 'package:onexray/service/connect/runtime_host.dart';
import 'package:onexray/service/connect/settings.dart';

import '../support/compiler_fixtures.dart';
import '../support/reload_fakes.dart';

/// The TUN resolver the app hands now, and the one an older request hands.
/// TEST-NET values.
const _tunNow = '192.0.2.2';
const _tunOld = '192.0.2.9';

/// The request the fake compile writes for [configuration]. Its connection
/// settings stand in for the routing, [dns] for the resolver block, and the
/// metrics listener carries [port].
ConnectionRuntime _compile(
  ConnectionConfiguration configuration, {
  required String port,
  String tun = _tunNow,
  String dns = 'current',
  bool measure = false,
  int entryId = 1,
}) => reloadRuntime(
  configuration,
  metricsPort: port,
  tunDnsIPv4: tun,
  measure: measure,
  entryId: entryId,
  core: {
    'routing': configuration.connection.toJson(),
    'dns': dns,
    'metrics': {'listen': '127.0.0.1:$port'},
  },
);

ConnectionConfiguration _region(
  String code, {
  bool switches = false,
  ServerSelection selection = const ServerSelection.location('fr-par'),
}) => ConnectionConfiguration(
  connection: ConnectionSettings(
    selection: selection,
    trafficMode: TrafficMode.smart,
    smart: SmartRoutingSettings(
      directRegions: [code],
      directApple: switches,
      directWindows: switches,
    ),
  ),
);

/// A real compile of [settings] on one node, with the metrics port [port],
/// as preparation writes it on Android.
ConnectionRuntime _real(ConnectionSettings settings, int port) {
  final configuration = ConnectionConfiguration(connection: settings);
  final compiled = ConnectionCompiler.compile(
    settings: settings,
    entries: [compilerNode(1)],
    regions: compilerCatalog,
    options: RuntimeOptions(
      platform: ConnectionPlatform.android,
      sessionDirectory: '/unused-session',
      metricsPort: port,
      socksPort: port + 1,
      tunDnsIpv4Address: tunnelDnsIpv4Address,
      tunDnsIpv6Address: tunnelDnsIpv6Address,
    ),
  );
  return ConnectionRuntime.create(
    configuration: configuration,
    compiled: compiled,
    platform: ConnectionPlatform.android,
    request: StartVpnRequest(
      configuration.policy.toTun(ConnectionPlatform.android),
      null,
      '$port',
      jsonEncode(
        LibXrayInvokeRequest(
          method: LibXrayMethod.runXray,
          payload: RunXrayRequest(compiled.xrayJson).toJson(),
        ).toJson(),
      ),
    ),
  );
}

void main() {
  late AppDatabase db;
  late ConnectionCoordinator coordinator;
  late FakeReloadHost host;
  ConnectionRuntime? start;
  ConnectionRuntime? prepared;
  late VpnStatus status;
  late int stops;
  late List<ConnectionRuntime> starts;
  late int freshPrepares;
  ConnectionRuntime? refreshed;
  ConnectionHostException? startError;
  late bool heldNow;
  late ValueNotifier<bool> measuring;
  late OneVpnReloadPolicy policy;
  final stored = _region('CN');

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    start = null;
    prepared = null;
    status = VpnStatus.connected;
    stops = 0;
    starts = [];
    freshPrepares = 0;
    refreshed = null;
    startError = null;
    heldNow = false;
    measuring = ValueNotifier(false);
    host = FakeReloadHost();
    host.onReload = (_) async {
      start = prepared;
      return ReloadResult.applied;
    };
    coordinator = ConnectionCoordinator(
      database: db,
      readRuntime: () async => start,
      inspect: (_) async => HostConnection(status, runtime: start),
      stop: () async {
        stops++;
        status = VpnStatus.disconnected;
        start = null;
        return const HostConnection(VpnStatus.disconnected);
      },
      start: (runtime) async {
        starts.add(runtime);
        if (startError case final error?) throw error;
        status = VpnStatus.connected;
        start = runtime;
        return HostConnection(VpnStatus.connected, runtime: runtime);
      },
    );
    addTearDown(coordinator.dispose);
    await coordinator.initialize(observe: false);
    // As on Android: a fresh connect starts a measure core.
    coordinator.freshConnectPrepare = (configuration, _) async {
      freshPrepares++;
      return _compile(configuration, port: '18005', measure: true);
    };
    policy = fakeReloadPolicy(
      host: host,
      prepare: (next) => prepared = _compile(next, port: '18002'),
    );
  });

  OneVpnLaunchRefresh refresh() => OneVpnLaunchRefresh(
    coordinator: coordinator,
    reloads: policy,
    held: OneVpnHeldTunnel(read: () async => heldNow, supported: true),
    measuring: measuring,
    prepare: (_, next, running) async => refreshed = _compile(
      next,
      port: '18003',
      entryId: running.entries.single.id,
    ),
  );

  /// Expects the one start to be [refreshed]: a pinned runtime on the entry
  /// [entryId] that hands the current TUN resolver, now connected.
  void expectPinnedStart({int entryId = 1}) {
    expect(freshPrepares, 0);
    final started = starts.single;
    expect(started.identity, refreshed?.identity);
    expect(OneVpnNativeConnect.isMeasure(started), isFalse);
    expect(started.entries.single.id, entryId);
    expect(started.request.tun?.tunDnsIPv4, _tunNow);
    expect(coordinator.state.value.phase, ConnectionPhase.connected);
    expect(coordinator.state.value.runtime?.identity, started.identity);
  }

  /// Runs [running] as the connected tunnel over the store [store].
  Future<void> settle(
    ConnectionRuntime running, {
    ConnectionConfiguration? store,
  }) async {
    start = running;
    await db.connectionConfigDao.commit(
      configurationJson: (store ?? stored).encode(),
    );
    await coordinator.refresh();
  }

  /// Expects the tunnel untouched: no reload, no stop, no start, the store
  /// as [store].
  Future<void> expectUntouched(
    ConnectionRuntime running, {
    ConnectionConfiguration? store,
  }) async {
    expect(host.requests, isEmpty);
    expect(stops, 0);
    expect(starts, isEmpty);
    expect(start?.identity, running.identity);
    expect(
      (await coordinator.configuration).encode(),
      (store ?? stored).encode(),
    );
  }

  group('a stale request', () {
    test(
      'that differs only in the core config reloads in place once',
      () async {
        await settle(_compile(stored, port: '18001', dns: 'older'));

        expect(await refresh().run(), OneVpnLaunchRefreshOutcome.reloaded);

        expect(host.requests, hasLength(1));
        expect(stops, 0);
        expect(starts, isEmpty);
        expect(start?.identity, prepared?.identity);
        expect((await coordinator.configuration).encode(), stored.encode());
      },
    );

    test('that differs in the TUN settings reconnects once', () async {
      await settle(_compile(stored, port: '18001', tun: _tunOld));

      expect(await refresh().run(), OneVpnLaunchRefreshOutcome.reconnected);

      // The reload refuses the TUN change before the native call.
      expect(host.requests, isEmpty);
      expect(stops, 1);
      expectPinnedStart();
      expect(starts.single.configuration.encode(), stored.encode());
      final selection = (await coordinator.configuration).connection;
      expect(selection.selection.location, 'fr-par');
      expect(selection.smart.directRegions, ['CN']);
    });

    test('reconnects onto the pinned runtime on the running server, never '
        'through the fresh-connect prepare', () async {
      coordinator.freshConnectPrepare = (_, _) async {
        freshPrepares++;
        throw const FormatException('no measure on a refresh');
      };
      await settle(_compile(stored, port: '18001', tun: _tunOld, entryId: 7));

      expect(await refresh().run(), OneVpnLaunchRefreshOutcome.reconnected);

      expect(stops, 1);
      expectPinnedStart(entryId: 7);
    });

    test('reconnects once where the native side cannot reload', () async {
      await settle(_compile(stored, port: '18001', dns: 'older'));
      host.onReload = (_) async => ReloadResult.notSupported;

      expect(await refresh().run(), OneVpnLaunchRefreshOutcome.reconnected);

      expect(host.requests, hasLength(1));
      expect(stops, 1);
      expectPinnedStart();
    });

    test('reconnects once where the platform never reloads in place', () async {
      policy = fakeReloadPolicy(
        host: host,
        supported: false,
        prepare: (next) => prepared = _compile(next, port: '18002'),
      );
      await settle(_compile(stored, port: '18001', dns: 'older'));

      expect(await refresh().run(), OneVpnLaunchRefreshOutcome.reconnected);

      expect(host.requests, isEmpty);
      expect(stops, 1);
      expectPinnedStart();
    });

    test('is current after the refresh: a second run and the next launch do '
        'nothing', () async {
      await settle(_compile(stored, port: '18001', tun: _tunOld));
      final first = refresh();
      expect(await first.run(), OneVpnLaunchRefreshOutcome.reconnected);
      await coordinator.refresh();

      expect(await first.run(), OneVpnLaunchRefreshOutcome.skipped);
      expect(await refresh().run(), OneVpnLaunchRefreshOutcome.current);

      expect(stops, 1);
      expect(starts, hasLength(1));
      expect(host.requests, isEmpty);
    });

    test('a reload that does not apply leaves the tunnel, and the next launch '
        'tries again', () async {
      final running = _compile(stored, port: '18001', dns: 'older');
      await settle(running);
      host.onReload = (_) async => ReloadResult.rolledBack;

      expect(await refresh().run(), OneVpnLaunchRefreshOutcome.notApplied);
      expect(host.requests, hasLength(1));
      expect(stops, 0);
      expect(start?.identity, running.identity);

      host.onReload = (_) async {
        start = prepared;
        return ReloadResult.applied;
      };
      expect(await refresh().run(), OneVpnLaunchRefreshOutcome.reloaded);
      expect(host.requests, hasLength(2));
    });

    test(
      'a double failure takes the failed-start path and never throws',
      () async {
        await settle(_compile(stored, port: '18001', dns: 'older'));
        host.onReload = (_) async {
          status = VpnStatus.disconnected;
          start = null;
          return ReloadResult.failed;
        };

        expect(await refresh().run(), OneVpnLaunchRefreshOutcome.notApplied);

        expect(host.requests, hasLength(1));
        expect(stops, 0);
        expect(starts, isEmpty);
        expect(coordinator.state.value.phase, ConnectionPhase.failed);
      },
    );
  });

  group('a reconnect that does not finish', () {
    test(
      'a start that fails after the stop lands red and never throws',
      () async {
        // As on Android: a failed start keeps a host that reads disconnected.
        coordinator.keepTunnelOnFailedStart = true;
        startError = const ConnectionHostException('startFailed');
        await settle(_compile(stored, port: '18001', tun: _tunOld));

        expect(await refresh().run(), OneVpnLaunchRefreshOutcome.notApplied);

        expect(stops, 1);
        expect(starts.single.identity, refreshed?.identity);
        expect(freshPrepares, 0);
        final view = coordinator.state.value;
        expect(view.phase, ConnectionPhase.failed);
        expect(view.runtime, isNull);
        expect(view.issue, 'startFailed');
        expect((await coordinator.configuration).encode(), stored.encode());
      },
    );

    test('a tunnel that stops before the reconnect starts nothing', () async {
      await settle(_compile(stored, port: '18001', dns: 'older'));
      host.onReload = (_) async {
        status = VpnStatus.disconnected;
        start = null;
        return ReloadResult.notSupported;
      };

      expect(await refresh().run(), OneVpnLaunchRefreshOutcome.skipped);

      expect(host.requests, hasLength(1));
      expect(stops, 0);
      expect(starts, isEmpty);
      expect(coordinator.state.value.phase, ConnectionPhase.disconnected);
    });

    test('a store change before the reconnect stops nothing and publishes '
        'nothing', () async {
      final running = _compile(stored, port: '18001', dns: 'older');
      await settle(running);
      final moved = _region('RU');
      final phases = <ConnectionPhase>[];
      void record() => phases.add(coordinator.state.value.phase);
      host.onReload = (_) async {
        await db.connectionConfigDao.commit(configurationJson: moved.encode());
        coordinator.state.addListener(record);
        return ReloadResult.notSupported;
      };
      addTearDown(() => coordinator.state.removeListener(record));

      expect(await refresh().run(), OneVpnLaunchRefreshOutcome.notApplied);

      expect(stops, 0);
      expect(starts, isEmpty);
      expect(start?.identity, running.identity);
      expect(phases, everyElement(ConnectionPhase.connected));
      expect(coordinator.state.value.runtime?.identity, running.identity);
      expect((await coordinator.configuration).encode(), moved.encode());
    });
  });

  group('nothing changes', () {
    test(
      'for an equal request on other ports and in another key order',
      () async {
        final running = _compile(stored, port: '18001');
        final reordered = reloadRuntime(
          stored,
          metricsPort: '18009',
          tunDnsIPv4: _tunNow,
          core: {
            'metrics': {'listen': '127.0.0.1:18009'},
            'dns': 'current',
            'routing': stored.connection.toJson(),
          },
        );
        expect(OneVpnLaunchRefresh.isCurrent(running, reordered), isTrue);
        await settle(running);

        expect(await refresh().run(), OneVpnLaunchRefreshOutcome.current);

        await expectUntouched(running);
      },
    );

    test('without a tunnel', () async {
      status = VpnStatus.disconnected;
      await settle(_compile(stored, port: '18001', tun: _tunOld));
      start = null;
      await coordinator.refresh();

      expect(await refresh().run(), OneVpnLaunchRefreshOutcome.current);

      expect(host.requests, isEmpty);
      expect(stops, 0);
      expect(starts, isEmpty);
    });

    test('while the tunnel connects', () async {
      status = VpnStatus.connecting;
      final running = _compile(stored, port: '18001', tun: _tunOld);
      await settle(running);
      expect(coordinator.state.value.phase, ConnectionPhase.connecting);

      expect(await refresh().run(), OneVpnLaunchRefreshOutcome.skipped);

      await expectUntouched(running);
    });

    test('over a measure or holding core', () async {
      final running = _compile(
        stored,
        port: '18001',
        tun: _tunOld,
        measure: true,
      );
      await settle(running);
      expect(coordinator.state.value.phase, ConnectionPhase.connected);

      expect(await refresh().run(), OneVpnLaunchRefreshOutcome.skipped);

      await expectUntouched(running);
    });

    test('while the native connect measures', () async {
      final running = _compile(stored, port: '18001', tun: _tunOld);
      await settle(running);
      measuring.value = true;

      expect(await refresh().run(), OneVpnLaunchRefreshOutcome.skipped);

      await expectUntouched(running);
    });

    test('while another reload runs', () async {
      final running = _compile(stored, port: '18001', tun: _tunOld);
      await settle(running);
      policy.state.value = OneVpnReloadState.reloading;

      expect(await refresh().run(), OneVpnLaunchRefreshOutcome.skipped);

      await expectUntouched(running);
    });

    test('over a held TUN', () async {
      final running = _compile(stored, port: '18001', tun: _tunOld);
      await settle(running);
      heldNow = true;

      expect(await refresh().run(), OneVpnLaunchRefreshOutcome.skipped);

      await expectUntouched(running);
    });

    test('when the store names another selection, mode or region', () async {
      for (final other in [
        _region('CN', selection: const ServerSelection.automatic()),
        _region('RU'),
        ConnectionConfiguration(
          connection: ConnectionSettings(
            selection: const ServerSelection.location('fr-par'),
          ),
        ),
      ]) {
        final running = _compile(other, port: '18001', tun: _tunOld);
        await settle(running);

        expect(await refresh().run(), OneVpnLaunchRefreshOutcome.skipped);

        await expectUntouched(running);
      }
    });

    test('when the stored selection does not prepare or falls back', () async {
      final running = _compile(stored, port: '18001', tun: _tunOld);
      await settle(running);
      for (final prepare in <OneVpnReloadPrepare>[
        (_, _, _) async => throw const FormatException('gone'),
        (_, next, _) async =>
            reloadRuntime(next, metricsPort: '18003', notice: 'selectionReset'),
      ]) {
        final skipped = OneVpnLaunchRefresh(
          coordinator: coordinator,
          reloads: policy,
          held: OneVpnHeldTunnel(read: () async => false, supported: true),
          measuring: measuring,
          prepare: prepare,
        );

        expect(await skipped.run(), OneVpnLaunchRefreshOutcome.skipped);

        await expectUntouched(running);
      }
    });
  });

  group('the region switch correction', () {
    // A tunnel compiled while the store held CN with both switches on, and
    // the store after the boot correction wrote them off.
    final switchesOn = _region('CN', switches: true);

    test('reloads in place onto the stored switches', () async {
      await settle(_compile(switchesOn, port: '18001'));

      expect(await refresh().run(), OneVpnLaunchRefreshOutcome.reloaded);

      expect(host.requests, hasLength(1));
      expect(stops, 0);
      final smart = start!.configuration.connection.smart;
      expect(smart.directApple, isFalse);
      expect(smart.directWindows, isFalse);
      expect(await refresh().run(), OneVpnLaunchRefreshOutcome.current);
    });

    test('reconnects once over an older TUN, never declining', () async {
      await settle(_compile(switchesOn, port: '18001', tun: _tunOld));

      expect(await refresh().run(), OneVpnLaunchRefreshOutcome.reconnected);

      expect(stops, 1);
      expectPinnedStart();
      final smart = starts.single.configuration.connection.smart;
      expect(smart.directRegions, ['CN']);
      expect(smart.directApple, isFalse);
      expect(smart.directWindows, isFalse);
    });

    test('is what a region pick writes', () {
      expect(
        OneVpnDirectRegionsApplyService.nextConfiguration(
          switchesOn,
          'CN',
        ).encode(),
        stored.encode(),
      );
    });
  });

  group('the real compile', () {
    final settings = _region('CN').connection;

    test('equals itself across prepares on other ports', () {
      expect(
        OneVpnLaunchRefresh.isCurrent(
          _real(settings, 18001),
          _real(settings, 28001),
        ),
        isTrue,
      );
    });

    test('differs when a region switch differs', () {
      expect(
        OneVpnLaunchRefresh.isCurrent(
          _real(_region('CN', switches: true).connection, 18001),
          _real(settings, 18001),
        ),
        isFalse,
      );
    });
  });
}
