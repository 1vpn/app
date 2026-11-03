// The Dart side of the contract for reloading the core in place. It wraps
// the generated bindings in handover.g.dart. Every call is bounded and
// never throws.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:onexray/core/tools/logger.dart';
import 'package:onexray/onevpn/handover/handover.g.dart';

/// Bounds for the reload channel.
abstract final class OneVpnHandoverDeadlines {
  /// The main-process wait for a reload's finished event. Matches
  /// `OneVpnHandoverHost.RELOAD_WAIT_MS` on Android.
  static const Duration nativeReload = Duration(seconds: 15);

  /// Bounds one reload await. It sits 5s above [nativeReload], so the
  /// native answer arrives first. It also bounds a network reload's started
  /// event that has no finished event.
  static const Duration reload = Duration(seconds: 20);

  /// Bounds the support query. The query answers at once. The bound only
  /// catches a wedged channel.
  static const Duration reloadSupported = Duration(seconds: 10);
}

/// Calls the native reload. Each method resolves to a value and never
/// throws.
class OneVpnHandoverHost {
  OneVpnHandoverHost({OneVpnHandoverHostApi? api})
    : _api = api ?? OneVpnHandoverHostApi();

  final OneVpnHandoverHostApi _api;

  /// Whether the native side can reload a running core in place now. It
  /// answers true while the tunnel interface is up and the service reads
  /// connected. It answers false in the held state and with no tunnel. It
  /// also answers false when the channel has no handler, fails, or outlives
  /// its bound.
  Future<bool> reloadSupported() async {
    try {
      return await _api.reloadSupported().timeout(
        OneVpnHandoverDeadlines.reloadSupported,
        onTimeout: () {
          ygLogger('OneVpnHandoverHost.reloadSupported expired');
          return false;
        },
      );
    } on PlatformException {
      return false;
    } catch (error) {
      ygLogger(
        'OneVpnHandoverHost.reloadSupported failed (${error.runtimeType})',
      );
      return false;
    }
  }

  /// Reloads the core from the staged request. [requestId] names this
  /// reload in its events. No other reload may use it.
  ///
  /// It answers [ReloadResult.timeout] when the state is unknown. That
  /// covers an expired [OneVpnHandoverDeadlines.reload], a channel with no
  /// handler, a native error, and an undecodable reply. It drops a
  /// completion after the bound. The native reload keeps running.
  /// [reloadSupported] detects a missing handler.
  Future<ReloadResult> reload(String requestId) async {
    try {
      return await _api
          .reload(ReloadRequest(requestId: requestId))
          .timeout(
            OneVpnHandoverDeadlines.reload,
            onTimeout: () {
              ygLogger('OneVpnHandoverHost.reload expired');
              return ReloadResult.timeout;
            },
          );
    } on PlatformException catch (error) {
      ygLogger('OneVpnHandoverHost.reload failed: ${error.code}');
      return ReloadResult.timeout;
    } catch (error) {
      ygLogger('OneVpnHandoverHost.reload failed (${error.runtimeType})');
      return ReloadResult.timeout;
    }
  }
}

/// Receives reload events from the native side and republishes them on
/// [events].
///
/// The engine buffers the last event that arrives with no receiver
/// attached. [attach] delivers that event first, so a receiver can see an
/// event older than itself.
class OneVpnHandoverEvents implements OneVpnHandoverFlutterApi {
  /// The attached receiver per messenger. The null key is the default
  /// messenger.
  static final _owners = <BinaryMessenger?, OneVpnHandoverEvents>{};

  final _controller = StreamController<ReloadEvent>.broadcast();

  /// Every event received while attached, in arrival order.
  Stream<ReloadEvent> get events => _controller.stream;

  /// Registers this receiver on [messenger], or on the default messenger.
  /// A later registration on the same messenger replaces this one.
  void attach({BinaryMessenger? messenger}) {
    _owners[messenger] = this;
    OneVpnHandoverFlutterApi.setUp(this, binaryMessenger: messenger);
  }

  /// Removes the receiver from [messenger], or from the default messenger.
  /// Does nothing when another receiver attached there since.
  void detach({BinaryMessenger? messenger}) {
    if (!identical(_owners[messenger], this)) return;
    _owners.remove(messenger);
    OneVpnHandoverFlutterApi.setUp(null, binaryMessenger: messenger);
  }

  @override
  Future<void> reloadEvent(ReloadEvent event) async {
    if (!_controller.isClosed) _controller.add(event);
  }

  /// Closes [events]. It drops every event received afterwards.
  Future<void> close() => _controller.close();
}
