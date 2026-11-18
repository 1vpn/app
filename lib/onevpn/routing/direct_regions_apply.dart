import 'package:collection/collection.dart';
import 'package:onexray/core/tools/logger.dart';
import 'package:onexray/onevpn/app/held_tunnel.dart';
import 'package:onexray/onevpn/connect/native_connect.dart';
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
/// one direct code and no Apple, Microsoft or Bing carve-out.
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
  /// no direct regions. A code is smart with that one direct region and the
  /// Apple and Windows switches off. The region's own names and the
  /// local-network names are then its only direct domains. Every other
  /// setting rides through unchanged.
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
          if (regionCode != null) ...{
            'directApple': false,
            'directWindows': false,
          },
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
  /// Under smart, a change to the Apple or Windows switch changes it too.
  static bool affectsRuntime(
    ConnectionConfiguration original,
    String? regionCode,
  ) {
    final next = nextConfiguration(original, regionCode).connection;
    final before = original.connection;
    return next.trafficMode != before.trafficMode ||
        !const ListEquality<String>().equals(
          next.smart.directRegions,
          before.smart.directRegions,
        ) ||
        (next.trafficMode == TrafficMode.smart &&
            (next.smart.directApple != before.smart.directApple ||
                next.smart.directWindows != before.smart.directWindows));
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
  }) => _apply(
    regionCode: regionCode,
    confirmReconnect: confirmReconnect,
    releaseHeld: true,
  );

  /// [apply] with the hold step chosen. With [releaseHeld] false it releases
  /// nothing: a held TUN is left held and the call answers unchanged without
  /// touching the tunnel.
  Future<OneVpnDirectRegionsOutcome> _apply({
    required String? regionCode,
    required Future<bool> Function() confirmReconnect,
    required bool releaseHeld,
  }) async {
    await coordinator.initialize();
    if (releaseHeld) {
      await held.release(coordinator);
    } else if (await held.refresh()) {
      return OneVpnDirectRegionsOutcome.unchanged;
    }
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

  /// Reloads a connected tunnel that runs one region with the Apple or
  /// Windows switch on while the store holds that same region with both
  /// off. The reload is a pick of the stored region through [apply]: it runs
  /// in place through [reloadPolicy] and declines a reconnect, so it never
  /// asks. It never releases a held TUN. Every other state is left alone: no
  /// tunnel, a phase other than connected, a measure core, a running or
  /// stored configuration that is not smart with exactly that one region,
  /// and a tunnel that agrees with the store on both switches. A failure is
  /// logged and never thrown. A rolled-back or declined reload leaves the
  /// tunnel as it ran, and the next start checks again. A reload that fails
  /// twice takes the failed-start path, as any failed reload does: the TUN
  /// is held and the app shows the failed state. Returns false when nothing
  /// was due, a hold stood, the reconnect was declined, or the call threw,
  /// and true otherwise.
  Future<bool> reloadRunningSwitches() async {
    try {
      await coordinator.initialize();
      final view = coordinator.state.value;
      final running = view.runtime;
      if (view.phase != ConnectionPhase.connected ||
          running == null ||
          OneVpnNativeConnect.isMeasure(running)) {
        return false;
      }
      final stored = (await coordinator.configuration).connection;
      final region = selectionOf(stored);
      if (region == null) return false;
      bool onlyRegion(ConnectionSettings connection) =>
          connection.trafficMode == TrafficMode.smart &&
          const ListEquality<String>().equals(connection.smart.directRegions, [
            region,
          ]);
      final run = running.configuration.connection;
      final stale =
          onlyRegion(stored) &&
          onlyRegion(run) &&
          !stored.smart.directApple &&
          !stored.smart.directWindows &&
          (run.smart.directApple || run.smart.directWindows);
      if (!stale) return false;
      final outcome = await _apply(
        regionCode: region,
        confirmReconnect: () async => false,
        releaseHeld: false,
      );
      return outcome != OneVpnDirectRegionsOutcome.unchanged;
    } catch (error, stackTrace) {
      ygLogger(
        'OneVpnDirectRegions: switch reload failed: $error\n$stackTrace',
      );
      return false;
    }
  }
}
