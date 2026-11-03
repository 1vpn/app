// The fork layout primitives: the mode helper, the split body, and the
// capped column. Screens compose these over upstream Scaffold and AppBar.

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:onexray/onevpn/shell/edge_dismiss.dart';
import 'package:onexray/pages/theme/color.dart';

/// The two layout modes. [split] sets two equal panes side by side.
/// [stacked] sets one column, centered and capped per screen.
enum OneVpnLayoutMode { stacked, split }

/// Picks the layout mode from the window size.
///
/// Split applies when the width is at least [splitMinWidth] and exceeds the
/// height. Stacked applies otherwise. The mode reads live, so a rotation
/// re-lays out in place.
abstract final class OneVpnLayout {
  /// The narrowest window that splits.
  static const double splitMinWidth = 600;

  /// The stacked cap for connect, the paywall, and the first-connect
  /// explainer.
  static const double narrowCap = 480;

  /// The stacked cap for the picker, direct regions, the menu, and the
  /// always-on guide.
  static const double listCap = 560;

  /// The widest a pane's content grows in split.
  static const double paneCap = 420;

  /// The sign-in cap. The form never splits, so it holds in both modes.
  static const double formCap = 420;

  /// The toolbar height of every fork app bar.
  static const double appBarHeight = 64;

  static OneVpnLayoutMode forSize(Size size) =>
      size.width >= splitMinWidth && size.width > size.height
      ? OneVpnLayoutMode.split
      : OneVpnLayoutMode.stacked;

  /// The mode for the window [context] renders in.
  static OneVpnLayoutMode of(BuildContext context) =>
      forSize(MediaQuery.sizeOf(context));

  static bool isSplit(BuildContext context) =>
      of(context) == OneVpnLayoutMode.split;
}

/// A column capped at [maxWidth] and centered horizontally.
///
/// Must sit under a bounded height. The child fills that height. With
/// [scrollable], the column scrolls when its content outgrows the height. With
/// [fillViewport], it also stays at least the viewport tall, so an [Expanded]
/// child takes the spare height. A filling child must support intrinsic sizing.
/// Under an edge route, the scroll view takes the route's handoff controller. A
/// swipe past its closing edge then closes the route.
class OneVpnConstrainedBody extends StatelessWidget {
  const OneVpnConstrainedBody({
    super.key,
    required this.maxWidth,
    required this.child,
    this.scrollable = false,
    this.fillViewport = false,
  });

  /// Marks the mounted stacked body.
  static const stackedKey = ValueKey<String>('onevpn-layout-stacked');

  final double maxWidth;
  final bool scrollable;
  final bool fillViewport;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      key: stackedKey,
      builder: (context, constraints) {
        final inset = math.max(0.0, (constraints.maxWidth - maxWidth) / 2);
        final column = SizedBox(
          width: constraints.maxWidth,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: inset),
            child: child,
          ),
        );
        if (fillViewport) {
          return SingleChildScrollView(
            controller: OneVpnEdgeScope.scrollControllerOf(context),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(child: column),
            ),
          );
        }
        if (scrollable) {
          return SingleChildScrollView(
            controller: OneVpnEdgeScope.scrollControllerOf(context),
            child: column,
          );
        }
        return SizedBox.fromSize(size: constraints.biggest, child: column);
      },
    );
  }
}

/// The split body: two equal panes with a 1dp divider between them.
///
/// The divider takes the border color and insets 16dp from the top and bottom.
/// Each pane centers its content horizontally at up to [OneVpnLayout.paneCap],
/// and vertically when it fits. A pane scrolls on its own when its content
/// outgrows the height. [start] takes the start pane, and [end] takes the end
/// pane. The panes then mirror under a right-to-left locale. Must sit under a
/// bounded height.
///
/// With [endFooter], the footer pins to the end pane's bottom at the same
/// cap. Only [end] scrolls, in the height above the footer.
///
/// [endAlignment] places [end] when it fits. A list takes
/// [Alignment.topCenter], so it starts at the top of its pane. A bottom
/// alignment also scrolls from the bottom, so the end of [end] stays on the
/// footer when it overflows.
///
/// With [divider] false, the 1dp slot stays empty, so the pane widths and
/// [endPane] hold either way.
class OneVpnAdaptiveBody extends StatelessWidget {
  const OneVpnAdaptiveBody({
    super.key,
    required this.start,
    required this.end,
    this.endFooter,
    this.endAlignment = Alignment.center,
    this.divider = true,
  });

  /// Marks the mounted split body.
  static const splitKey = ValueKey<String>('onevpn-layout-split');
  static const startPaneKey = ValueKey<String>('onevpn-layout-start-pane');
  static const endPaneKey = ValueKey<String>('onevpn-layout-end-pane');

  static const double dividerWidth = 1;
  static const double dividerInset = 16;

  final Widget start;
  final Widget end;
  final Widget? endFooter;
  final Alignment endAlignment;
  final bool divider;

  /// The end pane's horizontal extent, measured from the screen's left edge.
  ///
  /// It holds for a split body that spans the screen inside the horizontal
  /// safe insets [padding]. Surfaces that anchor to the end pane read it.
  static ({double left, double width}) endPane(
    Size size,
    EdgeInsets padding,
    TextDirection direction,
  ) {
    final width = (size.width - padding.horizontal - dividerWidth) / 2;
    final left = direction == TextDirection.ltr
        ? padding.left + width + dividerWidth
        : padding.left;
    return (left: left, width: width);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      key: splitKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _OneVpnPane(key: startPaneKey, child: start),
        ),
        if (divider)
          VerticalDivider(
            width: dividerWidth,
            thickness: dividerWidth,
            indent: dividerInset,
            endIndent: dividerInset,
            color: ColorManager.palette(context).border,
          )
        else
          const SizedBox(width: dividerWidth),
        Expanded(
          child: _OneVpnPane(
            key: endPaneKey,
            footer: endFooter,
            alignment: endAlignment,
            child: end,
          ),
        ),
      ],
    );
  }
}

/// The app scroll behavior. Every vertical scroll view shows a slim,
/// always-visible thumb at its end edge.
///
/// The thumb paints only while the content outgrows the viewport. On Android,
/// iOS, and Fuchsia it ignores touch, so a touch at the end edge scrolls the
/// list. On desktop it takes mouse drags and track clicks. The thumb tracks a
/// single scroll position. A scroll view that shares its controller with
/// another must opt out with
/// `ScrollConfiguration.of(context).copyWith(scrollbars: false)`. Horizontal
/// scroll views keep the platform default.
class OneVpnScrollBehavior extends MaterialScrollBehavior {
  const OneVpnScrollBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    final controller = details.controller;
    if (controller == null ||
        axisDirectionToAxis(details.direction) != Axis.vertical) {
      return super.buildScrollbar(context, child, details);
    }
    return RawScrollbar(
      controller: controller,
      thumbVisibility: true,
      // An interactive thumb on touch claims taps and swipes near the end
      // edge. A tap there jumps a page, and a swipe drags the thumb.
      interactive: switch (getPlatform(context)) {
        TargetPlatform.android ||
        TargetPlatform.iOS ||
        TargetPlatform.fuchsia => false,
        TargetPlatform.linux ||
        TargetPlatform.macOS ||
        TargetPlatform.windows => true,
      },
      thickness: 3,
      radius: const Radius.circular(1.5),
      crossAxisMargin: 2,
      mainAxisMargin: 8,
      thumbColor: ColorManager.palette(context).mutedForeground
          .withValues(alpha: 0.4),
      child: child,
    );
  }
}

/// One split pane. Content that outgrows the height scrolls under the
/// [OneVpnScrollBehavior] thumb.
class _OneVpnPane extends StatelessWidget {
  const _OneVpnPane({
    super.key,
    required this.child,
    this.footer,
    this.alignment = Alignment.center,
  });

  final Widget child;
  final Widget? footer;
  final Alignment alignment;

  static Widget _capped(
    Widget child, {
    Alignment alignment = Alignment.center,
  }) => Align(
    alignment: alignment,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: OneVpnLayout.paneCap),
      child: child,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final scroll = LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        // Two panes scroll side by side. Each holds its own controller.
        primary: false,
        reverse: alignment.y > 0,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: _capped(child, alignment: alignment),
        ),
      ),
    );
    final footer = this.footer;
    if (footer == null) return scroll;
    return Column(
      children: [
        Expanded(child: scroll),
        _capped(footer),
      ],
    );
  }
}

/// Anchors floating snack bars to the end pane while the window splits.
///
/// It covers Material [SnackBar]s, which carry every fork notice.
///
/// Wraps a [Scaffold] whose body is a split body. Stacked, it passes [child]
/// through unchanged. Split, snack bars float. They keep the theme's inset
/// padding, with the start margin moved to the end pane's start edge.
class OneVpnSnackBarAnchor extends StatelessWidget {
  const OneVpnSnackBarAnchor({super.key, required this.child});

  /// The floating snack bar margin when the theme sets none.
  static const EdgeInsets fallbackInsets = EdgeInsets.fromLTRB(15, 5, 15, 10);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // A stable Theme keeps the Scaffold mounted across a mode change.
    if (!OneVpnLayout.isSplit(context)) return Theme(data: theme, child: child);
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final direction = Directionality.of(context);
    final pane = OneVpnAdaptiveBody.endPane(size, padding, direction);
    final base = theme.snackBarTheme.insetPadding ?? fallbackInsets;
    // A floating snack bar adds the horizontal safe insets outside its
    // margin.
    final insets = direction == TextDirection.ltr
        ? base.copyWith(left: pane.left - padding.left + base.left)
        : base.copyWith(
            right:
                size.width -
                padding.right -
                pane.left -
                pane.width +
                base.right,
          );
    return Theme(
      data: theme.copyWith(
        snackBarTheme: theme.snackBarTheme.copyWith(
          behavior: SnackBarBehavior.floating,
          insetPadding: insets,
        ),
      ),
      child: child,
    );
  }
}
