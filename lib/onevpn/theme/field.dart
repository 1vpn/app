// The form-field tokens: the metrics every fork text field shares.

import 'package:material_ui/material_ui.dart';
import 'package:onexray/onevpn/theme/card.dart';
import 'package:onexray/pages/theme/color.dart';
import 'package:onexray/pages/theme/font.dart';

/// The shared text-field metrics. A field is 56dp tall at the default text
/// scale, with card corners and 14sp text and label.
abstract final class OneVpnField {
  /// The padding inside a field. With 14sp text it sets a 56dp field.
  static const padding = EdgeInsets.symmetric(horizontal: 16, vertical: 18);

  /// The corner radius of a field. It matches a card.
  static double get radius => OneVpnCard.radius;

  /// The type of a field's text.
  static TextStyle get text => AppTypography.settingsSelect;

  /// The decoration for an outlined field labelled [label]. Each border
  /// state keeps the theme's color and takes [radius].
  static InputDecoration decoration(AppPalette palette, String label) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: color),
    );
    return InputDecoration(
      labelText: label,
      contentPadding: padding,
      labelStyle: text.copyWith(color: palette.mutedForeground),
      floatingLabelStyle: text.copyWith(color: palette.primary),
      border: border(palette.input),
      enabledBorder: border(palette.input),
      disabledBorder: border(palette.input),
      focusedBorder: border(palette.ring),
      errorBorder: border(palette.destructive),
      focusedErrorBorder: border(palette.destructive),
    );
  }
}
