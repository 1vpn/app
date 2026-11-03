// The layout primitives.
//
// The mode splits at width 600dp and up when the width exceeds the height,
// and stacks otherwise. It reads live: a resize re-lays out in place and
// keeps the widget state. The split body sets two equal panes around a 1dp
// inset divider. It centers each pane's content at up to 420dp and scrolls
// each pane on its own. The capped column centers at its cap. Scrollable, it
// scrolls past the viewport. Filling, it also takes the full viewport height.
// A mode change keeps the Scaffold state. Snack bars anchor to the end pane
// in split and mirror under a right-to-left locale. The scroll behavior gives
// each vertical scroll view an always-visible thumb, and none to a horizontal
// one. The thumb paints only while the content outgrows the viewport. It sits
// at the end edge: right in English, left in Arabic. The thumb ignores touch
// on mobile and takes pointer input on desktop.

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/l10n/localizations/app_localizations.dart';
import 'package:onexray/onevpn/l10n/locales.dart';
import 'package:onexray/onevpn/shell/layout.dart';
import 'package:onexray/pages/theme/color.dart';
import 'package:onexray/pages/theme/theme.dart';

import '../support/localizations.dart';
import '../support/viewports.dart';

const _startKey = ValueKey('start-content');
const _endKey = ValueKey('end-content');

Future<void> _pumpScaffold(
  WidgetTester tester,
  Widget body, {
  TextDirection direction = TextDirection.ltr,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('en'),
      localizationsDelegates: oneVpnLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Directionality(
        textDirection: direction,
        child: OneVpnSnackBarAnchor(child: Scaffold(body: body)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Renders the live mode's body.
class _ModeHost extends StatefulWidget {
  const _ModeHost();

  @override
  State<_ModeHost> createState() => _ModeHostState();
}

class _ModeHostState extends State<_ModeHost> {
  @override
  Widget build(BuildContext context) {
    return OneVpnLayout.isSplit(context)
        ? const OneVpnAdaptiveBody(
            start: SizedBox(key: _startKey, width: 100, height: 100),
            end: SizedBox(key: _endKey, width: 100, height: 100),
          )
        : const OneVpnConstrainedBody(
            maxWidth: OneVpnLayout.narrowCap,
            child: SizedBox(key: _startKey),
          );
  }
}

void main() {
  group('the mode at the breakpoint edges', () {
    const cases = [
      (Size(599, 360), OneVpnLayoutMode.stacked),
      (Size(600, 360), OneVpnLayoutMode.split),
      (Size(600, 600), OneVpnLayoutMode.stacked),
      (Size(768, 1024), OneVpnLayoutMode.stacked),
      (Size(1024, 768), OneVpnLayoutMode.split),
      (kPortraitViewport, OneVpnLayoutMode.stacked),
      (kLandscapeViewport, OneVpnLayoutMode.split),
    ];
    for (final (size, mode) in cases) {
      test('${size.width.toInt()}x${size.height.toInt()} is ${mode.name}', () {
        expect(OneVpnLayout.forSize(size), mode);
      });
    }
  });

  testWidgets('the mode reads the window size', (tester) async {
    for (final entry in {
      const Size(599, 360): OneVpnConstrainedBody.stackedKey,
      const Size(600, 360): OneVpnAdaptiveBody.splitKey,
      const Size(600, 600): OneVpnConstrainedBody.stackedKey,
    }.entries) {
      await setViewport(tester, entry.key);
      await _pumpScaffold(tester, const _ModeHost());
      expect(find.byKey(entry.value), findsOneWidget, reason: '${entry.key}');
    }
  });

  testWidgets('a rotation re-lays out in place', (tester) async {
    await setViewport(tester, kPortraitViewport);
    await _pumpScaffold(tester, const _ModeHost());
    final state = tester.state(find.byType(_ModeHost));
    final scaffold = tester.state(find.byType(Scaffold));
    expect(find.byKey(OneVpnConstrainedBody.stackedKey), findsOneWidget);

    await setViewport(tester, kLandscapeViewport);
    await tester.pump();
    expect(find.byKey(OneVpnAdaptiveBody.splitKey), findsOneWidget);
    expect(find.byKey(OneVpnConstrainedBody.stackedKey), findsNothing);
    expect(tester.state(find.byType(_ModeHost)), same(state));
    expect(tester.state(find.byType(Scaffold)), same(scaffold));

    await setViewport(tester, kPortraitViewport);
    await tester.pump();
    expect(find.byKey(OneVpnConstrainedBody.stackedKey), findsOneWidget);
    expect(tester.state(find.byType(_ModeHost)), same(state));
  });

  group('the split body', () {
    testWidgets('sets two equal panes around a 1dp inset divider', (
      tester,
    ) async {
      await setViewport(tester, kLandscapeViewport);
      await _pumpScaffold(tester, const _ModeHost());

      final start = tester.getRect(find.byKey(OneVpnAdaptiveBody.startPaneKey));
      final end = tester.getRect(find.byKey(OneVpnAdaptiveBody.endPaneKey));
      expect(start.width, end.width);
      expect(start.width, (800 - 1) / 2);
      expect(end.left - start.right, 1);

      final divider = tester.widget<VerticalDivider>(
        find.byType(VerticalDivider),
      );
      final palette = ColorManager.palette(
        tester.element(find.byType(VerticalDivider)),
      );
      expect(divider.width, 1);
      expect(divider.thickness, 1);
      expect(divider.indent, 16);
      expect(divider.endIndent, 16);
      expect(divider.color, palette.border);
    });

    testWidgets('centers each pane content both ways', (tester) async {
      await setViewport(tester, kLandscapeViewport);
      await _pumpScaffold(tester, const _ModeHost());

      final pane = tester.getRect(find.byKey(OneVpnAdaptiveBody.endPaneKey));
      final content = tester.getRect(find.byKey(_endKey));
      expect(content.center.dx, closeTo(pane.center.dx, 0.01));
      expect(content.center.dy, closeTo(pane.center.dy, 0.01));
    });

    testWidgets('caps pane content at 420dp', (tester) async {
      await setViewport(tester, kTabletLandscapeViewport);
      await _pumpScaffold(
        tester,
        const OneVpnAdaptiveBody(
          start: SizedBox(key: _startKey, height: 40, width: double.infinity),
          end: SizedBox(key: _endKey, height: 40, width: double.infinity),
        ),
      );

      final pane = tester.getRect(find.byKey(OneVpnAdaptiveBody.startPaneKey));
      final content = tester.getRect(find.byKey(_startKey));
      expect(pane.width, greaterThan(OneVpnLayout.paneCap));
      expect(content.width, OneVpnLayout.paneCap);
      expect(content.center.dx, closeTo(pane.center.dx, 0.01));
    });

    testWidgets('scrolls a pane on its own when it outgrows the height', (
      tester,
    ) async {
      await setViewport(tester, kLandscapeViewport);
      await _pumpScaffold(
        tester,
        const OneVpnAdaptiveBody(
          start: SizedBox(key: _startKey, height: 100),
          end: SizedBox(key: _endKey, height: 900),
        ),
      );
      expect(tester.takeException(), isNull);
      final startTop = tester.getTopLeft(find.byKey(_startKey)).dy;
      final endTop = tester.getTopLeft(find.byKey(_endKey)).dy;
      expect(endTop, 0);

      await tester.drag(
        find.byKey(OneVpnAdaptiveBody.endPaneKey),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byKey(_endKey)).dy, lessThan(endTop));
      expect(tester.getTopLeft(find.byKey(_startKey)).dy, startTop);
    });

    testWidgets('pins an end footer while the end content scrolls', (
      tester,
    ) async {
      const footerKey = ValueKey('footer');
      await setViewport(tester, kLandscapeViewport);
      await _pumpScaffold(
        tester,
        const OneVpnAdaptiveBody(
          start: SizedBox(key: _startKey, height: 100),
          end: SizedBox(key: _endKey, height: 900),
          endFooter: SizedBox(
            key: footerKey,
            height: 80,
            width: double.infinity,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final pane = tester.getRect(find.byKey(OneVpnAdaptiveBody.endPaneKey));
      final footer = tester.getRect(find.byKey(footerKey));
      expect(footer.bottom, pane.bottom);
      expect(footer.width, OneVpnLayout.paneCap.clamp(0, pane.width));
      expect(footer.center.dx, closeTo(pane.center.dx, 0.01));

      final top = tester.getTopLeft(find.byKey(_endKey)).dy;
      await tester.dragFrom(
        pane.topCenter + const Offset(0, 40),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byKey(_endKey)).dy, lessThan(top));
      expect(tester.getRect(find.byKey(footerKey)), footer);
    });

    test('names the end pane extent in both directions', () {
      const padding = EdgeInsets.only(left: 40, right: 20);
      final ltr = OneVpnAdaptiveBody.endPane(
        kLandscapeViewport,
        padding,
        TextDirection.ltr,
      );
      final rtl = OneVpnAdaptiveBody.endPane(
        kLandscapeViewport,
        padding,
        TextDirection.rtl,
      );
      expect(ltr.width, (800 - 60 - 1) / 2);
      expect(ltr.left, 40 + ltr.width + 1);
      expect(rtl.width, ltr.width);
      expect(rtl.left, 40);
    });
  });

  group('the capped column', () {
    testWidgets('centers at its cap', (tester) async {
      await setViewport(tester, const Size(768, 1024));
      await _pumpScaffold(
        tester,
        const OneVpnConstrainedBody(
          maxWidth: OneVpnLayout.narrowCap,
          child: SizedBox(key: _startKey),
        ),
      );

      final column = tester.getRect(find.byKey(_startKey));
      expect(column.width, OneVpnLayout.narrowCap);
      expect(column.left, (768 - OneVpnLayout.narrowCap) / 2);
      expect(column.height, 1024);
    });

    testWidgets('takes the full width under its cap', (tester) async {
      await setViewport(tester, kPortraitViewport);
      await _pumpScaffold(
        tester,
        const OneVpnConstrainedBody(
          maxWidth: OneVpnLayout.narrowCap,
          child: SizedBox(key: _startKey),
        ),
      );

      expect(
        tester.getRect(find.byKey(_startKey)),
        Offset.zero & kPortraitViewport,
      );
    });

    testWidgets('scrollable, it scrolls inside its cap', (tester) async {
      await setViewport(tester, kLandscapeViewport);
      await _pumpScaffold(
        tester,
        const OneVpnConstrainedBody(
          maxWidth: OneVpnLayout.listCap,
          scrollable: true,
          child: SizedBox(key: _startKey, height: 600),
        ),
      );
      expect(tester.takeException(), isNull);
      final column = tester.getRect(find.byKey(_startKey));
      expect(column.width, OneVpnLayout.listCap);
      expect(column.left, (800 - OneVpnLayout.listCap) / 2);

      // A drag in the margin outside the cap scrolls the column too.
      await tester.dragFrom(const Offset(40, 300), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(tester.getBottomLeft(find.byKey(_startKey)).dy, 360);
    });

    testWidgets('filling, it fills the viewport and scrolls past it', (
      tester,
    ) async {
      Widget body(double content) => OneVpnConstrainedBody(
        maxWidth: OneVpnLayout.narrowCap,
        fillViewport: true,
        child: Column(
          children: [
            const Expanded(child: SizedBox(key: _startKey)),
            SizedBox(key: _endKey, height: content),
          ],
        ),
      );
      await setViewport(tester, kLandscapeViewport);

      await _pumpScaffold(tester, body(100));
      expect(tester.getSize(find.byKey(_startKey)).height, 360 - 100);
      expect(tester.getBottomLeft(find.byKey(_endKey)).dy, 360);

      await _pumpScaffold(tester, body(600));
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byKey(_startKey)).height, 0);
      await tester.drag(find.byKey(_endKey), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(tester.getBottomLeft(find.byKey(_endKey)).dy, 360);
    });
  });

  group('the snack bar anchor', () {
    Rect snackBar(WidgetTester tester) => tester.getRect(
      find
          .descendant(
            of: find.byType(SnackBar),
            matching: find.byType(Material),
          )
          .first,
    );

    Future<void> show(WidgetTester tester) async {
      ScaffoldMessenger.of(tester.element(find.byType(Scaffold)))
          .showSnackBar(const SnackBar(content: Text('saved')));
      await tester.pumpAndSettle();
    }

    testWidgets('keeps the theme margin when stacked', (tester) async {
      await setViewport(tester, kPortraitViewport);
      await _pumpScaffold(tester, const _ModeHost());
      await show(tester);

      final rect = snackBar(tester);
      expect(rect.left, OneVpnSnackBarAnchor.fallbackInsets.left);
      expect(rect.right, 360 - OneVpnSnackBarAnchor.fallbackInsets.right);
    });

    testWidgets('anchors to the end pane in split', (tester) async {
      await setViewport(tester, kLandscapeViewport);
      await _pumpScaffold(tester, const _ModeHost());
      await show(tester);

      final pane = tester.getRect(find.byKey(OneVpnAdaptiveBody.endPaneKey));
      final rect = snackBar(tester);
      expect(rect.left, pane.left + OneVpnSnackBarAnchor.fallbackInsets.left);
      expect(
        rect.right,
        pane.right - OneVpnSnackBarAnchor.fallbackInsets.right,
      );
    });

    testWidgets('anchors to the end pane past a start safe inset', (
      tester,
    ) async {
      tester.view.padding = const FakeViewPadding(left: 48);
      tester.view.viewPadding = const FakeViewPadding(left: 48);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      await setViewport(tester, kLandscapeViewport);
      await _pumpScaffold(tester, const SafeArea(child: _ModeHost()));
      await show(tester);

      final pane = tester.getRect(find.byKey(OneVpnAdaptiveBody.endPaneKey));
      final named = OneVpnAdaptiveBody.endPane(
        kLandscapeViewport,
        const EdgeInsets.only(left: 48),
        TextDirection.ltr,
      );
      expect(pane.left, named.left);
      expect(pane.width, named.width);
      final rect = snackBar(tester);
      expect(rect.left, pane.left + OneVpnSnackBarAnchor.fallbackInsets.left);
      expect(
        rect.right,
        pane.right - OneVpnSnackBarAnchor.fallbackInsets.right,
      );
    });

    testWidgets('anchors to the end pane under a right-to-left locale', (
      tester,
    ) async {
      await setViewport(tester, kLandscapeViewport);
      await _pumpScaffold(
        tester,
        const _ModeHost(),
        direction: TextDirection.rtl,
      );
      await show(tester);

      final pane = tester.getRect(find.byKey(OneVpnAdaptiveBody.endPaneKey));
      expect(pane.left, 0);
      final rect = snackBar(tester);
      expect(rect.left, pane.left + OneVpnSnackBarAnchor.fallbackInsets.left);
      expect(
        rect.right,
        pane.right - OneVpnSnackBarAnchor.fallbackInsets.right,
      );
    });
  });

  group('the scroll behavior', () {
    /// Mounts [body] under the scroll behavior. The text direction follows
    /// [locale].
    Future<void> pumpScroll(
      WidgetTester tester,
      Widget body, {
      Locale locale = const Locale('en'),
    }) => tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        scrollBehavior: const OneVpnScrollBehavior(),
        locale: locale,
        localizationsDelegates: oneVpnLocalizationsDelegates,
        supportedLocales: [for (final l in kOneVpnLocales) l.locale],
        builder: (context, child) => Directionality(
          textDirection: oneVpnTextDirection(Localizations.localeOf(context)),
          child: child!,
        ),
        home: Scaffold(body: body),
      ),
    );

    Iterable<Widget> rows([int count = 40]) => [
      for (var i = 0; i < count; i++) SizedBox(height: 48, child: Text('$i')),
    ];

    /// The thumb rects under the scrollbar. The thumb is the only rounded
    /// rect the scrollbar paints.
    List<Rect> thumbs() {
      final rects = <Rect>[];
      expect(
        find.byType(RawScrollbar),
        paints..everything((method, arguments) {
          if (method == #drawRRect) {
            rects.add((arguments.first as RRect).outerRect);
          }
          return true;
        }),
      );
      return rects;
    }

    testWidgets('a list that fits the viewport shows no thumb', (tester) async {
      await setViewport(tester, kPortraitViewport);
      await pumpScroll(tester, ListView(children: [...rows(3)]));
      await tester.pumpAndSettle();

      expect(find.byType(RawScrollbar), findsOneWidget);
      expect(thumbs(), isEmpty);
    });

    for (final (locale, rtl) in const [
      (Locale('en'), false),
      (Locale('ar'), true),
    ]) {
      testWidgets('under ${locale.languageCode}, the thumb sits at the '
          '${rtl ? 'left' : 'right'} edge', (tester) async {
        await setViewport(tester, kPortraitViewport);
        await pumpScroll(
          tester,
          ListView(children: [...rows()]),
          locale: locale,
        );
        await tester.pumpAndSettle();

        final thumb = thumbs().single;
        expect(thumb.width, 3);
        // The 2dp cross-axis margin separates the thumb from the edge.
        if (rtl) {
          expect(thumb.left, 2);
        } else {
          expect(thumb.right, kPortraitViewport.width - 2);
        }
      });
    }

    testWidgets('a vertical scroll view shows an always-visible thumb', (
      tester,
    ) async {
      await pumpScroll(tester, ListView(children: [...rows()]));

      final scrollbar = tester.widget<RawScrollbar>(find.byType(RawScrollbar));
      expect(scrollbar.thumbVisibility, isTrue);
      expect(scrollbar.thickness, 3);
      expect(tester.takeException(), isNull);
    });

    testWidgets('on touch, the end edge scrolls the list and never the thumb', (
      tester,
    ) async {
      await setViewport(tester, kPortraitViewport);
      await pumpScroll(tester, ListView(children: [...rows()]));
      // Must settle first: the thumb ignores every touch while it fades in.
      await tester.pumpAndSettle();
      final position = tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position;

      // A tap in the track strip, below the thumb, leaves the list in place.
      await tester.tapAt(const Offset(357, 600));
      await tester.pumpAndSettle();
      expect(position.pixels, 0);

      // A swipe up from the thumb scrolls the list down.
      await tester.dragFrom(const Offset(356, 60), const Offset(0, -80));
      await tester.pumpAndSettle();
      expect(position.pixels, greaterThan(0));
    }, variant: TargetPlatformVariant.mobile());

    testWidgets('on desktop, the thumb takes pointer input', (tester) async {
      await pumpScroll(tester, ListView(children: [...rows()]));

      final scrollbar = tester.widget<RawScrollbar>(find.byType(RawScrollbar));
      expect(scrollbar.interactive, isTrue);
    }, variant: TargetPlatformVariant.desktop());

    testWidgets('a horizontal scroll view shows no thumb', (tester) async {
      await pumpScroll(
        tester,
        ListView(scrollDirection: Axis.horizontal, children: [...rows()]),
      );

      expect(find.byType(RawScrollbar), findsNothing);
    });

    testWidgets('each split pane takes its own thumb', (tester) async {
      await setViewport(tester, kLandscapeViewport);
      await pumpScroll(
        tester,
        OneVpnAdaptiveBody(
          start: Column(children: [...rows()]),
          end: Column(children: [...rows()]),
        ),
      );

      for (final pane in [
        OneVpnAdaptiveBody.startPaneKey,
        OneVpnAdaptiveBody.endPaneKey,
      ]) {
        expect(
          find.descendant(
            of: find.byKey(pane),
            matching: find.byType(RawScrollbar),
          ),
          findsOneWidget,
        );
      }
      expect(tester.takeException(), isNull);
    });
  });
}
