// Pins the exposed surface of the native reload. Every broadcast is
// package scoped. No handover log line carries a decoded request. Every
// handover receiver registers as not exported. No source in the onevpn
// package reads the debuggable flag or gates a receiver on the DUMP
// permission. The manifest declares no receiver and no reload action. The
// in-place reload reads the start snapshot the service writes.

import 'package:flutter_test/flutter_test.dart';

import '../support/kotlin_source.dart';

const _kotlinRoot = 'android/app/src/main/kotlin/net/yuandev/onexray';
const _servicePath = '$_kotlinRoot/vpn/OneVpnService.kt';
const _onevpnDir = '$_kotlinRoot/onevpn';
const _handoverDir = '$_onevpnDir/handover';
const _broadcastPath = '$_handoverDir/OneVpnHandoverBroadcast.kt';
const _hostPath = '$_handoverDir/OneVpnHandoverHost.kt';
const _manifestPath = 'android/app/src/main/AndroidManifest.xml';
const _buildFilePath = 'android/app/build.gradle.kts';

/// Every log line of the handover sources, trimmed, in path order. None
/// logs a decoded request or an exception that can quote one.
const _handoverLogCensus = [
  'OneVpnHandoverHost.kt: '
      'XLog.e("OneVpnHandoverHost: reload request failed", error)',
  'OneVpnHandoverHost.kt: '
      r'XLog.w("OneVpnHandoverHost: reload $requestId outlived its bound")',
  'OneVpnHandoverService.kt: XLog.i(',
  'OneVpnHandoverService.kt: '
      'XLog.e("OneVpnHandover: promote failed, restoring the previous core")',
  'OneVpnHandoverService.kt: '
      r'XLog.i("OneVpnHandover: network change coalesced netIds=$netIds")',
  'OneVpnHandoverService.kt: '
      'XLog.i("OneVpnHandover: resolver change ignored")',
  'OneVpnHandoverService.kt: XLog.i(',
  'OneVpnHandoverService.kt: '
      r'XLog.e("OneVpnHandover: retry failed (${e.javaClass.simpleName})")',
  'OneVpnHandoverService.kt: '
      r'XLog.i("OneVpnHandover: retry trigger=network netIds=$netIds")',
  'OneVpnHandoverService.kt: '
      r'XLog.w("OneVpnHandover: unreadable request ${file.name}")',
  'OneVpnNetworkMonitor.kt: '
      r'XLog.d("OneVpnNetworkMonitor: lost $network")',
  'OneVpnNetworkMonitor.kt: '
      'XLog.e("OneVpnNetworkMonitor: request failed '
      r'(${e.javaClass.simpleName})")',
  'OneVpnNetworkMonitor.kt: '
      r'XLog.d("OneVpnNetworkMonitor: available $network")',
];

void main() {
  test('the running request path matches the service start snapshot', () {
    final service = kotlinSource(_servicePath);
    expect(service, contains('File(this.filesDir.path, "run")'));
    expect(service, contains('File(runPath.path, "start.json")'));
    expect(kotlinCensus(_handoverDir, 'start.json"'), [
      'OneVpnHandoverService.kt: private const val START_RELATIVE_PATH = '
          '"run/start.json"',
    ]);
  });

  group('broadcasts and logs', () {
    test('every broadcast is scoped to this package', () {
      expect(kotlinCensus(_onevpnDir, 'sendBroadcast('), [
        'OneVpnHandoverBroadcast.kt: context.sendBroadcast(',
        'OneVpnHandoverBroadcast.kt: context.sendBroadcast(',
      ]);
      final wire = kotlinSource(_broadcastPath);
      expect(
        wire.replaceAll(RegExp(r'\s+'), ' '),
        contains(
          'private fun scoped(context: Context, action: String): Intent = '
          'Intent(action) .setPackage(context.packageName)',
        ),
      );
      expect(
        RegExp(r'\bscoped\(context, ACTION_').allMatches(wire),
        hasLength(2),
      );
    });

    test('nothing logs a decoded request', () {
      expect(kotlinCensus(_handoverDir, 'XLog.'), _handoverLogCensus);
    });
  });

  group('receivers', () {
    test('two registrations, both not exported, none behind DUMP', () {
      expect(kotlinCensus(_onevpnDir, RegExp(r'(?<!un)registerReceiver\(')), [
        'OneVpnHandoverHost.kt: ContextCompat.registerReceiver(',
        'OneVpnHandoverService.kt: ContextCompat.registerReceiver(',
      ]);
      expect(kotlinCensus(_onevpnDir, 'RECEIVER_NOT_EXPORTED'), [
        'OneVpnHandoverHost.kt: ContextCompat.RECEIVER_NOT_EXPORTED,',
        'OneVpnHandoverService.kt: ContextCompat.RECEIVER_NOT_EXPORTED,',
      ]);
      expect(kotlinCensus(_onevpnDir, 'RECEIVER_EXPORTED'), isEmpty);
      expect(kotlinCensus(_onevpnDir, 'Manifest.permission.DUMP'), isEmpty);
      expect(kotlinCensus(_onevpnDir, 'FLAG_DEBUGGABLE'), isEmpty);
      expect(
        kotlinSource(_hostPath).replaceAll(RegExp(r'\s+'), ' '),
        contains(
          'IntentFilter(OneVpnHandoverBroadcast.ACTION_EVENT), '
          'ContextCompat.RECEIVER_NOT_EXPORTED,',
        ),
      );
    });

    test('the build file never marks a build debuggable', () {
      expect(kotlinSource(_buildFilePath), isNot(contains('ebuggable')));
    });

    test('the manifest declares no receiver and no reload action', () {
      final manifest = kotlinSource(_manifestPath);
      expect(manifest, isNot(contains('<receiver')));
      expect(manifest, isNot(contains('onevpn.')));
    });
  });
}
