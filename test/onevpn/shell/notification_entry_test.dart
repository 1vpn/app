// Pins where connection-failure notifications originate and that the
// notification service never requests notification permission.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  // The tray is the one background entry that pushes a connection-failure
  // notification. The start shortcut runs the connect screen's chain. The
  // foreground connect screen surfaces a failure inline, never as an OS
  // notification, so it must not reach NotificationService.
  test('connection failure notifications stay at the tray entry', () {
    final tray = File('lib/service/shared/menu/tray/service.dart')
        .readAsStringSync();
    final connect = File('lib/onevpn/shell/connect_screen.dart')
        .readAsStringSync();

    expect(tray, contains('NotificationService().pushNotification('));
    expect(tray, contains('connectionFailureMessage('));
    expect(tray, isNot(contains('prototypeConnectionFailed')));
    expect(connect, isNot(contains('NotificationService')));
  });

  // The notification service never requests notification permission on
  // Darwin, at initialize or at push time.
  test('Darwin notification permission is never requested', () {
    final source = File('lib/service/shared/notification/service.dart')
        .readAsStringSync();

    expect(source, contains('requestAlertPermission: false'));
    expect(source, contains('requestSoundPermission: false'));
    expect(source, contains('requestBadgePermission: false'));
    expect(source, isNot(contains('requestPermissions')));
  });
}
