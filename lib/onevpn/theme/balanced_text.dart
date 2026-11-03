// Balanced wrapping for short titles.

import 'package:material_ui/material_ui.dart';

/// [text] wrapped at the narrowest width that keeps its line count. The lines
/// come out even, and no word sits alone on the last line. Use it for titles.
/// Body text keeps the full width.
class OneVpnBalancedText extends StatelessWidget {
  const OneVpnBalancedText(this.text, {super.key, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    var effective = DefaultTextStyle.of(context).style.merge(style);
    // The measure takes the bold-text setting that Text draws with.
    if (MediaQuery.boldTextOf(context)) {
      effective = effective.merge(const TextStyle(fontWeight: FontWeight.bold));
    }
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        int lines(double width) {
          final painter = TextPainter(
            text: TextSpan(text: text, style: effective),
            textDirection: direction,
            textScaler: scaler,
          )..layout(maxWidth: width);
          final count = painter.computeLineMetrics().length;
          painter.dispose();
          return count;
        }

        final max = constraints.maxWidth;
        final target = lines(max);
        var low = 0.0;
        var high = max;
        if (target > 1) {
          while (high - low > 1) {
            final mid = (low + high) / 2;
            if (lines(mid) <= target) {
              high = mid;
            } else {
              low = mid;
            }
          }
        }
        // It is aligned, so a tight parent still lets the text take the width.
        return Align(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: 1,
          child: SizedBox(
            width: target > 1 ? high.ceilToDouble().clamp(0, max) : max,
            child: Text(text, style: style),
          ),
        );
      },
    );
  }
}
