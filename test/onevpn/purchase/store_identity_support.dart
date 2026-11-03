// A recording store identity SDK shared by the purchase suites.

import 'dart:async';

import 'package:onexray/onevpn/purchase/revenuecat_purchase_service.dart';

/// An identity SDK that records every call and can be sabotaged. It
/// starts anonymous. A log in names the customer. A log out makes it
/// anonymous again.
class RecordingIdentitySdk implements OneVpnStoreIdentitySdk {
  RecordingIdentitySdk([List<String>? calls]) : calls = calls ?? <String>[];

  /// One entry per call, in order. A caller can share it with other fakes.
  final List<String> calls;

  bool anonymous = true;

  /// The customer id the SDK reports.
  String appUserIdValue = r'$RCAnonymousID:device';

  bool throwOnAppUserId = false;
  bool throwOnLogIn = false;
  bool throwOnLogOut = false;

  /// When it answers true for an id, log in throws for that id.
  bool Function(String appUserId)? refuses;

  /// Awaited inside log in, so a test can hold one open.
  Completer<void>? holdLogIn;

  @override
  Future<String> appUserId() async {
    calls.add('appUserId');
    if (throwOnAppUserId) throw StateError('appUserId sabotaged');
    return appUserIdValue;
  }

  @override
  Future<bool> isAnonymous() async {
    calls.add('isAnonymous');
    return anonymous;
  }

  @override
  Future<void> logIn(String appUserId) async {
    calls.add('logIn:$appUserId');
    final hold = holdLogIn;
    if (hold != null) await hold.future;
    if (throwOnLogIn) throw StateError('logIn sabotaged');
    if (refuses?.call(appUserId) ?? false) {
      throw StateError('the store refuses $appUserId');
    }
    anonymous = false;
    appUserIdValue = appUserId;
  }

  @override
  Future<void> logOut() async {
    calls.add('logOut');
    if (throwOnLogOut) throw StateError('logOut sabotaged');
    anonymous = true;
    appUserIdValue = r'$RCAnonymousID:device';
  }
}
