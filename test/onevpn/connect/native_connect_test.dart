// The native connect over fakes. The pick takes the lowest alive account
// delay, then the lowest alive free delay. A tie goes to the lower id. A run
// pins once every candidate reports, or at the window after the first alive
// result. No result by the cap holds until an alive result pins. A release
// pins only when the window closes. A rolled-back pin picks again once. The
// release from the hold and the repick each open the window again. A missed
// pin retries. The last missed pin holds. Six empty probe rounds in the
// hold stop the core and leave a failed view once the view settles, and an
// alive result restarts that count. A stop ends the run and releases
// its claim. A held core stays claimed while it shows. Measuring spans
// Phase 1 to the pin. A pin lands while the app is in the background.
// The reload prepare measures on a pick and keeps the node on a region
// change. A fresh measure probes the remembered domain. An unsupported
// platform pins with no measure.
// An expiring hold reads red until the stop and never reads connected.

import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/core/db/dao/connection_config.dart';
import 'package:onexray/core/db/database/constants.dart';
import 'package:onexray/core/db/database/database.dart';
import 'package:onexray/core/model/tun_json.dart';
import 'package:onexray/core/pigeon/messages.g.dart';
import 'package:onexray/core/pigeon/model.dart';
import 'package:onexray/onevpn/app/held_tunnel.dart';
import 'package:onexray/onevpn/connect/native_auto_contracts.dart';
import 'package:onexray/onevpn/connect/native_connect.dart';
import 'package:onexray/onevpn/handover/handover.g.dart';
import 'package:onexray/onevpn/handover/handover_host.dart';
import 'package:onexray/onevpn/handover/reload_policy.dart';
import 'package:onexray/onevpn/net/api_transport.dart';
import 'package:onexray/onevpn/net/probe_endpoints.dart';
import 'package:onexray/onevpn/routing/direct_regions_apply.dart';
import 'package:onexray/onevpn/shell/connect_control.dart';
import 'package:onexray/service/connect/compiler.dart';
import 'package:onexray/service/connect/coordinator.dart';
import 'package:onexray/service/connect/resolver.dart';
import 'package:onexray/service/connect/runtime.dart';
import 'package:onexray/service/connect/runtime_host.dart';
import 'package:onexray/service/connect/settings.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../support/reload_fakes.dart';

const _account = '1vpn·acct·ams';
const _free = '1vpn·free·ams';

/// The rows in scope: two account rows and one free row.
final _rows = [_row(1, _account), _row(2, _account), _row(3, _free)];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the pick', () {
    test('the pick takes the lowest alive account delay', () {
      final pick = OneVpnNativeConnect.pick(
        _set([
          _alive('app-cand-acct-1', 120),
          _alive('app-cand-acct-2', 45),
          _dead('app-cand-acct-4'),
          _alive('app-cand-free-3', 10),
          _alive('app-cand-acct-9', 1),
          _alive('block', 1),
        ]),
        account: {1, 2, 4},
        free: {3},
      );

      expect(pick?.id, 2);
      expect(pick?.account, isTrue);
      expect(pick?.delayMs, 45);
    });

    test('a free row wins only with no alive account row', () {
      final dead = [
        _dead('app-cand-acct-1'),
        _dead('app-cand-acct-2'),
        _alive('app-cand-free-3', 90),
        _alive('app-cand-free-5', 60),
      ];
      final free = OneVpnNativeConnect.pick(
        _set(dead),
        account: {1, 2},
        free: {3, 5},
      );
      expect(free?.id, 5);
      expect(free?.account, isFalse);

      final account = OneVpnNativeConnect.pick(
        _set([...dead, _alive('app-cand-acct-2', 300)]),
        account: {1, 2},
        free: {3, 5},
      );
      expect(account?.id, 2);
      expect(account?.account, isTrue);

      expect(
        OneVpnNativeConnect.pick(
          _set([_dead('app-cand-acct-1'), _dead('app-cand-free-3')]),
          account: {1},
          free: {3},
        ),
        isNull,
      );
    });

    test('ties break by lower id', () {
      expect(
        OneVpnNativeConnect.pick(
          _set([_alive('app-cand-acct-7', 50), _alive('app-cand-acct-3', 50)]),
          account: {3, 7},
          free: const {},
        )?.id,
        3,
      );
      expect(
        OneVpnNativeConnect.pick(
          _set([_alive('app-cand-free-8', 50), _alive('app-cand-free-4', 50)]),
          account: const {},
          free: {4, 8},
        )?.id,
        4,
      );
    });
  });

  group('a run', () {
    test('the pick fires when every candidate reports', () {
      return _fake((h) async {
        final measure = await h.connectMeasure();
        h.observatory.byTag = _byTag([
          _alive('app-cand-acct-1', 80),
          _alive('app-cand-acct-2', 40),
          _dead('app-cand-free-3'),
        ]);

        final outcome = h.run(measure);
        await h.pump(Duration.zero);

        expect(outcome.value, OneVpnPinOutcome.pinned);
        expect(h.observatory.reads, hasLength(1));
        expect(h.pinnedEntry, 2);
      });
    });

    test('the pick fires 1.5 s after the first alive result', () {
      return _fake((h) async {
        final measure = await h.connectMeasure();

        final outcome = h.run(measure);
        await h.pump(const Duration(seconds: 1));
        // The first alive result lands on the read at 1.25 s.
        h.observatory.byTag = _byTag([_alive('app-cand-acct-1', 80)]);
        await h.pump(OneVpnNativeConnect.pollInterval);
        h.observatory.byTag = _byTag([
          _alive('app-cand-acct-1', 80),
          _alive('app-cand-acct-2', 40),
        ]);
        await h.pump(const Duration(milliseconds: 1499));
        expect(outcome.value, isNull);
        expect(h.host.requests, isEmpty);

        await h.pump(const Duration(milliseconds: 1));
        expect(outcome.value, OneVpnPinOutcome.pinned);
        expect(h.host.requests, hasLength(1));
        expect(h.pinnedEntry, 2);
      });
    });

    test('no result by the cap holds and a later alive result pins', () {
      return _fake((h) async {
        final measure = await h.connectMeasure();
        h.observatory.byTag = _byTag([
          _dead('app-cand-acct-1'),
          _dead('app-cand-acct-2'),
          _dead('app-cand-free-3'),
        ]);

        final outcome = h.run(measure);
        h.connect.attach();
        await h.pump(
          OneVpnNativeConnect.allDeadCap - const Duration(milliseconds: 1),
        );
        expect(h.connect.allDead.value, isFalse);
        expect(h.connect.measuring.value, isTrue);

        await h.pump(const Duration(milliseconds: 1));
        expect(h.connect.allDead.value, isTrue);
        expect(h.connect.measuring.value, isFalse);
        expect(outcome.value, isNull);

        // The hold keeps reading the same measure core.
        await h.pump(OneVpnNativeConnect.allDeadCap);
        expect(h.built.map((round) => round.probeUrl), [
          ProbeEndpoints.urls.first,
        ]);
        expect(h.host.requests, isEmpty);
        expect(h.native.active!.identity, measure.identity);
        expect(h.observatory.reads.last, h.portOf(measure));
        expect(h.connect.allDead.value, isTrue);

        h.observatory.byTag = _byTag([_alive('app-cand-free-3', 70)]);
        // The account rows never report, so the pin waits the window.
        await h.pump(
          OneVpnNativeConnect.pollInterval +
              OneVpnNativeConnect.firstResultWindow,
        );
        expect(outcome.value, OneVpnPinOutcome.pinned);
        expect(h.pinnedEntry, 3);
        expect(h.connect.allDead.value, isFalse);
      });
    });

    test('the hold expires after six empty probe rounds: the core stops and '
        'a failed view remains that a tap connects from', () {
      return _fake((h) async {
        expect(OneVpnNativeConnect.holdRounds, 6);
        expect(OneVpnNativeConnect.holdCap, const Duration(minutes: 1));
        final measure = await h.connectMeasure();
        final outcome = await h.runToHold(measure);
        h.connect.attach();

        await h.pump(
          OneVpnNativeConnect.holdCap - OneVpnNativeConnect.pollInterval,
        );
        expect(outcome.value, isNull);
        expect(h.native.active?.identity, measure.identity);
        expect(h.connect.allDead.value, isTrue);

        await h.pump(OneVpnNativeConnect.pollInterval * 2);
        expect(outcome.value, OneVpnPinOutcome.expired);
        expect(h.native.active, isNull);
        expect(h.native.status, VpnStatus.disconnected);
        final view = h.coordinator.state.value;
        expect(view.phase, ConnectionPhase.failed);
        expect(view.issue, oneVpnHoldExpiredIssue);
        expect(view.runtime, isNull);
        expect(h.connect.allDead.value, isFalse);
        expect(h.connect.measuring.value, isFalse);
        expect(
          OneVpnConnectControlState.failureLine(view, held: false),
          isTrue,
        );
        expect(
          OneVpnConnectControlState.of(view, held: false),
          OneVpnConnectControlState.disconnected,
        );
        expect(view.canDisconnect, isFalse);

        // The expired run reads nothing more.
        final reads = h.observatory.reads.length;
        await h.pump(OneVpnNativeConnect.holdCap);
        expect(h.observatory.reads, hasLength(reads));
      });
    });

    test('an expiring hold reads red until the stop and never reads '
        'connected', () {
      return _fake((h) async {
        final measure = await h.connectMeasure();
        final outcome = await h.runToHold(measure);
        h.connect.attach();
        // Each state the control shows, and the stop, in order.
        final shown = <String>[];
        void record() {
          final state = OneVpnConnectControlState.of(
            h.coordinator.state.value,
            held: false,
            measuring: h.connect.measuring.value,
            allDead: h.connect.allDead.value,
          ).name;
          if (shown.isEmpty || shown.last != state) shown.add(state);
        }

        record();
        h.coordinator.state.addListener(record);
        h.connect.measuring.addListener(record);
        h.connect.allDead.addListener(record);
        h.native.onStop = () => shown.add('stop');

        await h.pump(
          OneVpnNativeConnect.holdCap + OneVpnNativeConnect.pollInterval,
        );

        expect(outcome.value, OneVpnPinOutcome.expired);
        expect(h.coordinator.state.value.issue, oneVpnHoldExpiredIssue);
        expect(shown, ['noConnection', 'disconnected', 'stop', 'disconnected']);
      });
    });

    test('an expiry waits while a command moves the measure core', () {
      return _fake((h) async {
        final measure = await h.connectMeasure();
        final outcome = await h.runToHold(measure);
        final connected = h.coordinator.state.value;

        // A command over the measure core shows it connecting.
        h.coordinator.state.value = ConnectionView(
          phase: ConnectionPhase.connecting,
          runtime: measure,
        );
        await h.pump(OneVpnNativeConnect.holdCap * 2);
        expect(outcome.value, isNull);
        expect(h.native.active?.identity, measure.identity);

        h.coordinator.state.value = connected;
        await h.pump(OneVpnNativeConnect.pollInterval * 2);
        expect(outcome.value, OneVpnPinOutcome.expired);
        expect(h.native.active, isNull);
      });
    });

    test('an alive result in the hold restarts the empty-round count', () {
      return _fake((h) async {
        final measure = await h.connectMeasure();
        final outcome = await h.runToHold(measure);
        final dead = h.observatory.byTag;

        await h.pump(OneVpnNativeConnect.holdCap - const Duration(seconds: 1));
        // One read sees an alive row that is dead again before the window
        // closes. Nothing pins.
        h.observatory.byTag = _byTag([_alive('app-cand-free-3', 70)]);
        await h.pump(OneVpnNativeConnect.pollInterval);
        h.observatory.byTag = dead;
        await h.pump(const Duration(seconds: 2));
        expect(outcome.value, isNull);
        expect(h.host.requests, isEmpty);

        await h.pump(OneVpnNativeConnect.holdCap - const Duration(seconds: 3));
        expect(outcome.value, isNull);
        expect(h.native.active?.identity, measure.identity);

        await h.pump(const Duration(seconds: 2));
        expect(outcome.value, OneVpnPinOutcome.expired);
        expect(h.native.active, isNull);
      });
    });

    test('a release with a partial set waits the window and pins the lowest '
        'row that reported inside it', () {
      return _fake((h) async {
        final measure = await h.connectMeasure();
        final outcome = await h.runToHold(measure);

        // One row answers first. The other rows still read their dead
        // entries from the hold.
        h.observatory.byTag = _byTag([
          _dead('app-cand-acct-1'),
          _alive('app-cand-acct-2', 946),
          _dead('app-cand-free-3'),
        ]);
        await h.pump(OneVpnNativeConnect.pollInterval);
        expect(outcome.value, isNull);

        h.observatory.byTag = _byTag([
          _alive('app-cand-acct-1', 250),
          _alive('app-cand-acct-2', 946),
          _dead('app-cand-free-3'),
        ]);
        await h.pump(
          OneVpnNativeConnect.firstResultWindow -
              const Duration(milliseconds: 1),
        );
        expect(outcome.value, isNull);
        expect(h.host.requests, isEmpty);
        expect(h.connect.allDead.value, isTrue);

        await h.pump(const Duration(milliseconds: 1));
        expect(outcome.value, OneVpnPinOutcome.pinned);
        expect(h.host.requests, hasLength(1));
        expect(h.pinnedEntry, 1);
        expect(h.connect.allDead.value, isFalse);
      });
    });

    test('a connected measure runtime starts one run', () {
      return _fake((h) async {
        h.connect.attach();
        final measure = await h.connectMeasure();
        await h.pump(Duration.zero);
        expect(h.observatory.reads, [h.portOf(measure)]);

        await h.settle(h.coordinator.refresh());
        await h.settle(h.coordinator.refresh());
        await h.pump(Duration.zero);
        expect(h.observatory.reads, hasLength(1));

        await h.pump(OneVpnNativeConnect.pollInterval);
        expect(h.observatory.reads, hasLength(2));
      });
    });

    test('a pinned runtime starts none', () {
      return _fake((h) async {
        h.native
          ..status = VpnStatus.connected
          ..active = h.pinnedRuntime(2);
        await h.settle(h.coordinator.refresh());
        expect(h.coordinator.state.value.phase, ConnectionPhase.connected);

        h.connect.attach();
        await h.pump(const Duration(seconds: 1));

        expect(h.observatory.reads, isEmpty);
        expect(h.connect.measuring.value, isFalse);
        // The listener records the pinned entry as the last pin.
        final resolved = await h.settle(
          h.connect.defaultResolver.resolve(h.configuration.connection),
        );
        expect(resolved.single.id, 2);
      });
    });

    test('the pin reloads through applyInPlace with the pinned prepare and '
        'commits', () {
      return _fake((h) async {
        final measure = await h.connectMeasure();
        final commits = h.db.commits;
        h.observatory.byTag = _byTag([
          _alive('app-cand-acct-1', 80),
          _alive('app-cand-acct-2', 40),
          _alive('app-cand-free-3', 20),
        ]);

        final outcome = h.run(measure);
        await h.pump(Duration.zero);

        expect(outcome.value, OneVpnPinOutcome.pinned);
        expect(h.host.requests, hasLength(1));
        // The pinned prepare resolves the pick alone. The policy's own
        // prepare throws, so the applied reload never ran it.
        expect(h.resolved.last, [2]);
        expect(h.db.commits, commits + 1);
        final pinned = h.coordinator.state.value.runtime!;
        expect(OneVpnNativeConnect.isMeasure(pinned), isFalse);
        expect(pinned.entries.single.id, 2);
        expect(pinned.request.tun?.toJson(), measure.request.tun?.toJson());
      });
    });

    test('a rolled-back pin picks again once', () {
      return _fake((h) async {
        final measure = await h.connectMeasure();
        h.host.onReload = (_) async => ReloadResult.rolledBack;
        h.observatory.byTag = _byTag([
          _alive('app-cand-acct-1', 40),
          _alive('app-cand-acct-2', 80),
          _alive('app-cand-free-3', 20),
        ]);

        final outcome = h.run(measure);
        await h.pump(const Duration(seconds: 1));

        expect(outcome.value, OneVpnPinOutcome.held);
        expect(h.host.requests, hasLength(2));
        expect(h.resolved.skip(1), [
          [1],
          [2],
        ]);
        expect(h.connect.allDead.value, isTrue);
        expect(h.native.active?.identity, measure.identity);
      });
    });

    test('a rolled-back repick waits the window', () {
      return _fake((h) async {
        final measure = await h.connectMeasure();
        final applied = h.host.onReload;
        h.host.onReload = (_) async {
          h.host.onReload = applied;
          return ReloadResult.rolledBack;
        };
        // The second account row never reports.
        h.observatory.byTag = _byTag([
          _alive('app-cand-acct-1', 40),
          _alive('app-cand-free-3', 20),
        ]);

        final outcome = h.run(measure);
        await h.pump(OneVpnNativeConnect.firstResultWindow);
        // The first window closes. Its pin rolls back. The repick opens the
        // window again.
        expect(h.host.requests, hasLength(1));
        expect(h.resolved.last, [1]);
        expect(outcome.value, isNull);

        await h.pump(
          OneVpnNativeConnect.firstResultWindow -
              const Duration(milliseconds: 1),
        );
        expect(h.host.requests, hasLength(1));
        expect(outcome.value, isNull);

        await h.pump(const Duration(milliseconds: 1));
        expect(outcome.value, OneVpnPinOutcome.pinned);
        expect(h.host.requests, hasLength(2));
        expect(h.pinnedEntry, 3);
      });
    });

    test('a stop during Phase 1 ends the run', () {
      return _fake((h) async {
        final measure = await h.connectMeasure();
        final outcome = h.run(measure);
        h.connect.attach();
        await h.pump(const Duration(milliseconds: 600));
        final reads = h.observatory.reads.length;
        expect(reads, 3);
        expect(h.connect.measuring.value, isTrue);

        await h.settle(h.coordinator.disconnect());
        await h.pump(OneVpnNativeConnect.allDeadCap * 2);

        expect(outcome.value, OneVpnPinOutcome.stopped);
        expect(h.observatory.reads, hasLength(reads));
        expect(h.host.requests, isEmpty);
        expect(h.built, hasLength(1));
        expect(h.connect.measuring.value, isFalse);
        expect(h.connect.allDead.value, isFalse);

        // A stop while Phase 1 prepares clears measuring and builds nothing.
        // The preparation answers a stop with the resolver's cancel.
        final fresh = h.nativeConnect();
        final seen = <bool>[];
        fresh.measuring.addListener(() => seen.add(fresh.measuring.value));
        h.onPrepare = () => throw const ConnectionResolutionException(
          ConnectionResolutionFailure.cancelled,
        );
        await expectLater(
          h.settle(fresh.prepare(h.configuration, Completer<void>().future)),
          throwsA(isA<ConnectionResolutionException>()),
        );
        expect(seen, [true, false]);
        expect(h.built, hasLength(1));
      });
    });

    test('a missed pin retries on the next read', () {
      return _fake((h) async {
        final measure = await h.connectMeasure();
        h.host.supported = false;
        h.observatory.byTag = _byTag([
          _alive('app-cand-acct-1', 80),
          _alive('app-cand-acct-2', 40),
          _dead('app-cand-free-3'),
        ]);

        final outcome = h.run(measure);
        await h.pump(Duration.zero);
        // The reload finds no core to reload. The measure core still shows.
        expect(h.host.supportQueries, 1);
        expect(outcome.value, isNull);
        expect(h.connect.measuring.value, isTrue);
        expect(h.coordinator.state.value.runtime?.identity, measure.identity);

        h.host.supported = true;
        await h.pump(OneVpnNativeConnect.pollInterval);
        expect(outcome.value, OneVpnPinOutcome.pinned);
        expect(h.host.supportQueries, 2);
        expect(h.pinnedEntry, 2);
      });
    });

    test('the last missed pin holds', () {
      return _fake((h) async {
        final measure = await h.connectMeasure();
        h.host.supported = false;
        h.observatory.byTag = _byTag([
          _alive('app-cand-acct-1', 80),
          _alive('app-cand-acct-2', 40),
          _dead('app-cand-free-3'),
        ]);

        final outcome = h.run(measure);
        await h.pump(
          OneVpnNativeConnect.pollInterval *
              (OneVpnNativeConnect.pinAttempts - 2),
        );
        expect(h.host.supportQueries, OneVpnNativeConnect.pinAttempts - 1);
        expect(outcome.value, isNull);

        await h.pump(OneVpnNativeConnect.pollInterval);
        expect(outcome.value, OneVpnPinOutcome.held);
        expect(h.host.supportQueries, OneVpnNativeConnect.pinAttempts);
        expect(h.host.requests, isEmpty);
        expect(h.connect.allDead.value, isTrue);
        expect(h.connect.measuring.value, isFalse);
        expect(h.coordinator.state.value.runtime?.identity, measure.identity);
      });
    });

    test('a measure core shown again after a stop starts a fresh run', () {
      return _fake((h) async {
        h.connect.attach();
        final measure = await h.connectMeasure();
        await h.pump(OneVpnNativeConnect.pollInterval);
        expect(h.observatory.reads, hasLength(2));

        await h.settle(h.coordinator.disconnect());
        await h.pump(OneVpnNativeConnect.pollInterval);
        final reads = h.observatory.reads.length;
        expect(h.connect.measuring.value, isFalse);

        // A replay of the stored start request shows the same identity.
        h.observatory.byTag = _byTag([
          _alive('app-cand-acct-1', 80),
          _alive('app-cand-acct-2', 40),
          _dead('app-cand-free-3'),
        ]);
        h.native
          ..status = VpnStatus.connected
          ..active = measure;
        await h.settle(h.coordinator.refresh());
        await h.pump(Duration.zero);

        expect(h.observatory.reads, hasLength(reads + 1));
        expect(h.pinnedEntry, 2);
        expect(h.connect.measuring.value, isFalse);
      });
    });

    test('a held core starts a fresh run once the coordinator leaves it', () {
      return _fake((h) async {
        final applied = h.host.onReload;
        h.host.onReload = (_) async => ReloadResult.rolledBack;
        h.observatory.byTag = _byTag([
          _alive('app-cand-acct-1', 40),
          _alive('app-cand-acct-2', 80),
          _alive('app-cand-free-3', 20),
        ]);
        h.connect.attach();
        final measure = await h.connectMeasure();
        await h.pump(Duration.zero);
        expect(h.host.requests, hasLength(2));
        expect(h.connect.allDead.value, isTrue);

        // A view that still shows the held core starts nothing.
        await h.settle(h.coordinator.refresh());
        await h.pump(OneVpnNativeConnect.pollInterval);
        final reads = h.observatory.reads.length;
        expect(h.host.requests, hasLength(2));
        expect(h.connect.allDead.value, isTrue);

        await h.settle(h.coordinator.disconnect());
        h.host.onReload = applied;
        h.native
          ..status = VpnStatus.connected
          ..active = measure;
        await h.settle(h.coordinator.refresh());
        await h.pump(Duration.zero);

        expect(h.observatory.reads, hasLength(reads + 1));
        expect(h.pinnedEntry, 1);
        expect(h.connect.allDead.value, isFalse);
      });
    });

    test('a pin lands while the app is in the background', () {
      return _fake((h) async {
        h.connect.attach();
        final measure = await h.connectMeasure();
        h.coordinator.didChangeAppLifecycleState(AppLifecycleState.paused);
        await h.pump(const Duration(seconds: 1));
        expect(h.observatory.reads, isNotEmpty);
        expect(h.pinnedEntry, isNull);

        h.observatory.byTag = _byTag([
          _alive('app-cand-acct-1', 80),
          _alive('app-cand-acct-2', 40),
          _dead('app-cand-free-3'),
        ]);
        await h.pump(OneVpnNativeConnect.pollInterval);

        expect(h.pinnedEntry, 2);
        expect(h.coordinator.state.value.phase, ConnectionPhase.connected);
        expect(h.connect.measuring.value, isFalse);
        expect(h.observatory.reads.toSet(), {h.portOf(measure)});
      });
    });

    test('measuring spans Phase 1 to the pin', () {
      return _fake((h) async {
        final seen = <String>[];
        h.connect.measuring.addListener(
          () => seen.add('measuring ${h.connect.measuring.value}'),
        );
        h.connect.attach();
        h.onPrepare = () => seen.add('prepare ${h.connect.measuring.value}');

        await h.connectMeasure();
        expect(seen, ['measuring true', 'prepare true']);
        await h.pump(const Duration(seconds: 2));
        expect(h.connect.measuring.value, isTrue);

        h.observatory.byTag = _byTag([
          _alive('app-cand-acct-1', 80),
          _dead('app-cand-acct-2'),
          _dead('app-cand-free-3'),
        ]);
        await h.pump(OneVpnNativeConnect.pollInterval);

        // The pin's own prepare still reads measuring.
        expect(h.pinnedEntry, 1);
        expect(seen, [
          'measuring true',
          'prepare true',
          'prepare true',
          'measuring false',
        ]);
        expect(h.connect.measuring.value, isFalse);
      });
    });
  });

  group('the prepares', () {
    test('the reload prepare measures on a pick and keeps the node on a '
        'region change', () {
      return _fake((h) async {
        final running = h.pinnedRuntime(2);
        final pick = reloadConfiguration(
          const ServerSelection.location(_account),
        );

        final measured = await h.settle(
          h.connect.reloadPrepare(h.coordinator, pick, running),
        );
        expect(OneVpnNativeConnect.isMeasure(measured), isTrue);
        expect(h.built.single.ids, [1, 2]);
        expect(h.built.single.probeUrl, ProbeEndpoints.urls.first);
        expect(h.connect.measuring.value, isTrue);

        final region = OneVpnDirectRegionsApplyService.nextConfiguration(
          running.configuration,
          'IR',
        );
        final kept = await h.settle(
          h.connect.reloadPrepare(h.coordinator, region, running),
        );
        expect(OneVpnNativeConnect.isMeasure(kept), isFalse);
        expect(kept.entries.single.id, 2);
        expect(kept.configuration.encode(), region.encode());
        expect(h.built, hasLength(1));

        // A region change over a running measure runtime measures again.
        final overMeasure = await h.settle(
          h.connect.reloadPrepare(
            h.coordinator,
            OneVpnDirectRegionsApplyService.nextConfiguration(
              measured.configuration,
              'IR',
            ),
            measured,
          ),
        );
        expect(OneVpnNativeConnect.isMeasure(overMeasure), isTrue);
        expect(h.built, hasLength(2));
      });
    });

    test('a picked location measures, one server included', () {
      return _fake((h) async {
        final one = await h.settle(
          h.connect.prepare(
            reloadConfiguration(const ServerSelection.location(_free)),
            Completer<void>().future,
          ),
        );
        expect(OneVpnNativeConnect.isMeasure(one), isTrue);
        expect(h.built.single.ids, [3]);
        expect(h.connect.measuring.value, isTrue);
      });
    });

    test('only an Automatic selection measures for the fastest server', () {
      return _fake((h) async {
        expect(
          h.connect.picksFastest(const ServerSelection.automatic()),
          isTrue,
        );
        expect(
          h.connect.picksFastest(const ServerSelection.location(_account)),
          isFalse,
        );
        expect(
          h
              .nativeConnect(supported: false)
              .picksFastest(const ServerSelection.automatic()),
          isFalse,
        );
      });
    });

    test('a fresh measure probes the remembered domain', () async {
      final previous = SharedPreferencesAsyncPlatform.instance;
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      addTearDown(() => SharedPreferencesAsyncPlatform.instance = previous);
      await const OneVpnPrefsDomainMemory().write('1vpn.co');

      return _fake((h) async {
        final measure = await h.settle(
          h.connect.prepare(h.configuration, Completer<void>().future),
        );
        expect(OneVpnNativeConnect.isMeasure(measure), isTrue);
        expect(h.built.single.probeUrl, 'https://1vpn.co/ping/');
      });
    });

    test('an unsupported platform prepares a pin with no measure', () {
      return _fake((h) async {
        final connect = h.nativeConnect(supported: false);
        final seen = <bool>[];
        connect.measuring.addListener(() => seen.add(connect.measuring.value));

        final lowest = await h.settle(
          connect.prepare(h.configuration, Completer<void>().future),
        );
        expect(lowest.entries.single.id, 1);
        expect(OneVpnNativeConnect.isMeasure(lowest), isFalse);

        // A connected pinned runtime records the last pin.
        h.native
          ..status = VpnStatus.connected
          ..active = h.pinnedRuntime(2);
        await h.settle(h.coordinator.refresh());
        connect.attach();
        final last = await h.settle(
          connect.prepare(h.configuration, Completer<void>().future),
        );
        expect(last.entries.single.id, 2);

        final elsewhere = await h.settle(
          connect.prepare(
            reloadConfiguration(const ServerSelection.location(_free)),
            Completer<void>().future,
          ),
        );
        expect(elsewhere.entries.single.id, 3);

        expect(h.built, isEmpty);
        expect(h.observatory.reads, isEmpty);
        expect(seen, isEmpty);
      });
    });
  });
}

/// Runs [body] on the fake clock over a fresh [_Harness].
///
/// Fake time moves only through [_Harness.pump] and [_Harness.settle].
/// Between the steps, [_rootMicrotasks] lets root-zone completions through,
/// such as a stream subscription's cancel. The database opens before the
/// fake clock starts and closes at teardown, on the real clock.
Future<void> _fake(Future<void> Function(_Harness h) body) async {
  final db = _Db();
  addTearDown(db.close);
  await db.executor.ensureOpen(db);
  final fake = FakeAsync();
  final result = Completer<void>();
  fake.run((async) {
    final h = _Harness(async, db);
    Future<void> scenario() async {
      await h.settle(h.coordinator.initialize(observe: false));
      await h.settle(
        h.db.connectionConfigDao.commit(
          configurationJson: h.configuration.encode(),
        ),
      );
      try {
        await body(h);
      } finally {
        h.coordinator.dispose();
      }
    }

    scenario().then(result.complete, onError: result.completeError);
  });
  var finished = false;
  result.future.then((_) => finished = true, onError: (_) => finished = true);
  while (!finished) {
    fake.flushMicrotasks();
    await Future<void>.delayed(Duration.zero);
  }
  return result.future;
}

/// Runs the root-zone microtasks queued so far.
///
/// It never yields to the event loop. Its cost is independent of other work
/// in the isolate.
Future<void> _rootMicrotasks() =>
    Zone.root.run(() => Future<void>.microtask(() {}));

/// The coordinator, the policy, and the native connect over fakes.
class _Harness {
  _Harness(this.async, this.db) {
    coordinator = ConnectionCoordinator(
      database: db,
      readRuntime: () async => native.active,
      inspect: native.inspect,
      inspectObserved: (_, observed) async => HostConnection(
        observed,
        runtime: observed == VpnStatus.disconnected ? null : native.active,
      ),
      start: native.start,
      stop: native.stop,
      prepare: (_, _) async => throw StateError('the default prepare'),
      statusEvents: const Stream.empty(),
      observeStatus: () async {},
      disposeStatus: () {},
    );
    host.onReload = (_) async {
      native.active = ConnectionRuntime.fromRequest(stage.staged!);
      return ReloadResult.applied;
    };
    reloads = OneVpnReloadPolicy(
      host: host,
      events: OneVpnHandoverEvents(),
      supported: true,
      prepare: (_, _, _) async => throw StateError('the policy prepare'),
      validate: (_) async => '',
      stage: stage,
      withFiles: (action) => action(),
      held: OneVpnHeldTunnel(read: () async => false, supported: true),
    );
    connect = nativeConnect();
  }

  final FakeAsync async;

  /// The open in-memory database. [_fake] owns its open and close.
  final _Db db;
  final native = _Native();
  final host = FakeReloadHost();
  final stage = _Stage();
  final observatory = _Observatory();
  late final ConnectionCoordinator coordinator;
  late final OneVpnReloadPolicy reloads;
  late final OneVpnNativeConnect connect;

  /// The stored configuration: Automatic over All via VPN.
  final configuration = reloadConfiguration(const ServerSelection.automatic());

  /// Each measure config the builder built.
  final built = <({List<int> ids, String probeUrl})>[];

  /// The ids each preparation resolved, in order.
  final resolved = <List<int>>[];

  /// Runs at the start of each preparation.
  void Function()? onPrepare;

  var _port = 18000;

  OneVpnNativeConnect nativeConnect({bool? supported}) => OneVpnNativeConnect(
    coordinator: coordinator,
    reloads: reloads,
    observatory: observatory,
    measureConfig: _measureConfig,
    supported: supported,
    rows: () => Stream.value(_rows),
    preparation: _prepare,
  );

  /// Settles [future] with no fake time passing and answers its value.
  Future<T> settle<T>(Future<T> future) async {
    var done = false;
    late T value;
    Object? error;
    StackTrace? stack;
    future.then(
      (result) {
        value = result;
        done = true;
      },
      onError: (Object e, StackTrace s) {
        error = e;
        stack = s;
        done = true;
      },
    );
    for (var i = 0; i < 200 && !done; i++) {
      async.elapse(Duration.zero);
      if (!done) await _rootMicrotasks();
    }
    if (!done) fail('the future never settled');
    if (error != null) Error.throwWithStackTrace(error!, stack!);
    return value;
  }

  /// Moves fake time on by [duration], one poll interval at a time. Each
  /// step drains the work it started before the next one.
  Future<void> pump(Duration duration) async {
    var left = duration;
    while (true) {
      final step = left < OneVpnNativeConnect.pollInterval
          ? left
          : OneVpnNativeConnect.pollInterval;
      async.elapse(step);
      left -= step;
      for (var i = 0; i < 100; i++) {
        await _rootMicrotasks();
        async.elapse(Duration.zero);
      }
      if (left <= Duration.zero) return;
    }
  }

  /// Runs the fresh prepare, starts its measure runtime on the native side,
  /// and publishes it. Answers the measure runtime.
  ///
  /// The start skips [ConnectionCoordinator.apply]: its geodata file lock is
  /// shared across tests and outlives each fake clock.
  Future<ConnectionRuntime> connectMeasure() async {
    final measure = await settle(
      connect.prepare(configuration, Completer<void>().future),
    );
    expect(OneVpnNativeConnect.isMeasure(measure), isTrue);
    native
      ..status = VpnStatus.connected
      ..active = measure;
    await settle(coordinator.refresh());
    expect(coordinator.state.value.phase, ConnectionPhase.connected);
    expect(coordinator.state.value.runtime?.identity, measure.identity);
    return measure;
  }

  /// Starts a run over [measure]. The holder takes its outcome.
  ValueNotifier<OneVpnPinOutcome?> run(ConnectionRuntime measure) {
    final outcome = ValueNotifier<OneVpnPinOutcome?>(null);
    connect.run(measure).then((value) => outcome.value = value);
    return outcome;
  }

  /// Starts a run over [measure] with every candidate dead. Moves fake time
  /// on until the hold stands. The holder takes the run's outcome.
  Future<ValueNotifier<OneVpnPinOutcome?>> runToHold(
    ConnectionRuntime measure,
  ) async {
    observatory.byTag = _byTag([
      _dead('app-cand-acct-1'),
      _dead('app-cand-acct-2'),
      _dead('app-cand-free-3'),
    ]);
    final outcome = run(measure);
    await pump(OneVpnNativeConnect.allDeadCap);
    expect(connect.allDead.value, isTrue);
    expect(outcome.value, isNull);
    return outcome;
  }

  /// The single entry of the pinned runtime the coordinator shows.
  int? get pinnedEntry {
    final runtime = coordinator.state.value.runtime;
    if (runtime == null || OneVpnNativeConnect.isMeasure(runtime)) return null;
    return runtime.entries.single.id;
  }

  int portOf(ConnectionRuntime runtime) =>
      int.parse(runtime.request.metricsPort!);

  /// A pinned runtime on the row [id], as the preparation builds it.
  ConnectionRuntime pinnedRuntime(int id) => _runtime(configuration, [
    ResolvedServer.fromRow(_rows.firstWhere((row) => row.id == id)),
  ]);

  Future<ConnectionRuntime> _prepare(
    ConnectionConfiguration configuration,
    ConnectionResolver resolver, {
    Future<void>? cancelled,
    void Function(Set<int>)? onResolved,
  }) async {
    onPrepare?.call();
    final entries = await resolver.resolve(
      configuration.connection,
      cancelled: cancelled,
    );
    onResolved?.call({for (final entry in entries) entry.id});
    resolved.add([for (final entry in entries) entry.id]);
    return _runtime(configuration, entries);
  }

  ConnectionRuntime _runtime(
    ConnectionConfiguration configuration,
    List<ResolvedServer> entries,
  ) {
    final port = '${++_port}';
    final compiled = CompiledConnection(
      xrayJson: jsonEncode({
        'metrics': {'listen': '127.0.0.1:$port'},
        'outbounds': [
          for (final (index, entry) in entries.indexed)
            {...entry.outbound..remove('name'), 'tag': 'app-entry-$index'},
        ],
      }),
      entries: entries,
      finalExit: null,
      nodeTags: const {},
    );
    return ConnectionRuntime.create(
      configuration: configuration,
      compiled: compiled,
      platform: ConnectionPlatform.android,
      request: StartVpnRequest(
        TunJson.fromJson({'tunDnsIPv4': '1.1.1.1', 'enableIPv6': false}),
        null,
        port,
        jsonEncode(
          LibXrayInvokeRequest(
            method: LibXrayMethod.runXray,
            payload: RunXrayRequest(compiled.xrayJson).toJson(),
          ).toJson(),
        ),
      ),
    );
  }

  Map<String, dynamic> _measureConfig({
    required Map<String, dynamic> pinned,
    required List<ResolvedServer> candidates,
    required String probeUrl,
  }) {
    built.add((
      ids: [for (final candidate in candidates) candidate.id],
      probeUrl: probeUrl,
    ));
    return {
      'metrics': pinned['metrics'],
      'outbounds': [
        {'tag': 'block', 'protocol': 'blackhole'},
        for (final candidate in candidates)
          {'tag': OneVpnCandidateTags.tagFor(candidate), 'protocol': 'freedom'},
        {'tag': 'direct', 'protocol': 'freedom'},
      ],
      'burstObservatory': {
        'subjectSelector': [OneVpnCandidateTags.prefix],
        'pingConfig': {'destination': probeUrl},
      },
    };
  }
}

/// The native side: it starts and stops at once.
class _Native {
  VpnStatus status = VpnStatus.disconnected;
  ConnectionRuntime? active;

  /// Runs at the start of each stop.
  void Function()? onStop;

  Future<HostConnection> inspect(Iterable<ConnectionRuntime> _) async =>
      HostConnection(
        status,
        runtime: status == VpnStatus.disconnected ? null : active,
      );

  Future<HostConnection> start(ConnectionRuntime runtime) async {
    status = VpnStatus.connected;
    active = runtime;
    return HostConnection(status, runtime: runtime);
  }

  Future<HostConnection> stop() async {
    onStop?.call();
    status = VpnStatus.disconnected;
    active = null;
    return const HostConnection(VpnStatus.disconnected);
  }
}

/// A stage that keeps the last staged request in memory.
class _Stage extends OneVpnReloadStage {
  StartVpnRequest? staged;

  @override
  Future<void> write(
    StartVpnRequest request, {
    required String requestId,
  }) async => staged = request;

  @override
  Future<void> clear() async {}
}

/// An observatory that answers [byTag] on every port.
class _Observatory implements OneVpnObservatorySource {
  Map<String, OneVpnObservation> byTag = const {};

  /// The port of each read, in order.
  final reads = <int>[];

  @override
  Future<OneVpnObservationSet> read(int port) async {
    reads.add(port);
    return OneVpnObservationSet(byTag: byTag, readAt: DateTime(2026));
  }
}

/// A database that counts configuration commits.
class _Db extends AppDatabase {
  _Db() : super.forTesting(NativeDatabase.memory());

  late final _dao = _CountingDao(this);

  int get commits => _dao.commits;

  @override
  ConnectionConfigDao get connectionConfigDao => _dao;
}

class _CountingDao extends ConnectionConfigDao {
  _CountingDao(super.db);

  int commits = 0;

  @override
  Future<void> commit({
    required String configurationJson,
    Future<void> Function()? writeAssets,
  }) {
    commits++;
    return super.commit(
      configurationJson: configurationJson,
      writeAssets: writeAssets,
    );
  }
}

OneVpnObservation _alive(String tag, int delayMs) =>
    OneVpnObservation(tag: tag, alive: true, delayMs: delayMs, all: 1, fail: 0);

OneVpnObservation _dead(String tag) =>
    OneVpnObservation(tag: tag, alive: false, delayMs: 0, all: 1, fail: 1);

Map<String, OneVpnObservation> _byTag(List<OneVpnObservation> observations) => {
  for (final observation in observations) observation.tag: observation,
};

OneVpnObservationSet _set(List<OneVpnObservation> observations) =>
    OneVpnObservationSet(byTag: _byTag(observations), readAt: DateTime(2026));

CoreConfigData _row(int id, String stem) => CoreConfigData(
  id: id,
  name: '$stem·$id',
  type: 'outbound',
  tags: 'vless',
  delay: PingDelayConstants.unknown,
  subId: 0,
  favorite: false,
  data: base64Encode(
    utf8.encode(
      jsonEncode({
        'outbounds': [
          {
            'tag': '$stem·$id',
            'protocol': 'socks',
            'settings': {'address': '127.0.0.1', 'port': 1080},
          },
        ],
      }),
    ),
  ),
);
