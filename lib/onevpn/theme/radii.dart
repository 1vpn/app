// The fork corner tokens. Widgets read these, never brand.dart, so the
// active corner scale swaps in one place.

import 'package:onexray/onevpn/theme/brand.dart';

/// The active corner radii. Each value follows the active brand scale. Card
/// metrics, corners included, come from `OneVpnCard`.
abstract final class OneVpnRadii {
  static double get chip => OneVpnBrand.radii.chip;
  static double get inner => OneVpnBrand.radii.inner;
  static double get field => OneVpnBrand.radii.field;
  static double get indicator => OneVpnBrand.radii.indicator;
  static double get sheet => OneVpnBrand.radii.sheet;
}
