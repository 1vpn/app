// Asserts the iOS identity family across every file that states it. The
// entitlements grant the app group. Constants.swift returns the group and
// the tunnel bundle id at runtime. The signing xcconfigs set both bundle
// ids. No build compiles these files together. The app finds its extension
// by bundle id at runtime, so a mismatch ships silently and the tunnel
// never starts. The test gate runs no Apple build, so source is the only
// surface that can hold the family in sync.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Strips comments, so commented-out lines can neither satisfy nor violate
/// an assertion. It covers XML comments and whole-line // comments in
/// xcconfig and Swift sources.
String _withoutComments(String source) => source
    .replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '')
    .replaceAll(RegExp(r'^\s*//.*$', multiLine: true), '');

/// Null when the file is missing. Callers treat null as failure so a moved
/// file fails loudly instead of passing vacuously.
String? _read(String path) {
  final file = File(path);
  return file.existsSync() ? _withoutComments(file.readAsStringSync()) : null;
}

/// The string values an entitlements plist grants under [key], or null
/// when the file or the entitlement is missing.
List<String>? _grantedStrings(String path, String key) {
  final plist = _read(path);
  if (plist == null) return null;
  final array = RegExp(
    '<key>${RegExp.escape(key)}</key>\\s*<array>(.*?)</array>',
    dotAll: true,
  ).firstMatch(plist)?.group(1);
  if (array == null) return null;
  return RegExp(r'<string>([^<]+)</string>')
      .allMatches(array)
      .map((m) => m.group(1)!)
      .toList();
}

/// The app-group ids an entitlements plist grants.
List<String>? _entitlementGroups(String path) =>
    _grantedStrings(path, 'com.apple.security.application-groups');

/// The literal of the Swift constant `let <name> = "..."`. The runtime
/// value comes from these declarations. The test reads them by name, so a
/// rename fails the loads-guard.
String? _swiftConstant(String? source, String name) => source == null
    ? null
    : RegExp('let $name = "([^"]+)"').firstMatch(source)?.group(1);

/// The bundle id a signing xcconfig sets, or null when the file or the
/// setting is missing.
String? _bundleId(String path) {
  final config = _read(path);
  if (config == null) return null;
  return RegExp(
    r'^\s*PRODUCT_BUNDLE_IDENTIFIER\s*=\s*(\S+)\s*$',
    multiLine: true,
  ).firstMatch(config)?.group(1);
}

/// The keys that sign a target. Each matches with or without a condition.
const _signingKeys =
    r'^\s*"?(CODE_SIGN_IDENTITY|CODE_SIGN_STYLE|DEVELOPMENT_TEAM|'
    r'PRODUCT_BUNDLE_IDENTIFIER|PROVISIONING_PROFILE_SPECIFIER)\b';

/// Each target build configuration that names a base xcconfig, as the file
/// name and the build settings body.
List<(String, String)> _targetSettings() {
  final pbx = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
  return RegExp(
    r'baseConfigurationReference = \w+ /\* ([\w-]+\.xcconfig) \*/;\s*'
    r'buildSettings = \{(.*?)\n\t\t\t\};',
    dotAll: true,
  ).allMatches(pbx).map((m) => (m.group(1)!, m.group(2)!)).toList();
}

void main() {
  const appEntitlements = 'ios/Runner/Runner.entitlements';
  const tunnelEntitlements = 'ios/tunnel/tunnel.entitlements';

  late List<String>? appGroups;
  late List<String>? tunnelGroups;
  late String? swiftGroup;
  late String? swiftTunnelId;
  late String? appBundleId;
  late String? tunnelBundleId;

  setUp(() {
    final constants = _read('swift/All/Constants.swift');
    appGroups = _entitlementGroups(appEntitlements);
    tunnelGroups = _entitlementGroups(tunnelEntitlements);
    swiftGroup = _swiftConstant(constants, 'groupAppGroupId');
    swiftTunnelId = _swiftConstant(constants, 'tunId');
    appBundleId = _bundleId('ios/Signing/Runner.xcconfig');
    tunnelBundleId = _bundleId('ios/Signing/Tunnel.xcconfig');
  });

  group('iOS identity family', () {
    // Anti-vacuity guard: every comparison below reads these same loads. A
    // moved file, a renamed constant, or a broken pattern fails here instead
    // of passing vacuously there.
    test('every source still states its identity values', () {
      expect(appGroups, isNotNull, reason: '$appEntitlements grants no group');
      expect(
        tunnelGroups,
        isNotNull,
        reason: '$tunnelEntitlements grants no group',
      );
      expect(
        swiftGroup,
        isNotNull,
        reason: 'Constants.swift declares no groupAppGroupId',
      );
      expect(
        swiftTunnelId,
        isNotNull,
        reason: 'Constants.swift declares no tunId',
      );
      expect(
        appBundleId,
        isNotNull,
        reason: 'ios/Signing/Runner.xcconfig sets no bundle id',
      );
      expect(
        tunnelBundleId,
        isNotNull,
        reason: 'ios/Signing/Tunnel.xcconfig sets no bundle id',
      );
    });

    // The provisioning profiles list exactly one group per target. A second
    // group in either file would need portal registration to sign.
    test('both targets are granted exactly one app group, and they agree', () {
      expect(appGroups, isNotNull);
      expect(tunnelGroups, isNotNull);
      expect(appGroups, hasLength(1));
      expect(tunnelGroups, hasLength(1));
      expect(
        appGroups,
        equals(tunnelGroups),
        reason: 'the shared container only exists when both grants match',
      );
    });

    test('the runtime group constant matches the granted group', () {
      expect(appGroups, isNotNull);
      expect(
        swiftGroup,
        equals(appGroups!.single),
        reason:
            'appGroupId() must return the granted group or the app and the '
            'tunnel read different containers',
      );
    });

    test('the runtime tunnel id matches the tunnel bundle id', () {
      expect(
        swiftTunnelId,
        equals(tunnelBundleId),
        reason:
            'the app locates its extension by this id; a mismatch means the '
            'tunnel never starts',
      );
    });

    test('the group id derives from the app bundle id', () {
      expect(appGroups, isNotNull);
      expect(
        appGroups!.single,
        equals('group.$appBundleId'),
        reason: 'the registered group is the app bundle id under group.',
      );
    });

    // The platform requires an embedded extension id to extend the app id.
    test('the tunnel bundle id extends the app bundle id', () {
      expect(tunnelBundleId, isNotNull);
      expect(tunnelBundleId, startsWith('$appBundleId.'));
    });
  });

  // Signing lives in the ios/Signing xcconfigs. A target-level key
  // shadows its base xcconfig. Project-level keys resolve below it.
  group('iOS signing layers', () {
    test('the six target configurations take the Signing base xcconfigs', () {
      final settings = _targetSettings();
      expect(settings.map((entry) => entry.$1).toList()..sort(), [
        'Runner-Debug.xcconfig',
        'Runner-Release.xcconfig',
        'Runner-Release.xcconfig',
        'Tunnel.xcconfig',
        'Tunnel.xcconfig',
        'Tunnel.xcconfig',
      ]);
    });

    test('no target configuration sets a signing key', () {
      final settings = _targetSettings();
      // Anti-vacuity guard. The six target configurations parsed.
      expect(settings, hasLength(6));
      for (final (base, body) in settings) {
        expect(
          RegExp(_signingKeys, multiLine: true).hasMatch(body),
          isFalse,
          reason: 'a target configuration on $base shadows the xcconfig',
        );
      }
    });
  });

  // The app and the tunnel extension each state a display name. The app
  // states it in its plist. No app configuration generates a plist, so the
  // pbxproj label never reaches the bundle. The tunnel states it in
  // Tunnel.xcconfig. A target-level setting would shadow that value, so no
  // tunnel build configuration sets the key. The extension keeps a distinct
  // name so system listings show which entry is which.
  test('the iOS launcher label is 1VPN', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    for (final key in ['CFBundleDisplayName', 'CFBundleName']) {
      final m = RegExp('<key>$key</key>\\s*<string>([^<]*)</string>')
          .firstMatch(plist);
      expect(m, isNotNull, reason: '$key is missing from the plist');
      expect(m!.group(1), '1VPN', reason: '$key names the app users see');
    }
    final app = _targetSettings()
        .where((entry) => entry.$1.startsWith('Runner-'))
        .map((entry) => entry.$2)
        .toList();
    // Anti-vacuity guard. Debug, Release and Profile each take a Runner file.
    expect(app, hasLength(3));
    for (final settings in app) {
      expect(settings, contains('INFOPLIST_FILE = Runner/Info.plist;'));
      expect(
        settings,
        isNot(contains('GENERATE_INFOPLIST_FILE')),
        reason: 'a generated plist takes the pbxproj label',
      );
    }

    final tunnel = _read('ios/Signing/Tunnel.xcconfig');
    expect(tunnel, isNotNull, reason: 'ios/Signing/Tunnel.xcconfig moved');
    expect(
      RegExp(
        r'^\s*INFOPLIST_KEY_CFBundleDisplayName\s*=\s*(.+?)\s*$',
        multiLine: true,
      ).firstMatch(tunnel!)?.group(1),
      '1VPN Tunnel',
      reason: 'Tunnel.xcconfig names the extension in system listings',
    );
    final tunnelSettings = _targetSettings()
        .where((entry) => entry.$1 == 'Tunnel.xcconfig')
        .map((entry) => entry.$2)
        .toList();
    // Anti-vacuity guard. Debug, Release and Profile each take the file.
    expect(tunnelSettings, hasLength(3));
    for (final settings in tunnelSettings) {
      expect(settings, contains('CODE_SIGN_ENTITLEMENTS'));
      expect(
        settings,
        isNot(contains('INFOPLIST_KEY_CFBundleDisplayName')),
        reason: 'a tunnel configuration shadows the xcconfig label',
      );
    }
  });
}
