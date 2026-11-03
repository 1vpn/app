import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/app/platform_channel.dart';

/// Answers the fork channel's `tunnelHeld` with [held] for the whole test
/// body, and every other method with not-implemented. An unanswered
/// channel call completes outside the widget test clock. A connect or a
/// change that reads the shared held signal would then never finish.
void stubHeldTunnelChannel({bool held = false}) {
  const channel = MethodChannel(OneVpnPlatformChannel.name);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(channel, (call) async {
    if (call.method == 'tunnelHeld') return held;
    throw MissingPluginException();
  });
  addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
}
