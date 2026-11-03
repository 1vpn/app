// The in-place reload on the connect screen and the picker, at 360x800 and
// 800x360. The picker's account is exempt from the ad gate, so a connected
// pick reloads with no dialog. The picker pops once
// the reload applies. The status label reads "Updating…" only for a reload
// that outlives the 300ms hold. The tapped row shows no spinner. It reads as
// selected at once and reverts when the change does not apply.
// A second tap during a reload does nothing. The location row
// keeps the running location until the reload is confirmed, also over the
// real staged bytes. A change that fails to apply keeps the picker open. It
// shows the rollback notice, also after the picker closes. A fallback to
// Automatic shows its notice. A superseded reload shows none. A reload that
// finds no core commits with no dialog. A double failure stays red from the
// native status through the reply. It returns to the connect screen and
// shows no notice. A network reload keeps the Connected label. A network
// double failure lands red with no notice. The native retry's status then
// returns the screen to connected.

import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/core/db/database/database.dart';
import 'package:onexray/core/pigeon/flutter_api.dart';
import 'package:onexray/core/pigeon/messages.g.dart';
import 'package:onexray/l10n/localizations/app_localizations.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/app/held_tunnel.dart';
import 'package:onexray/onevpn/feedback/connection_actions.dart';
import 'package:onexray/onevpn/handover/handover.g.dart';
import 'package:onexray/onevpn/handover/reload_policy.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations_en.dart';
import 'package:onexray/onevpn/location/location_picker_page.dart';
import 'package:onexray/onevpn/paywall/paywall_cadence.dart';
import 'package:onexray/onevpn/paywall/paywall_trigger.dart';
import 'package:onexray/onevpn/shell/connect_control.dart';
import 'package:onexray/onevpn/shell/connect_screen.dart';
import 'package:onexray/onevpn/shell/first_connect_explainer.dart';
import 'package:onexray/onevpn/shell/routes.dart';
import 'package:onexray/pages/theme/theme.dart';
import 'package:onexray/service/connect/coordinator.dart';
import 'package:onexray/service/connect/runtime.dart';
import 'package:onexray/service/connect/runtime_host.dart';
import 'package:onexray/service/connect/settings.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../support/held_tunnel_stub.dart';
import '../support/invoke_channel_stub.dart';
import '../support/localizations.dart';
import '../support/reload_fakes.dart';
import '../support/viewports.dart';

const _ams = '1vpn·free·ams';
const _sgp = '1vpn·free·sgp';

/// An event of the network reload `network-1-1`.
ReloadEvent _network(
  ReloadPhase phase, {
  ReloadResult result = ReloadResult.applied,
}) => ReloadEvent(
  requestId: 'network-1-1',
  trigger: ReloadTrigger.network,
  phase: phase,
  result: phase == ReloadPhase.finished ? result : null,
);

class _EntitledAudience implements OneVpnPaywallAudience {
  @override
  bool get entitled => true;

  @override
  Future<void> whenRestored() async {}
}

CoreConfigData _node(String name, int id) => CoreConfigData(
  id: id,
  name: name,
  type: 'outbound',
  tags: 'vless',
  delay: 20,
  subId: 0,
  countryCode: null,
  favorite: false,
  data: '',
);

List<CoreConfigData> _freeFloorRows() => [
  _node('$_ams·1', 1),
  _node('$_sgp·1', 2),
  _node('1vpn·free·lax·1', 3),
];

/// Resolves [future] by pumping frames. The database runs on the widget
/// test clock.
Future<T> _drain<T>(WidgetTester tester, Future<T> future) async {
  var done = false;
  late T value;
  Object? failure;
  future.then(
    (result) {
      value = result;
      done = true;
    },
    onError: (Object error) {
      failure = error;
      done = true;
    },
  );
  for (var i = 0; i < 200 && !done; i++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
  expect(done, isTrue, reason: 'the future never finished');
  if (failure != null) throw failure!;
  return value;
}

/// Resolves [future] as [_drain] does, and lets real file work complete
/// between frames.
Future<T> _drainReal<T>(WidgetTester tester, Future<T> future) async {
  var done = false;
  late T value;
  Object? failure;
  future.then(
    (result) {
      value = result;
      done = true;
    },
    onError: (Object error) {
      failure = error;
      done = true;
    },
  );
  for (var i = 0; i < 200 && !done; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 10));
  }
  expect(done, isTrue, reason: 'the future never finished');
  if (failure != null) throw failure!;
  return value;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

void main() {
  final l = OneVpnLocalizationsEn();

  // The shared account service is born outside the widget test clock.
  setUpAll(() => OneVpnAccountService.instance);

  late AppDatabase db;
  late ConnectionCoordinator coordinator;
  late FakeReloadHost host;
  late OneVpnReloadPolicy policy;
  late OneVpnHeldTunnel held;
  late ConnectionRuntime running;
  ConnectionRuntime? start;

  /// The runtime the policy prepared last.
  ConnectionRuntime? prepared;

  /// The notice the next prepared runtime carries.
  String? prepareNotice;
  var status = VpnStatus.connected;
  var heldAnswer = false;

  /// How many next status reads still answer connected.
  var staleReads = 0;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    status = VpnStatus.connected;
    heldAnswer = false;
    staleReads = 0;
    prepareNotice = null;
  });

  /// Mounts the connect screen, connected on Amsterdam, over a policy that
  /// reloads a pick onto metrics port 18002 and stages through [stage].
  Future<void> pump(
    WidgetTester tester,
    Size size, {
    OneVpnReloadStage? stage,
  }) async {
    db = AppDatabase.forTesting(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    addTearDown(db.close);
    await _drain(
      tester,
      SharedPreferencesAsync().setBool(
        OneVpnFirstConnectExplainer.seenKey,
        true,
      ),
    );
    running = reloadRuntime(
      reloadConfiguration(const ServerSelection.location(_ams)),
      metricsPort: '18001',
      entryName: '$_ams·1',
    );
    start = running;
    await _drain(
      tester,
      db.connectionConfigDao.commit(
        configurationJson: running.configuration.encode(),
      ),
    );
    host = FakeReloadHost();
    prepared = null;
    policy = fakeReloadPolicy(
      host: host,
      stage: stage,
      held: () async => heldAnswer,
      prepare: (next) => prepared = reloadRuntime(
        next,
        metricsPort: '18002',
        entryId: 2,
        notice: prepareNotice,
      ),
    )..attach();
    addTearDown(policy.events.close);
    held = OneVpnHeldTunnel(
      read: () async => heldAnswer,
      supported: true,
      pollInterval: const Duration(milliseconds: 10),
      releaseTimeout: const Duration(milliseconds: 200),
    );
    addTearDown(held.dispose);
    coordinator = ConnectionCoordinator(
      database: db,
      readRuntime: () async => start,
      inspect: (_) async {
        if (staleReads > 0) {
          staleReads--;
          return HostConnection(VpnStatus.connected, runtime: start);
        }
        return HostConnection(
          status,
          runtime: status == VpnStatus.disconnected ? null : start,
        );
      },
      inspectObserved: (_, observed) async => HostConnection(
        observed,
        runtime: observed == VpnStatus.disconnected ? null : start,
      ),
      statusEvents: AppFlutterApi().vpnStatusController.stream,
      observeStatus: () async {},
      disposeStatus: () {},
    )..keepTunnelOnFailedStart = true;
    addTearDown(coordinator.dispose);
    await _drain(tester, coordinator.initialize());
    stubInvokeChannel();
    stubHeldTunnelChannel();
    await setViewport(tester, size);
    final router = GoRouter(
      initialLocation: kOneVpnConnectRoute,
      routes: [
        GoRoute(
          path: kOneVpnConnectRoute,
          builder: (_, _) => OneVpnConnectScreen(
            coordinator: coordinator,
            database: db,
            heldTunnel: held,
            reloadPolicy: policy,
            paywallTrigger: OneVpnPaywallTrigger(
              cadence: OneVpnPaywallCadence(now: DateTime.now),
              audience: _EntitledAudience(),
            ),
          ),
        ),
        GoRoute(
          path: kOneVpnLocationRoute,
          builder: (_, state) => OneVpnLocationPickerPage(
            // Exempt as premium is: a free connected pick stops the tunnel.
            accountState: ValueNotifier(const OneVpnAccountRestoring()),
            serversStream: Stream.value(_freeFloorRows()),
            selectionStream: const Stream.empty(),
            initialSelection: state.extra is ServerSelection
                ? state.extra! as ServerSelection
                : null,
            coordinator: coordinator,
            reloadPolicy: policy,
            heldTunnel: held,
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light,
        locale: const Locale('en'),
        localizationsDelegates: oneVpnLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => ShadTheme(
          data: AppTheme.shad(Brightness.light),
          child: ShadToaster(child: child!),
        ),
        routerConfig: router,
      ),
    );
    await _settle(tester);
  }

  /// The connect screen's location row.
  Finder row() => find
      .ancestor(
        of: find.byIcon(LucideIcons.chevronRightDir, skipOffstage: false),
        matching: find.byType(InkWell, skipOffstage: false),
      )
      .first;

  /// The check mark in the picker row titled [title].
  Finder checkOn(String title) => find.descendant(
    of: find
        .ancestor(of: find.text(title), matching: find.byType(InkWell))
        .first,
    matching: find.byIcon(LucideIcons.check),
  );

  /// The row's first line.
  String rowName(WidgetTester tester) => tester
      .widgetList<Text>(
        find.descendant(
          of: row(),
          matching: find.byType(Text, skipOffstage: false),
        ),
      )
      .first
      .data!;

  /// The status label under the connect control.
  bool labelReads(String text) =>
      find.text(text, skipOffstage: false).evaluate().isNotEmpty;

  bool red(WidgetTester tester) =>
      OneVpnConnectControlState.of(coordinator.state.value, held: held.value) ==
      OneVpnConnectControlState.noConnection;

  /// Starts a pick of Singapore from the connect screen's context.
  Future<ConnectionConfiguration?> pickSingapore(WidgetTester tester) =>
      oneVpnApplyConnectionChange(
        tester.element(find.byType(OneVpnConnectScreen)),
        coordinator,
        {'selection': const ServerSelection.location(_sgp).toJson()},
        label: 'Singapore',
        held: held,
        reloadPolicy: policy,
      );

  /// The native side promotes the staged request over start.json.
  ReloadResult promote(ReloadResult answer) {
    start = prepared;
    return answer;
  }

  /// Pumps until the policy reaches [state].
  Future<void> until(WidgetTester tester, OneVpnReloadState state) async {
    for (var i = 0; i < 100 && policy.state.value != state; i++) {
      await tester.pump(const Duration(milliseconds: 5));
    }
    expect(policy.state.value, state);
  }

  for (final size in [kPortraitViewport, kLandscapeViewport]) {
    final at = '${size.width.toInt()}x${size.height.toInt()}';

    testWidgets('at $at a slow reload reads Updating after the hold and the '
        'row moves only once the reload is confirmed', (tester) async {
      await pump(tester, size);
      expect(rowName(tester), 'Amsterdam');
      final reply = Completer<ReloadResult>();
      host.onReload = (_) => reply.future;

      final change = pickSingapore(tester);
      await until(tester, OneVpnReloadState.reloading);
      await tester.pump(const Duration(milliseconds: 250));
      expect(labelReads(l.onevpnConnected), isTrue);
      expect(labelReads(l.onevpnStatusUpdating), isFalse);
      await tester.pump(const Duration(milliseconds: 60));
      expect(labelReads(l.onevpnStatusUpdating), isTrue);
      expect(labelReads(l.onevpnConnected), isFalse);
      expect(find.byType(Dialog), findsNothing);
      expect(rowName(tester), 'Amsterdam');

      reply.complete(promote(ReloadResult.applied));
      final saved = await _drain(tester, change);
      await _settle(tester);

      expect(saved?.connection.selection.location, _sgp);
      expect(rowName(tester), 'Singapore');
      expect(labelReads(l.onevpnStatusUpdating), isFalse);
      expect(labelReads(l.onevpnConnected), isTrue);
      expect(coordinator.state.value.runtime?.identity, prepared!.identity);
    });

    testWidgets('at $at an applied answer the identity does not confirm keeps '
        'the row and shows the rollback notice', (tester) async {
      await pump(tester, size);
      host.onReload = (_) async => ReloadResult.applied;

      final kept = await _drain(tester, pickSingapore(tester));
      await _settle(tester);

      expect(kept, isNull);
      expect(rowName(tester), 'Amsterdam');
      expect(
        find.widgetWithText(SnackBar, l.onevpnReloadRolledBack('Singapore')),
        findsOneWidget,
      );
      expect(policy.state.value, OneVpnReloadState.connected);
    });

    testWidgets('at $at a fast reload never reads Updating and moves the '
        'row once confirmed', (tester) async {
      await pump(tester, size);
      host.onReload = (_) async => promote(ReloadResult.applied);

      var done = false;
      ConnectionConfiguration? saved;
      pickSingapore(tester).then((value) {
        saved = value;
        done = true;
      });
      for (var i = 0; i < 200 && !done; i++) {
        await tester.pump(const Duration(milliseconds: 10));
        expect(labelReads(l.onevpnStatusUpdating), isFalse);
      }
      await _settle(tester);

      expect(done, isTrue);
      expect(saved?.connection.selection.location, _sgp);
      expect(rowName(tester), 'Singapore');
      expect(labelReads(l.onevpnConnected), isTrue);
      expect(find.byType(Dialog), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('at $at a connected pick reloads with no dialog and pops the '
        'picker', (tester) async {
      await pump(tester, size);
      host.onReload = (_) async => promote(ReloadResult.applied);

      await tester.tap(row());
      await _settle(tester);
      expect(find.byType(OneVpnLocationPickerPage), findsOneWidget);
      await tester.tap(find.text('Singapore').first);
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 10));
        expect(find.byType(Dialog), findsNothing);
      }
      await _settle(tester);

      expect(host.requests, hasLength(1));
      expect(find.byType(OneVpnLocationPickerPage), findsNothing);
      expect(rowName(tester), 'Singapore');
      expect(tester.takeException(), isNull);
    });

    testWidgets('at $at a change that did not apply keeps the picker open '
        'and shows the rollback notice', (tester) async {
      await pump(tester, size);
      host.onReload = (_) async => ReloadResult.rolledBack;

      await tester.tap(row());
      await _settle(tester);
      await tester.tap(find.text('Singapore').first);
      await _settle(tester);

      expect(find.byType(OneVpnLocationPickerPage), findsOneWidget);
      expect(
        find.widgetWithText(SnackBar, l.onevpnReloadRolledBack('Singapore')),
        findsOneWidget,
      );
      expect(find.byType(Dialog), findsNothing);
      expect(rowName(tester), 'Amsterdam');
      expect(coordinator.state.value.phase, ConnectionPhase.connected);
    });

    testWidgets('at $at a double failure stays red through the reply and '
        'shows no notice', (tester) async {
      await pump(tester, size);
      final afterStatus = Completer<void>();
      final afterFinished = Completer<void>();
      host.onReload = (id) async {
        status = VpnStatus.disconnected;
        heldAnswer = true;
        AppFlutterApi().vpnStatusController.add(VpnStatus.disconnected);
        await afterStatus.future;
        await policy.events.reloadEvent(
          ReloadEvent(
            requestId: id,
            trigger: ReloadTrigger.settings,
            phase: ReloadPhase.finished,
            result: ReloadResult.failed,
          ),
        );
        await afterFinished.future;
        return ReloadResult.failed;
      };

      final change = pickSingapore(tester);
      await until(tester, OneVpnReloadState.reloading);
      for (var i = 0; i < 10 && host.requests.isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      await tester.pump(const Duration(milliseconds: 20));
      expect(red(tester), isTrue);
      afterStatus.complete();
      await tester.pump(const Duration(milliseconds: 20));
      expect(red(tester), isTrue);
      afterFinished.complete();
      expect(await _drain(tester, change), isNull);
      await _settle(tester);

      expect(red(tester), isTrue);
      expect(labelReads(l.onevpnStatusConnectionFailed), isTrue);
      expect(
        tester.widget<Text>(find.byKey(OneVpnConnectScreen.detailKey)).data,
        isEmpty,
      );
      expect(find.byType(SnackBar), findsNothing);
      expect(rowName(tester), 'Amsterdam');
      expect(policy.state.value, OneVpnReloadState.connected);
    });

    testWidgets('at $at the tapped row reads selected at once and the reload '
        'keeps it', (tester) async {
      await pump(tester, size);
      await tester.tap(row());
      await _settle(tester);
      expect(checkOn('Amsterdam'), findsOneWidget);
      final reply = Completer<ReloadResult>();
      host.onReload = (_) => reply.future;

      await tester.tap(find.text('Singapore').first);
      await until(tester, OneVpnReloadState.reloading);
      await tester.pump();

      expect(checkOn('Singapore'), findsOneWidget);
      expect(checkOn('Amsterdam'), findsNothing);

      reply.complete(promote(ReloadResult.applied));
      await _settle(tester);

      expect(find.byType(OneVpnLocationPickerPage), findsNothing);
    });

    testWidgets('at $at a reload that does not apply restores the committed '
        'row', (tester) async {
      await pump(tester, size);
      await tester.tap(row());
      await _settle(tester);
      // An applied answer the identity does not confirm rolls the change back.
      host.onReload = (_) async => ReloadResult.applied;

      await tester.tap(find.text('Singapore').first);
      await _settle(tester);

      expect(find.byType(OneVpnLocationPickerPage), findsOneWidget);
      expect(checkOn('Amsterdam'), findsOneWidget);
      expect(checkOn('Singapore'), findsNothing);
      expect(
        find.widgetWithText(SnackBar, l.onevpnReloadRolledBack('Singapore')),
        findsOneWidget,
      );
    });

    testWidgets('at $at a second tap during a reload does nothing and the '
        'first pick applies', (tester) async {
      await pump(tester, size);
      final reply = Completer<ReloadResult>();
      host.onReload = (_) => reply.future;

      await tester.tap(row());
      await _settle(tester);
      await tester.tap(find.text('Singapore').first);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('Los Angeles'));
      await tester.pump(const Duration(milliseconds: 50));
      reply.complete(promote(ReloadResult.applied));
      await _settle(tester);

      expect(host.requests, hasLength(1));
      expect(find.byType(OneVpnLocationPickerPage), findsNothing);
      expect(rowName(tester), 'Singapore');
      // A second pick that queued would settle rolledBack with a notice.
      expect(find.byType(SnackBar), findsNothing);
      final stored = await _drain(tester, coordinator.configuration);
      expect(stored.connection.selection.location, _sgp);
    });

    testWidgets('at $at the tapped row shows no spinner while a reload '
        'holds', (tester) async {
      await pump(tester, size);
      final reply = Completer<ReloadResult>();
      host.onReload = (_) => reply.future;

      await tester.tap(row());
      await _settle(tester);
      await tester.tap(find.text('Singapore').first);
      await until(tester, OneVpnReloadState.reloading);
      await tester.pump(const Duration(milliseconds: 250));
      final progress = find.byType(CircularProgressIndicator);
      expect(progress, findsNothing);
      await tester.pump(const Duration(milliseconds: 60));
      expect(progress, findsNothing);

      reply.complete(promote(ReloadResult.applied));
      await _settle(tester);
      expect(progress, findsNothing);
      expect(find.byType(OneVpnLocationPickerPage), findsNothing);
    });

    testWidgets('at $at a double failure from the picker returns to the '
        'connect screen, red, with no notice', (tester) async {
      await pump(tester, size);
      host.onReload = (_) async {
        status = VpnStatus.disconnected;
        heldAnswer = true;
        AppFlutterApi().vpnStatusController.add(VpnStatus.disconnected);
        return ReloadResult.failed;
      };

      await tester.tap(row());
      await _settle(tester);
      await tester.tap(find.text('Singapore').first);
      await _settle(tester);

      expect(find.byType(OneVpnLocationPickerPage), findsNothing);
      expect(red(tester), isTrue);
      expect(find.text(l.onevpnStatusConnectionFailed), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(OneVpnConnectScreen.detailKey)).data,
        isEmpty,
      );
      expect(find.byType(SnackBar), findsNothing);
      expect(rowName(tester), 'Amsterdam');
    });

    testWidgets('at $at a hold that arrives during a pick returns to the '
        'connect screen, red, commits nothing, and clears on the retry', (
      tester,
    ) async {
      await pump(tester, size);
      host.onReload = (_) async {
        // A network reload failed twice first: no core runs to reload.
        status = VpnStatus.disconnected;
        heldAnswer = true;
        AppFlutterApi().vpnStatusController.add(VpnStatus.disconnected);
        return ReloadResult.notRunning;
      };

      await tester.tap(row());
      await _settle(tester);
      await tester.tap(find.text('Singapore').first);
      await _settle(tester);

      expect(find.byType(OneVpnLocationPickerPage), findsNothing);
      expect(red(tester), isTrue);
      expect(
        tester.widget<Text>(find.byKey(OneVpnConnectScreen.detailKey)).data,
        isEmpty,
      );
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(Dialog), findsNothing);
      expect(rowName(tester), 'Amsterdam');
      expect(heldAnswer, isTrue);
      final stored = await _drain(tester, coordinator.configuration);
      expect(stored.connection.selection.location, _ams);

      // The native retry's start returns the screen to Connected.
      status = VpnStatus.connected;
      heldAnswer = false;
      AppFlutterApi().vpnStatusController.add(VpnStatus.connected);
      await _settle(tester);
      expect(red(tester), isFalse);
      expect(labelReads(l.onevpnConnected), isTrue);
    });

    testWidgets('at $at the rollback notice shows after the picker closed '
        'during the reload', (tester) async {
      await pump(tester, size);
      final reply = Completer<ReloadResult>();
      host.onReload = (_) => reply.future;

      await tester.tap(row());
      await _settle(tester);
      await tester.tap(find.text('Singapore').first);
      await until(tester, OneVpnReloadState.reloading);
      await tester.tap(find.byType(CloseButton));
      await _settle(tester);
      expect(find.byType(OneVpnLocationPickerPage), findsNothing);
      reply.complete(ReloadResult.rolledBack);
      await _settle(tester);

      expect(
        find.widgetWithText(SnackBar, l.onevpnReloadRolledBack('Singapore')),
        findsOneWidget,
      );
      expect(rowName(tester), 'Amsterdam');
    });

    testWidgets('at $at a reload over the real staged file confirms the '
        'promoted bytes', (tester) async {
      final directory = Directory.systemTemp.createTempSync('onevpn-stage-');
      addTearDown(() => directory.deleteSync(recursive: true));
      final file = File('${directory.path}/${OneVpnReloadStage.fileName}');
      await pump(tester, size, stage: OneVpnReloadStage(file: file));
      host.onReload = (_) async {
        start = promotedRuntime(file);
        return ReloadResult.applied;
      };

      final saved = await _drainReal(tester, pickSingapore(tester));
      await _settle(tester);

      expect(saved?.connection.selection.location, _sgp);
      expect(start!.identity, prepared!.identity);
      expect(rowName(tester), 'Singapore');
      expect(directory.listSync(), isEmpty);
    });

    testWidgets('at $at a fallback to Automatic shows its notice and pops the '
        'picker', (tester) async {
      await pump(tester, size);
      prepareNotice = 'selectionReset';
      host.onReload = (_) async => promote(ReloadResult.applied);

      await tester.tap(row());
      await _settle(tester);
      await tester.tap(find.text('Singapore').first);
      await _settle(tester);

      expect(find.byType(OneVpnLocationPickerPage), findsNothing);
      expect(
        find.widgetWithText(SnackBar, l.onevpnSelectionReset('Singapore')),
        findsOneWidget,
      );
    });

    testWidgets('at $at a superseded reload keeps the picker open with no '
        'notice', (tester) async {
      await pump(tester, size);
      host.onReload = (_) async => ReloadResult.superseded;

      await tester.tap(row());
      await _settle(tester);
      await tester.tap(find.text('Singapore').first);
      await _settle(tester);

      expect(find.byType(OneVpnLocationPickerPage), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(Dialog), findsNothing);
      expect(rowName(tester), 'Amsterdam');
    });

    testWidgets('at $at no running core commits with no dialog while the '
        'view still reads connected', (tester) async {
      await pump(tester, size);
      // The native side has no core. The refresh after the reload still
      // reads the stale connected status.
      host.supported = false;
      status = VpnStatus.disconnected;
      staleReads = 1;

      final change = pickSingapore(tester);
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 10));
        expect(find.byType(Dialog), findsNothing);
      }
      final saved = await _drain(tester, change);
      await _settle(tester);

      expect(saved?.connection.selection.location, _sgp);
      expect(staleReads, 0);
      expect(host.requests, isEmpty);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('at $at a reload that finds no running core commits with no '
        'dialog', (tester) async {
      await pump(tester, size);
      host.onReload = (_) async {
        status = VpnStatus.disconnected;
        start = null;
        AppFlutterApi().vpnStatusController.add(VpnStatus.disconnected);
        return ReloadResult.notRunning;
      };

      await tester.tap(row());
      await _settle(tester);
      await tester.tap(find.text('Singapore').first);
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 10));
        expect(find.byType(Dialog), findsNothing);
      }
      await _settle(tester);

      expect(find.byType(OneVpnLocationPickerPage), findsNothing);
      expect(rowName(tester), 'Singapore');
      expect(find.byType(SnackBar), findsNothing);
      final stored = await _drain(tester, coordinator.configuration);
      expect(stored.connection.selection.location, _sgp);
    });

    testWidgets('at $at a network reload keeps the Connected label', (
      tester,
    ) async {
      await pump(tester, size);

      await policy.events.reloadEvent(_network(ReloadPhase.started));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        expect(labelReads(l.onevpnConnected), isTrue);
        expect(labelReads(l.onevpnStatusUpdating), isFalse);
      }
      expect(policy.state.value, OneVpnReloadState.connected);
      await policy.events.reloadEvent(_network(ReloadPhase.finished));
      await tester.pump(const Duration(milliseconds: 10));

      expect(labelReads(l.onevpnConnected), isTrue);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(Dialog), findsNothing);
      expect(host.requests, isEmpty);
    });

    testWidgets('at $at a network double failure lands red with no notice, '
        'and the policy never retries', (tester) async {
      await pump(tester, size);

      await policy.events.reloadEvent(_network(ReloadPhase.started));
      await tester.pump(const Duration(milliseconds: 20));
      status = VpnStatus.disconnected;
      heldAnswer = true;
      AppFlutterApi().vpnStatusController.add(VpnStatus.disconnected);
      await tester.pump(const Duration(milliseconds: 20));
      await policy.events.reloadEvent(
        _network(ReloadPhase.finished, result: ReloadResult.failed),
      );
      await _settle(tester);

      expect(red(tester), isTrue);
      expect(labelReads(l.onevpnStatusConnectionFailed), isTrue);
      expect(
        tester.widget<Text>(find.byKey(OneVpnConnectScreen.detailKey)).data,
        isEmpty,
      );
      expect(find.byType(SnackBar), findsNothing);
      expect(policy.state.value, OneVpnReloadState.connected);

      // The next network change starts the service over the held TUN.
      status = VpnStatus.connected;
      heldAnswer = false;
      AppFlutterApi().vpnStatusController.add(VpnStatus.connected);
      await _settle(tester);

      expect(red(tester), isFalse);
      expect(labelReads(l.onevpnConnected), isTrue);
      expect(find.byType(SnackBar), findsNothing);
      expect(host.requests, isEmpty);
      expect(host.supportQueries, 0);
      expect(rowName(tester), 'Amsterdam');
    });
  }
}
