// Swipe-to-close on edge routes. The tests cover:
//
//   * flicks and slow releases on both sides of each threshold
//   * the list handoff at a list's closing edge, and the hand-back to
//     scrolling
//   * the split end edge, and mouse and trackpad drags
//   * a vetoed pop
//   * a rotation, a pop, a push, or a removed list mid-swipe
//   * the drawer's Esc and swipe
//
// Every release leaves no user gesture in progress.

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/onevpn/shell/edge_dismiss.dart';
import 'package:onexray/onevpn/shell/edge_route.dart';
import 'package:onexray/pages/theme/theme.dart';

import '../support/viewports.dart';

const _surface = ValueKey('surface');

/// A page whose list takes the edge route's handoff controller.
class _ListPage extends StatelessWidget {
  const _ListPage({this.rows = 60});

  final int rows;

  @override
  Widget build(BuildContext context) => Scaffold(
    key: _surface,
    appBar: AppBar(title: const Text('Page')),
    body: ListView(
      controller: OneVpnEdgeScope.scrollControllerOf(context),
      children: [
        for (var i = 0; i < rows; i++)
          SizedBox(height: 48, child: Text('row $i')),
      ],
    ),
  );
}

/// A page with two lists that share the edge route's handoff controller.
class _TwoListPage extends StatelessWidget {
  const _TwoListPage();

  @override
  Widget build(BuildContext context) {
    final controller = OneVpnEdgeScope.scrollControllerOf(context);
    Widget list(String name) => Expanded(
      child: ListView(
        controller: controller,
        children: [
          for (var i = 0; i < 30; i++)
            SizedBox(height: 48, child: Text('$name $i')),
        ],
      ),
    );
    return Scaffold(
      key: _surface,
      body: Column(children: [list('first'), list('second')]),
    );
  }
}

Future<void> _pump(
  WidgetTester tester, {
  required Page<Object?> Function(Widget child) page,
  Widget child = const _ListPage(),
  Size size = kPortraitViewport,
  TextDirection direction = TextDirection.ltr,
}) async {
  await setViewport(tester, size);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => context.push('/edge'),
              child: const Text('open'),
            ),
          ),
        ),
        routes: [GoRoute(path: 'edge', pageBuilder: (_, _) => page(child))],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: router,
      builder: (context, child) =>
          Directionality(textDirection: direction, child: child!),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  expect(find.byKey(_surface), findsOneWidget);
}

Page<Object?> _bottom(Widget child) => OneVpnEdgePage.fromBottom(child: child);
Page<Object?> _top(Widget child) => OneVpnEdgePage.menuDetail(child: child);

NavigatorState _navigator(WidgetTester tester) =>
    tester.state<NavigatorState>(find.byType(Navigator).first);

void _expectNoGesture(WidgetTester tester) =>
    expect(_navigator(tester).userGestureInProgress, isFalse);

void _expectClosed(WidgetTester tester) {
  expect(find.byKey(_surface), findsNothing);
  expect(find.text('open'), findsOneWidget);
  _expectNoGesture(tester);
}

void _expectOpen(WidgetTester tester) {
  expect(find.byKey(_surface), findsOneWidget);
  expect(tester.getTopLeft(find.byKey(_surface)), Offset.zero);
  _expectNoGesture(tester);
}

/// The edge route's animation value: 1 is fully open.
double _openness(WidgetTester tester) =>
    ModalRoute.of(tester.element(find.byKey(_surface)))!.animation!.value;

/// The scroll offset of the first list on the surface.
double _listOffset(WidgetTester tester) => tester
    .state<ScrollableState>(
      find
          .descendant(
            of: find.byKey(_surface),
            matching: find.byType(Scrollable),
          )
          .first,
    )
    .position
    .pixels;

/// A touch gesture with timed moves, so a release carries the finger's real
/// velocity.
class _Finger {
  _Finger._(this._tester, this._gesture);

  static Future<_Finger> down(WidgetTester tester, Offset at) async =>
      _Finger._(tester, await tester.startGesture(at));

  final WidgetTester _tester;
  final TestGesture _gesture;
  Duration _time = Duration.zero;

  /// Moves [by] in [steps] equal moves, [every] apart.
  Future<void> move(
    Offset by, {
    int steps = 60,
    Duration every = const Duration(milliseconds: 16),
  }) async {
    for (var i = 0; i < steps; i++) {
      _time += every;
      await _gesture.moveBy(by / steps.toDouble(), timeStamp: _time);
      await _tester.pump(every);
    }
  }

  Future<void> up() => _gesture.up(timeStamp: _time);
}

void main() {
  group('a page from the bottom', () {
    testWidgets('a flick down on the app bar closes it', (tester) async {
      await _pump(tester, page: _bottom);
      await tester.fling(find.text('Page'), const Offset(0, 120), 1500);
      await tester.pumpAndSettle();
      _expectClosed(tester);
    });

    testWidgets('a slow drag short of halfway snaps it open', (tester) async {
      await _pump(tester, page: _bottom);
      await tester.drag(find.text('Page'), const Offset(0, 200));
      await tester.pumpAndSettle();
      _expectOpen(tester);
    });

    testWidgets('a slow drag past halfway closes it', (tester) async {
      await _pump(tester, page: _bottom);
      await tester.drag(find.text('Page'), const Offset(0, 500));
      await tester.pumpAndSettle();
      _expectClosed(tester);
    });

    testWidgets('the list at its top hands a flick down to the close', (
      tester,
    ) async {
      await _pump(tester, page: _bottom);
      await tester.fling(find.text('row 3'), const Offset(0, 120), 1500);
      await tester.pumpAndSettle();
      _expectClosed(tester);
    });

    testWidgets('a scrolled list scrolls back before it closes', (
      tester,
    ) async {
      await _pump(tester, page: _bottom);
      await tester.drag(find.text('row 3'), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(find.text('row 0'), findsNothing);

      await tester.drag(find.text('row 12'), const Offset(0, 200));
      await tester.pumpAndSettle();
      _expectOpen(tester);
      expect(find.text('row 0'), findsNothing);
    });

    testWidgets('a gentle release short of halfway snaps it open', (
      tester,
    ) async {
      await _pump(tester, page: _bottom);
      // About a quarter surface per second, under the flick velocity.
      final finger = await _Finger.down(
        tester,
        tester.getCenter(find.text('Page')),
      );
      await finger.move(const Offset(0, 220));
      await finger.up();
      await tester.pumpAndSettle();
      _expectOpen(tester);
    });

    testWidgets('a flick back toward open after halfway reopens it', (
      tester,
    ) async {
      await _pump(tester, page: _bottom);
      final finger = await _Finger.down(
        tester,
        tester.getCenter(find.text('Page')),
      );
      await finger.move(const Offset(0, 560));
      await finger.move(
        const Offset(0, -60),
        steps: 6,
        every: const Duration(milliseconds: 4),
      );
      // The surface still sits past halfway at the release.
      expect(_openness(tester), lessThan(0.5));
      await finger.up();
      await tester.pumpAndSettle();
      _expectOpen(tester);
    });

    testWidgets('one gesture on a scrolled list scrolls to the top, then '
        'closes', (tester) async {
      await _pump(tester, page: _bottom);
      await tester.drag(find.text('row 3'), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(_listOffset(tester), greaterThan(0));

      final finger = await _Finger.down(
        tester,
        tester.getCenter(find.text('row 12')),
      );
      await finger.move(const Offset(0, 440));
      expect(_listOffset(tester), 0);
      expect(_openness(tester), lessThan(1));
      await finger.move(const Offset(0, 500));
      await finger.up();
      await tester.pumpAndSettle();
      _expectClosed(tester);
    });

    testWidgets('a reversed finger reopens it and scrolls the list again', (
      tester,
    ) async {
      await _pump(tester, page: _bottom);
      final finger = await _Finger.down(
        tester,
        tester.getCenter(find.text('row 3')),
      );
      await finger.move(const Offset(0, 200));
      expect(_openness(tester), lessThan(0.9));
      await finger.move(const Offset(0, -400));
      expect(tester.getTopLeft(find.byKey(_surface)), Offset.zero);
      expect(_listOffset(tester), greaterThan(100));
      await finger.up();
      await tester.pumpAndSettle();
      _expectOpen(tester);
    });

    testWidgets('a rotation mid-swipe snaps it open', (tester) async {
      await _pump(tester, page: _bottom);
      final finger = await _Finger.down(
        tester,
        tester.getCenter(find.text('Page')),
      );
      await finger.move(const Offset(0, 300));
      expect(_openness(tester), lessThan(0.8));
      await setViewport(tester, kLandscapeViewport);
      await tester.pumpAndSettle();
      _expectOpen(tester);
      await finger.up();
      await tester.pumpAndSettle();
      _expectOpen(tester);
    });

    testWidgets('a pop mid-swipe closes it and leaves the page beneath', (
      tester,
    ) async {
      await _pump(tester, page: _bottom);
      final finger = await _Finger.down(
        tester,
        tester.getCenter(find.text('Page')),
      );
      await finger.move(const Offset(0, 100));
      _navigator(tester).pop();
      await tester.pump(const Duration(milliseconds: 50));
      await finger.up();
      await tester.pumpAndSettle();
      _expectClosed(tester);
    });

    testWidgets('a push mid-swipe keeps it under the new page', (tester) async {
      await _pump(tester, page: _bottom);
      final finger = await _Finger.down(
        tester,
        tester.getCenter(find.text('Page')),
      );
      await finger.move(const Offset(0, 500));
      _navigator(tester).push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('next')),
        ),
      );
      await tester.pumpAndSettle();
      await finger.up();
      await tester.pumpAndSettle();
      expect(find.text('next'), findsOneWidget);
      _expectNoGesture(tester);
      _navigator(tester).pop();
      await tester.pumpAndSettle();
      _expectOpen(tester);
    });

    testWidgets('a list removed mid-swipe snaps it open and ends the '
        'gesture', (tester) async {
      final showList = ValueNotifier(true);
      addTearDown(showList.dispose);
      await _pump(
        tester,
        page: _bottom,
        child: ValueListenableBuilder<bool>(
          valueListenable: showList,
          builder: (_, show, _) => show
              ? const _ListPage()
              : const Scaffold(key: _surface, body: Text('empty')),
        ),
      );
      final finger = await _Finger.down(
        tester,
        tester.getCenter(find.text('row 3')),
      );
      await finger.move(const Offset(0, 200));
      expect(_navigator(tester).userGestureInProgress, isTrue);
      showList.value = false;
      await tester.pumpAndSettle();
      _expectOpen(tester);
      await finger.up();
      await tester.pumpAndSettle();
      _expectOpen(tester);
    });

    testWidgets('a second list leaves the first list\'s swipe alone', (
      tester,
    ) async {
      await _pump(tester, page: _bottom, child: const _TwoListPage());
      final first = await _Finger.down(
        tester,
        tester.getCenter(find.text('first 1')),
      );
      await first.move(const Offset(0, 200));
      final moved = _openness(tester);
      expect(moved, lessThan(0.9));

      await tester.fling(find.text('second 1'), const Offset(0, -80), 1500);
      await tester.pump(const Duration(milliseconds: 400));
      expect(_openness(tester), moved);

      await first.up();
      await tester.pumpAndSettle();
      _expectOpen(tester);
    });

    testWidgets('a trackpad pan past the list top leaves it open', (
      tester,
    ) async {
      await _pump(tester, page: _bottom);
      final at = tester.getCenter(find.text('row 3'));
      final pad = await tester.createGesture(kind: PointerDeviceKind.trackpad);
      await pad.panZoomStart(at);
      for (var i = 1; i <= 30; i++) {
        await pad.panZoomUpdate(at, pan: Offset(0, 20.0 * i));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await pad.panZoomEnd();
      await tester.pumpAndSettle();
      _expectOpen(tester);
    });

    testWidgets('a mouse drag leaves it open', (tester) async {
      await _pump(tester, page: _bottom);
      await tester.drag(
        find.text('Page'),
        const Offset(0, 600),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();
      _expectOpen(tester);
    });

    testWidgets('a vetoed pop keeps it in place', (tester) async {
      await _pump(
        tester,
        page: _bottom,
        child: const PopScope(canPop: false, child: _ListPage()),
      );
      await tester.fling(find.text('Page'), const Offset(0, 120), 1500);
      await tester.pumpAndSettle();
      _expectOpen(tester);
    });
  });

  group('a page from the top', () {
    testWidgets('a flick up on the app bar closes it', (tester) async {
      await _pump(tester, page: _top);
      await tester.fling(find.text('Page'), const Offset(0, -120), 1500);
      await tester.pumpAndSettle();
      _expectClosed(tester);
    });

    testWidgets('a short list hands a flick up to the close', (tester) async {
      await _pump(tester, page: _top, child: const _ListPage(rows: 3));
      await tester.fling(find.text('row 1'), const Offset(0, -120), 1500);
      await tester.pumpAndSettle();
      _expectClosed(tester);
    });

    testWidgets('a long list scrolls on a flick up', (tester) async {
      await _pump(tester, page: _top);
      await tester.fling(find.text('row 3'), const Offset(0, -120), 1500);
      await tester.pumpAndSettle();
      _expectOpen(tester);
      expect(find.text('row 0'), findsNothing);
    });
  });

  group('in split', () {
    testWidgets('a flick toward the end edge closes a page', (tester) async {
      await _pump(tester, page: _bottom, size: kLandscapeViewport);
      await tester.fling(find.text('row 2'), const Offset(200, 0), 1500);
      await tester.pumpAndSettle();
      _expectClosed(tester);
    });

    testWidgets('a vertical flick scrolls the list', (tester) async {
      await _pump(tester, page: _bottom, size: kLandscapeViewport);
      await tester.fling(find.text('row 2'), const Offset(0, -120), 1500);
      await tester.pumpAndSettle();
      _expectOpen(tester);
      expect(_listOffset(tester), greaterThan(120));
    });

    testWidgets('under a right-to-left locale the close runs left', (
      tester,
    ) async {
      await _pump(
        tester,
        page: _bottom,
        size: kLandscapeViewport,
        direction: TextDirection.rtl,
      );
      await tester.fling(find.text('row 2'), const Offset(200, 0), 1500);
      await tester.pumpAndSettle();
      _expectOpen(tester);
      await tester.fling(find.text('row 2'), const Offset(-200, 0), 1500);
      await tester.pumpAndSettle();
      _expectClosed(tester);
    });
  });

  group('a drawer', () {
    Page<Object?> drawer(Widget child) => OneVpnEdgePage.drawer(child: child);
    const menu = SizedBox(
      key: _surface,
      height: 240,
      width: double.infinity,
      child: Material(child: Center(child: Text('Menu'))),
    );

    testWidgets('a flick up closes it', (tester) async {
      await _pump(tester, page: drawer, child: menu);
      await tester.fling(find.text('Menu'), const Offset(0, -120), 1500);
      await tester.pumpAndSettle();
      _expectClosed(tester);
    });

    testWidgets('Esc closes it', (tester) async {
      await _pump(tester, page: drawer, child: menu);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      _expectClosed(tester);
    });
  });
}
