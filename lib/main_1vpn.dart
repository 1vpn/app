import 'dart:async';

import 'package:flutter/material.dart';
import 'package:onexray/core/pigeon/flutter_api.dart';
import 'package:onexray/core/pigeon/host_api.dart';
import 'package:onexray/core/pigeon/messages.g.dart';
import 'package:onexray/core/tools/platform.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/account/resume_beacon.dart';
import 'package:onexray/onevpn/app/app.dart';
import 'package:onexray/onevpn/boot/boot_steps.dart';
import 'package:onexray/onevpn/boot/defaults.dart';
import 'package:onexray/onevpn/boot/launch_hold.dart';
import 'package:onexray/onevpn/boot/launch_reachability.dart';
import 'package:onexray/onevpn/boot/plan_price_warmup.dart';
import 'package:onexray/onevpn/connect/measure_config.dart';
import 'package:onexray/onevpn/connect/native_connect.dart';
import 'package:onexray/onevpn/connect/observatory_reader.dart';
import 'package:onexray/onevpn/handover/reload_policy.dart';
import 'package:onexray/onevpn/net/api_transport.dart';
import 'package:onexray/onevpn/paywall/paywall_trigger.dart';
import 'package:onexray/onevpn/paywall/pending_purchase.dart';
import 'package:onexray/onevpn/provision/node_provisioner.dart';
import 'package:onexray/onevpn/purchase/purchase_backend.dart';
import 'package:onexray/onevpn/reload/launch_refresh.dart';
import 'package:onexray/onevpn/reload/reload_owner.dart';
import 'package:onexray/onevpn/shell/router.dart';
import 'package:onexray/onevpn/shell/routes.dart';
import 'package:onexray/onevpn/shell/start_shortcut.dart';
import 'package:onexray/service/connect/coordinator.dart';
import 'package:onexray/service/launch/app_startup.dart';

/// The 1vpn entry point. It runs on mobile only. Desktop boots through
/// lib/main.dart. It initializes [OneVpnBinding], awaits the boot steps in
/// order, then mounts [OneVpnApp]. It takes no arguments. An argument list
/// carries meaning only on Windows.
///
/// Each awaited boot step has a 10 s bound, [kOneVpnBootStepTimeout]. A
/// critical step that fails or passes the bound aborts boot with a
/// [StateError] before runApp, and the app never mounts. The critical steps
/// are the bridge setup and the tunnel files directory. Any other step that
/// fails or passes the bound is logged, and boot continues.
///
/// The first frame is held until the shell's service initialization ends, so
/// the native splash covers the whole launch.
///
/// The start shortcut receives launches from boot on. A cold start's
/// launching shortcut waits for the connect screen for at most
/// [OneVpnStartShortcut.holdLimit]. The screen runs it as a Connect tap.
///
/// A signed-out launch probes the API domains in the background, at most
/// once a day. The probe never delays the first frame.
///
/// A signed-out launch with a stored purchase that waits for an account opens
/// on the paywall's purchased screen over the connect shell. It also asks the
/// store whether the customer still holds a subscription. A session on the
/// purchase address clears that record, at launch and on every later sign-in.
/// A session on another address leaves it. Any other launch
/// with the recurring paywall due opens on the paywall over the connect shell
/// and starts loading the plan prices. On any other launch the paywall loads
/// its prices when it opens. A signed-in launch configures the store when the
/// account restore identifies the session. A signed-out launch with no
/// paywall makes no store call.
///
/// On Android a failed start fails closed. The service holds the TUN with no
/// core, and the coordinator keeps it until the user disconnects. A connect
/// from disconnected runs the native connect's prepare. Any other prepare
/// resolves through its default resolver, which never probes. The native
/// connect pins each measure core it sees connected. The reload policy
/// receives the native reload events from launch. After the launch selection
/// check, a connected tunnel whose request differs from the one the app
/// compiles now for the same selection is brought up to date once, with no
/// dialog: in place where the TUN settings match, and through one reconnect
/// where they differ.
Future<void> main() async {
  OneVpnBinding.ensureInitialized();
  // The native splash stays up until the shell's services are ready.
  OneVpnLaunchHold.hold();
  await oneVpnCriticalStep(() async {
    // Must run before any awaited platform call: statuses pushed before setUp
    // are dropped.
    BridgeFlutterApi.setUp(AppFlutterApi());
    // Must complete before anything reads VpnConstants paths. Without it the
    // start file lands on a path the native side never reads.
    await AppHostApi().initTunFilesDir();
  });
  await oneVpnOptionalStep(
    "start shortcut",
    OneVpnStartShortcut.instance.initialize,
  );
  await oneVpnOptionalStep(
    "boot defaults",
    () => applyBootDefaults(bootCorrections),
  );
  await oneVpnOptionalStep("startup preferences", AppStartupService().prepare);
  // Seeds the backup-domain notice from the stored domain record. Must run
  // before any account call: a later seed can revive a notice that a failed
  // walk cleared.
  await oneVpnOptionalStep(
    "backup domain notice",
    OneVpnApiTransport.instance.refreshBackupDomainNotice,
  );
  await oneVpnOptionalStep(
    "account restore",
    OneVpnAccountService.instance.restore,
  );
  // Must run after the account restore: the beacon and the reload owner read
  // the settled account state.
  OneVpnResumeBeacon.instance.register();
  await oneVpnOptionalStep("session reload owner", () async {
    await OneVpnAccountService.instance.whenRestored();
    OneVpnReloadOwner.instance.register();
  });
  // Probes the API domains for a signed-out account, so web links and the
  // backup notice follow the walk. Nothing waits for it.
  unawaited(
    oneVpnOptionalStep(
      "launch reachability",
      oneVpnProbeReachabilityAtLaunch,
      timeout: kOneVpnLaunchReachabilityBound,
    ),
  );
  // Provisions the free floor, plus a restored session's catalogue. A fresh
  // install can then connect before the API is reachable.
  await oneVpnOptionalStep("provision nodes", () async {
    await OneVpnAccountService.instance.whenRestored();
    oneVpnLogProvision(
      await OneVpnNodeProvisioner().provisionForSession(
        OneVpnAccountService.instance.session,
      ),
    );
  });
  ConnectionCoordinator.instance.keepTunnelOnFailedStart =
      AppPlatform.isAndroid;
  OneVpnNativeConnect.install(
    OneVpnNativeConnect(
      coordinator: ConnectionCoordinator.instance,
      reloads: OneVpnReloadPolicy.instance,
      observatory: OneVpnObservatoryReader(),
      measureConfig: oneVpnMeasureConfig,
    )..attach(),
  );
  ConnectionCoordinator.instance.freshConnectPrepare =
      OneVpnNativeConnect.instance.prepare;
  ConnectionCoordinator.instance.defaultResolver =
      OneVpnNativeConnect.instance.defaultResolver;
  OneVpnReloadPolicy.instance.attach();
  // Must run after the native connect installs its prepare: a lost selection
  // reloads a running tunnel through it. The launch refresh must start after
  // the reload policy attaches and once the selection check has finished:
  // two reloads at once would stack two measure runs. The selection check
  // logs its own failures and never throws, so the chain always reaches it.
  unawaited(
    OneVpnReloadOwner.instance.checkSelection().then(
      (_) => OneVpnLaunchRefresh.instance.run(),
    ),
  );
  final pending = OneVpnPendingPurchase()
    ..follow(OneVpnAccountService.instance.state);
  final purchased = await pending.dueAtLaunch(
    account: OneVpnAccountService.instance.state,
    restored: OneVpnAccountService.instance.whenRestored(),
  );
  if (purchased != null) {
    OneVpnRouter.initialLocation = kOneVpnPaywallRoute;
    OneVpnRouter.initialExtra = purchased;
    // A store that finds no subscription clears the record for later
    // launches. Nothing waits for it.
    unawaited(pending.checkStore(oneVpnPurchaseBackend()));
  } else if (await OneVpnPaywallTrigger().dueAtLaunch()) {
    OneVpnRouter.initialLocation = kOneVpnPaywallRoute;
    // The paywall opens at launch, so the plan prices load now.
    unawaited(oneVpnWarmPlanPricesAtLaunch());
  }
  runApp(const OneVpnApp());
}
