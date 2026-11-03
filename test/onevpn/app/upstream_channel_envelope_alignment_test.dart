// Pins the upstream shapes ChannelDeadlineMessenger copies. On expiry the
// messenger answers a bounded bridge call itself. Its answer is pigeon's
// success envelope around AppHostApi's failed value. A failure here means an
// upstream bump or a pigeon regeneration changed a copied shape. Re-check the
// expiry values in lib/onevpn/app/channel_deadlines.dart against the new
// upstream text. Then update the pinned shapes.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/app/channel_deadlines.dart';

const _hostApi = 'lib/core/pigeon/host_api.dart';
const _messages = 'lib/core/pigeon/messages.g.dart';

const _realign =
    'upstream changed: re-check the expiry values in '
    'lib/onevpn/app/channel_deadlines.dart';

/// The declaration in [path] whose first line starts with [signature] after
/// its indentation. It runs from the signature through the closing brace at
/// that indentation. Comment lines are dropped, and whitespace runs collapse
/// to single spaces. Formatting cannot move the pin. Statements can.
String _normalizedDeclaration(String path, String signature) {
  final lines = File(path).readAsLinesSync();
  final start = lines.indexWhere(
    (line) => line.trimLeft().startsWith(signature),
  );
  expect(start, isNot(-1), reason: '$path lacks $signature');
  final indent = lines[start].length - lines[start].trimLeft().length;
  final close = '${' ' * indent}}';
  final body = <String>[];
  for (var index = start; index < lines.length; index++) {
    final line = lines[index];
    if (RegExp(r'^\s*//').hasMatch(line)) {
      continue;
    }
    body.add(line);
    if (line == close) {
      return body.join('\n').replaceAll(RegExp(r'\s+'), ' ').trim();
    }
  }
  fail('$path: $signature never closes at its own indentation');
}

/// Upstream AppHostApi._platformPermissionFailed, normalized.
const _pinnedPermissionFailed =
    r'''PlatformPermissionResult _platformPermissionFailed([String? '''
    r'''message]) { return PlatformPermissionResult( kind: '''
    r'''PlatformPermissionKind.none, state: '''
    r'''PlatformPermissionState.failed, message: message, ); }''';

/// Upstream AppHostApi._commandFailed, normalized.
const _pinnedCommandFailed =
    r'''NativeVpnCommandResult _commandFailed([String? message]) { return '''
    r'''NativeVpnCommandResult( state: NativeVpnCommandState.failed, '''
    r'''permission: _platformPermissionFailed(), message: message, ); }''';

/// Pigeon's reply read, normalized. A one-element list is the success
/// envelope, and its element is the returned value.
const _pinnedReplyEnvelope =
    r'''Object? _extractReplyValueOrThrow( List<Object?>? replyList, '''
    r'''String channelName, { required bool isNullValid, }) { if '''
    r'''(replyList == null) { throw PlatformException( code: '''
    r''''channel-error', message: 'Unable to establish connection on '''
    r'''channel: "$channelName".', ); } else if (replyList.length > 1) { '''
    r'''throw PlatformException( code: replyList[0]! as String, message: '''
    r'''replyList[1] as String?, details: replyList[2], ); } else if '''
    r'''(!isNullValid && (replyList.isNotEmpty && replyList[0] == null)) '''
    r'''{ throw PlatformException( code: 'null-error', message: 'Host '''
    r'''platform returned null value for non-null return value.', ); } '''
    r'''return replyList.firstOrNull; }''';

/// The return type each bounded client method casts its reply value to.
const _boundedReturnTypes = {
  'readVpnStatus': 'NativeVpnCommandResult',
  'startVpn': 'NativeVpnCommandResult',
  'stopVpn': 'NativeVpnCommandResult',
  'invoke': 'String',
};

void main() {
  test('upstream failed results keep their pinned shape', () {
    final permission = _normalizedDeclaration(
      _hostApi,
      'PlatformPermissionResult _platformPermissionFailed(',
    );
    final command = _normalizedDeclaration(
      _hostApi,
      'NativeVpnCommandResult _commandFailed(',
    );
    // Anti-vacuity guard. The extraction produced whole methods.
    expect(permission, contains('PlatformPermissionState.failed'));
    expect(command, contains('NativeVpnCommandState.failed'));

    expect(permission, _pinnedPermissionFailed, reason: _realign);
    expect(command, _pinnedCommandFailed, reason: _realign);
  });

  test('the pigeon reply envelope keeps its pinned shape', () {
    final envelope = _normalizedDeclaration(
      _messages,
      'Object? _extractReplyValueOrThrow(',
    );
    expect(envelope, contains('return replyList.firstOrNull;'));
    expect(envelope, _pinnedReplyEnvelope, reason: _realign);
  });

  test('each bounded operation is a default-channel pigeon host call', () {
    // A channel suffix renames every channel. The messenger then bounds none.
    expect(
      File(_hostApi).readAsStringSync(),
      contains('final _api = BridgeHostApi();'),
      reason: _realign,
    );
    expect(
      ChannelDeadlineMessenger.boundedOperations,
      unorderedEquals(_boundedReturnTypes.keys),
    );
    for (final MapEntry(key: operation, value: type)
        in _boundedReturnTypes.entries) {
      final client = _normalizedDeclaration(
        _messages,
        'Future<$type> $operation(',
      );
      expect(
        client,
        contains(
          "'${ChannelDeadlineMessenger.channelPrefix}$operation"
          "\$pigeonVar_messageChannelSuffix'",
        ),
        reason: _realign,
      );
      expect(
        client,
        contains('await pigeonVar_sendFuture as List<Object?>?;'),
        reason: _realign,
      );
      expect(
        client,
        contains(
          '_extractReplyValueOrThrow( pigeonVar_replyList, '
          'pigeonVar_channelName, isNullValid: false, );',
        ),
        reason: _realign,
      );
      expect(
        client,
        contains('return pigeonVar_replyValue! as $type;'),
        reason: _realign,
      );
    }
  });
}
