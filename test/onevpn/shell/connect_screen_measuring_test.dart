// The measuring label on the connect screen. A connect that measures for the
// fastest server reads "Measuring Servers…" from its start until the pin. Any
// other connect reads "Connecting…", through a measure that guards a picked
// location too. The label sits behind the same 300ms hold. It fits portrait
// and landscape.

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/l10n/localizations/app_localizations.dart';
import 'package:onexray/onevpn/app/held_tunnel.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations_en.dart';
import 'package:onexray/onevpn/paywall/paywall_cadence.dart';
import 'package:onexray/onevpn/paywall/paywall_trigger.dart';
import 'package:onexray/onevpn/shell/connect_screen.dart';
import 'package:onexray/onevpn/shell/routes.dart';
import 'package:onexray/onevpn/shell/status_debounce.dart';
import 'package:onexray/pages/theme/theme.dart';
import 'package:onexray/service/connect/coordinator.dart';
import 'package:onexray/service/connect/runtime.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../support/invoke_channel_stub.dart';
import '../support/localizations.dart';
import '../support/viewports.dart';

/// A coordinator whose view the tests set directly.
class _ScriptedCoordinator extends ConnectionCoordinator {
  _ScriptedCoordinator()
    : super(
        statusEvents: const Stream.empty(),
        observeStatus: () async {},
        disposeStatus: () {},
      );

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
  late _ScriptedCoordinator coordinator;
  late ValueNotifier<bool> measuring;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  /// Mounts the screen over an Automatic selection. [fastest] answers
  /// whether a connect to it measures for the fastest server.
  Future<void> pump(
    WidgetTester tester,
    Size size, {
    required bool fastest,
  }) async {
    coordinator = _ScriptedCoordinator();
    measuring = ValueNotifier(false);
    addTearDown(measuring.dispose);
    final held = OneVpnHeldTunnel(
      read: () async => false,
      supported: false,
      pollInterval: const Duration(milliseconds: 10),
      releaseTimeout: const Duration(milliseconds: 200),
    );
    addTearDown(held.dispose);
    stubInvokeChannel();
    await setViewport(tester, size);
    final router = GoRouter(
      initialLocation: kOneVpnConnectRoute,
      routes: [
        GoRoute(
          path: kOneVpnConnectRoute,
          builder: (_, _) => OneVpnConnectScreen(
            coordinator: coordinator,
            heldTunnel: held,
            measuring: measuring,
            picksFastest: (_) => fastest,
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
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  void preparing() => coordinator.state.value = const ConnectionView(
    phase: ConnectionPhase.preparing,
  );

  for (final (name, size) in [
    ('portrait', kPortraitViewport),
    ('landscape', kLandscapeViewport),
  ]) {
    group('in $name', () {
      testWidgets('a fastest-server connect reads measuring from its start '
          'until the pin', (tester) async {
        await pump(tester, size, fastest: true);
        preparing();
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.text(l.onevpnStatusMeasuring), findsNothing);
        expect(find.text(l.onevpnDisconnected), findsOneWidget);

        // The measure has not started yet.
        await tester.pump(kOneVpnTransientStatusHold);
        expect(find.text(l.onevpnStatusMeasuring), findsOneWidget);
        expect(find.text(l.onevpnConnecting), findsNothing);
        expect(tester.takeException(), isNull);

        measuring.value = true;
        coordinator.state.value = const ConnectionView(
          phase: ConnectionPhase.connecting,
        );
        await tester.pump(kOneVpnTransientStatusHold);
        expect(find.text(l.onevpnStatusMeasuring), findsOneWidget);
        expect(find.text(l.onevpnConnecting), findsNothing);

        coordinator.state.value = const ConnectionView(
          phase: ConnectionPhase.connected,
        );
        await tester.pump(kOneVpnTransientStatusHold);
        expect(find.text(l.onevpnStatusMeasuring), findsOneWidget);

        // The pin lands.
        measuring.value = false;
        await tester.pump();
        expect(find.text(l.onevpnStatusMeasuring), findsNothing);
        expect(find.text(l.onevpnConnected), findsOneWidget);
      });

      testWidgets('any other connect reads connecting, through a measure too', (
        tester,
      ) async {
        await pump(tester, size, fastest: false);
        preparing();
        await tester.pump(kOneVpnTransientStatusHold);
        expect(find.text(l.onevpnConnecting), findsOneWidget);
        expect(find.text(l.onevpnStatusMeasuring), findsNothing);

        // A measure that guards a picked location.
        measuring.value = true;
        coordinator.state.value = const ConnectionView(
          phase: ConnectionPhase.connecting,
        );
        await tester.pump(kOneVpnTransientStatusHold);
        expect(find.text(l.onevpnConnecting), findsOneWidget);
        expect(find.text(l.onevpnStatusMeasuring), findsNothing);

        coordinator.state.value = const ConnectionView(
          phase: ConnectionPhase.connected,
        );
        await tester.pump(kOneVpnTransientStatusHold);
        expect(find.text(l.onevpnConnecting), findsOneWidget);
        expect(find.text(l.onevpnStatusMeasuring), findsNothing);

        measuring.value = false;
        await tester.pump();
        expect(find.text(l.onevpnConnected), findsOneWidget);
      });

      testWidgets('a preparing view with no measure reads connecting', (
        tester,
      ) async {
        await pump(tester, size, fastest: false);
        preparing();
        await tester.pump(kOneVpnTransientStatusHold);
        expect(find.text(l.onevpnConnecting), findsOneWidget);
        expect(find.text(l.onevpnStatusMeasuring), findsNothing);
      });
    });
  }
}
