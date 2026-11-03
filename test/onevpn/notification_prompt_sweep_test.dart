// Pins the notification ask to the connect tap chain. Only the prompt and
// the connect screen name the prompt or the plugin request. A Connect tap and
// a start-shortcut launch from the tile reach the ask through that chain.
// Connect-on-launch and always-on never reach it. The sweep reads every file
// the two app entries reach.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/lib_closure.dart';

/// The identifiers that reach the notification ask.
const _tokens = ['OneVpnNotificationPrompt', 'requestNotificationsPermission'];

/// The only files that may name a token. A new entry is a new place the ask
/// can fire. It lands here with the decision behind it.
const _allowed = {
  'lib/onevpn/shell/notification_prompt.dart',
  'lib/onevpn/shell/connect_screen.dart',
};

void main() {
  final sources = libClosureSources();

  test('the sweep sees the tree it guards', () {
    // A floor and known files guard against a silently empty walk. The
    // positive matches prove that reads return file content.
    expect(sources.length, greaterThan(100));
    final paths = sources.map((file) => file.path).toSet();
    expect(paths, containsAll(_allowed));
    expect(paths, contains('lib/service/launch/app_startup.dart'));
    expect(
      File('lib/onevpn/shell/notification_prompt.dart').readAsStringSync(),
      contains('requestNotificationsPermission'),
    );
    expect(
      File('lib/onevpn/shell/connect_screen.dart').readAsStringSync(),
      contains('OneVpnNotificationPrompt'),
    );
  });

  test('only the prompt and the connect screen reach the ask', () {
    final violations = <String>[];
    for (final file in sources) {
      if (_allowed.contains(file.path)) continue;
      final source = file.readAsStringSync();
      for (final token in _tokens) {
        if (source.contains(token)) {
          violations.add('${file.path}: $token');
        }
      }
    }
    expect(violations, isEmpty);
  });
}
