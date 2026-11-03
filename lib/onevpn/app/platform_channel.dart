import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The network the device uses now.
final class OneVpnActiveNetwork {
  const OneVpnActiveNetwork({this.handle, this.vpn = false})
    : assert(!vpn || handle == null);

  /// No active network, or no readable answer.
  static const unknown = OneVpnActiveNetwork();

  /// An OS-local id for the network. Null when unknown or a VPN.
  final int? handle;

  /// Whether the active network is a VPN. On Android the app is excluded
  /// from its own tunnel, so that tunnel, up or held, never reads as one.
  final bool vpn;
}

/// The fork's own platform channel. The Android side registers it in the
/// fork companion package. Other platforms register no handler.
abstract final class OneVpnPlatformChannel {
  /// The channel name. Frozen once shipped: the native side matches it.
  static const name = 'onevpn/platform';

  static const _channel = MethodChannel(name);

  /// Opens the Android system VPN settings screen, where the user turns
  /// always-on VPN on or off. Returns true when the screen opened. Returns
  /// false off Android, when the device has no such screen, or when the
  /// channel has no handler. Never throws.
  static Future<bool> openVpnSettings() async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      return await _channel.invokeMethod<bool>('openVpnSettings') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Whether a failed start holds the Android TUN with no core: the
  /// interface is up while the service status reads disconnected. Returns
  /// false off Android, when the status cannot be read, or when the channel
  /// has no handler. Never throws.
  static Future<bool> tunnelHeld() async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      return await _channel.invokeMethod<bool>('tunnelHeld') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// The active network: a VPN, or a non-VPN network with its handle.
  /// Unknown when there is none, when the answer is unreadable, or when the
  /// channel has no handler. Never throws.
  ///
  /// On Android a VPN whose interface is gone or down is stale. The native
  /// side waits up to 2 s for it to leave, then answers a VPN.
  static Future<OneVpnActiveNetwork> activeNetwork() async {
    try {
      final answer = await _channel.invokeMethod<Object?>('activeNetwork');
      if (answer is! Map) return OneVpnActiveNetwork.unknown;
      if (answer['vpn'] == true) return const OneVpnActiveNetwork(vpn: true);
      final handle = answer['handle'];
      return handle is int
          ? OneVpnActiveNetwork(handle: handle)
          : OneVpnActiveNetwork.unknown;
    } on PlatformException {
      return OneVpnActiveNetwork.unknown;
    } on MissingPluginException {
      return OneVpnActiveNetwork.unknown;
    }
  }

  /// Moves the app's task to the back on Android, as Home does. The
  /// activity and the Dart isolate keep running. Returns true when the task
  /// moved. Returns false off Android, when the task did not move, or when
  /// the channel has no handler. Never throws.
  static Future<bool> moveTaskToBack() async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      return await _channel.invokeMethod<bool>('moveTaskToBack') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Brings Play's purchase sheet back to the front on Android, when Home
  /// left it behind in a task of its own. Returns true when a sheet moved.
  /// Returns false off Android, with no such sheet, or when the channel has
  /// no handler. Never throws.
  static Future<bool> restoreBillingTask() async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      return await _channel.invokeMethod<bool>('restoreBillingTask') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Finishes the app's billing tasks on Android: a Play purchase sheet left
  /// behind, and a Recents entry a finished sheet left. A sheet that
  /// finishes cancels its purchase. Returns true when one finished. Returns
  /// false off Android, with none, or when the channel has no handler.
  /// Never throws.
  static Future<bool> finishBillingTasks() async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      return await _channel.invokeMethod<bool>('finishBillingTasks') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
