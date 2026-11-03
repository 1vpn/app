// The connect screen in both layout modes.
//
// At 360x800 the screen stacks: the control over the location row and the
// upgrade banner. At 800x360 it splits. The control and the status label
// fill the start pane. The location row and the banner fill the end pane,
// with no divider between them. Both viewports report no overflow and
// resolve the screen's keys. The split holds at the breakpoint edges, and a
// rotation re-lays out in place. A 1024x768 tablet splits with each pane
// capped at 420dp. In split, a snack bar anchors to the end pane and the
// hamburger opens the drawer over it.

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/l10n/localizations/app_localizations.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations_en.dart';
import 'package:onexray/onevpn/location/flag.dart';
import 'package:onexray/onevpn/paywall/paywall_cadence.dart';
import 'package:onexray/onevpn/paywall/paywall_trigger.dart';
import 'package:onexray/onevpn/shell/connect_control.dart';
import 'package:onexray/onevpn/shell/connect_screen.dart';
import 'package:onexray/onevpn/shell/layout.dart';
import 'package:onexray/onevpn/shell/menu.dart';
import 'package:onexray/onevpn/shell/route_indicator.dart';
import 'package:onexray/onevpn/shell/router.dart';
import 'package:onexray/onevpn/shell/routes.dart';
import 'package:onexray/onevpn/theme/backdrop.dart';
import 'package:onexray/onevpn/theme/brand_lockup.dart';
import 'package:onexray/onevpn/theme/card.dart';
import 'package:onexray/onevpn/theme/premium.dart';
import 'package:onexray/pages/theme/color.dart';
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

/// A coordinator whose commands do nothing. Tests set [state] directly.
class _ScriptedCoordinator extends ConnectionCoordinator {
  _ScriptedCoordinator()
    : super(
        statusEvents: const Stream.empty(),
        observeStatus: () async {},
        disposeStatus: () {},
      );

  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}

  @override
  void cancel() {}

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

const _bannerKey = ValueKey('onevpn-upgrade-banner');

void main() {
  final l = OneVpnLocalizationsEn();
  late _ScriptedCoordinator coordinator;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  /// Mounts the connect screen at the router root at [size], with the menu
  /// surfaces pushable over it.
  Future<void> pump(WidgetTester tester, Size size) async {
    coordinator = _ScriptedCoordinator();
    stubInvokeChannel();
    await setViewport(tester, size);
    final router = GoRouter(
      initialLocation: kOneVpnConnectRoute,
      routes: [
        GoRoute(
          path: kOneVpnConnectRoute,
          builder: (_, _) => OneVpnConnectScreen(
            coordinator: coordinator,
            paywallTrigger: OneVpnPaywallTrigger(
              cadence: OneVpnPaywallCadence(now: DateTime.now),
              audience: _EntitledAudience(),
            ),
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

  /// The screen's keys and landmarks resolve once each.
  void expectKeys() {
    expect(find.byType(OneVpnConnectControl), findsOneWidget);
    expect(find.byKey(OneVpnConnectControl.trackKey), findsOneWidget);
    expect(find.byKey(OneVpnConnectControl.thumbKey), findsOneWidget);
    expect(find.byType(OneVpnRouteIndicator), findsOneWidget);
    expect(find.byType(OneVpnBrandLockup), findsOneWidget);
    expect(find.byIcon(LucideIcons.zap), findsOneWidget);
    expect(find.byKey(_bannerKey), findsOneWidget);
    expect(find.text(l.onevpnDisconnected), findsOneWidget);
  }

  Finder inPane(Key pane, Finder finder) =>
      find.descendant(of: find.byKey(pane), matching: finder);

  for (final size in [kPortraitViewport, kLandscapeViewport]) {
    testWidgets('at ${size.width.toInt()}x${size.height.toInt()} the bolt and '
        'the star sit on flag-sized squares, and the row and banner text '
        'start at one x', (tester) async {
      await pump(tester, size);
      expect(tester.takeException(), isNull);

      final bolt = find.ancestor(
        of: find.byIcon(LucideIcons.zap),
        matching: find.byType(OneVpnBackdropSquare),
      );
      final star = find.ancestor(
        of: find.byType(OneVpnPremiumStar),
        matching: find.byType(OneVpnBackdropSquare),
      );
      final palette = ColorManager.palette(tester.element(bolt));
      expect(tester.getSize(bolt), const Size.square(OneVpnFlag.defaultSize));
      expect(tester.getSize(star), const Size.square(OneVpnFlag.defaultSize));
      expect(
        tester.widget<OneVpnBackdropSquare>(bolt).color,
        OneVpnBackdrop.tint(palette),
      );
      expect(
        tester.getTopLeft(find.text(l.onevpnAutomaticSelection)).dx,
        tester.getTopLeft(find.text(l.onevpnUpgradeBannerTitle)).dx,
      );
      expect(find.text(l.onevpnUpgradeBannerSubtitle), findsOneWidget);
    });
  }

  testWidgets('at 360x800 the screen stacks with no overflow', (tester) async {
    await pump(tester, kPortraitViewport);

    expect(tester.takeException(), isNull);
    expect(find.byKey(OneVpnConstrainedBody.stackedKey), findsOneWidget);
    expect(find.byKey(OneVpnAdaptiveBody.splitKey), findsNothing);
    expectKeys();
    // The stacked column: the control above the row, the row above the banner.
    final control = tester.getRect(find.byType(OneVpnConnectControl));
    final row = tester.getRect(find.byIcon(LucideIcons.zap));
    final banner = tester.getRect(find.byKey(_bannerKey));
    expect(control.bottom, lessThan(row.top));
    expect(row.bottom, lessThan(banner.top));
    expect(banner.width, 360 - 2 * OneVpnCard.margin);
  });

  testWidgets('at 800x360 the screen splits with no overflow', (tester) async {
    await pump(tester, kLandscapeViewport);

    expect(tester.takeException(), isNull);
    expect(find.byKey(OneVpnAdaptiveBody.splitKey), findsOneWidget);
    expect(find.byKey(OneVpnConstrainedBody.stackedKey), findsNothing);
    expectKeys();
    const start = OneVpnAdaptiveBody.startPaneKey;
    const end = OneVpnAdaptiveBody.endPaneKey;
    expect(inPane(start, find.byType(OneVpnConnectControl)), findsOneWidget);
    expect(inPane(start, find.text(l.onevpnDisconnected)), findsOneWidget);
    expect(inPane(end, find.byIcon(LucideIcons.zap)), findsOneWidget);
    expect(inPane(end, find.byKey(_bannerKey)), findsOneWidget);
    // No divider sits between the panes.
    expect(find.byType(VerticalDivider), findsNothing);
  });

  testWidgets('the screen splits at the breakpoint edges only', (tester) async {
    for (final entry in {
      const Size(599, 360): OneVpnConstrainedBody.stackedKey,
      const Size(600, 360): OneVpnAdaptiveBody.splitKey,
      const Size(600, 600): OneVpnConstrainedBody.stackedKey,
    }.entries) {
      await pump(tester, entry.key);
      expect(tester.takeException(), isNull, reason: '${entry.key}');
      expect(find.byKey(entry.value), findsOneWidget, reason: '${entry.key}');
    }
  });

  testWidgets('a rotation re-lays out in place', (tester) async {
    await pump(tester, kPortraitViewport);
    final screen = tester.state(find.byType(OneVpnConnectScreen));
    coordinator.state.value = const ConnectionView(
      phase: ConnectionPhase.connected,
    );
    await _settle(tester);

    await setViewport(tester, kLandscapeViewport);
    await _settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.byKey(OneVpnAdaptiveBody.splitKey), findsOneWidget);
    expect(tester.state(find.byType(OneVpnConnectScreen)), same(screen));
    expect(find.text(l.onevpnConnected), findsOneWidget);

    await setViewport(tester, kPortraitViewport);
    await _settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.byKey(OneVpnConstrainedBody.stackedKey), findsOneWidget);
    expect(tester.state(find.byType(OneVpnConnectScreen)), same(screen));
    expect(find.text(l.onevpnConnected), findsOneWidget);
  });

  testWidgets('a rotation keeps the control focused', (tester) async {
    await pump(tester, kPortraitViewport);
    final gesture = find.descendant(
      of: find.byType(OneVpnConnectControl),
      matching: find.byType(GestureDetector),
    );
    final node = Focus.of(tester.element(gesture.first));
    node.requestFocus();
    await tester.pump();
    expect(node.hasPrimaryFocus, isTrue);

    await setViewport(tester, kLandscapeViewport);
    await _settle(tester);
    expect(find.byKey(OneVpnAdaptiveBody.splitKey), findsOneWidget);
    expect(FocusManager.instance.primaryFocus, same(node));
    expect(node.hasPrimaryFocus, isTrue);
  });

  testWidgets('past a start safe inset the drawer and the snack bar anchor '
      'to the end pane', (tester) async {
    tester.view.padding = const FakeViewPadding(left: 48);
    tester.view.viewPadding = const FakeViewPadding(left: 48);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    await pump(tester, kLandscapeViewport);
    final pane = tester.getRect(find.byKey(OneVpnAdaptiveBody.endPaneKey));
    expect(pane.left, greaterThan((800 + 48) / 2));

    ScaffoldMessenger.of(tester.element(find.byType(OneVpnConnectControl)))
        .showSnackBar(const SnackBar(content: Text('saved')));
    await _settle(tester);
    final snackBar = tester.getRect(
      find
          .descendant(
            of: find.byType(SnackBar),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(snackBar.left, pane.left + OneVpnSnackBarAnchor.fallbackInsets.left);
    expect(
      snackBar.right,
      pane.right - OneVpnSnackBarAnchor.fallbackInsets.right,
    );

    await tester.tap(find.byTooltip(l.onevpnMenu));
    await _settle(tester);
    final drawer = tester.getRect(find.byKey(OneVpnMenu.drawerKey));
    expect(drawer.left, pane.left);
    expect(drawer.right, 800);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a 1024x768 tablet splits with each pane capped', (tester) async {
    await pump(tester, kTabletLandscapeViewport);

    expect(tester.takeException(), isNull);
    expect(find.byKey(OneVpnAdaptiveBody.splitKey), findsOneWidget);
    expectKeys();
    final start = tester.getRect(find.byKey(OneVpnAdaptiveBody.startPaneKey));
    final end = tester.getRect(find.byKey(OneVpnAdaptiveBody.endPaneKey));
    final control = tester.getRect(find.byType(OneVpnConnectControl));
    final banner = tester.getRect(find.byKey(_bannerKey));
    expect(control.center.dx, closeTo(start.center.dx, 0.01));
    // The control and the status label center together. The detail line
    // hangs below them.
    final status = tester.getRect(find.text(l.onevpnDisconnected));
    expect((control.top + status.bottom) / 2, closeTo(start.center.dy, 0.5));
    // The banner's card-margin side insets sit inside the 420dp pane cap.
    expect(banner.width, OneVpnLayout.paneCap - 2 * OneVpnCard.margin);
    expect(banner.center.dx, closeTo(end.center.dx, 0.01));
  });

  testWidgets('a snack bar anchors to the end pane in split', (tester) async {
    await pump(tester, kLandscapeViewport);
    ScaffoldMessenger.of(tester.element(find.byType(OneVpnConnectControl)))
        .showSnackBar(const SnackBar(content: Text('saved')));
    await _settle(tester);

    final pane = tester.getRect(find.byKey(OneVpnAdaptiveBody.endPaneKey));
    final snackBar = tester.getRect(
      find
          .descendant(
            of: find.byType(SnackBar),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(snackBar.left, greaterThanOrEqualTo(pane.left));
    expect(snackBar.right, lessThanOrEqualTo(pane.right));
  });

  testWidgets('the hamburger opens the menu page when stacked', (tester) async {
    await pump(tester, kPortraitViewport);
    await tester.tap(find.byTooltip(l.onevpnMenu));
    await _settle(tester);

    expect(find.byKey(OneVpnMenu.stackedKey), findsOneWidget);
    expect(find.byKey(OneVpnMenu.drawerKey), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the hamburger opens the drawer over the end pane in split', (
    tester,
  ) async {
    await pump(tester, kLandscapeViewport);
    final pane = tester.getRect(find.byKey(OneVpnAdaptiveBody.endPaneKey));
    await tester.tap(find.byTooltip(l.onevpnMenu));
    await _settle(tester);

    expect(find.byKey(OneVpnMenu.stackedKey), findsNothing);
    final drawer = tester.getRect(find.byKey(OneVpnMenu.drawerKey));
    expect(drawer.left, pane.left);
    expect(drawer.right, 800);
    expect(drawer.top, 0);
    expect(drawer.bottom, 360);
    // The connect screen stays mounted under the scrim.
    expect(find.byType(OneVpnConnectControl), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
