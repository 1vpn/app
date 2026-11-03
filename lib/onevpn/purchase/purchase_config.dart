// The store's configuration, injected rather than hard-coded.
//
// One input: the store's public SDK key, supplied at build time for the
// platform being built.
//
//   flutter build apk -t lib/main_1vpn.dart \
//     --dart-define=ONEVPN_RC_SDK_KEY=...
//
// No offering or entitlement identifier is named. The paywall renders the
// store's current offering and takes its annual and monthly package types.
// Premium is a backend fact read from the account endpoint.
//
// The key is optional. A dev, CI, or desktop build ordinarily carries none.
// Such a build degrades rather than fails. Without a key, [isConfigured] is
// false. The live service then leaves the SDK untouched, and the paywall
// shows placeholder pricing.
//
// Billing is mobile-only. A desktop build resolves no key.

import 'package:flutter/foundation.dart';

/// The store configuration for one build and one platform.
class OneVpnPurchaseConfig {
  const OneVpnPurchaseConfig({this.apiKey = ''});

  /// The store's public SDK key. Empty when the build carries none.
  final String apiKey;

  /// Whether this build can talk to the store at all. Everything the live
  /// service does is gated on it.
  bool get isConfigured => apiKey.isNotEmpty;

  static const String _sdkKey = String.fromEnvironment('ONEVPN_RC_SDK_KEY');

  /// The configuration for [platform], defaulting to the running one.
  ///
  /// Only the two store platforms resolve a key. Desktop resolves none: the
  /// store SDK has no desktop billing.
  static OneVpnPurchaseConfig forPlatform([TargetPlatform? platform]) {
    final target = platform ?? defaultTargetPlatform;
    final mobile =
        target == TargetPlatform.android || target == TargetPlatform.iOS;
    return OneVpnPurchaseConfig(apiKey: mobile ? _sdkKey : '');
  }
}
