// Tests the domain failover walk of the API transport.
//
//   * "remembers the domain that worked" pins stickiness. A later call
//     dials the remembered domain first and skips a dead primary.
//
//   * "fails over past a block page that answers 403" pins the accept
//     rule. A 4xx without a rejection key is a non-answer, so the walk
//     tries the backup domains.
//
// No test touches the network. A fake adapter replaces Dio's adapter, so
// the tests run offline and deterministically.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/data/account_api.dart';
import 'package:onexray/onevpn/model/user_data.dart';
import 'package:onexray/onevpn/net/api_transport.dart';
import 'package:onexray/onevpn/net/failover_domains.dart';

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

/// A domain memory that persists a real record against a movable clock.
///
/// The record uses the encoding that [OneVpnPrefsDomainMemory] writes to
/// preferences. [OneVpnEphemeralDomainMemory] holds a bare string with no
/// timestamp. A test of the TTL on the write path needs this memory.
class _ClockedMemory implements OneVpnDomainMemory {
  _ClockedMemory(this.clock);

  final DateTime Function() clock;

  /// [OneVpnPrefsDomainMemory]'s own default, so these tests measure the
  /// TTL the app ships with.
  static const ttl = Duration(days: 7);

  String? record;
  int writes = 0;

  @override
  Future<String?> read() async =>
      OneVpnPrefsDomainMemory.domainFromRecord(record, now: clock(), ttl: ttl);

  @override
  Future<void> write(String domain) async {
    writes++;
    record = OneVpnPrefsDomainMemory.encodeRecord(domain, clock());
  }

  @override
  Future<void> clear() async => record = null;
}

/// A domain memory whose backing store fails.
///
/// `shared_preferences` is platform IO. The channel can fail, and the
/// store can be unreadable on a device with no writable data directory.
class _BrokenMemory implements OneVpnDomainMemory {
  _BrokenMemory({
    this.failsRead = false,
    this.failsWrite = false,
    this.failsClear = false,
    this.domain,
  });

  final bool failsRead;
  final bool failsWrite;
  final bool failsClear;
  String? domain;
  int writes = 0;

  @override
  Future<String?> read() async {
    if (failsRead) throw Exception('preferences unavailable');
    return domain;
  }

  @override
  Future<void> write(String value) async {
    writes++;
    if (failsWrite) throw Exception('preferences unavailable');
    domain = value;
  }

  @override
  Future<void> clear() async {
    if (failsClear) throw Exception('preferences unavailable');
    domain = null;
  }
}

/// A reachability stamp whose clear fails.
class _UnclearableStamp extends OneVpnEphemeralReachabilityStamp {
  _UnclearableStamp(super.stamp);

  @override
  Future<void> clear() async => throw Exception('preferences unavailable');
}

ResponseBody _json(int status, Object body) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: <String, List<String>>{
    Headers.contentTypeHeader: <String>[Headers.jsonContentType],
  },
);

ResponseBody _html(int status, String body) => ResponseBody.fromString(
  body,
  status,
  headers: <String, List<String>>{
    Headers.contentTypeHeader: <String>['text/html; charset=utf-8'],
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
  OneVpnEphemeralReachabilityStamp stamp,
})
_harness(
  Future<ResponseBody> Function(RequestOptions options) handler, {
  String? sticky,
  OneVpnDomainMemory? memory,
}) {
  final adapter = _FakeAdapter(handler);
  final dio = Dio()..httpClientAdapter = adapter;
  // Several transports can share one passed-in memory. Each transport
  // stands for one app launch, so a shared store models a cold start.
  final store = memory ?? OneVpnEphemeralDomainMemory(sticky);
  final stamp = OneVpnEphemeralReachabilityStamp();
  return (
    transport: OneVpnApiTransport(
      memory: store,
      reachabilityStamp: stamp,
      now: () => _probeClock,
      dio: dio,
    ),
    adapter: adapter,
    memory: store,
    stamp: stamp,
  );
}

/// The clock every harness transport reads for the reachability stamp.
final DateTime _probeClock = DateTime.utc(2026, 10, 6, 12);

Future<OneVpnApiResult<Map<String, dynamic>>> _get(
  OneVpnApiTransport transport,
) => transport.send(method: 'POST', path: 'get_user_data_api/');

void main() {
  const domains = <String>[
    '1vpn.org',
    '1vpn.co',
    'onevpn.com',
    'cloudlogcdn.com',
  ];

  group('the shared domain list', () {
    // [OneVpnFailoverDomains] is the single source of the domain list.
    // The probe URL list derives from the same list. This test pins its
    // order for the transport walk.
    test('the transport walks the failover domains in the pinned order', () {
      expect(OneVpnFailoverDomains.all, domains);
      expect(OneVpnApiEnvironment.production.domains, domains);
      expect(OneVpnApiEnvironment.production.basePath, '/api');
    });

    test('there is no second environment to dial', () async {
      // Production is the only environment in shipping code. No staging
      // host is on the endpoint allowlist. The environment stays
      // injectable, so a test can dial a host of its choosing.
      final h = _harness((_) async => _json(200, _userDataBody));
      final transport = OneVpnApiTransport(
        environment: const OneVpnApiEnvironment(
          domains: <String>['api.example.invalid'],
        ),
        memory: OneVpnEphemeralDomainMemory(),
        dio: Dio()..httpClientAdapter = h.adapter,
      );

      await _get(transport);

      expect(h.adapter.hosts, <String>['api.example.invalid']);
    });
  });

  group('domain failover', () {
    test('uses the primary and stops there when it answers', () async {
      final h = _harness((_) async => _json(200, _userDataBody));

      final result = await _get(h.transport);

      expect(result, isA<OneVpnApiSuccess<Map<String, dynamic>>>());
      expect(h.adapter.hosts, <String>['1vpn.org']);
    });

    test('falls over to the next domain on HTTP 5xx', () async {
      final h = _harness(
        (options) async => options.uri.host == '1vpn.org'
            ? _json(503, <String, dynamic>{'detail': 'down'})
            : _json(200, _userDataBody),
      );

      final result = await _get(h.transport);

      expect(result, isA<OneVpnApiSuccess<Map<String, dynamic>>>());
      expect(h.adapter.hosts, <String>['1vpn.org', '1vpn.co']);
    });

    test('falls over when the connection itself fails', () async {
      final h = _harness((options) async {
        if (options.uri.host == '1vpn.org' || options.uri.host == '1vpn.co') {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionTimeout,
          );
        }
        return _json(200, _userDataBody);
      });

      final result = await _get(h.transport);

      expect(result, isA<OneVpnApiSuccess<Map<String, dynamic>>>());
      expect(h.adapter.hosts, <String>['1vpn.org', '1vpn.co', 'onevpn.com']);
    });

    test('reports every domain it tried when all of them fail', () async {
      final h = _harness(
        (options) async => throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      );

      final result = await _get(h.transport);

      expect(result, isA<OneVpnApiUnreachable<Map<String, dynamic>>>());
      final failure = result as OneVpnApiUnreachable<Map<String, dynamic>>;
      expect(
        failure.attempts.map((a) => a.domain).toList(growable: false),
        domains,
      );
      // The diagnostic a censored user's bug report has to carry.
      expect(failure.description, contains('connection error'));
    });
  });

  // The rotation retires the token it presents. A re-sent rotation would
  // present the retired token, and the next domain would answer 401. The
  // token refresh dials one domain. The other calls keep the walk.
  group('the token refresh dials one domain', () {
    const rejected = <String, dynamic>{'detail': 'Invalid token.'};

    Future<OneVpnApiResult<String>> rotate(OneVpnApiTransport transport) =>
        OneVpnAccountApi(transport: transport)
            .refreshToken(authToken: 'token-old');

    test('a timeout on the main domain ends the rotation there', () async {
      final h = _harness((options) async {
        if (options.uri.host == '1vpn.org') {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.receiveTimeout,
          );
        }
        return _json(401, rejected);
      });

      final result = await rotate(h.transport);

      expect(h.adapter.hosts, <String>['1vpn.org']);
      expect(result, isA<OneVpnApiUnreachable<String>>());
      final failure = result as OneVpnApiUnreachable<String>;
      expect(failure.attempts.single.domain, '1vpn.org');
      expect(failure.description, contains('receive timeout'));
    });

    test('the same timeout on an idempotent call walks on', () async {
      final h = _harness((options) async {
        if (options.uri.host == '1vpn.org') {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.receiveTimeout,
          );
        }
        return _json(200, _userDataBody);
      });

      final result = await OneVpnAccountApi(transport: h.transport)
          .fetchUserData(authToken: 'token-old');

      expect(h.adapter.hosts, <String>['1vpn.org', '1vpn.co']);
      expect(result, isA<OneVpnApiSuccess<OneVpnUserData>>());
    });

    test('a dropped connection on the remembered backup ends the rotation '
        'there and keeps the record', () async {
      final h = _harness((options) async {
        if (options.uri.host == '1vpn.co') {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          );
        }
        return _json(401, rejected);
      }, sticky: '1vpn.co');

      final result = await rotate(h.transport);

      expect(h.adapter.hosts, <String>['1vpn.co']);
      expect(result, isA<OneVpnApiUnreachable<String>>());
      expect(
        (result as OneVpnApiUnreachable<String>).description,
        contains('connection error'),
      );
      expect(await h.memory.read(), '1vpn.co');
    });

    test('a non-answer on the main domain ends the rotation there', () async {
      final h = _harness(
        (options) async => options.uri.host == '1vpn.org'
            ? _json(503, <String, dynamic>{})
            : _json(401, rejected),
      );

      final result = await rotate(h.transport);

      expect(h.adapter.hosts, <String>['1vpn.org']);
      expect(result, isA<OneVpnApiUnreachable<String>>());
    });
  });

  group('stickiness — the legacy defect', () {
    test(
      'remembers the domain that worked and tries it first next time',
      () async {
        final h = _harness(
          (options) async => options.uri.host == '1vpn.org'
              ? _json(503, <String, dynamic>{})
              : _json(200, _userDataBody),
        );

        await _get(h.transport);
        expect(h.adapter.hosts, <String>['1vpn.org', '1vpn.co']);
        expect(await h.memory.read(), '1vpn.co');

        h.adapter.requests.clear();
        await _get(h.transport);

        // The second call dials the remembered domain first and skips
        // 1vpn.org.
        expect(h.adapter.hosts, <String>['1vpn.co']);
      },
    );

    test(
      'a remembered domain that is no longer configured is ignored',
      () async {
        final h = _harness(
          (_) async => _json(200, _userDataBody),
          sticky: 'retired.example',
        );

        await _get(h.transport);

        expect(h.adapter.hosts, <String>['1vpn.org']);
      },
    );

    test(
      'still walks the rest of the list if the remembered domain dies',
      () async {
        final h = _harness(
          (options) async => options.uri.host == 'onevpn.com'
              ? _json(503, <String, dynamic>{})
              : _json(200, _userDataBody),
          sticky: 'onevpn.com',
        );

        await _get(h.transport);

        // Sticky first, then the configured order with the sticky one
        // removed.
        expect(h.adapter.hosts, <String>['onevpn.com', '1vpn.org']);
      },
    );
  });

  group('the accept rule', () {
    test(
      'a genuine API rejection is authoritative and does not fail over',
      () async {
        final h = _harness(
          (_) async => _json(401, <String, dynamic>{
            'error': 'Invalid credentials',
            'code': 4001,
          }),
        );

        final result = await _get(h.transport);

        expect(h.adapter.hosts, <String>['1vpn.org']);
        final rejected = result as OneVpnApiRejected<Map<String, dynamic>>;
        expect(rejected.status, 401);
        expect(rejected.code, 4001);
        expect(rejected.message, 'Invalid credentials');
        expect(rejected.isTwoFactorRequired, isFalse);
      },
    );

    test('fails over past a block page that answers 403', () async {
      // An HTML 403 carries no rejection key, so it is a non-answer. The
      // walk moves on instead of reporting a login failure.
      final h = _harness(
        (options) async => options.uri.host == '1vpn.org'
            ? _html(403, '<html><body>Access denied</body></html>')
            : _json(200, _userDataBody),
      );

      final result = await _get(h.transport);

      expect(result, isA<OneVpnApiSuccess<Map<String, dynamic>>>());
      expect(h.adapter.hosts, <String>['1vpn.org', '1vpn.co']);
    });

    test('fails over past a block page that answers 200', () async {
      // A captive portal can answer 200 with a block page. A 2xx without
      // the JSON payload is a non-answer, so the walk moves on.
      final h = _harness(
        (options) async => options.uri.host == '1vpn.org'
            ? _html(200, '<html>blocked</html>')
            : _json(200, _userDataBody),
      );

      final result = await _get(h.transport);

      expect(result, isA<OneVpnApiSuccess<Map<String, dynamic>>>());
      expect(h.adapter.hosts, <String>['1vpn.org', '1vpn.co']);
    });

    test('a 2xx that is not a JSON object never counts as an answer', () async {
      final h = _harness((_) async => _json(200, <dynamic>[]));

      final result = await _get(h.transport);

      final failure = result as OneVpnApiUnreachable<Map<String, dynamic>>;
      expect(
        failure.attempts.map((a) => a.domain).toList(growable: false),
        domains,
      );
      expect(failure.attempts.first.reason, contains('not an API response'));
    });

    test(
      'a 4xx carrying only a code is still an authoritative answer',
      () async {
        // The real 401 body carries no `error` string. The code alone
        // identifies a 2FA rejection. Either key alone ends the walk.
        final h = _harness(
          (_) async => _json(400, <String, dynamic>{'code': 42}),
        );

        final result = await _get(h.transport);

        final rejected = result as OneVpnApiRejected<Map<String, dynamic>>;
        expect(h.adapter.hosts, <String>['1vpn.org']);
        expect(rejected.code, 42);
        expect(rejected.message, 'request rejected');
      },
    );

    test('a DRF rejection body is an authoritative answer', () async {
      // The account API authenticates with Django REST Framework's
      // TokenAuthentication. Its rejection body is
      // {"detail": "Invalid token."}, with neither `error` nor `code`.
      // The accept rule treats `detail` as an answer. The stale token
      // reaches one domain, and the result reports an ended session.
      final h = _harness(
        (_) async => _json(401, <String, dynamic>{'detail': 'Invalid token.'}),
      );

      final result = await h.transport.send(
        method: 'POST',
        path: 'get_user_data_api/',
        authToken: 'stale-token',
      );

      final rejected = result as OneVpnApiRejected<Map<String, dynamic>>;
      expect(rejected.isUnauthorised, isTrue);
      expect(rejected.message, 'Invalid token.');
      expect(rejected.code, isNull);
      // The walk dials one domain, so the stale token goes nowhere else.
      expect(h.adapter.hosts, <String>['1vpn.org']);
      expect(
        h.adapter.requests.map((r) => r.headers['Authorization']),
        <String>['Token stale-token'],
      );
    });

    test(
      'every accepted 4xx shape is an answer, and nothing else is',
      () async {
        // [kOneVpnApiRejectionKeys] declares the accepted shapes. Each key
        // alone ends the walk. A 4xx body with none of them is an
        // interception, and the walk falls through.
        expect(kOneVpnApiRejectionKeys, <String>['error', 'code', 'detail']);

        final bodies = <Map<String, dynamic>>[
          <String, dynamic>{'error': 'nope'},
          <String, dynamic>{'code': 1001},
          <String, dynamic>{'detail': 'Invalid token.'},
        ];
        for (final body in bodies) {
          final h = _harness((_) async => _json(400, body));

          expect(
            await _get(h.transport),
            isA<OneVpnApiRejected<Map<String, dynamic>>>(),
            reason: '$body',
          );
          expect(h.adapter.hosts, <String>['1vpn.org'], reason: '$body');
        }

        final other = _harness(
          (_) async => _json(400, <String, dynamic>{'message': 'blocked'}),
        );
        expect(
          await _get(other.transport),
          isA<OneVpnApiUnreachable<Map<String, dynamic>>>(),
        );
      },
    );
  });

  group('redirects are refused, not inspected', () {
    test('a request never lets dio follow a redirect', () async {
      // dio follows up to five hops by default. dart:io re-sends the
      // request headers on a same-scheme hop. A followed redirect would
      // carry the account token to wherever a hijacked domain points.
      final h = _harness((_) async => _json(200, _userDataBody));

      await _get(h.transport);

      expect(h.adapter.requests.single.followRedirects, isFalse);
    });

    test('a 3xx is a non-answer and the walk moves on', () async {
      // The transport classifies a redirect like a 5xx. The domain did not
      // answer, so the walk tries the next one. The body stays unread.
      final h = _harness(
        (options) async => options.uri.host == '1vpn.org'
            ? _json(302, _userDataBody)
            : _json(200, _userDataBody),
      );

      final result = await _get(h.transport);

      expect(result, isA<OneVpnApiSuccess<Map<String, dynamic>>>());
      expect(h.adapter.hosts, <String>['1vpn.org', '1vpn.co']);
      // The domain that tried to redirect us is not the sticky winner.
      expect(await h.memory.read(), '1vpn.co');
    });

    test('the report names the status that was refused', () async {
      final h = _harness((_) async => _json(302, _userDataBody));

      final result = await _get(h.transport);

      final failure = result as OneVpnApiUnreachable<Map<String, dynamic>>;
      expect(failure.attempts, hasLength(4));
      for (final attempt in failure.attempts) {
        expect(attempt.reason, 'HTTP 302, not an API response');
      }
    });

    test('realUri is the dialled URI under these request options', () async {
      // Pins why the transport never compares the answering host with the
      // dialled one. `Response.realUri` is
      // `redirects.isNotEmpty ? redirects.last.location : requestOptions.uri`.
      // dart:io appends to `redirects` only inside a hop it follows. With
      // `followRedirects: false`, `realUri` is always the dialled URI.
      // TLS verification covers a host that answers on the dialled name.
      final adapter = _FakeAdapter((_) async => _json(302, _userDataBody));
      final dio = Dio()..httpClientAdapter = adapter;

      final response = await dio.request<dynamic>(
        'https://1vpn.org/api/get_user_data_api/',
        options: Options(
          method: 'POST',
          validateStatus: (_) => true,
          followRedirects: false,
        ),
      );

      expect(response.redirects, isEmpty);
      expect(response.realUri, response.requestOptions.uri);
    });
  });

  // Nothing leaves the device, so these strings are the whole failure
  // record from the field. `DioException.message` and `toString()` can
  // carry the URL, headers and body of the failed request. For `login/`,
  // the body holds the password and the 2FA code.
  group('attempt descriptions are safe by construction', () {
    test(
      'a described failure quotes neither the body nor the exception',
      () async {
        const password = 'hunter2-not-in-any-report';
        final h = _harness(
          (options) async => throw DioException(
            requestOptions: options,
            type: DioExceptionType.unknown,
            error: StateError('boom at https://leaky.example/api/login/'),
            message: 'sending $password to https://leaky.example',
          ),
        );

        final result = await h.transport.send(
          method: 'POST',
          path: 'login/',
          body: <String, dynamic>{
            'email': 'a@example.invalid',
            'password': password,
          },
        );

        final failure = result as OneVpnApiUnreachable<Map<String, dynamic>>;
        final report = failure.description;
        expect(report, isNot(contains(password)));
        expect(report, isNot(contains('leaky')));
        expect(report, isNot(contains('boom')));
        expect(report, isNot(contains('a@example.invalid')));
        // What it does say: the type, and nothing else.
        expect(report, contains('StateError'));
        for (final domain in domains) {
          expect(report, contains(domain));
        }
      },
    );

    test(
      'every dio failure type has a description built from the type',
      () async {
        for (final type in DioExceptionType.values) {
          final h = _harness(
            (options) async =>
                throw DioException(requestOptions: options, type: type),
          );

          final result = await _get(h.transport);

          final failure = result as OneVpnApiUnreachable<Map<String, dynamic>>;
          for (final attempt in failure.attempts) {
            expect(attempt.reason, isNotEmpty, reason: '$type');
            expect(
              attempt.reason,
              isNot(contains('DioException')),
              reason: '$type',
            );
          }
        }
      },
    );
  });

  group('sticky domain expiry', () {
    final now = DateTime.utc(2026, 8, 21, 12);
    const ttl = Duration(days: 7);

    String record(String domain, DateTime at) =>
        OneVpnPrefsDomainMemory.encodeRecord(domain, at);

    String? read(String? text) =>
        OneVpnPrefsDomainMemory.domainFromRecord(text, now: now, ttl: ttl);

    test('a fresh record is used', () {
      expect(
        read(record('1vpn.co', now.subtract(const Duration(days: 6)))),
        '1vpn.co',
      );
    });

    test('a stale record is discarded so the primary gets another chance', () {
      // The TTL bounds a demotion. One transient outage pins a fallback
      // for at most seven days.
      expect(
        read(record('1vpn.co', now.subtract(const Duration(days: 8)))),
        isNull,
      );
    });

    test('a timestamp from the future is treated as stale', () {
      // Phone clocks move backwards routinely. A future timestamp reads as
      // stale, so it never pins the domain until wall time catches up.
      expect(read(record('1vpn.co', now.add(const Duration(days: 1)))), isNull);
    });

    test('absent, unparseable and incomplete records all mean "no memory"', () {
      expect(read(null), isNull);
      expect(read(''), isNull);
      expect(read('not json'), isNull);
      expect(read('[]'), isNull);
      expect(read('{"domain":"1vpn.co"}'), isNull);
      expect(read('{"at":123}'), isNull);
      expect(read('{"domain":"","at":123}'), isNull);
    });
  });

  group('sticky domain expiry — the write path', () {
    // The group above tests the pure decoder. This group tests when the
    // transport writes the record, which decides what the decoder sees.

    test(
      'daily use does not re-stamp the record, so the TTL really expires',
      () async {
        var now = DateTime.utc(2026, 8, 1, 9);
        final memory = _ClockedMemory(() => now);
        var primaryHealthy = false;

        Future<ResponseBody> handler(RequestOptions options) async =>
            options.uri.host == '1vpn.org' && !primaryHealthy
            ? _json(503, <String, dynamic>{})
            : _json(200, _userDataBody);

        // Day 0: the primary fails, and 1vpn.co wins and is remembered.
        final day0 = _harness(handler, memory: memory);
        await _get(day0.transport);
        expect(day0.adapter.hosts, <String>['1vpn.org', '1vpn.co']);
        expect(await memory.read(), '1vpn.co');

        // Days 1 to 7: one app launch a day. Each launch builds a new
        // transport, because a cold start resets any in-process write guard.
        for (var day = 1; day <= 7; day++) {
          now = now.add(const Duration(days: 1));
          final h = _harness(handler, memory: memory);
          await _get(h.transport);
          expect(h.adapter.hosts, <String>['1vpn.co'], reason: 'day $day');
        }

        // Day 8 is past the 7-day TTL, measured from the failover. The
        // primary is healthy again and gets its chance back.
        now = now.add(const Duration(days: 1));
        primaryHealthy = true;
        final day8 = _harness(handler, memory: memory);
        await _get(day8.transport);

        expect(day8.adapter.hosts, <String>['1vpn.org']);
        // Seven launches that changed nothing wrote nothing.
        expect(memory.writes, 2, reason: 'day 0 failover, day 8 recovery');
      },
    );

    test(
      'a change of winner is stamped afresh, so its own TTL starts then',
      () async {
        // The transport always writes a new winner. Otherwise the record
        // would freeze on the first domain that ever won.
        var now = DateTime.utc(2026, 8, 1, 9);
        final memory = _ClockedMemory(() => now);
        await memory.write('1vpn.co');

        now = now.add(const Duration(days: 6));
        final h = _harness(
          (options) async => options.uri.host == 'onevpn.com'
              ? _json(200, _userDataBody)
              : _json(503, <String, dynamic>{}),
          memory: memory,
        );
        await _get(h.transport);

        expect(await memory.read(), 'onevpn.com');
        // Six more days: inside the TTL of the second failover, and past
        // the TTL of the first.
        now = now.add(const Duration(days: 6));
        expect(await memory.read(), 'onevpn.com');
      },
    );

    test('a record that goes stale mid-process is written again, so the walk '
        'stays sticky', () async {
      // An in-process write guard never suppresses a write the record
      // needs. A device clock that moves backwards makes a fresh record
      // read as stale. domainFromRecord treats a negative age as stale.
      // The transport then writes the sticky choice again. Later calls in
      // this process stay sticky and skip the dead primary.
      var now = DateTime.utc(2026, 8, 1, 12);
      final memory = _ClockedMemory(() => now);
      final h = _harness(
        (options) async => options.uri.host == '1vpn.org'
            ? _json(503, <String, dynamic>{})
            : _json(200, _userDataBody),
        memory: memory,
      );

      await _get(h.transport);
      expect(h.adapter.hosts, <String>['1vpn.org', '1vpn.co']);

      // NTP corrects the clock back an hour. The test keeps one transport
      // throughout: one process, no cold start.
      now = now.subtract(const Duration(hours: 1));
      expect(await memory.read(), isNull, reason: 'the record reads as stale');

      await _get(h.transport);
      await _get(h.transport);

      // The call after the jump re-walks, because the record is gone. It
      // leaves a fresh record behind, so the next call is sticky again.
      expect(h.adapter.hosts, <String>[
        '1vpn.org',
        '1vpn.co',
        '1vpn.org',
        '1vpn.co',
        '1vpn.co',
      ]);
      expect(memory.writes, 2, reason: 'the failover, then the re-stamp');
    });

    test('an expired record for the same domain is stamped again', () async {
      // A stale record sends the walk to the top of the list. A win by the
      // same domain is a fresh decision. It restarts the clock instead of
      // inheriting an age of eight days.
      var now = DateTime.utc(2026, 8, 1, 9);
      final memory = _ClockedMemory(() => now);
      await memory.write('1vpn.co');
      now = now.add(const Duration(days: 8));

      final h = _harness(
        (options) async => options.uri.host == '1vpn.co'
            ? _json(200, _userDataBody)
            : _json(503, <String, dynamic>{}),
        memory: memory,
      );
      await _get(h.transport);

      // The walk starts from the top because the record is stale, and
      // 1vpn.co wins again.
      expect(h.adapter.hosts, <String>['1vpn.org', '1vpn.co']);
      expect(memory.writes, 2);
      expect(await memory.read(), '1vpn.co');
    });
  });

  group('the per-attempt timeout', () {
    test(
      'reaches an injected Dio, not only the one the transport builds',
      () async {
        // Every test in this file hands the transport a bare `Dio()`. The
        // timeout applies to an injected Dio too, so these tests pin
        // [kOneVpnApiTimeout].
        final h = _harness((_) async => _json(200, _userDataBody));

        await _get(h.transport);

        final req = h.adapter.requests.single;
        expect(req.connectTimeout, kOneVpnApiTimeout);
        expect(req.receiveTimeout, kOneVpnApiTimeout);
        expect(req.sendTimeout, kOneVpnApiTimeout);
        expect(kOneVpnApiTimeout, const Duration(seconds: 10));
      },
    );

    test('a hung domain gives up and the walk moves on', () async {
      // Drives dio's real receive-timeout plumbing. A domain that accepts
      // the connection and then stays silent times out, and the walk
      // moves on.
      final stuck = StreamController<Uint8List>();
      addTearDown(stuck.close);
      final adapter = _FakeAdapter(
        (options) async => options.uri.host == '1vpn.org'
            ? ResponseBody(
                stuck.stream,
                200,
                headers: <String, List<String>>{
                  Headers.contentTypeHeader: <String>[Headers.jsonContentType],
                },
              )
            : _json(200, _userDataBody),
      );
      final transport = OneVpnApiTransport(
        memory: OneVpnEphemeralDomainMemory(),
        dio: Dio()..httpClientAdapter = adapter,
        timeout: const Duration(milliseconds: 50),
      );

      final result = await _get(transport);

      expect(result, isA<OneVpnApiSuccess<Map<String, dynamic>>>());
      expect(adapter.hosts, <String>['1vpn.org', '1vpn.co']);
    });

    test('a caller that set its own timeout keeps it', () async {
      // The transport assigns its default with `??=`. A timeout the caller
      // set on the Dio stays in force.
      final adapter = _FakeAdapter((_) async => _json(200, _userDataBody));
      final transport = OneVpnApiTransport(
        memory: OneVpnEphemeralDomainMemory(),
        dio: Dio(BaseOptions(connectTimeout: const Duration(seconds: 2)))
          ..httpClientAdapter = adapter,
      );

      await _get(transport);

      expect(
        adapter.requests.single.connectTimeout,
        const Duration(seconds: 2),
      );
      expect(adapter.requests.single.receiveTimeout, kOneVpnApiTimeout);
    });
  });

  // The notice tells a user in a censored region that the primary domain
  // is blocked for them. It follows the domain that answered the latest
  // request. The transport raises it in the session where the failover
  // happens, and it clears when the primary answers again.
  group('the backup-domain notice', () {
    test('follows the domain that ANSWERED, in both directions', () async {
      var blocked = <String>{'1vpn.org'};
      final h = _harness(
        (options) async => blocked.contains(options.uri.host)
            ? _json(503, <String, dynamic>{})
            : _json(200, _userDataBody),
      );
      final seen = <String?>[];
      h.transport.backupDomainInUse.addListener(
        () => seen.add(h.transport.backupDomainInUse.value),
      );

      expect(h.transport.backupDomainInUse.value, isNull);

      // The primary is blocked and 1vpn.co wins.
      await _get(h.transport);
      expect(h.transport.backupDomainInUse.value, '1vpn.co');

      // The second call goes straight to the sticky domain and rewrites
      // nothing. The notice still stands.
      await _get(h.transport);
      expect(h.transport.backupDomainInUse.value, '1vpn.co');

      // The block lifts, the backup goes away, and the walk reaches the
      // primary again. The notice clears.
      blocked = <String>{'1vpn.co'};
      await _get(h.transport);
      expect(h.transport.backupDomainInUse.value, isNull);

      expect(
        seen,
        <String?>['1vpn.co', null],
        reason:
            'and it must notify only when the answer actually changed — a '
            'banner that rebuilds on every request is its own defect',
      );
    });

    // The transport sets the value before the no-change short-circuit.
    // Only this test covers that order. Every other test starts from an
    // empty memory, where the first answer always changes the record.
    //
    // This test models every launch after the first in a censored network.
    // The walk starts at the sticky backup, and the backup answers. The
    // record is already in place, so the transport writes nothing.
    test('a session whose FIRST call lands on an already-sticky backup raises '
        'the notice, though it rewrites nothing', () async {
      final h = _harness(
        (_) async => _json(200, _userDataBody),
        sticky: '1vpn.co',
      );

      await _get(h.transport);

      expect(
        h.adapter.hosts,
        <String>['1vpn.co'],
        reason:
            'context: the remembered backup answered on the first try, so '
            'the primary was never dialled and nothing was written',
      );
      expect(await h.memory.read(), '1vpn.co');
      expect(
        h.transport.backupDomainInUse.value,
        '1vpn.co',
        reason:
            'the notice is live request state, not an echo of the write — '
            'a user whose primary is blocked is told so on every launch, '
            'not only on the one where the failover happened to be '
            'discovered',
      );
    });

    test('a cold start into an already-blocked network can be seeded from the '
        'remembered choice', () async {
      // The value is live request state. A process that has made no call
      // yet holds no value. The boot sequence calls
      // refreshBackupDomainNotice() to seed it.
      final h = _harness(
        (_) async => _json(200, _userDataBody),
        sticky: '1vpn.co',
      );

      expect(h.transport.backupDomainInUse.value, isNull);

      await h.transport.refreshBackupDomainNotice();

      expect(h.transport.backupDomainInUse.value, '1vpn.co');
      expect(
        h.adapter.requests,
        isEmpty,
        reason: 'seeding reads the preference; it must not cost a request',
      );
    });

    test('a walk in which nothing answered clears the notice', () async {
      // The notice names the backup domain that is answering. After a walk
      // where no domain answered, the notice names none.
      var reachable = true;
      final h = _harness(
        (options) async => reachable && options.uri.host == '1vpn.co'
            ? _json(200, _userDataBody)
            : _json(503, <String, dynamic>{}),
      );

      await _get(h.transport);
      expect(h.transport.backupDomainInUse.value, '1vpn.co');

      reachable = false;
      final result = await _get(h.transport);

      expect(result, isA<OneVpnApiUnreachable<Map<String, dynamic>>>());
      expect(h.transport.backupDomainInUse.value, isNull);
      // The record survives: the walk proves nothing about which domain
      // is blocked when every one of them failed.
      expect(await h.memory.read(), '1vpn.co');
    });
  });

  group('the web-link base URL', () {
    test('points at the primary when nothing is remembered', () async {
      final h = _harness((_) async => _json(200, _userDataBody));

      expect(await h.transport.activeBaseUrl(), 'https://1vpn.org');
      expect(h.adapter.requests, isEmpty, reason: 'not a network call');
    });

    test('points at the sticky domain once one is remembered', () async {
      // A forgot-password link to a blocked domain opens a page the user
      // cannot load. The link follows the sticky domain.
      final h = _harness(
        (_) async => _json(200, _userDataBody),
        sticky: 'cloudlogcdn.com',
      );

      expect(await h.transport.activeBaseUrl(), 'https://cloudlogcdn.com');
    });
  });

  // shared_preferences is platform IO. The channel can fail, and the store
  // can be unreadable. A failed read degrades the walk to memoryless. A
  // failed write keeps the answer that already arrived.
  group('a memory that cannot be reached', () {
    test('a failed read walks from the primary and still answers', () async {
      final memory = _BrokenMemory(failsRead: true, domain: 'cloudlogcdn.com');
      final h = _harness(
        (_) async => _json(200, _userDataBody),
        memory: memory,
      );

      final result = await _get(h.transport);

      expect(result, isA<OneVpnApiSuccess<Map<String, dynamic>>>());
      expect(h.adapter.hosts, <String>['1vpn.org']);
    });

    test('a failed write does not destroy the answer', () async {
      final memory = _BrokenMemory(failsWrite: true);
      final h = _harness(
        (options) async => options.uri.host == '1vpn.org'
            ? _json(503, <String, dynamic>{})
            : _json(200, _userDataBody),
        memory: memory,
      );

      final result = await _get(h.transport);

      expect(result, isA<OneVpnApiSuccess<Map<String, dynamic>>>());
      expect(memory.writes, 1, reason: 'the write was attempted');
      // The notice is live request state, so it stands whether or not the
      // record was persisted.
      expect(h.transport.backupDomainInUse.value, '1vpn.co');
    });

    test('activeBaseUrl falls back to the primary', () async {
      // activeBaseUrl makes no network call and never throws. It feeds a
      // link the user is about to open.
      final h = _harness(
        (_) async => _json(200, _userDataBody),
        memory: _BrokenMemory(failsRead: true, domain: 'cloudlogcdn.com'),
      );

      expect(await h.transport.activeBaseUrl(), 'https://1vpn.org');
    });

    test('refreshBackupDomainNotice raises no notice and no error', () async {
      final h = _harness(
        (_) async => _json(200, _userDataBody),
        memory: _BrokenMemory(failsRead: true, domain: '1vpn.co'),
      );

      await h.transport.refreshBackupDomainNotice();

      expect(h.transport.backupDomainInUse.value, isNull);
    });
  });

  group('forgetting the domain', () {
    test('forgetDomain clears the record and the notice', () async {
      // The transport owns the memory, so the sign-out sweep calls this
      // hook. Nothing else calls it.
      final h = _harness(
        (options) async => options.uri.host == '1vpn.org'
            ? _json(503, <String, dynamic>{})
            : _json(200, _userDataBody),
      );

      await _get(h.transport);
      expect(await h.memory.read(), '1vpn.co');
      expect(h.transport.backupDomainInUse.value, '1vpn.co');

      await h.transport.forgetDomain();

      expect(await h.memory.read(), isNull);
      expect(h.transport.backupDomainInUse.value, isNull);
    });

    test('forgetDomain clears the reachability stamp', () async {
      final h = _harness((_) async => ResponseBody.fromString('1', 200));

      await h.transport.probeReachability();
      expect(await h.transport.lastReachabilityAt(), _probeClock);

      await h.transport.forgetDomain();

      expect(await h.transport.lastReachabilityAt(), isNull);
    });

    test('a failed memory clear still clears the stamp', () async {
      final stamp = OneVpnEphemeralReachabilityStamp(_probeClock);
      final transport = OneVpnApiTransport(
        memory: _BrokenMemory(failsClear: true, domain: '1vpn.co'),
        reachabilityStamp: stamp,
        dio: Dio()
          ..httpClientAdapter = _FakeAdapter((_) async => _html(500, '')),
      );

      await expectLater(transport.forgetDomain(), throwsException);

      expect(stamp.stamp, isNull);
    });

    test('a failed stamp clear still forgets the domain', () async {
      final memory = OneVpnEphemeralDomainMemory('1vpn.co');
      final transport = OneVpnApiTransport(
        memory: memory,
        reachabilityStamp: _UnclearableStamp(_probeClock),
        dio: Dio()
          ..httpClientAdapter = _FakeAdapter((_) async => _html(500, '')),
      );
      await transport.refreshBackupDomainNotice();
      expect(transport.backupDomainInUse.value, '1vpn.co');

      await transport.forgetDomain();

      expect(await memory.read(), isNull);
      expect(transport.backupDomainInUse.value, isNull);
    });

    test('the next call after forgetting walks from the top again', () async {
      final h = _harness(
        (options) async => options.uri.host == '1vpn.org'
            ? _json(503, <String, dynamic>{})
            : _json(200, _userDataBody),
      );

      await _get(h.transport);
      await h.transport.forgetDomain();
      h.adapter.requests.clear();

      await _get(h.transport);

      expect(h.adapter.hosts, <String>['1vpn.org', '1vpn.co']);
    });
  });

  group('the reachability probe', () {
    test('sends only HEAD to the root /ping/ path', () async {
      final h = _harness((_) async => ResponseBody.fromString('1', 200));

      await h.transport.probeReachability();

      final request = h.adapter.requests.single;
      expect(request.method, 'HEAD');
      expect(request.uri.toString(), 'https://1vpn.org/ping/');
      expect(request.data, isNull);
      expect(request.headers.containsKey('Authorization'), isFalse);
      expect(request.headers.containsKey('Client-Type'), isFalse);
      expect(request.followRedirects, isFalse);
    });

    test('skips a dead first domain and remembers the answering one', () async {
      final h = _harness(
        (options) async => options.uri.host == '1vpn.org'
            ? throw DioException.connectionError(
                requestOptions: options,
                reason: 'refused',
              )
            : ResponseBody.fromString('1', 200),
      );

      final answered = await h.transport.probeReachability();

      expect(answered, '1vpn.co');
      expect(h.adapter.hosts, <String>['1vpn.org', '1vpn.co']);
      expect(await h.memory.read(), '1vpn.co');
      expect(h.transport.backupDomainInUse.value, '1vpn.co');
      expect(await h.transport.activeBaseUrl(), 'https://1vpn.co');
      expect(await h.transport.lastReachabilityAt(), _probeClock);
    });

    test('counts any HTTP status as an answer', () async {
      final h = _harness((_) async => _html(404, '<html></html>'));

      expect(await h.transport.probeReachability(), '1vpn.org');
      expect(h.adapter.hosts, <String>['1vpn.org']);
      expect(await h.memory.read(), '1vpn.org');
    });

    // The probe walks from the primary since the launch order ruling of
    // 2026-10-14. It no longer dials the remembered domain first.
    test('starts at the primary, and a primary that answers replaces a '
        'remembered backup', () async {
      final h = _harness(
        (_) async => ResponseBody.fromString('1', 200),
        sticky: 'onevpn.com',
      );
      await h.transport.refreshBackupDomainNotice();
      expect(h.transport.backupDomainInUse.value, 'onevpn.com');

      expect(await h.transport.probeReachability(), '1vpn.org');
      expect(h.adapter.hosts, <String>['1vpn.org']);
      expect(await h.memory.read(), '1vpn.org');
      expect(h.transport.backupDomainInUse.value, isNull);
    });

    // A resume or launch refresh goes through send, not the probe.
    test('API calls keep the remembered domain first, and a probe that lands '
        'on a backup leaves them there', () async {
      final h = _harness(
        (options) async => options.uri.host == '1vpn.org'
            ? throw DioException.connectionError(
                requestOptions: options,
                reason: 'refused',
              )
            : _json(200, _userDataBody),
        sticky: 'onevpn.com',
      );

      await _get(h.transport);
      expect(h.adapter.hosts, <String>['onevpn.com']);

      h.adapter.requests.clear();
      expect(await h.transport.probeReachability(), '1vpn.co');
      expect(h.adapter.hosts, <String>['1vpn.org', '1vpn.co']);

      h.adapter.requests.clear();
      await _get(h.transport);
      expect(h.adapter.hosts, <String>['1vpn.co']);
    });

    test('writes nothing when no domain answers', () async {
      final h = _harness(
        (options) async => throw DioException.connectionTimeout(
          timeout: kOneVpnApiTimeout,
          requestOptions: options,
        ),
      );

      final answered = await h.transport.probeReachability();

      expect(answered, isNull);
      expect(h.adapter.hosts, domains);
      expect(await h.memory.read(), isNull);
      expect(await h.transport.lastReachabilityAt(), isNull);
      expect(h.transport.backupDomainInUse.value, isNull);
    });
  });
}
