// Tests the launch with a purchase that waits for an account, at 360x800.
// The launch check answers the stored address. The router opens the paywall
// over the shell with that address as its extra. The paywall then shows the
// purchased screen, which names the address and offers the account step.
// Continue Free lands on the shell and hides the screen for the rest of the
// run. The next run shows it again. A launch with no record opens the
// shell.

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations_en.dart';
import 'package:onexray/onevpn/l10n/locales.dart';
import 'package:onexray/onevpn/paywall/paywall_page.dart';
import 'package:onexray/onevpn/paywall/pending_purchase.dart';
import 'package:onexray/onevpn/purchase/fake_purchase_service.dart';
import 'package:onexray/onevpn/shell/router.dart';
import 'package:onexray/onevpn/shell/routes.dart';
import 'package:onexray/pages/theme/theme.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../support/localizations.dart';
import '../support/viewports.dart';

const _buyer = 'buyer@example.invalid';
const _shell = 'connect shell';

void main() {
  final l = OneVpnLocalizationsEn();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    OneVpnPendingPurchase.resetLaunch();
  });

  /// Runs the launch check, then mounts a router of the fork's shape the way
  /// the entry point routes: the paywall over the shell when the check
  /// answers an address. Returns the addresses the handoff was called with.
  Future<List<String>> launch(
    WidgetTester tester,
    OneVpnPendingPurchase pending,
    ValueNotifier<OneVpnAccountState> account,
  ) async {
    final address = await pending.dueAtLaunch(
      account: account,
      restored: Future<void>.value(),
    );
    final handoffs = <String>[];
    final router = GoRouter(
      initialLocation: address == null
          ? kOneVpnConnectRoute
          : kOneVpnPaywallRoute,
      initialExtra: address,
      routes: [
        GoRoute(
          path: kOneVpnConnectRoute,
          builder: (_, _) => const Scaffold(body: Text(_shell)),
          routes: [
            GoRoute(
              path: kOneVpnPaywallRoute.substring(1),
              builder: (_, state) => OneVpnPaywallPage(
                service: OneVpnFakePurchaseService(),
                accountState: account,
                pending: pending,
                purchased: OneVpnRouter.purchasedAddress(state.extra),
                onPurchaseComplete: (_, email) async => handoffs.add(email),
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await setViewport(tester, kPortraitViewport);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light,
        locale: const Locale('en'),
        localizationsDelegates: oneVpnLocalizationsDelegates,
        supportedLocales: [for (final l in kOneVpnLocales) l.locale],
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();
    return handoffs;
  }

  testWidgets('a signed-out launch with the record opens on the purchased '
      'screen, and Continue Free lands on the shell', (tester) async {
    final pending = OneVpnPendingPurchase();
    await pending.record(_buyer);
    final account = ValueNotifier<OneVpnAccountState>(
      const OneVpnAccountSignedOut(),
    );

    final handoffs = await launch(tester, pending, account);

    expect(find.text(l.onevpnPaywallPurchasedTitle), findsOneWidget);
    expect(find.text(l.onevpnPaywallPurchasedBody(_buyer)), findsOneWidget);
    expect(find.text(l.onevpnAuthCreateAccount), findsOneWidget);
    expect(find.text(l.onevpnGetPremium), findsNothing);
    expect(tester.takeException(), isNull);

    // The account step runs for the stored address. It stays signed out
    // here, so the screen holds.
    await tester.tap(find.text(l.onevpnAuthCreateAccount));
    await tester.pumpAndSettle();
    expect(handoffs, [_buyer]);
    expect(find.text(l.onevpnPaywallPurchasedTitle), findsOneWidget);

    await tester.tap(find.text(l.onevpnContinueFree));
    await tester.pumpAndSettle();

    expect(find.text(_shell), findsOneWidget);
    expect(find.text(l.onevpnPaywallPurchasedTitle), findsNothing);
    // The rest of the run opens on the shell. The record stays for the next
    // launch.
    expect(
      await pending.dueAtLaunch(
        account: account,
        restored: Future<void>.value(),
      ),
      isNull,
    );
    expect(await pending.read(), _buyer);
  });

  testWidgets('the next run opens on the purchased screen again', (
    tester,
  ) async {
    final pending = OneVpnPendingPurchase();
    await pending.record(_buyer);
    OneVpnPendingPurchase.dismissForThisLaunch();

    // A new run starts with no dismissal.
    OneVpnPendingPurchase.resetLaunch();
    await launch(
      tester,
      pending,
      ValueNotifier<OneVpnAccountState>(const OneVpnAccountSignedOut()),
    );

    expect(find.text(l.onevpnPaywallPurchasedBody(_buyer)), findsOneWidget);
  });

  testWidgets('a launch with no record opens the shell', (tester) async {
    await launch(
      tester,
      OneVpnPendingPurchase(),
      ValueNotifier<OneVpnAccountState>(const OneVpnAccountSignedOut()),
    );

    expect(find.text(_shell), findsOneWidget);
    expect(find.text(l.onevpnPaywallPurchasedTitle), findsNothing);
  });
}
