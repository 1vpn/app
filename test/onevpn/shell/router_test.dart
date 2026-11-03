// The fork router's route tree. The paywall nests under the connect shell,
// so a launch that opens on the paywall stacks it over connect. The menu,
// the always-on guide, and the first-connect explainer stand alone over the
// root.
//
// Stacked, a page comes from the edge of its entry point. Menu pages come
// from the top edge. The location picker comes from the bottom. Direct
// regions and sign-in come from the edge their push names, and from the top
// when it names none. Each reads only its own extra type. Direct regions
// reads an edge, and sign-in reads the edge inside its args.

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/onevpn/account/sign_in_page.dart';
import 'package:onexray/onevpn/shell/edge_route.dart';
import 'package:onexray/onevpn/shell/router.dart';
import 'package:onexray/onevpn/shell/routes.dart';

import '../support/viewports.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the router opens on connect by default', () {
    expect(OneVpnRouter.initialLocation, kOneVpnConnectRoute);
  });

  test('the paywall location stacks the paywall over the connect shell', () {
    final match = OneVpnRouter.router.configuration.findMatch(
      Uri.parse(kOneVpnPaywallRoute),
    );
    expect(match.isError, isFalse);
    expect(match.matches.map((m) => m.matchedLocation).toList(), [
      kOneVpnConnectRoute,
      kOneVpnPaywallRoute,
    ]);
  });

  test('every other surface stands alone over the root', () {
    for (final location in [
      kOneVpnSupportRoute,
      kOneVpnLocationRoute,
      kOneVpnDirectRegionsRoute,
      kOneVpnSignInRoute,
      kOneVpnMenuRoute,
      kOneVpnLanguageRoute,
      kOneVpnAlwaysOnRoute,
      kOneVpnFirstConnectRoute,
    ]) {
      final match = OneVpnRouter.router.configuration.findMatch(
        Uri.parse(location),
      );
      expect(match.isError, isFalse, reason: location);
      expect(match.matches.map((m) => m.matchedLocation).toList(), [
        location,
      ], reason: location);
    }
  });

  testWidgets('each page comes from the edge of its entry point', (
    tester,
  ) async {
    await setViewport(tester, kPortraitViewport);
    await tester.pumpWidget(const SizedBox());
    final context = tester.element(find.byType(SizedBox));
    final configuration = OneVpnRouter.router.configuration;

    /// The stacked edge of the page [path] builds for a push with [extra].
    OneVpnStackedEdge edge(String path, [Object? extra]) {
      final route = configuration.routes.whereType<GoRoute>().firstWhere(
        (route) => route.path == path,
      );
      final page = route.pageBuilder!(
        context,
        GoRouterState(
          configuration,
          uri: Uri.parse(path),
          matchedLocation: path,
          fullPath: path,
          pathParameters: const {},
          extra: extra,
          pageKey: ValueKey(path),
        ),
      );
      return (page as OneVpnEdgePage).stackedEdge;
    }

    const top = OneVpnStackedEdge.top;
    const bottom = OneVpnStackedEdge.bottom;
    expect(edge(kOneVpnSupportRoute), top);
    expect(edge(kOneVpnLanguageRoute), top);
    expect(edge(kOneVpnAlwaysOnRoute), top);
    expect(edge(kOneVpnLocationRoute), bottom);
    expect(edge(kOneVpnDirectRegionsRoute), top);
    expect(edge(kOneVpnDirectRegionsRoute, bottom), bottom);
    expect(
      edge(
        kOneVpnDirectRegionsRoute,
        const OneVpnSignInArgs(mode: OneVpnSignInMode.signUp, edge: bottom),
      ),
      top,
    );
    expect(edge(kOneVpnSignInRoute), top);
    expect(edge(kOneVpnSignInRoute, bottom), top);
    expect(
      edge(
        kOneVpnSignInRoute,
        const OneVpnSignInArgs(mode: OneVpnSignInMode.logIn),
      ),
      top,
    );
    expect(
      edge(
        kOneVpnSignInRoute,
        const OneVpnSignInArgs(
          mode: OneVpnSignInMode.signUp,
          edge: OneVpnStackedEdge.bottom,
        ),
      ),
      bottom,
    );
  });
}
