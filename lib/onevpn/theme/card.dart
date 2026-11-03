// The card tokens: the metrics every fork card shares.

import 'package:material_ui/material_ui.dart';
import 'package:onexray/onevpn/theme/radii.dart';

/// The shared card metrics. A card has a 1dp outline, [radius] corners, and
/// [padding] around a leading item, [leadingGap], and its text.
abstract final class OneVpnCard {
  /// The corner radius of a card.
  static double get radius => OneVpnRadii.inner;

  /// The corner radius of a headline card. It sits one step above [radius].
  static double get headlineRadius => OneVpnRadii.sheet;

  /// The outline width of every card, selected or not.
  static const double outline = 1;

  /// The padding inside a card.
  static const padding = EdgeInsets.symmetric(horizontal: 20, vertical: 16);

  /// The padding inside a headline card.
  static const headlinePadding = EdgeInsets.all(20);

  /// The gap between a card's leading item and its text.
  static const double leadingGap = 18;

  /// The inset between a card and the edge of its column.
  static const double margin = 24;

  /// The gap between two stacked cards.
  static const double stackGap = 18;

  /// The tap splash of a card. It paints nothing. A card also sets its
  /// highlight to clear, and leaves focus and hover to the theme.
  static const InteractiveInkFeatureFactory noSplash = NoSplash.splashFactory;
}
