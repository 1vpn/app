// A restoring account on the connect screen never reaches the ads gateway.
// Screen entry starts no consent run and no preload. A connect tap connects
// at once with no ad, even with an ad cached. Once the state settles signed
// out, the screen runs the consent update and the first preload.

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/l10n/localizations/app_localizations.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/ads/connect_ad_gate.dart';
import 'package:onexray/onevpn/paywall/paywall_cadence.dart';
import 'package:onexray/onevpn/paywall/paywall_trigger.dart';
import 'package:onexray/onevpn/shell/connect_control.dart';
import 'package:onexray/onevpn/shell/connect_screen.dart';
import 'package:onexray/onevpn/shell/first_connect_explainer.dart';
import 'package:onexray/onevpn/shell/routes.dart';
import 'package:onexray/pages/theme/theme.dart';
import 'package:onexray/service/connect/coordinator.dart';
import 'package:onexray/service/connect/runtime.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../ads/fake_ad_gateway.dart';
import '../support/held_tunnel_stub.dart';
import '../support/invoke_channel_stub.dart';
import '../support/localizations.dart';
import '../support/viewports.dart';

/// A coordinator with no saved configuration whose connect counts.
class _CountingCoordinator extends ConnectionCoordinator {
  _CountingCoordinator()
    : super(
        statusEvents: const Stream.empty(),
        observeStatus: () async {},
        disposeStatus: () {},
      );

  int connects = 0;

  @override
  Future<void> connect() async => connects++;

  @override
  Future<ConnectionConfiguration> get configuration =>
      Future.error(StateError('no saved configuration'));
}

class _EntitledAudience implements OneVpnPaywallAudience {
  @override
  bool get entitled => true;

  @override
  Future<void> whenRestored() async {}
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

void main() {
  setUpAll(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('a restoring tap connects with no consent run and no ad', (
    tester,
  ) async {
    // Must hold before the mount: the account state stays restoring until
    // the first restore call, and this file makes none before the tap.
    expect(
      OneVpnAccountService.instance.state.value,
      isA<OneVpnAccountRestoring>(),
    );
    await tester.runAsync(() async {
      final preferences = SharedPreferencesAsync();
      await preferences.setBool(OneVpnFirstConnectExplainer.seenKey, true);
    });
    stubInvokeChannel();
    stubHeldTunnelChannel();
    await setViewport(tester, kPortraitViewport);
    final gateway = FakeAdGateway(ready: true);
    final coordinator = _CountingCoordinator();
    final router = GoRouter(
      initialLocation: kOneVpnConnectRoute,
      routes: [
        GoRoute(
          path: kOneVpnConnectRoute,
          builder: (_, _) => OneVpnConnectScreen(
            coordinator: coordinator,
            adGate: OneVpnConnectAdGate(gateway: gateway),
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
    await _settle(tester);

    await tester.tap(find.byType(OneVpnConnectControl));
    await _settle(tester);

    expect(coordinator.connects, 1);
    expect(gateway.calls, isEmpty);
    expect(
      await tester.runAsync(
        () => SharedPreferencesAsync().getBool(
          OneVpnConnectAdGate.firstConnectKey,
        ),
      ),
      isNull,
    );

    // The store answers with no session: the state settles signed out.
    await tester.runAsync(OneVpnAccountService.instance.restore);
    await _settle(tester);

    expect(gateway.calls.take(3), ['update', 'privacy', 'preload']);
    expect(tester.takeException(), isNull);
  });
}
