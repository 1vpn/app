// The fork router opened on the launch paywall. The location is set before
// the first read of the router, as the entry point does on a due launch.

import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/shell/router.dart';
import 'package:onexray/onevpn/shell/routes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a due launch starts on the paywall stacked over connect', () {
    OneVpnRouter.initialLocation = kOneVpnPaywallRoute;
    final start = OneVpnRouter.router.routeInformationProvider.value.uri;

    expect(start.path, kOneVpnPaywallRoute);
    final match = OneVpnRouter.router.configuration.findMatch(start);
    expect(match.isError, isFalse);
    expect(match.matches.map((m) => m.matchedLocation).toList(), [
      kOneVpnConnectRoute,
      kOneVpnPaywallRoute,
    ]);
  });
}
