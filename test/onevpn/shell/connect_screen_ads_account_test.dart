// The connect screen preloads on a change from an exempt account to a free
// one. A premium session on entry starts no gateway call. An entitlement
// that lapses while the screen is up runs the consent update and a preload.
// A later change between two free states starts nothing.

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/l10n/localizations/app_localizations.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/ads/connect_ad_gate.dart';
import 'package:onexray/onevpn/model/user_data.dart';
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

import '../ads/fake_ad_gateway.dart';
import '../support/held_tunnel_stub.dart';
import '../support/invoke_channel_stub.dart';
import '../support/localizations.dart';
import '../support/viewports.dart';

/// A coordinator with no saved configuration.
class _IdleCoordinator extends ConnectionCoordinator {
  _IdleCoordinator()
    : super(
        statusEvents: const Stream.empty(),
        observeStatus: () async {},
        disposeStatus: () {},
      );

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

/// A signed-in user, premium when [premium] is true.
OneVpnUserData _user({required bool premium, String username = 'someone'}) =>
    OneVpnUserData(
      username: username,
      email: 'someone@example.invalid',
      isPremium: premium,
      sessionAuthToken: 'token',
      credentials: const OneVpnCredentials(
        uuid: 'u',
        publicKey: 'p',
        shortId: 's',
      ),
      locations: const <OneVpnApiLocation>[],
    );

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

  testWidgets('a lapsed entitlement preloads once, a free change never', (
    tester,
  ) async {
    await tester.runAsync(
      () => OneVpnAccountService.instance.adoptSession(_user(premium: true)),
    );
    stubInvokeChannel();
    stubHeldTunnelChannel();
    await setViewport(tester, kPortraitViewport);
    final gateway = FakeAdGateway();
    final router = GoRouter(
      initialLocation: kOneVpnConnectRoute,
      routes: [
        GoRoute(
          path: kOneVpnConnectRoute,
          builder: (_, _) => OneVpnConnectScreen(
            coordinator: _IdleCoordinator(),
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
    expect(gateway.calls, isEmpty);

    // The entitlement lapses: the session turns free.
    await tester.runAsync(
      () => OneVpnAccountService.instance.adoptSession(_user(premium: false)),
    );
    await _settle(tester);
    expect(gateway.calls, ['update', 'privacy', 'preload']);

    // A second free session replaces the first.
    gateway.calls.clear();
    await tester.runAsync(
      () => OneVpnAccountService.instance.adoptSession(
        _user(premium: false, username: 'someone-else'),
      ),
    );
    await _settle(tester);
    expect(gateway.calls, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
