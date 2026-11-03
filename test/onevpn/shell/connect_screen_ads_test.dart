// The connect ad gate on the real connect screen, over a fake gateway.
//
// Screen entry refreshes the consent information with no form, then
// preloads. Where consent is required, entry loads nothing and the next tap
// shows the form and connects with no ad. A free connect tap after the
// first shows the cached ad, and the connect starts only after the ad
// closes. The close starts no load. A failed show cancels the connect. A
// tap with no cached ad connects at once and starts a load. The first
// connect tap ever shows no ad. A disconnect and a location change each
// start a preload. A tunnel start that is not the connect tap shows no ad.
// A declined permission skips the gate and connects as before. A second tap
// while the first tap's chain runs does nothing. A preload requested while
// the tunnel is up starts nothing. A resume while the ad still shows ends
// the chain with no connect after the grace, and the next tap runs fresh. A
// close before the resume connects as before. A resume with no ad showing
// does nothing. A tap inside the grace abandons the ad and connects. A
// return to the ad inside the grace abandons nothing.
//
// A free account's location switch while connected stops the tunnel with
// the pick, waits for the stop's load, shows the ad with the tunnel down,
// and connects on its close. A cached ad shows with no wait. A load that
// misses the bound connects with no ad. A failed show leaves the tunnel down
// on the pick. A first connect ever switches with no ad and stamps. The
// switch skips the once-ever censorship warning and notification ask. Both
// stay unstamped and run on the next Connect tap. A load that lands with the
// app out of front connects with no show and keeps the ad. Back in front, the
// ad shows. A show the user leaves connects to the pick once the grace ends
// it on the return, with no second ad. A start-shortcut launch inside the
// grace joins the switch's chain, which connects with no second ad. The
// launch runs no chain of its own. The stop shows no rating prompt. A
// Connect tap during the stop does nothing, and the switch runs on. A pick
// that arrives while a tap chain runs applies nothing. An exempt account's
// switch, a back-out, and a pick while the tunnel connects, holds, reads red
// or is down keep today's path. The screen renders at the reference handset
// size.

import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/core/db/database/database.dart';
import 'package:onexray/core/pigeon/messages.g.dart';
import 'package:onexray/core/tools/platform.dart';
import 'package:onexray/l10n/localizations/app_localizations.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/account/session.dart';
import 'package:onexray/onevpn/ads/ad_gateway.dart';
import 'package:onexray/onevpn/ads/connect_ad_gate.dart';
import 'package:onexray/onevpn/app/held_tunnel.dart';
import 'package:onexray/onevpn/catalogue/catalogue.dart';
import 'package:onexray/onevpn/handover/reload_policy.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations_en.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations_ru.dart';
import 'package:onexray/onevpn/location/location_picker_model.dart';
import 'package:onexray/onevpn/location/location_picker_page.dart';
import 'package:onexray/onevpn/model/user_data.dart';
import 'package:onexray/onevpn/paywall/paywall_cadence.dart';
import 'package:onexray/onevpn/paywall/paywall_trigger.dart';
import 'package:onexray/onevpn/rating/rating_prompt.dart';
import 'package:onexray/onevpn/shell/censorship_warning.dart';
import 'package:onexray/onevpn/shell/connect_control.dart';
import 'package:onexray/onevpn/shell/connect_screen.dart';
import 'package:onexray/onevpn/shell/first_connect_explainer.dart';
import 'package:onexray/onevpn/shell/notification_prompt.dart';
import 'package:onexray/onevpn/shell/routes.dart';
import 'package:onexray/onevpn/shell/start_shortcut.dart';
import 'package:onexray/pages/theme/theme.dart';
import 'package:onexray/service/connect/coordinator.dart';
import 'package:onexray/service/connect/runtime.dart';
import 'package:onexray/service/connect/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../ads/fake_ad_gateway.dart';
import '../support/held_tunnel_stub.dart';
import '../support/invoke_channel_stub.dart';
import '../support/localizations.dart';
import '../support/quick_actions_channel.dart';
import '../support/viewports.dart';

const _sgp = '1vpn·free·sgp';

/// A coordinator over [database] that logs each connect, disconnect, cancel
/// and apply into [log] and moves the phase. An apply that disconnects logs
/// `stop`, moves through disconnecting and commits. Any other apply logs
/// `apply` and commits. A held [connectGate] keeps each connect open once
/// it reads connected. A held [stopGate] keeps each stop open while it reads
/// disconnecting.
class _ScriptedCoordinator extends ConnectionCoordinator {
  _ScriptedCoordinator(AppDatabase database, this.log)
    : super(
        database: database,
        statusEvents: const Stream.empty(),
        observeStatus: () async {},
        disposeStatus: () {},
      );

  final List<String> log;

  /// Holds each connect open while set. The connect resolves once it
  /// completes.
  Completer<void>? connectGate;

  /// Holds each stop open while set. The stop commits once it completes.
  Completer<void>? stopGate;

  @override
  Future<void> connect() async {
    log.add('connect');
    state.value = const ConnectionView(phase: ConnectionPhase.connected);
    await connectGate?.future;
  }

  @override
  void cancel() {
    log.add('cancel');
    super.cancel();
  }

  @override
  Future<void> disconnect() async {
    log.add('disconnect');
    state.value = const ConnectionView(phase: ConnectionPhase.disconnected);
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
    log.add(disconnect ? 'stop' : 'apply');
    if (disconnect) {
      state.value = const ConnectionView(phase: ConnectionPhase.disconnecting);
      await stopGate?.future;
    }
    await db.connectionConfigDao.commit(configurationJson: next.encode());
    if (disconnect) {
      state.value = const ConnectionView(phase: ConnectionPhase.disconnected);
    }
  }
}

/// A reload policy that logs each in-place reload into [log] and answers
/// applied.
class _LoggingReloadPolicy extends OneVpnReloadPolicy {
  _LoggingReloadPolicy(this.log) : super(supported: true);

  final List<String> log;

  @override
  Future<OneVpnReloadResult> applyInPlace(
    ConnectionCoordinator coordinator,
    ConnectionConfiguration next, {
    required String expectedConfiguration,
    OneVpnReloadPrepare? prepare,
  }) async {
    log.add('reload');
    return (outcome: OneVpnReloadOutcome.applied, notice: null);
  }
}

/// An Android notifications plugin that counts each notification permission
/// request in [asks] and answers [answer]. A null answer leaves the prompt
/// unstamped, as a host with no Android plugin does.
class _CountingNotifications extends AndroidFlutterLocalNotificationsPlugin {
  bool? answer;
  int asks = 0;

  @override
  Future<bool?> requestNotificationsPermission() async {
    asks++;
    return answer;
  }
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

OneVpnSession _session({bool premium = false, DateTime? pendingSince}) =>
    OneVpnSession(
      sessionAuthToken: 'token',
      username: 'someone',
      email: 'someone@example.invalid',
      isPremium: premium,
      credentials: const OneVpnCredentials(
        uuid: '',
        publicKey: '',
        shortId: '',
      ),
      locations: const [],
      premiumPendingSince: pendingSince,
    );

/// The log without the preloads. A switch's commit also starts the location
/// preload, at a point the database decides.
List<String> _commands(List<String> log) =>
    log.where((entry) => entry != 'preload').toList();

class _EntitledAudience implements OneVpnPaywallAudience {
  @override
  bool get entitled => true;

  @override
  Future<void> whenRestored() async {}
}

/// The stored configuration with [selection].
String _configuration(ServerSelection selection) {
  final base = ConnectionConfiguration.fromJson({});
  return jsonEncode({
    ...base.toJson(),
    'connection': {
      ...base.connection.toJson(),
      'selection': selection.toJson(),
    },
  });
}

/// Resolves [future] by pumping frames. The database runs in the test's
/// fake-async zone, so its work advances only with the clock.
Future<T> _drain<T>(WidgetTester tester, Future<T> future) async {
  var done = false;
  late T value;
  future.then((result) {
    value = result;
    done = true;
  });
  for (var i = 0; i < 100 && !done; i++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
  expect(done, isTrue, reason: 'the future never finished');
  return value;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

/// Moves the app to the background and back, as a launcher relaunch does.
void _resume() {
  WidgetsBinding.instance
    ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
    ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
    ..handleAppLifecycleStateChanged(AppLifecycleState.paused)
    ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
    ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
    ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
}

void main() {
  late AppDatabase db;
  late _ScriptedCoordinator coordinator;
  late FakeAdGateway gateway;
  late List<String> log;
  late OneVpnHeldTunnel held;
  late ValueNotifier<bool> allDead;
  late FakeQuickActionsChannel channel;

  /// The native held answer the injected signal reads.
  var heldAnswer = false;

  /// The notifications plugin every notification ask reaches.
  late _CountingNotifications notifications;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    heldAnswer = false;
    FlutterLocalNotificationsPlatform.instance = notifications =
        _CountingNotifications();
  });

  Future<void> select(WidgetTester tester, ServerSelection selection) => _drain(
    tester,
    db.connectionConfigDao.commit(configurationJson: _configuration(selection)),
  );

  /// Mounts the connect screen for a signed-out user over [gateway], in
  /// [locale], with the app in front. With [firstConnectDone] the
  /// first-connect ad skip is already spent. With [connected] the tunnel is
  /// up at entry. The location picker reads [pickerAccount] over the free
  /// floor's rows. With [shortcut] the screen runs a start shortcut over
  /// [channel].
  Future<void> pump(
    WidgetTester tester, {
    bool firstConnectDone = true,
    bool loads = true,
    bool allowAds = true,
    bool connected = false,
    OneVpnAccountState pickerAccount = const OneVpnAccountSignedOut(),
    bool shortcut = false,
    Locale locale = const Locale('en'),
  }) async {
    // The store holds no session: the account state settles signed out.
    await tester.runAsync(OneVpnAccountService.instance.whenRestored);
    log = <String>[];
    gateway = FakeAdGateway(loads: loads, allowAds: allowAds, log: log);
    db = AppDatabase.forTesting(NativeDatabase.memory());
    coordinator = _ScriptedCoordinator(db, log);
    addTearDown(coordinator.dispose);
    if (connected) {
      coordinator.state.value = const ConnectionView(
        phase: ConnectionPhase.connected,
      );
    }
    await select(tester, const ServerSelection.automatic());
    await _drain(
      tester,
      SharedPreferencesAsync().setBool(
        OneVpnFirstConnectExplainer.seenKey,
        true,
      ),
    );
    if (firstConnectDone) {
      await _drain(
        tester,
        SharedPreferencesAsync().setBool(
          OneVpnConnectAdGate.firstConnectKey,
          true,
        ),
      );
    }
    stubInvokeChannel();
    stubHeldTunnelChannel();
    held = OneVpnHeldTunnel(read: () async => heldAnswer, supported: true);
    addTearDown(held.dispose);
    final measuring = ValueNotifier(false);
    addTearDown(measuring.dispose);
    allDead = ValueNotifier(false);
    addTearDown(allDead.dispose);
    final policy = _LoggingReloadPolicy(log);
    addTearDown(policy.state.dispose);
    OneVpnStartShortcut? start;
    if (shortcut) {
      channel = FakeQuickActionsChannel();
      start = OneVpnStartShortcut(mobile: true);
      await _drain(tester, start.initialize());
    }
    await setViewport(tester, kPortraitViewport);
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
            measuring: measuring,
            picksFastest: (_) => false,
            allDead: allDead,
            adGate: OneVpnConnectAdGate(gateway: gateway),
            paywallTrigger: OneVpnPaywallTrigger(
              cadence: OneVpnPaywallCadence(now: DateTime.now),
              audience: _EntitledAudience(),
            ),
            startShortcut: start,
          ),
        ),
        GoRoute(
          path: kOneVpnLocationRoute,
          builder: (_, state) => OneVpnLocationPickerPage(
            accountState: ValueNotifier(pickerAccount),
            serversStream: Stream.value([
              _node('1vpn·free·ams·1', 1),
              _node('1vpn·free·sgp·1', 2),
              _node('1vpn·free·lax·1', 3),
            ]),
            selectionStream: const Stream.empty(),
            initialSelection: state.extra is ServerSelection
                ? state.extra! as ServerSelection
                : null,
            coordinator: coordinator,
            reloadPolicy: policy,
            heldTunnel: held,
            measuring: measuring,
            allDead: allDead,
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    // Must run before the mount: the binding reports no lifecycle state
    // until a test drives one, and a switch shows its ad only once resumed.
    WidgetsBinding.instance.handleAppLifecycleStateChanged(
      AppLifecycleState.resumed,
    );
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light,
        locale: locale,
        localizationsDelegates: oneVpnLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await _settle(tester);
  }

  /// Unmounts the screen, closes the database, and runs out their timers.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpWidget(const SizedBox());
    await _drain(tester, db.close());
    await tester.pump();
  }

  Future<void> tapControl(WidgetTester tester) async {
    await tester.tap(find.byType(OneVpnConnectControl));
    await _settle(tester);
  }

  /// Opens the picker from the connect screen's location row.
  Future<void> openPicker(WidgetTester tester) async {
    await tester.tap(
      find
          .ancestor(
            of: find.byIcon(LucideIcons.chevronRightDir),
            matching: find.byType(InkWell),
          )
          .first,
    );
    await _settle(tester);
    expect(find.byType(OneVpnLocationPickerPage), findsOneWidget);
  }

  /// Opens the picker and taps Singapore, named [city] in the app language.
  Future<void> pickSingapore(
    WidgetTester tester, {
    String city = 'Singapore',
  }) async {
    await openPicker(tester);
    await tester.tap(find.text(city).first);
    await _settle(tester);
  }

  /// The stored once-ever flag under [key].
  Future<bool?> flag(WidgetTester tester, String key) =>
      _drain(tester, SharedPreferencesAsync().getBool(key));

  /// The stored selection, as JSON.
  Future<Map<String, dynamic>> stored(WidgetTester tester) async =>
      (await _drain(
        tester,
        coordinator.configuration,
      )).connection.selection.toJson();

  testWidgets('screen entry runs the update, with no form, then a preload', (
    tester,
  ) async {
    await pump(tester);

    expect(log.take(3), ['update', 'privacy', 'preload']);
    expect(gateway.sources, [OneVpnAdLoadSource.entry]);
    expect(gateway.count('update'), 1);
    expect(log, isNot(contains('form')));
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });

  testWidgets('a required form shows on the tap, which connects with no ad', (
    tester,
  ) async {
    await pump(tester, allowAds: false);
    expect(log, isNot(contains('form')));
    expect(log, isNot(contains('preload')));
    log.clear();

    await tapControl(tester);

    expect(log.first, 'form');
    expect(log, contains('connect'));
    expect(log, isNot(contains('preload')));
    expect(log, isNot(contains('show')));
    expect(log.indexOf('connect'), greaterThan(log.indexOf('form')));
    await unmount(tester);
  });

  testWidgets('a free tap shows the cached ad, then connects after it closes', (
    tester,
  ) async {
    await pump(tester);
    gateway.showGate = Completer<void>();
    log.clear();

    await tapControl(tester);
    // The ad is on screen. The connect waits.
    expect(log, ['show']);
    expect(coordinator.state.value.phase, ConnectionPhase.disconnected);

    gateway.showGate!.complete();
    await _settle(tester);

    expect(log, ['show', 'connect']);
    expect(coordinator.state.value.phase, ConnectionPhase.connected);
    await unmount(tester);
  });

  testWidgets('a failed show cancels the connect', (tester) async {
    await pump(tester);
    gateway.showResult = OneVpnAdShowResult.failed;
    log.clear();

    await tapControl(tester);

    expect(log, ['show']);
    expect(coordinator.state.value.phase, ConnectionPhase.disconnected);
    await unmount(tester);
  });

  testWidgets('a tap with no cached ad connects at once and starts a load', (
    tester,
  ) async {
    await pump(tester, loads: false);
    log.clear();

    await tapControl(tester);

    expect(log, ['preload', 'connect']);
    expect(log, isNot(contains('show')));
    await unmount(tester);
  });

  testWidgets('the first connect tap ever shows no ad', (tester) async {
    await pump(tester, firstConnectDone: false);
    log.clear();

    await tapControl(tester);

    expect(log, ['connect']);
    expect(
      await _drain(
        tester,
        SharedPreferencesAsync().getBool(OneVpnConnectAdGate.firstConnectKey),
      ),
      isTrue,
    );
    await unmount(tester);
  });

  testWidgets('a declined permission skips the gate and connects as before', (
    tester,
  ) async {
    // The host API answers not required on Linux and Windows without
    // prompting. The override runs the prompt on every test host.
    AppPlatform.debugOperatingSystemOverride = 'android';
    addTearDown(() => AppPlatform.debugOperatingSystemOverride = null);
    const channel = BasicMessageChannel<Object?>(
      'dev.flutter.pigeon.onexray.BridgeHostApi.requestPlatformPermission',
      BridgeHostApi.pigeonChannelCodec,
    );
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    var prompts = 0;
    messenger.setMockDecodedMessageHandler<Object?>(channel, (_) async {
      prompts++;
      return <Object?>[
        PlatformPermissionResult(
          kind: PlatformPermissionKind.androidVpn,
          state: PlatformPermissionState.denied,
        ),
      ];
    });
    addTearDown(
      () => messenger.setMockDecodedMessageHandler<Object?>(channel, null),
    );
    await pump(tester, firstConnectDone: false);
    coordinator.state.value = ConnectionView(
      phase: ConnectionPhase.failed,
      issue: 'permissionRequired',
      permission: PlatformPermissionResult(
        kind: PlatformPermissionKind.androidVpn,
        state: PlatformPermissionState.denied,
      ),
    );
    await _settle(tester);
    expect(gateway.isReady, isTrue);
    log.clear();

    await tapControl(tester);

    expect(prompts, 1);
    expect(log, ['connect']);
    // A consulted gate stamps the once-ever key on this first tap.
    expect(
      await _drain(
        tester,
        SharedPreferencesAsync().getBool(OneVpnConnectAdGate.firstConnectKey),
      ),
      isNull,
    );
    await unmount(tester);
  });

  testWidgets('a disconnect starts a preload and shows no ad', (tester) async {
    await pump(tester);
    coordinator.state.value = const ConnectionView(
      phase: ConnectionPhase.connected,
    );
    await _settle(tester);
    log.clear();

    await tapControl(tester);

    expect(log, ['disconnect', 'preload']);
    expect(gateway.sources.last, OneVpnAdLoadSource.disconnect);
    await unmount(tester);
  });

  testWidgets('a location change starts a preload', (tester) async {
    await pump(tester);
    log.clear();

    await select(tester, const ServerSelection.location('1vpn·free·ams'));
    await _settle(tester);

    expect(log, ['preload']);
    await unmount(tester);
  });

  testWidgets('a tunnel start that is not the connect tap shows no ad', (
    tester,
  ) async {
    await pump(tester);
    log.clear();

    // A reload or always-on start reaches the coordinator directly.
    await _drain(tester, coordinator.connect());
    await _settle(tester);

    expect(log, ['connect']);
    expect(gateway.isReady, isTrue);
    await unmount(tester);
  });

  testWidgets('a second tap during the ad runs no second chain', (
    tester,
  ) async {
    await pump(tester);
    gateway.showGate = Completer<void>();
    log.clear();

    await tapControl(tester);
    await tapControl(tester);
    expect(log, ['show']);

    gateway.showGate!.complete();
    await _settle(tester);

    expect(log, ['show', 'connect']);
    expect(gateway.count('show'), 1);
    await unmount(tester);
  });

  testWidgets('a location committed while connected starts no preload', (
    tester,
  ) async {
    await pump(tester, loads: false);
    await _drain(tester, coordinator.connect());
    await _settle(tester);
    log.clear();

    // A reload commits the pick with the tunnel up, as an exempt switch does.
    await select(tester, const ServerSelection.location('1vpn·free·ams'));
    await _settle(tester);

    expect(log, isEmpty);
    await unmount(tester);
  });

  testWidgets('screen entry while connected starts no update and no '
      'preload', (tester) async {
    await pump(tester, connected: true);

    expect(log, isNot(contains('update')));
    expect(log, isNot(contains('preload')));
    await unmount(tester);
  });

  testWidgets('a resume while the ad shows ends the chain with no connect, '
      'and the next tap connects', (tester) async {
    await pump(tester);
    final close = gateway.showGate = Completer<void>();
    log.clear();

    await tapControl(tester);
    expect(log, ['show']);

    _resume();
    await tester.pump(const Duration(seconds: 3));
    await _settle(tester);

    expect(log, ['show', 'abandon']);
    expect(coordinator.state.value.phase, ConnectionPhase.disconnected);

    // The guard is clear. No ad is cached, so the tap loads one and connects.
    log.clear();
    gateway.showGate = null;
    await tapControl(tester);

    expect(log, ['preload', 'connect']);
    expect(coordinator.state.value.phase, ConnectionPhase.connected);

    // The ad's close lands late and settles nothing.
    log.clear();
    close.complete();
    await _settle(tester);
    expect(log, isEmpty);
    expect(gateway.showsSettled, 1);
    await unmount(tester);
  });

  testWidgets('a close before the resume connects and abandons nothing', (
    tester,
  ) async {
    await pump(tester);
    gateway.showGate = Completer<void>();
    log.clear();

    await tapControl(tester);
    gateway.showGate!.complete();
    await _settle(tester);
    _resume();
    await tester.pump(const Duration(seconds: 3));
    await _settle(tester);

    expect(log, ['show', 'connect']);
    expect(coordinator.state.value.phase, ConnectionPhase.connected);
    await unmount(tester);
  });

  testWidgets('a resume with no ad showing does nothing', (tester) async {
    await pump(tester);
    log.clear();

    _resume();
    await tester.pump(const Duration(seconds: 3));
    await _settle(tester);

    expect(log, isEmpty);
    expect(gateway.isReady, isTrue);
    await unmount(tester);
  });

  testWidgets('a tap inside the grace abandons the ad and connects', (
    tester,
  ) async {
    await pump(tester);
    gateway.showGate = Completer<void>();
    log.clear();

    await tapControl(tester);
    _resume();
    await tester.pump(const Duration(milliseconds: 500));
    await tapControl(tester);

    expect(log, ['show', 'abandon', 'preload', 'connect']);
    expect(coordinator.state.value.phase, ConnectionPhase.connected);

    // The grace ended with the tap and abandons nothing later.
    await tester.pump(const Duration(seconds: 3));
    expect(log, ['show', 'abandon', 'preload', 'connect']);
    await unmount(tester);
  });

  testWidgets('a return to the ad inside the grace abandons nothing', (
    tester,
  ) async {
    await pump(tester);
    gateway.showGate = Completer<void>();
    log.clear();

    await tapControl(tester);
    _resume();
    await tester.pump(const Duration(seconds: 1));
    // Recents brings the ad back in front of the screen.
    WidgetsBinding.instance
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump(const Duration(seconds: 5));
    expect(log, ['show']);

    gateway.showGate!.complete();
    await _settle(tester);

    expect(log, ['show', 'connect']);
    WidgetsBinding.instance
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await unmount(tester);
  });

  group('a free location switch', () {
    final l = OneVpnLocalizationsEn();
    final singapore = const ServerSelection.location(_sgp).toJson();

    /// Connects through a tap that shows the cached ad, so the cache is
    /// empty while connected. Clears the log.
    Future<void> connectAfterAd(WidgetTester tester) async {
      log.clear();
      await tapControl(tester);
      expect(log, ['show', 'connect']);
      expect(gateway.isReady, isFalse);
      log.clear();
    }

    /// Connects outside the tap chain, as the tile or always-on does, so the
    /// entry preload's ad stays cached. Clears the log.
    Future<void> connectWithAdCached(WidgetTester tester) async {
      await _drain(tester, coordinator.connect());
      await _settle(tester);
      expect(gateway.isReady, isTrue);
      log.clear();
    }

    testWidgets("stops, waits for the stop's load, shows the ad with the "
        'tunnel down, and connects on its close', (tester) async {
      await pump(tester);
      await connectAfterAd(tester);
      gateway
        ..loadGate = Completer<void>()
        ..showGate = Completer<void>();

      await pickSingapore(tester);
      // The stop committed the pick and started the disconnect preload.
      expect(_commands(log), ['stop', 'wait']);
      expect(log.indexOf('preload'), log.indexOf('stop') + 1);
      expect(gateway.sources, contains(OneVpnAdLoadSource.disconnect));
      expect(coordinator.state.value.phase, ConnectionPhase.disconnected);
      expect(find.text(l.onevpnDisconnected), findsOneWidget);
      expect(await stored(tester), singapore);

      gateway.loadGate!.complete();
      await _settle(tester);
      // The ad is on screen. The tunnel stays down.
      expect(_commands(log), ['stop', 'wait', 'show']);
      expect(coordinator.state.value.phase, ConnectionPhase.disconnected);
      expect(find.text(l.onevpnDisconnected), findsOneWidget);

      gateway.showGate!.complete();
      await _settle(tester);

      expect(_commands(log), ['stop', 'wait', 'show', 'connect']);
      expect(coordinator.state.value.phase, ConnectionPhase.connected);
      await unmount(tester);
    });

    testWidgets('with a cached ad shows it with no wait', (tester) async {
      await pump(tester);
      await connectWithAdCached(tester);

      await pickSingapore(tester);

      expect(_commands(log), ['stop', 'show', 'connect']);
      expect(coordinator.state.value.phase, ConnectionPhase.connected);
      expect(await stored(tester), singapore);
      await unmount(tester);
    });

    testWidgets('with no ad in the bound connects with no ad', (tester) async {
      await pump(tester);
      await connectAfterAd(tester);
      gateway.loadGate = Completer<void>();

      await pickSingapore(tester);
      expect(_commands(log), ['stop', 'wait']);
      await tester.pump(const Duration(seconds: 5));
      await _settle(tester);

      expect(_commands(log), ['stop', 'wait', 'connect']);
      expect(gateway.sources.last, OneVpnAdLoadSource.tap);
      expect(coordinator.state.value.phase, ConnectionPhase.connected);
      await unmount(tester);
    });

    testWidgets('a failed show leaves the tunnel down on the pick and shows '
        'no rating prompt', (tester) async {
      await pump(tester);
      await connectWithAdCached(tester);
      gateway.showResult = OneVpnAdShowResult.failed;

      await pickSingapore(tester);

      expect(_commands(log), ['stop', 'show']);
      expect(coordinator.state.value.phase, ConnectionPhase.disconnected);
      expect(find.text(l.onevpnDisconnected), findsOneWidget);
      // The location row names the pick.
      expect(find.text('Singapore'), findsWidgets);
      expect(await stored(tester), singapore);
      expect(find.byType(OneVpnRatingDialog), findsNothing);
      await unmount(tester);
    });

    for (final (name, account) in [
      ('premium', OneVpnAccountSignedIn(_session(premium: true))),
      (
        'pending-premium',
        OneVpnAccountSignedIn(_session(pendingSince: DateTime.utc(2026))),
      ),
      ('restoring', const OneVpnAccountRestoring() as OneVpnAccountState),
    ]) {
      testWidgets('a $name switch reloads in place with no gateway call', (
        tester,
      ) async {
        await pump(tester, connected: true, pickerAccount: account);
        log.clear();

        await pickSingapore(tester);

        expect(log, ['reload']);
        expect(coordinator.state.value.phase, ConnectionPhase.connected);
        expect(find.byType(OneVpnLocationPickerPage), findsNothing);
        await unmount(tester);
      });
    }

    testWidgets('a signed-in free switch runs as a signed-out one', (
      tester,
    ) async {
      await pump(tester, pickerAccount: OneVpnAccountSignedIn(_session()));
      await connectWithAdCached(tester);

      await pickSingapore(tester);

      expect(_commands(log), ['stop', 'show', 'connect']);
      await unmount(tester);
    });

    testWidgets('a free account that never tapped connect switches as its '
        'first connect, with no ad', (tester) async {
      await pump(tester, firstConnectDone: false);
      await connectWithAdCached(tester);

      await pickSingapore(tester);

      expect(_commands(log), ['stop', 'connect']);
      expect(gateway.isReady, isTrue);
      expect(
        await _drain(
          tester,
          SharedPreferencesAsync().getBool(OneVpnConnectAdGate.firstConnectKey),
        ),
        isTrue,
      );
      await unmount(tester);
    });

    /// Singapore's name in Russian, where the censorship warning applies.
    String russianSingapore() => OneVpnLocationNaming.citiesByStem(
      OneVpnCatalogue.forSession(null),
      OneVpnLocalizationsRu(),
    )[_sgp]!;

    testWidgets('skips the once-ever warning and notification ask, which '
        'stay unstamped', (tester) async {
      notifications.answer = true;
      await pump(tester, locale: const Locale('ru'));
      await connectWithAdCached(tester);

      await pickSingapore(tester, city: russianSingapore());

      expect(_commands(log), ['stop', 'show', 'connect']);
      expect(find.byType(OneVpnCensorshipWarningDialog), findsNothing);
      expect(notifications.asks, 0);
      expect(await flag(tester, OneVpnCensorshipWarning.seenKey), isNull);
      expect(await flag(tester, OneVpnNotificationPrompt.askedKey), isNull);
      await unmount(tester);
    });

    testWidgets('leaves the once-ever steps to the next Connect tap', (
      tester,
    ) async {
      notifications.answer = true;
      await pump(tester, locale: const Locale('ru'));
      // A stored answer ends the rating prompt. Its dialog otherwise covers
      // the control after the disconnect tap.
      await _drain(
        tester,
        SharedPreferencesAsync().setBool(OneVpnRatingPrompt.answerKey, true),
      );
      await connectWithAdCached(tester);
      await pickSingapore(tester, city: russianSingapore());
      await tapControl(tester);
      expect(_commands(log), ['stop', 'show', 'connect', 'disconnect']);
      log.clear();

      await tapControl(tester);
      // The warning shows first. The connect waits for its dismissal.
      expect(find.byType(OneVpnCensorshipWarningDialog), findsOneWidget);
      expect(await flag(tester, OneVpnCensorshipWarning.seenKey), isTrue);
      expect(notifications.asks, 0);
      expect(_commands(log), isEmpty);

      await tester.tap(
        find.descendant(
          of: find.byType(OneVpnCensorshipWarningDialog),
          matching: find.byType(FilledButton),
        ),
      );
      await _settle(tester);

      expect(notifications.asks, 1);
      expect(await flag(tester, OneVpnNotificationPrompt.askedKey), isTrue);
      expect(_commands(log), ['show', 'connect']);
      await unmount(tester);
    });

    testWidgets('out of front when the load lands connects with no show and '
        'keeps the ad', (tester) async {
      await pump(tester);
      await connectAfterAd(tester);
      gateway.loadGate = Completer<void>();

      await pickSingapore(tester);
      expect(_commands(log), ['stop', 'wait']);
      // Home during the wait.
      WidgetsBinding.instance
        ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
        ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
        ..handleAppLifecycleStateChanged(AppLifecycleState.paused);
      gateway.loadGate!.complete();
      await _settle(tester);

      expect(_commands(log), ['stop', 'wait', 'connect']);
      expect(gateway.isReady, isTrue);
      expect(coordinator.state.value.phase, ConnectionPhase.connected);
      expect(await stored(tester), singapore);

      // The return shows nothing.
      WidgetsBinding.instance
        ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
        ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
        ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await _settle(tester);

      expect(_commands(log), ['stop', 'wait', 'connect']);
      expect(gateway.isReady, isTrue);
      await unmount(tester);
    });

    testWidgets('back in front when the load lands shows the ad', (
      tester,
    ) async {
      await pump(tester);
      await connectAfterAd(tester);
      gateway.loadGate = Completer<void>();

      await pickSingapore(tester);
      expect(_commands(log), ['stop', 'wait']);
      // Home and back during the wait.
      _resume();
      gateway.loadGate!.complete();
      await _settle(tester);

      expect(_commands(log), ['stop', 'wait', 'show', 'connect']);
      expect(coordinator.state.value.phase, ConnectionPhase.connected);
      await unmount(tester);
    });

    testWidgets('a show the user leaves connects to the pick once the grace '
        'ends it on the return, with no second ad', (tester) async {
      await pump(tester);
      await connectWithAdCached(tester);
      gateway.showGate = Completer<void>();

      await pickSingapore(tester);
      expect(_commands(log), ['stop', 'show']);

      // Home once the ad shows. The tunnel stays down while the app is away.
      WidgetsBinding.instance
        ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
        ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
        ..handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 30));
      expect(_commands(log), ['stop', 'show']);
      expect(coordinator.state.value.phase, ConnectionPhase.disconnected);

      // The launcher brings the screen back without the ad.
      WidgetsBinding.instance
        ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
        ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
        ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(seconds: 3));
      await _settle(tester);

      // The reconnect starts no load and shows no second ad.
      expect(log.sublist(log.indexOf('abandon')), ['abandon', 'connect']);
      expect(gateway.count('show'), 1);
      expect(coordinator.state.value.phase, ConnectionPhase.connected);
      expect(await stored(tester), singapore);
      await unmount(tester);
    });

    testWidgets("a start-shortcut launch inside the grace joins the switch's "
        'chain', (tester) async {
      await pump(tester, shortcut: true);
      await connectWithAdCached(tester);
      gateway.showGate = Completer<void>();

      await pickSingapore(tester);
      expect(_commands(log), ['stop', 'show']);

      // The launch brings the app forward, then reaches the screen.
      _resume();
      await tester.pump(const Duration(milliseconds: 500));
      unawaited(channel.launch(OneVpnStartShortcut.type));
      await _settle(tester);

      // The switch connects. The launch runs no chain of its own.
      expect(log.sublist(log.indexOf('abandon')), ['abandon', 'connect']);
      expect(_commands(log), ['stop', 'show', 'abandon', 'connect']);
      expect(gateway.count('show'), 1);
      expect(notifications.asks, 0);
      expect(coordinator.state.value.phase, ConnectionPhase.connected);
      await unmount(tester);
    });

    testWidgets('a pick that arrives while a tap chain runs applies nothing', (
      tester,
    ) async {
      await pump(tester);
      final connect = coordinator.connectGate = Completer<void>();
      log.clear();

      // The tap's connect reads connected and has not returned.
      await tapControl(tester);
      expect(_commands(log), ['show', 'connect']);
      await pickSingapore(tester);

      expect(_commands(log), ['show', 'connect']);
      expect(find.byType(OneVpnLocationPickerPage), findsNothing);
      expect(await stored(tester), const ServerSelection.automatic().toJson());

      connect.complete();
      await _settle(tester);

      expect(_commands(log), ['show', 'connect']);
      expect(coordinator.state.value.phase, ConnectionPhase.connected);
      await unmount(tester);
    });

    testWidgets('a Connect tap during the stop does nothing, and the switch '
        'runs on', (tester) async {
      await pump(tester);
      await connectWithAdCached(tester);
      final stop = coordinator.stopGate = Completer<void>();

      await pickSingapore(tester);
      expect(_commands(log), ['stop']);
      expect(coordinator.state.value.phase, ConnectionPhase.disconnecting);

      await tapControl(tester);
      expect(_commands(log), ['stop']);

      stop.complete();
      await _settle(tester);

      expect(_commands(log), ['stop', 'show', 'connect']);
      expect(coordinator.state.value.phase, ConnectionPhase.connected);
      expect(await stored(tester), singapore);
      await unmount(tester);
    });

    testWidgets('a back-out from the picker changes nothing', (tester) async {
      await pump(tester);
      await connectWithAdCached(tester);

      await openPicker(tester);
      await tester.tap(find.byType(CloseButton));
      await _settle(tester);

      expect(log, isEmpty);
      expect(coordinator.state.value.phase, ConnectionPhase.connected);
      await unmount(tester);
    });

    for (final (name, arrange)
        in <(String, Future<void> Function(WidgetTester))>[
          (
            'connects',
            (tester) async {
              coordinator.state.value = const ConnectionView(
                phase: ConnectionPhase.connecting,
              );
              await _settle(tester);
            },
          ),
          (
            'holds',
            (tester) async {
              allDead.value = true;
              await _settle(tester);
            },
          ),
          (
            'reads red over a held TUN',
            (tester) async {
              heldAnswer = true;
              await _drain(tester, held.refresh());
              await _settle(tester);
            },
          ),
        ]) {
      testWidgets('a pick while the tunnel $name reloads in place with no '
          'stop and no ad', (tester) async {
        await pump(tester, connected: true);
        await arrange(tester);
        log.clear();

        await pickSingapore(tester);

        expect(log, ['reload']);
        await unmount(tester);
      });
    }

    testWidgets('a pick while the tunnel is down commits it and starts the '
        'location preload', (tester) async {
      await pump(tester);
      log.clear();

      await pickSingapore(tester);

      expect(log, ['apply', 'preload']);
      expect(gateway.sources.last, OneVpnAdLoadSource.location);
      expect(coordinator.state.value.phase, ConnectionPhase.disconnected);
      await unmount(tester);
    });
  });
}
