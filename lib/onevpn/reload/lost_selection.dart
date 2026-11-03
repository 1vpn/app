import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:onexray/core/tools/logger.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/account/session.dart';
import 'package:onexray/onevpn/catalogue/catalogue.dart';
import 'package:onexray/onevpn/catalogue/location.dart';
import 'package:onexray/onevpn/catalogue/node_catalog.dart';
import 'package:onexray/onevpn/connect/native_connect.dart';
import 'package:onexray/onevpn/handover/reload_policy.dart';
import 'package:onexray/onevpn/model/user_data.dart';
import 'package:onexray/onevpn/reload/premium_selection.dart';
import 'package:onexray/service/connect/coordinator.dart';
import 'package:onexray/service/connect/runtime.dart';
import 'package:onexray/service/connect/settings.dart';

/// Moves a location selection to Automatic once the account no longer has
/// that location.
///
/// An account location belongs to a premium account. Sign-out and a lapsed
/// premium tier take it away, and so does an account list that no longer
/// carries it. While the account is premium and lists it, an account location
/// stays selected, working or not. A connect to one that is not working fails
/// with an error. An empty account list is one not yet loaded, and it keeps
/// every account location. Any other location stays while the account's
/// catalogue lists it as connectable.
///
/// An Automatic selection re-measures once its pinned node rows are gone. A
/// lapse reprovisions the free floor and deletes the account rows. An
/// Automatic tunnel pinned on one then reloads in place through the
/// fresh-connect prepare, which measures the rows that remain. A tunnel that
/// is down, a measure core, and a pin whose rows all remain change nothing.
///
/// Only a signed-in or signed-out account decides. A tunnel up or coming up
/// reloads in place onto Automatic. A tunnel that is down commits Automatic
/// with no connect. It never asks through a dialog.
class OneVpnLostSelection {
  OneVpnLostSelection({this._coordinator, this._accountState, this._reloads});

  /// The one hook the reload owner runs.
  static final OneVpnLostSelection instance = OneVpnLostSelection();

  final ConnectionCoordinator? _coordinator;

  /// The live account. Defaults to the account service's.
  final ValueListenable<OneVpnAccountState>? _accountState;

  /// The in-place reload. Defaults to [OneVpnReloadPolicy.instance].
  final OneVpnReloadPolicy? _reloads;

  /// Applies the move for the live account. A selection the account still
  /// has changes nothing. A change that did not apply leaves the selection
  /// as it was.
  Future<void> run() async {
    if (!_decides(_live)) return;
    final coordinator = _coordinator ?? ConnectionCoordinator.instance;
    try {
      final current = await coordinator.configuration;
      final selection = current.connection.selection;
      if (selection.kind == SelectionKind.automatic) {
        if (!_decides(_live) || !await _pinGone(coordinator)) return;
        await oneVpnApplySelection(
          coordinator,
          current,
          current,
          reloads: _reloads,
        );
        return;
      }
      // The account can change while the configuration loads. The live one
      // decides.
      final live = _live;
      if (!_decides(live) || !lost(selection, _sessionOf(live))) return;
      final next = ConnectionConfiguration(
        connection: ConnectionSettings.fromJson({
          ...current.connection.toJson(),
          'selection': const ServerSelection.automatic().toJson(),
        }),
        policy: current.policy,
      );
      await oneVpnApplySelection(coordinator, current, next, reloads: _reloads);
    } catch (error, stackTrace) {
      ygLogger("lost selection failed: $error\n$stackTrace");
    }
  }

  /// Whether the account of [session], or the signed-out account when null,
  /// no longer has the location [selection] names. Every other selection kind
  /// is never lost.
  @visibleForTesting
  static bool lost(ServerSelection selection, OneVpnSession? session) {
    if (selection.kind != SelectionKind.location) return false;
    final stem = selection.location;
    if (stem == null) return true;
    final catalogue = OneVpnCatalogue.forSession(session);
    if (stem.startsWith(OneVpnLocation.accountRowNamePrefix)) {
      if (catalogue.tier != OneVpnTier.premium) return true;
      final listed = session?.locations ?? const <OneVpnApiLocation>[];
      if (listed.isEmpty) return false;
      // The session catalogue carries the provisioner's stems for the
      // connectable locations. The full list names the rest.
      return !{
        ..._stems(catalogue),
        ..._stems(
          OneVpnCatalogue.of(
            tier: OneVpnTier.premium,
            locations: listed,
            freeTier: false,
          ),
        ),
      }.contains(stem);
    }
    return !{
      for (final pair in oneVpnCatalogueDomainPairs(catalogue.entries))
        if (pair.entry.location.isConnectable) pair.location.rowNameStem,
    }.contains(stem);
  }

  /// Whether a tunnel is up or coming up on a pinned runtime with an entry
  /// whose node row no longer exists.
  static Future<bool> _pinGone(ConnectionCoordinator coordinator) async {
    // An uninitialized coordinator reads disconnected over a running tunnel.
    await coordinator.initialize();
    final phase = coordinator.state.value.phase;
    if (phase == ConnectionPhase.disconnected ||
        phase == ConnectionPhase.failed) {
      return false;
    }
    final running = await coordinator.readCurrentRuntime();
    if (running == null || OneVpnNativeConnect.isMeasure(running)) {
      return false;
    }
    for (final entry in running.entries) {
      if (await coordinator.db.coreConfigDao.searchRow(entry.id) == null) {
        return true;
      }
    }
    return false;
  }

  /// The row-name stem of every location in [catalogue].
  static Iterable<String> _stems(OneVpnCatalogue catalogue) => [
    for (final pair in oneVpnCatalogueDomainPairs(catalogue.entries))
      pair.location.rowNameStem,
  ];

  OneVpnAccountState get _live =>
      (_accountState ?? OneVpnAccountService.instance.state).value;

  /// Whether [state] decides. Only a signed-in or signed-out account does.
  static bool _decides(OneVpnAccountState state) =>
      state is OneVpnAccountSignedIn || state is OneVpnAccountSignedOut;

  /// The session [state] carries, or null for a signed-out account.
  static OneVpnSession? _sessionOf(OneVpnAccountState state) =>
      state is OneVpnAccountSignedIn ? state.session : null;
}
