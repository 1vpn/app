import 'dart:convert';
import 'dart:io' show HttpClient, HttpException, HttpStatus;
import 'dart:typed_data';

import 'package:onexray/onevpn/connect/native_auto_contracts.dart';

/// Reads a running core's observatory from its loopback metrics endpoint.
///
/// A read sends one GET to `http://127.0.0.1:<port>/debug/vars`. It uses no
/// proxy and follows no redirect. [connectTimeout] bounds the connect.
/// [readTimeout] bounds the wait for the headers and each wait for a body
/// chunk.
///
/// A failed read answers an empty set. A read fails when a timeout expires
/// or the body passes 1 MiB. It also fails on a refused connect or a status
/// other than 200. A malformed body and a port outside 1 to 65535 fail it
/// too.
class OneVpnObservatoryReader implements OneVpnObservatorySource {
  OneVpnObservatoryReader({
    this.connectTimeout = const Duration(seconds: 2),
    this.readTimeout = const Duration(seconds: 3),
  });

  /// The longest wait for the connect to the metrics endpoint.
  final Duration connectTimeout;

  /// The longest wait for the response headers, and then for each body chunk.
  final Duration readTimeout;

  static const _maximumBytes = 1048576;

  /// Reads the observatory of the core whose metrics endpoint listens on
  /// loopback [port].
  ///
  /// The set holds one observation per key of the body's `observatory`
  /// object. The key is the tag. A missing or null `observatory` value
  /// answers an empty set. The core omits a false `alive` and every zero
  /// number. An absent `alive` reads false. An absent `delay`, `all` or
  /// `fail` reads 0. A field of another type or a negative number makes the
  /// body malformed. One malformed entry fails the whole read.
  ///
  /// [OneVpnObservationSet.readAt] is the time the read finished, failed or
  /// not.
  @override
  Future<OneVpnObservationSet> read(int port) async {
    Map<String, OneVpnObservation> byTag;
    try {
      byTag = _observations(await _body(port));
    } on Exception {
      byTag = const {};
    }
    return OneVpnObservationSet(byTag: byTag, readAt: DateTime.now());
  }

  Future<Object?> _body(int port) async {
    if (port < 1 || port > 65535) {
      throw const FormatException('Invalid metrics port');
    }
    final client = HttpClient()
      ..connectionTimeout = connectTimeout
      ..findProxy = (_) => 'DIRECT';
    try {
      final request = await client.getUrl(
        Uri(scheme: 'http', host: '127.0.0.1', port: port, path: '/debug/vars'),
      );
      request.followRedirects = false;
      final response = await request.close().timeout(readTimeout);
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('Metrics status ${response.statusCode}');
      }
      final bytes = BytesBuilder(copy: false);
      await for (final chunk in response.timeout(readTimeout)) {
        bytes.add(chunk);
        if (bytes.length > _maximumBytes) {
          throw const FormatException('Metrics body over 1 MiB');
        }
      }
      return jsonDecode(utf8.decode(bytes.takeBytes()));
    } finally {
      client.close(force: true);
    }
  }

  static Map<String, OneVpnObservation> _observations(Object? body) {
    if (body is! Map<String, dynamic>) {
      throw const FormatException('Metrics body is not an object');
    }
    final observatory = body['observatory'];
    if (observatory == null) return const {};
    if (observatory is! Map<String, dynamic>) {
      throw const FormatException('Observatory is not an object');
    }
    return {
      for (final MapEntry(key: tag, :value) in observatory.entries)
        tag: _observation(tag, value),
    };
  }

  static OneVpnObservation _observation(String tag, Object? entry) {
    if (entry is! Map<String, dynamic>) {
      throw const FormatException('Observatory entry is not an object');
    }
    final ping = entry['health_ping'] ?? const <String, dynamic>{};
    if (ping is! Map<String, dynamic>) {
      throw const FormatException('Health ping is not an object');
    }
    return OneVpnObservation(
      tag: tag,
      alive: _flag(entry['alive']),
      delayMs: _count(entry['delay']),
      all: _count(ping['all']),
      fail: _count(ping['fail']),
    );
  }

  static bool _flag(Object? value) => switch (value) {
    null => false,
    final bool flag => flag,
    _ => throw const FormatException('Invalid observatory flag'),
  };

  static int _count(Object? value) => switch (value) {
    null => 0,
    final int count when count >= 0 => count,
    _ => throw const FormatException('Invalid observatory number'),
  };
}
