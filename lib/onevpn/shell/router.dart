import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/account/sign_in_page.dart';
import 'package:onexray/onevpn/location/location_picker_page.dart';
import 'package:onexray/onevpn/paywall/paywall_page.dart';
import 'package:onexray/onevpn/paywall/upgrade_funnel.dart';
import 'package:onexray/onevpn/purchase/purchase_backend.dart';
import 'package:onexray/onevpn/routing/direct_regions_page.dart';
import 'package:onexray/onevpn/shell/always_on.dart';
import 'package:onexray/onevpn/shell/edge_route.dart';
import 'package:onexray/onevpn/shell/first_connect_explainer.dart';
import 'package:onexray/onevpn/shell/language_page.dart';
import 'package:onexray/onevpn/shell/menu.dart';
import 'package:onexray/onevpn/shell/routes.dart';
import 'package:onexray/onevpn/shell/shell.dart';
import 'package:onexray/onevpn/shell/support_page.dart';
import 'package:onexray/service/connect/settings.dart';

/// The fork router. It serves one root screen, the connect shell, on every
/// platform. These surfaces push over it: the Support page, the location
/// picker, the Direct-regions picker, the paywall, the dual-mode sign-in
/// surface, and the menu surfaces.
///
/// `/location` takes an optional [ServerSelection] through
/// `GoRouterState.extra`: the selection the picker opens on.
///
/// `/direct-regions` takes an optional [OneVpnStackedEdge] through
/// `GoRouterState.extra`: the edge the page comes from.
///
/// `/sign-in` takes an optional [OneVpnSignInArgs] through
/// `GoRouterState.extra`. The paywall funnel opens it in sign-up mode with a
/// prefilled and locked email, from the bottom edge. A push with no extra opens
/// log-in with no prefill, from the top edge.
///
/// The paywall gets a fresh [OneVpnUpgradeFunnel] per push. The funnel holds
/// the activation it started, which must not carry over from a previous visit.
///
/// `/menu` takes an optional account listenable through `GoRouterState.extra`:
/// the account the menu renders.
///
/// The menu and every page pushed over it or over connect are
/// [OneVpnEdgePage]s. The menu is a drawer from the top edge. Stacked, an edge
/// page comes from the edge of its entry point. When the menu opens them,
/// Support, Direct regions, sign-in, the language picker, and the always-on
/// guide slide from the drawer's top edge. The paywall, the location picker,
/// and the first-connect explainer slide up from the bottom. So do Direct
/// regions opened from connect's route indicator or the first-connect
/// explainer, and sign-up opened from the paywall. In split, every edge page
/// comes from the end edge.
///
/// The router opens on [initialLocation] whatever route the platform reports at
/// launch.
///
/// The paywall nests under the connect shell. A launch that opens on the
/// paywall stacks it over the connect shell, so closing it lands on connect. A
/// push of the paywall stacks it over the current route.
abstract final class OneVpnRouter {
  /// The location the router opens on. Must be set before the first read of
  /// [router]: the router reads it once, when it is built.
  static String initialLocation = kOneVpnConnectRoute;

  static final router = GoRouter(
    initialLocation: initialLocation,
    // A platform route, such as a launch intent extra, never picks the
    // first screen.
    overridePlatformDefaultLocation: true,
    routes: [
      GoRoute(
        path: kOneVpnConnectRoute,
        builder: (_, _) => const OneVpnShell(),
        routes: [
          // A child path is relative: the route without its leading slash.
          GoRoute(
            path: kOneVpnPaywallRoute.substring(1),
            pageBuilder: (_, state) => OneVpnEdgePage.fromBottom(
              key: state.pageKey,
              child: OneVpnPaywallPage(
                service: oneVpnPurchaseBackend(),
                onPurchaseComplete: OneVpnUpgradeFunnel().completePurchase,
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: kOneVpnSupportRoute,
        pageBuilder: (_, state) => OneVpnEdgePage.menuDetail(
          key: state.pageKey,
          child: const OneVpnSupportPage(),
        ),
      ),
      GoRoute(
        path: kOneVpnLocationRoute,
        pageBuilder: (_, state) => OneVpnEdgePage.fromBottom(
          key: state.pageKey,
          child: OneVpnLocationPickerPage(
            initialSelection: state.extra is ServerSelection
                ? state.extra as ServerSelection
                : null,
          ),
        ),
      ),
      GoRoute(
        path: kOneVpnDirectRegionsRoute,
        pageBuilder: (_, state) => OneVpnEdgePage(
          key: state.pageKey,
          stackedEdge: directRegionsEdge(state.extra),
          child: const OneVpnDirectRegionsPage(),
        ),
      ),
      GoRoute(
        path: kOneVpnSignInRoute,
        pageBuilder: (_, state) {
          final args = state.extra is OneVpnSignInArgs
              ? state.extra as OneVpnSignInArgs
              : null;
          return OneVpnEdgePage(
            key: state.pageKey,
            stackedEdge: args?.edge ?? OneVpnStackedEdge.top,
            child: OneVpnSignInPage(
              initialMode: args?.mode ?? OneVpnSignInMode.logIn,
              initialEmail: args?.email ?? '',
              lockEmail: args?.lockEmail ?? false,
            ),
          );
        },
      ),
      ...menuSurfaces(),
    ],
  );

  /// The stacked edge a Direct-regions push names in its extra, an
  /// [OneVpnStackedEdge]. A push that names none comes from the menu
  /// drawer's top edge.
  static OneVpnStackedEdge directRegionsEdge(Object? extra) =>
      extra is OneVpnStackedEdge ? extra : OneVpnStackedEdge.top;

  /// The menu, the language picker, the always-on guide, and the
  /// first-connect explainer. Each stands alone over the root.
  static List<GoRoute> menuSurfaces() => [
    GoRoute(
      path: kOneVpnMenuRoute,
      pageBuilder: (_, state) => OneVpnEdgePage.drawer(
        key: state.pageKey,
        child: OneVpnMenu(
          account: state.extra is ValueListenable<OneVpnAccountState>
              ? state.extra as ValueListenable<OneVpnAccountState>
              : OneVpnAccountService.instance.state,
        ),
      ),
    ),
    GoRoute(
      path: kOneVpnLanguageRoute,
      pageBuilder: (_, state) => OneVpnEdgePage.menuDetail(
        key: state.pageKey,
        child: const OneVpnLanguagePage(),
      ),
    ),
    GoRoute(
      path: kOneVpnAlwaysOnRoute,
      pageBuilder: (_, state) => OneVpnEdgePage.menuDetail(
        key: state.pageKey,
        child: const OneVpnAlwaysOnPage(),
      ),
    ),
    GoRoute(
      path: kOneVpnFirstConnectRoute,
      pageBuilder: (_, state) => OneVpnEdgePage.fromBottom(
        key: state.pageKey,
        child: const OneVpnFirstConnectPage(),
      ),
    ),
  ];
}
