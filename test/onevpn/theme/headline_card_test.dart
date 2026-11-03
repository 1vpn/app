// The headline card. An icon in the primary color sits in a row-sized slot,
// centered on the text. The slot sits beside an optional row-type title and
// the body. A wrapping title breaks into even lines.

import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/onevpn/theme/backdrop.dart';
import 'package:onexray/onevpn/theme/balanced_text.dart';
import 'package:onexray/onevpn/theme/card.dart';
import 'package:onexray/onevpn/theme/headline_card.dart';
import 'package:onexray/pages/theme/color.dart';
import 'package:onexray/pages/theme/font.dart';
import 'package:onexray/pages/theme/theme.dart';

import '../support/viewports.dart';

Future<void> _pump(WidgetTester tester, Widget card, {Size? size}) async {
  await setViewport(tester, size ?? kPortraitViewport);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(OneVpnCard.margin),
          child: Align(alignment: Alignment.topCenter, child: card),
        ),
      ),
    ),
  );
}

/// The row-sized slot around [icon].
Finder _slot(IconData icon) => find.ancestor(
  of: find.byIcon(icon),
  matching: find.byWidgetPredicate(
    (widget) =>
        widget is SizedBox &&
        widget.width == OneVpnBackdropSquare.size &&
        widget.height == OneVpnBackdropSquare.size,
  ),
);

void main() {
  const body = 'Android can keep 1VPN connected at all times.';

  for (final size in [kPortraitViewport, kLandscapeViewport]) {
    testWidgets('at ${size.width.toInt()}x${size.height.toInt()} the icon '
        'takes a row-sized slot in the primary color, centered on the text', (
      tester,
    ) async {
      await _pump(
        tester,
        const OneVpnHeadlineCard(
          icon: LucideIcons.shieldCheck,
          title: 'Always Stay Connected',
          body: body,
        ),
        size: size,
      );
      expect(tester.takeException(), isNull);

      final icon = find.byIcon(LucideIcons.shieldCheck);
      final palette = ColorManager.palette(tester.element(icon));
      expect(tester.widget<Icon>(icon).color, palette.primary);
      final slot = _slot(LucideIcons.shieldCheck);
      expect(
        tester.getSize(slot),
        const Size.square(OneVpnBackdropSquare.size),
      );

      final card = tester.getRect(find.byType(OneVpnHeadlineCard));
      final title = tester.getRect(find.text('Always Stay Connected'));
      final text = tester.getRect(find.text(body));
      // The text starts where a row's title starts: the card padding, the
      // slot, and the leading gap.
      expect(
        title.left - card.left,
        OneVpnCard.outline +
            OneVpnCard.headlinePadding.left +
            OneVpnBackdropSquare.size +
            OneVpnCard.leadingGap,
      );
      expect(text.left, title.left);
      // The icon centers on the title and body together.
      final center = (title.top + text.bottom) / 2;
      expect(tester.getCenter(slot).dy, moreOrLessEquals(center, epsilon: 1));

      final style = tester.widget<Text>(find.text('Always Stay Connected'));
      expect(style.style!.fontSize, AppTypography.settingsRow.fontSize);
      expect(style.style!.fontWeight, AppTypography.settingsRow.fontWeight);
    });
  }

  testWidgets('with no title, the body sits beside the icon alone', (
    tester,
  ) async {
    await _pump(
      tester,
      const OneVpnHeadlineCard(icon: LucideIcons.info, body: body),
    );
    expect(find.byType(OneVpnBalancedText), findsNothing);
    final slot = tester.getCenter(_slot(LucideIcons.info));
    final text = tester.getRect(find.text(body));
    expect(slot.dy, moreOrLessEquals(text.center.dy, epsilon: 1));
  });
}
