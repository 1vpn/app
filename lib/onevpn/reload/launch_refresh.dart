import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:onexray/core/tools/logger.dart';
import 'package:onexray/onevpn/app/held_tunnel.dart';
import 'package:onexray/onevpn/connect/native_connect.dart';
import 'package:onexray/onevpn/handover/reload_policy.dart';
import 'package:onexray/service/connect/coordinator.dart';
import 'package:onexray/service/connect/runtime.dart';
import 'package:onexray/service/connect/settings.dart';

/// What one launch refresh did.
enum OneVpnLaunchRefreshOutcome {
  /// No tunnel runs, or the running request is the one the app compiles
  /// now. Nothing changed.
  current,

  /// The refresh left the tunnel alone and logged one line saying why.
  skipped,

  /// The current request runs in place on the same TUN.
  reloaded,

  /// The tunnel stopped and started again on the current configuration.
  reconnected,

  /// The change did not apply. The reload policy or the coordinator shows
  /// the result as for any change. The next launch checks again.
  notApplied,
}

/// Brings a running tunnel up to the request the app compiles now, once per
/// launch, with no dialog.
///
/// The system restarts a tunnel from the request the app stored last. After
/// an update that request is the old version's, and nothing else replaces it
/// until a change from the app. [run] prepares the stored configuration over
/// the running entries and compares the result with the running request.
/// The TUN settings compare in full. The core config compares as JSON
/// without its metrics listener, which holds a port each prepare allocates.
///
/// - Equal: nothing happens.
/// - Different: the stored configuration applies in place through
///   [reloads]. A reload that answers needsReconnect, as a TUN change does,
///   takes one reconnect through the coordinator's apply, while the tunnel
///   still runs. The reconnect stops the tunnel and starts the prepared
///   runtime: a pinned request on the running entries. No measure core
///   starts, so the new tunnel needs nothing from the app after the native
///   start. Any other answer ends the refresh.
///
/// It acts only on a connected pinned tunnel whose selection, traffic mode
/// and direct regions equal the stored ones. It commits only the stored
/// configuration, so those stay as stored. It skips, with one log line, a
/// tunnel that connects, measures, holds or failed, a held TUN, a change in
/// flight, a store that names another selection, mode or region, and a
/// prepare that fails or falls back to Automatic. A second call in the same
/// launch skips. It never throws.
class OneVpnLaunchRefresh {
  OneVpnLaunchRefresh({
    this._coordinator,
    this._reloads,
    this._held,
    this._prepare,
    this._measuring,
  });

  /// The refresh the boot runs.
  static final instance = OneVpnLaunchRefresh();

  final ConnectionCoordinator? _coordinator;
  final OneVpnReloadPolicy? _reloads;
  final OneVpnHeldTunnel? _held;
  final OneVpnReloadPrepare? _prepare;
  final ValueListenable<bool>? _measuring;

  bool _ran = false;

  ConnectionCoordinator get _shared =>
      _coordinator ?? ConnectionCoordinator.instance;

  OneVpnReloadPolicy get _policy => _reloads ?? OneVpnReloadPolicy.instance;

  /// Runs the refresh once. Must start after the native connect installs
  /// its prepare and the reload policy attaches.
  Future<OneVpnLaunchRefreshOutcome> run() async {
    if (_ran) return _skip('it already ran at this launch');
    _ran = true;
    final coordinator = _shared;
    try {
      await coordinator.initialize();
      final view = coordinator.state.value;
      switch (view.phase) {
        case ConnectionPhase.disconnected:
          return OneVpnLaunchRefreshOutcome.current;
        case ConnectionPhase.connected:
          break;
        case ConnectionPhase.failed:
          return _skip('the tunnel failed or is held');
        case _:
          return _skip('a connect or a change is in progress');
      }
      final running = view.runtime;
      if (running == null) return _skip('the running request is unreadable');
      if (OneVpnNativeConnect.isMeasure(running) ||
          (_measuring ?? OneVpnNativeConnect.instance.measuring).value) {
        return _skip('the tunnel measures or holds');
      }
      if (_policy.state.value != OneVpnReloadState.connected) {
        return _skip('a change is in progress');
      }
      if (await (_held ?? OneVpnHeldTunnel.instance).refresh()) {
        return _skip('the TUN is held');
      }
      final stored = await coordinator.configuration;
      if (!_sameChoice(stored.connection, running.configuration.connection)) {
        return _skip('the store names another selection, mode or region');
      }
      final ConnectionRuntime fresh;
      try {
        fresh = await (_prepare ?? OneVpnNativeConnect.instance.reloadPrepare)(
          coordinator,
          stored,
          running,
        );
      } catch (error) {
        return _skip(
          'the stored selection does not prepare '
          '(${error.runtimeType})',
        );
      }
      if (fresh.notice == 'selectionReset') {
        return _skip('the stored selection falls back to Automatic');
      }
      if (isCurrent(running, fresh)) return OneVpnLaunchRefreshOutcome.current;
      final result = await _policy.applyInPlace(
        coordinator,
        stored,
        expectedConfiguration: stored.encode(),
      );
      if (result.outcome == OneVpnReloadOutcome.applied) {
        _log('reloaded the running request in place');
        return OneVpnLaunchRefreshOutcome.reloaded;
      }
      if (result.outcome != OneVpnReloadOutcome.needsReconnect) {
        _log('the reload answered ${result.outcome.name}');
        return OneVpnLaunchRefreshOutcome.notApplied;
      }
      // Read after the reload: the reconnect runs only while the tunnel
      // still runs.
      if (coordinator.state.value.phase != ConnectionPhase.connected) {
        return _skip('the tunnel stopped before the reconnect');
      }
      _log('reconnecting onto the current request');
      // Must start [fresh], never the fresh-connect prepare: that prepare
      // starts a measure core, whose pin runs only while the app runs.
      await coordinator.apply(
        stored,
        expectedConfiguration: stored.encode(),
        prepare: (_, _) async => fresh,
      );
      return OneVpnLaunchRefreshOutcome.reconnected;
    } catch (error, stackTrace) {
      _log('the refresh failed: $error\n$stackTrace');
      return OneVpnLaunchRefreshOutcome.notApplied;
    }
  }

  /// Whether [running] is the request [fresh] describes: the same TUN
  /// settings and the same core config apart from the metrics listener.
  /// Key order in the core config never counts.
  static bool isCurrent(ConnectionRuntime running, ConnectionRuntime fresh) =>
      jsonEncode(running.request.tun?.toJson()) ==
          jsonEncode(fresh.request.tun?.toJson()) &&
      const DeepCollectionEquality().equals(_core(running), _core(fresh));

  static Object? _core(ConnectionRuntime runtime) {
    final config = jsonDecode(runtime.xrayJson);
    if (config is Map<String, dynamic>) config.remove('metrics');
    return config;
  }

  static bool _sameChoice(ConnectionSettings a, ConnectionSettings b) =>
      jsonEncode(a.selection.toJson()) == jsonEncode(b.selection.toJson()) &&
      a.trafficMode == b.trafficMode &&
      const ListEquality<String>().equals(
        a.smart.directRegions,
        b.smart.directRegions,
      );

  OneVpnLaunchRefreshOutcome _skip(String reason) {
    _log('skipped: $reason');
    return OneVpnLaunchRefreshOutcome.skipped;
  }

  static void _log(String line) => ygLogger('OneVpnLaunchRefresh: $line');
}
