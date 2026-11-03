// Pins the shape of the desktop entry point. The fork boot stays aligned
// with it on the shared prefix. Before runApp, the desktop main performs
// exactly these actions: binding initialization, the shortcut service, the
// bridge pair via _initBridge, startup preferences, and the desktop window
// block. It then mounts the fork root widget. A failure here means the
// entry point changed. Re-derive the fork boot steps in
// lib/main_1vpn.dart against the new lib/main.dart. Then update the pinned
// shape.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The body of the top-level function in [path] whose first line starts
/// with [signaturePrefix]. It runs from the signature through the closing
/// brace at column zero. Comment lines are dropped, and whitespace runs
/// collapse to single spaces. Formatting cannot move the pin. Statements
/// can.
String _normalizedFunction(String path, String signaturePrefix) {
  final lines = File(path).readAsLinesSync();
  final start = lines.indexWhere((line) => line.startsWith(signaturePrefix));
  expect(start, isNot(-1), reason: "$path lacks $signaturePrefix");
  final body = <String>[];
  for (var index = start; index < lines.length; index++) {
    final line = lines[index];
    if (RegExp(r'^\s*//').hasMatch(line)) {
      continue;
    }
    body.add(line);
    if (line == "}") {
      return body.join("\n").replaceAll(RegExp(r'\s+'), ' ').trim();
    }
  }
  fail("$path: the function at $signaturePrefix never closes at column zero");
}

/// Upstream's main, normalized. Any statement added, removed, or
/// reordered changes this string.
const _pinnedMain =
    "Future<void> main(List<String> _) async "
    "{ OneVpnBinding.ensureInitialized(); "
    "await ShortCutService().initialize(); "
    "await _initBridge(); "
    "final appStartup = AppStartupService(); "
    "await appStartup.prepare(); "
    "if (AppPlatform.isDesktop) { "
    "await windowManager.ensureInitialized(); "
    "WindowOptions windowOptions = WindowOptions( "
    "size: _desktopWindowSize, "
    "minimumSize: _minimumDesktopWindowSize, "
    "center: true, ); "
    "windowManager.waitUntilReadyToShow(windowOptions, () async { "
    "await appStartup.onWindowReady(); }); } "
    "runApp(const OneVpnApp()); }";

/// Upstream's bridge setup, normalized. setUp must run first: statuses
/// pushed before it are dropped. The awaited tunnel files directory runs
/// second.
const _pinnedInitBridge =
    "Future<void> _initBridge() async "
    "{ BridgeFlutterApi.setUp(AppFlutterApi()); "
    "await AppHostApi().initTunFilesDir(); }";

/// The fork entry point's main, normalized by the same [_normalizedFunction]
/// as upstream's main above.
///
/// - The first statement initializes OneVpnBinding. Its messenger bounds the
///   status, start, stop and invoke bridge calls.
/// - The bridge setup and the tunnel files directory run first, in that
///   order, as one critical step. A failure or an expired bound throws a
///   StateError before runApp. Without the abort, the app mounts over a
///   failed bridge or a missing tunnel files directory.
/// - The start shortcut initializes right after the critical step. A cold
///   start's launching shortcut then waits for the connect screen.
/// - The backup-domain notice refresh precedes the account restore.
/// - The account restore precedes the resume beacon, the reload owner and
///   the node provision. Each reads the settled account state.
/// - The launch reachability probe starts after the account restore and
///   before the node provision. Nothing awaits it.
/// - On Android, main sets the coordinator's keepTunnelOnFailedStart. A
///   failed start then keeps the held TUN.
/// - main installs the native connect and attaches it. It pins each
///   measure core it sees connected.
/// - main sets the coordinator's fresh-connect prepare to the native
///   connect's. A connect from disconnected then starts a measure core.
/// - main sets the coordinator's default resolver to the native connect's.
///   Every other prepare then resolves with no probe.
/// - The reload policy attaches its event receiver.
/// - The reload owner's launch selection check starts after the native
///   connect installs its prepare. A lost selection then reloads a running
///   tunnel in place. Nothing awaits it.
/// - A due launch sets the router's initial location to the paywall before
///   runApp, and starts the plan-price warm-up. No other launch warms.
/// - The launch hold must precede the boot steps and runApp. Prices load only
///   on a due launch, after the account restore has run.
///
/// Any statement added, removed, or reordered changes this string.
const _pinnedForkMain =
    "Future<void> main() async { OneVpnBinding.ensureInitialized(); OneVpnLaunchHold.hold(); await oneVpnCriticalStep(() async { BridgeFlutterApi.setUp(AppFlutterApi()); await AppHostApi().initTunFilesDir(); }); await oneVpnOptionalStep( \"start shortcut\", OneVpnStartShortcut.instance.initialize, ); await oneVpnOptionalStep( \"boot defaults\", () => applyBootDefaults(bootCorrections), ); await oneVpnOptionalStep(\"startup preferences\", AppStartupService().prepare); await oneVpnOptionalStep( \"backup domain notice\", OneVpnApiTransport.instance.refreshBackupDomainNotice, ); await oneVpnOptionalStep( \"account restore\", OneVpnAccountService.instance.restore, ); OneVpnResumeBeacon.instance.register(); await oneVpnOptionalStep(\"session reload owner\", () async { await OneVpnAccountService.instance.whenRestored(); OneVpnReloadOwner.instance.register(); }); unawaited( oneVpnOptionalStep( \"launch reachability\", oneVpnProbeReachabilityAtLaunch, timeout: kOneVpnLaunchReachabilityBound, ), ); await oneVpnOptionalStep(\"provision nodes\", () async { await OneVpnAccountService.instance.whenRestored(); oneVpnLogProvision( await OneVpnNodeProvisioner().provisionForSession( OneVpnAccountService.instance.session, ), ); }); ConnectionCoordinator.instance.keepTunnelOnFailedStart = AppPlatform.isAndroid; OneVpnNativeConnect.install( OneVpnNativeConnect( coordinator: ConnectionCoordinator.instance, reloads: OneVpnReloadPolicy.instance, observatory: OneVpnObservatoryReader(), measureConfig: oneVpnMeasureConfig, )..attach(), ); ConnectionCoordinator.instance.freshConnectPrepare = OneVpnNativeConnect.instance.prepare; ConnectionCoordinator.instance.defaultResolver = OneVpnNativeConnect.instance.defaultResolver; OneVpnReloadPolicy.instance.attach(); unawaited(OneVpnReloadOwner.instance.checkSelection()); if (await OneVpnPaywallTrigger().dueAtLaunch()) { OneVpnRouter.initialLocation = kOneVpnPaywallRoute; unawaited(oneVpnWarmPlanPricesAtLaunch()); } runApp(const OneVpnApp()); }";

void main() {
  test('upstream main performs exactly the pinned pre-runApp actions', () {
    final mainBody = _normalizedFunction("lib/main.dart", "Future<void> main(");
    final initBridge = _normalizedFunction(
      "lib/main.dart",
      "Future<void> _initBridge(",
    );

    // Anti-vacuity guard. The extraction produced real function bodies,
    // not fragments.
    expect(mainBody, contains("runApp("));
    expect(initBridge, contains("initTunFilesDir"));

    expect(mainBody, _pinnedMain);
    expect(initBridge, _pinnedInitBridge);
  });

  // Diagnostic layer over the equality pin. Each shared-prefix action
  // appears exactly once and in this order. An order failure then names
  // the moved action instead of dumping two long strings.
  test('the shared prefix actions run once each, in order', () {
    const orderedActions = [
      "OneVpnBinding.ensureInitialized()",
      "await ShortCutService().initialize()",
      "await _initBridge()",
      "final appStartup = AppStartupService()",
      "await appStartup.prepare()",
      "if (AppPlatform.isDesktop)",
      "runApp(",
    ];
    final mainBody = _normalizedFunction("lib/main.dart", "Future<void> main(");

    var previousIndex = -1;
    for (final action in orderedActions) {
      final index = mainBody.indexOf(action);
      expect(index, isNot(-1), reason: "main lacks $action");
      expect(
        mainBody.indexOf(action, index + 1),
        -1,
        reason: "main repeats $action",
      );
      expect(
        index,
        greaterThan(previousIndex),
        reason: "$action runs out of order",
      );
      previousIndex = index;
    }

    final initBridge = _normalizedFunction(
      "lib/main.dart",
      "Future<void> _initBridge(",
    );
    expect(
      initBridge.indexOf("BridgeFlutterApi.setUp(AppFlutterApi())"),
      lessThan(initBridge.indexOf("await AppHostApi().initTunFilesDir()")),
      reason: "bridge setUp must precede the tunnel files directory",
    );
  });

  test('the fork main aborts on a critical boot failure before runApp', () {
    final forkMain = _normalizedFunction(
      "lib/main_1vpn.dart",
      "Future<void> main(",
    );

    // Anti-vacuity guard. The extraction returns the real function body, and
    // the abort it must contain is present.
    expect(forkMain, contains("runApp("));
    expect(forkMain, contains("await AppHostApi().initTunFilesDir()"));
    expect(forkMain, contains("oneVpnCriticalStep("));

    // The abort runs before the app mounts: a failed bridge or tunnel files
    // directory throws ahead of runApp. A merge that drops the critical step
    // or moves it after runApp fails here.
    expect(
      forkMain.indexOf("BridgeFlutterApi.setUp(AppFlutterApi())"),
      lessThan(forkMain.indexOf("await AppHostApi().initTunFilesDir()")),
      reason: "bridge setUp must precede the tunnel files directory",
    );
    expect(
      forkMain.indexOf("oneVpnCriticalStep("),
      lessThan(forkMain.indexOf("runApp(")),
      reason: "the abort must throw before mounting the app",
    );

    expect(forkMain, _pinnedForkMain);
  });
}
