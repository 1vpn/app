// Pins the lost selection. An account location is lost once the account is
// signed out, no longer premium, or its list drops the location. While the
// account is premium and lists it, an account location stays, working or
// not. An empty account list keeps every account location. A free location stays
// while the catalogue lists it. Automatic is never lost. Disconnected, a
// lost location saves as Automatic with no connect. Connected, it reloads in
// place onto Automatic through the fresh prepare. An Automatic tunnel pinned
// on a deleted row re-measures through the fresh prepare. A kept location, a
// pin whose row remains, and an unsettled account change nothing.

import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/core/db/database/constants.dart';
import 'package:onexray/core/db/database/database.dart';
import 'package:onexray/core/pigeon/messages.g.dart';
import 'package:onexray/core/pigeon/model.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/catalogue/catalogue.dart';
import 'package:onexray/onevpn/catalogue/node_catalog.dart';
import 'package:onexray/onevpn/handover/handover.g.dart';
import 'package:onexray/onevpn/handover/reload_policy.dart';
import 'package:onexray/onevpn/model/user_data.dart';
import 'package:onexray/onevpn/reload/lost_selection.dart';
import 'package:onexray/service/connect/compiler.dart';
import 'package:onexray/service/connect/coordinator.dart';
import 'package:onexray/service/connect/runtime.dart';
import 'package:onexray/service/connect/runtime_host.dart';
import 'package:onexray/service/connect/settings.dart';

import '../account/support.dart';
import '../support/reload_fakes.dart';

/// A scripted native host. It logs each start and stop.
class _Host {
  VpnStatus status = VpnStatus.disconnected;
  ConnectionRuntime? active;
  final log = <String>[];

  Future<HostConnection> inspect(Iterable<ConnectionRuntime> _) async =>
      HostConnection(status, runtime: active);

  Future<HostConnection> start(ConnectionRuntime runtime) async {
    log.add('start');
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
  // The launch case initializes a coordinator, which observes the app
  // lifecycle through the widgets binding.
  TestWidgetsFlutterBinding.ensureInitialized();

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

  group('lost', () {
    const down = OneVpnApiLocation(
      city: 'Downtown',
      cityCode: 'dwn',
      country: 'Someland',
      countryCode: 'SL',
      servers: <OneVpnApiServer>[],
    );
    final lapsed = testSession(isPremium: false);
    final withDown = testSession(
      isPremium: true,
      locations: const [...testLocations, down],
    );
    final degraded = testSession(isPremium: true, locations: const []);
    const downStem = '1vpn·acct·dwn';

    test('the fixture holds a free and a premium stem, and a degraded '
        'catalogue', () {
      expect(premiumStem, startsWith('1vpn·acct·'));
      expect(freeStem, startsWith('1vpn·free·'));
      expect(OneVpnCatalogue.forSession(degraded).isDegraded, isTrue);
    });

    test('an account location is lost once the account is signed out or no '
        'longer premium', () {
      final selection = ServerSelection.location(premiumStem);
      expect(OneVpnLostSelection.lost(selection, null), isTrue);
      expect(OneVpnLostSelection.lost(selection, lapsed), isTrue);
    });

    test('a premium account keeps a location its list carries, working or '
        'not', () {
      expect(
        OneVpnLostSelection.lost(
          ServerSelection.location(premiumStem),
          premium,
        ),
        isFalse,
      );
      expect(
        OneVpnLostSelection.lost(
          const ServerSelection.location(downStem),
          withDown,
        ),
        isFalse,
      );
    });

    test('a location the account list drops is lost', () {
      expect(
        OneVpnLostSelection.lost(
          const ServerSelection.location(downStem),
          premium,
        ),
        isTrue,
      );
      expect(
        OneVpnLostSelection.lost(
          const ServerSelection.location('1vpn·acct·gone'),
          withDown,
        ),
        isTrue,
      );
    });

    test('an empty account list keeps every account location', () {
      for (final stem in [premiumStem, '1vpn·acct·gone']) {
        expect(
          OneVpnLostSelection.lost(ServerSelection.location(stem), degraded),
          isFalse,
          reason: stem,
        );
      }
    });

    test('a free location stays while the catalogue lists it', () {
      for (final session in [null, lapsed, premium, degraded]) {
        expect(
          OneVpnLostSelection.lost(ServerSelection.location(freeStem), session),
          isFalse,
        );
      }
      expect(
        OneVpnLostSelection.lost(
          const ServerSelection.location('1vpn·free·zzz'),
          null,
        ),
        isTrue,
      );
    });

    test('Automatic is never lost', () {
      expect(
        OneVpnLostSelection.lost(const ServerSelection.automatic(), null),
        isFalse,
      );
    });
  });

  group('run', () {
    late AppDatabase db;
    late _Host host;
    late ConnectionCoordinator coordinator;
    late ValueNotifier<OneVpnAccountState> live;
    late OneVpnReloadPolicy reloads;
    late OneVpnLostSelection hook;
    ConnectionRuntime? fresh;

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
        host.log.add('fresh ${host.status.name}');
        return fresh = _runtime(configuration, '${count++}');
      };
      await coordinator.initialize(observe: false);
      reloads = fakeReloadPolicy(
        host: FakeReloadHost()
          ..onReload = (_) async {
            host.log.add('reload');
            host.active = fresh;
            return ReloadResult.applied;
          },
        prepare: (_) => throw StateError('the move passes its own prepare'),
      );
      live = ValueNotifier<OneVpnAccountState>(OneVpnAccountSignedIn(premium));
      hook = OneVpnLostSelection(
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

    Future<ServerSelection> selection() async =>
        (await coordinator.configuration).connection.selection;

    test('signed out and disconnected, an account location saves as '
        'Automatic with no connect', () async {
      await select(ServerSelection.location(premiumStem));
      live.value = const OneVpnAccountSignedOut();

      await hook.run();

      expect(host.log, isEmpty);
      expect((await selection()).kind, SelectionKind.automatic);
      expect(coordinator.state.value.phase, ConnectionPhase.disconnected);
    });

    test('a lapsed premium tier with the tunnel up reloads in place onto '
        'Automatic', () async {
      await select(ServerSelection.location(premiumStem));
      await coordinator.connect();
      host.log.clear();
      live.value = OneVpnAccountSignedIn(testSession(isPremium: false));

      await hook.run();

      expect(host.log, ['fresh connected', 'reload']);
      expect((await selection()).kind, SelectionKind.automatic);
      expect(coordinator.state.value.phase, ConnectionPhase.connected);
    });

    test('a tunnel already up at launch reloads in place, with the '
        'coordinator not yet initialized', () async {
      // A second coordinator over the same store stands in for a fresh app
      // process. Its view reads disconnected until it initializes.
      await select(ServerSelection.location(premiumStem));
      await coordinator.connect();
      host.log.clear();
      var count = 10;
      final relaunched = ConnectionCoordinator(
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
        statusEvents: const Stream.empty(),
        observeStatus: () async {},
        disposeStatus: () {},
      )..freshConnectPrepare = coordinator.freshConnectPrepare;
      addTearDown(relaunched.dispose);
      expect(relaunched.state.value.phase, ConnectionPhase.disconnected);
      live.value = const OneVpnAccountSignedOut();

      await OneVpnLostSelection(
        coordinator: relaunched,
        accountState: live,
        reloads: reloads,
      ).run();

      expect(host.log, ['fresh connected', 'reload']);
      expect((await selection()).kind, SelectionKind.automatic);
    });

    test('an Automatic tunnel pinned on a deleted row re-measures in place '
        'after a lapse', () async {
      await select(const ServerSelection.automatic());
      await coordinator.connect();
      host.log.clear();
      live.value = OneVpnAccountSignedIn(testSession(isPremium: false));

      await hook.run();

      expect(host.log, ['fresh connected', 'reload']);
      expect((await selection()).kind, SelectionKind.automatic);
      expect(coordinator.state.value.phase, ConnectionPhase.connected);
    });

    test('an Automatic pin whose row remains, and an Automatic tunnel that '
        'is down, change nothing', () async {
      final id = await db
          .into(db.coreConfig)
          .insert(
            CoreConfigCompanion.insert(
              name: 'node-1',
              type: 'outbound',
              tags: '',
              delay: PingDelayConstants.unknown,
              subId: 0,
            ),
          );
      expect(id, 1);
      await select(const ServerSelection.automatic());
      await coordinator.connect();
      host.log.clear();
      live.value = OneVpnAccountSignedIn(testSession(isPremium: false));

      await hook.run();
      await coordinator.disconnect();
      host.log.clear();
      await db.delete(db.coreConfig).go();
      await hook.run();

      expect(host.log, isEmpty);
      expect((await selection()).kind, SelectionKind.automatic);
    });

    test('a premium account keeps its location', () async {
      await select(ServerSelection.location(premiumStem));

      await hook.run();

      expect(host.log, isEmpty);
      expect((await selection()).location, premiumStem);
    });

    test('an unsettled account changes nothing', () async {
      await select(ServerSelection.location(premiumStem));
      for (final state in [
        const OneVpnAccountRestoring(),
        const OneVpnAccountUnreadable('unreadable'),
      ]) {
        live.value = state;

        await hook.run();

        expect((await selection()).location, premiumStem);
      }
      expect(host.log, isEmpty);
    });
  });

  test('the move reloads in place and restarts no node', () {
    final source = File('lib/onevpn/reload/lost_selection.dart')
        .readAsStringSync()
        .replaceAll(RegExp(r'\s+'), ' ');
    expect(source, contains('oneVpnApplySelection('));
    for (final name in ['connect: true', 'runExclusive', 'addListener']) {
      expect(source, isNot(contains(name)), reason: name);
    }
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
