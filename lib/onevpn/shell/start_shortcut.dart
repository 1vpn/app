import 'package:flutter/foundation.dart';
import 'package:onexray/core/tools/logger.dart';
import 'package:onexray/core/tools/platform.dart';
import 'package:quick_actions/quick_actions.dart';

/// The start shortcut, the one launcher shortcut the app registers. The
/// quick-settings tile launches it while the tunnel is down. The
/// launcher's long-press menu carries it too.
///
/// [initialize] starts receiving launches. A cold start's launching
/// shortcut arrives through it. A launch goes to the attached handler. A
/// launch with no handler attached is held, and the next [attach] receives
/// it. At most one launch is held, and a later launch renews it. A launch
/// held for longer than [holdLimit], by elapsed time or by the wall clock,
/// is dropped at the attach and never runs. A launch of any other type is
/// dropped.
///
/// It acts on mobile only. Elsewhere each call returns at once.
class OneVpnStartShortcut {
  OneVpnStartShortcut({
    bool? mobile,
    Duration Function()? elapsed,
    DateTime Function()? now,
  }) : _mobileOverride = mobile,
       _elapsed = elapsed ?? _stopwatch(),
       _now = now ?? DateTime.now;

  /// The shared shortcut. The entry point initializes it, and the connect
  /// screen attaches to it.
  static final OneVpnStartShortcut instance = OneVpnStartShortcut();

  /// The shortcut id. The quick-settings tile looks the shortcut up by it.
  static const type = 'startVpn';

  /// The icon the shortcut shows: a drawable on Android and an asset
  /// catalog image on iOS.
  static const icon = 'start_vpn';

  /// The longest a launch stays held, by elapsed time and by the wall clock.
  /// An attach drops a launch held for longer on either clock, and it never
  /// runs.
  static const holdLimit = Duration(seconds: 30);

  static const _quickActions = QuickActions();

  /// Whether the shortcut acts, as tests set it. Null follows the platform.
  final bool? _mobileOverride;

  bool get _mobile => _mobileOverride ?? AppPlatform.isMobile;

  /// The monotonic time a held launch is stamped and aged by. A wall-clock
  /// change never moves it. Tests inject one.
  final Duration Function() _elapsed;

  /// The wall-clock time a held launch is also stamped and aged by. Tests
  /// inject one.
  final DateTime Function() _now;

  /// The plugin's initialize, shared by every caller once it starts.
  Future<void>? _initializing;

  /// The handler each launch goes to, or null while none is attached.
  VoidCallback? _handler;

  /// When the launch that waits for the next attach arrived, on [_elapsed]
  /// and on [_now], or null while none waits.
  ({Duration elapsed, DateTime wallClock})? _heldAt;

  /// The title last registered, or null before a registration lands.
  String? _publishedLabel;

  /// Starts receiving launches. The plugin initializes once, and a later
  /// call waits on the first. A failure is logged, and the next call
  /// retries. Never throws.
  Future<void> initialize() async {
    if (!_mobile) return;
    try {
      await (_initializing ??= _quickActions.initialize(_receive));
    } catch (error, stackTrace) {
      _initializing = null;
      ygLogger('OneVpnStartShortcut: initialize failed: $error\n$stackTrace');
    }
  }

  /// Registers the shortcut with [label] as its title. A label already
  /// registered is not sent again. A failure is logged, and the next call
  /// retries. Never throws.
  Future<void> publish(String label) async {
    if (!_mobile || label == _publishedLabel) return;
    try {
      await _quickActions.setShortcutItems([
        ShortcutItem(type: type, localizedTitle: label, icon: icon),
      ]);
      _publishedLabel = label;
    } catch (error, stackTrace) {
      ygLogger('OneVpnStartShortcut: publish failed: $error\n$stackTrace');
    }
  }

  /// Hands each later launch to [handler]. A held launch goes to it at
  /// once, unless it was held for longer than [holdLimit] on either clock.
  void attach(VoidCallback handler) {
    _handler = handler;
    final heldAt = _heldAt;
    if (heldAt == null) return;
    _heldAt = null;
    if (_elapsed() - heldAt.elapsed > holdLimit ||
        _now().difference(heldAt.wallClock) > holdLimit) {
      ygLogger('OneVpnStartShortcut: launch held expired');
      return;
    }
    handler();
  }

  /// Stops handing launches to [handler]. Another attached handler stays.
  void detach(VoidCallback handler) {
    if (_handler == handler) _handler = null;
  }

  /// The elapsed time of a stopwatch started now.
  static Duration Function() _stopwatch() {
    final stopwatch = Stopwatch()..start();
    return () => stopwatch.elapsed;
  }

  void _receive(String launched) {
    if (launched != type) return;
    final handler = _handler;
    if (handler == null) {
      ygLogger('OneVpnStartShortcut: launch held');
      _heldAt = (elapsed: _elapsed(), wallClock: _now());
      return;
    }
    ygLogger('OneVpnStartShortcut: launch');
    handler();
  }
}
