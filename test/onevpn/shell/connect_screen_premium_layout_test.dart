// A premium account on the connect screen shows no upgrade banner in either
// layout mode. The end pane then holds the location row alone.
//
// The session is adopted on the real clock: the account service is process
// wide and outlives each test's fake clock.

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/l10n/localizations/app_localizations.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/model/user_data.dart';
import 'package:onexray/onevpn/paywall/paywall_cadence.dart';
import 'package:onexray/onevpn/paywall/paywall_trigger.dart';
import 'package:onexray/onevpn/shell/connect_control.dart';
import 'package:onexray/onevpn/shell/connect_screen.dart';
import 'package:onexray/onevpn/shell/layout.dart';
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

  Future<void> pump(WidgetTester tester, Size size) async {
    await tester.runAsync(
      () => OneVpnAccountService.instance.adoptSession(
        const OneVpnUserData(
          username: 'someone',
          email: 'someone@example.invalid',
          isPremium: true,
          sessionAuthToken: 'token',
          credentials: OneVpnCredentials(
            uuid: 'u',
            publicKey: 'p',
            shortId: 's',
          ),
          locations: <OneVpnApiLocation>[],
        ),
      ),
    );
    stubInvokeChannel();
    await setViewport(tester, size);
    final router = GoRouter(
      initialLocation: kOneVpnConnectRoute,
      routes: [
        GoRoute(
          path: kOneVpnConnectRoute,
          builder: (_, _) => OneVpnConnectScreen(
            coordinator: _IdleCoordinator(),
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
  }

  testWidgets('stacked, a premium account shows no banner', (tester) async {
    await pump(tester, kPortraitViewport);

    expect(tester.takeException(), isNull);
    expect(find.byKey(OneVpnConstrainedBody.stackedKey), findsOneWidget);
    expect(find.byType(OneVpnConnectControl), findsOneWidget);
    expect(find.byIcon(LucideIcons.zap), findsOneWidget);
    expect(find.byKey(const ValueKey('onevpn-upgrade-banner')), findsNothing);
  });

  testWidgets('split, a premium account shows no banner', (tester) async {
    await pump(tester, kLandscapeViewport);

    expect(tester.takeException(), isNull);
    expect(find.byKey(OneVpnAdaptiveBody.splitKey), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(OneVpnAdaptiveBody.endPaneKey),
        matching: find.byIcon(LucideIcons.zap),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('onevpn-upgrade-banner')), findsNothing);
  });
}
