import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:onexray/core/network/client.dart';
import 'package:onexray/core/tools/logger.dart';
import 'package:onexray/service/launch/app_startup.dart';
import 'package:onexray/service/advanced/xray/data_update/scheduler.dart';
import 'package:onexray/service/connect/coordinator.dart';
import 'package:onexray/service/connect/platform_requirements.dart';
import 'package:onexray/service/advanced/xray/geodata/service.dart';
import 'package:onexray/service/launch/storage_preparation.dart';
import 'package:onexray/service/shared/menu/short_cut/service.dart';
import 'package:onexray/service/shared/menu/tray/service.dart';
import 'package:onexray/service/shared/menu/window/service.dart';
import 'package:onexray/service/shared/notification/service.dart';
import 'package:onexray/service/shared/ping/service.dart';

abstract final class ServiceManager {
  static Future<void>? _initFuture;
  static var _initialized = false;

  static Future<void> serviceInit(BuildContext context) {
    if (_initialized) {
      return Future.value();
    }
    final initFuture = _initFuture;
    if (initFuture != null) {
      return initFuture;
    }

    final nextInitFuture = _serviceInitWithFailureRecovery(context);
    _initFuture = nextInitFuture;
    return nextInitFuture;
  }

  static Future<void> _serviceInitWithFailureRecovery(
    BuildContext context,
  ) async {
    try {
      await _serviceInit(context);
    } catch (error, stackTrace) {
      _initFuture = null;
      try {
        await AppStartupService().showMainWindow();
      } catch (windowError, windowStackTrace) {
        ygLogger(
          "show window after startup failure error: "
          "$windowError\n$windowStackTrace",
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  static Future<void> _serviceInit(BuildContext context) async {
    final databaseWasMissing = await StoragePreparation.ensureReady();
    await _runInit("NetClient", () => NetClient().asyncInit());
    await GeoDataService().ensureInstalled(
      resetOrphanedFiles: databaseWasMissing,
    );
    await ConnectionPlatformRequirements().ensureRuntime();
    // Recovery must succeed before external commands or automatic connection
    // are enabled. The legacy Profile runtime must not initialize alongside it.
    // Initialize receives no permission-request action. The OS VPN-permission
    // prompt fires at the first connect intent, never at app launch. The
    // connect controller asks when the published issue is permissionRequired.
    // Initialize still publishes the un-granted state. Connect-on-launch then
    // shows the main window instead of dialing past it.
    await ConnectionCoordinator.instance.initialize();
    await _runInit(
      "NotificationService",
      () => NotificationService().asyncInit(),
    );
    await _runInit("TrayService", () => TrayService().init());
    await _runInit("WindowService", () => WindowService().asyncInit());
    await _runInit(
      "AppStartupService",
      () => AppStartupService().handleServicesReady(),
    );
    BackgroundTaskService().init(
      vpnConnected:
          ConnectionCoordinator.instance.state.value.phase ==
          ConnectionPhase.connected,
    );
    _initialized = true;
    // No launch-path caller starts the background probe burst. The boot
    // provisioner fills the outbound table with the whole node floor. A burst
    // here would fan probes across every node before any connect intent.
    // Connect-time probe-and-pick is the product's only prober. startAutomatic
    // serves the setup and manual paths.
  }

  static Future<void> _runInit(
    String name,
    FutureOr<void> Function() init,
  ) async {
    try {
      await init();
    } catch (e, stackTrace) {
      ygLogger("$name init error: $e\n$stackTrace");
    }
  }

  static void serviceDispose() {
    PingService().stopAutomatic();
    _initFuture = null;
    _initialized = false;
    TrayService().dispose();
    ShortCutService().detach();
    WindowService().dispose();
    BackgroundTaskService().dispose();
  }
}
