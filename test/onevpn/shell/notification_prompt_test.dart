// The notification prompt asks once, at the first connect tap. It stamps the
// fork flag once the request returns an answer, so later taps never ask. A
// null answer or a failed request leaves the flag unstamped and never throws.
// On the connect tap the prompt runs before the held-TUN release and the VPN
// permission request, and after the first-connect explainer and the
// censorship warning. The connect follows whatever the answer.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/shell/notification_prompt.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  Future<bool?> asked() =>
      SharedPreferencesAsync().getBool(OneVpnNotificationPrompt.askedKey);

  for (final answer in [true, false]) {
    test(
      'an answer of $answer stamps the flag and later taps never ask',
      () async {
        var calls = 0;
        final prompt = OneVpnNotificationPrompt(
          request: () async {
            calls++;
            return answer;
          },
        );

        await prompt.askOnce();
        expect(calls, 1);
        expect(await asked(), isTrue);

        await prompt.askOnce();
        await OneVpnNotificationPrompt(
          request: () async {
            calls++;
            return answer;
          },
        ).askOnce();
        expect(calls, 1);
      },
    );
  }

  test('a null answer leaves the flag unstamped', () async {
    var calls = 0;
    final prompt = OneVpnNotificationPrompt(
      request: () async {
        calls++;
        return null;
      },
    );

    await prompt.askOnce();
    await prompt.askOnce();
    expect(calls, 2);
    expect(await asked(), isNull);
  });

  test('a failed request never throws and leaves the flag unstamped', () async {
    final prompt = OneVpnNotificationPrompt(
      request: () async => throw StateError('request in progress'),
    );

    await expectLater(prompt.askOnce(), completes);
    expect(await asked(), isNull);
  });

  test(
    'the connect tap runs the explainer, then the censorship warning, '
    'then the ask, before the release, the VPN permission and the connect',
    () {
      final source = File('lib/onevpn/shell/connect_screen.dart')
          .readAsStringSync();
      const anchors = [
        'await showOneVpnFirstConnectExplainer(context);',
        'await showOneVpnCensorshipWarning(context);',
        'await _notifications.askOnce();',
        'await _held.release(_coordinator);',
        'await AppHostApi().requestPlatformPermission();',
        'await _coordinator.connect();',
      ];

      // Anti-vacuity: each anchor is in the source exactly once.
      for (final anchor in anchors) {
        expect(anchor.allMatches(source).length, 1, reason: anchor);
      }
      final explainer = source.indexOf(anchors[0]);
      final warning = source.indexOf(anchors[1]);
      final ask = source.indexOf(anchors[2]);
      final release = source.indexOf(anchors[3]);
      final vpn = source.indexOf(anchors[4]);
      final connect = source.indexOf(anchors[5]);
      expect(explainer, lessThan(warning));
      expect(warning, lessThan(ask));
      expect(ask, lessThan(release));
      expect(ask, lessThan(vpn));
      expect(ask, lessThan(connect));
      expect(vpn, lessThan(connect));
    },
  );
}
