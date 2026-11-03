// The start shortcut over a fake quick-actions channel.
//
// The app registers one shortcut, startVpn, with its title and its icon. The
// id is the one the quick-settings tile looks up. The inactive tile reads
// Disconnected. The activity drops the shortcut's extra from a restored or
// history launch before the plugin reads it. A launch goes to the attached
// handler once per launch. A cold start's launch is held until a handler
// attaches and runs once. A launch held past the bound, by elapsed time or by
// the wall clock, is dropped at the attach. A backward clock step drops no
// fresh launch. A later launch renews the hold. A launch of another type runs
// nothing. The plugin initializes once. Off mobile the shortcut sends nothing.
// The extra key the activity drops equals the plugin's.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/shell/start_shortcut.dart';

import '../support/quick_actions_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('publishes the start shortcut alone, with its title and icon', () async {
    final channel = FakeQuickActionsChannel();
    final shortcut = OneVpnStartShortcut(mobile: true);

    await shortcut.publish('Start VPN');

    expect(channel.published, [
      [
        {
          'type': 'startVpn',
          'localizedTitle': 'Start VPN',
          'icon': 'start_vpn',
        },
      ],
    ]);
    expect(
      File('android/app/src/main/res/drawable/start_vpn.xml').existsSync(),
      isTrue,
    );
    expect(
      File('ios/Runner/Assets.xcassets/start_vpn.imageset/Contents.json')
          .existsSync(),
      isTrue,
    );
  });

  test('a new title publishes again, a repeated one does not', () async {
    final channel = FakeQuickActionsChannel();
    final shortcut = OneVpnStartShortcut(mobile: true);

    await shortcut.publish('Start VPN');
    await shortcut.publish('Start VPN');
    await shortcut.publish('Старт VPN');

    expect(channel.published.map((items) => items.single['localizedTitle']), [
      'Start VPN',
      'Старт VPN',
    ]);
  });

  test('the id is the one the quick-settings tile looks up', () {
    final controller = File(
      'android/app/src/main/kotlin/net/yuandev/onexray/vpn/VpnController.kt',
    ).readAsStringSync();
    expect(
      controller,
      contains(
        '?.dynamicShortcuts?.firstOrNull { it.id == '
        '"${OneVpnStartShortcut.type}" }',
      ),
    );
  });

  test('the inactive tile reads Disconnected', () {
    final tile = File(
      'android/app/src/main/kotlin/net/yuandev/onexray/tile/'
      'OneQuickSettingsTileService.kt',
    ).readAsStringSync();
    expect(
      tile,
      matches(
        RegExp(
          r'running -> getString\(R\.string\.quick_settings_tile_status_connected\)'
          r'\s*else -> getString\(R\.string\.quick_settings_tile_status_disconnected\)',
        ),
      ),
    );
    expect(tile, isNot(contains('quick_settings_tile_status_open_app')));
  });

  test('a restored or history launch drops the shortcut extra before the '
      'plugin reads it', () {
    final activity = File(
      'android/app/src/main/kotlin/net/yuandev/onexray/MainActivity.kt',
    ).readAsStringSync();
    final onCreate = activity.indexOf(
      'override fun onCreate(savedInstanceState: Bundle?)',
    );
    final drop = activity.indexOf(
      'OneVpnStartShortcutIntent.dropReplayedLaunch(intent, savedInstanceState)',
    );
    final superCreate = activity.indexOf('super.onCreate(savedInstanceState)');
    expect(onCreate, isNonNegative);
    expect(drop, greaterThan(onCreate));
    expect(superCreate, greaterThan(drop));

    final helper = File(
      'android/app/src/main/kotlin/net/yuandev/onexray/onevpn/'
      'OneVpnStartShortcutIntent.kt',
    ).readAsStringSync();
    expect(
      helper,
      contains('const val EXTRA_ACTION: String = "some unique action key"'),
    );
    expect(
      helper,
      matches(
        RegExp(
          r'if \(savedInstanceState != null \|\|\s*'
          r'\(intent\.flags and Intent\.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY\) '
          r'!= 0\s*\) \{\s*intent\.removeExtra\(EXTRA_ACTION\)\s*\}',
        ),
      ),
    );
  });

  final quickActionsAndroid = _quickActionsAndroidRoot();
  test(
    "the extra key the activity drops equals the plugin's EXTRA_ACTION",
    () {
      final plugin = File(
        '${quickActionsAndroid!.path}/android/src/main/java/io/flutter/'
        'plugins/quickactions/QuickActions.java',
      ).readAsStringSync();
      final declaration = RegExp(
        r'^\s*static final String EXTRA_ACTION = "([^"]*)";',
        multiLine: true,
      ).firstMatch(plugin);
      expect(
        declaration?.group(0)?.trim(),
        'static final String EXTRA_ACTION = "some unique action key";',
      );

      final helper = File(
        'android/app/src/main/kotlin/net/yuandev/onexray/onevpn/'
        'OneVpnStartShortcutIntent.kt',
      ).readAsStringSync();
      final key = RegExp(r'const val EXTRA_ACTION: String = "([^"]*)"')
          .firstMatch(helper)
          ?.group(1);
      expect(key, declaration?.group(1));
    },
    skip: quickActionsAndroid == null
        ? 'quick_actions_android does not resolve through '
              '.dart_tool/package_config.json: run flutter pub get'
        : false,
  );

  test('a launch runs the attached handler once per launch', () async {
    final channel = FakeQuickActionsChannel();
    final shortcut = OneVpnStartShortcut(mobile: true);
    await shortcut.initialize();
    var runs = 0;
    shortcut.attach(() => runs++);

    await channel.launch('startVpn');
    expect(runs, 1);
    await channel.launch('startVpn');
    expect(runs, 2);
    await channel.launch('stopVpn');
    expect(runs, 2);
  });

  test('a cold start launch waits for the attach and runs once', () async {
    final channel = FakeQuickActionsChannel(launchAction: 'startVpn');
    final shortcut = OneVpnStartShortcut(mobile: true);
    await shortcut.initialize();
    // A second launch before the attach is held in the same slot.
    await channel.launch('startVpn');

    var runs = 0;
    void handler() => runs++;
    shortcut.attach(handler);
    expect(runs, 1);

    shortcut.detach(handler);
    shortcut.attach(handler);
    expect(runs, 1);
  });

  test('a launch held for 29 seconds runs once at the attach', () async {
    FakeQuickActionsChannel(launchAction: 'startVpn');
    var elapsed = Duration.zero;
    final shortcut = OneVpnStartShortcut(mobile: true, elapsed: () => elapsed);
    await shortcut.initialize();
    var runs = 0;
    void handler() => runs++;

    elapsed += const Duration(seconds: 29);
    shortcut.attach(handler);
    expect(runs, 1);

    shortcut.detach(handler);
    shortcut.attach(handler);
    expect(runs, 1);
  });

  test('a launch held for 31 seconds is dropped at the attach', () async {
    final logs = <String?>[];
    final previous = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) => logs.add(message);
    addTearDown(() => debugPrint = previous);
    FakeQuickActionsChannel(launchAction: 'startVpn');
    var elapsed = Duration.zero;
    final shortcut = OneVpnStartShortcut(mobile: true, elapsed: () => elapsed);
    await shortcut.initialize();
    var runs = 0;
    void handler() => runs++;

    elapsed += const Duration(seconds: 31);
    shortcut.attach(handler);

    expect(runs, 0);
    expect(logs, [
      'OneVpnStartShortcut: launch held',
      'OneVpnStartShortcut: launch held expired',
    ]);
    // The slot is empty. A later attach runs nothing.
    shortcut.detach(handler);
    shortcut.attach(handler);
    expect(runs, 0);
  });

  test('a launch held across a wall-clock jump is dropped', () async {
    final logs = <String?>[];
    final previous = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) => logs.add(message);
    addTearDown(() => debugPrint = previous);
    FakeQuickActionsChannel(launchAction: 'startVpn');
    var elapsed = Duration.zero;
    var now = DateTime.utc(2026, 10, 27, 12);
    final shortcut = OneVpnStartShortcut(
      mobile: true,
      elapsed: () => elapsed,
      now: () => now,
    );
    await shortcut.initialize();
    var runs = 0;

    elapsed += const Duration(seconds: 5);
    now = now.add(const Duration(seconds: 40));
    shortcut.attach(() => runs++);

    expect(runs, 0);
    expect(logs, [
      'OneVpnStartShortcut: launch held',
      'OneVpnStartShortcut: launch held expired',
    ]);
  });

  test('a backward clock step does not drop a fresh launch', () async {
    FakeQuickActionsChannel(launchAction: 'startVpn');
    var elapsed = Duration.zero;
    var now = DateTime.utc(2026, 10, 27, 12);
    final shortcut = OneVpnStartShortcut(
      mobile: true,
      elapsed: () => elapsed,
      now: () => now,
    );
    await shortcut.initialize();
    var runs = 0;

    elapsed += const Duration(seconds: 5);
    now = now.subtract(const Duration(seconds: 10));
    shortcut.attach(() => runs++);

    expect(runs, 1);
  });

  test('a later launch renews the hold', () async {
    final channel = FakeQuickActionsChannel(launchAction: 'startVpn');
    var elapsed = Duration.zero;
    final shortcut = OneVpnStartShortcut(mobile: true, elapsed: () => elapsed);
    await shortcut.initialize();
    var runs = 0;
    void handler() => runs++;

    elapsed += const Duration(seconds: 25);
    await channel.launch('startVpn');
    // Ten seconds after the renewal and 35 after the first hold.
    elapsed += const Duration(seconds: 10);
    shortcut.attach(handler);
    expect(runs, 1);

    shortcut.detach(handler);
    shortcut.attach(handler);
    expect(runs, 1);
  });

  test('a launch after the detach waits for the next attach', () async {
    final channel = FakeQuickActionsChannel();
    final shortcut = OneVpnStartShortcut(mobile: true);
    await shortcut.initialize();
    var first = 0;
    var second = 0;
    void firstHandler() => first++;
    void secondHandler() => second++;

    shortcut.attach(firstHandler);
    shortcut.detach(firstHandler);
    await channel.launch('startVpn');
    expect(first, 0);

    shortcut.attach(secondHandler);
    expect(second, 1);
    // A stale detach leaves the attached handler in place.
    shortcut.detach(firstHandler);
    await channel.launch('startVpn');
    expect(second, 2);
    expect(first, 0);
  });

  test('a cold start launch of another type is dropped', () async {
    FakeQuickActionsChannel(launchAction: 'stopVpn');
    final shortcut = OneVpnStartShortcut(mobile: true);
    await shortcut.initialize();
    var runs = 0;

    shortcut.attach(() => runs++);

    expect(runs, 0);
  });

  test('the plugin initializes once, and a failure retries', () async {
    final channel = FakeQuickActionsChannel()
      ..launchError = PlatformException(code: 'no_activity');
    final shortcut = OneVpnStartShortcut(mobile: true);

    await shortcut.initialize();
    expect(channel.launchReads, 1);
    await shortcut.initialize();
    expect(channel.launchReads, 2);
    await shortcut.initialize();
    expect(channel.launchReads, 2);
  });

  test('off mobile the shortcut sends nothing', () async {
    final channel = FakeQuickActionsChannel(launchAction: 'startVpn');
    final shortcut = OneVpnStartShortcut(mobile: false);
    var runs = 0;

    await shortcut.initialize();
    await shortcut.publish('Start VPN');
    shortcut.attach(() => runs++);

    expect(channel.launchReads, 0);
    expect(channel.published, isEmpty);
    expect(runs, 0);
  });
}

/// The root of the quick_actions_android package, from its rootUri in
/// .dart_tool/package_config.json, or null when the host has not resolved
/// it.
Directory? _quickActionsAndroidRoot() {
  final config = File('.dart_tool/package_config.json');
  if (!config.existsSync()) return null;
  final packages =
      (jsonDecode(config.readAsStringSync()) as Map)['packages'] as List;
  for (final package in packages.cast<Map>()) {
    if (package['name'] != 'quick_actions_android') continue;
    final root = Directory.fromUri(
      config.absolute.uri.resolve(package['rootUri'] as String),
    );
    return root.existsSync() ? root : null;
  }
  return null;
}
