// A purchase that waits for an account: the store charged on this install,
// and no account has claimed the purchase yet.
//
// The record holds the purchase address and the store's id for the
// customer that made the purchase. A purchase that completes with no
// account on its address writes it. A launch that finds the record with the
// account signed out opens on the purchased screen, which names that
// address. A session on that address clears the record. A session on
// another address leaves it for the next signed-out launch. A store read
// that finds no active subscription for the customer that made the
// purchase clears it too. A dismissal hides the screen for the rest of the
// run and keeps the record.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/paywall/paywall_trigger.dart';
import 'package:onexray/onevpn/paywall/pending_purchase_record.dart';
import 'package:onexray/onevpn/purchase/purchase_service.dart';

/// The record of a purchase that waits for an account, with the launch
/// check, the dismissal and the two clears.
///
/// No method throws.
class OneVpnPendingPurchase extends OneVpnPendingPurchaseRecord {
  OneVpnPendingPurchase({super.preferences});

  static bool _dismissed = false;

  /// Whether the purchased screen was dismissed in this run. The value is
  /// process-wide and never stored.
  static bool get dismissedThisLaunch => _dismissed;

  /// Hides the launch's purchased screen for the rest of this run. The
  /// record stays, so the next launch shows the screen again.
  static void dismissForThisLaunch() => _dismissed = true;

  /// Forgets a dismissal, as a new run does.
  @visibleForTesting
  static void resetLaunch() => _dismissed = false;

  /// The address the launch's purchased screen names, or null when the
  /// launch opens on the shell.
  ///
  /// Waits for [restored] up to [restoreDeadline]. A restore that has not
  /// settled by then answers null. Only a signed-out account with a record
  /// answers an address. A dismissal in this run answers null.
  Future<String?> dueAtLaunch({
    required ValueListenable<OneVpnAccountState> account,
    required Future<void> restored,
    Duration restoreDeadline = kOneVpnLaunchPaywallRestoreDeadline,
  }) async {
    if (_dismissed) return null;
    try {
      await restored.timeout(restoreDeadline);
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
    return heldWhileSignedOut(account.value);
  }

  /// Clears the record whenever [account] is signed in on the purchase
  /// address, now and on every later change. That session has taken the
  /// purchase over. A session on another address leaves the record.
  void follow(ValueListenable<OneVpnAccountState> account) {
    void check() {
      final state = account.value;
      if (state is OneVpnAccountSignedIn) {
        unawaited(clearFor(state.session.email));
      }
    }

    account.addListener(check);
    check();
  }

  /// Clears the record when it names [email]. The session email is taken
  /// as the API returns it. An empty email matches no record.
  Future<void> clearFor(String email) async {
    final recorded = await read();
    if (recorded == null) return;
    if (!oneVpnSameAddress(recorded, email)) return;
    await clear();
  }

  /// Asks [service] whether the store customer that made the purchase
  /// holds a subscription. A clear no clears the record. A store that
  /// cannot tell keeps it. A record with no customer id cannot tell, and
  /// asks the store nothing.
  Future<void> checkStore(OneVpnPurchaseService service) async {
    final customerId = await readCustomer();
    if (customerId == null) return;
    bool? holds;
    try {
      holds = await service.holdsSubscription(customerId);
    } catch (_) {
      holds = null;
    }
    if (holds == false) await clear();
  }
}
