// Connection actions for fork screens. A failure shows a fork notice. A
// connected change reloads in place where the platform supports it, and
// otherwise reconnects.

import 'package:material_ui/material_ui.dart';
import 'package:onexray/onevpn/app/held_tunnel.dart';
import 'package:onexray/onevpn/feedback/failure_message.dart';
import 'package:onexray/onevpn/feedback/notice.dart';
import 'package:onexray/onevpn/handover/reload_policy.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations.dart';
import 'package:onexray/onevpn/reload/premium_selection.dart';
import 'package:onexray/onevpn/shell/connect_control.dart';
import 'package:onexray/service/connect/coordinator.dart';
import 'package:onexray/service/connect/failure.dart';
import 'package:onexray/service/connect/runtime.dart';
import 'package:onexray/service/connect/settings.dart';
import 'package:onexray/service/shared/failure.dart';

/// Runs [action] against [coordinator]. Resolves whether it completed.
///
/// A failure shows its message as a notice. A cancel by the user shows
/// nothing: the error, its reason, or the coordinator's issue marks it. A
/// failure that lands in the red state with its "Connection failed" line
/// shows nothing either. [held] is the signal that state reads, the shared
/// one by default.
///
/// When the action falls back to Automatic, a notice says so. It names
/// [selectionLabel], the selection the action started from. With
/// [notifyFallback] and no label, the notice names no location. With
/// neither, a fallback shows no notice.
Future<bool> oneVpnRunConnectionAction(
  BuildContext context,
  ConnectionCoordinator coordinator,
  Future<void> Function() action, {
  String? selectionLabel,
  bool notifyFallback = false,
  OneVpnHeldTunnel? held,
}) async {
  try {
    await action();
    if ((selectionLabel != null || notifyFallback) &&
        coordinator.state.value.issue == 'selectionReset' &&
        context.mounted) {
      oneVpnShowSelectionReset(context, selectionLabel);
    }
    return true;
  } catch (error) {
    if (!failureCancelled(error) &&
        connectionFailureReason(error) != 'cancelled' &&
        coordinator.state.value.issue != 'cancelled' &&
        context.mounted) {
      if (await oneVpnFailureOnScreen(coordinator, held) || !context.mounted) {
        return false;
      }
      OneVpnNotice.error(
        context,
        oneVpnConnectionFailureMessage(
          OneVpnLocalizations.of(context)!,
          error: error,
        ),
      );
    }
    return false;
  }
}

/// Whether the red state already shows the failure with its detail line.
/// Only a failed start waits for the native answer: it decides between red
/// and grey. [held] is the shared signal by default.
Future<bool> oneVpnFailureOnScreen(
  ConnectionCoordinator coordinator,
  OneVpnHeldTunnel? held,
) async {
  final tunnel = held ?? OneVpnHeldTunnel.instance;
  if (OneVpnConnectControlState.failedStart(coordinator.state.value)) {
    await tunnel.refresh();
  }
  return OneVpnConnectControlState.failureLine(
    coordinator.state.value,
    held: tunnel.value,
  );
}

/// Shows the fallback-to-Automatic notice. It names [label], or no location
/// when [label] is null.
void oneVpnShowSelectionReset(BuildContext context, String? label) {
  final l = OneVpnLocalizations.of(context)!;
  OneVpnNotice.info(
    context,
    label == null
        ? l.onevpnSelectionResetUnnamed
        : l.onevpnSelectionReset(label),
  );
}

/// Merges [values] into the stored connection settings and applies them.
///
/// A tunnel in any phase but disconnected or failed reloads in place through
/// [reloadPolicy], the shared policy by default, with no dialog. A reload
/// during a connect runs once the connect lands. The in-place reload runs on
/// Android only. A change that did not apply shows the rollback notice
/// naming [label]. A double failure lands in the red state with
/// nothing committed. So does a change that finds no core over a held TUN.
/// Where the change cannot reload in place, a tunnel that still runs
/// reconnects with no dialog. The reconnect runs the coordinator's
/// fresh-connect prepare. A change that falls back to Automatic shows a
/// notice naming [label]. The outcome notices show even when the page closed
/// during the reload. The change first releases any TUN that [held] reports.
/// Resolves the saved configuration, or the current one when nothing
/// changes. Resolves null when the change does not apply.
Future<ConnectionConfiguration?> oneVpnApplyConnectionChange(
  BuildContext context,
  ConnectionCoordinator coordinator,
  Map<String, dynamic> values, {
  required String label,
  OneVpnHeldTunnel? held,
  OneVpnReloadPolicy? reloadPolicy,
}) async {
  final current = await coordinator.configuration;
  final next = ConnectionConfiguration(
    connection: ConnectionSettings.fromJson({
      ...current.connection.toJson(),
      ...values,
    }),
    policy: current.policy,
  );
  if (next.encode() == current.encode()) return current;
  if (!context.mounted) return null;
  final tunnel = held ?? OneVpnHeldTunnel.instance;
  OneVpnReloadOutcome? outcome;
  if (oneVpnReloadsFirst(coordinator.state.value.phase)) {
    outcome = await _reloadInPlace(
      context,
      coordinator,
      reloadPolicy ?? OneVpnReloadPolicy.instance,
      next,
      expectedConfiguration: current.encode(),
      label: label,
      held: tunnel,
    );
    switch (outcome) {
      case OneVpnReloadOutcome.applied:
        return coordinator.configuration;
      case OneVpnReloadOutcome.needsReconnect || OneVpnReloadOutcome.notRunning:
        break;
      case OneVpnReloadOutcome.rolledBack ||
          OneVpnReloadOutcome.superseded ||
          null:
        return null;
      case OneVpnReloadOutcome.held:
        // The red state carries it. The caller returns to the connect screen.
        await tunnel.refresh();
        return null;
    }
  }
  if (!context.mounted) return null;
  // Read after any reload: only a tunnel that still runs reconnects.
  final reconnect =
      coordinator.state.value.phase == ConnectionPhase.connected &&
      outcome != OneVpnReloadOutcome.notRunning;
  ConnectionConfiguration? saved;
  await oneVpnRunConnectionAction(
    context,
    coordinator,
    () async {
      await tunnel.release(coordinator);
      await coordinator.apply(
        next,
        prepare: coordinator.freshConnectPrepare,
        expectedConfiguration: current.encode(),
        allowReconnect: reconnect,
      );
      saved = await coordinator.configuration;
    },
    selectionLabel: label,
    held: tunnel,
  );
  return saved;
}

/// Reloads [next] in place as a connection action. A change that did not apply
/// shows the rollback notice naming [label]. An applied change that fell back
/// to Automatic shows the fallback notice. Both show through a target captured
/// before the reload. Resolves the outcome, or null when the reload threw.
Future<OneVpnReloadOutcome?> _reloadInPlace(
  BuildContext context,
  ConnectionCoordinator coordinator,
  OneVpnReloadPolicy reloadPolicy,
  ConnectionConfiguration next, {
  required String expectedConfiguration,
  required String label,
  required OneVpnHeldTunnel held,
}) async {
  final noticeTarget = OneVpnNoticeTarget.of(context);
  final l = OneVpnLocalizations.of(context)!;
  OneVpnReloadResult? result;
  await oneVpnRunConnectionAction(
    context,
    coordinator,
    () async => result = await reloadPolicy.applyInPlace(
      coordinator,
      next,
      expectedConfiguration: expectedConfiguration,
    ),
    held: held,
  );
  switch (result) {
    case (outcome: OneVpnReloadOutcome.rolledBack, notice: _):
      noticeTarget.error(l.onevpnReloadRolledBack(label));
    case (outcome: OneVpnReloadOutcome.applied, notice: 'selectionReset'):
      noticeTarget.info(l.onevpnSelectionReset(label));
    case _:
      break;
  }
  return result?.outcome;
}
