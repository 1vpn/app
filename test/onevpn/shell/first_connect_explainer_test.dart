// The first-connect explainer: the once-ever gate and the non-blocking page.
// The product default leaves the gate off: every connect proceeds and nothing
// stamps. An enabled gate returns true on the first connect only and stamps
// the fork flag. A later connect returns false, and the page never re-shows.
// The page comes up from the bottom edge under a close app bar. The headline
// card holds the title and what a full tunnel breaks. Two points follow on
// the card's inset, and then both buttons. The direct point names the real
// IP. The primary button routes to the
// Direct-regions picker, which comes from the bottom edge, or the end edge in
// split. Not now, the close button, and system back return without routing,
// so the caller proceeds to connect.
// An enabled gate whose store throws resolves false, and the connect proceeds.
//
// At 360x800 the page stacks in one capped column. At 800x360 the card and
// the points fill the start pane. Both buttons center in the end pane, so
// Not now never sits below the fold. Both layouts report no overflow, and a
// rotation re-lays out in place.

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/l10n/localizations/app_localizations.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations_en.dart';
import 'package:onexray/onevpn/shell/edge_route.dart';
import 'package:onexray/onevpn/shell/first_connect_explainer.dart';
import 'package:onexray/onevpn/shell/layout.dart';
import 'package:onexray/onevpn/shell/router.dart';
import 'package:onexray/onevpn/shell/routes.dart';
import 'package:onexray/onevpn/theme/headline_card.dart';
import 'package:onexray/pages/theme/theme.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/localizations.dart';
import '../support/viewports.dart';

/// A router whose home screen opens the explainer. Its picker route renders
/// a marker, so a test can observe a navigation.
GoRouter _router() => GoRouter(
  initialLocation: kOneVpnConnectRoute,
  routes: [
    GoRoute(
      path: kOneVpnConnectRoute,
      builder: (context, _) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => showOneVpnFirstConnectExplainer(context),
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
    ...OneVpnRouter.menuSurfaces(),
  ],
);

Future<void> _pump(WidgetTester tester, {Size size = kPortraitViewport}) async {
  await setViewport(tester, size);
  await tester.pumpWidget(
    MaterialApp.router(
      theme: AppTheme.light,
      locale: const Locale('en'),
      localizationsDelegates: oneVpnLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _router(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Preferences whose boolean reads or writes throw for the explainer's key.
final class _FailingSeenKey extends InMemorySharedPreferencesAsync {
  _FailingSeenKey({required this.readThrows, required this.writeThrows})
    : super.empty();

  final bool readThrows;
  final bool writeThrows;

  @override
  Future<bool?> getBool(String key, SharedPreferencesOptions options) =>
      readThrows && key == OneVpnFirstConnectExplainer.seenKey
      ? Future<bool?>.error(StateError('prefs unavailable'))
      : super.getBool(key, options);

  @override
  Future<bool> setBool(
    String key,
    bool value,
    SharedPreferencesOptions options,
  ) => writeThrows && key == OneVpnFirstConnectExplainer.seenKey
      ? Future<bool>.error(StateError('prefs unavailable'))
      : super.setBool(key, value, options);
}

void main() {
  final l = OneVpnLocalizationsEn();

  group('the once-ever gate', () {
    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
    });

    test('is off by default: it never fires and never stamps', () async {
      expect(OneVpnFirstConnectExplainer.enabledByDefault, isFalse);
      final explainer = OneVpnFirstConnectExplainer();
      expect(explainer.enabled, isFalse);
      expect(await explainer.consumeFirstConnect(), isFalse);
      expect(await explainer.consumeFirstConnect(), isFalse);
      expect(
        await SharedPreferencesAsync().getBool(
          OneVpnFirstConnectExplainer.seenKey,
        ),
        isNull,
      );
    });

    test('enabled, it fires once and stamps the fork flag', () async {
      final explainer = OneVpnFirstConnectExplainer(enabled: true);

      // Anti-vacuity: a fresh install has not stamped the flag.
      expect(
        await SharedPreferencesAsync().getBool(
          OneVpnFirstConnectExplainer.seenKey,
        ),
        isNull,
      );

      // The first connect fires the explainer and stamps.
      expect(await explainer.consumeFirstConnect(), isTrue);
      expect(
        await SharedPreferencesAsync().getBool(
          OneVpnFirstConnectExplainer.seenKey,
        ),
        isTrue,
      );

      // Every later connect skips it.
      expect(await explainer.consumeFirstConnect(), isFalse);
      expect(await explainer.consumeFirstConnect(), isFalse);
    });

    test('enabled, a stamped flag never re-shows across instances', () async {
      await SharedPreferencesAsync().setBool(
        OneVpnFirstConnectExplainer.seenKey,
        true,
      );
      // A fresh instance reads the stamped flag and skips.
      expect(
        await OneVpnFirstConnectExplainer(enabled: true).consumeFirstConnect(),
        isFalse,
      );
    });

    for (final (name, read, write) in const [
      ('read', true, false),
      ('stamp', false, true),
    ]) {
      test('enabled, a $name that throws resolves false', () async {
        SharedPreferencesAsyncPlatform.instance = _FailingSeenKey(
          readThrows: read,
          writeThrows: write,
        );
        expect(
          await OneVpnFirstConnectExplainer(enabled: true)
              .consumeFirstConnect(),
          isFalse,
        );
      });
    }
  });

  testWidgets('the page renders the approved copy and both buttons', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expectCopy(tester, l);
    expect(l.onevpnFirstConnectPointDirect, contains('real IP'));
  });

  testWidgets('the page comes up from the bottom edge', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final page = find.byType(OneVpnFirstConnectPage);
    final route = ModalRoute.of(tester.element(page))!;
    expect(
      (route.settings as OneVpnEdgePage).stackedEdge,
      OneVpnStackedEdge.bottom,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('the primary button routes to the Direct-regions picker', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l.onevpnFirstConnectChooseRegion));
    await tester.pumpAndSettle();

    // The picker route is pushed.
    expect(find.text('picker'), findsOneWidget);
  });

  for (final size in [kPortraitViewport, kLandscapeViewport]) {
    final split = size == kLandscapeViewport;
    testWidgets('at ${size.width.toInt()}x${size.height.toInt()} the picker '
        'comes from the ${split ? 'end' : 'bottom'} edge', (tester) async {
      await _pump(tester, size: size);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.onevpnFirstConnectChooseRegion));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final page = find.text('picker');
      final route = ModalRoute.of(tester.element(page))!;
      expect(
        (route.settings as OneVpnEdgePage).stackedEdge,
        OneVpnStackedEdge.bottom,
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
        expect(midway.dy, greaterThan(0));
      }
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(surface), Offset.zero);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('dismissing returns without routing (non-blocking)', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l.onevpnFirstConnectDismiss));
    await tester.pumpAndSettle();

    // The page closes with no navigation. The caller proceeds.
    expect(find.text('picker'), findsNothing);
    expect(find.text(l.onevpnFirstConnectTitle), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('the close button returns without routing', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text(l.onevpnDirectRegions), findsOneWidget);
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();

    expect(find.text('picker'), findsNothing);
    expect(find.text(l.onevpnFirstConnectTitle), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('system back returns without routing', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('picker'), findsNothing);
    expect(find.text(l.onevpnFirstConnectTitle), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  Finder inPane(Key pane, Finder finder) =>
      find.descendant(of: find.byKey(pane), matching: finder);

  testWidgets('at 360x800 the page stacks with no overflow', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final page = find.byType(OneVpnFirstConnectPage);
    expect(tester.getRect(page), Offset.zero & kPortraitViewport);
    expect(
      find.descendant(
        of: page,
        matching: find.byKey(OneVpnConstrainedBody.stackedKey),
      ),
      findsOneWidget,
    );
    expect(find.byKey(OneVpnAdaptiveBody.splitKey), findsNothing);
    expectCopy(tester, l);
    // The card, then the two points, then the buttons, top to bottom.
    final card = tester.getRect(find.byType(OneVpnHeadlineCard));
    final direct = tester.getRect(find.text(l.onevpnFirstConnectPointDirect));
    final protected = tester.getRect(
      find.text(l.onevpnFirstConnectPointProtected),
    );
    final choose = tester.getRect(find.text(l.onevpnFirstConnectChooseRegion));
    final dismiss = tester.getRect(find.text(l.onevpnFirstConnectDismiss));
    expect(card.bottom, lessThan(direct.top));
    expect(direct.bottom, lessThan(protected.top));
    expect(protected.bottom, lessThan(choose.top));
    expect(choose.bottom, lessThan(dismiss.top));
    // The points' text starts where the card's title starts.
    final title = tester.getRect(find.text(l.onevpnFirstConnectTitle));
    expect(direct.left, moreOrLessEquals(title.left, epsilon: 0.5));
    expect(protected.left, moreOrLessEquals(title.left, epsilon: 0.5));
  });

  testWidgets('at 800x360 the page splits with no overflow', (tester) async {
    await _pump(tester, size: kLandscapeViewport);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(OneVpnAdaptiveBody.splitKey), findsOneWidget);
    expect(find.byKey(OneVpnConstrainedBody.stackedKey), findsNothing);
    expectCopy(tester, l);
    const start = OneVpnAdaptiveBody.startPaneKey;
    const end = OneVpnAdaptiveBody.endPaneKey;
    expect(inPane(start, find.byType(OneVpnHeadlineCard)), findsOneWidget);
    for (final text in [
      l.onevpnFirstConnectPointDirect,
      l.onevpnFirstConnectPointProtected,
    ]) {
      expect(inPane(start, find.text(text)), findsOneWidget, reason: text);
    }
    for (final text in [
      l.onevpnFirstConnectChooseRegion,
      l.onevpnFirstConnectDismiss,
    ]) {
      expect(inPane(end, find.text(text)), findsOneWidget, reason: text);
    }
    expect(
      find.text(l.onevpnFirstConnectDismiss).hitTestable(),
      findsOneWidget,
    );
  });

  testWidgets('in split, both buttons center in the end pane', (tester) async {
    await _pump(tester, size: kLandscapeViewport);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final pane = tester.getRect(find.byKey(OneVpnAdaptiveBody.endPaneKey));
    final top = tester
        .getRect(
          find.ancestor(
            of: find.text(l.onevpnFirstConnectChooseRegion),
            matching: find.byType(FilledButton),
          ),
        )
        .top;
    final bottom = tester
        .getRect(
          find.ancestor(
            of: find.text(l.onevpnFirstConnectDismiss),
            matching: find.byType(OutlinedButton),
          ),
        )
        .bottom;
    expect(top - pane.top, moreOrLessEquals(pane.bottom - bottom, epsilon: 1));
    expect(top, greaterThan(pane.top));
  });

  testWidgets('in split at 1.3x text, Not now shows with no scroll', (
    tester,
  ) async {
    // A status-bar inset and a larger text size push the start pane past its
    // height. The buttons keep their own pane.
    tester.view.padding = const FakeViewPadding(top: 24);
    tester.view.viewPadding = const FakeViewPadding(top: 24);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pump(tester, size: kLandscapeViewport);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    for (final label in [
      l.onevpnFirstConnectChooseRegion,
      l.onevpnFirstConnectDismiss,
    ]) {
      expect(find.text(label).hitTestable(), findsOneWidget, reason: label);
      expect(
        tester.getRect(find.text(label)).bottom,
        lessThanOrEqualTo(kLandscapeViewport.height),
      );
    }
    await tester.tap(find.text(l.onevpnFirstConnectDismiss));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('in split, Not now still returns without routing', (
    tester,
  ) async {
    await _pump(tester, size: kLandscapeViewport);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.onevpnFirstConnectDismiss));
    await tester.pumpAndSettle();

    expect(find.text('picker'), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('a rotation re-lays out the page in place', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final page = tester.element(find.byType(OneVpnFirstConnectPage));

    await setViewport(tester, kLandscapeViewport);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(OneVpnAdaptiveBody.splitKey), findsOneWidget);
    expect(tester.element(find.byType(OneVpnFirstConnectPage)), same(page));

    await setViewport(tester, kPortraitViewport);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(OneVpnAdaptiveBody.splitKey), findsNothing);
    expect(tester.element(find.byType(OneVpnFirstConnectPage)), same(page));
  });
}

/// The copy, both buttons, and the two point glyphs resolve once each. The
/// card leads with the route glyph and the direct point repeats it.
void expectCopy(WidgetTester tester, OneVpnLocalizationsEn l) {
  expect(find.text(l.onevpnFirstConnectTitle), findsOneWidget);
  expect(find.text(l.onevpnFirstConnectPointBreaks), findsOneWidget);
  expect(find.text(l.onevpnFirstConnectPointDirect), findsOneWidget);
  expect(find.text(l.onevpnFirstConnectPointProtected), findsOneWidget);
  expect(find.text(l.onevpnFirstConnectChooseRegion), findsOneWidget);
  expect(find.text(l.onevpnFirstConnectDismiss), findsOneWidget);
  expect(find.byIcon(LucideIcons.route), findsNWidgets(2));
  expect(find.byIcon(LucideIcons.shieldCheck), findsOneWidget);
  expect(
    find.descendant(
      of: find.byType(OneVpnHeadlineCard),
      matching: find.text(l.onevpnFirstConnectPointBreaks),
    ),
    findsOneWidget,
  );
}
