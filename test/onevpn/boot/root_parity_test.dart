// Pins the fork root and router shape. The fork root mounts the fork
// router and carries the 1VPN title. The fork router serves the one-screen
// connect shell at its initial location. It declares these routes over the
// shell: the Support page, the location picker, the Direct-regions picker,
// the paywall, and the sign-in surface. The fork root mirrors no upstream
// root widget. No tabbed shell route returns.
//
// The initial location is connect. Only the entry point overrides it, with
// the paywall on a due launch.
//
// Two route arguments carry the purchase funnel: the paywall's handoff into
// the funnel, and the sign-in route's locked-email argument. The funnel
// suite builds its own routes, so the real ones are pinned here.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/lib_closure.dart';

void main() {
  test('the fork root mounts the fork router and drops the retired one', () {
    final app = File('lib/onevpn/app/app.dart').readAsStringSync();

    // Anti-vacuity guard. The read returned the real root widget.
    expect(app, contains('class OneVpnApp'));

    expect(app, contains('routerConfig: OneVpnRouter.router'));
    expect(app, contains('title: "1VPN"'));
    expect(app, isNot(contains('RouterPath')));
  });

  test('the fork router serves the one-screen shell and its seams', () {
    final router = File('lib/onevpn/shell/router.dart').readAsStringSync();

    // Anti-vacuity guard. The read returned the real router.
    expect(router, contains('GoRouter('));

    expect(
      router,
      contains('static String initialLocation = kOneVpnConnectRoute'),
    );
    expect(router, contains('initialLocation: initialLocation'));
    expect(router, contains('OneVpnShell()'));
    expect(router, contains('OneVpnSupportPage()'));
    expect(router, contains('OneVpnLocationPickerPage('));
    expect(
      router,
      contains('initialSelection: state.extra is ServerSelection'),
    );
    expect(router, contains('OneVpnPaywallPage('));
    expect(router, contains('OneVpnSignInPage('));
    // No tabbed shell route returns.
    expect(router, isNot(contains('StatefulShellRoute')));
  });

  test('only the entry point sets the initial location', () {
    final setters = [
      for (final file in libClosureSources())
        if (file.readAsStringSync().contains('OneVpnRouter.initialLocation ='))
          file.path,
    ];
    expect(setters, ['lib/main_1vpn.dart']);
  });

  test('the router wires the paywall into the purchase funnel', () {
    final router = File('lib/onevpn/shell/router.dart').readAsStringSync();

    // The paywall runs against the build's selected backend, and a
    // confirmed purchase hands off to the funnel. A paywall built without
    // the handoff would buy and then dismiss, granting nothing.
    expect(router, contains('service: oneVpnPurchaseBackend()'));
    expect(
      router,
      contains('onPurchaseComplete: OneVpnUpgradeFunnel().completePurchase'),
    );
  });

  test('the sign-in route carries the locked-email argument', () {
    final router = File('lib/onevpn/shell/router.dart').readAsStringSync();

    // The funnel pushes sign-up with the address the purchase was made
    // against and locks it. A route that dropped the flag would let the
    // buyer change the address and strand the purchase.
    expect(router, contains('initialMode: args?.mode ?? OneVpnSignInMode'));
    expect(router, contains("initialEmail: args?.email ?? ''"));
    expect(router, contains('lockEmail: args?.lockEmail ?? false'));
  });
}
