// Pins the Advanced tab cut against upstream merges. The product ships no
// advanced diagnostics UI. These surfaces stay absent from lib:
//
// - the Advanced tab shell and its root entry
// - the per-platform tunnel pages and their policy editor
// - the Xray runtime page, its log-policy writer, and its log reader
// - the log viewer
// - the ping settings page
// - the geodata management pages
// - the data-update settings page
//
// The sweep reads every file the two app entries reach. Restored upstream
// code joins it once an entry imports it.
//
// The headless services stay whole and out of scope. The ping service
// measures server delay. The geodata updater refreshes the bundled
// defaults on its scheduler. The platform policy compiles the tunnel
// start. The tests below pin their boot wiring.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/service/advanced/platform_policy.dart';

import 'support/lib_closure.dart';

void main() {
  late List<File> sources;
  late Map<String, String> contents;

  setUpAll(() {
    sources = libClosureSources();
    contents = {for (final file in sources) file.path: file.readAsStringSync()};
  });

  // Anti-vacuity guard: the sweep reads a real tree before any negative
  // below counts. The kept headless services are present, and the sweep
  // must not flag them.
  test('discovers the tree and reads the kept headless services', () {
    expect(sources.length, greaterThan(200));
    expect(
      contents['lib/service/shared/ping/service.dart'],
      contains('class PingService'),
    );
    expect(
      contents['lib/service/advanced/xray/geodata/service.dart'],
      contains('updateDefaults'),
    );
    expect(
      contents['lib/service/advanced/platform_policy.dart'],
      contains('toTun'),
    );
  });

  test('the advanced pages, their tab shell, and their routes are gone', () {
    expect(
      Directory('lib/pages/advanced').existsSync(),
      isFalse,
      reason: 'lib/pages/advanced returned',
    );
    expect(
      File('lib/pages/main/advanced.dart').existsSync(),
      isFalse,
      reason: 'lib/pages/main/advanced.dart returned',
    );
    for (final entry in contents.entries) {
      for (final marker in const [
        'AdvancedRootPage',
        'AdvancedPage',
        'AdvancedController',
        'AdvancedTabVisibility',
        'XrayRuntimePage',
        'VpnTunnelPane',
        'PingPage',
        'LogFileViewerPage',
        'LogFileViewerParams',
        'GeoDataPage',
        'GeoDataFilePage',
        'AutoUpdatePage',
        'AndroidAppsPage',
        'AppleVpnPage',
        'AppleWifiPage',
        'WindowsVpnPage',
        'OutboundInterfacePage',
        'apple-vpn',
        'android-vpn',
        'outbound-interface',
        'log-file',
        'auto-update',
      ]) {
        expect(
          entry.value,
          isNot(contains(marker)),
          reason: '${entry.key} reintroduces an advanced surface via $marker',
        );
      }
    }
  });

  test('no advanced primary destination returns', () {
    expect(
      File('lib/pages/main/navigation.dart').existsSync(),
      isFalse,
      reason: 'lib/pages/main/navigation.dart returned',
    );
    for (final entry in contents.entries) {
      for (final marker in const [
        'advanced("/advanced")',
        '"/advanced"',
        "'/advanced'",
        'AppPrimaryDestination.advanced',
      ]) {
        expect(
          entry.value,
          isNot(contains(marker)),
          reason:
              '${entry.key} reintroduces the advanced primary destination '
              'via $marker',
        );
      }
    }
  });

  test('the tunnel policy editor and per-app icon loader are gone', () {
    for (final entry in contents.entries) {
      for (final marker in const [
        'PolicyEditorService',
        'PolicyEditorDraft',
        'PolicyEditorController',
        'TunnelDestination',
        'AppIconService',
      ]) {
        expect(
          entry.value,
          isNot(contains(marker)),
          reason:
              '${entry.key} reintroduces the tunnel settings surface '
              'via $marker',
        );
      }
    }
  });

  test('the log surface is gone and compiled logs stay off by default', () {
    for (final entry in contents.entries) {
      for (final marker in const [
        'saveRuntimeLogPolicy',
        'RuntimeDiagnosticFiles',
      ]) {
        expect(
          entry.value,
          isNot(contains(marker)),
          reason: '${entry.key} reintroduces the log surface via $marker',
        );
      }
    }
    // With no surface writing a log policy, the compiled configuration
    // keeps logs off through this default.
    expect(PlatformPolicy.defaults().logEnabled, isFalse);
  });

  test('the removed page strings carry no dead promises', () {
    for (final entry in contents.entries) {
      // The generated localizations declare every upstream key. Only a
      // read elsewhere shows a removed string.
      if (entry.key.startsWith('lib/l10n/localizations/')) continue;
      for (final marker in const [
        'speedSummary',
        'prototypeSpeedTestSavedNotice',
        'prototypeDownloadCompatibilityHint',
      ]) {
        expect(
          entry.value,
          isNot(contains(marker)),
          reason: '${entry.key} reintroduces a removed string via $marker',
        );
      }
    }
  });

  test('the headless survivors stay wired at boot', () {
    expect(
      contents['lib/service/manager.dart'],
      isNot(contains('PingService().startAutomatic()')),
      reason:
          'the launch-time probe burst is removed; the boot provisioner '
          'fills the outbound table, so a burst would fan probes across every '
          'node before any connect intent',
    );
    expect(
      contents['lib/service/manager.dart'],
      contains('BackgroundTaskService().init('),
      reason: 'startup no longer starts the data-update scheduler',
    );
    expect(
      contents['lib/service/advanced/xray/data_update/service.dart'],
      contains('GeoDataService().updateDefaults()'),
      reason: 'the scheduler path no longer refreshes the bundled defaults',
    );
  });
}
