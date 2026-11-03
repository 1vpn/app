// The close-style app bar for pages that slide in from a screen edge.

import 'package:material_ui/material_ui.dart';
import 'package:onexray/onevpn/shell/routes.dart';
import 'package:onexray/onevpn/theme/card.dart';

/// The Material icon size the close glyph renders at.
const double _iconSize = 24;

/// An app bar with [title] at the start and a close button at the end. The
/// close button pops the page, so a page opened from the menu returns to it.
/// With no route beneath, it goes to the connect shell.
///
/// [inset] sets both edges. The title starts and the close glyph ends that far
/// from the screen edge. The default lines both up with the cards below, at the
/// card margin. A page of full-bleed rows passes the row inset.
AppBar oneVpnCloseAppBar(
  BuildContext context,
  String title, {
  double inset = OneVpnCard.margin,
}) => AppBar(
  automaticallyImplyLeading: false,
  titleSpacing: inset,
  title: Text(title),
  // The glyph sits centered in the button's tap target.
  actionsPadding: EdgeInsetsDirectional.only(
    end: inset - (kMinInteractiveDimension - _iconSize) / 2,
  ),
  actions: [CloseButton(onPressed: () => oneVpnPopOrConnect(context))],
);
