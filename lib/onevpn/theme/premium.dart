// The premium accent token and the premium marker. Widgets read these,
// never brand.dart.

import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/onevpn/theme/brand.dart';

/// The premium signal color. Every filled premium marker renders in it.
const Color oneVpnPremiumAccent = OneVpnBrand.premiumGold;

/// The premium marker: the star.
///
/// The default star is filled in the premium accent.
/// [OneVpnPremiumStar.outline] draws the star's outline only. It uses [color],
/// or the ambient icon color when [color] is null.
class OneVpnPremiumStar extends StatelessWidget {
  const OneVpnPremiumStar({super.key, this.size = 24})
    : outlined = false,
      color = null;

  const OneVpnPremiumStar.outline({super.key, this.size = 24, this.color})
    : outlined = true;

  final double size;

  /// Whether the star draws its outline only.
  final bool outlined;

  /// The outline color. The filled star ignores it.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (outlined) return Icon(LucideIcons.star, size: size, color: color);
    return SvgPicture.asset(
      'assets/onevpn/brand/star.svg',
      width: size,
      height: size,
      colorFilter: const ColorFilter.mode(oneVpnPremiumAccent, BlendMode.srcIn),
    );
  }
}
