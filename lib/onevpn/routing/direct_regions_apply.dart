import 'package:collection/collection.dart';
import 'package:onexray/onevpn/app/held_tunnel.dart';
import 'package:onexray/onevpn/handover/reload_policy.dart';
import 'package:onexray/onevpn/reload/premium_selection.dart';
import 'package:onexray/service/connect/coordinator.dart';
import 'package:onexray/service/connect/runtime.dart';
import 'package:onexray/service/connect/runtime_host.dart';
import 'package:onexray/service/connect/settings.dart';

/// What a Direct-regions choice did.
enum OneVpnDirectRegionsOutcome {
  /// The change applied.
  applied,

  /// The change applied, and the location fell back to Automatic.
  selectionReset,

  /// Nothing changed: the user declined the reconnect, or a stop or a
  /// start moved the tunnel during the reload.
  unchanged,

  /// The change did not apply. The previous settings still run.
  rolledBack,
}

/// Writes a Direct-regions picker choice. When the routing changes, it
/// applies the choice to the running tunnel. All via VPN selects allVpn,
/// where the compiler emits no carve-out. A region selects smart with that
/// one direct code.
class OneVpnDirectRegionsApplyService {
  OneVpnDirectRegionsApplyService({
    ConnectionCoordinator? coordinator,
    OneVpnHeldTunnel? held,
    this._reloadPolicy,
  }) : coordinator = coordinator ?? ConnectionCoordinator.instance,
       held = held ?? OneVpnHeldTunnel.instance;

  final ConnectionCoordinator coordinator;

  /// The held signal. The service releases a held TUN before the change
  /// applies.
  final OneVpnHeldTunnel held;

  final OneVpnReloadPolicy? _reloadPolicy;

  /// The policy a connected change reloads through. Defaults to the shared
  /// one.
  OneVpnReloadPolicy get reloadPolicy =>
      _reloadPolicy ?? OneVpnReloadPolicy.instance;

  /// The configuration a row selects. A null code is All via VPN: allVpn with
  /// no direct regions. A code is smart with that one direct region. Every
  /// other setting rides through unchanged.
  static ConnectionConfiguration nextConfiguration(
    ConnectionConfiguration original,
    String? regionCode,
  ) {
    final mode = regionCode == null ? TrafficMode.allVpn : TrafficMode.smart;
    final regions = regionCode == null ? const <String>[] : [regionCode];
    return ConnectionConfiguration(
      connection: ConnectionSettings.fromJson({
        ...original.connection.toJson(),
        'trafficMode': mode.name,
        'smart': {
          ...original.connection.smart.toJson(),
          'directRegions': regions,
        },
      }),
      policy: original.policy,
    );
  }

  /// A configuration's picker row: the one direct region under smart, or null
  /// for All via VPN (allVpn, or smart with no direct region).
  static String? selectionOf(ConnectionSettings connection) =>
      connection.trafficMode == TrafficMode.smart &&
          connection.smart.directRegions.isNotEmpty
      ? connection.smart.directRegions.first
      : null;

  /// The stored selection as a picker row. An Off row stores allVpn first,
  /// through [storeOff].
  Future<String?> currentSelection() async {
    await coordinator.initialize();
    final row = selectionOf((await coordinator.configuration).connection);
    if (row == null) await storeOff();
    return row;
  }

  /// Stores allVpn with no direct region when the picker falls back to Off
  /// over any other mode. It writes the store only. A running tunnel keeps
  /// its routing until its next start or the next pick. A concurrent change
  /// wins.
  Future<void> storeOff() async {
    await coordinator.initialize();
    final original = await coordinator.configuration;
    if (original.connection.trafficMode == TrafficMode.allVpn) return;
    try {
      await coordinator.apply(
        nextConfiguration(original, null),
        affectsRuntime: false,
        expectedConfiguration: original.encode(),
      );
    } on ConnectionHostException {
      // The concurrent change stands. The next fallback writes again.
    }
  }

  /// The compiled routing changes when the mode or the direct regions change.
  static bool affectsRuntime(
    ConnectionConfiguration original,
    String? regionCode,
  ) {
    final next = nextConfiguration(original, regionCode);
    return next.connection.trafficMode != original.connection.trafficMode ||
        !const ListEquality<String>().equals(
          next.connection.smart.directRegions,
          original.connection.smart.directRegions,
        );
  }

  /// Reads the stored configuration and applies the row. It releases a held
  /// TUN first. The row changes the routing when it differs from the store
  /// or from the running tunnel. A change in any phase but disconnected or
  /// failed reloads in place through [reloadPolicy]. A reload during a
  /// connect runs once the connect lands. The in-place reload runs on Android
  /// only. Where it cannot run, the change reconnects only while the tunnel
  /// still runs and the user confirms. The reconnect runs the
  /// coordinator's fresh-connect prepare. A double failure throws, and
  /// so does a change that finds no core over a held TUN. Neither commits.
  Future<OneVpnDirectRegionsOutcome> apply({
    required String? regionCode,
    required Future<bool> Function() confirmReconnect,
  }) async {
    await coordinator.initialize();
    await held.release(coordinator);
    final original = await coordinator.configuration;
    // A store-only fallback can leave the running tunnel behind the store.
    final running = coordinator.state.value.runtime?.configuration;
    final changed =
        affectsRuntime(original, regionCode) ||
        (running != null && affectsRuntime(running, regionCode));
    final next = nextConfiguration(original, regionCode);
    var allowReconnect = false;
    if (changed && oneVpnReloadsFirst(coordinator.state.value.phase)) {
      final result = await reloadPolicy.applyInPlace(
        coordinator,
        next,
        expectedConfiguration: original.encode(),
      );
      switch (result.outcome) {
        case OneVpnReloadOutcome.applied:
          return result.notice == 'selectionReset'
              ? OneVpnDirectRegionsOutcome.selectionReset
              : OneVpnDirectRegionsOutcome.applied;
        case OneVpnReloadOutcome.rolledBack:
          return OneVpnDirectRegionsOutcome.rolledBack;
        case OneVpnReloadOutcome.superseded:
          return OneVpnDirectRegionsOutcome.unchanged;
        case OneVpnReloadOutcome.held:
          // A network reload failed twice during the change: the page takes
          // the red landing, and nothing commits.
          await held.refresh();
          throw const ConnectionHostException('startFailed');
        case OneVpnReloadOutcome.needsReconnect ||
            OneVpnReloadOutcome.notRunning:
          break;
      }
      // Read after the reload: the reconnect asks only while the tunnel
      // still runs.
      if (result.outcome == OneVpnReloadOutcome.needsReconnect &&
          coordinator.state.value.phase == ConnectionPhase.connected) {
        allowReconnect = await confirmReconnect();
        if (!allowReconnect) return OneVpnDirectRegionsOutcome.unchanged;
      }
    }
    await coordinator.apply(
      next,
      affectsRuntime: changed,
      allowReconnect: allowReconnect,
      expectedConfiguration: original.encode(),
      prepare: coordinator.freshConnectPrepare,
    );
    return coordinator.state.value.issue == 'selectionReset'
        ? OneVpnDirectRegionsOutcome.selectionReset
        : OneVpnDirectRegionsOutcome.applied;
  }
}
