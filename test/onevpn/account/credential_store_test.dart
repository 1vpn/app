// The store's three read answers, and the guarantee that reading never
// destroys what it could not read.
//
// The suite runs against the in-memory preferences platform. It exercises
// the real prefs implementation without a device.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/account/credential_store.dart';
import 'package:onexray/onevpn/account/session.dart';
import 'package:onexray/onevpn/model/user_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Preferences whose string reads throw, standing in for platform IO that
/// will not answer.
final class _UnavailablePreferences extends InMemorySharedPreferencesAsync {
  _UnavailablePreferences() : super.empty();

  @override
  Future<String?> getString(String key, SharedPreferencesOptions options) =>
      Future<String?>.error(StateError('prefs unavailable'));
}

const _credentials = OneVpnCredentials(
  uuid: 'uuid-1',
  publicKey: 'pbk-1',
  shortId: 'sid-1',
);

OneVpnSession _session({DateTime? pendingSince}) => OneVpnSession(
  sessionAuthToken: 'token-abc',
  username: 'someone',
  email: 'someone@example.invalid',
  isPremium: true,
  credentials: _credentials,
  locations: const <OneVpnApiLocation>[
    OneVpnApiLocation(
      country: 'Someland',
      countryCode: 'SL',
      servers: <OneVpnApiServer>[OneVpnApiServer(host: 'a.example.invalid')],
    ),
  ],
  premiumPendingSince: pendingSince,
);

void main() {
  late SharedPreferencesAsync prefs;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    prefs = SharedPreferencesAsync();
  });

  group('the shipped prefs store', () {
    const store = OneVpnPrefsCredentialStore();

    test('the keys are fork namespaced', () {
      expect(OneVpnAccountKeys.session, 'onevpn.account.session');
      expect(OneVpnAccountKeys.lastRefreshAt, 'onevpn.account.lastRefreshAt');
      // Upstream allocates from app2. Sharing that namespace would put
      // two owners on one key.
      expect(OneVpnAccountKeys.session, isNot(startsWith('app2.')));
      expect(OneVpnAccountKeys.lastRefreshAt, isNot(startsWith('app2.')));
    });

    test('no stored document reads as absent', () async {
      expect(await store.read(), isA<OneVpnSessionAbsent>());
    });

    test('a written session round trips through the store', () async {
      final at = DateTime.fromMillisecondsSinceEpoch(
        1789000000123,
        isUtc: true,
      );
      await store.write(_session(pendingSince: at));

      final read = await store.read();

      expect(read, isA<OneVpnSessionRestored>());
      final session = (read as OneVpnSessionRestored).session;
      expect(session.sessionAuthToken, 'token-abc');
      expect(session.credentials.uuid, 'uuid-1');
      expect(
        session.locations.single.servers!.single.host,
        'a.example.invalid',
      );
      expect(session.premiumPendingSince, at);
      expect(session.premiumPendingSince!.isUtc, isTrue);
    });

    test('a document that is not JSON reads as unreadable', () async {
      await prefs.setString(OneVpnAccountKeys.session, 'not json at all');

      final read = await store.read();

      expect(read, isA<OneVpnSessionUnreadable>());
      expect((read as OneVpnSessionUnreadable).detail, contains('not JSON'));
    });

    test('a JSON value that is not an object reads as unreadable', () async {
      await prefs.setString(OneVpnAccountKeys.session, '[1, 2, 3]');

      expect(await store.read(), isA<OneVpnSessionUnreadable>());
    });

    test('a JSON object that is not a session reads as unreadable', () async {
      await prefs.setString(
        OneVpnAccountKeys.session,
        jsonEncode(<String, dynamic>{'username': 'someone'}),
      );

      final read = await store.read();

      expect(read, isA<OneVpnSessionUnreadable>());
      expect(
        (read as OneVpnSessionUnreadable).detail,
        contains('token or an entitlement'),
      );
    });

    test('an empty document reads as unreadable, not as absent', () async {
      await prefs.setString(OneVpnAccountKeys.session, '');

      expect(await store.read(), isA<OneVpnSessionUnreadable>());
    });

    // An absent answer would report a signed-in user as signed out and hand
    // them the free catalogue. Unknown is not absent.
    test('platform IO that will not answer reads as unreadable', () async {
      SharedPreferencesAsyncPlatform.instance = _UnavailablePreferences();

      final read = await store.read();

      expect(read, isA<OneVpnSessionUnreadable>());
      expect(
        (read as OneVpnSessionUnreadable).detail,
        contains('store unavailable'),
      );
    });

    // Only an explicit user action removes a document: a new sign-in
    // overwriting it, or a sign-out clearing it. Every unreadable branch
    // leaves it where it is.
    test('reading an unreadable document leaves it on disk', () async {
      for (final document in <String>[
        'not json at all',
        '[1, 2, 3]',
        '{"username": "someone"}',
        '{"sessionAuthToken": "token-abc"}',
        '',
      ]) {
        await prefs.setString(OneVpnAccountKeys.session, document);

        expect(
          await store.read(),
          isA<OneVpnSessionUnreadable>(),
          reason: document,
        );
        expect(
          await store.read(),
          isA<OneVpnSessionUnreadable>(),
          reason: document,
        );

        expect(
          await prefs.getString(OneVpnAccountKeys.session),
          document,
          reason: document,
        );
      }
    });

    test('reading a good document leaves it on disk', () async {
      await store.write(_session());
      final written = await prefs.getString(OneVpnAccountKeys.session);

      await store.read();

      expect(await prefs.getString(OneVpnAccountKeys.session), written);
    });

    test('clear removes the document and the marker inside it', () async {
      await store.write(_session(pendingSince: DateTime.utc(2026, 9, 15)));

      await store.clear();

      expect(await prefs.getString(OneVpnAccountKeys.session), isNull);
      expect(await store.read(), isA<OneVpnSessionAbsent>());
    });

    test('a write replaces the previous document whole', () async {
      await store.write(_session(pendingSince: DateTime.utc(2026, 9, 15)));
      await store.write(_session());

      final read = await store.read() as OneVpnSessionRestored;

      expect(read.session.premiumPendingSince, isNull);
    });

    test('a stamp written from a local clock reads back as the same '
        'instant', () async {
      final local = DateTime(2026, 9, 15, 12);
      await store.writeLastRefreshAt(local);

      final read = await store.readLastRefreshAt();

      expect(read!.isUtc, isTrue);
      expect(read.millisecondsSinceEpoch, local.millisecondsSinceEpoch);
    });

    test('the cooldown stamp round trips and clears', () async {
      expect(await store.readLastRefreshAt(), isNull);

      final at = DateTime.fromMillisecondsSinceEpoch(
        1789000000000,
        isUtc: true,
      );
      await store.writeLastRefreshAt(at);
      expect(await store.readLastRefreshAt(), at);
      // The stamp reads back as UTC, so the cooldown ignores the device's
      // time zone.
      expect((await store.readLastRefreshAt())!.isUtc, isTrue);

      await store.clearLastRefreshAt();
      expect(await store.readLastRefreshAt(), isNull);
    });

    test('clearing the session leaves the stamp for its own step', () async {
      await store.write(_session());
      await store.writeLastRefreshAt(DateTime.utc(2026, 9, 15));

      await store.clear();

      expect(await store.readLastRefreshAt(), isNotNull);
    });
  });

  group('the in-memory store', () {
    test('answers the same three ways as the shipped store', () async {
      final store = OneVpnEphemeralCredentialStore();
      expect(await store.read(), isA<OneVpnSessionAbsent>());

      await store.write(_session());
      expect(await store.read(), isA<OneVpnSessionRestored>());

      store.document = 'not json at all';
      expect(await store.read(), isA<OneVpnSessionUnreadable>());

      store.document = jsonEncode(<String, dynamic>{'username': 'someone'});
      expect(await store.read(), isA<OneVpnSessionUnreadable>());

      await store.clear();
      expect(await store.read(), isA<OneVpnSessionAbsent>());
    });
  });
}
