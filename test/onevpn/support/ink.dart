import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Expects the ink well around each of [anchors] to show nothing when pressed
/// and to leave focus and hover to the theme.
///
/// A well that sets [InkWell.overlayColor] also sets what focus and hover
/// show, because the ink resolves those from it first. A keyboard user then
/// cannot see which row is focused.
void expectQuietInk(WidgetTester tester, Iterable<Finder> anchors) {
  for (final anchor in anchors) {
    final well = tester.widget<InkWell>(
      find.ancestor(of: anchor, matching: find.byType(InkWell)).first,
    );
    final reason = '$anchor';
    expect(well.overlayColor, isNull, reason: reason);
    expect(well.highlightColor, Colors.transparent, reason: reason);
    expect(well.splashFactory, NoSplash.splashFactory, reason: reason);
  }
}

/// Expects the ink well around each of [anchors] to flash white when pressed
/// and to show the theme's focus and hover colors.
void expectSolidInk(WidgetTester tester, Iterable<Finder> anchors) {
  for (final anchor in anchors) {
    final finder = find
        .ancestor(of: anchor, matching: find.byType(InkWell))
        .first;
    final overlay = tester.widget<InkWell>(finder).overlayColor;
    final theme = Theme.of(tester.element(finder));
    final reason = '$anchor';
    expect(overlay, isNotNull, reason: reason);
    expect(
      overlay!.resolve({WidgetState.pressed}),
      Colors.white.withValues(alpha: 0.18),
      reason: reason,
    );
    expect(
      overlay.resolve({WidgetState.focused}),
      theme.focusColor,
      reason: reason,
    );
    expect(
      overlay.resolve({WidgetState.hovered}),
      theme.hoverColor,
      reason: reason,
    );
  }
}
