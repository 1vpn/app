// The fork router ignores the platform's launch route. A launch intent that
// names a menu surface still opens on connect, so no surface starts with
// nothing beneath it.

import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/shell/router.dart';
import 'package:onexray/onevpn/shell/routes.dart';

void main() {
  test('a platform route to the always-on guide opens on connect', () {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    // Must run before the first read of the router: it reads the platform
    // route once, when it is built.
    binding.platformDispatcher.defaultRouteNameTestValue = kOneVpnAlwaysOnRoute;
    addTearDown(binding.platformDispatcher.clearDefaultRouteNameTestValue);
    expect(binding.platformDispatcher.defaultRouteName, kOneVpnAlwaysOnRoute);

    final start = OneVpnRouter.router.routeInformationProvider.value.uri;

    expect(start.path, kOneVpnConnectRoute);
  });
}
