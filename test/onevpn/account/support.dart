// Fakes shared by the account service and resume beacon suites.

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:onexray/onevpn/account/credential_store.dart';
import 'package:onexray/onevpn/account/outcomes.dart';
import 'package:onexray/onevpn/account/session.dart';
import 'package:onexray/onevpn/data/account_api.dart';
import 'package:onexray/onevpn/model/user_data.dart';
import 'package:onexray/onevpn/net/api_transport.dart';
import 'package:onexray/onevpn/purchase/purchase_service.dart';

const testCredentials = OneVpnCredentials(
  uuid: 'uuid-1',
  publicKey: 'pbk-1',
  shortId: 'sid-1',
);

const testLocations = <OneVpnApiLocation>[
  OneVpnApiLocation(
    country: 'Someland',
    countryCode: 'SL',
    servers: <OneVpnApiServer>[OneVpnApiServer(host: 'a.example.invalid')],
  ),
];

OneVpnSession testSession({
  String token = 'token-old',
  bool isPremium = true,
  DateTime? pendingSince,
  List<OneVpnApiLocation> locations = testLocations,
}) => OneVpnSession(
  sessionAuthToken: token,
  username: 'someone',
  email: 'someone@example.invalid',
  isPremium: isPremium,
  credentials: testCredentials,
  locations: locations,
  premiumPendingSince: pendingSince,
);

OneVpnUserData testUserData({
  bool isPremium = true,
  List<OneVpnApiLocation> locations = testLocations,
  OneVpnCredentials credentials = testCredentials,
}) => OneVpnUserData(
  username: 'someone',
  email: 'someone@example.invalid',
  isPremium: isPremium,
  // The client decodes get_user_data_api without requiring a token, so the
  // payload routinely carries none. The rotated token is the one that
  // lands.
  sessionAuthToken: '',
  credentials: credentials,
  locations: locations,
);

/// An endpoint client that answers from a script and dials nothing.
///
/// Every call is recorded with the token it was given, so ordering and
/// the zero-network paths are both assertable.
final class ScriptedApi extends OneVpnAccountApi {
  ScriptedApi({this.userData, this.rotated})
    : super(
        transport: OneVpnApiTransport(
          memory: OneVpnEphemeralDomainMemory(),
          dio: Dio(),
        ),
      );

  OneVpnApiResult<OneVpnUserData>? userData;
  OneVpnApiResult<String>? rotated;

  /// Awaited inside the user-data call, so a test can hold a refresh open.
  Future<void> Function()? beforeFetch;

  final List<String> calls = <String>[];

  @override
  Future<OneVpnApiResult<OneVpnUserData>> fetchUserData({
    required String authToken,
  }) async {
    calls.add('fetchUserData:$authToken');
    final hold = beforeFetch;
    if (hold != null) await hold();
    final scripted = userData;
    if (scripted == null) throw StateError('fetchUserData was not scripted');
    return scripted;
  }

  @override
  Future<OneVpnApiResult<String>> refreshToken({
    required String authToken,
  }) async {
    calls.add('refreshToken:$authToken');
    final scripted = rotated;
    if (scripted == null) throw StateError('refreshToken was not scripted');
    return scripted;
  }
}

/// A store that records every mutation into a shared log and can be
/// sabotaged one method at a time.
final class RecordingStore implements OneVpnCredentialStore {
  RecordingStore(this.log);

  final List<String> log;
  final OneVpnEphemeralCredentialStore inner = OneVpnEphemeralCredentialStore();

  bool throwOnRead = false;
  bool throwOnWrite = false;
  bool throwOnClear = false;
  bool throwOnClearStamp = false;
  bool throwOnWriteStamp = false;

  /// Awaited inside [write] after the document lands, so a test can hold
  /// a commit open on the session write.
  Future<void> Function()? afterWrite;

  /// Awaited inside [writeLastRefreshAt] after the stamp lands, so a test
  /// can hold a commit open on the stamp write.
  Future<void> Function()? afterWriteStamp;

  /// Awaited inside [readLastRefreshAt] after the stamp is read, so a test
  /// can hold a background refresh open on its cooldown check.
  Future<void> Function()? afterReadStamp;

  @override
  Future<OneVpnStoredSession> read() async {
    log.add('read');
    if (throwOnRead) throw StateError('read sabotaged');
    return inner.read();
  }

  @override
  Future<void> write(OneVpnSession session) async {
    log.add('write');
    if (throwOnWrite) throw StateError('write sabotaged');
    await inner.write(session);
    final hold = afterWrite;
    if (hold != null) await hold();
  }

  @override
  Future<void> clear() async {
    log.add('clear');
    if (throwOnClear) throw StateError('clear sabotaged');
    return inner.clear();
  }

  @override
  Future<DateTime?> readLastRefreshAt() async {
    log.add('readLastRefreshAt');
    final stamp = await inner.readLastRefreshAt();
    final hold = afterReadStamp;
    if (hold != null) await hold();
    return stamp;
  }

  @override
  Future<void> writeLastRefreshAt(DateTime at) async {
    log.add('writeLastRefreshAt');
    if (throwOnWriteStamp) throw StateError('stamp write sabotaged');
    await inner.writeLastRefreshAt(at);
    final hold = afterWriteStamp;
    if (hold != null) await hold();
  }

  @override
  Future<void> clearLastRefreshAt() async {
    log.add('clearLastRefreshAt');
    if (throwOnClearStamp) throw StateError('stamp clear sabotaged');
    return inner.clearLastRefreshAt();
  }
}

/// A clock a test moves by hand.
final class FakeClock {
  FakeClock(this.now);

  DateTime now;

  DateTime call() => now;

  void advance(Duration by) => now = now.add(by);
}

/// The three sign-out seams, recording into a shared log.
final class SignOutSeams {
  SignOutSeams(this.log);

  final List<String> log;

  bool tunnelStops = true;
  bool throwOnTunnel = false;
  bool throwOnSweep = false;
  bool throwOnStampClear = false;
  OneVpnSweepResult sweep = OneVpnSweepResult.unwired;

  Future<bool> stopTunnel() async {
    log.add('stopTunnel');
    if (throwOnTunnel) throw StateError('tunnel stop sabotaged');
    return tunnelStops;
  }

  Future<OneVpnSweepResult> sweepProvisioned() async {
    log.add('sweepProvisioned');
    if (throwOnSweep) throw StateError('sweep sabotaged');
    return sweep;
  }

  Future<void> clearReachabilityStamp() async {
    log.add('clearReachabilityStamp');
    if (throwOnStampClear) throw StateError('stamp clear sabotaged');
  }
}

/// The purchase service seen from the account service: the identity calls
/// only. Each call is recorded and can be sabotaged.
final class IdentitySeam implements OneVpnPurchaseService {
  final List<String> calls = <String>[];

  /// When true, the identity calls return a failed future.
  bool throwAsync = false;

  /// When true, the identity calls throw before they return a future.
  bool throwSync = false;

  /// Runs inside each identity call, so a test can read the service state
  /// at the moment of the call.
  void Function(String call)? onCall;

  Future<void> _record(String call) {
    calls.add(call);
    onCall?.call(call);
    if (throwSync) throw StateError('$call sabotaged');
    if (throwAsync) return Future<void>.error(StateError('$call sabotaged'));
    return Future<void>.value();
  }

  @override
  Future<void> identify(String appUserId) => _record('identify:$appUserId');

  @override
  Future<void> forget() => _record('forget');

  @override
  Future<OneVpnOfferingsResult> loadOfferings() => throw UnimplementedError();

  @override
  Future<OneVpnPurchaseOutcome> purchase({
    required OneVpnPurchasePackage package,
    required String email,
  }) => throw UnimplementedError();

  @override
  Future<bool> restorePurchaseSheet() => throw UnimplementedError();
}
