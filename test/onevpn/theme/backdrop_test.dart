// The backdrop token and square. The token is the tint under a leading glyph.
// The square is the size of a flag, so a row's text starts at one x.

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/onevpn/location/flag.dart';
import 'package:onexray/onevpn/theme/backdrop.dart';
import 'package:onexray/onevpn/theme/palettes.dart';
import 'package:onexray/onevpn/theme/radii.dart';

void main() {
  test('the tint is the solid brand blue at 12% in both themes', () {
    for (final brightness in Brightness.values) {
      final palette = OneVpnPalettes.tokens(brightness).palette;
      expect(
        OneVpnBackdrop.tint(palette),
        palette.primarySolid.withValues(alpha: 0.12),
      );
    }
  });

  test('the square takes the flag size', () {
    expect(OneVpnBackdropSquare.size, OneVpnFlag.defaultSize);
    expect(OneVpnBackdropSquare.glyphSize, 18);
  });

  testWidgets('the square draws its color at the chip corners, with an '
      'optional border', (tester) async {
    const fill = Color(0xFF000001);
    const edge = Color(0xFF000002);
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OneVpnBackdropSquare(color: fill, child: SizedBox()),
              OneVpnBackdropSquare(
                color: fill,
                border: edge,
                child: SizedBox(),
              ),
            ],
          ),
        ),
      ),
    );
    final boxes = tester
        .widgetList<Container>(find.byType(Container))
        .map((c) => c.decoration! as BoxDecoration)
        .toList();
    expect(boxes, hasLength(2));
    for (final box in boxes) {
      expect(box.color, fill);
      expect(box.borderRadius, BorderRadius.circular(OneVpnRadii.chip));
    }
    expect(boxes[0].border, isNull);
    expect(boxes[1].border, Border.all(color: edge));
    for (final square in tester.widgetList(find.byType(OneVpnBackdropSquare))) {
      expect(tester.getSize(find.byWidget(square)), const Size.square(32));
    }
  });
}
