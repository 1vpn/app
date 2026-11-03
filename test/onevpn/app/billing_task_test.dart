// The billing task methods on the fork channel. Each answers what the native
// side answers. An error reply, a channel with no handler, and every
// platform other than Android answer false. Off Android, neither method
// reaches the channel.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/app/platform_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(OneVpnPlatformChannel.name);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  /// The methods the channel received.
  late List<String> calls;

  setUp(() => calls = <String>[]);

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(channel, null);
  });

  /// A native side that answers [reply] to every call.
  void answer(Object? Function() reply) {
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return reply();
    });
  }

  for (final (name, method) in <(String, Future<bool> Function())>[
    ('restoreBillingTask', OneVpnPlatformChannel.restoreBillingTask),
    ('finishBillingTasks', OneVpnPlatformChannel.finishBillingTasks),
  ]) {
    group(name, () {
      test('answers true when the native side found a billing task', () async {
        answer(() => true);

        expect(await method(), isTrue);
        expect(calls, [name]);
      });

      test('answers false when the native side found none', () async {
        answer(() => false);

        expect(await method(), isFalse);
        expect(calls, [name]);
      });

      test('answers false for an error reply', () async {
        answer(() => throw PlatformException(code: 'failed'));

        expect(await method(), isFalse);
        expect(calls, [name]);
      });

      test('answers false with no handler', () async {
        // No mock handler: the call meets a MissingPluginException.
        expect(await method(), isFalse);
      });

      for (final platform in TargetPlatform.values.where(
        (platform) => platform != TargetPlatform.android,
      )) {
        test('on ${platform.name}, answers false with no call', () async {
          debugDefaultTargetPlatformOverride = platform;
          answer(() => true);

          expect(await method(), isFalse);
          expect(calls, isEmpty);
        });
      }
    });
  }
}
