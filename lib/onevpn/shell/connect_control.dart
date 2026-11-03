import 'package:material_ui/material_ui.dart';
import 'package:onexray/onevpn/connect/native_auto_contracts.dart';
import 'package:onexray/pages/theme/color.dart';
import 'package:onexray/service/connect/coordinator.dart';

/// The connect control's visual state. Each state fixes the thumb side and
/// the track color.
enum OneVpnConnectControlState {
  /// The thumb sits at the start on the grey track.
  disconnected,

  /// The thumb sits at the end on the grey track.
  connecting,

  /// The thumb sits at the end on the brand-blue track.
  connected,

  /// The thumb sits at the end on the red track.
  noConnection;

  /// The state for a coordinator [view] and the [held] signal. A disconnecting
  /// tunnel shows the thumb at the start.
  ///
  /// A settled view over a held TUN is red. A [failedStart] view is red unless
  /// [held] is false. A null [held] means the answer is pending or the platform
  /// holds no TUN. A [failedStop] view is red. Every other failed view, a
  /// declined permission and a [cancelled] attempt included, is disconnected.
  ///
  /// A connected view is red while [allDead] holds. Otherwise it reads
  /// connecting while [measuring] holds.
  static OneVpnConnectControlState of(
    ConnectionView view, {
    bool? held,
    bool measuring = false,
    bool allDead = false,
  }) => switch (view.phase) {
    ConnectionPhase.preparing => connecting,
    ConnectionPhase.connecting => connecting,
    ConnectionPhase.disconnecting => disconnected,
    _ when held == true => noConnection,
    ConnectionPhase.disconnected => disconnected,
    ConnectionPhase.connected when allDead => noConnection,
    ConnectionPhase.connected when measuring => connecting,
    ConnectionPhase.connected => connected,
    ConnectionPhase.failed =>
      (failedStart(view) && held == null) || failedStop(view)
          ? noConnection
          : disconnected,
  };

  /// Whether [view] and [held] show the "Connection failed" line: the red
  /// state for a held TUN, a failed start, or a connected view while
  /// [allDead] holds. A failed stop shows none. An [expiredHold] view shows
  /// it with the thumb at the start, so a tap connects.
  static bool failureLine(
    ConnectionView view, {
    bool? held,
    bool allDead = false,
  }) =>
      (expiredHold(view) && held != true) ||
      (of(view, held: held, allDead: allDead) == noConnection &&
          (held == true ||
              failedStart(view) ||
              (allDead && view.phase == ConnectionPhase.connected)));

  /// True for a failed [view] whose start failed.
  static bool failedStart(ConnectionView view) =>
      view.phase == ConnectionPhase.failed &&
      const {
        'startFailed',
        'startNotConfirmed',
        'startTimeout',
      }.contains(view.issue);

  /// True for a failed [view] that an expired hold left. The measure core
  /// is stopped, and no tunnel stands.
  static bool expiredHold(ConnectionView view) =>
      view.phase == ConnectionPhase.failed &&
      view.issue == oneVpnHoldExpiredIssue;

  /// True for a failed [view] whose stop failed.
  static bool failedStop(ConnectionView view) =>
      view.phase == ConnectionPhase.failed &&
      const {'stopFailed', 'stopNotConfirmed'}.contains(view.issue);

  /// True for a failed [view] that a cancel or a selection reset produced
  /// and that leaves no tunnel to stop. Such a view reads as disconnected.
  static bool cancelled(ConnectionView view) =>
      view.phase == ConnectionPhase.failed &&
      const {'cancelled', 'selectionReset'}.contains(view.issue) &&
      !view.canDisconnect;

  /// True when the thumb sits at the end, the switch's on side.
  bool get on => this != disconnected;
}

/// The connect screen's sliding-pill switch.
///
/// A [width] by [height] pill with a round thumb that slides between the
/// start (off) and end (on) sides. A tap anywhere on the pill calls [onTap].
/// The caller decides what a tap does for each [view].
///
/// The pill takes keyboard focus. Enter and Space call [onTap]. A keyboard
/// focus highlight draws a ring in the palette's ring color around the pill.
///
/// The thumb position and the track color animate over [duration]. They
/// change in one frame when the platform asks for reduced motion.
///
/// It reads as a switch to assistive technology. [label] names the control
/// and [value] announces the connection status. The switch state follows
/// [announcedView].
class OneVpnConnectControl extends StatefulWidget {
  const OneVpnConnectControl({
    super.key,
    required this.view,
    required this.label,
    required this.value,
    required this.onTap,
    this.held,
    this.measuring = false,
    this.allDead = false,
    ConnectionView? announcedView,
  }) : announcedView = announcedView ?? view;

  /// The coordinator view to render.
  final ConnectionView view;

  /// The view the accessible switch state reads. Defaults to [view]. It
  /// must be the view [value] describes.
  final ConnectionView announcedView;

  /// The accessible name of the control.
  final String label;

  /// The accessible status of the control.
  final String value;

  /// Called on every tap and every keyboard activation.
  final VoidCallback onTap;

  /// The held signal both views render with. See
  /// [OneVpnConnectControlState.of].
  final bool? held;

  /// Whether the native connect measures. Both views render with it.
  final bool measuring;

  /// Whether the native connect's hold stands. Both views render with it.
  final bool allDead;

  /// The pill width.
  static const double width = 200;

  /// The pill height, also the thumb's cell size.
  static const double height = 100;

  /// The gap between the thumb and the pill edge.
  static const double thumbInset = 10;

  /// The focus ring's stroke width, drawn outside the pill edge.
  static const double ringWidth = 3;

  /// The thumb slide and track color transition time.
  static const Duration duration = Duration(milliseconds: 500);

  /// The key of the pill track, read by tests.
  static const trackKey = ValueKey('onevpn-connect-control-track');

  /// The key of the round thumb, read by tests.
  static const thumbKey = ValueKey('onevpn-connect-control-thumb');

  /// The key of the focus ring box around the track, read by tests.
  static const ringKey = ValueKey('onevpn-connect-control-ring');

  @override
  State<OneVpnConnectControl> createState() => _OneVpnConnectControlState();
}

class _OneVpnConnectControlState extends State<OneVpnConnectControl> {
  bool _highlighted = false;

  @override
  Widget build(BuildContext context) {
    final palette = ColorManager.palette(context);
    final state = OneVpnConnectControlState.of(
      widget.view,
      held: widget.held,
      measuring: widget.measuring,
      allDead: widget.allDead,
    );
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final motion = reduceMotion ? Duration.zero : OneVpnConnectControl.duration;
    final track = switch (state) {
      OneVpnConnectControlState.disconnected => palette.borderStrong,
      OneVpnConnectControlState.connecting => palette.borderStrong,
      OneVpnConnectControlState.connected => palette.primarySolid,
      OneVpnConnectControlState.noConnection => palette.destructiveSolid,
    };
    return Semantics(
      container: true,
      toggled: OneVpnConnectControlState.of(
        widget.announcedView,
        held: widget.held,
        measuring: widget.measuring,
        allDead: widget.allDead,
      ).on,
      label: widget.label,
      value: widget.value,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap();
              return null;
            },
          ),
        },
        onShowFocusHighlight: (value) => setState(() => _highlighted = value),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          // The ring box stays mounted in every focus state: a remount restarts
          // the track animation.
          child: DecoratedBox(
            key: OneVpnConnectControl.ringKey,
            position: DecorationPosition.foreground,
            decoration: ShapeDecoration(
              shape: StadiumBorder(
                side: _highlighted
                    ? BorderSide(
                        color: palette.ring,
                        width: OneVpnConnectControl.ringWidth,
                        strokeAlign: BorderSide.strokeAlignOutside,
                      )
                    : BorderSide.none,
              ),
            ),
            child: AnimatedContainer(
              key: OneVpnConnectControl.trackKey,
              width: OneVpnConnectControl.width,
              height: OneVpnConnectControl.height,
              duration: motion,
              curve: Curves.fastOutSlowIn,
              decoration: ShapeDecoration(
                shape: const StadiumBorder(),
                color: track,
              ),
              child: AnimatedAlign(
                duration: motion,
                curve: Curves.fastOutSlowIn,
                alignment: state.on
                    ? AlignmentDirectional.centerEnd
                    : AlignmentDirectional.centerStart,
                child: Padding(
                  padding: const EdgeInsets.all(
                    OneVpnConnectControl.thumbInset,
                  ),
                  child: DecoratedBox(
                    key: OneVpnConnectControl.thumbKey,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: palette.primaryForeground,
                    ),
                    child: const SizedBox.square(
                      dimension:
                          OneVpnConnectControl.height -
                          2 * OneVpnConnectControl.thumbInset,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
