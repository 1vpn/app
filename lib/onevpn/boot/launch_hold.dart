import 'package:flutter/widgets.dart';

/// Keeps the native splash up until the app is ready to draw.
///
/// [hold] defers the first frame. The platform holds its splash until the
/// first frame reaches the engine, so the first thing the user sees is the
/// connect screen and never a blank or loading screen. [release] lets the
/// first frame through. Each call is idempotent, and [release] with nothing
/// held does nothing.
abstract final class OneVpnLaunchHold {
  static bool _held = false;

  /// Whether the first frame is currently deferred by this hold.
  static bool get held => _held;

  /// Defers the first frame. Must run before the first frame is produced,
  /// ahead of `runApp`.
  static void hold() {
    if (_held) return;
    _held = true;
    WidgetsBinding.instance.deferFirstFrame();
  }

  /// Lets the first frame through and requests a frame to send it.
  ///
  /// Safe to call from inside a frame callback.
  static void release() {
    if (!_held) return;
    _held = false;
    final binding = WidgetsBinding.instance;
    binding.allowFirstFrame();
    // allowFirstFrame schedules its warm-up frame only while the scheduler is
    // idle. From a frame callback it schedules none, so ask for one here.
    binding.ensureVisualUpdate();
  }
}
