import 'package:flutter/services.dart';
import 'package:onexray/core/pigeon/messages.g.dart';
import 'package:onexray/core/pigeon/model.dart';
import 'package:onexray/core/tools/json.dart';
import 'package:onexray/core/tools/logger.dart';

/// Time bounds for the pigeon command channel.
///
/// Every command awaits one native reply. Callers run commands on one
/// serial queue, so a lost reply blocks every later command. Each bound
/// turns a lost reply into the ordinary failed result, with [expired] as
/// the failure message. Expiry leaves the native call running. A reply
/// that arrives after the bound has no effect.
///
/// A bound catches only a wedged channel. The start and stop commands
/// resolve only when the native side reports the tunnel up or down. Native
/// timers limit that wait. Their bounds sit strictly above those native
/// budgets. A tighter bound would fail a slow but healthy command.
abstract final class ChannelDeadlines {
  /// Bounds the start command at 75s, 15s above the longest native chain.
  ///
  /// The longest chain is macOS through the system extension, at 60s. It
  /// waits 10s to activate, then spends 10s each on the listDat and
  /// startXray requests of syncDatAndStart. It then waits 30s for the
  /// connected status. The Android chain takes up to 33s. It waits up to 3s
  /// for the service bind, then up to 30s for completion.
  ///
  /// The bound excludes the dat transfer. A start whose dat manifest differs
  /// from the extension's also transfers the files, at 10s per request. That
  /// start can outlast the bound and fail with [expired].
  static const Duration startVpn = Duration(seconds: 75);

  /// Bounds the stop command at 25s, 7s above the longest native chain.
  /// Apple waits 15s for the disconnected status. The Android chain takes up
  /// to 18s. It waits up to 3s for the service bind, then up to 15s for
  /// completion.
  static const Duration stopVpn = Duration(seconds: 25);

  /// Status reads round-trip in milliseconds. The bound catches only a
  /// wedged channel.
  static const Duration readVpnStatus = Duration(seconds: 10);

  /// Invoke calls are plain request and response, with no lifecycle work.
  /// The bound catches only a wedged channel.
  static const Duration invoke = Duration(seconds: 10);

  /// The failure message on expiry. It matches no native error string, so
  /// logs attribute the failure to the channel layer.
  static const String expired = 'channelDeadline';
}

/// A messenger that applies [ChannelDeadlines] to the bridge's host calls.
///
/// It forwards every call to the messenger it wraps. A send on a bounded
/// channel that gets no reply within its bound resolves to a failed reply
/// instead. The reply is pigeon's success envelope around the failure value
/// `AppHostApi` builds. The caller then decodes an ordinary failed result
/// that carries [ChannelDeadlines.expired]. Expiry logs the operation. A
/// late reply or error from the wrapped messenger has no effect.
final class ChannelDeadlineMessenger extends BinaryMessenger {
  const ChannelDeadlineMessenger(this._inner);

  final BinaryMessenger _inner;

  /// The channel name prefix of every `BridgeHostApi` call.
  static const channelPrefix = 'dev.flutter.pigeon.onexray.BridgeHostApi.';

  /// The bound and the expiry value of each bounded operation. The key is
  /// the operation name that ends the channel name.
  static final Map<String, (Duration, Object Function())> _bounds = {
    'readVpnStatus': (ChannelDeadlines.readVpnStatus, _commandExpired),
    'startVpn': (ChannelDeadlines.startVpn, _commandExpired),
    'stopVpn': (ChannelDeadlines.stopVpn, _commandExpired),
    'invoke': (ChannelDeadlines.invoke, _invokeExpired),
  };

  /// The operations this messenger bounds.
  static Iterable<String> get boundedOperations => _bounds.keys;

  @override
  Future<ByteData?>? send(String channel, ByteData? message) {
    final reply = _inner.send(channel, message);
    final operation = channel.startsWith(channelPrefix)
        ? channel.substring(channelPrefix.length)
        : null;
    final bound = _bounds[operation];
    if (reply == null || bound == null) {
      return reply;
    }
    final (deadline, expiredValue) = bound;
    return reply.timeout(
      deadline,
      onTimeout: () {
        ygLogger(
          'BridgeHostApi.$operation failed: ${ChannelDeadlines.expired}',
        );
        return BridgeHostApi.pigeonChannelCodec.encodeMessage(<Object?>[
          expiredValue(),
        ]);
      },
    );
  }

  @override
  void setMessageHandler(String channel, MessageHandler? handler) =>
      _inner.setMessageHandler(channel, handler);

  @override
  Future<void> handlePlatformMessage(
    String channel,
    ByteData? data,
    PlatformMessageResponseCallback? callback,
  ) {
    // ignore: deprecated_member_use
    return _inner.handlePlatformMessage(channel, data, callback);
  }
}

/// The failed command result, in the shape of `AppHostApi._commandFailed`.
NativeVpnCommandResult _commandExpired() => NativeVpnCommandResult(
  state: NativeVpnCommandState.failed,
  permission: PlatformPermissionResult(
    kind: PlatformPermissionKind.none,
    state: PlatformPermissionState.failed,
  ),
  message: ChannelDeadlines.expired,
);

/// The failed invoke response JSON that `AppHostApi` parses.
String _invokeExpired() => JsonTool.encoder.convert(
  LibXrayInvokeResponse(false, null, ChannelDeadlines.expired).toJson(),
);
