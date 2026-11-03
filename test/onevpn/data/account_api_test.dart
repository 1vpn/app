// The endpoint layer: the four request shapes verbatim, and the decode
// rules that turn an answered call into a payload or into Malformed.
//
// test/onevpn/net/api_transport_test.dart pins the transport's walk and
// accept rule. This suite pins the half a server can change: the request
// each call sends, and what this client accepts and refuses back.
//
// No network is touched. The suite replaces Dio's adapter, so these tests
// run offline and deterministically.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/data/account_api.dart';
import 'package:onexray/onevpn/model/user_data.dart';
import 'package:onexray/onevpn/net/api_transport.dart';

/// Records every request and replies from a handler keyed on the host.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;
  final List<RequestOptions> requests = <RequestOptions>[];

  List<String> get hosts =>
      requests.map((r) => r.uri.host).toList(growable: false);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, Object body) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: <String, List<String>>{
    Headers.contentTypeHeader: <String>[Headers.jsonContentType],
  },
);

const Map<String, dynamic> _userDataBody = <String, dynamic>{
  'username': 'someone',
  'email': 'someone@example.invalid',
  'isPremium': true,
  'sessionAuthToken': 'token-abc',
  'uuid': 'uuid-1',
  'publicKey': 'pbk-1',
  'shortId': 'sid-1',
  'locations': <dynamic>[],
};

({
  OneVpnApiTransport transport,
  _FakeAdapter adapter,
  OneVpnDomainMemory memory,
})
_harness(Future<ResponseBody> Function(RequestOptions options) handler) {
  final adapter = _FakeAdapter(handler);
  final dio = Dio()..httpClientAdapter = adapter;
  final store = OneVpnEphemeralDomainMemory();
  return (
    transport: OneVpnApiTransport(memory: store, dio: dio),
    adapter: adapter,
    memory: store,
  );
}

/// A map that throws on every lookup.
///
/// Stands in for a parse failure the DTO itself never produces. It
/// exercises the decode boundary's catch-all on its own.
class _ExplodingMap implements Map<String, dynamic> {
  @override
  dynamic operator [](Object? key) => throw StateError('lookup exploded');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A transport that answers with a fixed result and never dials anything.
class _FixedResultTransport extends OneVpnApiTransport {
  _FixedResultTransport(this.result)
    : super(memory: OneVpnEphemeralDomainMemory(), dio: Dio());

  final OneVpnApiResult<Map<String, dynamic>> result;

  @override
  Future<OneVpnApiResult<Map<String, dynamic>>> send({
    required String method,
    required String path,
    Map<String, String>? query,
    Object? body,
    String? authToken,
    bool sendClientType = true,
    bool idempotent = true,
  }) async => result;
}

/// Decodes [body] the way login and signup do. A token is required.
OneVpnUserData? _parse(Map<String, dynamic> body) =>
    OneVpnUserData.fromJson(body);

void main() {
  const domains = <String>[
    '1vpn.org',
    '1vpn.co',
    'onevpn.com',
    'cloudlogcdn.com',
  ];

  group('request shape', () {
    test(
      'login carries Client-Type, ?type=xray and no Authorization',
      () async {
        final h = _harness((_) async => _json(200, _userDataBody));

        await OneVpnAccountApi(transport: h.transport)
            .logIn(email: 'a@example.invalid', password: 'pw');

        final req = h.adapter.requests.single;
        expect(req.method, 'POST');
        expect(req.uri.path, '/api/login/');
        expect(req.uri.queryParameters['type'], 'xray');
        expect(req.headers['Client-Type'], 'app');
        expect(req.headers['Content-Type'], 'application/json');
        expect(req.headers.containsKey('Authorization'), isFalse);
        expect(req.data, <String, dynamic>{
          'email': 'a@example.invalid',
          'password': 'pw',
        });
      },
    );

    test('login omits the token field until 2FA asks for it', () async {
      final h = _harness((_) async => _json(200, _userDataBody));
      final api = OneVpnAccountApi(transport: h.transport);

      await api.logIn(email: 'a@example.invalid', password: 'pw');
      expect(
        (h.adapter.requests.single.data as Map).containsKey('token'),
        isFalse,
      );

      h.adapter.requests.clear();
      await api.logIn(
        email: 'a@example.invalid',
        password: 'pw',
        twoFactorToken: '123456',
      );
      expect((h.adapter.requests.single.data as Map)['token'], '123456');
    });

    test('signup posts email and password and auto-logs-in', () async {
      final h = _harness((_) async => _json(200, _userDataBody));

      final result = await OneVpnAccountApi(transport: h.transport)
          .signUp(email: 'new@example.invalid', password: 'pw');

      final req = h.adapter.requests.single;
      expect(req.method, 'POST');
      expect(req.uri.path, '/api/signup/');
      expect(req.uri.queryParameters['type'], 'xray');
      expect(req.headers['Client-Type'], 'app');
      expect(req.data, <String, dynamic>{
        'email': 'new@example.invalid',
        'password': 'pw',
      });
      // The signup response carries the token, so signup needs no second
      // round trip.
      final data = (result as OneVpnApiSuccess<OneVpnUserData>).data;
      expect(data.sessionAuthToken, 'token-abc');
    });

    test('the Authorization header is exactly "Token <t>"', () async {
      final h = _harness((_) async => _json(200, _userDataBody));

      await OneVpnAccountApi(transport: h.transport)
          .fetchUserData(authToken: 'token-abc');

      expect(
        h.adapter.requests.single.headers['Authorization'],
        'Token token-abc',
      );
      // The call is a POST, not a GET.
      expect(h.adapter.requests.single.method, 'POST');
      // The call sends no body, not an empty JSON object.
      expect(h.adapter.requests.single.data, isNull);
    });

    test('a 401 is reported as unauthorised, a 400 is not', () async {
      final h = _harness(
        (_) async => _json(401, <String, dynamic>{'error': 'invalid token'}),
      );

      final result = await OneVpnAccountApi(transport: h.transport)
          .fetchUserData(authToken: 'stale');

      final rejected = result as OneVpnApiRejected<OneVpnUserData>;
      expect(rejected.isUnauthorised, isTrue);
      // A 401 body carries no `code`. The code is nullable, and classifying
      // a rejection never requires it.
      expect(rejected.code, isNull);
    });

    test('403 is not sign-out-worthy', () async {
      // A 403 is not a known expired-token signal. Treating it as one could
      // sign the user out for another cause.
      final h = _harness(
        (_) async => _json(403, <String, dynamic>{'error': 'forbidden'}),
      );

      final result = await OneVpnAccountApi(transport: h.transport)
          .fetchUserData(authToken: 'stale');

      expect(
        (result as OneVpnApiRejected<OneVpnUserData>).isUnauthorised,
        isFalse,
      );
    });

    test('refresh_token sends no Client-Type and no ?type', () async {
      // refresh_token is the one call with no Client-Type header and no type
      // query. The test pins its exact shape.
      final h = _harness(
        (_) async => _json(200, <String, dynamic>{'sessionAuthToken': 'new'}),
      );

      final result = await OneVpnAccountApi(transport: h.transport)
          .refreshToken(authToken: 'old');

      final req = h.adapter.requests.single;
      expect(req.method, 'POST');
      expect(req.uri.path, '/api/refresh_token/');
      expect(req.uri.queryParameters, isEmpty);
      expect(req.headers.containsKey('Client-Type'), isFalse);
      expect(req.headers['Authorization'], 'Token old');
      expect((result as OneVpnApiSuccess<String>).data, 'new');
    });
  });

  group('two-factor', () {
    test('code 1001 is a branch of the flow, not a failure', () async {
      final h = _harness(
        (_) async => _json(401, <String, dynamic>{
          'error': 'Two factor required',
          'code': kOneVpnTwoFactorRequiredCode,
        }),
      );

      final result = await OneVpnAccountApi(transport: h.transport)
          .logIn(email: 'a@example.invalid', password: 'pw');

      final rejected = result as OneVpnApiRejected<OneVpnUserData>;
      expect(rejected.isTwoFactorRequired, isTrue);
      expect(kOneVpnTwoFactorRequiredCode, 1001);
    });

    test('a failure survives being re-typed through decoding', () async {
      final h = _harness(
        (options) async => throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      );

      final result = await OneVpnAccountApi(transport: h.transport)
          .logIn(email: 'a@example.invalid', password: 'pw');

      expect(result, isA<OneVpnApiUnreachable<OneVpnUserData>>());
      expect(
        (result as OneVpnApiUnreachable<OneVpnUserData>).attempts.length,
        domains.length,
      );
    });

    test(
      'a 200 with no session token is malformed, not an empty account',
      () async {
        // Success here would sign the user in with no locations and no
        // token.
        final h = _harness(
          (_) async => _json(200, <String, dynamic>{'username': 'someone'}),
        );

        final result = await OneVpnAccountApi(transport: h.transport)
            .logIn(email: 'a@example.invalid', password: 'pw');

        expect(result, isA<OneVpnApiMalformed<OneVpnUserData>>());
      },
    );

    test(
      'a malformed answer still remembers the domain that answered',
      () async {
        // The transport got an answer, so the shape is the server's problem.
        // The next call must not repeat the walk.
        final h = _harness(
          (options) async => options.uri.host == '1vpn.org'
              ? _json(503, <String, dynamic>{})
              : _json(200, <String, dynamic>{'username': 'someone'}),
        );

        final result = await OneVpnAccountApi(transport: h.transport)
            .logIn(email: 'a@example.invalid', password: 'pw');

        expect(result, isA<OneVpnApiMalformed<OneVpnUserData>>());
        expect(await h.memory.read(), '1vpn.co');
      },
    );
  });

  group('decoding a user payload', () {
    test('a full payload decodes every modelled field', () {
      final data = _parse(<String, dynamic>{
        ..._userDataBody,
        'locations': <dynamic>[
          <String, dynamic>{
            'city': 'Amsterdam',
            'cityCode': 'AMS',
            'country': 'Netherlands',
            'countryCode': 'NL',
            'isPremium': false,
            'servers': <dynamic>[
              <String, dynamic>{'host': 'ams1.example.invalid'},
              <String, dynamic>{
                'host': 'ams2.example.invalid',
                'realityServerName': 'sni.example.invalid',
              },
            ],
          },
        ],
      })!;

      expect(data.username, 'someone');
      expect(data.email, 'someone@example.invalid');
      expect(data.isPremium, isTrue);
      expect(data.sessionAuthToken, 'token-abc');
      expect(data.credentials.uuid, 'uuid-1');
      expect(data.credentials.publicKey, 'pbk-1');
      expect(data.credentials.shortId, 'sid-1');
      expect(data.credentials.isComplete, isTrue);
      final location = data.locations.single;
      expect(location.city, 'Amsterdam');
      expect(location.cityCode, 'AMS');
      expect(location.country, 'Netherlands');
      expect(location.countryCode, 'NL');
      expect(location.servers, hasLength(2));
      expect(location.servers!.first.host, 'ams1.example.invalid');
      // Null means "use the default", not "no SNI". The outbound compiler
      // chooses and substitutes the default.
      expect(location.servers!.first.realityServerName, isNull);
      expect(location.servers!.last.realityServerName, 'sni.example.invalid');
    });

    test('the premium credential triple is absent for a free account', () {
      // The server declares these fields non-null but never enforces that.
      // A free account's payload can omit all three.
      final data = _parse(<String, dynamic>{
        'isPremium': false,
        'sessionAuthToken': 'token-abc',
      })!;

      expect(data.credentials.uuid, isEmpty);
      expect(data.credentials.isComplete, isFalse);
    });

    test('null and empty servers are the same thing', () {
      // A teaser is documented as `servers == null`. An empty list must
      // mean the same thing on every code path.
      OneVpnApiLocation location(Object? servers) =>
          OneVpnApiLocation.fromJson(<String, dynamic>{
            'country': 'Iceland',
            'countryCode': 'IS',
            'servers': servers,
          })!;

      expect(location(null).isConnectable, isFalse);
      expect(location(<dynamic>[]).isConnectable, isFalse);
      expect(
        location(<dynamic>[
          <String, dynamic>{'host': 'rkv.example.invalid'},
        ]).isConnectable,
        isTrue,
      );
      // Serialisation keeps the distinction the server made. A null list
      // stays absent, and an empty list stays empty.
      expect(location(null).toJson().containsKey('servers'), isFalse);
      expect(location(<dynamic>[]).toJson()['servers'], isEmpty);
    });

    test('a location without a country is dropped, not guessed at', () {
      final data = _parse(<String, dynamic>{
        ..._userDataBody,
        'locations': <dynamic>[
          <String, dynamic>{'countryCode': 'NL'},
          <String, dynamic>{'country': 'Netherlands'},
          <String, dynamic>{'country': 'Iceland', 'countryCode': 'IS'},
          'not an object',
        ],
      })!;

      expect(data.locations.map((l) => l.country), <String>['Iceland']);
    });

    test('a server without a host is dropped', () {
      final location = OneVpnApiLocation.fromJson(<String, dynamic>{
        'country': 'Iceland',
        'countryCode': 'IS',
        'servers': <dynamic>[
          <String, dynamic>{'realityServerName': 'sni.example.invalid'},
          <String, dynamic>{'host': ''},
          <String, dynamic>{'host': 'rkv.example.invalid'},
        ],
      })!;

      expect(location.servers!.map((s) => s.host), <String>[
        'rkv.example.invalid',
      ]);
    });

    test('a locations key that is not a list decodes as no locations', () {
      expect(
        _parse(<String, dynamic>{..._userDataBody, 'locations': 'unexpected'})!
            .locations,
        isEmpty,
      );
      expect(
        _parse(<String, dynamic>{..._userDataBody, 'locations': null})!
            .locations,
        isEmpty,
      );
    });

    // The API may start sending fields this client does not model. The
    // parse ignores them and still succeeds. The server can then ship a new
    // response shape before any client reads it. The `someFuture*` fields
    // below are that case.
    test('unknown fields are ignored, at every level of the payload', () {
      final data = _parse(<String, dynamic>{
        ..._userDataBody,
        'someFutureAccountField': <String, dynamic>{'nested': true},
        'locations': <dynamic>[
          <String, dynamic>{
            'country': 'Iceland',
            'countryCode': 'IS',
            'someFutureLocationField': 7,
            'servers': <dynamic>[
              <String, dynamic>{
                'host': 'rkv.example.invalid',
                'realityServerName': 'sni.example.invalid',
                'ip': '192.0.2.10',
                'ip6': '2001:db8::10',
              },
            ],
          },
        ],
      });

      expect(data, isNotNull);
      final server = data!.locations.single.servers!.single;
      expect(server.host, 'rkv.example.invalid');
      expect(server.realityServerName, 'sni.example.invalid');
      // `ip` and `ip6` round-trip. The `someFuture*` fields above remain the
      // unknown-field proof.
      expect(server.ip, '192.0.2.10');
      expect(server.ip6, '2001:db8::10');
      expect(server.toJson().keys, <String>[
        'host',
        'realityServerName',
        'ip',
        'ip6',
      ]);
    });

    // A literal the dialer cannot use is dropped at parse, so the node keeps
    // its hostname path. An invalid string, a family mismatch, and a
    // wrong-typed value all read as null.
    test('an unusable ip or ip6 literal drops to null', () {
      OneVpnApiServer parseServer(Map<String, dynamic> extra) =>
          OneVpnApiServer.fromJson(<String, dynamic>{
            'host': 'node.example.invalid',
            ...extra,
          })!;

      // A syntactically invalid literal drops.
      expect(parseServer(<String, dynamic>{'ip': 'not-an-ip'}).ip, isNull);
      // An IPv6 string in the v4 `ip` field fails the family check.
      expect(parseServer(<String, dynamic>{'ip': '2001:db8::10'}).ip, isNull);
      // An IPv4 string in the v6 `ip6` field fails the family check.
      expect(parseServer(<String, dynamic>{'ip6': '192.0.2.10'}).ip6, isNull);
      // A wrong-typed value drops.
      expect(parseServer(<String, dynamic>{'ip': 12345}).ip, isNull);
      expect(parseServer(<String, dynamic>{'ip6': true}).ip6, isNull);

      // Both literals drop and neither round-trips out, so the node dials its
      // hostname.
      final dropped = parseServer(<String, dynamic>{
        'ip': 'not-an-ip',
        'ip6': '192.0.2.10',
      });
      expect(dropped.ip, isNull);
      expect(dropped.ip6, isNull);
      expect(dropped.toJson().containsKey('ip'), isFalse);
      expect(dropped.toJson().containsKey('ip6'), isFalse);
    });

    test('a payload with no token does not decode for login or signup', () {
      // Without a token there is no session to persist, so login and signup
      // refuse the payload.
      expect(_parse(<String, dynamic>{'username': 'someone'}), isNull);
      expect(
        _parse(<String, dynamic>{..._userDataBody, 'sessionAuthToken': ''}),
        isNull,
      );
    });

    test(
      'get_user_data decodes without a token but not without isPremium',
      () async {
        // That endpoint's job is entitlement, not authentication, so it
        // needs no token. A token-less body must still identify itself as a
        // user record. Otherwise a courtesy 200 would decode as a default
        // UserData and downgrade a paying account.
        final withoutToken = OneVpnUserData.fromJson(<String, dynamic>{
          'username': 'someone',
          'isPremium': true,
        }, requireToken: false);
        expect(withoutToken, isNotNull);
        expect(withoutToken!.isPremium, isTrue);
        // The token is empty, never null. The caller answers a missing token
        // by keeping the token it holds.
        expect(withoutToken.sessionAuthToken, isEmpty);

        expect(
          OneVpnUserData.fromJson(<String, dynamic>{
            'username': 'someone',
          }, requireToken: false),
          isNull,
        );
        // The field is wrong-typed, not absent. This body carries a token,
        // so it reaches the field check. A token-less body would stop at the
        // token-less guard.
        expect(
          OneVpnUserData.fromJson(<String, dynamic>{
            'sessionAuthToken': 'token-abc',
            'isPremium': 'yes',
          }, requireToken: false),
          isNull,
        );
      },
    );

    test('fetchUserData accepts a token-less entitlement answer', () async {
      final h = _harness(
        (_) async => _json(200, <String, dynamic>{
          'username': 'someone',
          'isPremium': true,
        }),
      );

      final result = await OneVpnAccountApi(transport: h.transport)
          .fetchUserData(authToken: 'token-abc');

      expect(
        (result as OneVpnApiSuccess<OneVpnUserData>).data.isPremium,
        isTrue,
      );
    });

    test('a courtesy 200 that is not a user record is malformed', () async {
      final h = _harness(
        (_) async => _json(200, <String, dynamic>{'status': 'ok'}),
      );

      final result = await OneVpnAccountApi(transport: h.transport)
          .fetchUserData(authToken: 'token-abc');

      expect(result, isA<OneVpnApiMalformed<OneVpnUserData>>());
    });

    test('a refresh response without a token is malformed', () async {
      final h = _harness(
        (_) async => _json(200, <String, dynamic>{'sessionAuthToken': ''}),
      );

      final result = await OneVpnAccountApi(transport: h.transport)
          .refreshToken(authToken: 'old');

      expect(result, isA<OneVpnApiMalformed<String>>());
      expect(
        (result as OneVpnApiMalformed<String>).description,
        contains('sessionAuthToken'),
      );
    });
  });

  // Parsing never throws, and a malformed payload reports as
  // OneVpnApiMalformed. A hard cast on a wrong-typed field would break both
  // rules. The TypeError would escape logIn() and fetchUserData(). No
  // caller could classify it, and no failover or sign-in path could
  // recover.
  group('a wrong-typed payload is classified, never thrown', () {
    test('a wrong-typed isPremium is refused even with a token', () async {
      // The token proves nothing about the rest of the record. A body
      // whose isPremium is not a bool is not this API's user record.
      // Decoding it would report a paying account as free.
      final h = _harness(
        (_) async =>
            _json(200, <String, dynamic>{..._userDataBody, 'isPremium': 1}),
      );

      final result = await OneVpnAccountApi(transport: h.transport)
          .logIn(email: 'a@example.invalid', password: 'pw');

      expect(result, isA<OneVpnApiMalformed<OneVpnUserData>>());
    });

    test('a wrong-typed field inside one server row drops that row', () async {
      final h = _harness(
        (_) async => _json(200, <String, dynamic>{
          ..._userDataBody,
          'locations': <dynamic>[
            <String, dynamic>{
              'country': 'Iceland',
              'countryCode': 'IS',
              'servers': <dynamic>[
                <String, dynamic>{'host': 42},
                <String, dynamic>{'host': 'rkv.example.invalid'},
              ],
            },
          ],
        }),
      );

      final result = await OneVpnAccountApi(transport: h.transport)
          .logIn(email: 'a@example.invalid', password: 'pw');

      final data = (result as OneVpnApiSuccess<OneVpnUserData>).data;
      expect(data.locations.single.servers!.map((s) => s.host), <String>[
        'rkv.example.invalid',
      ]);
    });

    test('wrong-typed location fields drop that location', () async {
      final h = _harness(
        (_) async => _json(200, <String, dynamic>{
          ..._userDataBody,
          'locations': <dynamic>[
            <String, dynamic>{'country': 42, 'countryCode': 'IS'},
            <String, dynamic>{
              'country': 'Iceland',
              'countryCode': <int>[1],
            },
            <String, dynamic>{
              'country': 'Iceland',
              'countryCode': 'IS',
              'city': 7,
              'cityCode': false,
              'isPremium': 'yes',
            },
          ],
        }),
      );

      final result = await OneVpnAccountApi(transport: h.transport)
          .logIn(email: 'a@example.invalid', password: 'pw');

      final data = (result as OneVpnApiSuccess<OneVpnUserData>).data;
      final location = data.locations.single;
      expect(location.country, 'Iceland');
      // A wrong-typed optional field reads as absent rather than
      // poisoning the location that carries it.
      expect(location.city, isNull);
      expect(location.cityCode, isNull);
      expect(location.isPremium, isFalse);
    });

    test('any throw out of the parse becomes malformed', () async {
      // The boundary catch, on its own. The DTO is defensive field by
      // field. The guarantee holds at the boundary: whatever the parse
      // does, the caller gets a result.
      final api = OneVpnAccountApi(
        transport: _FixedResultTransport(
          OneVpnApiSuccess<Map<String, dynamic>>(_ExplodingMap()),
        ),
      );

      expect(
        await api.logIn(email: 'a@example.invalid', password: 'pw'),
        isA<OneVpnApiMalformed<OneVpnUserData>>(),
      );
      expect(
        await api.fetchUserData(authToken: 'token-abc'),
        isA<OneVpnApiMalformed<OneVpnUserData>>(),
      );
      expect(
        await api.refreshToken(authToken: 'old'),
        isA<OneVpnApiMalformed<String>>(),
      );
    });

    test('an entitlement body with a token still needs isPremium', () async {
      // The sanity check reads the whole get_user_data response, not only
      // its token-less form. Otherwise a refresh with a token and no
      // entitlement field would decode as free and downgrade a paying
      // account.
      final h = _harness(
        (_) async => _json(200, <String, dynamic>{
          'username': 'someone',
          'sessionAuthToken': 'token-abc',
        }),
      );

      final result = await OneVpnAccountApi(transport: h.transport)
          .fetchUserData(authToken: 'token-abc');

      expect(result, isA<OneVpnApiMalformed<OneVpnUserData>>());
    });

    test('a servers list that loses every row drops the location', () {
      // A teaser is `servers: null`. A list that arrived with rows and
      // lost all of them is not a teaser. Reporting it as [] would
      // re-serialise a shape the server never sent.
      expect(
        OneVpnApiLocation.fromJson(<String, dynamic>{
          'country': 'Iceland',
          'countryCode': 'IS',
          'servers': <dynamic>[
            <String, dynamic>{'realityServerName': 'sni.example.invalid'},
            <String, dynamic>{'host': ''},
          ],
        }),
        isNull,
      );

      final data = _parse(<String, dynamic>{
        ..._userDataBody,
        'locations': <dynamic>[
          <String, dynamic>{
            'country': 'Nowhere',
            'countryCode': 'NW',
            'servers': <dynamic>[
              <String, dynamic>{'host': 42},
            ],
          },
          <String, dynamic>{'country': 'Iceland', 'countryCode': 'IS'},
        ],
      })!;

      expect(data.locations.map((l) => l.country), <String>['Iceland']);
    });
  });
}
