// The press overlay of a solid blue surface. Pressed flashes a light white.
// Focus and hover show the theme's own colors, so a keyboard user sees which
// button is focused.

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/onevpn/theme/button.dart';
import 'package:onexray/pages/theme/theme.dart';

void main() {
  testWidgets('pressed flashes white and focus and hover keep the theme '
      'colors', (tester) async {
    late ThemeData theme;
    late WidgetStateProperty<Color?> overlay;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) {
            theme = Theme.of(context);
            overlay = OneVpnButton.solidOverlay(context);
            return const SizedBox();
          },
        ),
      ),
    );
    final flash = Colors.white.withValues(alpha: 0.18);

    expect(overlay.resolve({WidgetState.pressed}), flash);
    expect(overlay.resolve({WidgetState.focused}), theme.focusColor);
    expect(overlay.resolve({WidgetState.hovered}), theme.hoverColor);
    expect(overlay.resolve({WidgetState.pressed, WidgetState.focused}), flash);
    expect(overlay.resolve(<WidgetState>{}), Colors.transparent);
    // A transparent theme color would hide focus again.
    expect(theme.focusColor.a, greaterThan(0));
  });
}
