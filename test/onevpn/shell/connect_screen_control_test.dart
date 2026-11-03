// The connect control on the real connect screen.
//
// The screen mounts the sliding-pill control, and a tap runs the screen's
// connect action against a scripted coordinator. A disconnected tap
// connects, a connected tap disconnects, and a busy tap cancels. With the
// first-connect explainer off, the first connect intent connects at once.
//
// A held TUN renders the red track, the no-connection status, and the
// "Connection failed" detail line. It does so on a cold start too, and a tap
// on it disconnects. The held signal clears red when the interface goes
// down. A connect releases a held TUN before it runs. The red state shows at
// once through the hold and survives a rebuild and a rotation. A declined
// permission reads grey, and one tap prompts again. A failed stop is red
// with no detail line. A cancelled attempt renders the grey off state and
// the disconnected status.
//
// The header route indicator stays mounted. It opens Direct regions from the
// bottom edge, or from the end edge in split. The status label reads regular
// weight. A connect inside the 300ms hold never shows the connecting label.
// The header lockup renders 28dp tall.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/l10n/localizations/app_localizations.dart';
import 'package:onexray/onevpn/app/held_tunnel.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations_en.dart';
import 'package:onexray/onevpn/paywall/paywall_cadence.dart';
import 'package:onexray/onevpn/paywall/paywall_trigger.dart';
import 'package:onexray/onevpn/shell/connect_control.dart';
import 'package:onexray/onevpn/shell/connect_screen.dart';
import 'package:onexray/onevpn/shell/edge_route.dart';
import 'package:onexray/onevpn/shell/first_connect_explainer.dart';
import 'package:onexray/onevpn/shell/layout.dart';
import 'package:onexray/onevpn/shell/route_indicator.dart';
import 'package:onexray/onevpn/shell/router.dart';
import 'package:onexray/onevpn/shell/routes.dart';
import 'package:onexray/onevpn/shell/status_debounce.dart';
import 'package:onexray/onevpn/theme/brand_lockup.dart';
import 'package:onexray/onevpn/theme/palettes.dart';
import 'package:onexray/pages/theme/theme.dart';
import 'package:onexray/core/pigeon/flutter_api.dart';
import 'package:onexray/core/tools/platform.dart';
import 'package:onexray/core/pigeon/messages.g.dart';
import 'package:onexray/service/connect/coordinator.dart';
import 'package:onexray/service/connect/runtime.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../support/invoke_channel_stub.dart';
import '../support/localizations.dart';
import '../support/viewports.dart';

/// A coordinator whose commands only count. Tests set [state] directly.
class _ScriptedCoordinator extends ConnectionCoordinator {
  _ScriptedCoordinator()
    : super(
        statusEvents: const Stream.empty(),
        observeStatus: () async {},
        disposeStatus: () {},
      );

  int connects = 0;
  int disconnects = 0;
  int cancels = 0;

  /// Each connect and disconnect, in call order.
  final calls = <String>[];

  /// Runs inside each disconnect.
  void Function()? onDisconnect;

  @override
  Future<void> connect() async {
    connects++;
    calls.add('connect');
  }

  @override
  Future<void> disconnect() async {
    disconnects++;
    calls.add('disconnect');
    onDisconnect?.call();
  }

  @override
  void cancel() => cancels++;

  // The screen reads the saved selection on entry and ignores a failure.
  @override
  Future<ConnectionConfiguration> get configuration =>
      Future.error(StateError('no saved configuration'));
}

/// An entitled audience, so the recurring paywall never opens.
class _EntitledAudience implements OneVpnPaywallAudience {
  @override
  bool get entitled => true;

  @override
  Future<void> whenRestored() async {}
}

/// Advances frames without waiting for a quiet tree. The connect screen
/// holds a live database stream, so it never settles.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

void main() {
  final l = OneVpnLocalizationsEn();
  late _ScriptedCoordinator coordinator;

  /// The native held answer the scripted signal reads.
  var heldAnswer = false;

  /// The platform permission prompts the screen requested.
  var permissionRequests = 0;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    heldAnswer = false;
    permissionRequests = 0;
  });

  /// Answers the platform permission prompt as granted and counts it.
  void stubPermissionPrompt() {
    const channel = BasicMessageChannel<Object?>(
      'dev.flutter.pigeon.onexray.BridgeHostApi.requestPlatformPermission',
      BridgeHostApi.pigeonChannelCodec,
    );
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockDecodedMessageHandler<Object?>(channel, (_) async {
      permissionRequests++;
      return <Object?>[
        PlatformPermissionResult(
          kind: PlatformPermissionKind.androidVpn,
          state: PlatformPermissionState.granted,
        ),
      ];
    });
    addTearDown(
      () => messenger.setMockDecodedMessageHandler<Object?>(channel, null),
    );
  }

  /// Marks the first-connect explainer as already shown.
  Future<void> explainerSeen() => SharedPreferencesAsync().setBool(
    OneVpnFirstConnectExplainer.seenKey,
    true,
  );

  /// Mounts the connect screen at the router root over [coordinator], at
  /// [size]. On [android] the coordinator keeps a failed start's TUN and
  /// the held signal reads [heldAnswer]. Elsewhere it holds no TUN.
  Future<void> pump(
    WidgetTester tester, {
    Size size = kPortraitViewport,
    bool android = true,
  }) async {
    // The test body builds the coordinator, so the shared database opens in
    // the widget test zone.
    coordinator = _ScriptedCoordinator()..keepTunnelOnFailedStart = android;
    final held = OneVpnHeldTunnel(
      read: () async => heldAnswer,
      supported: android,
      pollInterval: const Duration(milliseconds: 10),
      releaseTimeout: const Duration(milliseconds: 200),
    );
    addTearDown(held.dispose);
    stubInvokeChannel();
    stubPermissionPrompt();
    await setViewport(tester, size);
    final router = GoRouter(
      initialLocation: kOneVpnConnectRoute,
      routes: [
        GoRoute(
          path: kOneVpnConnectRoute,
          builder: (_, _) => OneVpnConnectScreen(
            coordinator: coordinator,
            heldTunnel: held,
            paywallTrigger: OneVpnPaywallTrigger(
              cadence: OneVpnPaywallCadence(now: DateTime.now),
              audience: _EntitledAudience(),
            ),
          ),
        ),
        GoRoute(
          path: kOneVpnDirectRegionsRoute,
          pageBuilder: (_, state) => OneVpnEdgePage(
            key: state.pageKey,
            stackedEdge: OneVpnRouter.directRegionsEdge(state.extra),
            child: const Scaffold(body: Text('direct regions')),
          ),
        ),
        ...OneVpnRouter.menuSurfaces(),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light,
        locale: const Locale('en'),
        localizationsDelegates: oneVpnLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await _settle(tester);
  }

  Future<void> tapControl(WidgetTester tester) async {
    await tester.tap(find.byType(OneVpnConnectControl));
    await _settle(tester);
  }

  Color trackColor(WidgetTester tester) {
    final track = tester.widget<AnimatedContainer>(
      find.byKey(OneVpnConnectControl.trackKey),
    );
    return (track.decoration! as ShapeDecoration).color!;
  }

  /// The grey off state with an empty detail line.
  void expectGrey(WidgetTester tester) {
    expect(
      trackColor(tester),
      OneVpnPalettes.tokens(Brightness.light).palette.borderStrong,
    );
    expect(find.text(l.onevpnStatusNoConnection), findsNothing);
    expect(
      tester.widget<Text>(find.byKey(OneVpnConnectScreen.detailKey)).data,
      isEmpty,
    );
  }

  /// The red state after a failed connect: the thumb on the end side of the
  /// red track, the "Connection Failed" status, and an empty detail line.
  void expectRedState(WidgetTester tester) {
    expect(
      trackColor(tester),
      OneVpnPalettes.tokens(Brightness.light).palette.destructiveSolid,
    );
    final track = tester.getRect(find.byKey(OneVpnConnectControl.trackKey));
    final thumb = tester.getCenter(find.byKey(OneVpnConnectControl.thumbKey));
    expect(
      thumb.dx,
      closeTo(track.right - OneVpnConnectControl.height / 2, 0.001),
    );
    expect(find.text(l.onevpnStatusConnectionFailed), findsOneWidget);
    expect(find.text(l.onevpnStatusNoConnection), findsNothing);
    final detail = tester.widget<Text>(
      find.byKey(OneVpnConnectScreen.detailKey),
    );
    expect(detail.data, isEmpty);
  }

  testWidgets('the screen mounts the control in place of the power button', (
    tester,
  ) async {
    await pump(tester);

    expect(find.byType(OneVpnConnectControl), findsOneWidget);
    expect(find.byIcon(LucideIcons.power), findsNothing);
    expect(find.text(l.onevpnDisconnected), findsOneWidget);
    expect(find.byType(OneVpnRouteIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in [kPortraitViewport, kLandscapeViewport]) {
    final split = size == kLandscapeViewport;
    testWidgets('at ${size.width.toInt()}x${size.height.toInt()} the route '
        'indicator opens Direct regions from the '
        '${split ? 'end' : 'bottom'} edge', (tester) async {
      await pump(tester, size: size);
      tester
          .widget<OneVpnRouteIndicator>(find.byType(OneVpnRouteIndicator))
          .onTap();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final page = find.text('direct regions');
      final route = ModalRoute.of(tester.element(page))!;
      expect(
        (route.settings as OneVpnEdgePage).stackedEdge,
        OneVpnStackedEdge.bottom,
      );
      // Mid-slide, the page sits between its edge and its place.
      final midway = tester.getTopLeft(
        find.ancestor(of: page, matching: find.byType(Scaffold)).first,
      );
      if (split) {
        expect(midway.dy, 0);
        expect(midway.dx, greaterThan(0));
        expect(midway.dx, lessThan(size.width));
      } else {
        expect(midway.dx, 0);
        expect(midway.dy, greaterThan(0));
        expect(midway.dy, lessThan(size.height));
      }
      await _settle(tester);
      expect(
        tester.getTopLeft(
          find.ancestor(of: page, matching: find.byType(Scaffold)).first,
        ),
        Offset.zero,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the status label reads regular weight', (tester) async {
    await pump(tester);
    coordinator.state.value = const ConnectionView(
      phase: ConnectionPhase.connected,
    );
    await _settle(tester);

    final label = tester.widget<Text>(find.text(l.onevpnConnected));
    expect(label.style?.fontWeight, FontWeight.w400);
  });

  testWidgets('a connect inside the hold skips the connecting label', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);
    coordinator.state.value = const ConnectionView(
      phase: ConnectionPhase.connecting,
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text(l.onevpnConnecting), findsNothing);
    expect(find.text(l.onevpnDisconnected), findsOneWidget);
    // The pill renders the live view. The accessible state holds with the
    // label.
    expect(
      tester
          .widget<OneVpnConnectControl>(find.byType(OneVpnConnectControl))
          .view
          .phase,
      ConnectionPhase.connecting,
    );
    expect(
      tester.getSemantics(find.byType(OneVpnConnectControl)),
      isSemantics(
        value: l.onevpnDisconnected,
        hasToggledState: true,
        isToggled: false,
      ),
    );
    semantics.dispose();

    coordinator.state.value = const ConnectionView(
      phase: ConnectionPhase.connected,
    );
    await tester.pump();
    expect(find.text(l.onevpnConnected), findsOneWidget);
    await _settle(tester);
    expect(find.text(l.onevpnConnecting), findsNothing);
  });

  testWidgets('a slow connect shows the connecting label after the hold', (
    tester,
  ) async {
    await pump(tester);
    coordinator.state.value = const ConnectionView(
      phase: ConnectionPhase.connecting,
    );
    await tester.pump(kOneVpnTransientStatusHold);
    expect(find.text(l.onevpnConnecting), findsOneWidget);
  });

  testWidgets('the header lockup renders 28dp tall', (tester) async {
    await pump(tester);
    expect(tester.getSize(find.byType(OneVpnBrandLockup)).height, 28);
  });

  testWidgets('a disconnected tap connects', (tester) async {
    await explainerSeen();
    await pump(tester);

    await tapControl(tester);

    expect(coordinator.connects, 1);
    expect(coordinator.disconnects, 0);
    expect(find.text(l.onevpnFirstConnectTitle), findsNothing);
  });

  testWidgets('with the explainer off, the first connect intent connects '
      'at once and stamps nothing', (tester) async {
    expect(OneVpnFirstConnectExplainer.enabledByDefault, isFalse);
    await pump(tester);

    await tapControl(tester);

    expect(find.text(l.onevpnFirstConnectTitle), findsNothing);
    expect(coordinator.connects, 1);
    expect(
      await SharedPreferencesAsync().getBool(
        OneVpnFirstConnectExplainer.seenKey,
      ),
      isNull,
    );
  });

  testWidgets('a connected tap disconnects', (tester) async {
    await pump(tester);
    coordinator.state.value = const ConnectionView(
      phase: ConnectionPhase.connected,
    );
    await _settle(tester);

    expect(find.text(l.onevpnConnected), findsOneWidget);
    expect(
      trackColor(tester),
      OneVpnPalettes.tokens(Brightness.light).palette.primarySolid,
    );

    await tapControl(tester);

    expect(coordinator.disconnects, 1);
    expect(coordinator.connects, 0);
  });

  testWidgets('a connecting tap cancels the attempt', (tester) async {
    await pump(tester);
    coordinator.state.value = const ConnectionView(
      phase: ConnectionPhase.connecting,
    );
    await _settle(tester);

    expect(find.text(l.onevpnConnecting), findsOneWidget);

    await tapControl(tester);

    expect(coordinator.cancels, 1);
    expect(coordinator.connects, 0);
    expect(coordinator.disconnects, 0);
  });

  testWidgets('a failed start over a held TUN renders the red state', (
    tester,
  ) async {
    await explainerSeen();
    heldAnswer = true;
    await pump(tester);
    coordinator.state.value = const ConnectionView(
      phase: ConnectionPhase.failed,
      issue: 'startFailed',
    );
    await _settle(tester);

    expectRedState(tester);

    // The held TUN is released first. A retry is a fresh connect.
    await tapControl(tester);
    expect(coordinator.disconnects, 1);
    expect(coordinator.connects, 0);
  });

  group('fail closed', () {
    const failedView = ConnectionView(
      phase: ConnectionPhase.failed,
      issue: 'startFailed',
    );

    testWidgets('a held TUN reads red on a cold start', (tester) async {
      heldAnswer = true;
      await pump(tester);

      // The coordinator reads the held TUN as disconnected.
      expect(coordinator.state.value.phase, ConnectionPhase.disconnected);
      expectRedState(tester);

      await tapControl(tester);
      expect(coordinator.disconnects, 1);
      expect(coordinator.connects, 0);
    });

    testWidgets('red clears when the interface goes down', (tester) async {
      heldAnswer = true;
      await pump(tester);
      expectRedState(tester);

      // The notification's Disconnect releases the TUN. Only the native
      // status reports it: the coordinator view stays unchanged.
      heldAnswer = false;
      AppFlutterApi().vpnStatusController.add(VpnStatus.disconnected);
      await _settle(tester);

      expectGrey(tester);
      expect(find.text(l.onevpnDisconnected), findsOneWidget);
    });

    testWidgets('a failed start the held signal clears reads grey', (
      tester,
    ) async {
      await explainerSeen();
      await pump(tester);
      coordinator.state.value = failedView;
      await _settle(tester);

      expectGrey(tester);
      expect(find.text(l.onevpnDisconnected), findsOneWidget);

      await tapControl(tester);
      expect(coordinator.connects, 1);
      expect(coordinator.disconnects, 0);
    });

    testWidgets('a connect releases a held TUN before it runs', (tester) async {
      await explainerSeen();
      await pump(tester);
      expectGrey(tester);
      // The screen still shows the last answer when a failed start holds
      // the TUN.
      heldAnswer = true;
      coordinator.onDisconnect = () => heldAnswer = false;

      await tapControl(tester);

      expect(coordinator.calls, ['disconnect', 'connect']);
    });

    testWidgets('the red state announces its status through the detail line', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      heldAnswer = true;
      await pump(tester);
      coordinator.state.value = failedView;
      await _settle(tester);

      expect(
        tester.getSemantics(find.byType(OneVpnConnectControl)),
        isSemantics(
          value: l.onevpnStatusConnectionFailed,
          hasToggledState: true,
          isToggled: true,
        ),
      );
      expect(
        tester.getSemantics(find.byKey(OneVpnConnectScreen.detailKey)),
        isSemantics(label: l.onevpnStatusConnectionFailed, isLiveRegion: true),
      );
      semantics.dispose();
    });

    testWidgets('an idle view exposes no detail line', (tester) async {
      final semantics = tester.ensureSemantics();
      await pump(tester);

      expect(
        find.bySemanticsLabel(l.onevpnStatusConnectionFailed),
        findsNothing,
      );
      expect(
        tester.widget<Text>(find.byKey(OneVpnConnectScreen.detailKey)).data,
        isEmpty,
      );
      semantics.dispose();
    });

    // The hold tests run where no TUN is held, so red reads the view alone.
    testWidgets('a failed start inside the hold shows red at once', (
      tester,
    ) async {
      await pump(tester, android: false);
      coordinator.state.value = const ConnectionView(
        phase: ConnectionPhase.connecting,
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(l.onevpnConnecting), findsNothing);

      coordinator.state.value = failedView;
      await tester.pump();
      expect(find.text(l.onevpnStatusConnectionFailed), findsOneWidget);

      // A fresh attempt 150ms later starts its own hold. The timer of the
      // first hold, due at 300ms, never shows the fresh attempt early.
      await tester.pump(const Duration(milliseconds: 150));
      coordinator.state.value = const ConnectionView(
        phase: ConnectionPhase.connecting,
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text(l.onevpnStatusConnectionFailed), findsOneWidget);
      expect(find.text(l.onevpnConnecting), findsNothing);
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text(l.onevpnConnecting), findsOneWidget);
    });

    testWidgets('a failed start after the hold shows red at once', (
      tester,
    ) async {
      await pump(tester, android: false);
      coordinator.state.value = const ConnectionView(
        phase: ConnectionPhase.connecting,
      );
      await tester.pump(kOneVpnTransientStatusHold);
      expect(find.text(l.onevpnConnecting), findsOneWidget);

      coordinator.state.value = failedView;
      await tester.pump();
      expect(find.text(l.onevpnConnecting), findsNothing);
      expect(find.text(l.onevpnStatusConnectionFailed), findsOneWidget);
      await _settle(tester);
      expectRedState(tester);
    });

    testWidgets('the red state survives a rebuild and a rotation', (
      tester,
    ) async {
      heldAnswer = true;
      await pump(tester);
      coordinator.state.value = failedView;
      await _settle(tester);

      tester.element(find.byType(OneVpnConnectScreen)).markNeedsBuild();
      await _settle(tester);
      expectRedState(tester);

      await setViewport(tester, kLandscapeViewport);
      await _settle(tester);
      expect(find.byKey(OneVpnAdaptiveBody.splitKey), findsOneWidget);
      expectRedState(tester);

      await setViewport(tester, kPortraitViewport);
      await _settle(tester);
      expectRedState(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the red state clears on disconnect', (tester) async {
      heldAnswer = true;
      await pump(tester);
      coordinator.state.value = failedView;
      await _settle(tester);
      coordinator.onDisconnect = () => heldAnswer = false;

      await tapControl(tester);
      expect(coordinator.disconnects, 1);
      coordinator.state.value = const ConnectionView();
      await _settle(tester);

      expectGrey(tester);
      expect(find.text(l.onevpnDisconnected), findsOneWidget);

      // The next tap is a fresh connect.
      await explainerSeen();
      await tapControl(tester);
      expect(coordinator.connects, 1);
    });

    testWidgets('the detail line keeps its height in every state', (
      tester,
    ) async {
      await pump(tester);
      final idle = tester.getRect(find.byKey(OneVpnConnectControl.trackKey));
      final idleLine = tester.getSize(
        find.byKey(OneVpnConnectScreen.detailKey),
      );

      heldAnswer = true;
      coordinator.state.value = failedView;
      await _settle(tester);

      expectRedState(tester);
      expect(tester.getRect(find.byKey(OneVpnConnectControl.trackKey)), idle);
      expect(
        tester.getSize(find.byKey(OneVpnConnectScreen.detailKey)).height,
        idleLine.height,
      );
    });
  });

  for (final android in [true, false]) {
    final platform = android ? 'Android' : 'a platform with no hold';
    testWidgets('on $platform a declined permission reads grey and one tap '
        'prompts again', (tester) async {
      // The host API answers not required on Linux and Windows without
      // prompting. The override runs the prompt as the platform under test
      // on every test host.
      AppPlatform.debugOperatingSystemOverride = android ? 'android' : 'ios';
      addTearDown(() => AppPlatform.debugOperatingSystemOverride = null);
      await explainerSeen();
      await pump(tester, android: android);
      coordinator.state.value = ConnectionView(
        phase: ConnectionPhase.failed,
        issue: 'permissionRequired',
        permission: PlatformPermissionResult(
          kind: PlatformPermissionKind.androidVpn,
          state: PlatformPermissionState.denied,
        ),
      );
      await _settle(tester);

      expectGrey(tester);

      await tapControl(tester);
      expect(permissionRequests, 1);
      expect(coordinator.connects, 1);
      expect(coordinator.disconnects, 0);
    });
  }

  testWidgets('on a platform with no hold a red tap retries the connect', (
    tester,
  ) async {
    await explainerSeen();
    await pump(tester, android: false);
    coordinator.state.value = const ConnectionView(
      phase: ConnectionPhase.failed,
      issue: 'startFailed',
    );
    await _settle(tester);

    expectRedState(tester);

    await tapControl(tester);
    expect(coordinator.connects, 1);
    expect(coordinator.disconnects, 0);
  });

  testWidgets('a cancelled attempt renders the off state', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);
    coordinator.state.value = const ConnectionView(
      phase: ConnectionPhase.failed,
      issue: 'cancelled',
    );
    await _settle(tester);

    expect(find.text(l.onevpnDisconnected), findsOneWidget);
    expect(find.text(l.onevpnStatusConnectionFailed), findsNothing);
    expect(
      trackColor(tester),
      OneVpnPalettes.tokens(Brightness.light).palette.borderStrong,
    );
    final track = tester.getRect(find.byKey(OneVpnConnectControl.trackKey));
    final thumb = tester.getCenter(find.byKey(OneVpnConnectControl.thumbKey));
    expect(
      thumb.dx,
      closeTo(track.left + OneVpnConnectControl.height / 2, 0.001),
    );
    expect(
      tester.getSemantics(find.byType(OneVpnConnectControl)),
      isSemantics(
        value: l.onevpnDisconnected,
        hasToggledState: true,
        isToggled: false,
      ),
    );
    semantics.dispose();
  });

  testWidgets('a failed stop is red with no detail line and disconnects', (
    tester,
  ) async {
    await pump(tester);
    coordinator.state.value = const ConnectionView(
      phase: ConnectionPhase.failed,
      issue: 'stopFailed',
    );
    await _settle(tester);

    expect(
      trackColor(tester),
      OneVpnPalettes.tokens(Brightness.light).palette.destructiveSolid,
    );
    expect(find.text(l.onevpnStatusNoConnection), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(OneVpnConnectScreen.detailKey)).data,
      isEmpty,
    );

    await tapControl(tester);

    expect(coordinator.disconnects, 1);
    expect(coordinator.connects, 0);
  });

  group('split at 800x360', () {
    Future<void> pumpSplit(WidgetTester tester) async {
      await pump(tester, size: kLandscapeViewport);
      expect(find.byKey(OneVpnAdaptiveBody.splitKey), findsOneWidget);
    }

    testWidgets('a disconnected tap connects', (tester) async {
      await explainerSeen();
      await pumpSplit(tester);

      await tapControl(tester);

      expect(coordinator.connects, 1);
      expect(coordinator.disconnects, 0);
      expect(find.text(l.onevpnFirstConnectTitle), findsNothing);
    });

    testWidgets('with the explainer off, the first connect intent connects '
        'at once', (tester) async {
      await pumpSplit(tester);

      await tapControl(tester);

      expect(find.text(l.onevpnFirstConnectTitle), findsNothing);
      expect(coordinator.connects, 1);
    });
  });
}
