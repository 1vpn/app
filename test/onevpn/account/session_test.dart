// The persisted session document: what survives a round trip, and what
// makes a document unusable.

import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/account/session.dart';
import 'package:onexray/onevpn/model/user_data.dart';

const _credentials = OneVpnCredentials(
  uuid: 'uuid-1',
  publicKey: 'pbk-1',
  shortId: 'sid-1',
);

OneVpnSession _session({DateTime? pendingSince, bool isPremium = true}) =>
    OneVpnSession(
      sessionAuthToken: 'token-abc',
      username: 'someone',
      email: 'someone@example.invalid',
      isPremium: isPremium,
      credentials: _credentials,
      locations: const <OneVpnApiLocation>[
        OneVpnApiLocation(
          city: 'Somewhere',
          cityCode: 'SWH',
          country: 'Someland',
          countryCode: 'SL',
          servers: <OneVpnApiServer>[
            OneVpnApiServer(
              host: 'a.example.invalid',
              realityServerName: 'sni',
            ),
          ],
          isPremium: true,
        ),
        OneVpnApiLocation(
          country: 'Teaserland',
          countryCode: 'TL',
          isPremium: true,
        ),
      ],
      premiumPendingSince: pendingSince,
    );

void main() {
  test('a session round trips through JSON with every field intact', () {
    final restored = OneVpnSession.fromJson(_session().toJson());

    expect(restored, isNotNull);
    expect(restored!.sessionAuthToken, 'token-abc');
    expect(restored.username, 'someone');
    expect(restored.email, 'someone@example.invalid');
    expect(restored.isPremium, isTrue);
    expect(restored.credentials.uuid, 'uuid-1');
    expect(restored.credentials.publicKey, 'pbk-1');
    expect(restored.credentials.shortId, 'sid-1');
    expect(restored.locations, hasLength(2));
    expect(restored.locations.first.servers!.single.host, 'a.example.invalid');
    expect(restored.locations.first.servers!.single.realityServerName, 'sni');
    // A teaser is sent as no servers and must round trip as no servers,
    // not as an empty list.
    expect(restored.locations.last.servers, isNull);
    expect(restored.locations.last.isConnectable, isFalse);
    expect(restored.premiumPendingSince, isNull);
  });

  // The marker decodes as UTC. A document written in one time zone and read
  // in another describes the same instant.
  test('the marker round trips to the millisecond, in UTC', () {
    final at = DateTime.fromMillisecondsSinceEpoch(1789000000123, isUtc: true);
    final restored = OneVpnSession.fromJson(
      _session(pendingSince: at).toJson(),
    );

    expect(restored!.premiumPendingSince, at);
    expect(restored.premiumPendingSince!.isUtc, isTrue);
    expect(restored.isPremiumPending, isTrue);
  });

  test('a document with no marker carries no marker key', () {
    expect(_session().toJson().containsKey('premiumPendingSince'), isFalse);
  });

  test('a pending grant reads as entitled while the server says free', () {
    final pending = _session(
      isPremium: false,
      pendingSince: DateTime.utc(2026, 9, 15),
    );

    expect(pending.isPremium, isFalse);
    expect(pending.isPremiumEntitled, isTrue);
    expect(_session(isPremium: false).isPremiumEntitled, isFalse);
  });

  test('a document with no token is not a session', () {
    final json = _session().toJson()..remove('sessionAuthToken');
    expect(OneVpnSession.fromJson(json), isNull);
    expect(
      OneVpnSession.fromJson(_session().toJson()..['sessionAuthToken'] = ''),
      isNull,
    );
  });

  test('a document with no entitlement is not a session', () {
    final json = _session().toJson()..remove('isPremium');
    expect(OneVpnSession.fromJson(json), isNull);
    expect(
      OneVpnSession.fromJson(_session().toJson()..['isPremium'] = 'yes'),
      isNull,
    );
  });

  // One unparseable row must not cost the user the whole session.
  test('an unusable location row is dropped and the session survives', () {
    final json = _session().toJson();
    json['locations'] = <dynamic>[
      ...json['locations'] as List,
      <String, dynamic>{'country': 'Nowhere'},
    ];

    final restored = OneVpnSession.fromJson(json);

    expect(restored, isNotNull);
    expect(restored!.locations, hasLength(2));
  });

  test('a document written by a later build keeps the fields this one '
      'models', () {
    final json = _session().toJson()..['fieldFromAFutureBuild'] = 42;

    final restored = OneVpnSession.fromJson(json);

    expect(restored!.sessionAuthToken, 'token-abc');
    expect(restored.locations, hasLength(2));
  });

  test('a sign-in payload becomes a session with no marker', () {
    final data = OneVpnUserData.fromJson(const <String, dynamic>{
      'username': 'someone',
      'email': 'someone@example.invalid',
      'isPremium': true,
      'sessionAuthToken': 'token-abc',
      'uuid': 'uuid-1',
      'publicKey': 'pbk-1',
      'shortId': 'sid-1',
      'locations': <dynamic>[],
    })!;

    final session = OneVpnSession.fromUserData(data);

    expect(session.sessionAuthToken, 'token-abc');
    expect(session.isPremium, isTrue);
    expect(session.premiumPendingSince, isNull);
    expect(session.credentials.isComplete, isTrue);
  });

  test('copyWith clears the marker only when asked', () {
    final marked = _session(pendingSince: DateTime.utc(2026, 9, 15));

    expect(marked.copyWith(isPremium: false).premiumPendingSince, isNotNull);
    expect(
      marked.copyWith(clearPremiumPendingSince: true).premiumPendingSince,
      isNull,
    );
  });
}
