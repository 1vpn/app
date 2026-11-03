// Back on the connect screen. While the native connect measures or holds,
// Back moves the app to the background and the screen stays. At any other
// time Back leaves through the platform, including a measure that ended
// after the last build. A route over the screen pops first.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/l10n/localizations/app_localizations.dart';
import 'package:onexray/onevpn/app/held_tunnel.dart';
import 'package:onexray/onevpn/app/platform_channel.dart';
import 'package:onexray/onevpn/paywall/paywall_cadence.dart';
import 'package:onexray/onevpn/paywall/paywall_trigger.dart';
import 'package:onexray/onevpn/shell/connect_screen.dart';
import 'package:onexray/onevpn/shell/routes.dart';
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
  late ValueNotifier<bool> measuring;
  late ValueNotifier<bool> allDead;

  /// The methods the fork channel received, in order.
  late List<String> forkCalls;

  /// The platform's own navigator pops, in order.
  late List<String> systemPops;

  /// The router over the screen, with one route to push over it.
  late GoRouter router;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  Future<void> pump(WidgetTester tester) async {
    final coordinator = _ScriptedCoordinator();
    coordinator.state.value = const ConnectionView(
      phase: ConnectionPhase.connecting,
    );
    measuring = ValueNotifier(false);
    allDead = ValueNotifier(false);
    addTearDown(measuring.dispose);
    addTearDown(allDead.dispose);
    final held = OneVpnHeldTunnel(
      read: () async => false,
      supported: false,
      pollInterval: const Duration(milliseconds: 10),
      releaseTimeout: const Duration(milliseconds: 200),
    );
    addTearDown(held.dispose);
    stubInvokeChannel();
    forkCalls = [];
    systemPops = [];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const fork = MethodChannel(OneVpnPlatformChannel.name);
    messenger.setMockMethodCallHandler(fork, (call) async {
      forkCalls.add(call.method);
      return call.method == 'moveTaskToBack' ? true : null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(fork, null));
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'SystemNavigator.pop') systemPops.add(call.method);
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await setViewport(tester, kPortraitViewport);
    router = GoRouter(
      initialLocation: kOneVpnConnectRoute,
      routes: [
        GoRoute(
          path: kOneVpnConnectRoute,
          builder: (_, _) => OneVpnConnectScreen(
            coordinator: coordinator,
            heldTunnel: held,
            measuring: measuring,
            allDead: allDead,
            picksFastest: (_) => true,
            paywallTrigger: OneVpnPaywallTrigger(
              cadence: OneVpnPaywallCadence(now: DateTime.now),
              audience: _EntitledAudience(),
            ),
          ),
        ),
        GoRoute(
          path: '/over',
          builder: (_, _) => const Scaffold(body: Text('over')),
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

  testWidgets('Back during a measure moves the app to the background', (
    tester,
  ) async {
    await pump(tester);
    measuring.value = true;
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(forkCalls, ['moveTaskToBack']);
    expect(systemPops, isEmpty);
    expect(find.byType(OneVpnConnectScreen), findsOneWidget);
  });

  testWidgets('Back during the hold moves the app to the background', (
    tester,
  ) async {
    await pump(tester);
    allDead.value = true;
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(forkCalls, ['moveTaskToBack']);
    expect(systemPops, isEmpty);
  });

  testWidgets('Back with no measure and no hold leaves through the platform', (
    tester,
  ) async {
    await pump(tester);
    measuring.value = true;
    await tester.pump();
    measuring.value = false;
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(forkCalls, isEmpty);
    expect(systemPops, ['SystemNavigator.pop']);
  });

  testWidgets('Back after a measure ended within the frame leaves through '
      'the platform', (tester) async {
    await pump(tester);
    measuring.value = true;
    await tester.pump();
    // No frame runs: the scope still reads the measure.
    measuring.value = false;

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(forkCalls, isEmpty);
    expect(systemPops, ['SystemNavigator.pop']);
  });

  testWidgets('Back during a measure pops a route over the screen first', (
    tester,
  ) async {
    await pump(tester);
    measuring.value = true;
    unawaited(router.push('/over'));
    await tester.pumpAndSettle();
    expect(find.text('over'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('over'), findsNothing);
    expect(find.byType(OneVpnConnectScreen), findsOneWidget);
    expect(forkCalls, isEmpty);
    expect(systemPops, isEmpty);

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(forkCalls, ['moveTaskToBack']);
    expect(systemPops, isEmpty);
  });
}
