import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/core/pigeon/messages.g.dart';

/// Answers the invoke channel with an empty success payload for the whole
/// test body. Controllers that read the xray version over the channel
/// otherwise leave the channel deadline timer pending.
void stubInvokeChannel() {
  const channel = BasicMessageChannel<Object?>(
    'dev.flutter.pigeon.onexray.BridgeHostApi.invoke',
    BridgeHostApi.pigeonChannelCodec,
  );
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockDecodedMessageHandler<Object?>(channel, (_) async {
    return <Object?>[
      jsonEncode({'success': true, 'data': {}, 'error': ''}),
    ];
  });
  addTearDown(
    () => messenger.setMockDecodedMessageHandler<Object?>(channel, null),
  );
}
