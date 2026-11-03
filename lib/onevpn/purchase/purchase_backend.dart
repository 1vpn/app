// Selects the purchase service the app runs against.
//
// ONEVPN_FAKE_PURCHASES selects the clean-room fake. Dev and CI builds then
// run the paywall with no store key:
//
//   flutter run --dart-define=ONEVPN_FAKE_PURCHASES=true
//
// Unset, the build takes the real purchases_flutter-backed service.
//
// This is the one file that names both implementations. The paywall takes
// the selected service as an argument.

import 'package:onexray/onevpn/purchase/fake_purchase_service.dart';
import 'package:onexray/onevpn/purchase/purchase_service.dart';
import 'package:onexray/onevpn/purchase/revenuecat_purchase_service.dart';

/// True when the build asked for the fake purchase service.
const bool kOneVpnUseFakePurchases = bool.fromEnvironment(
  'ONEVPN_FAKE_PURCHASES',
);

final OneVpnPurchaseService _backend = kOneVpnUseFakePurchases
    ? OneVpnFakePurchaseService()
    : const OneVpnRevenueCatPurchaseService();

/// The purchase service for this build. Every call answers the same instance,
/// so the launch warm-up and the paywall share one offerings cache.
OneVpnPurchaseService oneVpnPurchaseBackend() => _backend;
