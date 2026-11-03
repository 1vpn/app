// The premium flip reloads in place on Automatic. Connected on a free
// location or on Automatic, the fresh prepare runs with the tunnel up. The
// reload then applies with no stop. A fresh prepare that fails keeps the
// node that ran. A reload that needs a reconnect restarts through the fresh
// prepare. Disconnected, a free location saves as Automatic with no
// connect, and Automatic stays. A premium location, a free session, and a
// session with no dialable account row change nothing. Mid-connect, the
// flip queues behind the connect. The reload owner runs the hook after the
// premium reprovision. An account change during the reprovision applies
// nothing: the live account decides.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/core/db/database/database.dart';
import 'package:onexray/core/pigeon/messages.g.dart';
import 'package:onexray/core/pigeon/model.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/catalogue/catalogue.dart';
import 'package:onexray/onevpn/catalogue/node_catalog.dart';
import 'package:onexray/onevpn/handover/handover.g.dart';
import 'package:onexray/onevpn/handover/reload_policy.dart';
import 'package:onexray/onevpn/model/user_data.dart';
import 'package:onexray/onevpn/provision/node_provisioner.dart';
import 'package:onexray/onevpn/reload/premium_selection.dart';
import 'package:onexray/onevpn/reload/reload_owner.dart';
import 'package:onexray/service/connect/compiler.dart';
import 'package:onexray/service/connect/coordinator.dart';
import 'package:onexray/service/connect/resolver.dart';
import 'package:onexray/service/connect/runtime.dart';
import 'package:onexray/service/connect/runtime_host.dart';
import 'package:onexray/service/connect/settings.dart';

import '../account/support.dart';
import '../support/reload_fakes.dart';

/// A reprovision that wrote nothing and reported nothing.
const _provisioned = OneVpnProvisionResult(nodes: [], errors: []);

/// A scripted native host. It logs each start and stop, and keeps each
/// started runtime. A start waits on [holdStart] once, when set.
class _Host {
  VpnStatus status = VpnStatus.disconnected;
  ConnectionRuntime? active;
  final log = <String>[];
  final starts = <ConnectionRuntime>[];
  Completer<void>? holdStart;

  Future<HostConnection> inspect(Iterable<ConnectionRuntime> _) async =>
      HostConnection(status, runtime: active);

  Future<HostConnection> start(ConnectionRuntime runtime) async {
    log.add('start');
    starts.add(runtime);
    final hold = holdStart;
    holdStart = null;
    if (hold != null) await hold.future;
    status = VpnStatus.connected;
    active = runtime;
    return HostConnection(status, runtime: runtime);
  }

  Future<HostConnection> stop() async {
    log.add('stop');
    status = VpnStatus.disconnected;
    active = null;
    return HostConnection(status);
  }
}

void main() {
  late AppDatabase db;
  late _Host host;
  late ConnectionCoordinator coordinator;
  late ValueNotifier<OneVpnAccountState> live;
  late FakeReloadHost reloadHost;
  late OneVpnReloadPolicy reloads;
  late OneVpnPremiumSelection hook;

  /// The runtime the last fresh prepare answered.
  ConnectionRuntime? fresh;

  final premium = testSession(isPremium: true);
  final pairs = oneVpnCatalogueDomainPairs(
    OneVpnCatalogue.forSession(premium).entries,
  );
  final freeStem = pairs
      .firstWhere((pair) => pair.entry.freeTier)
      .location
      .rowNameStem;
  final premiumStem = pairs
      .firstWhere((pair) => !pair.entry.freeTier)
      .location
      .rowNameStem;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    host = _Host();
    var count = 0;
    coordinator = ConnectionCoordinator(
      database: db,
      readRuntime: () async => host.active,
      inspect: host.inspect,
      inspectObserved: (_, observed) async =>
          HostConnection(observed, runtime: host.active),
      prepare: (configuration, _) async {
        host.log.add('default');
        return _runtime(configuration, '${count++}');
      },
      start: host.start,
      stop: host.stop,
    );
    coordinator.freshConnectPrepare = (configuration, _) async {
      // The log names the tunnel status the fresh prepare runs under.
      host.log.add('fresh ${host.status.name}');
      return fresh = _runtime(configuration, '${count++}');
    };
    await coordinator.initialize(observe: false);
    // The native side promotes the last fresh runtime over start.json.
    reloadHost = FakeReloadHost()
      ..onReload = (_) async {
        host.log.add('reload');
        host.active = fresh;
        return ReloadResult.applied;
      };
    reloads = fakeReloadPolicy(
      host: reloadHost,
      prepare: (_) => throw StateError('the flip passes its own prepare'),
    );
    live = ValueNotifier<OneVpnAccountState>(OneVpnAccountSignedIn(premium));
    hook = OneVpnPremiumSelection(
      coordinator: coordinator,
      accountState: live,
      reloads: reloads,
    );
  });
  tearDown(() async {
    reloads.state.dispose();
    live.dispose();
    coordinator.dispose();
    await db.close();
  });

  Future<void> select(ServerSelection selection) async {
    final current = await coordinator.configuration;
    await coordinator.apply(
      ConnectionConfiguration(
        connection: ConnectionSettings.fromJson({
          ...current.connection.toJson(),
          'selection': selection.toJson(),
        }),
        policy: current.policy,
      ),
    );
  }

  Future<void> connect() async {
    await coordinator.connect();
    expect(coordinator.state.value.phase, ConnectionPhase.connected);
    host.log.clear();
  }

  Future<ServerSelection> selection() async =>
      (await coordinator.configuration).connection.selection;

  test('the fixture holds a free and a premium stem', () {
    expect(freeStem, isNot(premiumStem));
  });

  group('connected', () {
    test('a free location reloads in place on Automatic through the fresh '
        'prepare', () async {
      await select(ServerSelection.location(freeStem));
      await connect();

      await hook.run(premium);

      expect(host.log, ['fresh connected', 'reload']);
      expect((await selection()).kind, SelectionKind.automatic);
      expect(
        host.active?.configuration.connection.selection.kind,
        SelectionKind.automatic,
      );
      expect(coordinator.state.value.phase, ConnectionPhase.connected);
      expect(coordinator.state.value.runtime?.identity, fresh?.identity);
    });

    test('Automatic reloads in place through the fresh prepare', () async {
      await select(const ServerSelection.automatic());
      await connect();

      await hook.run(premium);

      expect(host.log, ['fresh connected', 'reload']);
      expect((await selection()).kind, SelectionKind.automatic);
    });

    test('a fresh prepare that fails keeps the node that ran', () async {
      await select(ServerSelection.location(freeStem));
      await connect();
      final ran = host.active!;
      coordinator.freshConnectPrepare = (_, _) async {
        host.log.add('fresh ${host.status.name}');
        throw const ConnectionResolutionException(
          ConnectionResolutionFailure.selectionUnavailable,
        );
      };

      await hook.run(premium);

      expect(host.log, ['fresh connected']);
      expect(host.active?.identity, ran.identity);
      expect(coordinator.state.value.phase, ConnectionPhase.connected);
      expect((await selection()).location, freeStem);
    });

    test('a reload that needs a reconnect restarts through the fresh '
        'prepare', () async {
      await select(ServerSelection.location(freeStem));
      await connect();
      reloadHost.onReload = (_) async {
        host.log.add('reload');
        return ReloadResult.notSupported;
      };

      await hook.run(premium);

      expect(host.log, [
        'fresh connected',
        'reload',
        'stop',
        'fresh disconnected',
        'start',
      ]);
      expect((await selection()).kind, SelectionKind.automatic);
      expect(coordinator.state.value.phase, ConnectionPhase.connected);
    });

    test('a premium location stays', () async {
      await select(ServerSelection.location(premiumStem));
      await connect();

      await hook.run(premium);

      expect(host.log, isEmpty);
      expect((await selection()).location, premiumStem);
    });

    test('a free session changes nothing', () async {
      await select(ServerSelection.location(freeStem));
      await connect();

      await hook.run(testSession(isPremium: false));

      expect(host.log, isEmpty);
      expect((await selection()).location, freeStem);
    });

    test('a session with no dialable account row changes nothing', () async {
      await select(ServerSelection.location(freeStem));
      await connect();

      await hook.run(testSession(isPremium: true, locations: const []));
      await hook.run(
        testSession(isPremium: true).copyWith(
          credentials: const OneVpnCredentials(
            uuid: '',
            publicKey: '',
            shortId: '',
          ),
        ),
      );

      expect(host.log, isEmpty);
      expect((await selection()).location, freeStem);
    });
  });

  group('mid-connect', () {
    /// Starts a connect on Automatic and holds it in the connecting phase.
    Future<(Future<void>, Completer<void>)> holdConnect() async {
      await select(const ServerSelection.automatic());
      host.log.clear();
      final hold = host.holdStart = Completer<void>();
      final connecting = coordinator.connect();
      await pumpEventQueue();
      expect(coordinator.state.value.phase, ConnectionPhase.connecting);
      return (connecting, hold);
    }

    test('the flip queues, then reloads in place once the connect '
        'lands', () async {
      final (connecting, hold) = await holdConnect();

      final flip = hook.run(premium);
      await pumpEventQueue();
      hold.complete();
      await connecting;
      await flip;

      expect(host.log, [
        'fresh disconnected',
        'start',
        'fresh connected',
        'reload',
      ]);
      expect(host.starts, hasLength(1));
      expect(coordinator.state.value.phase, ConnectionPhase.connected);
    });

    test('a queued flip whose prepare fails keeps the node the connect '
        'started', () async {
      final (connecting, hold) = await holdConnect();
      coordinator.freshConnectPrepare = (_, _) async {
        host.log.add('fresh ${host.status.name}');
        throw const ConnectionResolutionException(
          ConnectionResolutionFailure.selectionUnavailable,
        );
      };

      final flip = hook.run(premium);
      await pumpEventQueue();
      hold.complete();
      await connecting;
      await flip;

      expect(host.log, ['fresh disconnected', 'start', 'fresh connected']);
      expect(host.starts, hasLength(1));
      expect(host.active?.identity, host.starts.single.identity);
      expect(coordinator.state.value.phase, ConnectionPhase.connected);
    });

    test('behind a cancelled connect, the flip commits only', () async {
      final (connecting, hold) = await holdConnect();

      final flip = hook.run(premium);
      await pumpEventQueue();
      coordinator.cancel();
      hold.complete();
      await expectLater(connecting, throwsA(isA<ConnectionHostException>()));
      await flip;

      expect(host.log, ['fresh disconnected', 'start', 'stop']);
      expect(host.active, isNull);
      expect((await selection()).kind, SelectionKind.automatic);
    });
  });

  group('disconnected', () {
    test('a free location saves as Automatic with no connect', () async {
      await select(ServerSelection.location(freeStem));
      host.log.clear();

      await hook.run(premium);

      expect(host.log, isEmpty);
      expect((await selection()).kind, SelectionKind.automatic);
      expect(coordinator.state.value.phase, ConnectionPhase.disconnected);
    });

    test('Automatic stays', () async {
      await select(const ServerSelection.automatic());
      host.log.clear();

      await hook.run(premium);

      expect(host.log, isEmpty);
      expect((await selection()).kind, SelectionKind.automatic);
    });
  });

  test('the hook reloads in place and restarts no node', () {
    final source = File('lib/onevpn/reload/premium_selection.dart')
        .readAsStringSync()
        .replaceAll(RegExp(r'\s+'), ' ');
    expect(source, contains('(reloads ?? OneVpnReloadPolicy.instance)'));
    expect(source, contains('.applyInPlace( coordinator, next,'));
    expect(source, contains('prepare: coordinator.freshConnectPrepare,'));
    for (final name in ['connect: true', 'runExclusive', 'addListener']) {
      expect(source, isNot(contains(name)), reason: name);
    }
  });

  group('the reload owner', () {
    late ValueNotifier<OneVpnAccountState> accountState;
    late List<String> events;

    OneVpnReloadOwner build(OneVpnAccountState initial) {
      accountState = ValueNotifier<OneVpnAccountState>(initial);
      addTearDown(accountState.dispose);
      events = [];
      return OneVpnReloadOwner(
        accountState: accountState,
        reprovision: (session) async {
          events.add('reprovision');
          return _provisioned;
        },
        onPremium: (session) async => events.add('premium'),
      )..register();
    }

    test('a premium baseline runs no hook on a location change', () async {
      build(OneVpnAccountSignedIn(premium));

      accountState.value = OneVpnAccountSignedIn(
        testSession(isPremium: true, locations: const []),
      );
      await pumpEventQueue();

      expect(events, ['reprovision']);
    });

    group('an account change during the reprovision', () {
      late Completer<void> held;
      Future<void>? flip;

      setUp(() async {
        await select(ServerSelection.location(freeStem));
        await connect();
        held = Completer<void>();
        flip = null;
        accountState = ValueNotifier<OneVpnAccountState>(
          OneVpnAccountSignedIn(testSession(isPremium: false)),
        );
        addTearDown(accountState.dispose);
        final real = OneVpnPremiumSelection(
          coordinator: coordinator,
          accountState: accountState,
          reloads: reloads,
        );
        var reprovisions = 0;
        OneVpnReloadOwner(
          accountState: accountState,
          reprovision: (_) async {
            if (reprovisions++ == 0) await held.future;
            return _provisioned;
          },
          onPremium: (session) => flip = real.run(session),
        ).register();
        accountState.value = OneVpnAccountSignedIn(premium);
        await pumpEventQueue();
      });

      Future<void> release() async {
        held.complete();
        await pumpEventQueue();
        expect(flip, isNotNull);
        await flip;
      }

      test('a sign-out applies nothing', () async {
        accountState.value = const OneVpnAccountSignedOut();
        await release();

        expect(host.log, isEmpty);
        expect((await selection()).location, freeStem);
      });

      test('a flip to free applies nothing', () async {
        accountState.value = OneVpnAccountSignedIn(
          testSession(isPremium: false),
        );
        await release();

        expect(host.log, isEmpty);
        expect((await selection()).location, freeStem);
      });
    });
  });
}

ConnectionRuntime _runtime(ConnectionConfiguration configuration, String n) {
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
    request: StartVpnRequest(null, null, '1800$n', jsonEncode(invoke.toJson())),
  );
}
