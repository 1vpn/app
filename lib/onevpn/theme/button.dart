// The button tokens: the metrics every fork action button shares.

import 'package:material_ui/material_ui.dart';
import 'package:onexray/onevpn/theme/card.dart';
import 'package:onexray/pages/theme/font.dart';

/// The shared action-button metrics. An action button is [height] tall with
/// [radius] corners and a [label] in the settings-row type.
abstract final class OneVpnButton {
  /// The height of an action button.
  static const double height = 48;

  /// The corner radius of an action button. It matches a card.
  static double get radius => OneVpnCard.radius;

  /// The gap between two stacked action buttons.
  static const double stackGap = 16;

  /// The label type of an action button.
  static TextStyle get label => AppTypography.settingsRow;

  /// The press overlay of a solid blue surface, resolved against the theme of
  /// [context]. A light white flash fades in while pressed. Focus and hover
  /// show the theme's own colors.
  static WidgetStateProperty<Color?> solidOverlay(BuildContext context) {
    final theme = Theme.of(context);
    return WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) {
        return Colors.white.withValues(alpha: 0.18);
      }
      if (states.contains(WidgetState.focused)) return theme.focusColor;
      if (states.contains(WidgetState.hovered)) return theme.hoverColor;
      return Colors.transparent;
    });
  }

  /// The overrides for a themed Material button on a fork screen. It keeps
  /// the theme's colors and sets the height, corners, and label type.
  static ButtonStyle get style => ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(Size(64, height)),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
    ),
    textStyle: WidgetStatePropertyAll(label),
  );
}
