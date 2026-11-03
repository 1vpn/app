import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:onexray/onevpn/theme/card.dart';
import 'package:onexray/onevpn/theme/radii.dart';
import 'package:onexray/pages/theme/color.dart';
import 'package:onexray/pages/theme/font.dart';

/// The routing indicator in the connect-screen header. A compact pill holds a
/// routing icon and the active direct region's raw ISO code. It shows only when
/// a region other than All via VPN is active. A null [region] renders nothing,
/// so the caller mounts it unconditionally and the widget owns the show/hide.
/// Tapping it opens the Direct-regions picker.
class OneVpnRouteIndicator extends StatelessWidget {
  const OneVpnRouteIndicator({
    super.key,
    required this.region,
    required this.onTap,
  });

  /// The active direct region's ISO code, or null for All via VPN.
  final String? region;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final region = this.region;
    if (region == null) return const SizedBox.shrink();
    final palette = ColorManager.palette(context);
    // The end inset keeps the pill off the menu button's tap target.
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0, 8, 4, 8),
      child: Material(
        color: palette.muted,
        borderRadius: BorderRadius.circular(OneVpnRadii.indicator),
        child: InkWell(
          borderRadius: BorderRadius.circular(OneVpnRadii.indicator),
          highlightColor: Colors.transparent,
          splashFactory: OneVpnCard.noSplash,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(OneVpnRadii.indicator),
              border: Border.all(color: palette.borderStrong),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.route, size: 16, color: palette.primary),
                const SizedBox(width: 6),
                Text(region, style: AppTypography.routingRegionCode),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
