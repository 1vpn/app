// Pins the observatory reader against a loopback server that plays the
// core's metrics endpoint. The well-formed bodies have the shape the core
// encodes. The core omits a false alive and every zero number. An absent
// field reads false or 0. Every failed or malformed read answers an empty
// set with the time the read finished.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/connect/native_auto_contracts.dart';
import 'package:onexray/onevpn/connect/observatory_reader.dart';

void main() {
  test('an alive entry parses delay and counts', () async {
    final requests = <String>[];
    final port = await _serve((request) {
      requests.add('${request.method} ${request.uri}');
      _reply(
        request,
        _metrics({
          'app-cand-acct-17': _alive('app-cand-acct-17', 312, all: 3, fail: 1),
        }),
      );
    });

    final set = await OneVpnObservatoryReader().read(port);

    expect(requests, ['GET /debug/vars']);
    expect(set.byTag.keys, ['app-cand-acct-17']);
    final observation = set.byTag['app-cand-acct-17']!;
    expect(observation.tag, 'app-cand-acct-17');
    expect(observation.alive, isTrue);
    expect(observation.delayMs, 312);
    expect(observation.all, 3);
    expect(observation.fail, 1);
  });

  test('an entry with alive omitted reads dead', () async {
    final port = await _serveBody(
      _metrics({
        'app-cand-free-3': {
          'outbound_tag': 'app-cand-free-3',
          'health_ping': {'all': 2, 'fail': 2},
        },
      }),
    );

    final observation = (await OneVpnObservatoryReader().read(port))
        .byTag['app-cand-free-3']!;

    expect(observation.alive, isFalse);
    expect(observation.delayMs, 0);
    expect(observation.all, 2);
    expect(observation.fail, 2);
  });

  test('an entry with delay omitted reads 0', () async {
    final port = await _serveBody(
      _metrics({
        'app-cand-acct-5': {
          'alive': true,
          'outbound_tag': 'app-cand-acct-5',
          'health_ping': {'all': 1},
        },
        'app-cand-acct-6': {'alive': true, 'outbound_tag': 'app-cand-acct-6'},
      }),
    );

    final set = await OneVpnObservatoryReader().read(port);

    final counted = set.byTag['app-cand-acct-5']!;
    expect(counted.alive, isTrue);
    expect(counted.delayMs, 0);
    expect(counted.all, 1);
    expect(counted.fail, 0);
    // An entry with no health_ping reads 0 for both counts.
    final uncounted = set.byTag['app-cand-acct-6']!;
    expect(uncounted.delayMs, 0);
    expect(uncounted.all, 0);
    expect(uncounted.fail, 0);
  });

  test('a tag outside the candidate prefix is kept as data', () async {
    final port = await _serveBody(
      _metrics({
        'app-entry-0': _alive('app-entry-0', 80),
        'direct': _alive('direct', 5),
        'app-cand-free-2': _alive('app-cand-free-2', 140),
      }),
    );

    final set = await OneVpnObservatoryReader().read(port);

    expect(
      set.byTag.keys,
      unorderedEquals(['app-entry-0', 'direct', 'app-cand-free-2']),
    );
    for (final tag in ['app-entry-0', 'direct']) {
      expect(tag, isNot(startsWith(OneVpnCandidateTags.prefix)));
      expect(set.byTag[tag]!.tag, tag);
      expect(set.byTag[tag]!.alive, isTrue);
    }
    expect(set.byTag['app-entry-0']!.delayMs, 80);
    expect(set.byTag['direct']!.delayMs, 5);
  });

  test('a missing or null observatory value answers empty', () async {
    final missing = await _serveBody(jsonEncode({'stats': _stats}));
    final none = await _serveBody(
      jsonEncode({'stats': _stats, 'observatory': null}),
    );

    await _expectEmpty(OneVpnObservatoryReader(), missing);
    await _expectEmpty(OneVpnObservatoryReader(), none);
  });

  test('a non-200 answers empty', () async {
    final body = _metrics({'app-cand-acct-1': _alive('app-cand-acct-1', 90)});
    final failing = await _serveBody(
      body,
      status: HttpStatus.internalServerError,
    );
    final requests = <String>[];
    final redirecting = await _serve((request) {
      requests.add(request.uri.path);
      if (request.uri.path == '/debug/vars') {
        request.response
          ..statusCode = HttpStatus.found
          ..headers.set(HttpHeaders.locationHeader, '/moved');
        request.response.close().ignore();
      } else {
        _reply(request, body);
      }
    });

    await _expectEmpty(OneVpnObservatoryReader(), failing);
    await _expectEmpty(OneVpnObservatoryReader(), redirecting);
    expect(requests, ['/debug/vars']);
  });

  test('a body over the cap answers empty', () async {
    const cap = 1048576;
    final body = _metrics({'app-cand-acct-1': _alive('app-cand-acct-1', 90)});
    final atCap = await _serveBody(body.padRight(cap));
    final overCap = await _serveBody(body.padRight(cap + 1));

    final full = await OneVpnObservatoryReader().read(atCap);

    expect(full.byTag.keys, ['app-cand-acct-1']);
    await _expectEmpty(OneVpnObservatoryReader(), overCap);
  });

  test('a read against a local server honors the timeouts', () async {
    const bound = Duration(milliseconds: 300);
    // The connect bound exceeds the 2 s limit below. A wait within that
    // limit ends on the read bound.
    final reader = OneVpnObservatoryReader(
      connectTimeout: const Duration(seconds: 10),
      readTimeout: bound,
    );
    // The headers never arrive.
    final silent = await _serve((_) {});
    // The headers and part of the body arrive. The body then stalls.
    final stalled = await _serve((request) {
      request.response
        ..statusCode = HttpStatus.ok
        ..write('{"observatory": {');
      request.response.flush().ignore();
    });
    // Nothing listens on the port. The connect is refused at once.
    final closed = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final refused = closed.port;
    await closed.close(force: true);

    for (final port in [silent, stalled]) {
      final start = DateTime.now();
      final set = await _expectEmpty(reader, port);
      final waited = set.readAt.difference(start);
      // The read time marks the end of the wait.
      expect(waited, greaterThanOrEqualTo(bound * 0.8));
      // The read bound applies, not the 3 s default or the connect bound.
      expect(waited, lessThan(const Duration(seconds: 2)));
    }
    final start = DateTime.now();
    final set = await _expectEmpty(reader, refused);
    expect(set.readAt.difference(start), lessThan(const Duration(seconds: 2)));

    final defaults = OneVpnObservatoryReader();
    expect(defaults.connectTimeout, const Duration(seconds: 2));
    expect(defaults.readTimeout, const Duration(seconds: 3));
  });

  test('a malformed body answers empty', () async {
    final valid = _alive('app-cand-acct-1', 90);
    final bodies = <Object>[
      'not json',
      '[]',
      jsonEncode({'observatory': []}),
      _metrics({'app-cand-acct-1': null}),
      _metrics({
        'app-cand-acct-1': {...valid, 'alive': 'true'},
      }),
      _metrics({
        'app-cand-acct-1': {...valid, 'delay': 90.5},
      }),
      _metrics({
        'app-cand-acct-1': {...valid, 'delay': -1},
      }),
      _metrics({
        'app-cand-acct-1': {...valid, 'health_ping': []},
      }),
      _metrics({
        'app-cand-acct-1': valid,
        'app-cand-acct-2': {
          ...valid,
          'health_ping': {'all': 1, 'fail': '0'},
        },
      }),
      [0x7b, 0xff, 0x7d],
    ];

    for (final body in bodies) {
      await _expectEmpty(OneVpnObservatoryReader(), await _serveBody(body));
    }
  });
}

/// The `stats` value of an idle core.
const _stats = {'inbound': {}, 'outbound': {}, 'user': {}};

/// A metrics body whose `observatory` value is [observatory].
String _metrics(Map<String, Object?> observatory) => jsonEncode({
  'cmdline': ['xray'],
  'stats': _stats,
  'observatory': observatory,
});

/// The alive entry of [tag] as the core encodes it. [delay] is in
/// milliseconds.
Map<String, Object?> _alive(
  String tag,
  int delay, {
  int all = 1,
  int fail = 0,
}) => {
  'alive': true,
  'delay': delay,
  'outbound_tag': tag,
  'health_ping': {
    'all': all,
    if (fail > 0) 'fail': fail,
    'average': delay * 1000000,
    'max': delay * 1000000,
    'min': delay * 1000000,
  },
};

/// Starts a loopback server that hands each request to [handle] and answers
/// its port. The test's teardown closes it.
Future<int> _serve(void Function(HttpRequest request) handle) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  addTearDown(() => server.close(force: true));
  server.listen(handle);
  return server.port;
}

/// Starts a loopback server that answers every request with [body] and
/// [status]. A list body goes out as raw bytes.
Future<int> _serveBody(Object body, {int status = HttpStatus.ok}) =>
    _serve((request) => _reply(request, body, status: status));

void _reply(HttpRequest request, Object body, {int status = HttpStatus.ok}) {
  request.response
    ..statusCode = status
    ..headers.contentType = ContentType.json;
  if (body is List<int>) {
    request.response.add(body);
  } else {
    request.response.write(body);
  }
  // The close fails when the reader hangs up first, as on an oversized body.
  request.response.close().ignore();
}

/// Reads [port] with [reader] and expects an empty set read during the call.
Future<OneVpnObservationSet> _expectEmpty(
  OneVpnObservatoryReader reader,
  int port,
) async {
  final before = DateTime.now();
  final set = await reader.read(port);
  final after = DateTime.now();
  expect(set.byTag, isEmpty);
  expect(set.readAt.isBefore(before), isFalse);
  expect(set.readAt.isAfter(after), isFalse);
  return set;
}
