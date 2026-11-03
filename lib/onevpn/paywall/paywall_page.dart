// The paywall: a hand-built "Choose Your Plan" screen on the fork purchase
// seam. It shows a benefit list, then Yearly and Monthly plan cards with
// live store prices. The Yearly card is preselected. The footer holds a Get
// Premium action and a Continue Free dismissal.
//
// Copy is local. Only the price strings are live, through
// OneVpnPurchaseService. A failed offering load leaves placeholder pricing.
// The paywall never goes blank or blocks.
//
// Get Premium resolves the join key before it opens the store sheet: the
// signed-in buyer's session email, or the inline prompt. The address goes
// to the purchase service and on to onPurchaseComplete. It is captured once
// and reused. The backend links the purchase by that exact address.
//
// A handoff that returns with the account still signed out leaves a paid
// purchase with no account to claim it. The screen then holds the
// purchased-but-unlinked state. It names the address. Its primary action
// reopens the account step, not the store.
//
// A purchase holds Get Premium and Continue Free until its result. With no
// result after [kOneVpnPurchaseDeadline] in the foreground, both free. The
// first return to the foreground after a pause asks the store to bring back
// a purchase sheet that Home left behind. A later success still hands off.
// A later failure or cancel shows nothing. A failure names its cause, and a
// named cause lasts until closed. Another account and an owned subscription
// link 1VPN Support in the message. The failure notice closes when the
// paywall leaves the screen.
//
// Stacked, one column capped at [OneVpnLayout.narrowCap] scrolls over the
// pinned footer. Split, the title and the benefits fill the start pane. The
// plan cards and the footer scroll together in the end pane. The
// purchased-but-unlinked message sits in the end pane, directly above the
// footer. The start pane then stays empty. Snack bars anchor to the end
// pane in split.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/feedback/notice.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations.dart';
import 'package:onexray/onevpn/paywall/purchase_email_prompt.dart';
import 'package:onexray/onevpn/paywall/sale_price.dart';
import 'package:onexray/onevpn/purchase/offerings_cache.dart';
import 'package:onexray/onevpn/purchase/purchase_service.dart';
import 'package:onexray/onevpn/shell/backup_domain_notice.dart'
    show OneVpnOpenLink;
import 'package:onexray/onevpn/shell/edge_dismiss.dart';
import 'package:onexray/onevpn/shell/layout.dart';
import 'package:onexray/onevpn/shell/links.dart';
import 'package:onexray/onevpn/theme/backdrop.dart';
import 'package:onexray/onevpn/theme/button.dart';
import 'package:onexray/onevpn/theme/card.dart';
import 'package:onexray/onevpn/theme/radii.dart';
import 'package:onexray/pages/theme/color.dart';
import 'package:onexray/pages/theme/font.dart';

/// Called after a purchase the store confirmed, with the address it was
/// made against. The router hands in the upgrade funnel. The default
/// dismisses.
typedef OneVpnPaywallPurchased = Future<void> Function(
  BuildContext context,
  String email,
);

/// Asks the buyer for the join key, or null if they back out. Defaults to
/// the inline prompt. Tests script it.
typedef OneVpnPaywallEmailAsk = Future<String?> Function(
  BuildContext context,
  String initial,
);

/// How long a purchase with no result holds the paywall's buttons. The
/// count runs while the app is in the foreground. It starts at the tap and
/// again at each return to the foreground.
const Duration kOneVpnPurchaseDeadline = Duration(seconds: 30);

class OneVpnPaywallPage extends StatefulWidget {
  const OneVpnPaywallPage({
    super.key,
    required this.service,
    this.accountState,
    this.onPurchaseComplete,
    this.onContinueFree,
    this.askForEmail,
    this.openLink,
  });

  /// The key of the selected plan card's mark.
  static const selectedMarkKey = ValueKey('onevpn.paywall.selectedMark');

  /// The purchase surface. The router hands in the build's selected
  /// backend. Tests hand in the fake.
  final OneVpnPurchaseService service;

  /// The account state the buyer's email is read from. Defaults to the
  /// shared service.
  final ValueListenable<OneVpnAccountState>? accountState;

  final OneVpnPaywallPurchased? onPurchaseComplete;
  final VoidCallback? onContinueFree;

  /// How the join key is collected when the account has none.
  final OneVpnPaywallEmailAsk? askForEmail;

  /// Opens the contact page. Defaults to [openExternalLink].
  final OneVpnOpenLink? openLink;

  @override
  State<OneVpnPaywallPage> createState() => _OneVpnPaywallPageState();
}

class _OneVpnPaywallPageState extends State<OneVpnPaywallPage>
    with WidgetsBindingObserver {
  late final ValueListenable<OneVpnAccountState> _accountState;

  late final OneVpnOfferingsCache _cache;

  bool _loading = true;
  OneVpnOfferings? _offerings;

  /// Whether the last load failed because the store was unreachable. It
  /// drives the load-error copy: only this shows the connectivity message.
  bool _unreachable = false;
  OneVpnPurchaseTerm _selected = OneVpnPurchaseTerm.yearly;

  /// Whether a purchase holds Get Premium and Continue Free.
  bool _purchasing = false;

  /// Counts purchase taps. A result moves the screen only while its tap is
  /// the latest one and still holds the buttons.
  int _attempt = 0;

  /// Whether the app was paused since the latest tap or the last return to
  /// the foreground. Only a pause can leave a store sheet behind.
  bool _pausedSinceTap = false;

  /// Frees the buttons when a purchase gives no result in time.
  Timer? _deadline;

  /// The failure notice this screen showed last. It closes when the screen
  /// leaves: a store message belongs to the paywall.
  OneVpnNoticeHandle? _notice;

  /// The address the prompt last answered with, or empty when it has not
  /// been asked. A later ask opens on it. A retry cannot hand the store a
  /// second address.
  String _captured = '';

  /// The address a completed purchase is still waiting on an account for.
  /// It is empty while no purchase has ended that way.
  String _unlinked = '';

  bool get _loadFailed =>
      !_loading && (_offerings == null || !_offerings!.hasAny);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _accountState = widget.accountState ?? OneVpnAccountService.instance.state;
    _cache = OneVpnOfferingsCache.forService(widget.service);
    // Cached prices show on the first frame. A fresh load then runs quietly.
    final cached = _cache.loaded;
    if (cached != null) {
      _offerings = cached;
      _loading = false;
    }
    _loadOfferings(quiet: cached != null);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A route pushed over the paywall takes it off the screen.
    if (ModalRoute.isCurrentOf(context) == false) _closeNotice();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _deadline?.cancel();
    _closeNotice();
    super.dispose();
  }

  void _closeNotice() {
    _notice?.close();
    _notice = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_purchasing) return;
    if (state != AppLifecycleState.resumed) {
      if (state == AppLifecycleState.paused) _pausedSinceTap = true;
      _deadline?.cancel();
      return;
    }
    _startDeadline();
    // A store sheet that Home left behind comes back to the front. Its own
    // result then frees the buttons. A return with no pause has no sheet
    // behind it: a closing sheet's result is still on its way.
    if (_pausedSinceTap) {
      _pausedSinceTap = false;
      unawaited(widget.service.restorePurchaseSheet());
    }
  }

  /// Starts the count to [kOneVpnPurchaseDeadline] from now.
  void _startDeadline() {
    _deadline?.cancel();
    _deadline = Timer(kOneVpnPurchaseDeadline, () {
      if (mounted) setState(() => _purchasing = false);
    });
  }

  /// Loads the offerings. A [quiet] load shows no loading state, and a failed
  /// one keeps the prices already on screen.
  Future<void> _loadOfferings({bool quiet = false}) async {
    if (!quiet) setState(() => _loading = true);
    final result = await _cache.refresh();
    if (!mounted) return;
    setState(() {
      if (result is OneVpnOfferingsLoaded) {
        _offerings = result.offerings;
        _unreachable = false;
      } else if (!quiet) {
        _offerings = null;
        _unreachable = result is OneVpnOfferingsUnreachable;
      }
      _loading = false;
      // A partial offering must not dead-end. The selection moves to the
      // term with a live package.
      if (_packageFor(_selected) == null) {
        final available = _firstAvailableTerm();
        if (available != null) _selected = available;
      }
    });
  }

  OneVpnPurchasePackage? _packageFor(OneVpnPurchaseTerm term) {
    final offerings = _offerings;
    if (offerings == null) return null;
    return term == OneVpnPurchaseTerm.yearly
        ? offerings.yearly
        : offerings.monthly;
  }

  /// The first term with a live package, yearly preferred, or null if the
  /// offering has neither.
  OneVpnPurchaseTerm? _firstAvailableTerm() {
    for (final term in const [
      OneVpnPurchaseTerm.yearly,
      OneVpnPurchaseTerm.monthly,
    ]) {
      if (_packageFor(term) != null) return term;
    }
    return null;
  }

  String _emailOf(OneVpnAccountState state) =>
      state is OneVpnAccountSignedIn ? state.session.email : '';

  Future<void> _onGetPremium() async {
    final package = _packageFor(_selected);
    if (package == null) {
      // The selected term has no live package. Reload, which re-selects an
      // available term.
      await _loadOfferings();
      return;
    }

    // The join key, before the store sheet. An account with an email on
    // file is never asked.
    final email = await _resolveEmail();
    if (email == null || !mounted) return;

    final attempt = ++_attempt;
    _pausedSinceTap = false;
    setState(() => _purchasing = true);
    _startDeadline();
    final outcome = await widget.service.purchase(
      package: package,
      email: email,
    );
    if (!mounted) return;
    // A result after the deadline or after a later tap leaves the screen as
    // it is. A success still hands off: the store has charged.
    final current = attempt == _attempt && _purchasing;
    if (current) {
      _deadline?.cancel();
      setState(() => _purchasing = false);
    }
    switch (outcome) {
      case OneVpnPurchaseSucceeded():
        await _handOff(email);
      case OneVpnPurchaseCancelled():
        // Silent return to the paywall.
        break;
      case OneVpnPurchaseFailed(:final reason):
        if (current) _showFailure(reason);
    }
  }

  /// Names the cause of a failed purchase. A named cause lasts until
  /// closed. Another account and an owned subscription link 1VPN Support.
  void _showFailure(OneVpnPurchaseFailureReason reason) {
    final l = OneVpnLocalizations.of(context)!;
    final open = widget.openLink ?? openExternalLink;
    final page = context;
    final support = OneVpnNoticeLink(
      label: l.onevpnPaywallSupportLink,
      onTap: () => open(page, OneVpnLinks.contactUs),
    );
    _notice = switch (reason) {
      OneVpnPurchaseFailureReason.otherAccount => OneVpnNotice.errorWithLink(
        context,
        l.onevpnPaywallPurchaseOtherAccount,
        support,
      ),
      OneVpnPurchaseFailureReason.owned => OneVpnNotice.errorWithLink(
        context,
        l.onevpnPaywallPurchaseOwned,
        support,
      ),
      OneVpnPurchaseFailureReason.unfinished => OneVpnNotice.error(
        context,
        l.onevpnPaywallPurchaseUnfinished,
        persist: true,
      ),
      OneVpnPurchaseFailureReason.storeProblem ||
      OneVpnPurchaseFailureReason.unknown => OneVpnNotice.error(
        context,
        l.onevpnPaywallPurchaseError,
      ),
    };
  }

  /// Reopens the account step for the address the purchase was made
  /// against.
  ///
  /// The store is never reopened here. The money has already moved.
  Future<void> _onLinkAccount() async {
    if (_unlinked.isEmpty) return;
    await _handOff(_unlinked);
  }

  /// Runs the post-purchase handoff for [email] and records where it left
  /// the buyer.
  ///
  /// An account still signed out means the purchase has nothing to link
  /// to. The screen holds that address. A signed-in account clears it.
  Future<void> _handOff(String email) async {
    final complete = widget.onPurchaseComplete ?? _dismiss;
    await complete(context, email);
    if (!mounted) return;
    final linked = _accountState.value is OneVpnAccountSignedIn;
    setState(() => _unlinked = linked ? '' : email);
  }

  /// The address the purchase is linked by, or null when the buyer backed
  /// out of the prompt.
  ///
  /// The answer is kept. A second ask opens on it. A retry cannot send the
  /// store a different address.
  Future<String?> _resolveEmail() async {
    final known = _emailOf(_accountState.value);
    if (known.isNotEmpty) return known;
    // The explicit type makes a signature change on either side a compile
    // error.
    final OneVpnPaywallEmailAsk ask =
        widget.askForEmail ??
        (context, initial) =>
            showOneVpnPurchaseEmailPrompt(context, initial: initial);
    final answer = await ask(context, _captured);
    if (answer != null) _captured = answer;
    return answer;
  }

  Future<void> _dismiss(BuildContext context, String email) async {
    if (context.mounted && context.canPop()) context.pop();
  }

  void _onContinueFree() {
    final onContinueFree = widget.onContinueFree;
    if (onContinueFree != null) {
      onContinueFree();
    } else if (context.canPop()) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = OneVpnLocalizations.of(context)!;
    final palette = ColorManager.palette(context);
    final unlinked = _unlinked.isNotEmpty;
    final footer = _footer(palette, l, unlinked);

    return OneVpnSnackBarAnchor(
      child: Scaffold(
        body: SafeArea(
          child: OneVpnLayout.isSplit(context)
              ? OneVpnAdaptiveBody(
                  start: unlinked
                      ? const SizedBox.shrink()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _title(palette, l, TextAlign.start, top: 20),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                OneVpnCard.margin,
                                4,
                                OneVpnCard.margin,
                                20,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: _benefits(palette, l),
                              ),
                            ),
                          ],
                        ),
                  // The footer scrolls with the plan cards.
                  end: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // With the footer's 8dp top inset, the cards clear Get
                      // Premium by 24dp.
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          OneVpnCard.margin,
                          20,
                          OneVpnCard.margin,
                          unlinked ? 0 : 16,
                        ),
                        child: unlinked
                            ? _purchased(palette, l)
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: _plans(palette, l),
                              ),
                      ),
                      footer,
                    ],
                  ),
                  // The unlinked message sits on the footer that acts on it.
                  endAlignment: unlinked
                      ? Alignment.bottomCenter
                      : Alignment.center,
                )
              : OneVpnConstrainedBody(
                  maxWidth: OneVpnLayout.narrowCap,
                  child: Column(
                    children: [
                      if (!unlinked)
                        _title(palette, l, TextAlign.center, top: 24),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: OneVpnEdgeScope.scrollControllerOf(
                            context,
                          ),
                          padding: EdgeInsets.fromLTRB(
                            OneVpnCard.margin,
                            unlinked ? 24 : 8,
                            OneVpnCard.margin,
                            8,
                          ),
                          child: unlinked
                              ? _purchased(palette, l)
                              : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    ..._benefits(palette, l),
                                    const SizedBox(height: 20),
                                    ..._plans(palette, l),
                                  ],
                                ),
                        ),
                      ),
                      footer,
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  /// The page title. It keeps the card margin.
  Widget _title(
    AppPalette palette,
    OneVpnLocalizations l,
    TextAlign align, {
    required double top,
  }) => Padding(
    padding: EdgeInsets.fromLTRB(OneVpnCard.margin, top, OneVpnCard.margin, 16),
    child: Text(
      l.onevpnPaywallTitle,
      style: AppTypography.pageTitle.copyWith(color: palette.foreground),
      textAlign: align,
    ),
  );

  List<Widget> _benefits(AppPalette palette, OneVpnLocalizations l) => [
    _benefit(palette, LucideIcons.globe, l.onevpnPaywallBenefitLocations),
    _benefit(palette, LucideIcons.megaphoneOff, l.onevpnPaywallBenefitNoAds),
    _benefit(palette, LucideIcons.zap, l.onevpnPaywallBenefitSpeed),
    _benefit(palette, LucideIcons.arrowDownUp, l.onevpnPaywallBenefitP2p),
    _benefit(
      palette,
      LucideIcons.creditCardCheck,
      l.onevpnPaywallBenefitMoneyBack,
    ),
  ];

  /// The load notice, when the offering failed, over both plan cards.
  List<Widget> _plans(AppPalette palette, OneVpnLocalizations l) => [
    if (_loadFailed)
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          _unreachable
              ? l.onevpnPaywallPlansLoadFailed
              : l.onevpnPaywallPlansUnavailable,
          style: AppTypography.settingsHint.copyWith(
            color: palette.destructive,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    _planCard(
      palette: palette,
      l: l,
      term: OneVpnPurchaseTerm.yearly,
      title: l.onevpnPaywallPlanYearly,
      sale: _yearlySale(l),
      saleRoom: true,
    ),
    const SizedBox(height: _planGap),
    _planCard(
      palette: palette,
      l: l,
      term: OneVpnPurchaseTerm.monthly,
      title: l.onevpnPaywallPlanMonthly,
    ),
  ];

  /// The yearly card's discount pill label, or null when no saving from 1
  /// to 99 percent follows from the two live prices. Placeholder pricing and
  /// a missing plan show no pill. The percent takes the digits of the
  /// per-month price.
  String? _yearlySale(OneVpnLocalizations l) {
    final percent = oneVpnYearlySavingPercent(
      yearlyPrice: _offerings?.yearly?.price,
      yearlyCurrency: _offerings?.yearly?.currencyCode,
      monthlyPrice: _offerings?.monthly?.price,
      monthlyCurrency: _offerings?.monthly?.currencyCode,
    );
    if (percent == null || percent < 1 || percent > 99) return null;
    return l.onevpnPaywallSaleYearly(
      oneVpnSavingPercentText(
        percent,
        locale: Localizations.localeOf(context).toString(),
      ),
    );
  }

  /// The primary action over Continue Free. Stacked, it pins below the
  /// scroll view. Split, it scrolls with the end pane.
  Widget _footer(AppPalette palette, OneVpnLocalizations l, bool unlinked) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        OneVpnCard.margin,
        8,
        OneVpnCard.margin,
        OneVpnCard.margin,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _primaryButton(
            palette: palette,
            label: unlinked
                ? l.onevpnAuthCreateAccount
                : (_loadFailed ? l.onevpnPaywallRetry : l.onevpnGetPremium),
            onPressed: unlinked
                ? _onLinkAccount
                : ((_loading || _purchasing)
                      ? null
                      : (_loadFailed ? _loadOfferings : _onGetPremium)),
          ),
          const SizedBox(height: OneVpnButton.stackGap),
          _outlineButton(
            palette: palette,
            label: l.onevpnContinueFree,
            onPressed: _purchasing ? null : _onContinueFree,
          ),
        ],
      ),
    );
  }

  /// The purchased-but-unlinked surface. It names the address the backend
  /// links on and promises nothing about when the entitlement lands.
  Widget _purchased(AppPalette palette, OneVpnLocalizations l) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Icon(LucideIcons.circleCheck, size: 48, color: palette.primary),
      const SizedBox(height: 20),
      Text(
        l.onevpnPaywallPurchasedTitle,
        style: AppTypography.pageTitle.copyWith(color: palette.foreground),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 12),
      Text(
        l.onevpnPaywallPurchasedBody(_unlinked),
        style: AppTypography.settingsRow.copyWith(
          color: palette.mutedForeground,
        ),
        textAlign: TextAlign.center,
      ),
    ],
  );

  Widget _benefit(AppPalette palette, IconData icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: OneVpnBackdrop.tint(palette),
            borderRadius: BorderRadius.circular(OneVpnRadii.field),
          ),
          child: Icon(icon, size: 20, color: palette.primary),
        ),
        const SizedBox(width: OneVpnCard.leadingGap),
        Expanded(
          child: Text(
            text,
            style: AppTypography.rowTitle.copyWith(color: palette.foreground),
          ),
        ),
      ],
    ),
  );

  /// A plan card: the plan name over its price at the start, then the
  /// selection mark. With a live price and currency, the price reads per
  /// month. A plan with [saleRoom] keeps room above the card for a discount
  /// pill. The room holds whether or not a pill shows, so the card holds
  /// still. The [sale] pill straddles the card's top edge once the prices
  /// land.
  Widget _planCard({
    required AppPalette palette,
    required OneVpnLocalizations l,
    required OneVpnPurchaseTerm term,
    required String title,
    String? sale,
    bool saleRoom = false,
  }) {
    final selected = _selected == term;
    final package = _packageFor(term);
    final price =
        package?.priceString ??
        (_loading ? '…' : l.onevpnPaywallPriceUnavailable);
    // Per-month figures show with a live price and currency only.
    final currency = package?.currencyCode;
    final figures = currency == null
        ? null
        : OneVpnSaleFigures.of(
            price: package?.price,
            yearly: term == OneVpnPurchaseTerm.yearly,
            locale: Localizations.localeOf(context).toString(),
          );
    final priceStyle = AppTypography.settingsRow.copyWith(
      color: palette.mutedForeground,
    );
    final card = Material(
      animationDuration: Duration.zero,
      color: selected ? palette.accent : palette.card,
      borderRadius: BorderRadius.circular(OneVpnCard.radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(OneVpnCard.radius),
        highlightColor: Colors.transparent,
        splashFactory: OneVpnCard.noSplash,
        onTap: () => setState(() => _selected = term),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(OneVpnCard.radius),
            border: Border.all(
              color: selected ? palette.primary : palette.border,
              width: OneVpnCard.outline,
            ),
          ),
          padding: OneVpnCard.padding,
          // The title and price column takes all the slack, so a long price
          // never overflows. The mark keeps a fixed gap on the trailing
          // padding.
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.rowTitle.copyWith(
                        fontSize: 16,
                        color: palette.foreground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (figures == null)
                      Text(price, style: priceStyle)
                    else
                      // One line. A price wider than the column scales down,
                      // below the user's text scale if it must. Fallback
                      // price text wraps instead.
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          l.onevpnPaywallPricePerMonth(
                            figures.perMonth,
                            currency!,
                          ),
                          style: priceStyle,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              _selectionMark(palette, selected),
            ],
          ),
        ),
      ),
    );
    // The pill must sit inside the stack: taps outside its bounds never
    // reach the pill.
    return Stack(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [if (saleRoom) _pillSlot(palette), card],
        ),
        if (figures != null && sale != null)
          PositionedDirectional(
            top: 0,
            start: 0,
            end: 0,
            // The pill centers on the card's top edge. A tap on it selects
            // its card.
            child: Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                excludeFromSemantics: true,
                onTap: () => setState(() => _selected = term),
                child: _salePill(palette, sale),
              ),
            ),
          ),
      ],
    );
  }

  /// A plan card's selection mark, 24dp square. Selected is a blue disc
  /// with a small white dot at its center. Unselected is an empty circle.
  Widget _selectionMark(AppPalette palette, bool selected) => selected
      ? Container(
          key: OneVpnPaywallPage.selectedMarkKey,
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: palette.primary,
          ),
          alignment: Alignment.center,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.primaryForeground,
            ),
          ),
        )
      : Icon(LucideIcons.circle, color: palette.border);

  /// The room above a plan card for its discount pill: half the pill's
  /// height, so the pill straddles the card's top edge at any text scale. A
  /// blank pill sets the height, so the room never depends on the label.
  Widget _pillSlot(AppPalette palette) => Align(
    heightFactor: 0.5,
    alignment: Alignment.topCenter,
    child: Visibility(
      visible: false,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: _salePill(palette, ' '),
    ),
  );

  /// The gap between the two plan cards.
  static const double _planGap = 19;

  /// The discount pill on a plan card's top edge: [label] in white on the
  /// brand blue, at the chip corners.
  Widget _salePill(AppPalette palette, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: palette.primarySolid,
      borderRadius: BorderRadius.circular(OneVpnRadii.chip),
    ),
    child: Text(
      label,
      style: AppTypography.badge.copyWith(
        fontSize: 15,
        color: palette.primaryForeground,
      ),
    ),
  );

  Widget _primaryButton({
    required AppPalette palette,
    required String label,
    required VoidCallback? onPressed,
  }) => Material(
    color: onPressed == null ? palette.muted : palette.primarySolid,
    borderRadius: BorderRadius.circular(OneVpnButton.radius),
    child: InkWell(
      borderRadius: BorderRadius.circular(OneVpnButton.radius),
      overlayColor: OneVpnButton.solidOverlay(context),
      onTap: onPressed,
      child: Container(
        height: OneVpnButton.height,
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTypography.settingsRow.copyWith(
            color: palette.primaryForeground,
          ),
        ),
      ),
    ),
  );

  Widget _outlineButton({
    required AppPalette palette,
    required String label,
    required VoidCallback? onPressed,
  }) => Material(
    color: palette.background,
    borderRadius: BorderRadius.circular(OneVpnButton.radius),
    child: InkWell(
      borderRadius: BorderRadius.circular(OneVpnButton.radius),
      highlightColor: Colors.transparent,
      splashFactory: OneVpnCard.noSplash,
      onTap: onPressed,
      child: Container(
        height: OneVpnButton.height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(OneVpnButton.radius),
          border: Border.all(color: palette.border),
        ),
        child: Text(
          label,
          style: AppTypography.settingsRow.copyWith(color: palette.foreground),
        ),
      ),
    ),
  );
}
