// The recurring paywall's trigger: when the cadence is asked, and what
// happens with its answer.
//
// The screen owns the two moments it fires at: entry and resume. The
// entry point asks once more at launch, before the first frame.

import 'dart:async';

import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/paywall/paywall_cadence.dart';

/// The session facts the trigger reads.
abstract interface class OneVpnPaywallAudience {
  /// Completes once the stored session has settled.
  Future<void> whenRestored();

  /// Whether the settled session holds premium, an unconfirmed optimistic
  /// grant included.
  bool get entitled;
}

/// Binds the trigger to an account service, the process-wide one by
/// default.
class OneVpnServicePaywallAudience implements OneVpnPaywallAudience {
  const OneVpnServicePaywallAudience({this.service});

  /// The service to bind to, or null for the process-wide one.
  final OneVpnAccountService? service;

  OneVpnAccountService get _target => service ?? OneVpnAccountService.instance;

  @override
  Future<void> whenRestored() => _target.whenRestored();

  @override
  bool get entitled => switch (_target.state.value) {
    OneVpnAccountSignedIn(:final session) => session.isPremiumEntitled,
    _ => false,
  };
}

/// How long the launch check waits for the session restore. A restore that
/// has not settled by then opens the connect screen.
const Duration kOneVpnLaunchPaywallRestoreDeadline = Duration(seconds: 2);

/// Decides and performs one recurring-paywall showing.
class OneVpnPaywallTrigger {
  OneVpnPaywallTrigger({
    OneVpnPaywallCadence? cadence,
    OneVpnPaywallAudience? audience,
  }) : cadence = cadence ?? OneVpnPaywallCadence(),
       audience = audience ?? const OneVpnServicePaywallAudience();

  final OneVpnPaywallCadence cadence;
  final OneVpnPaywallAudience audience;

  bool _running = false;

  /// Whether the launch opens on the paywall. The entry point asks this
  /// before the first frame and routes straight there on true.
  ///
  /// A true answer stamps the cadence, so the connect screen's entry check
  /// then finds nothing due. A restore that does not settle within
  /// [restoreDeadline] answers false and leaves the cadence unstamped.
  Future<bool> dueAtLaunch({
    Duration restoreDeadline = kOneVpnLaunchPaywallRestoreDeadline,
  }) async {
    try {
      await audience.whenRestored().timeout(restoreDeadline);
    } on TimeoutException {
      return false;
    }
    return cadence.consumeDue(entitled: audience.entitled);
  }

  /// Shows the recurring paywall when the cadence says it is due, and
  /// reports whether it did.
  ///
  /// Must await the session restore first: a premium account reads as
  /// signed out until the store answers.
  ///
  /// [isTopmost] is read again after every await. A push onto a screen the
  /// user has since left would interrupt the picker or the sign-in form.
  ///
  /// Overlapping calls answer false without asking the cadence. Two
  /// showings would spend one due window twice.
  Future<bool> run({
    required bool Function() isTopmost,
    required void Function() show,
  }) async {
    if (_running) return false;
    _running = true;
    try {
      await audience.whenRestored();
      if (!isTopmost()) return false;
      if (!await cadence.consumeDue(entitled: audience.entitled)) return false;
      if (!isTopmost()) return false;
      show();
      return true;
    } finally {
      _running = false;
    }
  }
}
