// The fork router's paths. The connect shell is the root. Every other surface
// pushes over it.

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// The one-screen connect shell. It is the router's default initial location.
const kOneVpnConnectRoute = '/';

/// The fork Support page: the FAQ, Contact Us, the privacy policy, the
/// terms, and the refund policy.
const kOneVpnSupportRoute = '/support';

/// The location picker. The connect screen's location row pushes here.
const kOneVpnLocationRoute = '/location';

/// The Direct-regions picker. The connect screen's Direct-regions control
/// pushes here. It is the app's only routing surface.
const kOneVpnDirectRegionsRoute = '/direct-regions';

/// The paywall. The upgrade banner and the menu's Upgrade push here.
const kOneVpnPaywallRoute = '/paywall';

/// The sign-in surface. The menu's Log in and Sign up push here.
const kOneVpnSignInRoute = '/sign-in';

/// The menu. The hamburger pushes here. Stacked, it is a drawer from the top
/// edge. Split, it is a drawer over the end pane.
const kOneVpnMenuRoute = '/menu';

/// The language picker, a full page. The menu's Language row pushes here.
const kOneVpnLanguageRoute = '/language';

/// The always-on VPN guide, a full page. The menu's always-on row pushes
/// here.
const kOneVpnAlwaysOnRoute = '/always-on';

/// The first-connect explainer, a full page. The first connect intent
/// pushes here.
const kOneVpnFirstConnectRoute = '/first-connect';

/// Pops the current route with [result]. A route with nothing beneath it
/// goes to the connect shell instead, so the stack never empties.
void oneVpnPopOrConnect<T extends Object?>(BuildContext context, [T? result]) {
  final navigator = Navigator.of(context);
  if (navigator.canPop()) {
    navigator.pop(result);
  } else {
    context.go(kOneVpnConnectRoute);
  }
}
