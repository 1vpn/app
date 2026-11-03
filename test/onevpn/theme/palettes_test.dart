// Pins the fork palettes. The blue family derives from the brand blue. The
// readable blue clears WCAG AA on every ground its theme draws it on.

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/onevpn/theme/palettes.dart';
import 'package:onexray/pages/theme/color.dart';

void main() {
  test('the whole blue family derives from the brand blue', () {
    final light = OneVpnPalettes.light;
    const lightBlue = Color(0xFF106CD5);
    const lightHover = Color(0xFF0E5CB5);
    expect(light.primary, lightBlue);
    expect(light.primaryHover, lightHover);
    expect(light.primarySolid, lightBlue);
    expect(light.primarySolidHover, lightHover);
    expect(light.accentForeground, lightBlue);
    expect(light.ring, lightBlue);
    expect(light.sidebarPrimary, lightBlue);
    expect(light.sidebarRing, lightBlue);

    final dark = OneVpnPalettes.dark;
    const darkBlue = Color(0xFF5AA0F0);
    expect(dark.primary, darkBlue);
    expect(dark.primaryHover, const Color(0xFF7DB4F4));
    expect(dark.primarySolid, lightBlue);
    expect(dark.primarySolidHover, lightHover);
    expect(dark.accentForeground, darkBlue);
    expect(dark.ring, darkBlue);
    expect(dark.sidebarPrimary, darkBlue);
    expect(dark.sidebarRing, darkBlue);

    // The accent tints forward from upstream.
    expect(light.accent, AppPalette.light.accent);
    expect(dark.accent, AppPalette.dark.accent);
    expect(dark.sidebarAccent, AppPalette.dark.sidebarAccent);
    expect(
      dark.sidebarAccentForeground,
      AppPalette.dark.sidebarAccentForeground,
    );
  });

  test('the readable blue clears WCAG AA on its theme ground', () {
    double contrast(Color a, Color b) {
      final la = a.computeLuminance();
      final lb = b.computeLuminance();
      return la > lb ? (la + 0.05) / (lb + 0.05) : (lb + 0.05) / (la + 0.05);
    }

    for (final palette in [OneVpnPalettes.light, OneVpnPalettes.dark]) {
      for (final ground in [
        palette.background,
        palette.card,
        palette.sidebar,
        palette.accent,
      ]) {
        expect(contrast(palette.primary, ground), greaterThanOrEqualTo(4.5));
      }
      expect(
        contrast(Colors.white, palette.primarySolid),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(Colors.white, palette.primarySolidHover),
        greaterThanOrEqualTo(4.5),
      );
    }
  });
}
