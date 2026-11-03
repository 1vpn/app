// The start shortcut on the real connect screen, over a fake quick-actions
// channel and a fake ad gateway, for a signed-out user.
//
// The screen registers the shortcut with the Connect title in the app's
// locale. A launch with the tunnel down runs the tap chain once: a cached ad
// shows and the connect follows its close. The first launch ever stamps the
// first connect and shows no ad. A launch asks the VPN consent the
// coordinator reports. The resume that brings the app forward leaves the ad
// open. A launch during the ad outside the resume grace adds no second chain
// and abandons nothing. A launch inside the grace abandons the ad and
// connects, as a tap does. A launch during another step of a chain neither
// cancels nor reruns, the chain's connecting phase included. A launch while
// connecting, connected or held runs nothing, then or later. A failed start
// from a launch holds the TUN like a tap's. On a platform with no hold, a
// launch over a failed start connects, as a tap does. A cold start's launch
// runs once, after the screen's first frame. The screen renders at the
// reference handset size.

import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/core/db/database/database.dart';
import 'package:onexray/core/pigeon/flutter_api.dart';
import 'package:onexray/core/pigeon/messages.g.dart';
import 'package:onexray/core/tools/platform.dart';
import 'package:onexray/l10n/localizations/app_localizations.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/ads/ad_gateway.dart';
import 'package:onexray/onevpn/ads/connect_ad_gate.dart';
import 'package:onexray/onevpn/app/held_tunnel.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations_en.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations_ru.dart';
import 'package:onexray/onevpn/paywall/paywall_cadence.dart';
import 'package:onexray/onevpn/paywall/paywall_trigger.dart';
import 'package:onexray/onevpn/shell/connect_control.dart';
import 'package:onexray/onevpn/shell/connect_screen.dart';
import 'package:onexray/onevpn/shell/first_connect_explainer.dart';
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
import '../support/invoke_channel_stub.dart';
import '../support/localizations.dart';
import '../support/quick_actions_channel.dart';
import '../support/viewports.dart';

/// A coordinator over [database] that logs each command into [log] and
/// moves the phase. A set [startFails] makes the next connect fail its
/// start. A set [connectGate] holds the next connect in the connecting phase
/// until it completes.
class _ScriptedCoordinator extends ConnectionCoordinator {
  _ScriptedCoordinator(AppDatabase database, this.log)
    : super(
        database: database,
        statusEvents: const Stream.empty(),
        observeStatus: () async {},
        disposeStatus: () {},
      );

  final List<String> log;

  /// Runs inside a failing connect, before it throws.
  void Function()? startFails;

  /// Holds the next connect in the connecting phase until it completes.
  Completer<void>? connectGate;

  @override
  Future<void> connect() async {
    log.add('connect');
    final gate = connectGate;
    if (gate != null) {
      connectGate = null;
      state.value = const ConnectionView(phase: ConnectionPhase.connecting);
      await gate.future;
    }
    final fails = startFails;
    if (fails != null) {
      startFails = null;
      fails();
      state.value = const ConnectionView(
        phase: ConnectionPhase.failed,
        issue: 'startFailed',
      );
      throw StateError('start failed');
    }
    state.value = const ConnectionView(phase: ConnectionPhase.connected);
  }

  @override
  Future<void> disconnect() async {
    log.add('disconnect');
    state.value = const ConnectionView(phase: ConnectionPhase.disconnected);
  }

  @override
  void cancel() => log.add('cancel');
}

class _EntitledAudience implements OneVpnPaywallAudience {
  @override
  bool get entitled => true;

  @override
  Future<void> whenRestored() async {}
}

/// A start shortcut that records, at each attach, the scheduler phase and
/// whether the connect control is in the tree.
class _ProbeShortcut extends OneVpnStartShortcut {
  _ProbeShortcut() : super(mobile: true);

  final attaches = <(SchedulerPhase, bool)>[];

  @override
  void attach(VoidCallback handler) {
    attaches.add((
      SchedulerBinding.instance.schedulerPhase,
      find.byType(OneVpnConnectControl).evaluate().isNotEmpty,
    ));
    super.attach(handler);
  }
}

/// The log entries of the coordinator's commands and the ad's show.
const _commands = {'connect', 'disconnect', 'cancel', 'show'};

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

/// Moves the app to the background and back, as the tile's launch does.
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
  final l = OneVpnLocalizationsEn();
  late AppDatabase db;
  late _ScriptedCoordinator coordinator;
  late FakeAdGateway gateway;
  late FakeQuickActionsChannel channel;
  late List<String> log;

  /// The native held answer the injected signal reads.
  var heldAnswer = false;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    heldAnswer = false;
  });

  /// Mounts the connect screen for a signed-out user over [gateway], with a
  /// start shortcut over [channel]. With [firstConnectDone] the first-connect
  /// ad skip is already spent. [launchAction] is the cold start's launching
  /// shortcut, read before the screen mounts. [shortcut] replaces the
  /// shortcut the screen attaches to. With [hold] false the coordinator
  /// keeps no failed start's TUN and the held signal is unsupported, as on a
  /// platform with no hold. The app runs in [locale].
  Future<OneVpnStartShortcut> pump(
    WidgetTester tester, {
    bool firstConnectDone = true,
    bool loads = true,
    String? launchAction,
    OneVpnStartShortcut? shortcut,
    bool hold = true,
    Locale locale = const Locale('en'),
  }) async {
    // The store holds no session: the account state settles signed out.
    await tester.runAsync(OneVpnAccountService.instance.whenRestored);
    log = <String>[];
    gateway = FakeAdGateway(loads: loads, log: log);
    db = AppDatabase.forTesting(NativeDatabase.memory());
    coordinator = _ScriptedCoordinator(db, log)..keepTunnelOnFailedStart = hold;
    addTearDown(coordinator.dispose);
    final held = OneVpnHeldTunnel(
      read: () async => heldAnswer,
      supported: hold,
      pollInterval: const Duration(milliseconds: 10),
      releaseTimeout: const Duration(milliseconds: 200),
    );
    addTearDown(held.dispose);
    await _drain(
      tester,
      db.connectionConfigDao.commit(
        configurationJson: _configuration(const ServerSelection.automatic()),
      ),
    );
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
    channel = FakeQuickActionsChannel(launchAction: launchAction);
    final start = shortcut ?? OneVpnStartShortcut(mobile: true);
    await _drain(tester, start.initialize());
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
            adGate: OneVpnConnectAdGate(gateway: gateway),
            paywallTrigger: OneVpnPaywallTrigger(
              cadence: OneVpnPaywallCadence(now: DateTime.now),
              audience: _EntitledAudience(),
            ),
            startShortcut: start,
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
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
    return start;
  }

  /// Unmounts the screen, closes the database, and runs out their timers.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpWidget(const SizedBox());
    await _drain(tester, db.close());
    await tester.pump();
  }

  /// Delivers a start-shortcut launch from the platform and settles.
  Future<void> launch(WidgetTester tester) async {
    unawaited(channel.launch(OneVpnStartShortcut.type));
    await _settle(tester);
  }

  testWidgets('the screen registers the shortcut with the Connect title', (
    tester,
  ) async {
    await pump(tester);

    expect(channel.published.last, [
      {'type': 'startVpn', 'localizedTitle': 'Connect', 'icon': 'start_vpn'},
    ]);
    await unmount(tester);
  });

  testWidgets('the shortcut title is the Connect string of the app locale', (
    tester,
  ) async {
    final ru = OneVpnLocalizationsRu();
    expect(ru.onevpnConnect, isNot(l.onevpnConnect));
    await pump(tester, locale: const Locale('ru'));

    expect(channel.published.last, [
      {
        'type': 'startVpn',
        'localizedTitle': ru.onevpnConnect,
        'icon': 'start_vpn',
      },
    ]);
    await unmount(tester);
  });

  testWidgets('a launch with the tunnel down shows the cached ad, then '
      'connects once', (tester) async {
    await pump(tester);
    gateway.showGate = Completer<void>();
    log.clear();

    await launch(tester);
    // The ad is on screen. The connect waits.
    expect(log, ['show']);
    expect(coordinator.state.value.phase, ConnectionPhase.disconnected);

    gateway.showGate!.complete();
    await _settle(tester);

    expect(log, ['show', 'connect']);
    expect(coordinator.state.value.phase, ConnectionPhase.connected);
    await unmount(tester);
  });

  testWidgets('the first launch ever stamps the first connect and shows no '
      'ad', (tester) async {
    await pump(tester, firstConnectDone: false);
    log.clear();

    await launch(tester);

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

  testWidgets('a launch asks the VPN consent the coordinator reports', (
    tester,
  ) async {
    // The host API answers not required on Linux and Windows without
    // prompting. The override runs the prompt on every test host.
    AppPlatform.debugOperatingSystemOverride = 'android';
    addTearDown(() => AppPlatform.debugOperatingSystemOverride = null);
    const permission = BasicMessageChannel<Object?>(
      'dev.flutter.pigeon.onexray.BridgeHostApi.requestPlatformPermission',
      BridgeHostApi.pigeonChannelCodec,
    );
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    var prompts = 0;
    messenger.setMockDecodedMessageHandler<Object?>(permission, (_) async {
      prompts++;
      return <Object?>[
        PlatformPermissionResult(
          kind: PlatformPermissionKind.androidVpn,
          state: PlatformPermissionState.granted,
        ),
      ];
    });
    addTearDown(
      () => messenger.setMockDecodedMessageHandler<Object?>(permission, null),
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
    log.clear();

    await launch(tester);

    expect(prompts, 1);
    expect(log, ['connect']);
    await unmount(tester);
  });

  testWidgets('the resume that brings the app forward leaves the ad open', (
    tester,
  ) async {
    await pump(tester);
    gateway.showGate = Completer<void>();
    log.clear();

    unawaited(channel.launch(OneVpnStartShortcut.type));
    _resume();
    await tester.pump(const Duration(seconds: 3));
    await _settle(tester);

    expect(log, ['show']);

    gateway.showGate!.complete();
    await _settle(tester);

    expect(log, ['show', 'connect']);
    await unmount(tester);
  });

  testWidgets('a launch during the ad outside the grace adds no chain and '
      'abandons nothing', (tester) async {
    await pump(tester);
    gateway.showGate = Completer<void>();
    log.clear();

    await launch(tester);
    await launch(tester);
    expect(log, ['show']);

    gateway.showGate!.complete();
    await _settle(tester);

    expect(log, ['show', 'connect']);
    expect(gateway.count('show'), 1);
    await unmount(tester);
  });

  testWidgets('a launch inside the grace abandons the ad and connects', (
    tester,
  ) async {
    await pump(tester);
    gateway.showGate = Completer<void>();
    log.clear();

    await launch(tester);
    _resume();
    await tester.pump(const Duration(milliseconds: 500));
    await launch(tester);

    expect(log, ['show', 'abandon', 'preload', 'connect']);
    expect(coordinator.state.value.phase, ConnectionPhase.connected);

    // The grace ended with the launch and abandons nothing later.
    await tester.pump(const Duration(seconds: 3));
    expect(log, ['show', 'abandon', 'preload', 'connect']);
    await unmount(tester);
  });

  testWidgets('a launch during the VPN consent of a chain neither cancels '
      'nor reruns', (tester) async {
    // The host API answers not required on Linux and Windows without
    // prompting. The override runs the prompt on every test host.
    AppPlatform.debugOperatingSystemOverride = 'android';
    addTearDown(() => AppPlatform.debugOperatingSystemOverride = null);
    const permission = BasicMessageChannel<Object?>(
      'dev.flutter.pigeon.onexray.BridgeHostApi.requestPlatformPermission',
      BridgeHostApi.pigeonChannelCodec,
    );
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final answer = Completer<void>();
    var prompts = 0;
    messenger.setMockDecodedMessageHandler<Object?>(permission, (_) async {
      prompts++;
      await answer.future;
      return <Object?>[
        PlatformPermissionResult(
          kind: PlatformPermissionKind.androidVpn,
          state: PlatformPermissionState.granted,
        ),
      ];
    });
    addTearDown(
      () => messenger.setMockDecodedMessageHandler<Object?>(permission, null),
    );
    await pump(tester);
    coordinator.state.value = ConnectionView(
      phase: ConnectionPhase.failed,
      issue: 'permissionRequired',
      permission: PlatformPermissionResult(
        kind: PlatformPermissionKind.androidVpn,
        state: PlatformPermissionState.denied,
      ),
    );
    await _settle(tester);
    // The cached ad fails its show, so the chain ends with the tunnel down
    // and a rerun would run a second chain.
    gateway.showResult = OneVpnAdShowResult.failed;
    log.clear();

    await launch(tester);
    expect(prompts, 1);
    await launch(tester);
    expect(prompts, 1);
    expect(log, isEmpty);

    answer.complete();
    await _settle(tester);

    expect(prompts, 1);
    expect(log.where(_commands.contains), ['show']);
    expect(coordinator.state.value.phase, ConnectionPhase.failed);
    await unmount(tester);
  });

  testWidgets('a launch while connecting cancels nothing and connects '
      'nothing later', (tester) async {
    await pump(tester, loads: false);
    coordinator.state.value = const ConnectionView(
      phase: ConnectionPhase.connecting,
    );
    await _settle(tester);
    log.clear();

    await launch(tester);
    expect(log, isEmpty);

    coordinator.state.value = const ConnectionView(
      phase: ConnectionPhase.disconnected,
    );
    await _settle(tester);
    expect(log.where(_commands.contains), isEmpty);

    // The next launch with the tunnel down connects.
    await launch(tester);
    expect(log.where(_commands.contains), ['connect']);
    await unmount(tester);
  });

  testWidgets('a launch while a chain connects cancels nothing, and the chain '
      'connects once', (tester) async {
    await pump(tester, loads: false);
    final connecting = Completer<void>();
    coordinator.connectGate = connecting;
    log.clear();

    await launch(tester);
    expect(coordinator.state.value.phase, ConnectionPhase.connecting);
    expect(log.where(_commands.contains), ['connect']);

    await launch(tester);
    expect(log.where(_commands.contains), ['connect']);

    connecting.complete();
    await _settle(tester);

    expect(log.where(_commands.contains), ['connect']);
    expect(coordinator.state.value.phase, ConnectionPhase.connected);
    await unmount(tester);
  });

  testWidgets('a launch while connected disconnects nothing', (tester) async {
    await pump(tester, loads: false);
    coordinator.state.value = const ConnectionView(
      phase: ConnectionPhase.connected,
    );
    await _settle(tester);
    log.clear();

    await launch(tester);
    expect(log, isEmpty);
    expect(coordinator.state.value.phase, ConnectionPhase.connected);

    // The next launch with the tunnel down connects.
    coordinator.state.value = const ConnectionView(
      phase: ConnectionPhase.disconnected,
    );
    await _settle(tester);
    await launch(tester);
    expect(log.where(_commands.contains), ['connect']);
    await unmount(tester);
  });

  testWidgets('a launch over a held TUN releases nothing', (tester) async {
    heldAnswer = true;
    await pump(tester, loads: false);
    expect(find.text(l.onevpnStatusConnectionFailed), findsOneWidget);
    log.clear();

    await launch(tester);
    expect(log, isEmpty);

    // The notification releases the TUN. The next launch connects.
    heldAnswer = false;
    AppFlutterApi().vpnStatusController.add(VpnStatus.disconnected);
    await _settle(tester);
    await launch(tester);
    expect(log.where(_commands.contains), ['connect']);
    await unmount(tester);
  });

  testWidgets('a failed start from a launch holds the TUN like a tap', (
    tester,
  ) async {
    await pump(tester, firstConnectDone: false);
    coordinator.startFails = () => heldAnswer = true;
    log.clear();

    await launch(tester);

    expect(log, ['connect']);
    expect(find.text(l.onevpnStatusConnectionFailed), findsOneWidget);

    // The hold stands. The next launch leaves it in place.
    await launch(tester);
    expect(log, ['connect']);
    await unmount(tester);
  });

  testWidgets('on a platform with no hold a launch over a failed start '
      'connects', (tester) async {
    AppPlatform.debugOperatingSystemOverride = 'ios';
    addTearDown(() => AppPlatform.debugOperatingSystemOverride = null);
    await pump(tester, loads: false, hold: false);
    coordinator.state.value = const ConnectionView(
      phase: ConnectionPhase.failed,
      issue: 'startFailed',
    );
    await _settle(tester);
    expect(find.text(l.onevpnStatusConnectionFailed), findsOneWidget);
    log.clear();

    await launch(tester);

    expect(log.where(_commands.contains), ['connect']);
    expect(coordinator.state.value.phase, ConnectionPhase.connected);
    await unmount(tester);
  });

  testWidgets('a cold start launch runs once, after the first frame', (
    tester,
  ) async {
    final probe = _ProbeShortcut();
    await pump(
      tester,
      firstConnectDone: false,
      launchAction: OneVpnStartShortcut.type,
      shortcut: probe,
    );

    // One attach, after the frame that built the control.
    expect(probe.attaches, [(SchedulerPhase.postFrameCallbacks, true)]);
    expect(log.where(_commands.contains), ['connect']);
    expect(coordinator.state.value.phase, ConnectionPhase.connected);

    // The held launch is spent. Later frames run nothing more.
    await _settle(tester);
    expect(log.where(_commands.contains), ['connect']);
    await unmount(tester);
  });
}
