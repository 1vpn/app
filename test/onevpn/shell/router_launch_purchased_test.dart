// The fork router opened on the purchased screen. The location and the extra
// are set before the first read of the router, as the entry point does on a
// launch with a purchase that waits for an account. The paywall route builds
// a page that carries the address from its extra.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:onexray/onevpn/shell/edge_route.dart';
import 'package:onexray/onevpn/shell/router.dart';
import 'package:onexray/onevpn/shell/routes.dart';

const _buyer = 'buyer@example.invalid';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the launch opens the paywall over connect with the address', () {
    OneVpnRouter.initialLocation = kOneVpnPaywallRoute;
    OneVpnRouter.initialExtra = _buyer;
    final start = OneVpnRouter.router.routeInformationProvider.value;

    expect(start.uri.path, kOneVpnPaywallRoute);
    expect((start.state! as RouteInformationState<void>).extra, _buyer);
    final match = OneVpnRouter.router.configuration.findMatch(start.uri);
    expect(match.matches.map((m) => m.matchedLocation).toList(), [
      kOneVpnConnectRoute,
      kOneVpnPaywallRoute,
    ]);
  });

  test('the paywall route opens the purchased screen for the address', () {
    // The route builds its page through this static, so the launch extra
    // reaches the page here.
    expect(OneVpnRouter.paywallFor(_buyer).purchased, _buyer);
    expect(OneVpnRouter.paywallFor(null).purchased, isNull);
    expect(OneVpnRouter.paywallFor('').purchased, isNull);
    expect(
      File('lib/onevpn/shell/router.dart').readAsStringSync(),
      contains('child: paywallFor(state.extra)'),
    );
  });

  test('only a non-empty address opens the purchased screen', () {
    expect(OneVpnRouter.purchasedAddress(_buyer), _buyer);
    expect(OneVpnRouter.purchasedAddress(''), isNull);
    expect(OneVpnRouter.purchasedAddress(null), isNull);
    expect(OneVpnRouter.purchasedAddress(OneVpnStackedEdge.top), isNull);
  });
}
