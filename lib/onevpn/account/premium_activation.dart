// The paid-but-Free bridge: an optimistic premium grant and a bounded
// confirmation poll.
//
// The server turns a purchase premium through a webhook the client cannot
// observe. Until it lands, a buyer reads as Free.
//
// Grant only after the session flips to signed in. Skip the grant when the
// adopted session already reports premium: markPremiumPending carries no
// premium guard of its own.
//
// The poll can close unconfirmed. Every surface built on this says
// "confirming", never "you will be upgraded".

import 'package:flutter/foundation.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/account/outcomes.dart';

/// When the confirmation poll fires, measured from the grant.
///
/// The account endpoint allows ten calls a minute. The post-sign-up and
/// resume refreshes share that budget. The schedule leaves them headroom.
/// A failed refresh still spends an attempt.
const List<Duration> kOneVpnPremiumConfirmSchedule = <Duration>[
  Duration(seconds: 3),
  Duration(seconds: 8),
  Duration(seconds: 18),
  Duration(seconds: 35),
  Duration(seconds: 55),
];

/// The slice of the account service the activation needs.
abstract interface class OneVpnPremiumAccount {
  /// The session-change signal. Read for the adopted entitlement.
  ValueListenable<OneVpnAccountState> get state;

  /// Records the optimistic grant. False when nothing was written.
  Future<bool> markPremiumPending();

  /// Revalidates against the server. [manual] bypasses the cooldown. The
  /// confirmation poll always passes it.
  Future<OneVpnRefreshOutcome> refresh({required bool manual});
}

/// Binds the activation to an account service, the process-wide one by
/// default.
class OneVpnServicePremiumAccount implements OneVpnPremiumAccount {
  const OneVpnServicePremiumAccount({this.service});

  /// The service to bind to, or null for the process-wide one.
  final OneVpnAccountService? service;

  OneVpnAccountService get _target => service ?? OneVpnAccountService.instance;

  @override
  ValueListenable<OneVpnAccountState> get state => _target.state;

  @override
  Future<bool> markPremiumPending() => _target.markPremiumPending();

  @override
  Future<OneVpnRefreshOutcome> refresh({required bool manual}) =>
      _target.refresh(manual: manual);
}

/// What one activation did.
///
/// Every field records what happened, not what was intended.
class OneVpnPremiumActivationResult {
  const OneVpnPremiumActivationResult({
    required this.signedIn,
    required this.alreadyPremium,
    required this.markedPending,
    required this.confirmed,
    required this.attempts,
  });

  /// Whether a signed-in session was there to grant against. False means
  /// the caller ran before the session adoption. Nothing was recorded.
  final bool signedIn;

  /// The adopted session already reported premium. No marker was written
  /// and no poll ran.
  final bool alreadyPremium;

  /// The optimistic marker reached the store. False when the session is
  /// signed out or already premium, or when the store refuses the write.
  final bool markedPending;

  /// The server confirmed the entitlement before the window closed.
  final bool confirmed;

  /// How many refreshes the poll spent.
  final int attempts;

  /// Whether the poll window closed with the grant still unconfirmed. The
  /// service confirms or revokes it from here.
  bool get unconfirmed => markedPending && !confirmed;
}

/// Waits [delay] before the next poll attempt. Tests replace it to run the
/// schedule in no wall-clock time.
typedef OneVpnPollDelay = Future<void> Function(Duration delay);

/// Runs the optimistic grant and its confirmation poll.
///
/// Outlives the screen that starts it: it holds no BuildContext and reports
/// through the account state.
class OneVpnPremiumActivator {
  OneVpnPremiumActivator({
    OneVpnPremiumAccount? account,
    this.schedule = kOneVpnPremiumConfirmSchedule,
    OneVpnPollDelay? delay,
  }) : account = account ?? const OneVpnServicePremiumAccount(),
       _delay = delay ?? _sleep;

  final OneVpnPremiumAccount account;

  /// When each poll attempt fires, measured from the grant.
  final List<Duration> schedule;

  final OneVpnPollDelay _delay;

  static Future<void> _sleep(Duration delay) => Future<void>.delayed(delay);

  /// Grants premium optimistically, then polls until the server confirms
  /// or the window closes.
  Future<OneVpnPremiumActivationResult> activate() async {
    final state = account.state.value;
    if (state is! OneVpnAccountSignedIn) {
      // No session to grant against. markPremiumPending would record
      // nothing.
      return const OneVpnPremiumActivationResult(
        signedIn: false,
        alreadyPremium: false,
        markedPending: false,
        confirmed: false,
        attempts: 0,
      );
    }

    if (state.session.isPremium) {
      // Nothing to bridge. Marking would show an activated account as
      // activating.
      return const OneVpnPremiumActivationResult(
        signedIn: true,
        alreadyPremium: true,
        markedPending: false,
        confirmed: true,
        attempts: 0,
      );
    }

    final marked = await account.markPremiumPending();

    // Poll even when the marker was refused. The poll is what fetches real
    // premium.
    var attempts = 0;
    var confirmed = false;
    // The schedule holds offsets from the grant, not gaps between attempts.
    // Wait the remainder of each offset, so attempt five lands at 55s.
    var elapsed = Duration.zero;
    for (final offset in schedule) {
      final gap = offset > elapsed ? offset - elapsed : Duration.zero;
      await _delay(gap);
      elapsed += gap;
      attempts++;
      final outcome = await account.refresh(manual: true);
      switch (outcome) {
        case OneVpnRefreshed(:final session):
          if (session.isPremium) {
            confirmed = true;
          }
        case OneVpnKept():
          // No verdict: offline, rate limited, or an undecodable body.
          // The marker survives. The attempt is spent either way.
          break;
        case OneVpnSignedOut():
        case OneVpnNoSession():
          // No session left to confirm against.
          return OneVpnPremiumActivationResult(
            signedIn: true,
            alreadyPremium: false,
            markedPending: marked,
            confirmed: false,
            attempts: attempts,
          );
      }
      if (confirmed) break;
    }

    return OneVpnPremiumActivationResult(
      signedIn: true,
      alreadyPremium: false,
      markedPending: marked,
      confirmed: confirmed,
      attempts: attempts,
    );
  }
}
