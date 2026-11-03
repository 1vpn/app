// The settled brand decisions, as named constants.
//
// This is the reference tier. Only palette construction and asset generation
// read it. A widget never imports this file. A widget reads a named token,
// which can swap, and never a bare literal.

import 'package:material_ui/material_ui.dart';

/// The brand decisions. Constants only.
abstract final class OneVpnBrand {
  /// The brand blue. It is the app primary and the mark color. The whole blue
  /// ramp below derives from it.
  static const brandBlue = Color(0xFF106CD5);

  /// The hover shade of [brandBlue]. Solid fills and light-ground text hover
  /// to it.
  static const brandBlueHover = Color(0xFF0E5CB5);

  /// The readable blue on dark grounds. Dark text, icons, and rings render
  /// in it.
  static const brandBlueLight = Color(0xFF5AA0F0);

  /// The hover shade of [brandBlueLight].
  static const brandBlueLightHover = Color(0xFF7DB4F4);

  /// The inherited upstream blue. It stays for a later A/B against [brandBlue].
  /// Product reads it only once [primary] selects it.
  static const candidateUpstreamBlue = Color(0xFF1F6AF9);

  /// The active primary. The A/B flips here in one line. The flip swaps
  /// the base blue only. The ramp shades stay.
  static const primary = brandBlue;

  /// The premium accent. Every premium signal renders in it: locks,
  /// badges, and plan highlights.
  static const premiumGold = Color(0xFFFED330);

  /// The active font family. Null selects the platform default stack.
  /// Android renders Roboto.
  static const String? fontFamily = null;

  /// The active corner scale. The A/B flips here in one line.
  static const radii = radiiV3Current;

  /// The v3 corner scale. It is the shipped idiom.
  static const radiiV3Current = OneVpnRadiusScale(
    chip: 6,
    inner: 8,
    field: 10,
    indicator: 11,
    sheet: 12,
    card: 14,
    panel: 18,
  );

  /// The v2 corner scale. It is 8dp-centric and stays for a revisit toward the
  /// v2 spec.
  static const radiiV2Spec = OneVpnRadiusScale(
    chip: 8,
    inner: 8,
    field: 8,
    indicator: 8,
    sheet: 8,
    card: 8,
    panel: 12,
  );
}

/// A named corner scale. Every hand-built fork corner reads one field, so
/// the whole scale swaps as one selection.
class OneVpnRadiusScale {
  const OneVpnRadiusScale({
    required this.chip,
    required this.inner,
    required this.field,
    required this.indicator,
    required this.sheet,
    required this.card,
    required this.panel,
  });

  final double chip;
  final double inner;
  final double field;
  final double indicator;
  final double sheet;
  final double card;
  final double panel;
}
