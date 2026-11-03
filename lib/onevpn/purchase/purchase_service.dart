// The fork-owned purchase seam.
//
// The paywall, the fake, and every test speak only these fork types.
// Exactly one file imports purchases_flutter: the live bridge in
// revenuecat_purchase_service.dart. The store SDK stays off the code's
// critical path. The ONEVPN_FAKE_PURCHASES --dart-define swaps in the fake
// through purchase_backend.dart. The paywall then builds, runs and tests
// end to end with no live RevenueCat key.
//
// Nothing here throws to report an outcome. loadOfferings returns a sealed
// result and leaves a missing plan null. purchase returns a sealed result
// for cancel and failure. A paywall degrades rather than crashes on a store
// that is offline, unconfigured, or says no.

/// Which billing term a package renews on. [other] covers any term the
/// paywall does not lay out its own card for.
enum OneVpnPurchaseTerm { yearly, monthly, other }

/// One purchasable plan, as the paywall needs it.
///
/// [priceString] is the store's own localized price text. [price] is the
/// same amount as a number. [currencyCode] is its ISO 4217 code. Each is
/// null when the store gives none. The paywall derives its per-month sale
/// figures from the two.
///
/// [storeHandle] is an opaque carrier for the store package the live
/// bridge purchases. It is null for the fake and for any package built
/// fork-side. Its [Object] type keeps purchases_flutter out of this file.
class OneVpnPurchasePackage {
  const OneVpnPurchasePackage({
    required this.identifier,
    required this.term,
    required this.priceString,
    this.price,
    this.currencyCode,
    this.storeHandle,
  });

  final String identifier;
  final OneVpnPurchaseTerm term;
  final String priceString;
  final double? price;
  final String? currencyCode;
  final Object? storeHandle;
}

/// The current offering, split into the two plans the paywall renders. A
/// plan the store does not offer is null. The paywall keeps its card and
/// shows placeholder pricing.
class OneVpnOfferings {
  const OneVpnOfferings({this.yearly, this.monthly});

  final OneVpnPurchasePackage? yearly;
  final OneVpnPurchasePackage? monthly;

  /// Whether at least one plan carries live pricing.
  bool get hasAny => yearly != null || monthly != null;
}

/// How loading the current offering ended.
///
/// A failure splits two ways, one per cause the paywall names. An
/// unconfigured store or an empty offering is [OneVpnOfferingsUnavailable].
/// A store the device could not reach is [OneVpnOfferingsUnreachable].
sealed class OneVpnOfferingsResult {
  const OneVpnOfferingsResult();
}

/// The offering loaded with at least one live plan.
final class OneVpnOfferingsLoaded extends OneVpnOfferingsResult {
  const OneVpnOfferingsLoaded(this.offerings);

  final OneVpnOfferings offerings;
}

/// The store answered with no plan to sell. The SDK is unconfigured, or the
/// current offering is empty. It is never a connectivity fault.
final class OneVpnOfferingsUnavailable extends OneVpnOfferingsResult {
  const OneVpnOfferingsUnavailable();
}

/// The device could not reach the store. This is the connectivity fault.
final class OneVpnOfferingsUnreachable extends OneVpnOfferingsResult {
  const OneVpnOfferingsUnreachable();
}

/// How a purchase attempt ended.
sealed class OneVpnPurchaseOutcome {
  const OneVpnPurchaseOutcome();
}

/// The store confirmed the purchase. The sign-up funnel takes it from here.
/// In isolation, the paywall dismisses.
final class OneVpnPurchaseSucceeded extends OneVpnPurchaseOutcome {
  const OneVpnPurchaseSucceeded();
}

/// The user backed out of the store sheet. The paywall stays open and
/// shows no error.
final class OneVpnPurchaseCancelled extends OneVpnPurchaseOutcome {
  const OneVpnPurchaseCancelled();
}

/// Why a purchase failed. The paywall names each cause other than
/// [unknown] and [storeProblem].
enum OneVpnPurchaseFailureReason {
  /// A cause the paywall does not name. It shows the generic retry message.
  unknown,

  /// The store account holds, or recently held, the subscription for
  /// another account.
  otherAccount,

  /// The store account already owns the subscription.
  owned,

  /// An earlier purchase of the product is still pending in the store.
  unfinished,

  /// The store reported a fault of its own.
  storeProblem,
}

/// The purchase failed for a reason other than cancellation. The paywall
/// surfaces this to the user with a retry.
final class OneVpnPurchaseFailed extends OneVpnPurchaseOutcome {
  const OneVpnPurchaseFailed(
    this.detail, {
    this.reason = OneVpnPurchaseFailureReason.unknown,
  });

  /// A short, safe reason. Never a raw exception string.
  final String detail;

  /// The cause the paywall names.
  final OneVpnPurchaseFailureReason reason;
}

/// The purchase surface the paywall and the account service drive.
abstract interface class OneVpnPurchaseService {
  /// Loads the current offering. Never throws: a failure is a result. The
  /// paywall stays usable and names the cause.
  Future<OneVpnOfferingsResult> loadOfferings();

  /// Sets [email] as the join key, then purchases [package].
  ///
  /// The email lands before the purchase. The store's initial-purchase
  /// event then carries the address the backend webhook links on. Never
  /// throws: cancellation and failure come back as outcomes.
  Future<OneVpnPurchaseOutcome> purchase({
    required OneVpnPurchasePackage package,
    required String email,
  });

  /// Names the store customer [appUserId]. Never throws.
  ///
  /// Later purchases belong to that customer. The call configures the store
  /// if needed, then applies the id. A failed configure keeps the id for the
  /// next one. A build with no store key only records it. An id the store
  /// refuses fails the identity check before a purchase.
  Future<void> identify(String appUserId);

  /// Returns the store customer to an anonymous one. Never throws.
  ///
  /// An anonymous customer stays as it is. The call configures the store if
  /// needed, then applies the change. A failed configure keeps the change
  /// for the next one. A build with no store key only records it.
  Future<void> forget();

  /// Brings back the store's purchase sheet that a purchase left behind,
  /// and answers whether it came back. Never throws.
  ///
  /// Google Play runs the sheet in a task of its own, which Home leaves
  /// behind. Every other store answers false.
  Future<bool> restorePurchaseSheet();
}

/// The low-level store operations the real service composes.
///
/// A recording double tests the setEmail-before-purchase order without
/// the store SDK. That order makes a purchase linkable. The live
/// implementation, [OneVpnLivePurchasesBridge], is the only code that
/// touches purchases_flutter.
abstract interface class OneVpnRevenueCatBridge {
  Future<OneVpnOfferingsResult> loadOfferings();

  /// Sets the email attribute on a best-effort basis. It never throws: a
  /// store that cannot record the attribute never blocks the purchase.
  Future<void> setEmail(String email);

  /// Purchases the package carried by [storeHandle]. Never throws. It
  /// translates the store's cancel and error signals into outcomes.
  Future<OneVpnPurchaseOutcome> purchasePackage(Object? storeHandle);

  /// Logs the store customer in as [appUserId]. Never throws.
  ///
  /// Records the id, then configures the store. A configure that answers
  /// false leaves the id recorded for a later configure.
  Future<void> logIn(String appUserId);

  /// Logs an identified store customer out. Never throws. An anonymous
  /// customer stays as it is.
  ///
  /// Records the change, then configures the store. A configure that
  /// answers false leaves the change recorded for a later configure.
  Future<void> logOut();

  /// Makes the store customer match the wanted identity before a purchase.
  ///
  /// Returns false when the store customer could not be matched. The
  /// purchase must not run then: its receipt would land on another
  /// account's customer. A failed configure answers false too. A build with
  /// no store key answers true. The purchase then reports the missing
  /// configuration. Never throws.
  Future<bool> assertIdentity();

  /// Empties the store's pending purchases for the wanted customer. Never
  /// throws.
  ///
  /// Logs the store customer out, then back in as the wanted customer. The
  /// log out drops every purchase the store still waits on. Answers false
  /// with no customer wanted, on a failed configure, on an SDK failure, and
  /// when the wanted customer changes before the reset ends.
  Future<bool> resetPurchases();

  /// Brings back the store's purchase sheet that a purchase left behind,
  /// and answers whether it came back. Google Play only: every other store
  /// answers false. Never throws.
  Future<bool> restorePurchaseSheet();

  /// Finishes the store's purchase sheets that a purchase left behind, and
  /// answers whether one finished. Google Play only: every other store
  /// answers false. Never throws.
  ///
  /// A finished sheet cancels its purchase. The answer waits for that
  /// cancel, up to a bound, so a purchase after it meets no pending one.
  Future<bool> finishPurchaseSheets();
}
