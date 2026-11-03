// The active-network method on the fork channel. The Dart side answers a
// handle, a VPN, or unknown, and never throws. The native side logs no
// network.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/app/platform_channel.dart';

import '../support/kotlin_source.dart';

const _nativePath =
    'android/app/src/main/kotlin/net/yuandev/onexray/onevpn/'
    'OneVpnPlatformChannel.kt';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the Dart method', () {
    const channel = MethodChannel(OneVpnPlatformChannel.name);
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      messenger.setMockMethodCallHandler(channel, null);
    });

    Future<OneVpnActiveNetwork> answer(Object? reply) {
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'activeNetwork');
        return reply;
      });
      return OneVpnPlatformChannel.activeNetwork();
    }

    test('answers the handle of a non-VPN network', () async {
      final network = await answer({'handle': 432902426637});
      expect(network.handle, 432902426637);
      expect(network.vpn, isFalse);
    });

    test('answers a VPN with no handle', () async {
      final network = await answer({'vpn': true});
      expect(network.vpn, isTrue);
      expect(network.handle, isNull);
    });

    test('answers unknown for no network or an unreadable reply', () async {
      for (final reply in [
        null,
        true,
        <String, Object?>{},
        {'handle': 'x'},
      ]) {
        final network = await answer(reply);
        expect(network.handle, isNull, reason: '$reply');
        expect(network.vpn, isFalse, reason: '$reply');
      }
    });

    test('answers unknown for an error reply', () async {
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => throw PlatformException(code: 'failed'),
      );
      final network = await OneVpnPlatformChannel.activeNetwork();
      expect(network.handle, isNull);
      expect(network.vpn, isFalse);
    });

    test('answers unknown with no handler, as on iOS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final network = await OneVpnPlatformChannel.activeNetwork();
      expect(network.handle, isNull);
      expect(network.vpn, isFalse);
    });
  });

  group('the native method', () {
    test('logs no network', () {
      for (final signature in [
        'private suspend fun activeNetwork(',
        'private suspend fun stale(',
      ]) {
        final method = normalizedKotlinMethod(_nativePath, signature);
        expect(method, isNot(contains('XLog')), reason: signature);
        expect(method, isNot(contains('Log.')), reason: signature);
      }
    });
  });
}
