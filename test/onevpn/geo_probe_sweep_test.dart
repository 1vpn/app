// Pins the geolocation strip. No file the two app entries reach targets the
// Cloudflare geo endpoint. A ping batch request leaves without a location
// URL. The sweep fails when a geolocation probe returns through an upstream
// merge.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/core/pigeon/messages.g.dart';
import 'package:onexray/onevpn/net/probe_endpoints.dart';
import 'package:onexray/service/shared/ping/batch.dart';
import 'package:onexray/service/shared/ping/state.dart';

import 'support/lib_closure.dart';

/// Source strings only the removed geolocation surfaces contain. `geoIPUrl`
/// is the endpoint constant. `suggestRegion` is the setup probe entry point.
const _banned = [
  'ip-check-perf.radar.cloudflare.com',
  'geoIPUrl',
  'suggestRegion',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final sources = libClosureSources();

  test('the sweep sees the tree it guards', () {
    // A floor and known files guard against a silently empty walk. The
    // positive match proves reads return file content.
    expect(sources.length, greaterThan(100));
    final paths = sources.map((file) => file.path).toSet();
    expect(paths, contains('lib/service/launch/app_startup.dart'));
    expect(paths, contains('lib/service/shared/ping/batch.dart'));
    expect(
      File('lib/service/shared/ping/batch.dart').readAsStringSync(),
      contains('PingBatchRequest('),
    );
  });

  test('no geolocation endpoint or probe entry point in lib', () {
    final violations = <String>[];
    for (final file in sources) {
      final source = file.readAsStringSync();
      for (final banned in _banned) {
        if (source.contains(banned)) {
          violations.add('${file.path}: $banned');
        }
      }
    }
    expect(violations, isEmpty);
  });

  test('the batch runner builds requests without a location URL', () {
    final source = File('lib/service/shared/ping/batch.dart')
        .readAsStringSync();
    // The positive match proves the request construction is still here. The
    // negative match pins that no field on it carries a location URL.
    expect(source, contains('PingBatchRequest('));
    expect(source, isNot(contains('locationUrl')));
  });

  test(
    'a ping batch request leaves the bridge without a location URL',
    () async {
      const channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.onexray.BridgeHostApi.invoke',
        BridgeHostApi.pigeonChannelCodec,
      );
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final payloads = <Map<String, dynamic>>[];
      messenger.setMockDecodedMessageHandler(channel, (request) async {
        final json = jsonDecode(
          (request as List).single as String,
        ) as Map<String, dynamic>;
        expect(json['method'], 'pingBatch');
        payloads.add(json['payload'] as Map<String, dynamic>);
        return [
          jsonEncode({
            'success': true,
            'data': {
              'results': [
                {'success': true, 'delay': 10},
              ],
            },
            'error': '',
          }),
        ];
      });
      addTearDown(() => messenger.setMockDecodedMessageHandler(channel, null));

      final state = PingState();
      final results = await PingBatchRunner.run(const [
        PingBatchSource('{"outbounds":[]}'),
      ], state);

      expect(results.single.success, isTrue);
      final payload = payloads.single;
      // The URL proves the captured payload is the real request body.
      expect(payload['url'], ProbeEndpoints.urls.first);
      expect(payload.containsKey('locationUrl'), isFalse);
    },
    skip: !(Platform.isMacOS || Platform.isIOS || Platform.isAndroid),
  );
}
