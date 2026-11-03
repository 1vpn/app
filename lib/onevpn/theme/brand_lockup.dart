// The brand lockup: the shield-and-wordmark mark for the app header.

import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

/// The header lockup. The wordmark takes [color], and the shield keeps the
/// brand blue.
class OneVpnBrandLockup extends StatelessWidget {
  const OneVpnBrandLockup({super.key, required this.color, this.height = 22.5});

  /// The wordmark color. The shield ignores it.
  final Color color;

  /// The lockup height. The default sizes the app header.
  final double height;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/onevpn/brand/logo.svg',
    height: height,
    theme: SvgTheme(currentColor: color),
  );
}
