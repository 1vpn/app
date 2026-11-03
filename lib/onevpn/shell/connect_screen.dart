import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/core/db/database/database.dart';
import 'package:onexray/core/pigeon/flutter_api.dart';
import 'package:onexray/core/pigeon/host_api.dart';
import 'package:onexray/core/pigeon/messages.g.dart';
import 'package:onexray/core/tools/logger.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/account/session.dart';
import 'package:onexray/onevpn/ads/ad_gateway.dart';
import 'package:onexray/onevpn/ads/connect_ad_gate.dart';
import 'package:onexray/onevpn/app/held_tunnel.dart';
import 'package:onexray/onevpn/app/platform_channel.dart';
import 'package:onexray/onevpn/catalogue/catalogue.dart';
import 'package:onexray/onevpn/catalogue/free_floor.dart';
import 'package:onexray/onevpn/connect/native_connect.dart';
import 'package:onexray/onevpn/feedback/connection_actions.dart';
import 'package:onexray/onevpn/handover/reload_policy.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations.dart';
import 'package:onexray/onevpn/location/flag.dart';
import 'package:onexray/onevpn/location/location_picker_model.dart';
import 'package:onexray/onevpn/paywall/paywall_trigger.dart';
import 'package:onexray/onevpn/rating/rating_prompt.dart';
import 'package:onexray/onevpn/routing/direct_regions_apply.dart';
import 'package:onexray/onevpn/shell/backup_domain_notice.dart';
import 'package:onexray/onevpn/shell/censorship_warning.dart';
import 'package:onexray/onevpn/shell/connect_control.dart';
import 'package:onexray/onevpn/shell/edge_route.dart';
import 'package:onexray/onevpn/shell/first_connect_explainer.dart';
import 'package:onexray/onevpn/shell/layout.dart';
import 'package:onexray/onevpn/shell/menu.dart';
import 'package:onexray/onevpn/shell/notification_prompt.dart';
import 'package:onexray/onevpn/shell/route_indicator.dart';
import 'package:onexray/onevpn/shell/routes.dart';
import 'package:onexray/onevpn/shell/start_shortcut.dart';
import 'package:onexray/onevpn/shell/status_debounce.dart';
import 'package:onexray/onevpn/theme/backdrop.dart';
import 'package:onexray/onevpn/theme/brand_lockup.dart';
import 'package:onexray/onevpn/theme/button.dart';
import 'package:onexray/onevpn/theme/card.dart';
import 'package:onexray/onevpn/theme/premium.dart';
import 'package:onexray/pages/theme/color.dart';
import 'package:onexray/pages/theme/font.dart';
import 'package:onexray/service/connect/coordinator.dart';
import 'package:onexray/service/connect/runtime.dart';
import 'package:onexray/service/connect/settings.dart';
import 'package:onexray/service/servers/catalog.dart';

/// The fork connect screen. The 1VPN wordmark and a menu hamburger head the
/// screen. Below them sit the sliding-pill connect control, a status label, and
/// the current-location row. A non-premium account also sees the upgrade
/// banner. The control runs connect and disconnect through the below-waterline
/// coordinator. The screen requests the OS VPN permission at the first connect
/// intent, never before.
///
/// A free account's connect tap runs [OneVpnConnectAdGate] after the
/// permission and before the connect. The screen starts the gate's preload
/// on entry, on a location change, on a disconnect, and on a change from an
/// exempt account to a free one. Each preload runs only while the tunnel is
/// down.
///
/// A pick the location picker returns is a free account's switch. The screen
/// stops the tunnel and commits the pick in one coordinator command. It then
/// runs the tap chain's connect branch from disconnected, with the gate's
/// switch wait. The switch skips the once-ever explainer, censorship warning
/// and notification ask, so each stays for the next Connect tap. A tap
/// during the stop does nothing. A failed show leaves the tunnel down on
/// the pick. An abandoned show connects to the pick with no further ad. The
/// stop shows no rating prompt. A pick that arrives while a tap chain runs
/// does nothing.
///
/// A launch of [OneVpnStartShortcut] acts as a Connect tap. While a tap would
/// start a connect, it runs the tap chain once. While a tap chain runs, it
/// acts as a second tap does. A launch while a phase is in flight, or while a
/// tap would disconnect, is dropped. The screen registers the shortcut with
/// the localized Connect title.
///
/// Stacked, the column caps at [OneVpnLayout.narrowCap] and scrolls when the
/// height runs short. Split, the start pane holds the control and the status
/// label. The end pane holds the location row and the upgrade banner. Snack
/// bars anchor to the end pane in split.
///
/// It also triggers the recurring paywall. It asks the cadence on entry and on
/// every resume. A resume asks only while this route is topmost. The showing
/// never lands over the picker, the sign-in form, or the paywall itself.
///
/// A Back that would leave this route while the native connect measures or
/// holds moves the app to the background, as Home does, and keeps the
/// activity. The measure runs in this isolate, so the pin lands, or the hold
/// reaches its cap, with the app in the background. At any other time Back
/// leaves as the platform does.
class OneVpnConnectScreen extends StatefulWidget {
  const OneVpnConnectScreen({
    super.key,
    this.paywallTrigger,
    this.coordinator,
    this.database,
    this.heldTunnel,
    this.reloadPolicy,
    this.measuring,
    this.picksFastest,
    this.allDead,
    this.adGate,
    this.ratingPrompt,
    this.startShortcut,
  });

  /// Decides and performs the recurring-paywall showing. Defaults to the
  /// shared one. Tests inject a scripted cadence and audience.
  final OneVpnPaywallTrigger? paywallTrigger;

  /// The coordinator the connect control drives. Defaults to the shared
  /// one. Tests inject a scripted coordinator.
  final ConnectionCoordinator? coordinator;

  /// The database the selection and the catalog are watched from. Defaults
  /// to the shared one. Tests inject an in-memory one.
  final AppDatabase? database;

  /// The held signal the control renders from. Defaults to the shared one.
  /// Tests inject a scripted answer.
  final OneVpnHeldTunnel? heldTunnel;

  /// The reload policy the status label reads. Defaults to the shared one.
  /// Tests inject one.
  final OneVpnReloadPolicy? reloadPolicy;

  /// Whether the native connect measures. Defaults to the shared native
  /// connect's. Tests inject one.
  final ValueListenable<bool>? measuring;

  /// Whether a connect to a selection measures for the fastest server.
  /// Defaults to the shared native connect's. Tests inject one.
  final bool Function(ServerSelection selection)? picksFastest;

  /// Whether the native connect's hold stands. Defaults to the shared native
  /// connect's. Tests inject one.
  final ValueListenable<bool>? allDead;

  /// The interstitial gate on the connect tap. Defaults to the shared one.
  /// Tests inject one over a fake gateway.
  final OneVpnConnectAdGate? adGate;

  /// The rating prompt after a tap that disconnects a connected tunnel.
  /// Defaults to a prompt that opens the Play store listing. Tests inject a
  /// fake launcher.
  final OneVpnRatingPrompt? ratingPrompt;

  /// The start shortcut whose launches the screen runs. Defaults to the
  /// shared one. Tests inject one over a fake channel.
  final OneVpnStartShortcut? startShortcut;

  /// The key of the detail line under the status label, read by tests.
  static const detailKey = ValueKey('onevpn-connect-status-detail');

  @override
  State<OneVpnConnectScreen> createState() => _OneVpnConnectScreenState();
}

class _OneVpnConnectScreenState extends State<OneVpnConnectScreen>
    with WidgetsBindingObserver {
  late final AppDatabase _db = widget.database ?? AppDatabase();
  late final OneVpnHeldTunnel _held =
      widget.heldTunnel ?? OneVpnHeldTunnel.instance;
  late final ConnectionCoordinator _coordinator =
      widget.coordinator ?? ConnectionCoordinator.instance;
  final OneVpnFirstConnectExplainer _explainer = OneVpnFirstConnectExplainer();
  final OneVpnCensorshipWarning _censorship = OneVpnCensorshipWarning();
  final OneVpnNotificationPrompt _notifications = OneVpnNotificationPrompt();
  late final OneVpnConnectAdGate _adGate =
      widget.adGate ?? OneVpnConnectAdGate.instance;
  late final OneVpnRatingPrompt _rating =
      widget.ratingPrompt ?? OneVpnRatingPrompt();
  late final OneVpnPaywallTrigger _paywallTrigger =
      widget.paywallTrigger ?? OneVpnPaywallTrigger();
  late final OneVpnStartShortcut _startShortcut =
      widget.startShortcut ?? OneVpnStartShortcut.instance;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  /// The view the status label renders. It skips a transient phase that
  /// ends within [kOneVpnTransientStatusHold].
  late final OneVpnDebouncedConnectionView _statusView =
      OneVpnDebouncedConnectionView(_coordinator.state);

  /// Whether the connected label reads the updating copy. It shows once a
  /// settings reload holds for [kOneVpnTransientStatusHold].
  late final OneVpnReloadLabel _updating = OneVpnReloadLabel(
    (widget.reloadPolicy ?? OneVpnReloadPolicy.instance).state,
  );

  /// Whether a preparing or connected label reads the measuring copy.
  late final ValueListenable<bool> _measuring =
      widget.measuring ?? OneVpnNativeConnect.instance.measuring;

  /// Whether a connect to a selection measures for the fastest server.
  late final bool Function(ServerSelection) _picksFastest =
      widget.picksFastest ?? OneVpnNativeConnect.instance.picksFastest;

  /// Whether a connected view reads no connection.
  late final ValueListenable<bool> _allDead =
      widget.allDead ?? OneVpnNativeConnect.instance.allDead;

  /// Notifies when [_measuring] or [_allDead] changes. Back keeps the app
  /// alive while either reads true.
  late final Listenable _measureOrHold = Listenable.merge([
    _measuring,
    _allDead,
  ]);

  /// The keys hold the control, the location row, and the banner across a mode
  /// change. Focus and animation state then survive a rotation.
  final GlobalKey _controlKey = GlobalKey();
  final GlobalKey _rowKey = GlobalKey();
  final GlobalKey _bannerKey = GlobalKey();

  ServerSelection _selection = const ServerSelection.automatic();
  String? _directRegion;
  ServerCatalog _catalog = ServerCatalog();
  OneVpnAccountState _account = const OneVpnAccountRestoring();

  /// The signed-in session, or null in any other account state.
  OneVpnSession? get _session => _sessionOf(_account);

  /// This screen's route, read to check that it is still topmost. The resume
  /// check runs with no build in progress, so the state captures the route
  /// here.
  ModalRoute<dynamic>? _route;

  /// The coordinator phase last seen, read to detect a disconnect.
  ConnectionPhase? _phase;

  /// Whether a connect or disconnect tap chain runs.
  bool _tapInFlight = false;

  /// Whether a tap abandoned the ad gate's show and runs once the chain ends.
  bool _tapAgain = false;

  /// Whether a switch's stop runs. A tap does nothing until it ends.
  bool _switchStopping = false;

  /// Whether the tunnel is down: no phase in flight, nothing to disconnect,
  /// and no held TUN. A held signal that has not answered yet reads as not
  /// held.
  bool get _tunnelDown {
    final view = _coordinator.state.value;
    return !view.busy && !view.canDisconnect && _held.value != true;
  }

  /// Starts the gate's preload from [source] for the current account while
  /// the tunnel is down.
  void _preload(OneVpnAdLoadSource source) =>
      _adGate.preload(_account, tunnelDown: () => _tunnelDown, source: source);

  @override
  void initState() {
    super.initState();
    _account = OneVpnAccountService.instance.state.value;
    OneVpnAccountService.instance.state.addListener(_onAccountChanged);
    WidgetsBinding.instance.addObserver(this);
    _loadSelection();
    _preload(OneVpnAdLoadSource.entry);
    // Runs after the first frame: a route has no navigator to answer the
    // topmost check until it is installed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_showRecurringPaywallIfDue());
    });
    // Attaches after the first frame: the tap chain reads the locale and
    // pushes routes. A cold start's launch waits in the shortcut until then.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startShortcut.attach(_onStartShortcut);
    });
    _subscriptions.add(
      _db.connectionConfigDao.watch().listen((row) {
        if (!mounted) return;
        final connection = ConnectionConfiguration.fromJson(
          jsonDecode(row.configurationJson) as Map<String, dynamic>,
        ).connection;
        if (!_sameSelection(connection.selection, _selection)) {
          _preload(OneVpnAdLoadSource.location);
        }
        setState(() {
          _selection = connection.selection;
          _directRegion = OneVpnDirectRegionsApplyService.selectionOf(
            connection,
          );
        });
      }, onError: (_) {}),
    );
    _subscriptions.add(
      ServerCatalog.watch(_db).listen((catalog) {
        if (!mounted) return;
        setState(() => _catalog = catalog);
      }, onError: (_) {}),
    );
    // The screen reads the held signal on mount, on resume, on each native
    // status, and on each settled coordinator view. A release from the
    // notification or the tile reaches it through the native status.
    unawaited(_held.refresh());
    _subscriptions.add(
      AppFlutterApi().vpnStatusController.stream.listen(
        (_) => unawaited(_held.refresh()),
      ),
    );
    _phase = _coordinator.state.value.phase;
    _coordinator.state.addListener(_onViewChanged);
  }

  void _onViewChanged() {
    final phase = _coordinator.state.value.phase;
    final previous = _phase;
    _phase = phase;
    if (phase == ConnectionPhase.disconnected &&
        previous != ConnectionPhase.disconnected) {
      _preload(OneVpnAdLoadSource.disconnect);
    }
    if (phase == ConnectionPhase.connected) return;
    unawaited(_held.refresh());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
    unawaited(
      _startShortcut.publish(OneVpnLocalizations.of(context)!.onevpnConnect),
    );
  }

  /// Re-asks the cadence when the app returns to the foreground. A resume
  /// while the ad gate awaits a show starts the gate's grace, so the tap
  /// chain ends and the next tap runs fresh. A hidden or paused app cancels
  /// the grace.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      _adGate.onAppHidden();
      return;
    }
    if (state != AppLifecycleState.resumed) return;
    // The ad shows in its own task. A relaunch brings this screen back
    // without it, and only the abandon ends the wait.
    _adGate.onAppResumed();
    unawaited(_held.refresh());
    unawaited(_showRecurringPaywallIfDue());
  }

  /// Opens the paywall when the cadence allows it.
  Future<void> _showRecurringPaywallIfDue() async {
    await _paywallTrigger.run(
      isTopmost: () => mounted && (_route?.isCurrent ?? true),
      show: () => context.push(kOneVpnPaywallRoute),
    );
  }

  Future<void> _loadSelection() async {
    try {
      final configuration = await _coordinator.configuration;
      if (!mounted) return;
      setState(() {
        _selection = configuration.connection.selection;
        _directRegion = OneVpnDirectRegionsApplyService.selectionOf(
          configuration.connection,
        );
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _startShortcut.detach(_onStartShortcut);
    WidgetsBinding.instance.removeObserver(this);
    _coordinator.state.removeListener(_onViewChanged);
    OneVpnAccountService.instance.state.removeListener(_onAccountChanged);
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _statusView.dispose();
    _updating.dispose();
    super.dispose();
  }

  /// Tracks the account state. A change from an exempt account to a free
  /// one starts a preload: a restoring state that settles free, a sign-out,
  /// or a lapsed entitlement. A change between two free states starts none.
  void _onAccountChanged() {
    if (!mounted) return;
    final previous = _account;
    setState(() => _account = OneVpnAccountService.instance.state.value);
    if (OneVpnConnectAdGate.exempts(previous) &&
        !OneVpnConnectAdGate.exempts(_account)) {
      _preload(OneVpnAdLoadSource.account);
    }
  }

  /// Whether [a] and [b] name the same selection.
  static bool _sameSelection(ServerSelection a, ServerSelection b) =>
      a.kind == b.kind &&
      a.id == b.id &&
      a.region == b.region &&
      a.location == b.location;

  static OneVpnSession? _sessionOf(OneVpnAccountState state) =>
      state is OneVpnAccountSignedIn ? state.session : null;

  /// Runs a start-shortcut launch as one Connect tap. The launch runs
  /// [_toggle] while no phase is in flight and a tap on the view would not
  /// disconnect. While a tap chain runs, the launch acts as a second tap. It
  /// abandons the ad gate's show inside the resume grace. A chain the abandon
  /// cancels then runs again once. At any other step of the chain it does
  /// nothing. A launch while a phase is in flight, or while a tap would
  /// disconnect, is dropped and never runs later.
  void _onStartShortcut() {
    if (!mounted) return;
    final view = _coordinator.state.value;
    if (view.busy || _tapDisconnects(view)) {
      ygLogger(
        'OneVpnConnectScreen: start shortcut ignored, ${view.phase.name}',
      );
      return;
    }
    ygLogger(
      _tapInFlight
          ? 'OneVpnConnectScreen: start shortcut joins the running tap'
          : 'OneVpnConnectScreen: start shortcut connects',
    );
    unawaited(_toggle());
  }

  /// Runs the coordinator's connect or disconnect. A busy phase cancels the
  /// in-flight attempt, except a switch's stop, which the tap leaves to run.
  /// A tap in the red state disconnects where a failed start
  /// holds the TUN. The connect branch runs seven steps in order: the
  /// first-connect explainer once, the censorship warning once, the
  /// notification ask once, the OS VPN permission when the coordinator reports
  /// one is required, the ad gate, the held-TUN release, and the connect. A
  /// declined permission skips the ad gate. A cancelling gate ends the tap
  /// before the release. A tap that disconnects a connected tunnel and lands
  /// disconnected runs the rating prompt. A tap while an earlier chain runs
  /// does nothing, unless the phase is busy and the tap cancels. A tap inside
  /// the ad gate's resume grace abandons the show. It runs as a fresh tap
  /// once a cancelled chain ends.
  Future<void> _toggle() async {
    final view = _coordinator.state.value;
    if (view.busy) {
      // A switch's stop runs to its commit. A cancel there drops the pick
      // and leaves the tunnel down.
      if (!_switchStopping) _coordinator.cancel();
      return;
    }
    if (_tapInFlight) {
      if (_adGate.abandonOnTap()) _tapAgain = true;
      return;
    }
    await _runChain(() => _runTap(view));
  }

  /// Opens the location picker. A pick it returns runs as a switch.
  Future<void> _pickLocation() async {
    final pick = await context.push<ServerSelection>(
      kOneVpnLocationRoute,
      extra: _selection,
    );
    if (pick != null && mounted) await _switchTo(pick);
  }

  /// Runs a free account's switch to [pick] as one tap chain. A pick that
  /// arrives while a tap chain runs does nothing.
  Future<void> _switchTo(ServerSelection pick) async {
    if (_tapInFlight) return;
    ygLogger('OneVpnConnectScreen: location switch');
    await _runChain(() => _runTap(_coordinator.state.value, switchTo: pick));
  }

  /// Runs [chain] as the one tap chain in flight. A tap that abandoned the
  /// ad gate's show runs once the chain ends, while the tunnel is down.
  Future<void> _runChain(Future<void> Function() chain) async {
    _tapInFlight = true;
    try {
      await chain();
    } finally {
      _tapInFlight = false;
    }
    final again = _tapAgain;
    _tapAgain = false;
    // A chain that still connected leaves nothing for the tap to run.
    if (again && mounted && _tunnelDown) await _toggle();
  }

  /// Whether a tap on [view] disconnects. A view with a tunnel to stop
  /// disconnects. Where a failed start holds the TUN, so does a red view
  /// other than a declined permission.
  bool _tapDisconnects(ConnectionView view) =>
      view.canDisconnect ||
      (_coordinator.keepTunnelOnFailedStart &&
          view.issue != 'permissionRequired' &&
          OneVpnConnectControlState.of(view, held: _held.value) ==
              OneVpnConnectControlState.noConnection);

  /// Runs one tap chain from [view]. With [switchTo] it runs the connect
  /// branch after a stop that commits [switchTo], and skips the three
  /// once-ever steps.
  Future<void> _runTap(ConnectionView view, {ServerSelection? switchTo}) async {
    final disconnects = switchTo == null && _tapDisconnects(view);
    // The no-connection state is a failure. Its disconnect shows no rating.
    final rates =
        disconnects &&
        view.phase == ConnectionPhase.connected &&
        OneVpnConnectControlState.of(
              view,
              held: _held.value,
              allDead: _allDead.value,
            ) !=
            OneVpnConnectControlState.noConnection;
    // A connect with a picked selection can fall back to Automatic. The
    // notice names the catalogue city it started from, or no location.
    final selection = switchTo ?? _selection;
    final notifyFallback =
        !disconnects && selection.kind != SelectionKind.automatic;
    final locale = Localizations.localeOf(context);
    final selectionLabel = notifyFallback
        ? OneVpnConnectRowLabel.cityOf(
            OneVpnLocalizations.of(context)!,
            selection,
            OneVpnCatalogue.forSession(_session),
          )
        : null;
    final completed = await oneVpnRunConnectionAction(
      context,
      _coordinator,
      () async {
        if (disconnects) {
          await _coordinator.disconnect();
          return;
        }
        if (switchTo != null) {
          // Must run first: the switch connects from disconnected. The
          // once-ever steps stay unstamped for the next Connect tap.
          await _stopWith(switchTo);
        } else {
          // The explainer fires once, before the connect intent. The flag
          // stamps and the connect proceeds either way.
          if (await _explainer.consumeFirstConnect() && mounted) {
            await showOneVpnFirstConnectExplainer(context);
          }
          // The warning fires once, for a free account in Russian, Persian
          // or Chinese. The connect proceeds once the user dismisses it.
          if (await _censorship.consumeFirstConnect(
                locale,
                premium: _session?.isPremiumEntitled ?? false,
              ) &&
              mounted) {
            await showOneVpnCensorshipWarning(context);
          }
          // Must run before the release: the held TUN covers the device
          // while the dialog shows. The connect proceeds whatever the answer.
          await _notifications.askOnce();
        }
        var permitted = true;
        if (view.issue == 'permissionRequired' && view.permission != null) {
          final result = await AppHostApi().requestPlatformPermission();
          permitted =
              result.state == PlatformPermissionState.granted ||
              result.state == PlatformPermissionState.notRequired;
        }
        // Must run before the release: a release before the ad leaves the
        // device outside any tunnel for the ad's length.
        if (permitted &&
            !await _adGate.beforeConnect(
              _account,
              switching: switchTo != null,
            )) {
          return;
        }
        await _held.release(_coordinator);
        await _coordinator.connect();
      },
      selectionLabel: selectionLabel,
      notifyFallback: notifyFallback,
      held: _held,
    );
    final after = _coordinator.state.value;
    if (rates &&
        completed &&
        mounted &&
        after.phase == ConnectionPhase.disconnected &&
        !after.failed) {
      await _rating.afterUserDisconnect(context);
    }
  }

  /// Stops the tunnel and commits [pick] in one coordinator command. A tap
  /// while it runs does nothing.
  Future<void> _stopWith(ServerSelection pick) async {
    _switchStopping = true;
    try {
      final current = await _coordinator.configuration;
      await _coordinator.apply(
        ConnectionConfiguration(
          connection: ConnectionSettings.fromJson({
            ...current.connection.toJson(),
            'selection': pick.toJson(),
            'expert': false,
          }),
          policy: current.policy,
        ),
        disconnect: true,
        expectedConfiguration: current.encode(),
      );
    } finally {
      _switchStopping = false;
    }
  }

  /// The status text for [view] and [held]. The red state reads a failed
  /// connection when a connect failed, the hold included, and no connection
  /// otherwise. A preparing or connecting view, and a
  /// connected view while the native connect measures, read the
  /// [_connectingLabel]. Otherwise a connected view reads the updating copy
  /// during a settings reload. Every other failed view reads disconnected.
  String _statusLabel(OneVpnLocalizations l, ConnectionView view, bool? held) =>
      switch (view.phase) {
        _ when _connectFailed(view, held) => l.onevpnStatusConnectionFailed,
        _
            when OneVpnConnectControlState.of(
                  view,
                  held: held,
                  allDead: _allDead.value,
                ) ==
                OneVpnConnectControlState.noConnection =>
          l.onevpnStatusNoConnection,
        ConnectionPhase.disconnected => l.onevpnDisconnected,
        ConnectionPhase.preparing ||
        ConnectionPhase.connecting => _connectingLabel(l),
        ConnectionPhase.connected when _measuring.value => _connectingLabel(l),
        ConnectionPhase.connected when _updating.value =>
          l.onevpnStatusUpdating,
        ConnectionPhase.connected => l.onevpnConnected,
        ConnectionPhase.disconnecting => l.onevpnDisconnecting,
        ConnectionPhase.failed => l.onevpnDisconnected,
      };

  /// The text while a connect is under way. A connect that measures for the
  /// fastest server reads the measuring copy from its start. Every other
  /// connect reads the connecting copy, through a measure that guards a
  /// picked location too.
  String _connectingLabel(OneVpnLocalizations l) =>
      _picksFastest(_selection) ? l.onevpnStatusMeasuring : l.onevpnConnecting;

  /// Whether [view] and [held] show a failed connect.
  bool _connectFailed(ConnectionView view, bool? held) =>
      OneVpnConnectControlState.failureLine(
        view,
        held: held,
        allDead: _allDead.value,
      );

  /// The [byStem] entry for the location the row names, or null when the
  /// selection names no catalogue location.
  String? _selectionByStem(
    ServerSelection selection,
    ConnectionView view,
    Map<String, String> Function(OneVpnCatalogue) byStem,
  ) {
    final connected = view.phase == ConnectionPhase.connected;
    return OneVpnConnectRowLabel.locationByStem(
      selection: selection,
      resolvedNodeId: connected ? view.runtime?.entries.firstOrNull?.id : null,
      catalog: _catalog,
      byStem: OneVpnConnectRowLabel.merged(
        OneVpnConnectRowLabel.namingCatalogues(_session),
        byStem,
      ),
    );
  }

  /// The location-row label for the current selection and connection view.
  /// Delegates to [OneVpnConnectRowLabel] against the session's naming
  /// catalogues.
  String _selectionName(
    OneVpnLocalizations l,
    ServerSelection selection,
    ConnectionView view,
  ) {
    final connected = view.phase == ConnectionPhase.connected;
    return OneVpnConnectRowLabel.locationRow(
      l: l,
      selection: selection,
      connected: connected,
      resolvedNodeId: connected ? view.runtime?.entries.firstOrNull?.id : null,
      catalog: _catalog,
      catalogue: OneVpnCatalogue.forSession(_session),
      fallbacks: OneVpnConnectRowLabel.namingCatalogues(_session).skip(1),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _measureOrHold,
    builder: (_, screen) => PopScope(
      canPop: !_measuring.value && !_allDead.value,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // The measure stops with the Flutter engine, and a finished activity
        // takes the engine with it. The TUN then stays held until a relaunch.
        // The flags are read again here: a measure that ended after the last
        // build leaves through the platform.
        if (_measuring.value || _allDead.value) {
          unawaited(OneVpnPlatformChannel.moveTaskToBack());
        } else {
          unawaited(SystemNavigator.pop());
        }
      },
      child: screen!,
    ),
    child: _screen(context),
  );

  Widget _screen(BuildContext context) {
    final l = OneVpnLocalizations.of(context)!;
    final palette = ColorManager.palette(context);
    return OneVpnSnackBarAnchor(
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 28,
          title: OneVpnBrandLockup(color: palette.foreground, height: 28),
          actions: [
            OneVpnRouteIndicator(
              region: _directRegion,
              onTap: () => context.push(
                kOneVpnDirectRegionsRoute,
                extra: OneVpnStackedEdge.bottom,
              ),
            ),
            IconButton(
              tooltip: l.onevpnMenu,
              icon: Icon(LucideIcons.menu, color: palette.foreground),
              onPressed: () => showOneVpnMenu(context),
            ),
          ],
        ),
        body: SafeArea(
          child: OneVpnLayout.isSplit(context)
              ? OneVpnAdaptiveBody(
                  divider: false,
                  start: _control(l),
                  end: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _row(l, palette),
                      _banner(l, palette),
                      const OneVpnBackupDomainNotice(),
                      const SizedBox(height: OneVpnCard.margin),
                    ],
                  ),
                )
              : OneVpnConstrainedBody(
                  maxWidth: OneVpnLayout.narrowCap,
                  fillViewport: true,
                  child: Column(
                    children: [
                      Expanded(child: Center(child: _control(l))),
                      _row(l, palette),
                      _banner(l, palette),
                      const OneVpnBackupDomainNotice(),
                      const SizedBox(height: OneVpnCard.margin),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  /// The connect control and the status label, rebuilt on each view.
  Widget _control(OneVpnLocalizations l) => KeyedSubtree(
    key: _controlKey,
    child: ValueListenableBuilder<ConnectionView>(
      valueListenable: _coordinator.state,
      builder: (context, view, _) => _toggleAndStatus(context, l, view),
    ),
  );

  /// The location row.
  Widget _row(OneVpnLocalizations l, AppPalette palette) =>
      KeyedSubtree(key: _rowKey, child: _locationRow(context, l, palette));

  /// The upgrade banner. A premium account shows none.
  Widget _banner(OneVpnLocalizations l, AppPalette palette) => KeyedSubtree(
    key: _bannerKey,
    child: ValueListenableBuilder<OneVpnAccountState>(
      valueListenable: OneVpnAccountService.instance.state,
      builder: (context, state, _) {
        final session = state is OneVpnAccountSignedIn ? state.session : null;
        if (session?.isPremiumEntitled ?? false) {
          return const SizedBox.shrink();
        }
        return _upgradeBanner(context, l, palette);
      },
    ),
  );

  /// The control over the status label and its detail line. The control renders
  /// [view]. The label, the detail line, and the accessible state read the
  /// debounced view. A fast connect never flashes the connecting label. All of
  /// them read the held signal and the native connect's state. The label
  /// reads the measuring copy through a connect that measures for the fastest
  /// server. It reads the updating copy during a settings reload. The detail
  /// line shows no text and keeps its height, so the control stays put. It is
  /// a live region, so screen readers announce a failed connect's status.
  ///
  /// Stacked, the control alone sits at the center. Split, the control and
  /// the status label center together, and the detail line hangs below.
  Widget _toggleAndStatus(
    BuildContext context,
    OneVpnLocalizations l,
    ConnectionView view,
  ) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _statusView,
        _held,
        _updating,
        _measuring,
        _allDead,
      ]),
      builder: (context, _) {
        final shown = _statusView.value;
        final held = _held.value;
        final status = _statusLabel(l, shown, held);
        final failed = _connectFailed(shown, held);
        final palette = ColorManager.palette(context);
        final statusStyle = AppTypography.panelTitle.copyWith(
          fontWeight: FontWeight.w400,
        );
        final detailStyle = AppTypography.settingsValueLabel.copyWith(
          color: palette.mutedForeground,
        );
        final split = OneVpnLayout.isSplit(context);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Blank twin of what hangs below the centered block, at the same
            // height. Stacked, that is the whole status block. Split, it is
            // the detail line alone.
            Visibility(
              visible: false,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!split) ...[
                    const SizedBox(height: 16),
                    Text(' ', style: statusStyle),
                  ],
                  const SizedBox(height: 4),
                  Text(' ', style: detailStyle),
                ],
              ),
            ),
            OneVpnConnectControl(
              view: view,
              announcedView: shown,
              held: held,
              measuring: _measuring.value,
              allDead: _allDead.value,
              label: l.onevpnConnect,
              value: status,
              onTap: _toggle,
            ),
            const SizedBox(height: 16),
            ExcludeSemantics(child: Text(status, style: statusStyle)),
            const SizedBox(height: 4),
            // The detail line shows no text. A failed connect announces its
            // status through it.
            ExcludeSemantics(
              excluding: !failed,
              child: Semantics(
                liveRegion: true,
                label: failed ? status : null,
                child: Text(
                  '',
                  key: OneVpnConnectScreen.detailKey,
                  style: detailStyle,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _locationRow(
    BuildContext context,
    OneVpnLocalizations l,
    AppPalette palette,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        OneVpnCard.margin,
        OneVpnCard.margin,
        OneVpnCard.margin,
        0,
      ),
      child: Material(
        color: palette.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OneVpnCard.radius),
          side: BorderSide(color: palette.border, width: OneVpnCard.outline),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(OneVpnCard.radius),
          highlightColor: Colors.transparent,
          splashFactory: OneVpnCard.noSplash,
          onTap: _pickLocation,
          child: Padding(
            padding: OneVpnCard.padding,
            child: ValueListenableBuilder<ConnectionView>(
              valueListenable: _coordinator.state,
              builder: (context, view, _) {
                // An Automatic selection that names no location yet reads
                // as the fastest pick.
                final subtitle =
                    _selectionByStem(
                      _selection,
                      view,
                      (catalogue) =>
                          OneVpnLocationNaming.countriesByStem(catalogue, l),
                    ) ??
                    (_selection.kind == SelectionKind.automatic
                        ? l.onevpnAutomaticSubtitle
                        : null);
                final code = _selectionByStem(
                  _selection,
                  view,
                  OneVpnLocationNaming.countryCodesByStem,
                );
                // The row keeps one height in every state: a 32dp leading slot
                // and two single lines. The second line stays empty when there
                // is nothing to show. The connect control above then stays put.
                return Row(
                  children: [
                    // A location shows its flag. Automatic shows the
                    // picker's bolt until it names a location.
                    if (OneVpnFlag.has(code))
                      OneVpnFlag(countryCode: code!)
                    else
                      OneVpnBackdropSquare(
                        color: OneVpnBackdrop.tint(palette),
                        child: Icon(
                          _selection.kind == SelectionKind.automatic
                              ? LucideIcons.zap
                              : LucideIcons.globe,
                          size: OneVpnBackdropSquare.glyphSize,
                          color: palette.primary,
                        ),
                      ),
                    const SizedBox(width: OneVpnCard.leadingGap),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectionName(l, _selection, view),
                            style: AppTypography.settingsRow,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          ExcludeSemantics(
                            excluding: subtitle == null,
                            child: Text(
                              subtitle ?? '',
                              style: AppTypography.settingsValueLabel.copyWith(
                                color: palette.mutedForeground,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      LucideIcons.chevronRightDir,
                      color: palette.mutedForeground,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _upgradeBanner(
    BuildContext context,
    OneVpnLocalizations l,
    AppPalette palette,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        OneVpnCard.margin,
        OneVpnCard.stackGap,
        OneVpnCard.margin,
        0,
      ),
      child: Material(
        key: const ValueKey('onevpn-upgrade-banner'),
        color: palette.primarySolid,
        borderRadius: BorderRadius.circular(OneVpnCard.radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(OneVpnCard.radius),
          overlayColor: OneVpnButton.solidOverlay(context),
          onTap: () => context.push(kOneVpnPaywallRoute),
          child: Padding(
            padding: OneVpnCard.padding,
            child: Row(
              children: [
                OneVpnBackdropSquare(
                  color: palette.primaryForeground.withValues(alpha: 0.2),
                  child: OneVpnPremiumStar.outline(
                    size: OneVpnBackdropSquare.glyphSize,
                    color: palette.primaryForeground,
                  ),
                ),
                const SizedBox(width: OneVpnCard.leadingGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.onevpnUpgradeBannerTitle,
                        style: AppTypography.settingsRow.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l.onevpnUpgradeBannerSubtitle,
                        style: AppTypography.settingsValueLabel.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The connect-screen location-row label.
///
/// A connected Automatic tunnel names the node the resolver landed on. It
/// maps [resolvedNodeId] through the provisioned row name to the catalogue
/// city. A disconnected Automatic tunnel reads "Automatic". A
/// location selection names its city. A region selection names its region. A
/// source or server selection names its [ServerCatalog] entry.
///
/// A city comes from [catalogue] first, then from each of [fallbacks] in
/// order. A selection nothing names reads "Automatic".
abstract final class OneVpnConnectRowLabel {
  static String locationRow({
    required OneVpnLocalizations l,
    required ServerSelection selection,
    required bool connected,
    required int? resolvedNodeId,
    required ServerCatalog catalog,
    required OneVpnCatalogue catalogue,
    Iterable<OneVpnCatalogue> fallbacks = const [],
  }) {
    final cities = merged([
      catalogue,
      ...fallbacks,
    ], (catalogue) => OneVpnLocationNaming.citiesByStem(catalogue, l));
    if (selection.kind == SelectionKind.automatic) {
      final resolved = connected
          ? _resolvedByStem(resolvedNodeId, catalog, cities)
          : null;
      return resolved == null
          ? l.onevpnAutomaticSelection
          : l.onevpnAutomaticResolved(resolved);
    }
    return switch (selection.kind) {
      SelectionKind.automatic => l.onevpnAutomaticSelection,
      SelectionKind.region => selection.region ?? l.onevpnAutomaticSelection,
      SelectionKind.source =>
        catalog.sourcesById[selection.id]?.name ?? l.onevpnAutomaticSelection,
      SelectionKind.server =>
        catalog.servers
                .where((row) => row.id == selection.id)
                .map((row) => catalog.display(row).name)
                .firstOrNull ??
            l.onevpnAutomaticSelection,
      SelectionKind.location =>
        (selection.location == null ? null : cities[selection.location]) ??
            l.onevpnAutomaticSelection,
    };
  }

  /// The catalogues the connect row names a location from, in order.
  ///
  /// The session's catalogue comes first. The account's full location list
  /// follows. It names an account location that has no server right now.
  /// The free catalogue's premium teasers come last. They name a premium
  /// city while the account's list is not loaded.
  static List<OneVpnCatalogue> namingCatalogues(OneVpnSession? session) => [
    OneVpnCatalogue.forSession(session),
    if (session != null)
      OneVpnCatalogue.of(
        tier: OneVpnTier.premium,
        locations: session.locations,
        freeTier: false,
      ),
    OneVpnCatalogue.of(
      tier: OneVpnTier.premium,
      locations: [
        for (final location in kOneVpnFreeCatalogue)
          if (location.isPremium) location,
      ],
      freeTier: false,
    ),
  ];

  /// The [byStem] maps of [catalogues], merged. An earlier catalogue's entry
  /// wins over a later one's.
  static Map<String, String> merged(
    Iterable<OneVpnCatalogue> catalogues,
    Map<String, String> Function(OneVpnCatalogue) byStem,
  ) => {
    for (final catalogue in catalogues.toList().reversed) ...byStem(catalogue),
  };

  /// The localized catalogue city a location [selection] names, or null for
  /// any other selection and for a location outside [catalogue].
  static String? cityOf(
    OneVpnLocalizations l,
    ServerSelection selection,
    OneVpnCatalogue catalogue,
  ) => selection.kind == SelectionKind.location && selection.location != null
      ? OneVpnLocationNaming.citiesByStem(catalogue, l)[selection.location]
      : null;

  /// The [byStem] entry for the location the row names. A location
  /// selection names its own location. A connected Automatic tunnel names
  /// the resolved node's location. Every other selection returns null.
  static String? locationByStem({
    required ServerSelection selection,
    required int? resolvedNodeId,
    required ServerCatalog catalog,
    required Map<String, String> byStem,
  }) => switch (selection.kind) {
    SelectionKind.location =>
      selection.location == null ? null : byStem[selection.location],
    SelectionKind.automatic => _resolvedByStem(resolvedNodeId, catalog, byStem),
    _ => null,
  };

  /// The [byStem] entry for the node the connected runtime resolved to. The
  /// runtime entry's id maps through the provisioned row name to the catalogue.
  /// It is null when the node is not a catalogue location.
  static String? _resolvedByStem(
    int? id,
    ServerCatalog catalog,
    Map<String, String> byStem,
  ) {
    if (id == null) return null;
    final row = catalog.servers.where((row) => row.id == id).firstOrNull;
    if (row == null) return null;
    final stem = OneVpnLocationNaming.stemOfRowName(row.name);
    return stem == null ? null : byStem[stem];
  }
}
