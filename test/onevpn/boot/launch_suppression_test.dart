// Contract for the connect-on-launch suppression on a fresh install. The
// test walks one boot pass in production order: the first-boot correction,
// then startup preferences, then the service-ready hook. The first-boot
// correction stamps acceptance implicitly. The same correction suppresses
// connect on app launch. The service-ready hook therefore sends nothing on
// any VPN bridge channel or fork reload channel. The implicit stamp never
// triggers an auto-connect. The pass runs once per process:
// AppStartupService latches its launch handling after the first
// service-ready call. A second pass would assert against a no-op.
//
// The bridge is a pigeon channel on mobile targets and on macOS. On Linux
// and Windows, every host-api method forks to FFI before the channel. The
// test reports macOS as the operating system, so the pass takes the
// channel path on every test host.

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/core/constants/preferences.dart';
import 'package:onexray/core/db/database/database.dart';
import 'package:onexray/core/pigeon/host_api.dart';
import 'package:onexray/core/tools/platform.dart';
import 'package:onexray/onevpn/boot/defaults.dart';
import 'package:onexray/onevpn/handover/handover_host.dart';
import 'package:onexray/service/connect/coordinator.dart';
import 'package:onexray/service/launch/app_startup.dart';
import 'package:onexray/service/shared/event_bus/service.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../support/reload_channels.dart';

/// Every message channel of the VPN bridge host api, read from the
/// generated pigeon bindings. A regenerated api therefore cannot leave a
/// new channel untapped. Starting a VPN, or preparing to start one, sends
/// on one of these. The test floors the result at the fourteen known
/// methods before trusting it.
List<String> _hostApiMethods() {
  final source = File("lib/core/pigeon/messages.g.dart").readAsStringSync();
  return RegExp(r'dev\.flutter\.pigeon\.onexray\.BridgeHostApi\.(\w+)')
      .allMatches(source)
      .map((match) => match.group(1)!)
      .toSet()
      .toList();
}

String _hostApiChannel(String method) =>
    "dev.flutter.pigeon.onexray.BridgeHostApi.$method";

/// The tray-refresh stage touches ConnectionCoordinator.instance. Its
/// construction builds the AppDatabase. Drift schedules the database open
/// at once rather than at the first query. The open starts with
/// path_provider lookups. Unstubbed, they reject with a
/// MissingPluginException. That rejection can land after the test
/// completes and fail it under full-suite load. Resolving both lookups to
/// a per-test directory keeps the open inside the test's control. No query
/// runs in this pass, so no database file is created there.
///
/// The stub alone leaves a window: the open runs from a scheduled task.
/// tearDown could restore the real platform before the lookups fire. It
/// therefore awaits the open first, through the database reset. It
/// restores the platform only after the open resolves.
final class _IsolatedPaths extends PathProviderPlatform {
  _IsolatedPaths(this.path);
  final String path;

  @override
  Future<String?> getApplicationDocumentsPath() async => path;

  @override
  Future<String?> getTemporaryPath() async => path;
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const trayChannel = MethodChannel("tray_manager");
  final hostApiMethods = _hostApiMethods();
  final forkReloadChannels = reloadChannels();

  late AppEventBus eventBus;
  late Directory tempDirectory;
  late PathProviderPlatform previousPaths;
  final bridgeCalls = <String>[];
  final trayCalls = <String>[];

  setUp(() async {
    AppPlatform.debugOperatingSystemOverride = 'macos';
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    tempDirectory = await Directory.systemTemp.createTemp(
      'launch-suppression-',
    );
    previousPaths = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _IsolatedPaths(tempDirectory.path);
    // The static late AppEventBus.instance must exist before anything reads
    // it.
    eventBus = AppEventBus();
    bridgeCalls.clear();
    trayCalls.clear();
    for (final method in hostApiMethods) {
      binding.defaultBinaryMessenger.setMockMessageHandler(
        _hostApiChannel(method),
        (message) async {
          bridgeCalls.add(method);
          return null;
        },
      );
    }
    for (final channel in forkReloadChannels) {
      binding.defaultBinaryMessenger.setMockMessageHandler(channel, (
        message,
      ) async {
        bridgeCalls.add(channel);
        return null;
      });
    }
    // The test host is a desktop platform. The service-ready hook therefore
    // refreshes the tray before the suppression check, inside a catch that
    // returns on failure. The stub answers each tray call and records its
    // method. The record is the positive control: it proves the pass ran
    // the tray stage. A tray failure would return early and skip the
    // suppression check.
    binding.defaultBinaryMessenger.setMockMethodCallHandler(trayChannel, (
      call,
    ) async {
      trayCalls.add(call.method);
      return null;
    });
  });

  tearDown(() async {
    for (final method in hostApiMethods) {
      binding.defaultBinaryMessenger.setMockMessageHandler(
        _hostApiChannel(method),
        null,
      );
    }
    for (final channel in forkReloadChannels) {
      binding.defaultBinaryMessenger.setMockMessageHandler(channel, null);
    }
    binding.defaultBinaryMessenger.setMockMethodCallHandler(trayChannel, null);
    // Joins the in-flight database open before the stub goes away. The
    // reset closes the singleton, and closing awaits the pending open. The
    // path lookups therefore resolve against the stub, and nothing from the
    // open lands after the test. Restoring the platform first would reopen
    // the window the stub closes.
    //
    // Must reset last: the database open reads the override. The finally
    // resets it even when an earlier step throws.
    try {
      await AppDatabase.resetAfterOpenFailure();
      PathProviderPlatform.instance = previousPaths;
      await tempDirectory.delete(recursive: true);
      await eventBus.close();
    } finally {
      AppPlatform.debugOperatingSystemOverride = null;
    }
  });

  test('a fresh install stamps acceptance and never reaches the VPN '
      'bridge', () async {
    // Anti-vacuity floor on the derived channel list. The parse really
    // read the generated bindings: at least the fourteen known host-api
    // methods, among them the one that starts a VPN.
    expect(hostApiMethods, hasLength(greaterThanOrEqualTo(14)));
    expect(hostApiMethods, contains("startVpn"));
    expect(forkReloadChannels, hasLength(2));

    // Anti-vacuity guard. The recorder really intercepts bridge traffic,
    // so an empty record below means no traffic and not a dead tap.
    await AppHostApi().readVpnStatus();
    expect(bridgeCalls, ["readVpnStatus"]);
    bridgeCalls.clear();
    await OneVpnHandoverHost().reloadSupported();
    expect(bridgeCalls, [
      "dev.flutter.pigeon.onevpn.OneVpnHandoverHostApi.reloadSupported",
    ]);
    bridgeCalls.clear();

    // The risky configuration: connect on app launch enabled, a fresh
    // install that has not yet accepted the privacy policy.
    await PreferencesKey().saveConnectOnAppLaunch(true);
    expect(await PreferencesKey().readConnectOnAppLaunch(), isTrue);
    expect(await PreferencesKey().readPrivacyAccepted(), isFalse);

    // The first-boot correction stamps acceptance and suppresses connect
    // on app launch for this pass.
    await acceptPrivacyOnFirstBoot.apply();
    expect(await PreferencesKey().readPrivacyAccepted(), isTrue);

    final appStartup = AppStartupService();
    await appStartup.prepare();
    // Destination resolution itself sends nothing on the bridge.
    expect(bridgeCalls, isEmpty);

    await appStartup.handleServicesReady();

    // Positive control on the pass itself. setContextMenu is the last
    // call of the tray-refresh stage. Its presence proves the stage
    // completed and the pass reached the suppression check next. A missing
    // entry means the tray stage threw and the pass returned early. The
    // bridge silence below would then be vacuous.
    expect(trayCalls, contains("setContextMenu"));

    expect(bridgeCalls, isEmpty);
    expect(
      ConnectionCoordinator.instance.state.value.phase,
      ConnectionPhase.disconnected,
    );
  });
}
