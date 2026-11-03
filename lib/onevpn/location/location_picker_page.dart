import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/core/db/database/database.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/account/session.dart';
import 'package:onexray/onevpn/ads/connect_ad_gate.dart';
import 'package:onexray/onevpn/app/held_tunnel.dart';
import 'package:onexray/onevpn/catalogue/catalogue.dart';
import 'package:onexray/onevpn/connect/native_connect.dart';
import 'package:onexray/onevpn/feedback/connection_actions.dart';
import 'package:onexray/onevpn/handover/reload_policy.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations.dart';
import 'package:onexray/onevpn/location/flag.dart';
import 'package:onexray/onevpn/location/location_picker_model.dart';
import 'package:onexray/onevpn/location/place_names.dart';
import 'package:onexray/onevpn/shell/close_app_bar.dart';
import 'package:onexray/onevpn/shell/connect_control.dart';
import 'package:onexray/onevpn/shell/edge_dismiss.dart';
import 'package:onexray/onevpn/shell/layout.dart';
import 'package:onexray/onevpn/shell/links.dart';
import 'package:onexray/onevpn/shell/routes.dart';
import 'package:onexray/onevpn/theme/backdrop.dart';
import 'package:onexray/onevpn/theme/button.dart';
import 'package:onexray/onevpn/theme/card.dart';
import 'package:onexray/pages/theme/color.dart';
import 'package:onexray/pages/theme/font.dart';
import 'package:onexray/service/connect/coordinator.dart';
import 'package:onexray/service/connect/runtime.dart';
import 'package:onexray/service/connect/settings.dart';

/// The full-screen location picker the connect screen's location row opens.
///
/// The page is a pure consumer of the catalogue value and the provisioned
/// rows. It triggers no load and no provision: the reload owner owns both. A
/// tap commits a selection through the below-waterline coordinator and
/// returns. While connected on Android it reloads in place. A change that
/// cannot reload in place reconnects with no dialog. The page ignores taps
/// until the selection in flight settles. The tapped row reads as selected at
/// once and reverts if the change does not apply. An applied change pops the
/// page only while its route is still current. A page already closing pops
/// nothing more. A change that does not apply keeps the page open. A double
/// failure returns to the connect screen.
///
/// A switch is a free account's tap that changes the selection while the
/// connect control reads connected and the route is current. A free account
/// is one the ad gate does not exempt. The switch applies nothing. It pops
/// the page with the pick as its result, and the pick reads as selected while
/// the page leaves. The connect screen runs the switch. Only the default tap
/// switches.
///
/// Stacked, the rows form one column capped at [OneVpnLayout.listCap].
/// Split, the tiles flow into a two-column grid in reading order, capped at
/// [gridCap] and aligned to the top. The degraded banner and the Upgrade
/// header span both columns.
///
/// The row of the committed selection scrolls into view once the selection
/// and the rows load, and again after each change between the stacked and
/// split layouts. A tap never scrolls the list.
class OneVpnLocationPickerPage extends StatefulWidget {
  const OneVpnLocationPickerPage({
    super.key,
    this.accountState,
    this.serversStream,
    this.selectionStream,
    this.onSelect,
    this.onPaywall,
    this.onRetry,
    this.catalogue,
    this.failoverWindow = kOneVpnPremiumFailoverWindow,
    this.initialSelection,
    this.coordinator,
    this.reloadPolicy,
    this.heldTunnel,
    this.measuring,
    this.allDead,
  });

  /// Marks the mounted split grid.
  static const gridKey = ValueKey<String>('onevpn-location-grid');

  /// The gap between the two grid columns.
  static const double gridGutter = 16;

  /// The widest the split grid grows: two pane-wide tiles with the
  /// [gridGutter] between them and card-margin edge insets. A wider window
  /// centers it.
  static const double gridCap =
      2 * OneVpnLayout.paneCap + gridGutter + 2 * OneVpnCard.margin;

  final ValueListenable<OneVpnAccountState>? accountState;
  final Stream<List<CoreConfigData>>? serversStream;
  final Stream<ServerSelection>? selectionStream;
  final Future<void> Function(BuildContext, ServerSelection, String)? onSelect;
  final void Function(BuildContext)? onPaywall;
  final Future<void> Function()? onRetry;

  /// Overrides the session catalogue the picker renders. Defaults to the
  /// current session's catalogue. A test passes an emptied catalogue to pin
  /// the terminal state, which the compiled floor otherwise prevents.
  final OneVpnCatalogue? catalogue;

  /// How long a premium account waits for a premium node before the free
  /// nodes appear. The wait starts when the page opens, and again when the
  /// account first turns premium while the page is open.
  final Duration failoverWindow;

  /// The committed selection the caller already knows. The page renders it
  /// from the first frame, and [selectionStream] updates it afterwards.
  /// Null holds the free nodes until the stream's first value.
  final ServerSelection? initialSelection;

  /// The coordinator the default tap commits through. Defaults to the
  /// shared one. Tests inject one.
  final ConnectionCoordinator? coordinator;

  /// The policy a connected tap reloads through. Defaults to the shared
  /// one. Tests inject one.
  final OneVpnReloadPolicy? reloadPolicy;

  /// The held signal the default tap reads. Defaults to the shared one.
  /// Tests inject one.
  final OneVpnHeldTunnel? heldTunnel;

  /// Whether the native connect measures, read by the default tap. Defaults
  /// to the shared native connect's. Tests inject one.
  final ValueListenable<bool>? measuring;

  /// Whether the native connect's hold stands, read by the default tap.
  /// Defaults to the shared native connect's. Tests inject one.
  final ValueListenable<bool>? allDead;

  @override
  State<OneVpnLocationPickerPage> createState() =>
      _OneVpnLocationPickerPageState();
}

class _OneVpnLocationPickerPageState extends State<OneVpnLocationPickerPage> {
  late final ValueListenable<OneVpnAccountState> _accountState;
  late final Future<void> Function(BuildContext, ServerSelection, String)
  _onSelect;
  late final void Function(BuildContext) _onPaywall;
  late final Future<void> Function() _onRetry;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  OneVpnSession? _session;
  List<CoreConfigData> _servers = const [];
  ServerSelection _selection = const ServerSelection.automatic();
  bool _retrying = false;
  bool _failoverElapsed = false;
  Timer? _failover;

  /// False until a committed selection is known, from
  /// [OneVpnLocationPickerPage.initialSelection] or the stream. The free
  /// nodes stay listed until then.
  bool _selectionLoaded = false;

  /// Every location stem selected while the page is open. Each stays listed
  /// until the page pops.
  final Set<String> _kept = {};

  /// Set once a premium page lists the free nodes. They then stay listed.
  bool _freeListed = false;

  /// Whether the page has seen a premium catalogue.
  bool _premiumSeen = false;

  /// The selection in flight. The page ignores taps until it settles.
  ServerSelection? _pending;

  /// Whether the native connect measures.
  late final ValueListenable<bool> _measuring =
      widget.measuring ?? OneVpnNativeConnect.instance.measuring;

  /// Whether the native connect's hold stands.
  late final ValueListenable<bool> _allDead =
      widget.allDead ?? OneVpnNativeConnect.instance.allDead;

  /// False until the rows stream delivers its first value.
  bool _serversLoaded = false;

  /// The Automatic row's key. With [_locationKeys], every row keeps its key
  /// whichever row is selected, so a selection changes no row's identity.
  final _automaticKey = GlobalKey();

  /// The location rows' keys, by stem.
  final Map<String, GlobalKey> _locationKeys = {};

  /// Whether the last build laid out the split grid. Null before the first
  /// build.
  bool? _split;

  /// Whether the committed selection's row still waits to scroll into view.
  /// A layout change sets it. The first build with the selection and the rows
  /// loaded clears it, whether or not a row carries the selection.
  bool _revealPending = false;

  @override
  void initState() {
    super.initState();
    _accountState = widget.accountState ?? OneVpnAccountService.instance.state;
    _onSelect = widget.onSelect ?? _defaultOnSelect;
    _onPaywall =
        widget.onPaywall ?? (context) => context.push(kOneVpnPaywallRoute);
    _onRetry = widget.onRetry ?? _defaultOnRetry;
    if (widget.initialSelection case final seed?) {
      _selection = seed;
      _selectionLoaded = true;
      if (seed.location case final stem?) _kept.add(stem);
    }

    _session = _sessionOf(_accountState.value);
    _accountState.addListener(_onAccountChanged);
    _premiumSeen = _catalogue.tier == OneVpnTier.premium;
    _startFailover();

    final servers =
        widget.serversStream ?? AppDatabase().coreConfigDao.watchOutbounds();
    _subscriptions.add(
      servers.listen((rows) {
        if (!mounted) return;
        setState(() {
          _servers = rows;
          _serversLoaded = true;
        });
      }, onError: (_) {}),
    );

    final selection = widget.selectionStream ?? _defaultSelectionStream();
    _subscriptions.add(
      selection.listen((value) {
        if (!mounted) return;
        setState(() {
          _selection = value;
          _selectionLoaded = true;
          if (value.location case final stem?) _kept.add(stem);
        });
      }, onError: (_) {}),
    );
  }

  @override
  void dispose() {
    _failover?.cancel();
    _accountState.removeListener(_onAccountChanged);
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }

  void _onAccountChanged() {
    if (!mounted) return;
    setState(() {
      _session = _sessionOf(_accountState.value);
      if (!_premiumSeen && _catalogue.tier == OneVpnTier.premium) {
        _premiumSeen = true;
        _startFailover();
      }
    });
  }

  OneVpnCatalogue get _catalogue =>
      widget.catalogue ?? OneVpnCatalogue.forSession(_session);

  void _startFailover() {
    _failover?.cancel();
    _failoverElapsed = false;
    _failover = Timer(widget.failoverWindow, () {
      if (mounted) setState(() => _failoverElapsed = true);
    });
  }

  static OneVpnSession? _sessionOf(OneVpnAccountState state) =>
      state is OneVpnAccountSignedIn ? state.session : null;

  static Stream<ServerSelection> _defaultSelectionStream() =>
      AppDatabase().connectionConfigDao.watch().map(
        (row) => ConnectionConfiguration.fromJson(
          jsonDecode(row.configurationJson) as Map<String, dynamic>,
        ).connection.selection,
      );

  Future<void> _defaultOnSelect(
    BuildContext context,
    ServerSelection selection,
    String label,
  ) async {
    final coordinator = widget.coordinator ?? ConnectionCoordinator.instance;
    // Captured before the apply: a close during the apply leaves the context
    // mounted while another route is current.
    final route = ModalRoute.of(context);
    if ((route?.isCurrent ?? false) && _switches(coordinator, selection)) {
      setState(() => _selection = selection);
      Navigator.of(context).pop(selection);
      return;
    }
    final saved = await oneVpnApplyConnectionChange(
      context,
      coordinator,
      {'selection': selection.toJson(), 'expert': false},
      label: label,
      held: widget.heldTunnel,
      reloadPolicy: widget.reloadPolicy,
    );
    if (!context.mounted) return;
    if (saved != null) {
      if (route?.isCurrent ?? false) Navigator.of(context).pop();
    } else if (await oneVpnFailureOnScreen(coordinator, widget.heldTunnel) &&
        context.mounted) {
      // The red state carries the failure on the connect screen.
      context.go(kOneVpnConnectRoute);
    }
  }

  /// Whether a tap on [selection] is a switch: a free account, a connect
  /// control that reads connected, and a selection other than the committed
  /// one. It reads the native connect only while the phase is connected.
  bool _switches(ConnectionCoordinator coordinator, ServerSelection selection) {
    final view = coordinator.state.value;
    return view.phase == ConnectionPhase.connected &&
        !OneVpnConnectAdGate.exempts(_accountState.value) &&
        jsonEncode(selection.toJson()) != jsonEncode(_selection.toJson()) &&
        OneVpnConnectControlState.of(
              view,
              held: (widget.heldTunnel ?? OneVpnHeldTunnel.instance).value,
              measuring: _measuring.value,
              allDead: _allDead.value,
            ) ==
            OneVpnConnectControlState.connected;
  }

  /// Runs [_onSelect] for a tapped row. A tap while another selection is in
  /// flight does nothing. The row reads as selected while the change is in
  /// flight.
  Future<void> _select(
    BuildContext context,
    ServerSelection selection,
    String label,
  ) async {
    if (_pending != null) return;
    setState(() => _pending = selection);
    try {
      await _onSelect(context, selection, label);
    } finally {
      if (mounted) setState(() => _pending = null);
    }
  }

  /// Whether [selection] is the one in flight.
  bool _isPending(ServerSelection selection) =>
      _pending != null &&
      jsonEncode(_pending!.toJson()) == jsonEncode(selection.toJson());

  /// Scrolls the committed selection's row to the middle of the list after
  /// this frame. A row already fully in view, or a selection that no row
  /// carries, scrolls nothing.
  void _revealSelectionAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final key = switch (_selection.kind) {
        SelectionKind.automatic => _automaticKey,
        SelectionKind.location => _locationKeys[_selection.location],
        _ => null,
      };
      final row = key?.currentContext;
      final box = row?.findRenderObject();
      final position = row == null ? null : Scrollable.maybeOf(row)?.position;
      if (row == null || box == null || position == null) return;
      // The offsets that put the row at the viewport's top and bottom edges.
      // Any offset between them shows the whole row.
      final viewport = RenderAbstractViewport.of(box);
      final atTop = viewport.getOffsetToReveal(box, 0).offset;
      final atBottom = viewport.getOffsetToReveal(box, 1).offset;
      if (position.pixels >= atBottom && position.pixels <= atTop) return;
      unawaited(Scrollable.ensureVisible(row, alignment: 0.5));
    });
  }

  static Future<void> _defaultOnRetry() =>
      OneVpnAccountService.instance.refresh(manual: true);

  Future<void> _retry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    try {
      await _onRetry();
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = OneVpnLocalizations.of(context)!;
    final palette = ColorManager.palette(context);
    final catalogue = _catalogue;
    final model = OneVpnLocationPickerModel.from(
      catalogue: catalogue,
      servers: _servers,
      // The tapped row reads as selected at once. A change that does not
      // apply clears [_pending], and the committed selection shows again.
      selection: _pending ?? _selection,
      failoverElapsed: _failoverElapsed,
      freeListed: _freeListed || !_selectionLoaded,
      kept: _kept,
    );
    if (_selectionLoaded &&
        catalogue.tier == OneVpnTier.premium &&
        !catalogue.isDegraded &&
        !model.freeHidden) {
      _freeListed = true;
    }
    final split = OneVpnLayout.isSplit(context);
    if (split != _split) {
      _split = split;
      _revealPending = true;
    }
    // Must wait for the selection and the rows: an earlier build lays out a
    // different list.
    if (_revealPending && _selectionLoaded && _serversLoaded) {
      _revealPending = false;
      _revealSelectionAfterFrame();
    }
    return Scaffold(
      appBar: oneVpnCloseAppBar(context, l.onevpnSelectLocation),
      body: SafeArea(
        child: model.empty
            ? _terminal(context, l, palette)
            : _list(context, l, palette, model),
      ),
    );
  }

  /// The rows in list order. A spanning entry takes a full grid row.
  Widget _list(
    BuildContext context,
    OneVpnLocalizations l,
    AppPalette palette,
    OneVpnLocationPickerModel model,
  ) {
    // A list of free locations only takes a Free header. Free rows among
    // premium rows name the tier in their second line.
    final allFree =
        model.locations.isNotEmpty &&
        model.locations.every((location) => location.freeTier);
    final entries = <({Widget child, bool span})>[
      (
        child: KeyedSubtree(
          key: _automaticKey,
          child: _automaticRow(context, l, palette, model),
        ),
        span: false,
      ),
      if (model.degraded)
        (child: _degradedBanner(context, l, palette), span: true),
      if (allFree) (child: _sectionHeader(l.onevpnFree, palette), span: true),
      for (final location in model.locations)
        (
          child: KeyedSubtree(
            key: _locationKeys.putIfAbsent(location.stem, GlobalKey.new),
            child: _locationRow(
              context,
              l,
              palette,
              location,
              tierLine: !allFree && location.freeTier,
            ),
          ),
          span: false,
        ),
      if (model.teasers.isNotEmpty)
        (child: _sectionHeader(l.onevpnUpgrade, palette), span: true),
      for (final teaser in model.teasers)
        (child: _teaserRow(context, l, palette, teaser), span: false),
    ];
    const padding = EdgeInsets.symmetric(vertical: _sectionGap);
    if (OneVpnLayout.isSplit(context)) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final inset = math.max(
            0.0,
            (constraints.maxWidth - OneVpnLocationPickerPage.gridCap) / 2,
          );
          return ListView(
            key: OneVpnLocationPickerPage.gridKey,
            primary: false,
            padding: padding.add(EdgeInsets.symmetric(horizontal: inset)),
            scrollCacheExtent: _cacheExtent,
            children: _gridRows(entries),
          );
        },
      );
    }
    return OneVpnConstrainedBody(
      maxWidth: OneVpnLayout.listCap,
      child: ListView(
        controller: OneVpnEdgeScope.scrollControllerOf(context),
        padding: padding,
        scrollCacheExtent: _cacheExtent,
        children: [for (final entry in entries) entry.child],
      ),
    );
  }

  /// Pairs the tiles into rows of two in reading order. A spanning entry
  /// closes the open row and takes a row of its own.
  ///
  /// Each cell bleeds into the gutter, so the gutter narrows to
  /// [OneVpnLocationPickerPage.gridGutter].
  static List<Widget> _gridRows(List<({Widget child, bool span})> entries) {
    final rows = <Widget>[];
    final pending = <Widget>[];
    void flush() {
      for (var i = 0; i < pending.length; i += 2) {
        rows.add(
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _OneVpnGridBleed(towardEnd: true, child: pending[i]),
                ),
                Expanded(
                  child: i + 1 < pending.length
                      ? _OneVpnGridBleed(
                          towardEnd: false,
                          child: pending[i + 1],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        );
      }
      pending.clear();
    }

    for (final entry in entries) {
      if (entry.span) {
        flush();
        rows.add(entry.child);
      } else {
        pending.add(entry.child);
      }
    }
    flush();
    return rows;
  }

  Widget _automaticRow(
    BuildContext context,
    OneVpnLocalizations l,
    AppPalette palette,
    OneVpnLocationPickerModel model,
  ) => _tile(
    palette: palette,
    leading: LucideIcons.zap,
    backdrop: true,
    title: l.onevpnAutomaticSelection,
    subtitle: l.onevpnAutomaticSubtitle,
    selected: model.automaticSelected,
    applying: _isPending(const ServerSelection.automatic()),
    onTap: () => _select(
      context,
      const ServerSelection.automatic(),
      l.onevpnAutomaticSelection,
    ),
  );

  /// A location row. A [tierLine] row names the free tier after the
  /// country. A location with no working node reads and selects like any
  /// other. Its connect fails with an error.
  Widget _locationRow(
    BuildContext context,
    OneVpnLocalizations l,
    AppPalette palette,
    OneVpnLocationChoice location, {
    required bool tierLine,
  }) {
    final city = OneVpnPlaceNames.city(
      l,
      displayCode: location.displayCode,
      countryCode: location.countryCode,
      city: location.city,
    );
    final country = OneVpnPlaceNames.country(
      l,
      countryCode: location.countryCode,
      country: location.country,
    );
    return _tile(
      palette: palette,
      leading: LucideIcons.globe,
      countryCode: location.countryCode,
      title: city,
      subtitle: tierLine ? l.onevpnFreeSubtitle(country) : country,
      selected: location.selected,
      applying: _isPending(ServerSelection.location(location.stem)),
      onTap: () =>
          _select(context, ServerSelection.location(location.stem), city),
    );
  }

  Widget _teaserRow(
    BuildContext context,
    OneVpnLocalizations l,
    AppPalette palette,
    OneVpnLocationTeaser teaser,
  ) => _tile(
    palette: palette,
    leading: LucideIcons.globe,
    countryCode: teaser.countryCode,
    title: OneVpnPlaceNames.city(
      l,
      displayCode: teaser.displayCode,
      countryCode: teaser.countryCode,
      city: teaser.city,
    ),
    subtitle: OneVpnPlaceNames.country(
      l,
      countryCode: teaser.countryCode,
      country: teaser.country,
    ),
    trailing: LucideIcons.lock,
    muted: true,
    locked: true,
    onTap: () => _onPaywall(context),
  );

  Widget _degradedBanner(
    BuildContext context,
    OneVpnLocalizations l,
    AppPalette palette,
  ) => Padding(
    padding: const EdgeInsets.fromLTRB(
      OneVpnCard.margin,
      4,
      OneVpnCard.margin,
      4,
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            l.onevpnLocationsLoadFailed,
            style: AppTypography.settingsHint.copyWith(
              color: palette.mutedForeground,
            ),
          ),
        ),
        TextButton(
          onPressed: _retrying ? null : _retry,
          child: Text(l.onevpnRetry),
        ),
      ],
    ),
  );

  Widget _terminal(
    BuildContext context,
    OneVpnLocalizations l,
    AppPalette palette,
  ) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l.onevpnLocationsUnavailable,
            textAlign: TextAlign.center,
            style: AppTypography.settingsRow,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            style: OneVpnButton.style,
            onPressed: () => openExternalLink(context, OneVpnLinks.contactUs),
            child: Text(l.onevpnContactUs),
          ),
        ],
      ),
    ),
  );

  /// How far past each viewport edge the list builds its rows. A row needs a
  /// built context to scroll into view.
  ///
  /// A row is about 80dp tall. The 33-entry catalogue lays out 34 rows and two
  /// headers, about 2900dp. At 360x800 the viewport is 744dp, so 4000dp builds
  /// every row of a list up to about 4700dp, or 58 rows.
  static const _cacheExtent = ScrollCacheExtent.pixels(4000);

  /// The space over a section header, and at the top and bottom of the
  /// list. The first card sits as far below the app bar as a header sits
  /// below a card.
  static const double _sectionGap = 16;

  Widget _sectionHeader(String title, AppPalette palette) => Padding(
    padding: const EdgeInsets.fromLTRB(
      OneVpnCard.margin,
      _sectionGap,
      OneVpnCard.margin,
      8,
    ),
    child: Text(
      title,
      style: AppTypography.sectionTitle.copyWith(
        color: palette.mutedForeground,
      ),
    ),
  );

  /// A picker row. The leading slot shows the [countryCode] flag when one
  /// ships, and [leading] otherwise. A [backdrop] row sets [leading] on a
  /// backdrop square. A [selected] row takes the selected fill, a primary
  /// outline, and a primary check. An [applying] row's check announces the
  /// update to screen readers. Screen readers hear the rows as one group with
  /// the [selected] row selected. A [locked] row sits outside the group, and
  /// its trailing icon reads as locked to Premium.
  Widget _tile({
    required AppPalette palette,
    required IconData leading,
    required String title,
    required VoidCallback onTap,
    bool backdrop = false,
    String? countryCode,
    String? subtitle,
    IconData? trailing,
    bool selected = false,
    bool applying = false,
    bool muted = false,
    bool locked = false,
  }) {
    final foreground = muted ? palette.mutedForeground : palette.foreground;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(OneVpnCard.radius),
      side: BorderSide(
        color: selected ? palette.primary : palette.border,
        width: OneVpnCard.outline,
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        OneVpnCard.margin,
        6,
        OneVpnCard.margin,
        6,
      ),
      child: Semantics(
        container: true,
        selected: locked ? null : selected,
        inMutuallyExclusiveGroup: locked ? null : true,
        child: Material(
          animationDuration: Duration.zero,
          color: selected ? palette.selectedSurface : palette.card,
          shape: shape,
          child: InkWell(
            borderRadius: BorderRadius.circular(OneVpnCard.radius),
            highlightColor: Colors.transparent,
            splashFactory: OneVpnCard.noSplash,
            onTap: onTap,
            child: Padding(
              padding: OneVpnCard.padding,
              child: Row(
                children: [
                  if (OneVpnFlag.has(countryCode))
                    OneVpnFlag(countryCode: countryCode!)
                  else if (backdrop)
                    OneVpnBackdropSquare(
                      color: OneVpnBackdrop.tint(palette),
                      child: Icon(
                        leading,
                        size: OneVpnBackdropSquare.glyphSize,
                        color: palette.primary,
                      ),
                    )
                  else
                    Icon(leading, color: palette.mutedForeground),
                  const SizedBox(width: OneVpnCard.leadingGap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTypography.settingsRow.copyWith(
                            color: foreground,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle,
                            style: AppTypography.settingsValueLabel.copyWith(
                              color: palette.mutedForeground,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (selected)
                    Semantics(
                      container: true,
                      liveRegion: applying,
                      label: applying
                          ? OneVpnLocalizations.of(context)!
                                .onevpnStatusUpdating
                          : null,
                      child: Icon(LucideIcons.check, color: palette.primary),
                    )
                  else if (trailing != null)
                    Icon(
                      trailing,
                      color: palette.mutedForeground,
                      semanticLabel: locked
                          ? OneVpnLocalizations.of(context)!
                                .onevpnLocationLocked
                          : null,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Lays out a grid cell [bleed] wider than its slot, on the gutter side.
///
/// The extra width holds only the tile's transparent inset. Two cells
/// overlap their insets in the gutter, which narrows the two card margins
/// to [OneVpnLocationPickerPage.gridGutter].
/// Intrinsic sizes account for the bleed, so the cell works under
/// [IntrinsicHeight].
class _OneVpnGridBleed extends SingleChildRenderObjectWidget {
  const _OneVpnGridBleed({required this.towardEnd, required super.child});

  /// Whether the cell bleeds toward its end edge. A start cell does.
  final bool towardEnd;

  static const double bleed =
      OneVpnCard.margin - OneVpnLocationPickerPage.gridGutter / 2;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderOneVpnGridBleed(_bleedsLeft(context));

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderOneVpnGridBleed renderObject,
  ) {
    renderObject.bleedsLeft = _bleedsLeft(context);
  }

  bool _bleedsLeft(BuildContext context) =>
      towardEnd == (Directionality.of(context) == TextDirection.rtl);
}

class _RenderOneVpnGridBleed extends RenderShiftedBox {
  _RenderOneVpnGridBleed(this._bleedsLeft) : super(null);

  bool _bleedsLeft;
  set bleedsLeft(bool value) {
    if (value == _bleedsLeft) return;
    _bleedsLeft = value;
    markNeedsLayout();
  }

  static const double _bleed = _OneVpnGridBleed.bleed;

  BoxConstraints _childConstraints(BoxConstraints constraints) {
    final width = constraints.maxWidth + _bleed;
    return constraints.copyWith(minWidth: width, maxWidth: width);
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      child?.getMinIntrinsicHeight(width + _bleed) ?? 0;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      child?.getMaxIntrinsicHeight(width + _bleed) ?? 0;

  @override
  double computeMinIntrinsicWidth(double height) =>
      math.max(0, (child?.getMinIntrinsicWidth(height) ?? 0) - _bleed);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      math.max(0, (child?.getMaxIntrinsicWidth(height) ?? 0) - _bleed);

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.smallest;
    final size = child.getDryLayout(_childConstraints(constraints));
    return constraints.constrain(Size(constraints.maxWidth, size.height));
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(_childConstraints(constraints), parentUsesSize: true);
    size = constraints.constrain(Size(constraints.maxWidth, child.size.height));
    (child.parentData! as BoxParentData).offset = Offset(
      _bleedsLeft ? -_bleed : 0,
      0,
    );
  }
}
