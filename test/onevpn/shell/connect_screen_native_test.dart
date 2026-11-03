// The native connect's state on the connect screen. A connected view reads
// "Measuring Servers…" on the grey track while the native connect measures.
// It reads "Connected" on the blue track once the pin lands. While the hold
// stands, a connected view is red with the no-connection status and the
// "Connection failed" line. A tap on it disconnects.

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/l10n/localizations/app_localizations.dart';
import 'package:onexray/onevpn/app/held_tunnel.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations_en.dart';
import 'package:onexray/onevpn/paywall/paywall_cadence.dart';
import 'package:onexray/onevpn/paywall/paywall_trigger.dart';
import 'package:onexray/onevpn/shell/connect_control.dart';
import 'package:onexray/onevpn/shell/connect_screen.dart';
import 'package:onexray/onevpn/shell/routes.dart';
import 'package:onexray/onevpn/theme/palettes.dart';
import 'package:onexray/pages/theme/theme.dart';
import 'package:onexray/service/connect/coordinator.dart';
import 'package:onexray/service/connect/runtime.dart';
import 'package:onexray/service/connect/settings.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../support/invoke_channel_stub.dart';
import '../support/localizations.dart';
import '../support/reload_fakes.dart';
import '../support/viewports.dart';

/// A coordinator whose view the tests set directly. It counts disconnects.
class _ScriptedCoordinator extends ConnectionCoordinator {
  _ScriptedCoordinator()
    : super(
        statusEvents: const Stream.empty(),
        observeStatus: () async {},
        disposeStatus: () {},
      );

  int disconnects = 0;

  @override
  Future<void> disconnect() async => disconnects++;

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

void main() {
  final l = OneVpnLocalizationsEn();
  final palette = OneVpnPalettes.tokens(Brightness.light).palette;
  late _ScriptedCoordinator coordinator;
  late ValueNotifier<bool> measuring;
  late ValueNotifier<bool> allDead;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  Future<void> pump(WidgetTester tester) async {
    coordinator = _ScriptedCoordinator();
    measuring = ValueNotifier(false);
    addTearDown(measuring.dispose);
    allDead = ValueNotifier(false);
    addTearDown(allDead.dispose);
    final held = OneVpnHeldTunnel(
      read: () async => false,
      supported: true,
      pollInterval: const Duration(milliseconds: 10),
      releaseTimeout: const Duration(milliseconds: 200),
    );
    addTearDown(held.dispose);
    stubInvokeChannel();
    await setViewport(tester, kPortraitViewport);
    final router = GoRouter(
      initialLocation: kOneVpnConnectRoute,
      routes: [
        GoRoute(
          path: kOneVpnConnectRoute,
          builder: (_, _) => OneVpnConnectScreen(
            coordinator: coordinator,
            heldTunnel: held,
            measuring: measuring,
            // The selection is Automatic, which measures for the fastest
            // server.
            picksFastest: (_) => true,
            allDead: allDead,
            paywallTrigger: OneVpnPaywallTrigger(
              cadence: OneVpnPaywallCadence(now: DateTime.now),
              audience: _EntitledAudience(),
            ),
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
        routerConfig: router,
      ),
    );
    await settle(tester);
  }

  void connected() => coordinator.state.value = ConnectionView(
    phase: ConnectionPhase.connected,
    runtime: reloadRuntime(
      reloadConfiguration(const ServerSelection.automatic()),
      metricsPort: '18001',
    ),
  );

  Color trackColor(WidgetTester tester) {
    final track = tester.widget<AnimatedContainer>(
      find.byKey(OneVpnConnectControl.trackKey),
    );
    return (track.decoration! as ShapeDecoration).color!;
  }

  String? detail(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(OneVpnConnectScreen.detailKey)).data;

  testWidgets('the connected label reads measuring', (tester) async {
    await pump(tester);
    measuring.value = true;
    connected();
    await settle(tester);

    expect(find.text(l.onevpnStatusMeasuring), findsOneWidget);
    expect(find.text(l.onevpnConnected), findsNothing);
    expect(trackColor(tester), palette.borderStrong);
    expect(detail(tester), isEmpty);

    measuring.value = false;
    await settle(tester);

    expect(find.text(l.onevpnStatusMeasuring), findsNothing);
    expect(find.text(l.onevpnConnected), findsOneWidget);
    expect(trackColor(tester), palette.primarySolid);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the all-dead state reads a failed connection', (tester) async {
    await pump(tester);
    connected();
    allDead.value = true;
    await settle(tester);

    expect(find.text(l.onevpnStatusConnectionFailed), findsOneWidget);
    expect(find.text(l.onevpnConnected), findsNothing);
    expect(detail(tester), isEmpty);
    expect(trackColor(tester), palette.destructiveSolid);

    await tester.tap(find.byType(OneVpnConnectControl));
    await settle(tester);
    expect(coordinator.disconnects, 1);
    expect(tester.takeException(), isNull);
  });
}
