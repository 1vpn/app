// Asserts the help links open the hosted 1vpn pages and the notification
// service never asks for the notification permission. The help links come
// from the OneVpnLinks constants. The app ships no in-app policy copy: the help
// surface hands off to the hosted pages.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  // The help surface opens exactly the pages the 1vpn site serves. Each
  // is a single canonical page. OneVpnLinks holds plain constants and
  // builds no locale or docs-layout path.
  test('the help links are the four hosted 1vpn pages', () {
    final links = File('lib/onevpn/shell/links.dart').readAsStringSync();
    expect(links, contains("'https://1vpn.org/privacy-policy/'"));
    expect(links, contains("'https://1vpn.org/terms-of-service/'"));
    expect(links, contains("'https://1vpn.org/#faq'"));
    expect(links, contains("'https://1vpn.org/refund-policy/'"));
    expect(links, isNot(contains('/docs')));
    expect(links, isNot(contains('credits')));
    expect(links.toLowerCase(), isNot(contains('onexray.com')));
  });
  // The notification service never prompts, at initialize or at push time.
  // Darwin requests during initialize unless every request flag is false.
  // Darwin also requests at push time through requestPermissions, which
  // must not appear at all.
  test('the notification service never asks for notification permission', () {
    final service = File('lib/service/shared/notification/service.dart')
        .readAsStringSync();
    expect(service, isNot(contains('requestNotificationsPermission')));
    expect(service, isNot(contains('requestPermissions')));
    expect(service, contains('requestAlertPermission: false'));
    expect(service, contains('requestBadgePermission: false'));
    expect(service, contains('requestSoundPermission: false'));
  });
}
