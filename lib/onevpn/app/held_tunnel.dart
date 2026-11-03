import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:onexray/onevpn/app/platform_channel.dart';
import 'package:onexray/service/connect/coordinator.dart';

/// Whether a failed start holds the TUN with no core, as the native side
/// reports it.
///
/// [value] is null until the first read answers, and stays null where the
/// platform holds no TUN. [refresh] reads the native answer and publishes
/// it. When reads overlap, only the latest one publishes.
class OneVpnHeldTunnel extends ValueNotifier<bool?> {
  OneVpnHeldTunnel({
    Future<bool> Function()? read,
    bool? supported,
    this.pollInterval = const Duration(milliseconds: 100),
    this.releaseTimeout = const Duration(seconds: 3),
  }) : _read = read ?? OneVpnPlatformChannel.tunnelHeld,
       supported = supported ?? defaultTargetPlatform == TargetPlatform.android,
       super(null);

  /// The shared signal the connect screen and the change helpers read.
  static final instance = OneVpnHeldTunnel();

  final Future<bool> Function() _read;

  /// Whether this platform holds a TUN after a failed start.
  final bool supported;

  /// The delay between reads while [release] waits for the interface.
  final Duration pollInterval;

  /// The longest [release] waits for the interface to go down.
  final Duration releaseTimeout;

  int _generation = 0;

  /// Reads the native answer. Resolves false where [supported] is false,
  /// and publishes nothing there.
  Future<bool> refresh() async {
    if (!supported) return false;
    final generation = ++_generation;
    final held = await _read();
    if (generation == _generation) value = held;
    return held;
  }

  /// Disconnects [coordinator] when a TUN is held, then waits for the
  /// interface to go down, up to [releaseTimeout]. Must run before any work
  /// that needs the network: a held TUN drops every packet. Resolves
  /// whether a hold was found.
  Future<bool> release(ConnectionCoordinator coordinator) async {
    if (!await refresh()) return false;
    await coordinator.disconnect();
    final waited = Stopwatch()..start();
    while (await refresh() && waited.elapsed < releaseTimeout) {
      await Future<void>.delayed(pollInterval);
    }
    return true;
  }
}
