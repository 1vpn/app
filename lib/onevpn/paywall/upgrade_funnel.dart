// The buy-first funnel: what happens between the store confirming a
// purchase and the buyer seeing premium.
//
// A signed-out user buys first and makes an account second.
//
// Two orderings are load-bearing. The funnel awaits the sign-up step to
// completion. The step completes only once its session is adopted. The
// grant records nothing against a session that has not flipped. The grant
// then runs detached: the confirmation poll spans the better part of a
// minute.
//
// The email is captured once, on the paywall, and reused verbatim at
// sign-up. The backend links the purchase to the account by that address.
// The sign-up field is therefore locked, not just prefilled.
//
// An abandoned sign-up keeps the purchase and grants nothing. The account
// state stays signed out. The paywall reads that as its
// purchased-but-unlinked state.

import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/account/premium_activation.dart';
import 'package:onexray/onevpn/account/sign_in_page.dart';
import 'package:onexray/onevpn/shell/edge_route.dart';
import 'package:onexray/onevpn/shell/routes.dart';

/// Runs the sign-up step for [email] and reports whether the user
/// completed it. Must not return true until the resulting session has been
/// adopted.
typedef OneVpnSignUpStep = Future<bool> Function(
  BuildContext context,
  String email,
);

/// Starts the optimistic grant and its confirmation poll.
typedef OneVpnActivatePremium =
    Future<OneVpnPremiumActivationResult> Function();

/// Carries a confirmed purchase through to premium.
///
/// One instance per paywall: it remembers the activation it started.
class OneVpnUpgradeFunnel {
  OneVpnUpgradeFunnel({
    OneVpnPremiumAccount? account,
    OneVpnSignUpStep? signUp,
    OneVpnActivatePremium? activate,
  }) : account = account ?? const OneVpnServicePremiumAccount(),
       _signUp = signUp ?? pushSignUp,
       _activate = activate ?? _activateShared;

  final OneVpnPremiumAccount account;
  final OneVpnSignUpStep _signUp;
  final OneVpnActivatePremium _activate;

  Future<OneVpnPremiumActivationResult>? _activation;

  /// The grant and poll this funnel started, or null before that step.
  /// Detached from the UI. Exposed so a test can await it.
  Future<OneVpnPremiumActivationResult>? get activation => _activation;

  /// The paywall's post-purchase handoff. [email] is the address the
  /// purchase was made against.
  Future<void> completePurchase(BuildContext context, String email) async {
    if (account.state.value is! OneVpnAccountSignedIn) {
      final signedUp = await _signUp(context, email);
      // An abandoned sign-up leaves no account to grant against. The state
      // stays signed out and the paywall surfaces that.
      if (!signedUp) return;
    }

    // The session has flipped by here. The activator re-reads the state
    // and enforces both rules itself.
    final started = _activate();
    _activation = started;
    // Detached, and its errors with it. A throwing account seam must not
    // surface as an unhandled async error.
    unawaited(started.then<void>((_) {}, onError: (Object _, StackTrace _) {}));

    if (context.mounted && context.canPop()) context.pop();
  }

  /// Pushes the auth screen in sign-up mode with the purchase email
  /// prefilled and locked. It reports whether the screen came back
  /// authenticated. Stacked, the screen comes up from the bottom edge, like
  /// the paywall.
  static Future<bool> pushSignUp(BuildContext context, String email) async {
    final completed = await context.push<OneVpnSignInMode>(
      kOneVpnSignInRoute,
      extra: OneVpnSignInArgs(
        mode: OneVpnSignInMode.signUp,
        email: email,
        lockEmail: true,
        edge: OneVpnStackedEdge.bottom,
      ),
    );
    return completed != null;
  }

  static Future<OneVpnPremiumActivationResult> _activateShared() =>
      OneVpnPremiumActivator().activate();
}
