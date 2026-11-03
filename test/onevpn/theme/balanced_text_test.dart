// Balanced wrapping: a title wraps at the narrowest width that keeps its line
// count. No word sits alone on the last line. One line keeps its width.
// With bold text on, the width fits the bold title in the same line count.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/onevpn/theme/balanced_text.dart';

Future<void> _pump(WidgetTester tester, String text, double width) =>
    tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: OneVpnBalancedText(
              text,
              style: const TextStyle(fontSize: 20, height: 1),
            ),
          ),
        ),
      ),
    );

void main() {
  // The test font draws every glyph as a 1em square, so 20px a character.
  const title = 'Some Regions Work Better Direct';

  testWidgets('a two-line title breaks into even lines', (tester) async {
    // 31 characters at 20px is 620px. At 600px a greedy wrap leaves
    // "Direct" alone on the second line.
    await _pump(tester, title, 600);
    final text = find.text(title);
    final size = tester.getSize(text);
    expect(size.height, 40);
    // "Some Regions Work " fits 360px and "Better Direct" 260px, so the
    // balanced width is under 400px.
    expect(size.width, lessThan(400));
    expect(size.width, greaterThanOrEqualTo(340));
  });

  testWidgets('a one-line title keeps the full width', (tester) async {
    await _pump(tester, 'Always Stay Connected', 600);
    expect(tester.getSize(find.byType(SizedBox).last).width, 600);
    expect(tester.getSize(find.text('Always Stay Connected')).height, 20);
  });

  testWidgets('under a tight parent the text still narrows', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 600,
            child: Row(
              children: [
                Expanded(
                  child: OneVpnBalancedText(
                    title,
                    style: const TextStyle(fontSize: 20, height: 1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(tester.getSize(find.text(title)).width, lessThan(400));
  });

  testWidgets('with bold text on, the title keeps its line count', (
    tester,
  ) async {
    // The test font ignores weight. A variable font draws bold wider.
    await tester.runAsync(() async {
      final loader = FontLoader('BalancedProbe')
        ..addFont(rootBundle.load('packages/shadcn_ui/fonts/Geist[wght].ttf'));
      await loader.load();
    });
    const style = TextStyle(
      fontFamily: 'BalancedProbe',
      fontSize: 20,
      height: 1,
    );
    final bold = style.copyWith(fontWeight: FontWeight.bold);
    // The width of [style] on one line, and its line count at [width].
    (double, int) measure(TextStyle style, [double width = double.infinity]) {
      final painter = TextPainter(
        text: TextSpan(text: title, style: style),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: width);
      final result = (painter.width, painter.computeLineMetrics().length);
      painter.dispose();
      return result;
    }

    int lines(TextStyle style, double width) => measure(style, width).$2;

    final (regularWidth, _) = measure(style);
    final (boldWidth, _) = measure(bold);
    final width = regularWidth * 0.8;
    // Anti-vacuity: bold draws wider, and both weights take two lines.
    expect(boldWidth, greaterThan(regularWidth * 1.02));
    expect(lines(style, width), 2);
    expect(lines(bold, width), 2);

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData.fromView(tester.view).copyWith(boldText: true),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              child: OneVpnBalancedText(title, style: style),
            ),
          ),
        ),
      ),
    );
    // Each line is 20px tall at height 1.
    final height = tester.getSize(find.text(title)).height;
    expect((height / 20).round(), lines(style, width));
  });
}
