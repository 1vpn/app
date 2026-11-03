// The real, purchases_flutter-backed purchase service.
//
// This is the only file in the fork that imports purchases_flutter. Every
// other consumer speaks the fork types in purchase_service.dart.
//
// The public SDK key arrives through OneVpnPurchaseConfig, never
// hard-coded. The bridge configures the SDK at the first session boundary
// or the first paywall call. A signed-in launch, a sign-in and a sign-out
// are session boundaries. A launch that opens on the paywall configures the
// SDK through the plan-price warm-up. A signed-out launch with no paywall
// makes no store call. A build with no key never touches the store.
//
// A missing key, a misconfigured store, or an empty offering answers
// OneVpnOfferingsUnavailable. A network fault answers
// OneVpnOfferingsUnreachable. A purchase with no key fails as an outcome.
//
// The store identity follows the account session. A log in or log out
// records the wanted customer, then runs the configure. The configure stays
// anonymous. It starts applying the record and does not wait for it. A
// failed configure keeps the record for the next one. A purchase checks the
// identity again after every pending apply.
//
// Only Google Play failures carry a named reason. On every other store a
// failure is the unknown reason, which never finishes a sheet or resets.
//
// A purchase the store still holds as pending blocks every later purchase of
// its product. A purchase that meets one first finishes the purchase sheets
// an earlier purchase left behind. A finished sheet cancels that purchase,
// and the purchase runs once more. With no sheet left, a signed-in purchase
// resets the store customer once: a log out, then a log in as the same
// customer. The purchase then runs again. A debug build logs each reset and
// each failure by reason and store code.
//
// No offering or entitlement identifier is named.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:onexray/onevpn/app/platform_channel.dart';
import 'package:onexray/onevpn/purchase/purchase_config.dart';
import 'package:onexray/onevpn/purchase/purchase_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Composes the store bridge into the fork purchase surface.
///
/// The setEmail-before-purchase order lives here. The identity check runs
/// before both. An unfinished outcome first finishes the purchase sheets an
/// earlier purchase left behind, then runs the purchase once more from the
/// identity check. With no sheet left, it resets the store's pending
/// purchases once and runs again.
class OneVpnRevenueCatPurchaseService implements OneVpnPurchaseService {
  const OneVpnRevenueCatPurchaseService({OneVpnRevenueCatBridge? bridge})
    : _bridge = bridge ?? const OneVpnLivePurchasesBridge();

  final OneVpnRevenueCatBridge _bridge;

  @override
  Future<OneVpnOfferingsResult> loadOfferings() => _bridge.loadOfferings();

  @override
  Future<OneVpnPurchaseOutcome> purchase({
    required OneVpnPurchasePackage package,
    required String email,
  }) async {
    final outcome = await _purchaseOnce(package, email);
    if (outcome is! OneVpnPurchaseFailed ||
        outcome.reason != OneVpnPurchaseFailureReason.unfinished) {
      return outcome;
    }
    // A finished sheet cancels the earlier purchase, so the rerun reaches a
    // new sheet. Its own unfinished outcome then stands.
    if (await _bridge.finishPurchaseSheets()) {
      return _purchaseOnce(package, email);
    }
    // With no sheet left, a reset drops the pending purchase. With no
    // customer wanted, or after a failed reset, the outcome stands.
    if (!await _bridge.resetPurchases()) return outcome;
    return _purchaseOnce(package, email);
  }

  /// Runs the identity check, sets the join key, then purchases [package].
  Future<OneVpnPurchaseOutcome> _purchaseOnce(
    OneVpnPurchasePackage package,
    String email,
  ) async {
    // Must run first: a receipt on a stale store customer links to the
    // wrong account.
    if (!await _bridge.assertIdentity()) {
      return _failed('purchase failed');
    }
    // The join key first. The store flushes subscriber attributes with the
    // receipt. A later set misses the initial-purchase event.
    await _bridge.setEmail(email);
    return _bridge.purchasePackage(package.storeHandle);
  }

  @override
  Future<void> identify(String appUserId) async {
    try {
      await _bridge.logIn(appUserId);
    } catch (_) {
      // The store identity never fails the caller.
    }
  }

  @override
  Future<void> forget() async {
    try {
      await _bridge.logOut();
    } catch (_) {
      // The store identity never fails the caller.
    }
  }

  @override
  Future<bool> restorePurchaseSheet() => _bridge.restorePurchaseSheet();
}

/// Configures the store for [config] and reports whether it is configured.
/// Never throws.
typedef OneVpnStoreConfigure = Future<bool> Function(
  OneVpnPurchaseConfig config,
);

/// The live store bridge over the purchases_flutter statics.
class OneVpnLivePurchasesBridge implements OneVpnRevenueCatBridge {
  const OneVpnLivePurchasesBridge({
    this.config,
    this._configure = _OneVpnStoreConfiguration.ensure,
    this._identity,
  });

  /// The configuration to run against, or null to resolve it from the
  /// build's --dart-defines for the running platform.
  final OneVpnPurchaseConfig? config;

  /// Configures the store. The default configures it once per process.
  final OneVpnStoreConfigure _configure;

  /// The wanted store customer, or null for [OneVpnStoreIdentity.shared].
  /// The default configure marks the shared instance ready.
  final OneVpnStoreIdentity? _identity;

  OneVpnPurchaseConfig get _resolved =>
      config ?? OneVpnPurchaseConfig.forPlatform();

  OneVpnStoreIdentity get _storeIdentity =>
      _identity ?? OneVpnStoreIdentity.shared;

  @override
  Future<OneVpnOfferingsResult> loadOfferings() async {
    if (!await _configure(_resolved)) {
      return const OneVpnOfferingsUnavailable();
    }
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null) return const OneVpnOfferingsUnavailable();
      final mapped = OneVpnOfferings(
        yearly: _map(current.annual, OneVpnPurchaseTerm.yearly),
        monthly: _map(current.monthly, OneVpnPurchaseTerm.monthly),
      );
      return mapped.hasAny
          ? OneVpnOfferingsLoaded(mapped)
          : const OneVpnOfferingsUnavailable();
    } on PlatformException catch (error) {
      // A network fault is the only connectivity cause. A configuration or
      // store error reads as unavailable.
      final code = PurchasesErrorHelper.getErrorCode(error);
      if (code == PurchasesErrorCode.networkError) {
        return const OneVpnOfferingsUnreachable();
      }
      return const OneVpnOfferingsUnavailable();
    } catch (_) {
      return const OneVpnOfferingsUnavailable();
    }
  }

  @override
  Future<void> setEmail(String email) async {
    if (email.isEmpty) return;
    if (!await _configure(_resolved)) return;
    try {
      await Purchases.setEmail(email);
    } catch (_) {
      // Best effort: the attribute flush never blocks a purchase.
    }
  }

  @override
  Future<OneVpnPurchaseOutcome> purchasePackage(Object? storeHandle) async {
    if (!await _configure(_resolved)) {
      return _failed('the store is not configured');
    }
    if (storeHandle is! Package) {
      return _failed('no store package to purchase');
    }
    try {
      // The returned customer info is not inspected. Premium is a backend
      // fact, read from the account endpoint.
      await _OneVpnPurchaseCalls.track(
        () => Purchases.purchase(PurchaseParams.package(storeHandle)),
      );
      return const OneVpnPurchaseSucceeded();
    } on PlatformException catch (error) {
      // Must run first: the SDK helper throws on a code that is no store
      // error number, and no later clause catches that throw.
      if ((int.tryParse(error.code) ?? -1) < 0) {
        return _failed('purchase failed');
      }
      final code = PurchasesErrorHelper.getErrorCode(error);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return const OneVpnPurchaseCancelled();
      }
      return _failed(
        'purchase failed',
        reason: _reasonOf(code, error.details),
        code: error.code,
      );
    } catch (_) {
      return _failed('purchase failed');
    }
  }

  @override
  Future<void> logIn(String appUserId) async {
    // The record comes first, so the configure applies this request.
    final applying = _storeIdentity.identify(appUserId);
    await _configure(_resolved);
    await applying;
  }

  @override
  Future<void> logOut() async {
    // The record comes first, so the configure applies this request.
    final applying = _storeIdentity.forget();
    await _configure(_resolved);
    await applying;
  }

  @override
  Future<bool> assertIdentity() async {
    final config = _resolved;
    if (!await _configure(config)) {
      // With no key, the purchase reports the missing configuration. A
      // failed configure with a key fails closed: a later retry would
      // purchase before the identity applies.
      return !config.isConfigured;
    }
    return _storeIdentity.assertForPurchase();
  }

  @override
  Future<bool> resetPurchases() async {
    if (!await _configure(_resolved)) return false;
    return _storeIdentity.reset();
  }

  // Off Android the channel answers false with no call.
  @override
  Future<bool> restorePurchaseSheet() =>
      OneVpnPlatformChannel.restoreBillingTask();

  /// How long a finish waits for the cancel of the purchase it ended.
  static const _cancelWait = Duration(seconds: 3);

  // Off Android the channel answers false with no call.
  @override
  Future<bool> finishPurchaseSheets() async {
    if (!await OneVpnPlatformChannel.finishBillingTasks()) return false;
    // A purchase ahead of the cancel meets the pending purchase again.
    await _OneVpnPurchaseCalls.settled(_cancelWait);
    return true;
  }

  /// Whether the store is Google Play. Only Play failures carry a named
  /// reason: the messages name Google Play, and the cures for a pending
  /// purchase are Play behavior. Every other platform answers the unknown
  /// reason, so it shows the generic text and never finishes a sheet or
  /// resets.
  static bool get _play => defaultTargetPlatform == TargetPlatform.android;

  /// Play's debug text for a purchase whose account stamp differs from the
  /// stamp on the subscription the store account holds or held. The text is
  /// Play's, not a contract. A changed text maps to the unknown reason.
  static const _accountMismatch = "Account identifiers don't match";

  /// The failure reason for the store error [code]. [details] is the error
  /// map the SDK attaches. Its underlyingErrorMessage carries Play's debug
  /// text. Off Play, every code is the unknown reason.
  static OneVpnPurchaseFailureReason _reasonOf(
    PurchasesErrorCode code,
    Object? details,
  ) {
    if (!_play) return OneVpnPurchaseFailureReason.unknown;
    return switch (code) {
      PurchasesErrorCode.purchaseInvalidError
          when _underlyingMessage(details).contains(_accountMismatch) =>
        OneVpnPurchaseFailureReason.otherAccount,
      PurchasesErrorCode.receiptAlreadyInUseError =>
        OneVpnPurchaseFailureReason.otherAccount,
      PurchasesErrorCode.productAlreadyPurchasedError =>
        OneVpnPurchaseFailureReason.owned,
      PurchasesErrorCode.operationAlreadyInProgressError =>
        OneVpnPurchaseFailureReason.unfinished,
      PurchasesErrorCode.storeProblemError =>
        OneVpnPurchaseFailureReason.storeProblem,
      _ => OneVpnPurchaseFailureReason.unknown,
    };
  }

  /// The underlyingErrorMessage of the SDK error [details], or empty when
  /// it carries none.
  static String _underlyingMessage(Object? details) {
    if (details is! Map) return '';
    final message = details['underlyingErrorMessage'];
    return message is String ? message : '';
  }

  static OneVpnPurchasePackage? _map(
    Package? package,
    OneVpnPurchaseTerm term,
  ) {
    if (package == null) return null;
    return OneVpnPurchasePackage(
      identifier: package.identifier,
      term: term,
      priceString: package.storeProduct.priceString,
      price: package.storeProduct.price,
      currencyCode: package.storeProduct.currencyCode,
      storeHandle: package,
    );
  }
}

/// The store purchase calls open in this isolate.
///
/// A purchase call stays open until the store answers it. A call from an
/// earlier engine in the same process is not counted.
abstract final class _OneVpnPurchaseCalls {
  static int _open = 0;
  static Completer<void>? _settled;

  /// Runs [call] as an open purchase call.
  static Future<T> track<T>(Future<T> Function() call) async {
    _open++;
    try {
      return await call();
    } finally {
      _open--;
      if (_open == 0) {
        _settled?.complete();
        _settled = null;
      }
    }
  }

  /// Completes once no purchase call is open, or after [bound].
  static Future<void> settled(Duration bound) {
    if (_open == 0) return Future<void>.value();
    final settled = _settled ??= Completer<void>();
    return settled.future.timeout(bound, onTimeout: () {});
  }
}

/// Configures the store SDK once per process.
///
/// The SDK is a process-wide singleton. The memo is a Dart static, so a
/// new engine in a live process starts it empty and asks the SDK whether
/// it is configured. Only a successful configure is remembered. A failure
/// clears the memo, and the next call retries. An unconfigured build short-circuits before the SDK
/// is touched. A debug build sets the SDK log level to debug before the
/// configure.
abstract final class _OneVpnStoreConfiguration {
  static Future<bool>? _pending;

  static Future<bool> ensure(OneVpnPurchaseConfig config) async {
    if (!config.isConfigured) return false;
    final pending = _pending ??= _configure(config);
    final configured = await pending;
    if (!configured && identical(_pending, pending)) _pending = null;
    return configured;
  }

  static Future<bool> _configure(OneVpnPurchaseConfig config) async {
    try {
      if (!await Purchases.isConfigured) {
        if (kDebugMode) await _debugLogLevel();
        await Purchases.configure(PurchasesConfiguration(config.apiKey));
      }
    } catch (_) {
      return false;
    }
    // Detached: the configure never waits on a log-in round trip. The
    // check before a purchase chains after this apply.
    unawaited(OneVpnStoreIdentity.shared.markReady());
    return true;
  }

  /// Sets the SDK log level to debug. A failure keeps the default level and
  /// never fails the configure.
  static Future<void> _debugLogLevel() async {
    try {
      await Purchases.setLogLevel(LogLevel.debug);
    } catch (_) {
      // The configure runs at the default level.
    }
  }
}

/// The store SDK's identity calls.
abstract interface class OneVpnStoreIdentitySdk {
  Future<String> appUserId();
  Future<bool> isAnonymous();
  Future<void> logIn(String appUserId);
  Future<void> logOut();
}

/// The identity calls over the purchases_flutter statics.
class OneVpnLiveStoreIdentitySdk implements OneVpnStoreIdentitySdk {
  const OneVpnLiveStoreIdentitySdk();

  @override
  Future<String> appUserId() => Purchases.appUserID;

  @override
  Future<bool> isAnonymous() => Purchases.isAnonymous;

  @override
  Future<void> logIn(String appUserId) async {
    // The returned customer info is not inspected. Premium is a backend
    // fact, read from the account endpoint.
    await Purchases.logIn(appUserId);
  }

  @override
  Future<void> logOut() async {
    try {
      await Purchases.logOut();
    } on PlatformException catch (error) {
      // An anonymous customer has nothing to log out of.
      final code = PurchasesErrorHelper.getErrorCode(error);
      if (code == PurchasesErrorCode.logOutWithAnonymousUserError) return;
      rethrow;
    }
  }
}

/// The store customer the app wants, applied once the store is configured.
///
/// The SDK is a process-wide singleton. [shared] is a Dart static, so a
/// new engine in a live process starts it empty, and its first request
/// records the wanted customer again. Before [markReady], a request only
/// records the wanted customer. [markReady]
/// applies the latest recorded request. From then on, every request
/// applies at once. Requests apply one at a time, in order. No method
/// throws.
class OneVpnStoreIdentity {
  OneVpnStoreIdentity({this._sdk = const OneVpnLiveStoreIdentitySdk()});

  /// The instance the live bridge and the configure memo share.
  static final OneVpnStoreIdentity shared = OneVpnStoreIdentity();

  final OneVpnStoreIdentitySdk _sdk;

  bool _ready = false;

  /// Whether any request arrived. With none, [markReady] calls nothing.
  bool _requested = false;

  /// The wanted customer id. Null after a request names the anonymous
  /// customer.
  String? _appUserId;

  Future<void> _applying = Future<void>.value();

  /// The wanted customer id, or null when none is wanted.
  @visibleForTesting
  String? get appUserId => _appUserId;

  /// Wants the customer [appUserId].
  Future<void> identify(String appUserId) {
    _requested = true;
    _appUserId = appUserId;
    return _ready ? _enqueue(appUserId) : Future<void>.value();
  }

  /// Wants the anonymous customer.
  Future<void> forget() {
    _requested = true;
    _appUserId = null;
    return _ready ? _enqueue(null) : Future<void>.value();
  }

  /// Records that the store is configured and applies the wanted customer.
  Future<void> markReady() {
    if (_ready) return _applying;
    _ready = true;
    return _requested ? _enqueue(_appUserId) : Future<void>.value();
  }

  /// Makes the store customer match the wanted customer and reports
  /// whether it does. Must run after the configure.
  ///
  /// Chained after every earlier request, the configure's apply included.
  /// A purchase therefore never runs ahead of a pending log in or log out.
  /// With no id wanted, the wanted customer is the anonymous one. That
  /// holds also when no request arrived. Any SDK failure answers false.
  /// Never throws.
  Future<bool> assertForPurchase() {
    final matched = _applying.then((_) => _match(_appUserId));
    _applying = matched.then<void>((_) {});
    return matched;
  }

  /// Logs the store customer out, then back in as the wanted customer, and
  /// reports whether that held. Must run after the configure.
  ///
  /// The log out drops every purchase the store still waits on. Chained
  /// after every earlier request. A request recorded during the reset
  /// applies after it. Answers false with no customer wanted, on any SDK
  /// failure, and when the wanted customer changes before the reset ends.
  /// Never throws.
  Future<bool> reset() {
    final appUserId = _appUserId;
    if (appUserId == null) return Future<bool>.value(false);
    final applied = _applying.then((_) => _reset(appUserId));
    _applying = applied.then<void>((_) {});
    return applied;
  }

  /// Makes the store customer [appUserId], or the anonymous one when it
  /// is null, and reports whether that held.
  ///
  /// A customer that already matches costs one read and no network call.
  /// A failed store call leaves the store customer as it was and answers
  /// false.
  Future<bool> _match(String? appUserId) async {
    try {
      if (appUserId != null) {
        if (await _sdk.appUserId() != appUserId) await _sdk.logIn(appUserId);
      } else if (!await _sdk.isAnonymous()) {
        // The SDK throws on an anonymous log out.
        await _sdk.logOut();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Logs the store customer out, then in as [appUserId]. Answers whether
  /// both calls succeeded with [appUserId] still wanted.
  Future<bool> _reset(String appUserId) async {
    if (_appUserId != appUserId) return false;
    _log('reset');
    try {
      await _sdk.logOut();
      await _sdk.logIn(appUserId);
    } catch (_) {
      return false;
    }
    return _appUserId == appUserId;
  }

  /// Applies [appUserId] after every earlier request. Null applies the
  /// anonymous customer.
  Future<void> _enqueue(String? appUserId) =>
      _applying = _applying.then((_) => _match(appUserId).then<void>((_) {}));
}

/// A failed outcome with [reason]. A debug build logs the reason, and the
/// store's error [code] when the store gave one.
OneVpnPurchaseFailed _failed(
  String detail, {
  OneVpnPurchaseFailureReason reason = OneVpnPurchaseFailureReason.unknown,
  String? code,
}) {
  _log('failed reason=${reason.name}${code == null ? '' : ' code=$code'}');
  return OneVpnPurchaseFailed(detail, reason: reason);
}

/// Logs [line] in a debug build. A line names a reason or a store code,
/// never a customer, an address or a product.
void _log(String line) {
  if (kDebugMode) debugPrint('OneVpnPurchase $line');
}
