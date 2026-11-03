import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:onexray/core/tools/logger.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/account/session.dart';
import 'package:onexray/onevpn/catalogue/catalogue.dart';
import 'package:onexray/onevpn/handover/reload_policy.dart';
import 'package:onexray/onevpn/location/location_picker_model.dart';
import 'package:onexray/service/connect/coordinator.dart';
import 'package:onexray/service/connect/runtime.dart';
import 'package:onexray/service/connect/settings.dart';

/// Whether [session] can dial its account rows. That takes a premium tier,
/// a catalogue that is not degraded, and complete credentials.
bool oneVpnAccountDialable(OneVpnSession? session) {
  if (session == null) return false;
  final catalogue = OneVpnCatalogue.forSession(session);
  return catalogue.tier == OneVpnTier.premium &&
      !catalogue.isDegraded &&
      session.credentials.isComplete;
}

/// Moves the selection to Automatic when the account turns premium, as a
/// fresh connect to Automatic.
///
/// Must run after the premium reprovision: Automatic resolves against the
/// provisioned rows. It acts only once the account rows are dialable. It
/// checks the session it is given, then the live account just before it
/// applies.
///
/// A free location or Automatic with a tunnel up or coming up reloads in
/// place with the tunnel up. The coordinator's fresh-connect prepare starts
/// a measure core. The native connect then pins a node. A disconnected free
/// location saves as Automatic with no connect. Any other selection stays.
/// It never asks through a dialog.
class OneVpnPremiumSelection {
  OneVpnPremiumSelection({
    this._coordinator,
    this._accountState,
    this._reloads,
  });

  /// The one hook the reload owner runs.
  static final OneVpnPremiumSelection instance = OneVpnPremiumSelection();

  final ConnectionCoordinator? _coordinator;

  /// The live account. Defaults to the account service's.
  final ValueListenable<OneVpnAccountState>? _accountState;

  /// The in-place reload. Defaults to [OneVpnReloadPolicy.instance].
  final OneVpnReloadPolicy? _reloads;

  /// Applies the move for [session]. A session whose account rows are not
  /// dialable changes nothing. A change that did not apply leaves the
  /// selection as it was.
  Future<void> run(OneVpnSession session) async {
    if (!oneVpnAccountDialable(session)) return;
    final catalogue = OneVpnCatalogue.forSession(session);
    final coordinator = _coordinator ?? ConnectionCoordinator.instance;
    try {
      final current = await coordinator.configuration;
      final selection = current.connection.selection;
      final free =
          selection.kind == SelectionKind.location &&
          OneVpnLocationNaming.freeStems(catalogue)
              .contains(selection.location);
      final automatic = selection.kind == SelectionKind.automatic;
      final phase = coordinator.state.value.phase;
      final down =
          phase == ConnectionPhase.disconnected ||
          phase == ConnectionPhase.failed;
      if (!free && !(automatic && !down)) return;
      final next = ConnectionConfiguration(
        connection: ConnectionSettings.fromJson({
          ...current.connection.toJson(),
          'selection': const ServerSelection.automatic().toJson(),
          'expert': false,
        }),
        policy: current.policy,
      );
      // The account can change during the reprovision. The live one decides.
      final live = (_accountState ?? OneVpnAccountService.instance.state).value;
      if (!oneVpnAccountDialable(
        live is OneVpnAccountSignedIn ? live.session : null,
      )) {
        return;
      }
      await oneVpnApplySelection(coordinator, current, next, reloads: _reloads);
    } catch (error, stackTrace) {
      ygLogger("premium selection failed: $error\n$stackTrace");
    }
  }
}

/// Whether a change in [phase] takes the in-place reload first. Every phase
/// but disconnected and failed does. The reload queues behind a connect in
/// flight and runs once the connect lands. The in-place reload runs on
/// Android only. Elsewhere it answers needsReconnect and the change takes
/// the reconnect path.
bool oneVpnReloadsFirst(ConnectionPhase phase) =>
    phase != ConnectionPhase.disconnected && phase != ConnectionPhase.failed;

/// Applies [next] over [current] with no dialog.
///
/// It initializes [coordinator] first, so the phase it reads is the host's.
/// A tunnel up or coming up reloads in place through [reloads], the shared
/// policy by default, after the queue ahead of it. The reload prepares
/// through the fresh-connect prepare. A change that needs a reconnect, or
/// finds no core, takes the coordinator's apply with that prepare. A tunnel
/// that is down only commits.
Future<void> oneVpnApplySelection(
  ConnectionCoordinator coordinator,
  ConnectionConfiguration current,
  ConnectionConfiguration next, {
  OneVpnReloadPolicy? reloads,
}) async {
  // An uninitialized coordinator reads disconnected over a running tunnel.
  await coordinator.initialize();
  final fresh = coordinator.freshConnectPrepare;
  if (oneVpnReloadsFirst(coordinator.state.value.phase)) {
    final result = await (reloads ?? OneVpnReloadPolicy.instance).applyInPlace(
      coordinator,
      next,
      expectedConfiguration: current.encode(),
      // A reload takes no cancel. The cancel future never completes.
      prepare: fresh == null
          ? null
          : (_, change, _) => fresh(change, Completer<void>().future),
    );
    switch (result.outcome) {
      case OneVpnReloadOutcome.needsReconnect || OneVpnReloadOutcome.notRunning:
        break;
      case OneVpnReloadOutcome.applied ||
          OneVpnReloadOutcome.rolledBack ||
          OneVpnReloadOutcome.superseded ||
          OneVpnReloadOutcome.held:
        return;
    }
  }
  await coordinator.apply(
    next,
    expectedConfiguration: current.encode(),
    prepare: coordinator.freshConnectPrepare,
  );
}
