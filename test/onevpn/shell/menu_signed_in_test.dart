// The hamburger menu for a signed-in account.
//
// Signed in on Android, the menu carries its most rows. It still reaches
// every row at 360x800 in the top drawer. It reaches every row at 800x360
// in the end drawer, in the same order. The account row carries no trailing
// icon. A pending grant shows the refresh icon, and a tap on the row
// re-checks it. A completed sign-up closes the menu.
//
// Each test passes its own account state, so no test depends on run order.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/l10n/localizations/app_localizations.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/account/session.dart';
import 'package:onexray/onevpn/account/sign_in_page.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations_en.dart';
import 'package:onexray/onevpn/model/user_data.dart';
import 'package:onexray/onevpn/shell/menu.dart';
import 'package:onexray/onevpn/shell/router.dart';
import 'package:onexray/onevpn/shell/routes.dart';
import 'package:onexray/pages/theme/theme.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../support/localizations.dart';
import '../support/viewports.dart';

OneVpnAccountState _signedIn({
  required bool isPremium,
  DateTime? pendingSince,
}) => OneVpnAccountSignedIn(
  OneVpnSession(
    sessionAuthToken: 'token',
    username: 'someone',
    email: 'someone@example.invalid',
    isPremium: isPremium,
    credentials: const OneVpnCredentials(
      uuid: 'u',
      publicKey: 'p',
      shortId: 's',
    ),
    locations: const <OneVpnApiLocation>[],
    premiumPendingSince: pendingSince,
  ),
);

GoRouter _router(ValueListenable<OneVpnAccountState> account) => GoRouter(
  initialLocation: kOneVpnConnectRoute,
  routes: [
    GoRoute(
      path: kOneVpnConnectRoute,
      builder: (context, _) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => showOneVpnMenu(context, accountState: account),
            child: const Text('open'),
          ),
        ),
      ),
    ),
    // Answers the push as a completed sign-up.
    GoRoute(
      path: kOneVpnSignInRoute,
      builder: (context, _) => Scaffold(
        body: TextButton(
          onPressed: () => context.pop(OneVpnSignInMode.signUp),
          child: const Text('signed up'),
        ),
      ),
    ),
    GoRoute(
      path: kOneVpnPaywallRoute,
      builder: (_, _) => const Scaffold(body: Text('paywall')),
    ),
    ...OneVpnRouter.menuSurfaces(),
  ],
);

Future<void> _openMenu(
  WidgetTester tester,
  ValueListenable<OneVpnAccountState> account, {
  Size size = kPortraitViewport,
}) async {
  await setViewport(tester, size);
  await tester.pumpWidget(
    MaterialApp.router(
      theme: AppTheme.light,
      locale: const Locale('en'),
      localizationsDelegates: oneVpnLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _router(account),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  final l = OneVpnLocalizationsEn();

  setUpAll(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('a sign-up that lands premium opens no paywall', (tester) async {
    final account = ValueNotifier<OneVpnAccountState>(
      const OneVpnAccountSignedOut(),
    );
    addTearDown(account.dispose);
    await _openMenu(tester, account);
    await tester.tap(find.text(l.onevpnSignUp));
    await tester.pumpAndSettle();
    // The sign-up links a purchase, so the adopted session is premium.
    account.value = _signedIn(isPremium: true);
    await tester.tap(find.text('signed up'));
    await tester.pumpAndSettle();

    expect(find.text('paywall'), findsNothing);
    expect(find.byKey(OneVpnMenu.stackedKey), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  group('signed in free', () {
    testWidgets('the account row carries no link icon', (tester) async {
      await _openMenu(tester, ValueNotifier(_signedIn(isPremium: false)));

      expect(find.text('someone@example.invalid'), findsOneWidget);
      expect(find.byIcon(LucideIcons.externalLink), findsNothing);
      final row = tester.widget<ListTile>(
        find.ancestor(
          of: find.text('someone@example.invalid'),
          matching: find.byType(ListTile),
        ),
      );
      expect(row.trailing, isNull);
    });

    testWidgets('every entry is reachable at 360x800 with no overflow', (
      tester,
    ) async {
      await _openMenu(tester, ValueNotifier(_signedIn(isPremium: false)));
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.text(l.onevpnLogOut));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(l.onevpnAlwaysOnTitle), findsOneWidget);
      expect(find.text(l.onevpnUpgrade), findsOneWidget);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets('every drawer entry is reachable at 800x360 in page order', (
      tester,
    ) async {
      List<String> titles() => [
        for (final tile in tester.widgetList<ListTile>(find.byType(ListTile)))
          switch (tile.title) {
            final OneVpnAccountLine line => line.name,
            final Text text => text.data!,
            _ => throw StateError('unexpected title'),
          },
      ];
      await _openMenu(tester, ValueNotifier(_signedIn(isPremium: false)));
      final page = titles();

      await _openMenu(
        tester,
        ValueNotifier(_signedIn(isPremium: false)),
        size: kLandscapeViewport,
      );
      expect(tester.takeException(), isNull);
      expect(find.byKey(OneVpnMenu.drawerKey), findsOneWidget);
      expect(titles(), page);
      expect(page, [
        'someone@example.invalid',
        l.onevpnUpgrade,
        l.onevpnDirectRegions,
        l.onevpnAlwaysOnTitle,
        l.onevpnLanguage,
        l.onevpnSupport,
        l.onevpnLogOut,
      ]);

      await tester.ensureVisible(find.text(l.onevpnLogOut));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(l.onevpnLogOut).hitTestable(), findsOneWidget);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets('a larger text size scrolls the page to Logout', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 4.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _openMenu(tester, ValueNotifier(_signedIn(isPremium: false)));
      expect(tester.takeException(), isNull);
      expect(find.text(l.onevpnLogOut).hitTestable(), findsNothing);

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -2000),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(l.onevpnLogOut).hitTestable(), findsOneWidget);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));
  });

  testWidgets('a pending grant shows the refresh icon and re-checks on tap', (
    tester,
  ) async {
    // The re-check reaches the account service. It restores on the real
    // clock: the service outlives each test's fake clock.
    await tester.runAsync(OneVpnAccountService.instance.whenRestored);
    await _openMenu(
      tester,
      ValueNotifier(
        _signedIn(isPremium: false, pendingSince: DateTime.utc(2026, 9, 21)),
      ),
    );
    final row = find.ancestor(
      of: find.text('someone@example.invalid'),
      matching: find.byType(ListTile),
    );
    expect(
      find.descendant(of: row, matching: find.byIcon(LucideIcons.refreshCw)),
      findsOneWidget,
    );

    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.text(l.onevpnPremiumRecheck), findsOneWidget);
  });
}
