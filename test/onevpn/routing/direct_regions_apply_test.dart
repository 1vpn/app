// Pins the Direct-regions apply service: the row-to-mode mapping and the
// runtime-effect predicate. All via VPN maps to allVpn with no direct
// regions. A region maps to smart with that one code and the Apple and
// Windows switches off. The service reports a runtime change when the mode
// or the direct regions change, and under smart when a switch changes. A
// pick of the stored region reloads a tunnel that runs the switches on. The
// service persists the mapped configuration through the coordinator. A held
// TUN is released before the change applies. A connected change reloads in
// place with no dialog where the platform supports it. A change that fails
// to apply reports the failure and saves nothing. Where the reload cannot
// run, the service asks through the reconnect callback. A double failure
// throws. A change while the tunnel connects reloads in place too.
//
// At open, a connected tunnel that runs a region with a switch on while the
// store holds that region with both off reloads once in place, with no
// dialog. No tunnel, a tunnel that connects, a tunnel with no region or in
// allVpn, and a tunnel that agrees with the store reload nothing. A reload
// that fails never throws, and the next open tries again.
//
// A fallback to Off stores allVpn over any other stored mode, and the
// stored result compiles no direct rule and no direct DNS server. A stored
// allVpn is left unwritten, and a concurrent change wins over the fallback.
// An Off pick over an allVpn store still reloads a tunnel that runs smart.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/core/db/database/database.dart';
import 'package:onexray/core/pigeon/messages.g.dart';
import 'package:onexray/onevpn/app/held_tunnel.dart';
import 'package:onexray/onevpn/handover/handover.g.dart';
import 'package:onexray/onevpn/routing/direct_regions_apply.dart';
import 'package:onexray/service/connect/compiler.dart';
import 'package:onexray/service/connect/coordinator.dart';
import 'package:onexray/service/connect/runtime_host.dart';
import 'package:onexray/service/connect/runtime.dart';
import 'package:onexray/service/connect/settings.dart';

import '../support/compiler_fixtures.dart';
import '../support/reload_fakes.dart';

ConnectionConfiguration _config(TrafficMode mode, List<String> regions) =>
    ConnectionConfiguration(
      connection: ConnectionSettings(
        trafficMode: mode,
        smart: SmartRoutingSettings(directRegions: regions),
      ),
    );

/// A coordinator over a disconnected host that records each disconnect.
class _RecordingCoordinator extends ConnectionCoordinator {
  _RecordingCoordinator(AppDatabase db)
    : super(
        database: db,
        inspect: (_) async => const HostConnection(VpnStatus.disconnected),
      );

  /// Each disconnect and apply, in call order.
  final calls = <String>[];

  /// Runs inside each disconnect.
  void Function()? onDisconnect;

  /// Runs inside each apply, before the coordinator's own.
  Future<void> Function()? beforeApply;

  @override
  Future<void> disconnect() async {
    calls.add('disconnect');
    onDisconnect?.call();
  }

  @override
  Future<void> apply(
    ConnectionConfiguration next, {
    bool connect = false,
    bool disconnect = false,
    bool affectsRuntime = true,
    bool allowReconnect = true,
    String? expectedConfiguration,
    Future<void> Function()? writeAssets,
    Future<void> Function()? validateAssets,
    PrepareConnection? prepare,
  }) async {
    calls.add('apply');
    await beforeApply?.call();
    return super.apply(
      next,
      connect: connect,
      disconnect: disconnect,
      affectsRuntime: affectsRuntime,
      allowReconnect: allowReconnect,
      expectedConfiguration: expectedConfiguration,
      writeAssets: writeAssets,
      validateAssets: validateAssets,
      prepare: prepare,
    );
  }
}

Future<ConnectionCoordinator> _initialize(
  ConnectionCoordinator coordinator,
) async {
  addTearDown(coordinator.dispose);
  await coordinator.initialize(observe: false);
  return coordinator;
}

void main() {
  test('All via VPN maps to allVpn, a region maps to smart with one code', () {
    final base = _config(TrafficMode.smart, const ['CN']);

    final allVpn = OneVpnDirectRegionsApplyService.nextConfiguration(
      base,
      null,
    );
    expect(allVpn.connection.trafficMode, TrafficMode.allVpn);
    expect(allVpn.connection.smart.directRegions, isEmpty);
    // The carve-out bools ride along untouched. allVpn suppresses them at
    // compile, so the posture is leak-safe whatever these bools hold.
    expect(allVpn.connection.smart.directApple, isTrue);

    final region = OneVpnDirectRegionsApplyService.nextConfiguration(
      base,
      'RU',
    );
    expect(region.connection.trafficMode, TrafficMode.smart);
    expect(region.connection.smart.directRegions, ['RU']);
  });

  test('a region pick writes the Apple and Windows switches off', () {
    // Anti-vacuity: the stored shape carries both switches on.
    final base = _config(TrafficMode.allVpn, const []);
    expect(base.connection.smart.directApple, isTrue);
    expect(base.connection.smart.directWindows, isTrue);

    for (final code in const ['CN', 'IR', 'RU', 'TM']) {
      final smart = OneVpnDirectRegionsApplyService.nextConfiguration(
        base,
        code,
      ).connection.smart;
      expect(smart.directRegions, [code]);
      expect(smart.directApple, isFalse, reason: code);
      expect(smart.directWindows, isFalse, reason: code);
      expect(smart.directPrivate, isTrue, reason: code);
    }
  });

  test('a runtime change is the mode or the direct regions changing', () {
    final allVpn = _config(TrafficMode.allVpn, const []);
    final cn = OneVpnDirectRegionsApplyService.nextConfiguration(allVpn, 'CN');

    expect(
      OneVpnDirectRegionsApplyService.affectsRuntime(allVpn, null),
      isFalse,
    );
    expect(
      OneVpnDirectRegionsApplyService.affectsRuntime(allVpn, 'CN'),
      isTrue,
    );
    expect(OneVpnDirectRegionsApplyService.affectsRuntime(cn, 'CN'), isFalse);
    expect(OneVpnDirectRegionsApplyService.affectsRuntime(cn, 'RU'), isTrue);
    expect(OneVpnDirectRegionsApplyService.affectsRuntime(cn, null), isTrue);
  });

  test('a pick over a region with the switches on is a runtime change', () {
    // A stored region with both switches on.
    final cnWithSwitches = _config(TrafficMode.smart, const ['CN']);
    expect(cnWithSwitches.connection.smart.directApple, isTrue);

    expect(
      OneVpnDirectRegionsApplyService.affectsRuntime(cnWithSwitches, 'CN'),
      isTrue,
    );
  });

  test(
    'apply persists the mapped mode and regions while disconnected',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final coordinator = await _initialize(
        ConnectionCoordinator(
          database: db,
          inspect: (_) async => const HostConnection(VpnStatus.disconnected),
        ),
      );
      final service = OneVpnDirectRegionsApplyService(
        coordinator: coordinator,
        held: OneVpnHeldTunnel(read: () async => false, supported: true),
      );

      expect(
        await service.apply(
          regionCode: 'CN',
          confirmReconnect: () async => throw StateError('no reconnect'),
        ),
        OneVpnDirectRegionsOutcome.applied,
      );
      var stored = await coordinator.configuration;
      expect(stored.connection.trafficMode, TrafficMode.smart);
      expect(stored.connection.smart.directRegions, ['CN']);

      expect(
        await service.apply(
          regionCode: null,
          confirmReconnect: () async => throw StateError('no reconnect'),
        ),
        OneVpnDirectRegionsOutcome.applied,
      );
      stored = await coordinator.configuration;
      expect(stored.connection.trafficMode, TrafficMode.allVpn);
      expect(stored.connection.smart.directRegions, isEmpty);
    },
  );

  test('apply releases a held TUN before the change', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final coordinator = _RecordingCoordinator(db);
    await _initialize(coordinator);
    var heldAnswer = true;
    coordinator.onDisconnect = () => heldAnswer = false;
    final service = OneVpnDirectRegionsApplyService(
      coordinator: coordinator,
      held: OneVpnHeldTunnel(
        read: () async => heldAnswer,
        supported: true,
        pollInterval: const Duration(milliseconds: 1),
      ),
    );

    expect(
      await service.apply(
        regionCode: 'CN',
        confirmReconnect: () async => throw StateError('no reconnect'),
      ),
      OneVpnDirectRegionsOutcome.applied,
    );

    expect(coordinator.calls, ['disconnect', 'apply']);
    final stored = await coordinator.configuration;
    expect(stored.connection.smart.directRegions, ['CN']);
  });

  group('the Off fallback', () {
    late AppDatabase db;
    late _RecordingCoordinator coordinator;
    late OneVpnDirectRegionsApplyService service;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      coordinator = _RecordingCoordinator(db);
      await _initialize(coordinator);
      service = OneVpnDirectRegionsApplyService(
        coordinator: coordinator,
        held: OneVpnHeldTunnel(read: () async => false, supported: true),
      );
    });

    Future<void> store(ConnectionConfiguration configuration) => db
        .connectionConfigDao
        .commit(configurationJson: configuration.encode());

    Future<ConnectionSettings> stored() async =>
        (await coordinator.configuration).connection;

    test('an empty stored set reads as Off and stores allVpn', () async {
      await store(_config(TrafficMode.smart, const []));

      expect(await service.currentSelection(), isNull);

      expect((await stored()).trafficMode, TrafficMode.allVpn);
      expect((await stored()).smart.directRegions, isEmpty);
    });

    test('a stored custom mode reads as Off and stores allVpn', () async {
      await store(_config(TrafficMode.custom, const []));

      expect(await service.currentSelection(), isNull);

      expect((await stored()).trafficMode, TrafficMode.allVpn);
    });

    test('a stored region reads as its row and stays smart', () async {
      await store(_config(TrafficMode.smart, const ['CN']));

      expect(await service.currentSelection(), 'CN');

      expect(coordinator.calls, isEmpty);
      expect((await stored()).trafficMode, TrafficMode.smart);
      expect((await stored()).smart.directRegions, ['CN']);
    });

    test('a region the geodata dropped stores allVpn', () async {
      await store(_config(TrafficMode.smart, const ['TM']));

      await service.storeOff();

      expect((await stored()).trafficMode, TrafficMode.allVpn);
      expect((await stored()).smart.directRegions, isEmpty);
    });

    test('an explicit Off pick stores allVpn', () async {
      await store(_config(TrafficMode.smart, const ['CN']));

      expect(
        await service.apply(
          regionCode: null,
          confirmReconnect: () async => throw StateError('no reconnect'),
        ),
        OneVpnDirectRegionsOutcome.applied,
      );

      expect((await stored()).trafficMode, TrafficMode.allVpn);
      expect((await stored()).smart.directRegions, isEmpty);
    });

    test('a stored allVpn is left unwritten', () async {
      await store(_config(TrafficMode.allVpn, const []));

      expect(await service.currentSelection(), isNull);
      await service.storeOff();

      expect(coordinator.calls, isEmpty);
    });

    test('a concurrent change wins over the fallback', () async {
      await store(_config(TrafficMode.smart, const []));
      final concurrent = _config(TrafficMode.smart, const ['RU']);
      coordinator.beforeApply = () => store(concurrent);

      await service.storeOff();

      expect(coordinator.calls, ['apply']);
      expect((await coordinator.configuration).encode(), concurrent.encode());
    });

    test('the stored fallback compiles no direct rule and no direct DNS '
        'server', () async {
      final before = _config(TrafficMode.smart, const []);
      await store(before);
      await service.currentSelection();
      final after = await stored();

      for (final platform in [
        ConnectionPlatform.android,
        ConnectionPlatform.linux,
      ]) {
        CompiledConnection compile(ConnectionSettings settings) =>
            ConnectionCompiler.compile(
              settings: settings,
              entries: [compilerNode(1)],
              regions: compilerCatalog,
              options: compilerOptions(
                platform: platform,
                interfaceName: platform == ConnectionPlatform.linux
                    ? 'selected-interface'
                    : '',
              ),
            );
        List<Map> directRules(CompiledConnection plan) =>
            (plan.config['routing']['rules'] as List)
                .cast<Map>()
                .where((rule) => rule['outboundTag'] == 'direct')
                .toList();

        // Anti-vacuity: the stored smart shape compiles direct rules.
        expect(directRules(compile(before.connection)), isNotEmpty);

        final plan = compile(after);
        expect(directRules(plan), isEmpty, reason: '$platform');
        final servers = plan.config['dns']['servers'] as List;
        expect(servers, isNotEmpty);
        for (final server in servers) {
          expect(server, isA<Map>(), reason: '$platform');
          expect(
            (server as Map)['tag'],
            ConnectionCompiler.dnsProxy,
            reason: '$platform',
          );
        }
        expect(plan.xrayJson, isNot(contains('app-direct-dns')));
      }
    });
  });

  group('a connected change', () {
    late AppDatabase db;
    late ConnectionCoordinator coordinator;
    late FakeReloadHost host;
    late ConnectionRuntime running;
    ConnectionRuntime? start;
    ConnectionRuntime? prepared;
    var status = VpnStatus.connected;
    late int confirms;
    late int stops;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      running = reloadRuntime(
        _config(TrafficMode.allVpn, const []),
        metricsPort: '18001',
      );
      start = running;
      prepared = null;
      status = VpnStatus.connected;
      confirms = 0;
      stops = 0;
      host = FakeReloadHost();
      coordinator = await _initialize(
        ConnectionCoordinator(
          database: db,
          readRuntime: () async => start,
          inspect: (_) async => HostConnection(status, runtime: start),
          stop: () async {
            stops++;
            return const HostConnection(VpnStatus.disconnected);
          },
        ),
      );
      await db.connectionConfigDao.commit(
        configurationJson: running.configuration.encode(),
      );
    });

    OneVpnDirectRegionsApplyService service({
      bool supported = true,
      String? notice,
      Future<bool> Function()? policyHeld,
    }) => OneVpnDirectRegionsApplyService(
      coordinator: coordinator,
      held: OneVpnHeldTunnel(read: () async => false, supported: true),
      reloadPolicy: fakeReloadPolicy(
        host: host,
        supported: supported,
        held: policyHeld,
        prepare: (next) => prepared = reloadRuntime(
          next,
          metricsPort: '18002',
          notice: notice,
        ),
      ),
    );

    Future<bool> confirm() async {
      confirms++;
      return false;
    }

    test('reloads in place with no dialog', () async {
      host.onReload = (_) async {
        start = prepared;
        return ReloadResult.applied;
      };

      final outcome = await service().apply(
        regionCode: 'CN',
        confirmReconnect: confirm,
      );

      expect(outcome, OneVpnDirectRegionsOutcome.applied);
      expect(confirms, 0);
      expect(host.requests, hasLength(1));
      final stored = await coordinator.configuration;
      expect(stored.connection.smart.directRegions, ['CN']);
    });

    test('while connecting reloads in place with no dialog', () async {
      status = VpnStatus.connecting;
      await coordinator.refresh();
      expect(coordinator.state.value.phase, ConnectionPhase.connecting);
      host.onReload = (_) async {
        start = prepared;
        return ReloadResult.applied;
      };

      final outcome = await service().apply(
        regionCode: 'CN',
        confirmReconnect: confirm,
      );

      expect(outcome, OneVpnDirectRegionsOutcome.applied);
      expect(confirms, 0);
      expect(host.requests, hasLength(1));
      final stored = await coordinator.configuration;
      expect(stored.connection.smart.directRegions, ['CN']);
    });

    // A store-only fallback leaves the store at allVpn while the tunnel
    // still runs smart. The Off pick compares against the running tunnel.
    test(
      'an Off pick over an allVpn store reloads a tunnel that runs smart',
      () async {
        start = reloadRuntime(
          _config(TrafficMode.smart, const ['CN']),
          metricsPort: '18001',
        );
        await coordinator.refresh();
        expect(
          coordinator.state.value.runtime?.configuration.connection.trafficMode,
          TrafficMode.smart,
        );
        host.onReload = (_) async {
          start = prepared;
          return ReloadResult.applied;
        };

        final outcome = await service().apply(
          regionCode: null,
          confirmReconnect: confirm,
        );

        expect(outcome, OneVpnDirectRegionsOutcome.applied);
        expect(confirms, 0);
        expect(host.requests, hasLength(1));
        expect(
          prepared!.configuration.connection.trafficMode,
          TrafficMode.allVpn,
        );
        expect(prepared!.configuration.connection.smart.directRegions, isEmpty);
        expect(
          (await coordinator.configuration).connection.trafficMode,
          TrafficMode.allVpn,
        );
      },
    );

    // The store holds the region with both switches off while the tunnel
    // runs it with both on. A pick of the same region compares against the
    // running tunnel and reloads it.
    test('a pick of the stored region reloads a tunnel that runs the '
        'switches on', () async {
      start = reloadRuntime(
        _config(TrafficMode.smart, const ['CN']),
        metricsPort: '18001',
      );
      await coordinator.refresh();
      expect(
        coordinator
            .state
            .value
            .runtime
            ?.configuration
            .connection
            .smart
            .directApple,
        isTrue,
      );
      await db.connectionConfigDao.commit(
        configurationJson: OneVpnDirectRegionsApplyService.nextConfiguration(
          running.configuration,
          'CN',
        ).encode(),
      );
      host.onReload = (_) async {
        start = prepared;
        return ReloadResult.applied;
      };

      final outcome = await service().apply(
        regionCode: 'CN',
        confirmReconnect: confirm,
      );

      expect(outcome, OneVpnDirectRegionsOutcome.applied);
      expect(confirms, 0);
      expect(host.requests, hasLength(1));
      final smart = prepared!.configuration.connection.smart;
      expect(smart.directRegions, ['CN']);
      expect(smart.directApple, isFalse);
      expect(smart.directWindows, isFalse);
    });

    group('the switch reload at open', () {
      // CN with both switches on, as a tunnel compiled before the picker
      // wrote them off runs it.
      final cnSwitchesOn = _config(TrafficMode.smart, const ['CN']);
      // CN in the shape a pick writes: both switches off.
      final cnSwitchesOff = OneVpnDirectRegionsApplyService.nextConfiguration(
        cnSwitchesOn,
        'CN',
      );

      // Runs [configuration] as the connected tunnel and stores [stored].
      Future<void> settle(
        ConnectionConfiguration configuration,
        ConnectionConfiguration stored,
      ) async {
        start = reloadRuntime(configuration, metricsPort: '18001');
        await db.connectionConfigDao.commit(configurationJson: stored.encode());
        await coordinator.refresh();
        host.onReload = (_) async {
          start = prepared;
          return ReloadResult.applied;
        };
      }

      test('reloads once in place with the stored configuration', () async {
        await settle(cnSwitchesOn, cnSwitchesOff);
        expect(coordinator.state.value.phase, ConnectionPhase.connected);

        expect(await service().reloadRunningSwitches(), isTrue);

        expect(host.requests, hasLength(1));
        expect(prepared!.configuration.encode(), cnSwitchesOff.encode());
        expect(
          (await coordinator.configuration).encode(),
          cnSwitchesOff.encode(),
        );

        // A second open finds the tunnel on the stored routing.
        await coordinator.refresh();
        expect(await service().reloadRunningSwitches(), isFalse);
        expect(host.requests, hasLength(1));
      });

      test('never releases a hold that stands when it reaches apply', () async {
        await settle(cnSwitchesOn, cnSwitchesOff);
        // The phase still reads connected; the native side already holds.
        final automatic = OneVpnDirectRegionsApplyService(
          coordinator: coordinator,
          held: OneVpnHeldTunnel(
            read: () async => true,
            supported: true,
            pollInterval: const Duration(milliseconds: 1),
          ),
          reloadPolicy: fakeReloadPolicy(
            host: host,
            prepare: (next) =>
                prepared = reloadRuntime(next, metricsPort: '18002'),
          ),
        );

        expect(await automatic.reloadRunningSwitches(), isFalse);

        expect(stops, 0);
        expect(host.requests, isEmpty);
        expect(automatic.held.value, isTrue);
        expect(
          coordinator.state.value.runtime?.configuration.encode(),
          cnSwitchesOn.encode(),
        );
      });

      test('reloads nothing without a tunnel', () async {
        await settle(cnSwitchesOn, cnSwitchesOff);
        status = VpnStatus.disconnected;
        start = null;
        await coordinator.refresh();

        expect(await service().reloadRunningSwitches(), isFalse);
        expect(host.requests, isEmpty);
      });

      test('reloads nothing while the tunnel connects', () async {
        status = VpnStatus.connecting;
        await settle(cnSwitchesOn, cnSwitchesOff);
        expect(coordinator.state.value.phase, ConnectionPhase.connecting);

        expect(await service().reloadRunningSwitches(), isFalse);
        expect(host.requests, isEmpty);
      });

      test('reloads nothing for a tunnel with no region', () async {
        await settle(_config(TrafficMode.smart, const []), cnSwitchesOff);

        expect(await service().reloadRunningSwitches(), isFalse);
        expect(host.requests, isEmpty);
      });

      test('reloads nothing for an all-traffic tunnel', () async {
        await settle(_config(TrafficMode.allVpn, const []), cnSwitchesOff);

        expect(await service().reloadRunningSwitches(), isFalse);
        expect(host.requests, isEmpty);
      });

      test('reloads nothing for a tunnel that agrees with the store', () async {
        await settle(cnSwitchesOff, cnSwitchesOff);

        expect(await service().reloadRunningSwitches(), isFalse);
        expect(host.requests, isEmpty);
      });

      test('a reload that does not apply leaves the tunnel, and the next open '
          'tries again', () async {
        await settle(cnSwitchesOn, cnSwitchesOff);
        host.onReload = (_) async => ReloadResult.rolledBack;

        expect(await service().reloadRunningSwitches(), isTrue);
        expect(host.requests, hasLength(1));
        expect(
          coordinator.state.value.runtime?.configuration.encode(),
          cnSwitchesOn.encode(),
        );

        host.onReload = (_) async {
          start = prepared;
          return ReloadResult.applied;
        };
        expect(await service().reloadRunningSwitches(), isTrue);
        expect(host.requests, hasLength(2));
      });

      test('a double failure takes the failed-start path and never throws '
          'to the start', () async {
        await settle(cnSwitchesOn, cnSwitchesOff);
        var heldNow = false;
        host.onReload = (_) async {
          // The native failed-start path: the core is gone, the TUN is held,
          // and the status reads down.
          status = VpnStatus.disconnected;
          start = null;
          heldNow = true;
          return ReloadResult.failed;
        };

        await expectLater(
          service(policyHeld: () async => heldNow).reloadRunningSwitches(),
          completion(false),
        );
        expect(host.requests, hasLength(1));
        expect(stops, 0);
        expect(coordinator.state.value.phase, ConnectionPhase.failed);
      });

      // Runs [automatic] over the stale state where the reload asks for a
      // reconnect, the native [answer] when one is given, and expects
      // nothing stopped, started or stored.
      Future<void> expectDeclined(
        OneVpnDirectRegionsApplyService automatic, {
        ReloadResult? answer,
      }) async {
        await settle(cnSwitchesOn, cnSwitchesOff);
        if (answer != null) host.onReload = (_) async => answer;
        final running = coordinator.state.value.runtime;

        expect(await automatic.reloadRunningSwitches(), isFalse);

        expect(stops, 0);
        expect(coordinator.state.value.runtime?.identity, running?.identity);
        expect(
          coordinator.state.value.runtime?.configuration.encode(),
          cnSwitchesOn.encode(),
        );
        expect(
          (await coordinator.configuration).encode(),
          cnSwitchesOff.encode(),
        );
        expect(coordinator.state.value.phase, ConnectionPhase.connected);
      }

      test('declines the reconnect where no in-place reload runs', () async {
        await expectDeclined(service(supported: false));
        expect(host.requests, isEmpty);
      });

      test('declines the reconnect a native answer asks for', () async {
        await expectDeclined(service(), answer: ReloadResult.notSupported);
        expect(host.requests, hasLength(1));
      });

      test('reloads nothing over a measure core', () async {
        start = reloadRuntime(
          cnSwitchesOn,
          metricsPort: '18001',
          measure: true,
        );
        await db.connectionConfigDao.commit(
          configurationJson: cnSwitchesOff.encode(),
        );
        await coordinator.refresh();
        expect(coordinator.state.value.phase, ConnectionPhase.connected);

        expect(await service().reloadRunningSwitches(), isFalse);
        expect(host.requests, isEmpty);
      });

      test('reloads nothing while the store holds a switch on', () async {
        final stored = ConnectionConfiguration(
          connection: ConnectionSettings(
            trafficMode: TrafficMode.smart,
            smart: SmartRoutingSettings(
              directRegions: const ['CN'],
              directApple: true,
              directWindows: false,
            ),
          ),
        );
        await settle(cnSwitchesOn, stored);

        expect(await service().reloadRunningSwitches(), isFalse);
        expect(host.requests, isEmpty);
        expect((await coordinator.configuration).encode(), stored.encode());
      });

      test('reloads nothing with several regions in the store or on the '
          'tunnel', () async {
        final severalOn = _config(TrafficMode.smart, const ['CN', 'RU']);
        final severalOff = ConnectionConfiguration(
          connection: ConnectionSettings(
            trafficMode: TrafficMode.smart,
            smart: SmartRoutingSettings(
              directRegions: const ['CN', 'RU'],
              directApple: false,
              directWindows: false,
            ),
          ),
        );
        for (final (running, stored) in [
          (cnSwitchesOn, severalOff),
          (severalOn, cnSwitchesOff),
          (severalOn, severalOff),
        ]) {
          await settle(running, stored);

          expect(await service().reloadRunningSwitches(), isFalse);
          expect(host.requests, isEmpty);
          expect((await coordinator.configuration).encode(), stored.encode());
        }
      });

      test('reloads a tunnel with only one switch on', () async {
        for (final (directApple, directWindows) in const [
          (true, false),
          (false, true),
        ]) {
          final running = ConnectionConfiguration(
            connection: ConnectionSettings(
              trafficMode: TrafficMode.smart,
              smart: SmartRoutingSettings(
                directRegions: const ['CN'],
                directApple: directApple,
                directWindows: directWindows,
              ),
            ),
          );
          host.requests.clear();
          await settle(running, cnSwitchesOff);

          expect(await service().reloadRunningSwitches(), isTrue);
          expect(host.requests, hasLength(1));
          expect(prepared!.configuration.encode(), cnSwitchesOff.encode());
        }
      });
    });

    test(
      'an Off pick over an allVpn store and tunnel reloads nothing',
      () async {
        final outcome = await service().apply(
          regionCode: null,
          confirmReconnect: confirm,
        );

        expect(outcome, OneVpnDirectRegionsOutcome.applied);
        expect(confirms, 0);
        expect(host.requests, isEmpty);
        expect(host.supportQueries, 0);
      },
    );

    test('that did not apply reports it and saves nothing', () async {
      host.onReload = (_) async => ReloadResult.rolledBack;

      final outcome = await service().apply(
        regionCode: 'CN',
        confirmReconnect: confirm,
      );

      expect(outcome, OneVpnDirectRegionsOutcome.rolledBack);
      expect(confirms, 0);
      expect(
        (await coordinator.configuration).encode(),
        running.configuration.encode(),
      );
    });

    test(
      'with no in-place reload asks through the reconnect callback',
      () async {
        final outcome = await service(supported: false)
            .apply(regionCode: 'CN', confirmReconnect: confirm);

        expect(outcome, OneVpnDirectRegionsOutcome.unchanged);
        expect(confirms, 1);
        expect(host.supportQueries, 0);
      },
    );

    test('with a double failure throws', () async {
      host.onReload = (_) async => ReloadResult.failed;

      await expectLater(
        service().apply(regionCode: 'CN', confirmReconnect: confirm),
        throwsA(isA<ConnectionHostException>()),
      );
      expect(confirms, 0);
      expect(coordinator.state.value.phase, ConnectionPhase.failed);
    });

    test('that falls back to Automatic reports it', () async {
      host.onReload = (_) async {
        start = prepared;
        return ReloadResult.applied;
      };

      final outcome = await service(notice: 'selectionReset')
          .apply(regionCode: 'CN', confirmReconnect: confirm);

      expect(outcome, OneVpnDirectRegionsOutcome.selectionReset);
      expect(confirms, 0);
    });

    test('superseded saves nothing and asks nothing', () async {
      host.onReload = (_) async => ReloadResult.superseded;

      final outcome = await service().apply(
        regionCode: 'CN',
        confirmReconnect: confirm,
      );

      expect(outcome, OneVpnDirectRegionsOutcome.unchanged);
      expect(confirms, 0);
      expect(
        (await coordinator.configuration).encode(),
        running.configuration.encode(),
      );
    });

    test('that finds no running core commits with no reconnect', () async {
      host.onReload = (_) async {
        status = VpnStatus.disconnected;
        start = null;
        return ReloadResult.notRunning;
      };

      final outcome = await service().apply(
        regionCode: 'CN',
        confirmReconnect: confirm,
      );

      expect(outcome, OneVpnDirectRegionsOutcome.applied);
      expect(confirms, 0);
      final stored = await coordinator.configuration;
      expect(stored.connection.smart.directRegions, ['CN']);
    });

    test('over a hold that arrives during the change lands red and commits '
        'nothing', () async {
      var heldNow = false;
      host.onReload = (_) async {
        // A network reload has already failed twice, so the TUN is held with
        // no core.
        status = VpnStatus.disconnected;
        heldNow = true;
        return ReloadResult.notRunning;
      };

      await expectLater(
        service(policyHeld: () async => heldNow)
            .apply(regionCode: 'CN', confirmReconnect: confirm),
        throwsA(
          isA<ConnectionHostException>().having(
            (error) => error.reason,
            'reason',
            'startFailed',
          ),
        ),
      );

      expect(confirms, 0);
      expect(stops, 0);
      // The held signal carries the red state. No failure latches.
      expect(coordinator.state.value.phase, isNot(ConnectionPhase.failed));
      expect(
        (await coordinator.configuration).encode(),
        running.configuration.encode(),
      );
    });
  });
}
