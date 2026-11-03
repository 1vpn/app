// The single reactor to account-state change. It re-provisions the
// catalogue when the dialable set changes. No page or service provisions
// on its own.
//
// Boot registers it once, after the account restore. It listens to
// OneVpnAccountService.state. It re-runs the provisioner on the settled
// transitions that change the dialable set. Those are a sign-in, a tier
// flip, a changed connectable-location set, and account rows turning
// dialable. A refresh that only rotates the token leaves the set unchanged
// and triggers nothing. Restoring is not a settled state and triggers
// nothing. The account service sweep owns sign-out. It runs after the
// state flips. The owner leaves the free floor standing and never races
// the sweep. The selection check runs on sign-out, after every
// reprovision, and once at launch through checkSelection.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:onexray/core/tools/logger.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/account/session.dart';
import 'package:onexray/onevpn/catalogue/catalogue.dart';
import 'package:onexray/onevpn/provision/node_provisioner.dart';
import 'package:onexray/onevpn/reload/lost_selection.dart';
import 'package:onexray/onevpn/reload/premium_selection.dart';

/// Re-provisions the catalogue for a session and returns what it did. The
/// default drives the production provisioner. Tests inject their own.
typedef OneVpnReprovision = Future<OneVpnProvisionResult> Function(
  OneVpnSession? session,
);

/// Runs after the reprovision that follows a flip to dialable premium
/// account rows.
typedef OneVpnPremiumFlip = Future<void> Function(OneVpnSession session);

/// Runs after every settled account change and once at launch. It reads the
/// live account itself.
typedef OneVpnSelectionCheck = Future<void> Function();

/// What the provisioner would produce, reduced to the parts that decide
/// whether a rebuild is due. Those parts are presence, tier, the
/// connectable-location set, the account's full location list, and whether
/// the account rows are dialable. The full list decides the selection check
/// alone: a location dropped with no server changes no connectable set.
/// The key omits the session token. A token rotation compares equal and
/// skips the rebuild.
@immutable
class _ProvisionKey {
  const _ProvisionKey({
    required this.signedIn,
    required this.tier,
    required this.connectable,
    required this.listed,
    required this.accountDialable,
  });

  final bool signedIn;
  final OneVpnTier tier;
  final String connectable;

  /// The account's locations, connectable or not, as sorted codes.
  final String listed;

  /// Whether the account rows are dialable: a premium tier, a catalogue
  /// that is not degraded, and complete account credentials.
  final bool accountDialable;

  @override
  bool operator ==(Object other) =>
      other is _ProvisionKey &&
      other.signedIn == signedIn &&
      other.tier == tier &&
      other.connectable == connectable &&
      other.listed == listed &&
      other.accountDialable == accountDialable;

  @override
  int get hashCode =>
      Object.hash(signedIn, tier, connectable, listed, accountDialable);
}

class OneVpnReloadOwner {
  OneVpnReloadOwner({
    ValueListenable<OneVpnAccountState>? accountState,
    OneVpnReprovision? reprovision,
    this._onPremium,
    this._onSettled,
  }) : _accountState = accountState ?? OneVpnAccountService.instance.state,
       _reprovision =
           reprovision ?? OneVpnNodeProvisioner().provisionForSession;

  /// The one owner every boot registers. A flip to premium runs
  /// [OneVpnPremiumSelection]. Every settled change runs
  /// [OneVpnLostSelection].
  static final OneVpnReloadOwner instance = OneVpnReloadOwner(
    onPremium: OneVpnPremiumSelection.instance.run,
    onSettled: OneVpnLostSelection.instance.run,
  );

  final ValueListenable<OneVpnAccountState> _accountState;
  final OneVpnReprovision _reprovision;
  final OneVpnPremiumFlip? _onPremium;
  final OneVpnSelectionCheck? _onSettled;

  bool _registered = false;
  _ProvisionKey? _baseline;

  /// Subscribes to the account state and records the settled state as the
  /// baseline. The boot provision step provisions this same state. The
  /// baseline keeps the first later change from re-provisioning what boot
  /// already built. Idempotent: a second call does nothing.
  void register() {
    if (_registered) return;
    _registered = true;
    _baseline = _keyFor(_accountState.value);
    _accountState.addListener(_onAccountStateChanged);
  }

  void _onAccountStateChanged() {
    final state = _accountState.value;
    // Restoring is not settled: the owner decides nothing against it.
    if (state is OneVpnAccountRestoring) return;
    final key = _keyFor(state);
    // The account service sweep owns sign-out. The sweep runs after the
    // state flips to signed out, so provisioning here would race it. The
    // free floor already stands. The selection check touches no node row.
    // Must run before the equality check: a failed sign-in reprovision
    // leaves the signed-out baseline, and the sign-out still checks.
    if (state is OneVpnAccountSignedOut) {
      _baseline = key;
      unawaited(checkSelection());
      return;
    }
    if (key == _baseline) return;
    // A pending grant or a degraded catalogue waits: the flip counts once
    // the account rows are dialable.
    final turnedPremium =
        key.accountDialable && !(_baseline?.accountDialable ?? false);
    final previous = _baseline;
    _baseline = key;
    unawaited(
      _reprovisionFor(
        state,
        key: key,
        previous: previous,
        turnedPremium: turnedPremium,
      ),
    );
  }

  /// Reprovisions for [state] and logs what the provision reports. On a flip
  /// to dialable premium account rows, the premium hook runs after the
  /// reprovision writes those rows. A failed reprovision skips the hook. It
  /// restores the [previous] baseline unless a later change replaced [key],
  /// so the next settled change retries. The selection check runs last,
  /// whether or not the reprovision succeeded.
  Future<void> _reprovisionFor(
    OneVpnAccountState state, {
    required _ProvisionKey key,
    required _ProvisionKey? previous,
    required bool turnedPremium,
  }) async {
    final session = _sessionFor(state);
    final OneVpnProvisionResult result;
    try {
      result = await _reprovision(session);
    } catch (error, stackTrace) {
      ygLogger("reload owner reprovision failed: $error\n$stackTrace");
      if (identical(_baseline, key)) _baseline = previous;
      await checkSelection();
      return;
    }
    oneVpnLogProvision(result);
    final onPremium = _onPremium;
    if (turnedPremium && session != null && onPremium != null) {
      try {
        await onPremium(session);
      } catch (error, stackTrace) {
        ygLogger("reload owner premium hook failed: $error\n$stackTrace");
      }
    }
    await checkSelection();
  }

  /// Runs the selection check and logs a failure. Boot calls it once, after
  /// the native connect installs its prepare.
  Future<void> checkSelection() async {
    final onSettled = _onSettled;
    if (onSettled == null) return;
    try {
      await onSettled();
    } catch (error, stackTrace) {
      ygLogger("reload owner selection check failed: $error\n$stackTrace");
    }
  }

  /// The session a state carries, or null for every state that maps to the
  /// free floor. [OneVpnAccountUnreadable] takes the free path, never the
  /// account path.
  OneVpnSession? _sessionFor(OneVpnAccountState state) =>
      state is OneVpnAccountSignedIn ? state.session : null;

  _ProvisionKey _keyFor(OneVpnAccountState state) {
    final catalogue = OneVpnCatalogue.forSession(_sessionFor(state));
    final connectable =
        catalogue.connectable
            .map((location) => '${location.countryCode}/${location.cityCode}')
            .toList()
          ..sort();
    final listed =
        (_sessionFor(state)?.locations ?? const [])
            .map((location) => '${location.countryCode}/${location.cityCode}')
            .toList()
          ..sort();
    return _ProvisionKey(
      signedIn: state is OneVpnAccountSignedIn,
      tier: catalogue.tier,
      connectable: connectable.join(','),
      listed: listed.join(','),
      accountDialable: oneVpnAccountDialable(_sessionFor(state)),
    );
  }
}
