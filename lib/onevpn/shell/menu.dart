import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/account/session.dart';
import 'package:onexray/onevpn/account/sign_in_page.dart';
import 'package:onexray/onevpn/feedback/notice.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations.dart';
import 'package:onexray/onevpn/shell/always_on.dart';
import 'package:onexray/onevpn/shell/edge_dismiss.dart';
import 'package:onexray/onevpn/shell/edge_route.dart';
import 'package:onexray/onevpn/shell/layout.dart';
import 'package:onexray/onevpn/shell/links.dart';
import 'package:onexray/onevpn/shell/routes.dart';
import 'package:onexray/onevpn/theme/card.dart';
import 'package:onexray/onevpn/theme/premium.dart';
import 'package:onexray/onevpn/theme/radii.dart';
import 'package:onexray/pages/theme/color.dart';

/// What the menu resolved to. The menu route pops with one of these. The
/// caller acts on it against the connect screen's context, which outlives
/// the route.
enum _OneVpnMenuAction {
  upgrade,
  alwaysOnSettings,
  signedUp,
  recheckPremium,
  editInfo,
  logOut,
}

/// Opens the menu from the connect screen's hamburger. The items follow the
/// account state. Signed out offers Upgrade, Log in, Sign up, Direct regions,
/// and Support. Signed in swaps Log in and Sign up for the account row and
/// Logout. The menu drops Upgrade once the account is premium. A grant still
/// awaiting server confirmation reads as premium, and the account row names it
/// as confirming. Android adds the always-on VPN guidance row. Direct regions,
/// Support, the always-on guidance, and the auth screen open over the menu.
/// Back returns to the menu. The backup-domain item ends the list while the
/// account API answers on a backup domain.
///
/// A completed auth closes the menu. A completed sign-up that leaves the
/// account without premium then opens the paywall, whichever row opened the
/// auth screen. A completed log-in opens nothing.
///
/// The menu is the [kOneVpnMenuRoute] route. See [OneVpnMenu] for its two
/// layouts.
///
/// [accountState] is the account the menu renders and the paywall check
/// reads. Defaults to the account service's state.
Future<void> showOneVpnMenu(
  BuildContext context, {
  ValueListenable<OneVpnAccountState>? accountState,
}) async {
  final account = accountState ?? OneVpnAccountService.instance.state;
  final action = await context.push<Object?>(kOneVpnMenuRoute, extra: account);
  if (action is! _OneVpnMenuAction || !context.mounted) return;
  final l = OneVpnLocalizations.of(context)!;
  switch (action) {
    case _OneVpnMenuAction.upgrade:
      context.push(kOneVpnPaywallRoute);
    case _OneVpnMenuAction.alwaysOnSettings:
      await openOneVpnAlwaysOnSettings(context);
    case _OneVpnMenuAction.signedUp:
      if (!_entitled(account.value)) context.push(kOneVpnPaywallRoute);
    case _OneVpnMenuAction.recheckPremium:
      OneVpnNotice.info(context, l.onevpnPremiumRecheck);
      await OneVpnAccountService.instance.refresh(manual: true);
    case _OneVpnMenuAction.editInfo:
      await openExternalLink(context, OneVpnLinks.account);
    case _OneVpnMenuAction.logOut:
      await OneVpnAccountService.instance.signOut();
  }
}

/// Whether [state] holds premium, an unconfirmed optimistic grant included.
bool _entitled(OneVpnAccountState state) =>
    state is OneVpnAccountSignedIn && state.session.isPremiumEntitled;

/// The menu surface. The layout mode reads live.
///
/// Stacked, it is a full-width drawer surface for the top edge, as tall as
/// its items. Split, it is a full-height drawer surface over the end pane of
/// the screen behind it. Both scroll when the items outgrow the height. The
/// close button and system back dismiss either one. The menu route, a
/// [OneVpnEdgePage.drawer], slides the surface in and adds the scrim.
class OneVpnMenu extends StatelessWidget {
  const OneVpnMenu({super.key, required this.account});

  /// Marks the mounted stacked surface: the top drawer.
  static const stackedKey = ValueKey<String>('onevpn-menu-stacked');

  /// Marks the mounted drawer surface.
  static const drawerKey = ValueKey<String>('onevpn-menu-drawer');

  final ValueListenable<OneVpnAccountState> account;

  @override
  Widget build(BuildContext context) {
    final l = OneVpnLocalizations.of(context)!;
    // Menu rows show no press effect.
    final items = Theme(
      data: Theme.of(context).copyWith(
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        splashFactory: OneVpnCard.noSplash,
      ),
      child: ValueListenableBuilder<OneVpnAccountState>(
        valueListenable: account,
        builder: (context, state, _) => Column(
          mainAxisSize: MainAxisSize.min,
          children: _items(context, l, state),
        ),
      ),
    );
    if (OneVpnLayout.isSplit(context)) return _drawer(context, l, items);
    return _topDrawer(context, l, items);
  }

  /// The drawer's header: the Menu title and the close button.
  Widget _header(BuildContext context, OneVpnLocalizations l) => AppBar(
    automaticallyImplyLeading: false,
    backgroundColor: Colors.transparent,
    title: Text(l.onevpnMenu),
    actions: [CloseButton(onPressed: () => oneVpnPopOrConnect(context))],
  );

  /// The stacked drawer surface. It spans the width, runs through the top
  /// safe inset, and grows to its items. It stops short of the bottom so
  /// the scrim stays tappable, and scrolls past that. Screen readers read it
  /// as the Menu route, as they read the split drawer.
  Widget _topDrawer(BuildContext context, OneVpnLocalizations l, Widget items) {
    final palette = ColorManager.palette(context);
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: l.onevpnMenu,
      child: _topDrawerSurface(context, palette, size, padding, l, items),
    );
  }

  Widget _topDrawerSurface(
    BuildContext context,
    AppPalette palette,
    Size size,
    EdgeInsets padding,
    OneVpnLocalizations l,
    Widget items,
  ) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        key: stackedKey,
        color: palette.card,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(OneVpnRadii.sheet),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: (size.height - padding.top) * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _header(context, l),
                Flexible(
                  child: SingleChildScrollView(
                    controller: OneVpnEdgeScope.scrollControllerOf(context),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: OneVpnLayout.listCap,
                        ),
                        child: items,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The split drawer surface. It runs the full height, from the end pane's
  /// start edge to the screen's end edge.
  Widget _drawer(BuildContext context, OneVpnLocalizations l, Widget items) {
    final palette = ColorManager.palette(context);
    final direction = Directionality.of(context);
    final ltr = direction == TextDirection.ltr;
    final size = MediaQuery.sizeOf(context);
    final pane = OneVpnAdaptiveBody.endPane(
      size,
      MediaQuery.paddingOf(context),
      direction,
    );
    // The drawer runs through the end safe inset.
    final width = ltr ? size.width - pane.left : pane.left + pane.width;
    return SizedBox(
      width: width,
      height: double.infinity,
      child: Drawer(
        key: drawerKey,
        width: width,
        backgroundColor: palette.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusDirectional.horizontal(
            start: Radius.circular(OneVpnRadii.sheet),
          ),
        ),
        // The drawer's start edge sits mid-screen. It takes no safe inset
        // there.
        child: MediaQuery.removePadding(
          context: context,
          removeLeft: ltr,
          removeRight: !ltr,
          child: Column(
            children: [
              _header(context, l),
              Expanded(
                // The header clears the status bar. Without the top inset
                // removed, the thumb track starts that far below the divider.
                // Must read the drawer's padding: the route's padding still
                // holds the start inset the drawer strips.
                child: Builder(
                  builder: (context) => MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    child: SafeArea(
                      child: SingleChildScrollView(
                        primary: false,
                        child: items,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _items(
    BuildContext context,
    OneVpnLocalizations l,
    OneVpnAccountState state,
  ) {
    final session = state is OneVpnAccountSignedIn ? state.session : null;
    final premium = session?.isPremiumEntitled ?? false;
    void pop(_OneVpnMenuAction action) => oneVpnPopOrConnect(context, action);
    return [
      if (session != null)
        ListTile(
          leading: const Icon(LucideIcons.userRound),
          title: OneVpnAccountLine(
            name: session.email.isEmpty ? l.onevpnAccount : session.email,
            plan: OneVpnAccountPlanLabel.of(l, session),
          ),
          // A pending row re-checks entitlement on tap and shows the
          // refresh icon. A signed-in row opens the account page.
          trailing: session.isPremiumPending
              ? const Icon(LucideIcons.refreshCw)
              : null,
          onTap: () => pop(
            session.isPremiumPending
                ? _OneVpnMenuAction.recheckPremium
                : _OneVpnMenuAction.editInfo,
          ),
        ),
      if (!premium)
        ListTile(
          leading: OneVpnPremiumStar.outline(
            color: ColorManager.palette(context).mutedForeground,
          ),
          title: Text(l.onevpnUpgrade),
          onTap: () => pop(_OneVpnMenuAction.upgrade),
        ),
      if (session == null)
        ListTile(
          leading: const Icon(LucideIcons.logIn),
          title: Text(l.onevpnLogIn),
          onTap: () => _openSignIn(context, OneVpnSignInMode.logIn),
        ),
      if (session == null)
        ListTile(
          leading: const Icon(LucideIcons.userPlus),
          title: Text(l.onevpnSignUp),
          onTap: () => _openSignIn(context, OneVpnSignInMode.signUp),
        ),
      ListTile(
        leading: const Icon(LucideIcons.route),
        title: Text(l.onevpnDirectRegions),
        onTap: () => context.push(kOneVpnDirectRegionsRoute),
      ),
      if (oneVpnAlwaysOnGuidanceAvailable)
        ListTile(
          leading: const Icon(LucideIcons.shieldLock),
          title: Text(l.onevpnAlwaysOnTitle),
          onTap: () => _openAlwaysOn(context),
        ),
      ListTile(
        leading: const Icon(LucideIcons.languages),
        title: Text(l.onevpnLanguage),
        onTap: () => context.push(kOneVpnLanguageRoute),
      ),
      ListTile(
        leading: const Icon(LucideIcons.lifeBuoy),
        title: Text(l.onevpnSupport),
        onTap: () => context.push(kOneVpnSupportRoute),
      ),
      if (session != null)
        ListTile(
          leading: const Icon(LucideIcons.logOut),
          title: Text(l.onevpnLogOut),
          onTap: () => pop(_OneVpnMenuAction.logOut),
        ),
    ];
  }

  /// Pushes the auth screen in [mode] over the menu. Back returns to the
  /// menu. A completed auth closes the menu, and a completed sign-up tells
  /// the caller.
  ///
  /// Holds the navigator from before the push. A mode change while the auth
  /// screen is open remounts the row that pushed it.
  Future<void> _openSignIn(BuildContext context, OneVpnSignInMode mode) async {
    final navigator = Navigator.of(context);
    final completed = await context.push<OneVpnSignInMode>(
      kOneVpnSignInRoute,
      extra: OneVpnSignInArgs(mode: mode),
    );
    if (completed == null || !navigator.mounted) return;
    navigator.pop(
      completed == OneVpnSignInMode.signUp ? _OneVpnMenuAction.signedUp : null,
    );
  }

  /// Pushes the always-on guide over the menu. The guide's primary button
  /// closes the menu, and the caller opens the system VPN settings.
  ///
  /// Holds the navigator from before the push. A mode change while the guide is
  /// open remounts the row that pushed it.
  Future<void> _openAlwaysOn(BuildContext context) async {
    final navigator = Navigator.of(context);
    final openSettings = await context.push<bool>(kOneVpnAlwaysOnRoute);
    if (openSettings == true && navigator.mounted) {
      navigator.pop(_OneVpnMenuAction.alwaysOnSettings);
    }
  }
}

/// The account row's plan line.
///
/// A purchase the server has not confirmed reads as premium everywhere the
/// entitlement is checked. The row names that state as confirming and
/// promises nothing about how it ends.
abstract final class OneVpnAccountPlanLabel {
  static String of(OneVpnLocalizations l, OneVpnSession session) {
    if (session.isPremiumPending) return l.onevpnPlanPremiumPending;
    return session.isPremiumEntitled ? l.onevpnPlanPremium : l.onevpnPlanFree;
  }
}

/// The account row's name and plan.
///
/// [name] is the email, or the Account label when the email is empty. [plan]
/// is the plan line from [OneVpnAccountPlanLabel].
///
/// The one-line form reads the name, a middle dot, and the plan. The line
/// never wraps or overflows. The dot and the plan show whole, and the name
/// takes the rest of the row and ends in an ellipsis. A plan wider than the
/// row alone ends in an ellipsis and leaves the name no space.
///
/// The two-line form puts the name above the plan, with no dot. The name
/// takes one line and ends in an ellipsis. The plan wraps. This form applies
/// when the text scale at the ambient font size exceeds [twoLineScale], or
/// when [plan] carries a middle dot.
///
/// The plan takes the muted foreground and regular weight in both forms. The
/// row follows the ambient text direction, so a right-to-left locale puts the
/// name on the right. Screen readers read the name and the plan without the
/// separator.
class OneVpnAccountLine extends StatelessWidget {
  const OneVpnAccountLine({super.key, required this.name, required this.plan});

  /// The separator between the name and the plan in the one-line form.
  static const separator = ' \u00b7 ';

  /// The text scale above which the row takes the two-line form.
  static const twoLineScale = 1.3;

  final String name;
  final String plan;

  /// Whether the row takes the two-line form in [context].
  bool _twoLines(BuildContext context) {
    if (plan.contains('\u00b7')) return true;
    final fontSize = DefaultTextStyle.of(context).style.fontSize ?? 14;
    return MediaQuery.textScalerOf(context).scale(fontSize) >
        fontSize * twoLineScale;
  }

  @override
  Widget build(BuildContext context) {
    final planStyle = TextStyle(
      color: ColorManager.palette(context).mutedForeground,
      fontWeight: FontWeight.w400,
    );
    if (_twoLines(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
          ),
          Text(plan, style: planStyle),
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth),
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: separator, semanticsLabel: ''),
                  TextSpan(text: plan),
                ],
              ),
              style: planStyle,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
