// Fork notices. An info notice takes the primary tone and the info icon. A
// failure takes the destructive tone and the alert icon. A new notice
// replaces the one on screen. A lasting failure stays with a close button
// until closed. A failure with a link lasts, and its link is one underlined
// span that reads as a link. A tap on the link closes the notice and runs
// it. A message that places the link other than once shows as plain text.

import 'package:flutter/gestures.dart' show TapGestureRecognizer;
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/onevpn/feedback/notice.dart';
import 'package:onexray/pages/theme/color.dart';
import 'package:onexray/pages/theme/theme.dart';

/// Pumps a scaffold and returns a context under it.
Future<BuildContext> _pump(WidgetTester tester) async {
  late BuildContext context;
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Builder(
        builder: (value) {
          context = value;
          return const Scaffold();
        },
      ),
    ),
  );
  return context;
}

Finder _inNotice(Finder finder) =>
    find.descendant(of: find.byType(SnackBar), matching: finder);

/// The text spans of the notice paragraph that holds [text], in order.
List<TextSpan> _spans(WidgetTester tester, String text) {
  final paragraph = _inNotice(
    find.byWidgetPredicate(
      (widget) => widget is RichText && widget.text.toPlainText() == text,
    ),
  );
  final spans = <TextSpan>[];
  tester.widget<RichText>(paragraph).text.visitChildren((span) {
    if (span is TextSpan && span.text != null) spans.add(span);
    return true;
  });
  return spans;
}

void main() {
  testWidgets('info then error: each takes its tone, and the second '
      'replaces the first', (tester) async {
    final context = await _pump(tester);
    final palette = ColorManager.palette(context);

    BorderSide side() =>
        (tester.widget<SnackBar>(find.byType(SnackBar)).shape!
                as RoundedRectangleBorder)
            .side;
    Color iconColor(IconData icon) =>
        tester.widget<Icon>(find.byIcon(icon)).color!;

    OneVpnNotice.info(context, 'saved');
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);
    expect(side().color, palette.primary);
    expect(iconColor(LucideIcons.info), palette.primary);
    expect(find.byIcon(LucideIcons.circleAlert), findsNothing);

    OneVpnNotice.error(context, 'failed');
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('saved'), findsNothing);
    expect(find.text('failed'), findsOneWidget);
    expect(side().color, palette.destructive);
    expect(iconColor(LucideIcons.circleAlert), palette.destructive);
    expect(find.byIcon(LucideIcons.info), findsNothing);
    // Anti-vacuity guard. The two tones differ.
    expect(palette.destructive, isNot(palette.primary));
  });

  testWidgets('a lasting failure stays with a close button until '
      'closed', (tester) async {
    final context = await _pump(tester);

    OneVpnNotice.error(context, 'failed', persist: true);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 30));
    expect(_inNotice(find.text('failed')), findsOneWidget);

    await tester.tap(_inNotice(find.byIcon(Icons.close)));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);

    // Anti-vacuity guard. A plain failure has no close button and leaves.
    OneVpnNotice.error(context, 'failed');
    await tester.pumpAndSettle();
    expect(_inNotice(find.byIcon(Icons.close)), findsNothing);
    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('a failure with a link lasts, reads the link as a link, and a '
      'tap on it closes the notice and runs it', (tester) async {
    final semantics = tester.ensureSemantics();
    final context = await _pump(tester);
    final palette = ColorManager.palette(context);
    var taps = 0;

    OneVpnNotice.errorWithLink(
      context,
      (link) => 'Write to $link today.',
      OneVpnNoticeLink(label: 'the team', onTap: () => taps++),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 30));

    final spans = _spans(tester, 'Write to the team today.');
    expect(spans.map((span) => span.text), [
      'Write to ',
      'the team',
      ' today.',
    ]);
    expect(spans[1].recognizer, isA<TapGestureRecognizer>());
    expect(spans[1].style!.decoration, TextDecoration.underline);
    expect(spans[1].style!.color, palette.primary);
    expect(_inNotice(find.byIcon(Icons.close)), findsOneWidget);
    expect(
      find.semantics.byLabel('the team').evaluate().single,
      isSemantics(isLink: true, hasTapAction: true),
    );

    await tester.tapOnText(
      find.textRange.ofSubstring(
        'the team',
        descendentOf: find.byType(SnackBar),
      ),
    );
    await tester.pumpAndSettle();

    expect(taps, 1);
    expect(find.byType(SnackBar), findsNothing);
    semantics.dispose();
  });

  for (final (name, message) in <(String, OneVpnLinkedMessage)>[
    ('no link slot', (_) => 'Write to us today.'),
    ('two link slots', (link) => 'Write to $link or $link.'),
  ]) {
    testWidgets('a message with $name shows as plain text and lasts', (
      tester,
    ) async {
      final context = await _pump(tester);

      OneVpnNotice.errorWithLink(
        context,
        message,
        OneVpnNoticeLink(label: 'the team', onTap: () {}),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 30));

      expect(_inNotice(find.text(message('the team'))), findsOneWidget);
      expect(_spans(tester, message('the team')), hasLength(1));
      expect(_inNotice(find.byIcon(Icons.close)), findsOneWidget);
    });
  }

  testWidgets('a handle closes its own notice and leaves a newer one', (
    tester,
  ) async {
    final context = await _pump(tester);

    final first = OneVpnNotice.error(context, 'first', persist: true);
    await tester.pumpAndSettle();
    first.close();
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);

    final second = OneVpnNotice.error(context, 'second', persist: true);
    await tester.pumpAndSettle();
    OneVpnNotice.error(context, 'third', persist: true);
    await tester.pumpAndSettle();
    second.close();
    await tester.pumpAndSettle();
    expect(_inNotice(find.text('third')), findsOneWidget);
  });

  testWidgets('a handle closes a notice queued behind another once it comes '
      'on screen', (tester) async {
    final context = await _pump(tester);
    OneVpnNotice.error(context, 'first', persist: true);
    await tester.pumpAndSettle();

    // The first notice is still leaving when the second one is closed.
    final second = OneVpnNotice.error(context, 'second', persist: true);
    await tester.pump();
    expect(_inNotice(find.text('first')), findsOneWidget);
    second.close();
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
  });

  test('the link parts are the text around a single link slot', () {
    expect(oneVpnLinkParts((link) => 'Write to $link today.'), (
      'Write to ',
      ' today.',
    ));
    expect(oneVpnLinkParts((link) => link), ('', ''));
    expect(oneVpnLinkParts((_) => 'Write to us.'), isNull);
    expect(oneVpnLinkParts((link) => '$link and $link'), isNull);
  });
}
