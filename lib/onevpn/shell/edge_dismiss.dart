// Swipe-to-close for edge surfaces: the drag that drives an edge route's
// animation, and the scroll handoff that feeds it from a list at its edge.

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

/// The fraction of the surface per second at which a release flicks the
/// surface open or closed, whatever its position.
const double _flingVelocity = 1;

/// The devices a close swipe answers. A mouse or a trackpad closes a surface
/// with Esc, the close button, or the scrim instead.
const Set<PointerDeviceKind> _swipeDevices = {
  PointerDeviceKind.touch,
  PointerDeviceKind.stylus,
  PointerDeviceKind.invertedStylus,
};

/// The direction a finger moves to close a surface. [axis] is the closing axis.
/// [sign] is +1 toward the axis end (right or down) or -1 toward its start.
typedef OneVpnEdgeClosing = ({Axis axis, double sign});

/// Drives an edge route's animation from a close swipe.
///
/// One source owns a swipe at a time: the drag area or one list. [start] claims
/// the swipe for an owner. It fails while [enabled] is false or while another
/// owner holds the swipe. [update], [end], and [cancel] act only for the owner.
/// [update] moves the surface by a finger delta toward closing. [end] releases
/// it. A flick past [_flingVelocity] goes its way. A slow release closes past
/// halfway and snaps open otherwise.
///
/// A release pops only while the route is current. A route with a page above it
/// snaps open instead. A route that is no longer active only ends the user
/// gesture. [abandon] ends the swipe with no motion.
class OneVpnEdgeDismiss {
  OneVpnEdgeDismiss({
    required this.animation,
    required this.navigator,
    required this.enabled,
    required this.isCurrent,
    required this.isActive,
    required this.extent,
  });

  /// The route's animation controller. 1 is fully open.
  final AnimationController Function() animation;
  final NavigatorState Function() navigator;
  final bool Function() enabled;
  final bool Function() isCurrent;
  final bool Function() isActive;

  /// The surface's size along the closing axis, in logical pixels.
  final double Function() extent;

  Object? _owner;

  /// Whether any source holds a swipe.
  bool get dragging => _owner != null;

  /// Whether [owner] holds the swipe.
  bool draggingBy(Object owner) => identical(_owner, owner);

  /// Whether the surface sits fully open.
  bool get open => animation().value >= 1;

  bool start(Object owner) {
    if (_owner != null) return draggingBy(owner);
    if (!enabled()) return false;
    navigator().didStartUserGesture();
    _owner = owner;
    return true;
  }

  void update(Object owner, double towardClose) {
    if (!draggingBy(owner)) return;
    final size = extent();
    if (size <= 0) return;
    animation().value -= towardClose / size;
  }

  /// Releases the swipe with [velocityTowardClose] in logical pixels per
  /// second.
  void end(Object owner, double velocityTowardClose) {
    if (!draggingBy(owner)) return;
    final value = animation().value;
    final size = extent();
    final fling = size <= 0 ? 0.0 : velocityTowardClose / size;
    _release(close: fling.abs() >= _flingVelocity ? fling > 0 : value < 0.5);
  }

  /// Snaps the surface open and ends [owner]'s swipe. With no [owner], ends
  /// whichever swipe is in progress. Reads no layout, so it runs during a
  /// build.
  void cancel([Object? owner]) {
    if (_owner == null || (owner != null && !draggingBy(owner))) return;
    _release(close: false);
  }

  /// Ends any swipe in progress with no motion.
  void abandon() {
    if (_owner == null) return;
    _owner = null;
    navigator().didStopUserGesture();
  }

  void _release({required bool close}) {
    _owner = null;
    final nav = navigator();
    if (!isActive()) {
      nav.didStopUserGesture();
      return;
    }
    final controller = animation();
    if (close && isCurrent()) {
      // The pop reverses the animation from where the finger left it.
      nav.pop();
    } else {
      controller.forward();
    }
    if (controller.isAnimating) {
      late final AnimationStatusListener done;
      done = (status) {
        if (status.isAnimating) return;
        controller.removeStatusListener(done);
        nav.didStopUserGesture();
      };
      controller.addStatusListener(done);
    } else {
      nav.didStopUserGesture();
    }
  }
}

/// Hands an edge route's close swipe to the content inside it.
class OneVpnEdgeScope extends InheritedWidget {
  const OneVpnEdgeScope({
    super.key,
    required this.dismiss,
    required this.closing,
    required this.scrollController,
    required super.child,
  });

  final OneVpnEdgeDismiss dismiss;
  final OneVpnEdgeClosing closing;

  /// The handoff controller, or null when lists scroll across the closing
  /// axis and need no handoff.
  final ScrollController? scrollController;

  /// The controller a scroll view under an edge route takes. A swipe past the
  /// list's closing edge then closes the surface. It is null outside an edge
  /// route and while the closing axis is horizontal.
  static ScrollController? scrollControllerOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<OneVpnEdgeScope>()
      ?.scrollController;

  @override
  bool updateShouldNotify(OneVpnEdgeScope oldWidget) =>
      closing != oldWidget.closing ||
      scrollController != oldWidget.scrollController;
}

/// A scroll controller whose positions hand a swipe past the list's closing
/// edge to an edge route.
class OneVpnEdgeScrollController extends ScrollController {
  OneVpnEdgeScrollController({required this.dismiss, required this.closing});

  final OneVpnEdgeDismiss dismiss;

  /// The controller reads it at each drag, so a rotation takes effect at once.
  final OneVpnEdgeClosing Function() closing;

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) => _OneVpnEdgeScrollPosition(
    physics: physics.applyTo(const AlwaysScrollableScrollPhysics()),
    context: context,
    oldPosition: oldPosition,
    dismiss: dismiss,
    closing: closing,
  );
}

/// A scroll position that feeds the close swipe while the list sits at its
/// closing edge.
///
/// A surface that closes downward hands off at the list's top. A surface
/// that closes upward hands off at the list's end. A swipe back toward open
/// scrolls the list again once the surface is fully open. Only a touch or
/// stylus drag hands off. A trackpad or mouse drag only scrolls.
class _OneVpnEdgeScrollPosition extends ScrollPositionWithSingleContext {
  _OneVpnEdgeScrollPosition({
    required super.physics,
    required super.context,
    super.oldPosition,
    required this.dismiss,
    required this.closing,
  });

  final OneVpnEdgeDismiss dismiss;
  final OneVpnEdgeClosing Function() closing;

  /// The device of the current drag. It is null before the first drag.
  PointerDeviceKind? _kind;

  @override
  Drag drag(DragStartDetails details, VoidCallback dragCancelCallback) {
    _kind = details.kind;
    return super.drag(details, dragCancelCallback);
  }

  @override
  void dispose() {
    dismiss.cancel(this);
    super.dispose();
  }

  /// The finger's sign that closes, or null when the list scrolls across the
  /// closing axis.
  double? get _sign {
    final value = closing();
    return value.axis == axis ? value.sign : null;
  }

  bool _atClosingEdge(double sign) =>
      sign > 0 ? pixels <= minScrollExtent : pixels >= maxScrollExtent;

  @override
  void applyUserOffset(double delta) {
    final sign = _sign;
    if (sign != null && _swipeDevices.contains(_kind)) {
      final towardClose = sign * delta;
      if (dismiss.draggingBy(this)) {
        if (towardClose < 0 && dismiss.open) {
          dismiss.end(this, 0);
        } else {
          dismiss.update(this, towardClose);
          return;
        }
      } else if (towardClose > 0 &&
          _atClosingEdge(sign) &&
          dismiss.start(this)) {
        dismiss.update(this, towardClose);
        return;
      }
    }
    super.applyUserOffset(delta);
  }

  @override
  void goBallistic(double velocity) {
    if (dismiss.draggingBy(this)) {
      final sign = _sign;
      if (sign == null) {
        dismiss.cancel(this);
      } else {
        // A scroll velocity runs against the finger.
        dismiss.end(this, -velocity * sign);
      }
      super.goBallistic(0);
      return;
    }
    super.goBallistic(velocity);
  }
}

/// The swipe area over an edge surface, outside any list. A drag along the
/// closing axis moves the surface, and a rotation mid-swipe snaps it open.
class OneVpnEdgeDragArea extends StatefulWidget {
  const OneVpnEdgeDragArea({
    super.key,
    required this.dismiss,
    required this.closing,
    required this.child,
  });

  final OneVpnEdgeDismiss dismiss;
  final OneVpnEdgeClosing closing;
  final Widget child;

  @override
  State<OneVpnEdgeDragArea> createState() => _OneVpnEdgeDragAreaState();
}

class _OneVpnEdgeDragAreaState extends State<OneVpnEdgeDragArea> {
  @override
  void didUpdateWidget(OneVpnEdgeDragArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.closing != widget.closing) oldWidget.dismiss.cancel(this);
  }

  @override
  void dispose() {
    widget.dismiss.cancel(this);
    super.dispose();
  }

  void _start(DragStartDetails _) => widget.dismiss.start(this);

  void _update(DragUpdateDetails details) =>
      widget.dismiss.update(this, widget.closing.sign * details.primaryDelta!);

  void _end(DragEndDetails details) =>
      widget.dismiss.end(this, widget.closing.sign * details.primaryVelocity!);

  void _cancel() => widget.dismiss.cancel(this);

  @override
  Widget build(BuildContext context) {
    final horizontal = widget.closing.axis == Axis.horizontal;
    return RawGestureDetector(
      behavior: HitTestBehavior.translucent,
      gestures: {
        if (horizontal)
          HorizontalDragGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<
                HorizontalDragGestureRecognizer
              >(
                () => HorizontalDragGestureRecognizer(
                  supportedDevices: _swipeDevices,
                ),
                _configure,
              )
        else
          VerticalDragGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<
                VerticalDragGestureRecognizer
              >(
                () => VerticalDragGestureRecognizer(
                  supportedDevices: _swipeDevices,
                ),
                _configure,
              ),
      },
      child: widget.child,
    );
  }

  void _configure(DragGestureRecognizer recognizer) => recognizer
    ..onStart = _start
    ..onUpdate = _update
    ..onEnd = _end
    ..onCancel = _cancel;
}
