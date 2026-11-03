// The country flag for a catalogue location.

import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/onevpn/theme/radii.dart';

/// A square country flag at [size] with chip corners.
///
/// [countryCode] is the catalogue code, in any case. A regional code in
/// [aliases] draws its country's flag. A code with no flag asset renders
/// nothing: callers check [has] first.
class OneVpnFlag extends StatelessWidget {
  const OneVpnFlag({
    super.key,
    required this.countryCode,
    this.size = defaultSize,
  });

  /// The flag size rows lay out around.
  static const double defaultSize = 32;

  /// The catalogue country codes that ship a flag asset.
  static const codes = {
    'ae', 'ar', 'au', 'br', 'ca', 'ch', 'cl', 'de', 'es', 'fi', //
    'fr', 'ge', 'hk', 'id', 'ie', 'il', 'in', 'is', 'it', 'jp', //
    'ke', 'kr', 'kz', 'lu', 'mx', 'my', 'ng', 'nl', 'nz', 'pa', //
    'ph', 'pl', 'pt', 'ro', 'ru', 'se', 'sg', 'th', 'tr', 'tw', //
    'ua', 'uk', 'us', 'za',
  };

  /// Regional catalogue codes and the country code whose flag each draws.
  /// The US catalogue splits into east, south, and west. The ISO code gb
  /// draws the uk asset.
  static const aliases = {'gb': 'uk', 'use': 'us', 'uss': 'us', 'usw': 'us'};

  /// The asset code [countryCode] draws, or null when it has no flag.
  static String? assetCode(String? countryCode) {
    if (countryCode == null) return null;
    final lower = countryCode.toLowerCase();
    final code = aliases[lower] ?? lower;
    return codes.contains(code) ? code : null;
  }

  /// Whether [countryCode] has a flag asset.
  static bool has(String? countryCode) => assetCode(countryCode) != null;

  final String countryCode;
  final double size;

  @override
  Widget build(BuildContext context) {
    final code = assetCode(countryCode);
    if (code == null) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(OneVpnRadii.chip),
      child: SvgPicture.asset(
        'assets/onevpn/flags/$code.svg',
        width: size,
        height: size,
      ),
    );
  }
}
