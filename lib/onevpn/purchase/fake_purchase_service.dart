// A clean-room fake purchase service.
//
// It ships in the app as well as the tests. The ONEVPN_FAKE_PURCHASES
// --dart-define selects it for dev and CI. The paywall and the purchase
// flow then build and run with no live RevenueCat key. It doubles as the
// test double for the paywall's widget tests. It never touches
// purchases_flutter.
//
// Canned prices are dev stand-ins, not real pricing. The live numbers come
// from the store through the real service.

import 'package:onexray/onevpn/purchase/purchase_service.dart';

/// Canned offering used when none is supplied.
const OneVpnOfferings _kFakeOfferings = OneVpnOfferings(
  yearly: OneVpnPurchasePackage(
    identifier: 'onevpn_yearly_dev',
    term: OneVpnPurchaseTerm.yearly,
    priceString: r'$39.99',
    price: 39.99,
    currencyCode: 'USD',
  ),
  monthly: OneVpnPurchasePackage(
    identifier: 'onevpn_monthly_dev',
    term: OneVpnPurchaseTerm.monthly,
    priceString: r'$6.99',
    price: 6.99,
    currencyCode: 'USD',
  ),
);

/// A scripted, offline purchase service.
///
/// Every field is mutable. A test can change the scripted outcome between
/// calls, for example a failed load that succeeds on retry. Every call is
/// recorded, so a test can assert ordering and wiring.
class OneVpnFakePurchaseService implements OneVpnPurchaseService {
  OneVpnFakePurchaseService({
    OneVpnOfferings? offerings = _kFakeOfferings,
    this.offeringsAvailable = true,
    this.loadFailure = const OneVpnOfferingsUnavailable(),
    this.outcome = const OneVpnPurchaseSucceeded(),
  }) : offerings = offerings ?? _kFakeOfferings;

  /// The offering [loadOfferings] returns while [offeringsAvailable].
  OneVpnOfferings offerings;

  /// When false, [loadOfferings] returns [loadFailure].
  bool offeringsAvailable;

  /// The failure [loadOfferings] returns while not [offeringsAvailable]. A
  /// test scripts the unreachable case by setting it.
  OneVpnOfferingsResult loadFailure;

  /// The outcome [purchase] returns.
  OneVpnPurchaseOutcome outcome;

  /// One entry per call, in order, for assertions.
  final List<String> calls = <String>[];

  String? lastEmail;
  OneVpnPurchasePackage? lastPackage;

  /// The id the last [identify] call named, or null before any.
  String? lastAppUserId;

  /// The answer [restorePurchaseSheet] gives.
  bool sheetRestored = false;

  @override
  Future<OneVpnOfferingsResult> loadOfferings() async {
    calls.add('loadOfferings');
    return offeringsAvailable ? OneVpnOfferingsLoaded(offerings) : loadFailure;
  }

  @override
  Future<OneVpnPurchaseOutcome> purchase({
    required OneVpnPurchasePackage package,
    required String email,
  }) async {
    // Records the email as part of the purchase call. The fork API takes
    // the join key as a purchase argument. An email is present by
    // construction before the purchase resolves.
    calls.add('purchase');
    lastEmail = email;
    lastPackage = package;
    return outcome;
  }

  @override
  Future<void> identify(String appUserId) async {
    calls.add('identify:$appUserId');
    lastAppUserId = appUserId;
  }

  @override
  Future<void> forget() async {
    calls.add('forget');
  }

  @override
  Future<bool> restorePurchaseSheet() async {
    calls.add('restorePurchaseSheet');
    return sheetRestored;
  }
}
