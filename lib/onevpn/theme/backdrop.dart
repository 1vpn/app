// The backdrop token and square: the tint under a leading glyph on a card.

import 'package:material_ui/material_ui.dart';
import 'package:onexray/onevpn/theme/radii.dart';
import 'package:onexray/pages/theme/color.dart';

/// The backdrop colors. A glyph on a card sits on the solid brand blue at a
/// low alpha, in the glyph's primary color.
abstract final class OneVpnBackdrop {
  /// The tint under a leading glyph on a card.
  static Color tint(AppPalette palette) =>
      palette.primarySolid.withValues(alpha: 0.12);
}

/// A leading glyph on a square [color] backdrop, outlined in [border] when one
/// is given. It takes a flag's size and corners. A row's text then starts at
/// one x, whether the row leads with a flag or a glyph.
class OneVpnBackdropSquare extends StatelessWidget {
  const OneVpnBackdropSquare({
    super.key,
    required this.color,
    required this.child,
    this.border,
  });

  /// The side of the square. It matches the flag size.
  static const double size = 32;

  /// The glyph size on the square.
  static const double glyphSize = 18;

  final Color color;
  final Widget child;
  final Color? border;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(OneVpnRadii.chip),
      border: border == null ? null : Border.all(color: border!),
    ),
    child: child,
  );
}
