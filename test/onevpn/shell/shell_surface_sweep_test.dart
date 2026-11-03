// Pins the one-screen shell shape. The fork shell has no tabs and no bottom
// navigation. No StatefulShellRoute is declared in lib, and the connect
// screen mounts neither a NavigationBar nor a bottomNavigationBar. The
// connect screen carries none of the upstream traffic-method,
// why-this-connection, or traffic-readout furniture. The launcher carries the
// start shortcut alone: no handleMobileQuickAction anywhere, and the fork
// entry boots the start shortcut and no upstream shortcut service. The
// Support page hands every row off to a hosted page. It pushes no in-app
// policy route. The sweep reads every file the two app entries reach.

import 'package:flutter_test/flutter_test.dart';

import '../support/lib_closure.dart';

void main() {
  late Map<String, String> contents;

  setUpAll(() {
    contents = {
      for (final file in libClosureSources())
        file.path: file.readAsStringSync(),
    };
  });

  test('no tabbed shell route survives in lib', () {
    // Anti-vacuity guard. The sweep reads a real tree.
    expect(contents.length, greaterThan(200));
    for (final entry in contents.entries) {
      expect(
        entry.value,
        isNot(contains('StatefulShellRoute')),
        reason: '${entry.key} reintroduces the tabbed shell route',
      );
    }
  });

  test('the connect screen mounts no bottom navigation', () {
    final connect = contents['lib/onevpn/shell/connect_screen.dart'];
    expect(connect, isNotNull, reason: 'the connect screen moved');
    expect(connect, contains('ConnectionCoordinator'));
    expect(connect, isNot(contains('NavigationBar')));
    expect(connect, isNot(contains('bottomNavigationBar')));
  });

  test('the connect screen carries no upstream connect furniture', () {
    final connect = contents['lib/onevpn/shell/connect_screen.dart']!;
    // Anti-vacuity guard. It is the real fork connect screen.
    expect(connect, contains('kOneVpnLocationRoute'));
    for (final marker in const [
      'TrafficReadout',
      'chooseTrafficMethod',
      'ConnectTrafficMethodDialog',
      'showWhy',
      'trafficMode',
    ]) {
      expect(
        connect,
        isNot(contains(marker)),
        reason: 'the connect screen reintroduces upstream furniture: $marker',
      );
    }
  });

  test('the launcher carries the start shortcut alone', () {
    for (final entry in contents.entries) {
      expect(
        entry.value,
        isNot(contains('handleMobileQuickAction')),
        reason: '${entry.key} reintroduces the quick-action handler',
      );
    }
    final steps = contents['lib/main_1vpn.dart']!;
    expect(steps, isNot(contains('ShortCutService')));
    expect(steps, contains('OneVpnStartShortcut.instance.initialize'));
  });

  test('the Support page hands every row off to the hosted pages', () {
    final support = contents['lib/onevpn/shell/support_page.dart'];
    expect(support, isNotNull, reason: 'the Support page moved');
    // Every link row hands its URL to the browser. The privacy row opens
    // the hosted policy, never an in-app render or a policy route. The
    // Manage subscription row opens the Play subscriptions page in the
    // browser. The one other row opens the ads consent platform's privacy
    // options form.
    for (final url in const [
      'privacyPolicy',
      'faq',
      'termsOfService',
      'contactUs',
      'refundPolicy',
    ]) {
      expect(
        support,
        contains('() => openExternalLink(context, OneVpnLinks.$url),'),
        reason: url,
      );
    }
    expect(
      support,
      contains(
        '() => openExternalLink(context, OneVpnStoreLinks.playSubscriptions),',
      ),
    );
    expect('openExternalLink('.allMatches(support!).length, 6);
    expect(support, contains('gate.showPrivacyOptions,'));
    expect('onTap:'.allMatches(support).length, 1);
    expect(support, isNot(contains('kOneVpnPrivacyRoute')));
    expect(support, isNot(contains('BundledPolicyPage')));
    expect(support, isNot(contains('context.push')));
  });
}
