// The edge route: every fork surface that slides in from a screen edge,
// from the menu drawer to the pages opened over it.

import 'package:material_ui/material_ui.dart';
import 'package:onexray/onevpn/shell/edge_dismiss.dart';
import 'package:onexray/onevpn/shell/layout.dart';
import 'package:onexray/pages/theme/color.dart';

/// The screen edge a stacked edge surface slides in from.
enum OneVpnStackedEdge { top, bottom }

/// What an edge route shows.
enum OneVpnEdgeSurface {
  /// A full page. It covers the screen once it settles.
  page,

  /// A drawer sized by its content, pinned to its edge, over a scrim that
  /// dismisses it.
  drawer,
}

/// The motion every edge surface shares: 300ms with an ease-out curve, in
/// both directions.
abstract final class OneVpnEdgeMotion {
  static const duration = Duration(milliseconds: 300);
  static const Curve curve = Curves.easeOutCubic;
}

/// Where an edge surface comes from in the current layout mode.
///
/// Stacked, a surface comes from its [OneVpnStackedEdge]. In split, every
/// surface comes from the end edge, which mirrors under a right-to-left
/// locale. The layout mode reads live, so a rotation moves the edge.
abstract final class OneVpnEdge {
  /// The fractional offset that holds a surface just past its edge.
  static Offset hidden(BuildContext context, OneVpnStackedEdge edge) {
    if (OneVpnLayout.isSplit(context)) {
      return Offset(
        Directionality.of(context) == TextDirection.ltr ? 1 : -1,
        0,
      );
    }
    return switch (edge) {
      OneVpnStackedEdge.top => const Offset(0, -1),
      OneVpnStackedEdge.bottom => const Offset(0, 1),
    };
  }

  /// The finger direction that closes a surface: back toward its edge.
  static OneVpnEdgeClosing closing(
    BuildContext context,
    OneVpnStackedEdge edge,
  ) {
    if (OneVpnLayout.isSplit(context)) {
      return (
        axis: Axis.horizontal,
        sign: Directionality.of(context) == TextDirection.ltr ? 1 : -1,
      );
    }
    return switch (edge) {
      OneVpnStackedEdge.top => (axis: Axis.vertical, sign: -1),
      OneVpnStackedEdge.bottom => (axis: Axis.vertical, sign: 1),
    };
  }

  /// The alignment that pins a drawer to its edge.
  static AlignmentGeometry pin(BuildContext context, OneVpnStackedEdge edge) {
    if (OneVpnLayout.isSplit(context)) return AlignmentDirectional.centerEnd;
    return switch (edge) {
      OneVpnStackedEdge.top => Alignment.topCenter,
      OneVpnStackedEdge.bottom => Alignment.bottomCenter,
    };
  }
}

/// A go_router page for an edge surface. It creates a [OneVpnEdgeRoute].
class OneVpnEdgePage<T> extends Page<T> {
  const OneVpnEdgePage({
    super.key,
    required this.stackedEdge,
    required this.child,
    this.surface = OneVpnEdgeSurface.page,
  });

  /// A page opened from the menu. It comes from the menu drawer's edge.
  const OneVpnEdgePage.menuDetail({super.key, required this.child})
    : stackedEdge = OneVpnStackedEdge.top,
      surface = OneVpnEdgeSurface.page;

  /// A page opened from the bottom of connect. It comes up from the bottom
  /// edge.
  const OneVpnEdgePage.fromBottom({super.key, required this.child})
    : stackedEdge = OneVpnStackedEdge.bottom,
      surface = OneVpnEdgeSurface.page;

  /// The menu drawer. It comes down from the top edge.
  const OneVpnEdgePage.drawer({super.key, required this.child})
    : stackedEdge = OneVpnStackedEdge.top,
      surface = OneVpnEdgeSurface.drawer;

  final OneVpnStackedEdge stackedEdge;
  final OneVpnEdgeSurface surface;
  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) => OneVpnEdgeRoute<T>(this);
}

/// The route behind every [OneVpnEdgePage].
///
/// The surface slides in from [OneVpnEdge.hidden] with [OneVpnEdgeMotion], at
/// its own size. A page is opaque once it settles. A drawer is transparent. The
/// route's barrier is its scrim, which fades with the slide. The scrim
/// dismisses the drawer on a tap or Esc. With reduced motion the surface
/// appears in place.
///
/// A touch swipe back toward the edge closes the surface. Outside a list the
/// swipe starts anywhere on the surface. A list that takes
/// [OneVpnEdgeScope.scrollControllerOf] hands the swipe over at its closing
/// edge. The swipe follows [popGestureEnabled], so a first route or a vetoed
/// pop keeps the surface in place.
class OneVpnEdgeRoute<T> extends PageRoute<T> {
  OneVpnEdgeRoute(OneVpnEdgePage<T> page) : super(settings: page);

  OneVpnEdgePage<T> get _page => settings as OneVpnEdgePage<T>;

  final _surfaceKey = GlobalKey();

  OneVpnEdgeClosing _closing = (axis: Axis.vertical, sign: 1);

  late final _dismiss = OneVpnEdgeDismiss(
    animation: () => controller!,
    navigator: () => navigator!,
    enabled: () => isCurrent && popGestureEnabled,
    isCurrent: () => isCurrent,
    isActive: () => isActive,
    extent: () {
      final size = _surfaceKey.currentContext?.size;
      if (size == null) return 0;
      return _closing.axis == Axis.horizontal ? size.width : size.height;
    },
  );

  late final _scroll = OneVpnEdgeScrollController(
    dismiss: _dismiss,
    closing: () => _closing,
  );

  /// A pop mid-swipe lets the pop animation run from where the finger left
  /// the surface.
  @override
  bool didPop(T? result) {
    _dismiss.abandon();
    return super.didPop(result);
  }

  /// A page pushed above mid-swipe snaps the surface open beneath it.
  @override
  void didChangeNext(Route<dynamic>? nextRoute) {
    if (nextRoute != null) _dismiss.cancel();
    super.didChangeNext(nextRoute);
  }

  @override
  void dispose() {
    _dismiss.abandon();
    _scroll.dispose();
    super.dispose();
  }

  bool get _drawer => _page.surface == OneVpnEdgeSurface.drawer;

  @override
  bool get opaque => !_drawer;

  @override
  bool get barrierDismissible => _drawer;

  @override
  Color? get barrierColor =>
      _drawer ? ColorManager.palette(navigator!.context).overlay : null;

  @override
  String? get barrierLabel => _drawer
      ? MaterialLocalizations.of(navigator!.context).modalBarrierDismissLabel
      : null;

  @override
  Curve get barrierCurve => OneVpnEdgeMotion.curve;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => OneVpnEdgeMotion.duration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => _page.child;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final edge = _page.stackedEdge;
    final closing = _closing = OneVpnEdge.closing(context, edge);
    final swipeable = OneVpnEdgeScope(
      dismiss: _dismiss,
      closing: closing,
      scrollController: closing.axis == Axis.vertical ? _scroll : null,
      child: OneVpnEdgeDragArea(
        dismiss: _dismiss,
        closing: closing,
        child: KeyedSubtree(key: _surfaceKey, child: child),
      ),
    );
    final surface = MediaQuery.disableAnimationsOf(context)
        ? swipeable
        : SlideTransition(
            position: animation.drive(
              Tween<Offset>(
                begin: OneVpnEdge.hidden(context, edge),
                end: Offset.zero,
              ).chain(CurveTween(curve: OneVpnEdgeMotion.curve)),
            ),
            child: swipeable,
          );
    if (!_drawer) return surface;
    return Align(alignment: OneVpnEdge.pin(context, edge), child: surface);
  }
}
