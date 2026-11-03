// Pins the native contracts the Kotlin compiler cannot check.
//
// - The fork channel dispatches exactly the methods the Dart side invokes.
//   MainActivity registers the channel. A missing arm compiles clean, and
//   the Dart side then answers false or unknown.
// - The VPN service keeps its frozen companion constants. Their strings
//   cross files and processes, and the IPv6 TUN address must equal the Dart
//   policy's.
// - The VPN service holds one socket controller per process, registered
//   once. The core keeps every registration, and a stale one cancels every
//   dial. A per-instance controller compiles clean.
// - The upstream VPN service reaches the fork delegate through single-line
//   hooks. An unused delegate member is legal Kotlin, so a merge that drops
//   a hook compiles clean.
// - The builder policy excludes the app's own package outside the
//   allow-list mode and never inside it. A dropped exclusion compiles
//   clean, and a disallow call after an allow call throws at connect.
// - The native measure cap sits above the Dart all-dead cap plus the hold
//   cap, the path where no server answers. It reads the measure
//   config by the rule tag the Dart side writes, and is armed and disarmed
//   at its three sites. A dropped site compiles clean.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/app/platform_channel.dart';
import 'package:onexray/onevpn/connect/native_auto_contracts.dart';
import 'package:onexray/onevpn/connect/native_connect.dart';
import 'package:onexray/service/advanced/platform_policy.dart';

import 'support/kotlin_source.dart';

const _kotlinRoot = 'android/app/src/main/kotlin/net/yuandev/onexray';
const _channelPath = '$_kotlinRoot/onevpn/OneVpnPlatformChannel.kt';
const _activityPath = '$_kotlinRoot/MainActivity.kt';
const _servicePath = '$_kotlinRoot/vpn/OneVpnService.kt';
const _dartChannelPath = 'lib/onevpn/app/platform_channel.dart';
const _timeoutPath = '$_kotlinRoot/onevpn/OneVpnMeasureTimeout.kt';
const _delegatePath = '$_kotlinRoot/onevpn/OneVpnServiceDelegate.kt';
const _handoverPath = '$_kotlinRoot/onevpn/handover/OneVpnHandoverService.kt';
const _billingTaskPath = '$_kotlinRoot/onevpn/OneVpnBillingTask.kt';

/// The single-site hooks and the retry-start guard. Each appears exactly
/// as in the service, with leading indentation stripped. Each is the whole physical line. The tunnel-up
/// hook runs only while no release has begun since the start. The
/// tunnel-down hook has two sites and its own census.
const _hookLines = [
  'OneVpnServiceDelegate.applyBuilderPolicy(builder, tun, packageName)',
  'if (generation == startGeneration.get() && !released.get()) '
      'OneVpnServiceDelegate.onTunnelUp(this@OneVpnService, ::reloadXray)',
  'if (OneVpnServiceDelegate.dropsStart(intent, failedClosed && tunnel != '
      'null)) return START_NOT_STICKY',
  'return OneVpnServiceDelegate.runningResult(this)',
  'return OneVpnServiceDelegate.onUnrecognizedStart(this, intent, startId, '
      '{ VpnController.consumeStopRequest(this) }) '
      '{ if (!running && tunnel == null) startTun(startId) }',
  'OneVpnServiceDelegate.markUserStop(this)',
  'val result = LibXray.invoke(patchRuntimeEnv(coreInvokeText, '
      'establishedTunnel.fd, '
      'OneVpnServiceDelegate.directDnsPatch(this@OneVpnService)))',
  'val directDns = OneVpnServiceDelegate.directDnsPatch(this)',
];

/// Companion constants that the controller, the tile, and the interface
/// probe read across files. The set also holds the channel id line that
/// the identity pin reads from the service.
const _frozenServiceLines = [
  'const val ACTION_START: String = "vpn_start"',
  'const val ACTION_STOP: String = "vpn_stop"',
  'const val ACTION_STOP_REQUEST: String = '
      '"net.yuandev.onexray.VPN_STOP_REQUEST"',
  'const val IPV4_ADDRESS = "198.18.0.1"',
  'const val IPV6_ADDRESS = "fc00::1"',
  'const val ACTION_VPN_STATUS: String = "net.yuandev.onexray.VPN_STATUS"',
  'const val EXTRA_RUNNING: String = "running"',
  'const val NOTIFICATION_OPEN_REQUEST_CODE = 1',
  'const val NOTIFICATION_STOP_REQUEST_CODE = 2',
  'val channelId = "com.one.vpnapp.tunnel"',
];

/// The companion's one-time controller registration, as trimmed lines.
const _controllerInitLines = [
  '@Synchronized',
  'private fun initController() {',
  'if (controllerInit) {',
  'return',
  '}',
  'LibXray.registerDialerController(controller)',
  'LibXray.registerListenerController(controller)',
  'controllerInit = true',
  '}',
];

/// The trimmed lines of the companion object in [path], braces excluded.
/// Fails the test when the companion is missing or never closes.
List<String> _companionLines(String path) {
  final lines = kotlinSource(path).split('\n');
  final start = lines.indexWhere((line) => line.trim() == 'companion object {');
  expect(start, isNot(-1), reason: '$path lacks a companion object');
  final open = lines[start];
  final indent = open.substring(0, open.length - open.trimLeft().length);
  final end = lines.indexWhere((line) => line == '$indent}', start + 1);
  expect(end, isNot(-1), reason: '$path: the companion never closes');
  return [for (final line in lines.sublist(start + 1, end)) line.trim()];
}

/// Whether [lines] holds [run] as a contiguous run.
bool _containsRun(List<String> lines, List<String> run) {
  for (var index = 0; index + run.length <= lines.length; index++) {
    var match = true;
    for (var offset = 0; offset < run.length; offset++) {
      if (lines[index + offset] != run[offset]) {
        match = false;
        break;
      }
    }
    if (match) return true;
  }
  return false;
}

/// The trimmed lines of [path].
List<String> _trimmedLines(String path) =>
    kotlinSource(path).split('\n').map((line) => line.trim()).toList();

void main() {
  group('fork platform channel', () {
    test('the Kotlin side dispatches exactly the methods Dart invokes', () {
      final invoked = RegExp(r"invokeMethod<[^>]+>\('(\w+)'\)")
          .allMatches(File(_dartChannelPath).readAsStringSync())
          .map((match) => match.group(1)!)
          .toList();
      // Anti-vacuity: the scan finds the six Dart methods.
      expect(invoked, [
        'openVpnSettings',
        'tunnelHeld',
        'activeNetwork',
        'moveTaskToBack',
        'restoreBillingTask',
        'finishBillingTasks',
      ]);

      final arms = [
        for (final line in kotlinLines(_channelPath, '" ->'))
          RegExp(r'^"(\w+)" ->').firstMatch(line)!.group(1)!,
      ];
      expect(arms, invoked);
      expect(
        kotlinLines(_channelPath, 'else -> result.notImplemented()'),
        hasLength(1),
      );
    });

    test('the channel name matches the Dart side', () {
      expect(kotlinLines(_channelPath, 'const val CHANNEL'), [
        'const val CHANNEL: String = "${OneVpnPlatformChannel.name}"',
      ]);
    });

    test('openVpnSettings opens the system VPN settings screen', () {
      expect(kotlinLines(_channelPath, 'Settings.ACTION_VPN_SETTINGS'), [
        'activity.startActivity(Intent(Settings.ACTION_VPN_SETTINGS))',
      ]);
    });

    test('the billing task methods reach the fork billing task file', () {
      expect(kotlinLines(_channelPath, 'OneVpnBillingTask.'), [
        '"restoreBillingTask" -> '
            'result.success(OneVpnBillingTask.restore(activity))',
        '"finishBillingTasks" -> '
            'result.success(OneVpnBillingTask.finish(activity))',
      ]);
    });

    test('the billing task restore moves only a running sheet, and the log '
        'names no intent', () {
      expect(kotlinLines(_billingTaskPath, 'const val PROXY'), [
        'private const val PROXY = '
            '"com.android.billingclient.api.ProxyBillingActivity"',
      ]);
      // A task that is not running would restart its spent purchase intent.
      expect(kotlinLines(_billingTaskPath, 'info.isRunning &&'), [
        'info.isRunning && info.topActivity?.className != PROXY',
      ]);
      expect(kotlinLines(_billingTaskPath, 'moveToFront()'), [
        'sheet?.first?.moveToFront()',
      ]);
      // The base intent appears in the selection only, never in the log.
      expect(kotlinLines(_billingTaskPath, 'baseIntent'), [
        'if (info.taskId == activity.taskId || '
            'info.baseIntent.component?.className != PROXY) {',
      ]);
      expect(kotlinLines(_billingTaskPath, 'xtras'), [
        '* It never names the base intent or its extras.',
      ]);
      expect(kotlinLines(_billingTaskPath, 'XLog.'), ['XLog.d(']);
    });

    test('moveTaskToBack moves the task and keeps the activity', () {
      expect(kotlinLines(_channelPath, 'moveTaskToBack('), [
        '"moveTaskToBack" -> result.success(activity.moveTaskToBack(true))',
      ]);
    });

    test('MainActivity registers the channel on the engine', () {
      expect(kotlinLines(_activityPath, 'OneVpnPlatformChannel.setUp('), [
        'OneVpnPlatformChannel.setUp(flutterEngine.dartExecutor, this)',
      ]);
    });
  });

  group('VPN service', () {
    test('the frozen companion constants and the channel id stayed put', () {
      final service = _trimmedLines(_servicePath);
      for (final line in _frozenServiceLines) {
        expect(
          service,
          contains(line),
          reason: 'OneVpnService.kt no longer declares: $line',
        );
      }
    });

    test('the IPv6 TUN address equals the Dart policy', () {
      expect(
        _trimmedLines(_servicePath),
        contains('const val IPV6_ADDRESS = "${PlatformPolicy.tunIpv6Address}"'),
      );
    });

    test('the companion holds the one controller and registers it once', () {
      final companion = _companionLines(_servicePath);
      expect(companion, contains('private val controller = VPNController()'));
      expect(companion, contains('private var controllerInit = false'));
      expect(
        _containsRun(companion, _controllerInitLines),
        isTrue,
        reason:
            'the companion must register the controller once: '
            '${_controllerInitLines.join(' ')}',
      );
      // A second construction or declaration outside the companion brings
      // back the per-instance controller.
      expect(kotlinLines(_servicePath, 'VPNController()'), [
        'private val controller = VPNController()',
      ]);
      expect(kotlinLines(_servicePath, 'var controllerInit'), [
        'private var controllerInit = false',
      ]);
      expect(kotlinLines(_servicePath, 'fun initController('), [
        'private fun initController() {',
      ]);
    });

    test('each hook line appears in the service exactly once', () {
      final service = _trimmedLines(_servicePath);
      for (final hook in _hookLines) {
        expect(
          service.where((line) => line == hook),
          hasLength(1),
          reason: 'the service must reach the delegate exactly here: $hook',
        );
      }
    });

    test('the app excludes itself outside the allow-list mode', () {
      expect(
        normalizedKotlinMethod(_delegatePath, 'fun applyBuilderPolicy('),
        'fun applyBuilderPolicy( builder: VpnService.Builder, tun: TunJson, '
        'selfPackage: String, ) { builder.setMetered(false) '
        'if (tun.perAppVPNMode != PerAppVPNMode.ALLOW) { try { '
        'builder.addDisallowedApplication(selfPackage) } '
        'catch (e: PackageManager.NameNotFoundException) { '
        'XLog.d("OneVpnServiceDelegate: self exclusion failed") '
        'XLog.d(e) } } }',
      );
      // A second call site could run after the allow-list setup.
      expect(kotlinLines(_delegatePath, 'addDisallowedApplication('), [
        'builder.addDisallowedApplication(selfPackage)',
      ]);
    });
  });

  group('native measure cap', () {
    test('the cap is 90 seconds, above the all-dead cap plus the hold cap', () {
      final lines = kotlinLines(_timeoutPath, 'const val TIMEOUT_MS');
      expect(lines, ['const val TIMEOUT_MS: Long = 90_000L']);
      final ms = int.parse(
        RegExp(r'= ([\d_]+)L$')
            .firstMatch(lines.single)!
            .group(1)!
            .replaceAll('_', ''),
      );
      expect(
        OneVpnNativeConnect.allDeadCap + OneVpnNativeConnect.holdCap,
        lessThan(Duration(milliseconds: ms)),
      );
    });

    test('the measure rule tag matches the Dart side', () {
      expect(kotlinLines(_timeoutPath, 'const val MEASURE_BLOCK_RULE_TAG'), [
        'const val MEASURE_BLOCK_RULE_TAG: String = '
            '"$oneVpnMeasureBlockRuleTag"',
      ]);
      expect(kotlinLines(_timeoutPath, 'const val OBSERVATORY_KEY'), [
        'private const val OBSERVATORY_KEY = "burstObservatory"',
      ]);
    });

    test('the classifier needs the observatory and the single block rule', () {
      expect(
        normalizedKotlinMethod(_timeoutPath, 'fun isMeasureConfig('),
        'fun isMeasureConfig(config: JsonObject): Boolean { '
        'if (!config.containsKey(OBSERVATORY_KEY)) return false '
        'val rules = (config["routing"] as? JsonObject)?.get("rules") '
        'as? JsonArray ?: return false '
        'val rule = rules.singleOrNull() as? JsonObject ?: return false '
        'val tag = rule["ruleTag"] as? JsonPrimitive ?: return false '
        'return tag.isString && tag.content == MEASURE_BLOCK_RULE_TAG }',
      );
    });

    test('the expiry stops the tunnel as a user disconnect does', () {
      expect(kotlinLines(_timeoutPath, 'VpnController.stopVpn('), [
        'if (!VpnController.stopVpn(context)) {',
      ]);
    });

    test('the cap is armed and disarmed at exactly its three sites', () {
      expect(kotlinLines(_delegatePath, 'OneVpnMeasureTimeout.'), [
        'OneVpnMeasureTimeout.arm(service)',
        'OneVpnMeasureTimeout.disarm()',
      ]);
      expect(
        normalizedKotlinMethod(_delegatePath, 'fun onTunnelUp('),
        contains('{ OneVpnMeasureTimeout.arm(service) try {'),
      );
      expect(
        normalizedKotlinMethod(_delegatePath, 'fun onTunnelDown('),
        contains('{ OneVpnMeasureTimeout.disarm() try {'),
      );
      expect(kotlinLines(_handoverPath, 'OneVpnMeasureTimeout.arm('), [
        'OneVpnMeasureTimeout.arm(context)',
      ]);
      expect(
        normalizedKotlinMethod(_handoverPath, 'private fun settingsResult('),
        contains(
          'if (outcome != ReloadOutcome.APPLIED) return resultOf(outcome) '
          'if (claimed.renameTo(start)) { '
          'OneVpnMeasureTimeout.arm(context) return resultOf(outcome) }',
        ),
      );
    });
  });
}
