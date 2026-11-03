// The headline card: the one prominent card at the top of a guide screen.

import 'package:material_ui/material_ui.dart';
import 'package:onexray/onevpn/theme/backdrop.dart';
import 'package:onexray/onevpn/theme/balanced_text.dart';
import 'package:onexray/onevpn/theme/card.dart';
import 'package:onexray/pages/theme/color.dart';
import 'package:onexray/pages/theme/font.dart';

/// An outlined card with an icon beside a title and a body.
///
/// It takes the headline corners, the strong border, and a tint that fades down
/// into the card color. [icon] draws in the primary color in a row-sized slot,
/// centered on the text. The text then starts where a row's title starts. The
/// title takes the row title type. A title that wraps breaks into even lines.
/// The card is informative only: it takes no taps.
class OneVpnHeadlineCard extends StatelessWidget {
  const OneVpnHeadlineCard({
    super.key,
    required this.icon,
    this.title,
    required this.body,
  });

  final IconData icon;

  /// The card title. With none, the body sits beside the icon alone.
  final String? title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final palette = ColorManager.palette(context);
    // The slot is row-sized, so the text starts where a row's title starts.
    final medallion = SizedBox.square(
      dimension: OneVpnBackdropSquare.size,
      child: Center(child: Icon(icon, color: palette.primary)),
    );
    final title = this.title;
    final bodyText = Text(
      body,
      style: AppTypography.settingsValueLabel.copyWith(
        color: palette.mutedForeground,
      ),
    );
    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(OneVpnCard.headlineRadius),
        border: Border.all(
          color: palette.borderStrong,
          width: OneVpnCard.outline,
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.selectedSurface, palette.card],
          stops: const [0, 0.6],
        ),
      ),
      padding: OneVpnCard.headlinePadding,
      child: Row(
        children: [
          medallion,
          const SizedBox(width: OneVpnCard.leadingGap),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  OneVpnBalancedText(title, style: AppTypography.settingsRow),
                  const SizedBox(height: 4),
                ],
                bodyText,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
