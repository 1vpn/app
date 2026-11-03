// The hamburger menu route: its Direct-regions entry, its signed-out
// entries, its two layouts, its account row, and the row's plan line.
//
// Signed out, the menu reaches every entry at 360x800 and marks Upgrade with
// a grey outline star. A completed sign-up opens the paywall, whichever row
// opened the auth screen. A completed log-in opens nothing.
//
// Stacked, the menu is a full-width top drawer titled Menu, with a close
// button, over a scrim. It grows to at most 0.85 of the height below the top
// inset, and the scrim below it stays tappable. At 800x360 it is a drawer
// over the end pane with a scrim over the start pane. The drawer slides in
// from the end edge as the scrim fades in. The scrim, the close button, and
// system back dismiss either drawer. A rotation swaps the top drawer for the
// end drawer in place. Both layouts list the same items in the same order.
// Past a start safe inset, the list spans the drawer in either direction.
// Each drawer reads as the Menu route to screen readers.
//
// Direct regions, Support, and the auth screen open over the menu. Stacked,
// they come from the top edge. Back returns to the menu. A completed auth
// closes it.
//
// The Direct regions item reuses the picker title, and tapping it routes to
// the Direct-regions picker. The entry is present in every account state.
// Signed in, the account row reads the email, a middle dot, and the plan on
// one line at 360x800, in English and under Arabic. Under Arabic the email
// sits on the right. A long email ends in an ellipsis, and the plan shows
// whole. The plan line names a purchase awaiting server confirmation without
// promising it.
//
// The backup-domain item is last in the menu while the transport's live
// notice names a backup domain, and absent otherwise. Its second line is
// the bare host. It takes no tap and shows with no tunnel up.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/account/session.dart';
import 'package:onexray/onevpn/account/sign_in_page.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations_ar.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations_en.dart';
import 'package:onexray/onevpn/l10n/locale_choice.dart';
import 'package:onexray/onevpn/model/user_data.dart';
import 'package:onexray/onevpn/net/api_transport.dart';
import 'package:onexray/onevpn/net/failover_domains.dart';
import 'package:onexray/onevpn/shell/edge_route.dart';
import 'package:onexray/onevpn/shell/language_page.dart';
import 'package:onexray/onevpn/shell/layout.dart';
import 'package:onexray/onevpn/shell/menu.dart';
import 'package:onexray/onevpn/shell/router.dart';
import 'package:onexray/onevpn/shell/routes.dart';
import 'package:onexray/onevpn/shell/support_page.dart';
import 'package:onexray/onevpn/theme/premium.dart';
import 'package:onexray/pages/theme/color.dart';
import 'package:onexray/pages/theme/theme.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../support/localizations.dart';
import '../support/viewports.dart';

/// The host router, over [account].
GoRouter _routerOver(ValueListenable<OneVpnAccountState> account) => GoRouter(
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
    GoRoute(
      path: kOneVpnDirectRegionsRoute,
      pageBuilder: (_, state) => OneVpnEdgePage(
        key: state.pageKey,
        stackedEdge: OneVpnRouter.directRegionsEdge(state.extra),
        child: const Scaffold(body: Text('picker')),
      ),
    ),
    GoRoute(
      path: kOneVpnSupportRoute,
      pageBuilder: (_, state) => OneVpnEdgePage.menuDetail(
        key: state.pageKey,
        child: const OneVpnSupportPage(),
      ),
    ),
    // Answers the push with the button the test taps.
    GoRoute(
      path: kOneVpnSignInRoute,
      pageBuilder: (context, state) => OneVpnEdgePage(
        key: state.pageKey,
        stackedEdge:
            (state.extra as OneVpnSignInArgs?)?.edge ?? OneVpnStackedEdge.top,
        child: Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: [
                TextButton(
                  onPressed: () => context.pop(OneVpnSignInMode.signUp),
                  child: const Text('signed up'),
                ),
                TextButton(
                  onPressed: () => context.pop(OneVpnSignInMode.logIn),
                  child: const Text('logged in'),
                ),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('backed out'),
                ),
              ],
            ),
          ),
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

OneVpnSession _session({
  required bool isPremium,
  DateTime? pendingSince,
  String email = 'someone@example.invalid',
}) => OneVpnSession(
  sessionAuthToken: 'token',
  username: 'someone',
  email: email,
  isPremium: isPremium,
  credentials: const OneVpnCredentials(uuid: 'u', publicKey: 'p', shortId: 's'),
  locations: const <OneVpnApiLocation>[],
  premiumPendingSince: pendingSince,
);

Future<void> _pump(
  WidgetTester tester, {
  Size size = kPortraitViewport,
  TextDirection direction = TextDirection.ltr,
  Locale locale = const Locale('en'),
  OneVpnAccountState account = const OneVpnAccountSignedOut(),
}) async {
  await setViewport(tester, size);
  await tester.pumpWidget(
    // The language picker reads the fork language choice.
    BlocProvider(
      create: (_) => OneVpnLocaleChoice(),
      child: MaterialApp.router(
        builder: (_, child) =>
            Directionality(textDirection: direction, child: child!),
        theme: AppTheme.light,
        scrollBehavior: const OneVpnScrollBehavior(),
        locale: locale,
        localizationsDelegates: oneVpnLocalizationsDelegates,
        supportedLocales: [locale],
        routerConfig: _routerOver(ValueNotifier(account)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final l = OneVpnLocalizationsEn();

  testWidgets('the menu carries a Direct regions item routing to the picker', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // The Direct regions item is present, titled by the reused picker key.
    expect(find.text(l.onevpnDirectRegions), findsOneWidget);

    await tester.tap(find.text(l.onevpnDirectRegions));
    await tester.pumpAndSettle();

    // Tapping it pushes the Direct-regions picker route.
    expect(find.text('picker'), findsOneWidget);
  });

  testWidgets('the Language row opens the picker', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final row = find.widgetWithText(ListTile, l.onevpnLanguage);
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.byType(OneVpnLanguagePage), findsOneWidget);
  });

  testWidgets('signed out, the menu offers a Sign up entry', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Account creation is reachable without the purchase funnel. Log in
    // stays its own entry.
    expect(find.text(l.onevpnSignUp), findsOneWidget);
    expect(find.text(l.onevpnLogIn), findsOneWidget);
  });

  testWidgets('a completed sign-up from the menu opens the paywall', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.onevpnSignUp));
    await tester.pumpAndSettle();
    await tester.tap(find.text('signed up'));
    await tester.pumpAndSettle();

    expect(find.text('paywall'), findsOneWidget);
    expect(find.byKey(OneVpnMenu.stackedKey), findsNothing);
  });

  testWidgets('a sign-up completed from the Log in row opens the paywall', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.onevpnLogIn));
    await tester.pumpAndSettle();
    // The user switches to Create account on the auth screen.
    await tester.tap(find.text('signed up'));
    await tester.pumpAndSettle();

    expect(find.text('paywall'), findsOneWidget);
    expect(find.byKey(OneVpnMenu.stackedKey), findsNothing);
  });

  testWidgets('a log-in completed from the Sign up row opens no paywall', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.onevpnSignUp));
    await tester.pumpAndSettle();
    // The user switches to I have an account on the auth screen.
    await tester.tap(find.text('logged in'));
    await tester.pumpAndSettle();

    expect(find.text('paywall'), findsNothing);
    expect(find.byKey(OneVpnMenu.stackedKey), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('a sign-up backed out of returns to the menu', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.onevpnSignUp));
    await tester.pumpAndSettle();
    await tester.tap(find.text('backed out'));
    await tester.pumpAndSettle();

    expect(find.text('paywall'), findsNothing);
    expect(find.text('backed out'), findsNothing);
    expect(find.byKey(OneVpnMenu.stackedKey), findsOneWidget);
  });

  for (final (name, row, page) in [
    ('Direct regions', l.onevpnDirectRegions, find.text('picker')),
    ('Language', l.onevpnLanguage, find.byType(OneVpnLanguagePage)),
    ('Support', l.onevpnSupport, find.byType(OneVpnSupportPage)),
  ]) {
    testWidgets('back from $name returns to the menu', (tester) async {
      await _pump(tester);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(row));
      await tester.pumpAndSettle();
      await tester.tap(find.text(row));
      await tester.pumpAndSettle();
      expect(page, findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(page, findsNothing);
      expect(find.byKey(OneVpnMenu.stackedKey), findsOneWidget);
    });
  }

  for (final size in [kPortraitViewport, kLandscapeViewport]) {
    final split = size == kLandscapeViewport;
    for (final (name, row, page) in [
      ('Direct regions', l.onevpnDirectRegions, find.text('picker')),
      ('the auth screen', l.onevpnSignUp, find.text('signed up')),
    ]) {
      testWidgets('at ${size.width.toInt()}x${size.height.toInt()} $name '
          'comes from the ${split ? 'end' : 'top'} edge', (tester) async {
        await _pump(tester, size: size);
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(row));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final route = ModalRoute.of(tester.element(page))!;
        expect(
          (route.settings as OneVpnEdgePage).stackedEdge,
          OneVpnStackedEdge.top,
        );
        // Mid-slide, the page sits between its edge and its place.
        final surface = find
            .ancestor(of: page, matching: find.byType(Scaffold))
            .first;
        final midway = tester.getTopLeft(surface);
        if (split) {
          expect(midway.dy, 0);
          expect(midway.dx, greaterThan(0));
        } else {
          expect(midway.dx, 0);
          expect(midway.dy, lessThan(0));
        }
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(surface), Offset.zero);
      });
    }
  }

  testWidgets('Upgrade carries the star as a grey outline', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final star = tester.widget<OneVpnPremiumStar>(
      find.byType(OneVpnPremiumStar),
    );
    final palette = ColorManager.palette(tester.element(find.text('open')));
    expect(star.outlined, isTrue);
    expect(star.color, palette.mutedForeground);
    expect(
      find.descendant(
        of: find.byType(OneVpnPremiumStar),
        matching: find.byIcon(LucideIcons.star),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'signed out, every entry is reachable at 360x800 with no overflow',
    (tester) async {
      await _pump(tester);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text(l.onevpnSupport));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(l.onevpnAlwaysOnTitle), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  /// The item titles in on-screen order.
  List<String> itemTitles(WidgetTester tester) => [
    for (final tile in tester.widgetList<ListTile>(find.byType(ListTile)))
      (tile.title! as Text).data!,
  ];

  group('stacked', () {
    testWidgets('the menu is a top drawer with a close button, titled Menu', (
      tester,
    ) async {
      await _pump(tester);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byKey(OneVpnMenu.stackedKey), findsOneWidget);
      expect(find.byKey(OneVpnMenu.drawerKey), findsNothing);
      expect(find.byType(BottomSheet), findsNothing);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text(l.onevpnMenu),
        ),
        findsOneWidget,
      );
      expect(find.byType(CloseButton), findsOneWidget);
      // The drawer is full width, comes from the top edge, and is shorter
      // than the screen.
      final drawer = tester.getRect(find.byKey(OneVpnMenu.stackedKey));
      expect(drawer.top, 0);
      expect(drawer.width, 360);
      expect(drawer.height, lessThan(800));

      await tester.tap(find.byType(CloseButton));
      await tester.pumpAndSettle();
      expect(find.byKey(OneVpnMenu.stackedKey), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('system back closes the top drawer', (tester) async {
      await _pump(tester);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byKey(OneVpnMenu.stackedKey), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('a scrim tap below the top drawer closes it', (tester) async {
      await _pump(tester);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final drawer = tester.getRect(find.byKey(OneVpnMenu.stackedKey));
      await tester.tapAt(Offset(180, (drawer.bottom + 800) / 2));
      await tester.pumpAndSettle();

      expect(find.byKey(OneVpnMenu.stackedKey), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('at text scale 4.0 the top drawer stops at 0.85 of the height '
        'below the top inset', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 4.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      tester.view.padding = const FakeViewPadding(top: 24);
      tester.view.viewPadding = const FakeViewPadding(top: 24);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      await _pump(tester);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final drawer = tester.getRect(find.byKey(OneVpnMenu.stackedKey));
      // The surface runs through the top inset, so its height adds it.
      expect(drawer.height - 24, lessThanOrEqualTo((800 - 24) * 0.85 + 0.01));
      // Anti-vacuity guard. The items overflow, so the cap binds.
      expect(drawer.height - 24, closeTo((800 - 24) * 0.85, 0.5));
      final below = Offset(180, (drawer.bottom + 800) / 2);
      // The scrim point below the surface still takes the tap.
      await tester.tapAt(below);
      await tester.pumpAndSettle();
      expect(find.byKey(OneVpnMenu.stackedKey), findsNothing);
    });

    testWidgets('the top drawer reads as the Menu route', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(
          find
              .ancestor(
                of: find.byKey(OneVpnMenu.stackedKey),
                matching: find.byType(Semantics),
              )
              .first,
        ),
        isSemantics(label: l.onevpnMenu, scopesRoute: true, namesRoute: true),
      );
      semantics.dispose();
    });
  });

  group('split', () {
    Future<void> openDrawer(WidgetTester tester) async {
      await _pump(tester, size: kLandscapeViewport);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    final pane = OneVpnAdaptiveBody.endPane(
      kLandscapeViewport,
      EdgeInsets.zero,
      TextDirection.ltr,
    );

    testWidgets('the drawer covers the end pane under a close button', (
      tester,
    ) async {
      await openDrawer(tester);

      expect(tester.takeException(), isNull);
      expect(find.byKey(OneVpnMenu.stackedKey), findsNothing);
      final drawer = tester.getRect(find.byKey(OneVpnMenu.drawerKey));
      expect(drawer.left, pane.left);
      expect(drawer.right, kLandscapeViewport.width);
      expect(drawer.top, 0);
      expect(drawer.bottom, kLandscapeViewport.height);
      expect(
        find.descendant(
          of: find.byKey(OneVpnMenu.drawerKey),
          matching: find.text(l.onevpnMenu),
        ),
        findsOneWidget,
      );
      final close = find.descendant(
        of: find.byKey(OneVpnMenu.drawerKey),
        matching: find.byType(CloseButton),
      );
      expect(close, findsOneWidget);
      expect(
        find.byTooltip(
          MaterialLocalizations.of(tester.element(close)).closeButtonTooltip,
        ),
        findsOneWidget,
      );
      // The scrim covers the start pane over the screen behind it.
      final scrim = tester.getRect(find.byType(AnimatedModalBarrier));
      expect(scrim, Offset.zero & kLandscapeViewport);
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('the drawer slides in from the end edge as the scrim fades', (
      tester,
    ) async {
      await _pump(tester, size: kLandscapeViewport);
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final drawer = tester.getRect(find.byKey(OneVpnMenu.drawerKey));
      expect(drawer.left, greaterThan(pane.left));
      expect(drawer.left, lessThan(kLandscapeViewport.width));
      final barrier = tester.widget<AnimatedModalBarrier>(
        find.byType(AnimatedModalBarrier),
      );
      final full = ColorManager.palette(
        tester.element(find.byType(AnimatedModalBarrier)),
      ).overlay;
      final midway = barrier.color.value!;
      expect(midway.a, greaterThan(0));
      expect(midway.a, lessThan(full.a));

      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(OneVpnMenu.drawerKey)).left, pane.left);
      expect(barrier.color.value, full);
    });

    testWidgets('the drawer spans the end pane past a start safe inset', (
      tester,
    ) async {
      tester.view.padding = const FakeViewPadding(left: 48);
      tester.view.viewPadding = const FakeViewPadding(left: 48);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      await openDrawer(tester);

      final inset = OneVpnAdaptiveBody.endPane(
        kLandscapeViewport,
        const EdgeInsets.only(left: 48),
        TextDirection.ltr,
      );
      final drawer = tester.getRect(find.byKey(OneVpnMenu.drawerKey));
      expect(drawer.left, inset.left);
      expect(drawer.right, kLandscapeViewport.width);
      expect(tester.takeException(), isNull);
    });

    for (final direction in TextDirection.values) {
      testWidgets('${direction.name}, the list spans the drawer past a start '
          'safe inset', (tester) async {
        final ltr = direction == TextDirection.ltr;
        final inset = FakeViewPadding(left: ltr ? 48 : 0, right: ltr ? 0 : 48);
        tester.view.padding = inset;
        tester.view.viewPadding = inset;
        addTearDown(tester.view.resetPadding);
        addTearDown(tester.view.resetViewPadding);
        await _pump(tester, size: kLandscapeViewport, direction: direction);
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        final drawer = tester.getRect(find.byKey(OneVpnMenu.drawerKey));
        final list = tester.getRect(
          find.descendant(
            of: find.byKey(OneVpnMenu.drawerKey),
            matching: find.byType(Scrollable),
          ),
        );
        final thumb = find.descendant(
          of: find.byKey(OneVpnMenu.drawerKey),
          matching: find.byType(RawScrollbar),
        );
        expect(thumb, findsOneWidget);
        // The drawer's start edge sits mid-screen, on the left in LTR.
        expect(ltr ? list.left : list.right, ltr ? drawer.left : drawer.right);
        expect(ltr ? list.right : list.left, ltr ? drawer.right : drawer.left);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('under a right-to-left locale the drawer mirrors', (
      tester,
    ) async {
      await _pump(
        tester,
        size: kLandscapeViewport,
        direction: TextDirection.rtl,
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final rtl = OneVpnAdaptiveBody.endPane(
        kLandscapeViewport,
        EdgeInsets.zero,
        TextDirection.rtl,
      );
      // It slides in from the left edge.
      final midway = tester.getRect(find.byKey(OneVpnMenu.drawerKey));
      expect(midway.left, lessThan(0));

      await tester.pumpAndSettle();
      final drawer = tester.getRect(find.byKey(OneVpnMenu.drawerKey));
      expect(drawer.left, 0);
      expect(drawer.right, rtl.left + rtl.width);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a scrim tap dismisses the drawer', (tester) async {
      await openDrawer(tester);
      await tester.tapAt(const Offset(100, 180));
      await tester.pumpAndSettle();

      expect(find.byKey(OneVpnMenu.drawerKey), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('the close button dismisses the drawer', (tester) async {
      await openDrawer(tester);
      await tester.tap(find.byType(CloseButton));
      await tester.pumpAndSettle();

      expect(find.byKey(OneVpnMenu.drawerKey), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('system back dismisses the drawer', (tester) async {
      await openDrawer(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byKey(OneVpnMenu.drawerKey), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('a drawer row acts like the page row', (tester) async {
      await openDrawer(tester);
      await tester.tap(find.text(l.onevpnDirectRegions));
      await tester.pumpAndSettle();

      expect(find.byKey(OneVpnMenu.drawerKey), findsNothing);
      expect(find.text('picker'), findsOneWidget);
    });

    testWidgets('a sign-up completed from the drawer opens the paywall', (
      tester,
    ) async {
      await openDrawer(tester);
      await tester.tap(find.text(l.onevpnSignUp));
      await tester.pumpAndSettle();
      await tester.tap(find.text('signed up'));
      await tester.pumpAndSettle();

      expect(find.text('paywall'), findsOneWidget);
    });

    testWidgets(
      'signed out, every entry is reachable at 800x360 with no overflow',
      (tester) async {
        await openDrawer(tester);

        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text(l.onevpnSupport));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(l.onevpnSupport).hitTestable(), findsOneWidget);
        expect(find.text(l.onevpnAlwaysOnTitle), findsOneWidget);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.android),
    );

    testWidgets('the drawer lists the page items in the same order', (
      tester,
    ) async {
      await _pump(tester);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final page = itemTitles(tester);

      await openDrawer(tester);
      expect(itemTitles(tester), page);
      expect(page, [
        l.onevpnUpgrade,
        l.onevpnLogIn,
        l.onevpnSignUp,
        l.onevpnDirectRegions,
        l.onevpnAlwaysOnTitle,
        l.onevpnLanguage,
        l.onevpnSupport,
      ]);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets('a rotation swaps the page and the drawer in place', (
      tester,
    ) async {
      await _pump(tester);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final menu = tester.element(find.byType(OneVpnMenu));
      expect(find.byKey(OneVpnMenu.stackedKey), findsOneWidget);

      await setViewport(tester, kLandscapeViewport);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(OneVpnMenu.stackedKey), findsNothing);
      expect(find.byKey(OneVpnMenu.drawerKey), findsOneWidget);
      expect(tester.getRect(find.byKey(OneVpnMenu.drawerKey)).left, pane.left);
      expect(tester.element(find.byType(OneVpnMenu)), same(menu));

      await setViewport(tester, kPortraitViewport);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(OneVpnMenu.stackedKey), findsOneWidget);
      expect(find.byKey(OneVpnMenu.drawerKey), findsNothing);
      expect(tester.element(find.byType(OneVpnMenu)), same(menu));
    });
  });

  group('the backup domain', () {
    final transport = OneVpnApiTransport.instance;

    setUp(() {
      final previous = SharedPreferencesAsyncPlatform.instance;
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      // Must clear before the restore: the clear writes to the store.
      addTearDown(() async {
        await transport.forgetDomain();
        SharedPreferencesAsyncPlatform.instance = previous;
      });
    });

    testWidgets('shows no menu item: the connect screen carries it', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await const OneVpnPrefsDomainMemory().write(
          OneVpnFailoverDomains.all[1],
        );
        await transport.refreshBackupDomainNotice();
      });
      await _pump(tester);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(transport.backupDomainInUse.value, OneVpnFailoverDomains.all[1]);
      expect(find.byType(OneVpnMenu), findsOneWidget);
      expect(
        find.text(l.onevpnBackupDomainBlocked(OneVpnFailoverDomains.all[1])),
        findsNothing,
      );
    });
  });

  group('the account row', () {
    Future<void> openSignedIn(
      WidgetTester tester, {
      String email = 'someone@example.invalid',
      Locale locale = const Locale('en'),
      TextDirection direction = TextDirection.ltr,
      DateTime? pendingSince,
    }) async {
      await _pump(
        tester,
        locale: locale,
        direction: direction,
        account: OneVpnAccountSignedIn(
          _session(isPremium: false, email: email, pendingSince: pendingSince),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    /// The dot and the plan, as the row renders them.
    String tail(String plan) => '${OneVpnAccountLine.separator}$plan';

    /// The dot and the plan's Text, matched by what it paints. Its plain text
    /// for screen readers leaves out the dot.
    Finder findTail(String plan) => find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          widget.textSpan?.toPlainText(includeSemanticsLabels: false) ==
              tail(plan),
    );

    RenderParagraph paragraph(WidgetTester tester, Finder finder) =>
        tester.renderObject<RenderParagraph>(finder);

    /// Expects the name, the dot, and the plan on one line in one row.
    void expectOneLine(WidgetTester tester, String name, String plan) {
      final line = find.byType(OneVpnAccountLine);
      expect(line, findsOneWidget);
      final parts = [find.text(name), findTail(plan)];
      for (final part in parts) {
        expect(
          find.descendant(of: line, matching: part),
          findsOneWidget,
          reason: '$part',
        );
        // A single line is as tall as the row.
        expect(tester.getSize(part).height, tester.getSize(line).height);
      }
      expect(tester.getCenter(parts.first).dy, tester.getCenter(parts.last).dy);
      expect(tester.takeException(), isNull);
    }

    testWidgets('in English it reads the email, a dot, and the plan on one '
        'line', (tester) async {
      await openSignedIn(tester);

      expectOneLine(tester, 'someone@example.invalid', l.onevpnPlanFree);
      final name = tester.getRect(find.text('someone@example.invalid'));
      final plan = tester.getRect(findTail(l.onevpnPlanFree));
      expect(name.right, lessThanOrEqualTo(plan.left));
      expect(
        paragraph(tester, findTail(l.onevpnPlanFree)).text.style?.color,
        ColorManager.palette(tester.element(find.byType(OneVpnAccountLine)))
            .mutedForeground,
      );
    });

    testWidgets('under Arabic it reads right to left on one line', (
      tester,
    ) async {
      await openSignedIn(
        tester,
        locale: const Locale('ar'),
        direction: TextDirection.rtl,
      );

      final ar = OneVpnLocalizationsAr();
      expectOneLine(tester, 'someone@example.invalid', ar.onevpnPlanFree);
      // The name sits at the start edge, on the right.
      final name = tester.getRect(find.text('someone@example.invalid'));
      final plan = tester.getRect(findTail(ar.onevpnPlanFree));
      expect(plan.right, lessThanOrEqualTo(name.left));
    });

    testWidgets('a long email ends in an ellipsis and the plan shows whole '
        'at 360 wide', (tester) async {
      final email = '${'a' * 80}@example.invalid';
      await openSignedIn(tester, email: email);

      expectOneLine(tester, email, l.onevpnPlanFree);
      expect(paragraph(tester, find.text(email)).didExceedMaxLines, isTrue);
      expect(
        paragraph(tester, findTail(l.onevpnPlanFree)).didExceedMaxLines,
        isFalse,
      );
      expect(
        tester.getRect(find.byType(OneVpnAccountLine)).right,
        lessThanOrEqualTo(kPortraitViewport.width),
      );
    });

    /// Expects the name above the plan, each whole, with no separator.
    void expectTwoLines(WidgetTester tester, String name, String plan) {
      final line = find.byType(OneVpnAccountLine);
      expect(line, findsOneWidget);
      final nameText = find.descendant(of: line, matching: find.text(name));
      final planText = find.descendant(of: line, matching: find.text(plan));
      expect(nameText, findsOneWidget);
      expect(planText, findsOneWidget);
      expect(findTail(plan), findsNothing);
      expect(
        tester.getRect(nameText).bottom,
        lessThanOrEqualTo(tester.getRect(planText).top),
      );
      // The name keeps the full row width, so a long one still shows.
      expect(tester.getSize(nameText).width, tester.getSize(line).width);
      expect(paragraph(tester, planText).didExceedMaxLines, isFalse);
      expect(
        paragraph(tester, planText).text.style?.color,
        ColorManager.palette(tester.element(line)).mutedForeground,
      );
      expect(
        tester.getRect(line).right,
        lessThanOrEqualTo(kPortraitViewport.width),
      );
      expect(tester.takeException(), isNull);
    }

    testWidgets('at text scale 2.0 the email sits above the plan at 360 '
        'wide', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await openSignedIn(tester);

      expectTwoLines(tester, 'someone@example.invalid', l.onevpnPlanFree);
    });

    testWidgets('the pending plan sits below the email at text scale 1.0', (
      tester,
    ) async {
      await openSignedIn(tester, pendingSince: DateTime.utc(2026, 9, 21));

      expectTwoLines(
        tester,
        'someone@example.invalid',
        l.onevpnPlanPremiumPending,
      );
    });

    testWidgets('text scale 1.3 keeps the one-line form', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await openSignedIn(tester);

      expect(findTail(l.onevpnPlanFree), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('screen readers read the two-line form without a separator', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await openSignedIn(tester);

      final tile = find.ancestor(
        of: find.byType(OneVpnAccountLine),
        matching: find.byType(ListTile),
      );
      final label = tester.getSemantics(tile).label;
      expect(label, contains('someone@example.invalid'));
      expect(label, contains(l.onevpnPlanFree));
      expect(label, isNot(contains('\u00b7')));
      semantics.dispose();
    });

    testWidgets('screen readers read the name and the plan without the dot', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await openSignedIn(tester);

      final tile = find.ancestor(
        of: find.byType(OneVpnAccountLine),
        matching: find.byType(ListTile),
      );
      final label = tester.getSemantics(tile).label;
      expect(label, contains('someone@example.invalid'));
      expect(label, contains(l.onevpnPlanFree));
      expect(label, isNot(contains('\u00b7')));
      semantics.dispose();
    });
  });

  group('the account row plan line', () {
    test('a free account reads as free', () {
      expect(
        OneVpnAccountPlanLabel.of(l, _session(isPremium: false)),
        l.onevpnPlanFree,
      );
    });

    test('a confirmed account reads as premium', () {
      expect(
        OneVpnAccountPlanLabel.of(l, _session(isPremium: true)),
        l.onevpnPlanPremium,
      );
    });

    test('a purchase awaiting confirmation reads as confirming', () {
      final pending = _session(
        isPremium: false,
        pendingSince: DateTime.utc(2026, 9, 21),
      );

      // The account is entitled, so no surface shows Free after the
      // purchase. The row says the confirmation is outstanding. It makes no
      // promise that the confirmation will come.
      expect(pending.isPremiumEntitled, isTrue);
      expect(OneVpnAccountPlanLabel.of(l, pending), l.onevpnPlanPremiumPending);
      expect(l.onevpnPlanPremiumPending, isNot(l.onevpnPlanPremium));
    });
  });
}
