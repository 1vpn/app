// Pins the identity surface against upstream merges: no deep-link surface,
// frozen bridge identifiers, and the 1vpn store id. The sweep discovers
// link-surface files rather than pinning paths, so a new manifest or plist
// joins it automatically.
//
// apple_identity_test.dart pins the agreement of the Apple bundle id and
// app group.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Strips comments, so commented-out declarations can neither satisfy nor
/// violate an assertion. It covers XML comments and whole-line // comments
/// in Gradle and Kotlin sources.
String _withoutComments(String source) => source
    .replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '')
    .replaceAll(RegExp(r'^\s*//.*$', multiLine: true), '');

/// Null when the file is missing. Callers treat null as failure because
/// `isNot(contains(...))` passes against a null actual.
String? _read(String path) {
  final file = File(path);
  return file.existsSync() ? _withoutComments(file.readAsStringSync()) : null;
}

/// Directory names that never hold the project's own declarations. Build
/// output and fetched dependencies under them would make the sweep
/// nondeterministic.
const Set<String> _foreignDirs = {
  'build',
  'Pods',
  '.symlinks',
  '.gradle',
  'ephemeral',
};

/// Every file that can declare an OS-level link surface on a shipping
/// platform: Android manifests and Apple Info.plists under android/ and
/// ios/. macos/ and macos_se/ are excluded. Neither is a shipping target
/// here, and both keep upstream text.
List<String> _linkSurfacePaths() {
  final paths = <String>[];
  for (final root in const ['android', 'ios']) {
    final dir = Directory(root);
    if (!dir.existsSync()) continue;
    for (final entity in dir.listSync(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final segments = entity.path.split(Platform.pathSeparator);
      final name = segments.last;
      if (name != 'AndroidManifest.xml' && name != 'Info.plist') continue;
      if (segments.any(_foreignDirs.contains)) continue;
      paths.add(entity.path);
    }
  }
  return paths..sort();
}

/// The value of the Gradle assignment `name = "..."`, or null when the
/// source or the assignment is missing.
String? _gradleString(String? source, String name) => source == null
    ? null
    : RegExp(
        '^\\s*$name = "([^"]+)"\$',
        multiLine: true,
      ).firstMatch(source)?.group(1);

/// The channel names messages.g.dart allocates. The generated code builds
/// each name as a literal prefix plus a runtime suffix. The prefix is the
/// frozen identifier this sweep pins. Empty when the file is missing, which
/// fails the comparison loudly.
Set<String> _declaredChannelNames(String? source) => source == null
    ? const {}
    : RegExp(r'dev\.flutter\.pigeon\.[\w.]+')
          .allMatches(source)
          .map((m) => m.group(0)!)
          .toSet();

/// Every platform channel the pigeon bridge allocates. These names are
/// frozen identifiers, never part of the rebrand.
const List<String> _pigeonChannelNames = [
  'dev.flutter.pigeon.onexray.BridgeFlutterApi.refreshVpn',
  'dev.flutter.pigeon.onexray.BridgeFlutterApi.vpnStatusChanged',
  'dev.flutter.pigeon.onexray.BridgeHostApi.appleVpnCapabilities',
  'dev.flutter.pigeon.onexray.BridgeHostApi.getAppIcon',
  'dev.flutter.pigeon.onexray.BridgeHostApi.getCurrentAppIcon',
  'dev.flutter.pigeon.onexray.BridgeHostApi.getInstalledApps',
  'dev.flutter.pigeon.onexray.BridgeHostApi.getTunFilesDir',
  'dev.flutter.pigeon.onexray.BridgeHostApi.invoke',
  'dev.flutter.pigeon.onexray.BridgeHostApi.openLaunchAtLoginSettings',
  'dev.flutter.pigeon.onexray.BridgeHostApi.queryLaunchAtLogin',
  'dev.flutter.pigeon.onexray.BridgeHostApi.queryPlatformPermission',
  'dev.flutter.pigeon.onexray.BridgeHostApi.readVpnStatus',
  'dev.flutter.pigeon.onexray.BridgeHostApi.requestPlatformPermission',
  'dev.flutter.pigeon.onexray.BridgeHostApi.setAppIcon',
  'dev.flutter.pigeon.onexray.BridgeHostApi.setLaunchAtLogin',
  'dev.flutter.pigeon.onexray.BridgeHostApi.startVpn',
  'dev.flutter.pigeon.onexray.BridgeHostApi.stopVpn',
  'dev.flutter.pigeon.onexray.BridgeHostApi.useSystemExtension',
];

void main() {
  group('link-surface sweep', () {
    late List<String> paths;

    setUp(() {
      paths = _linkSurfacePaths();
    });

    // Anti-vacuity guard: an empty sweep would let every negative below
    // pass.
    test('discovers the known declaration files', () {
      expect(
        paths,
        containsAll(const [
          'android/app/src/debug/AndroidManifest.xml',
          'android/app/src/main/AndroidManifest.xml',
          'android/app/src/profile/AndroidManifest.xml',
          'ios/Runner/Info.plist',
          'ios/tunnel/Info.plist',
        ]),
      );
    });

    test('no manifest or plist declares a URI scheme or upstream host', () {
      for (final path in paths) {
        final content = _read(path);
        expect(content, isNotNull, reason: '$path vanished mid-sweep');
        // Case-sensitive: the scheme and host are lowercase. A separate pin
        // covers the OneXray display name.
        expect(
          content,
          isNot(contains('onexray')),
          reason: '$path names the upstream scheme or identifier',
        );
        expect(
          content,
          isNot(matches(RegExp('onexray\\.com', caseSensitive: false))),
          reason: '$path names the upstream host in some casing',
        );
        if (path.endsWith('AndroidManifest.xml')) {
          expect(
            content,
            isNot(contains('android.intent.category.BROWSABLE')),
            reason: '$path reopens a browsable entry point',
          );
          // A <queries> entry makes other apps visible and claims nothing.
          expect(
            content!.replaceAll(
              RegExp(r'<queries\b.*?</queries>', dotAll: true),
              '',
            ),
            isNot(contains('android:scheme=')),
            reason: '$path claims a URI scheme, whatever its value',
          );
        } else {
          expect(
            content,
            isNot(contains('CFBundleURLTypes')),
            reason: '$path registers a URL type and none may ship',
          );
        }
      }
    });
  });

  group('Android store identity', () {
    late String? gradle;

    setUp(() {
      gradle = _read('android/app/build.gradle.kts');
    });

    // Anti-vacuity guard: both pins below parse this same load.
    test('the Gradle file still loads', () {
      expect(gradle, isNotNull);
    });

    test('the namespace stays on upstream identifier', () {
      expect(
        _gradleString(gradle, 'namespace'),
        equals('net.yuandev.onexray'),
        reason:
            'the namespace is a frozen identifier; the Kotlin package and '
            'the pigeon channel names embed it independently per side, and '
            'an unsynchronized rename breaks the bridge silently',
      );
    });

    test('the applicationId stays on the 1vpn store id', () {
      expect(
        _gradleString(gradle, 'applicationId'),
        equals('com.one.vpnapp'),
        reason:
            'this is the install and store identity existing users update '
            'in place; a change forks the listing',
      );
    });
  });

  group('pigeon channel names', () {
    test('all 18 stay byte-identical', () {
      final declared = _declaredChannelNames(
        _read('lib/core/pigeon/messages.g.dart'),
      );
      expect(
        declared,
        hasLength(_pigeonChannelNames.length),
        reason:
            'the bridge allocates exactly these channels; a new or removed '
            'one must be mirrored in the Kotlin and Swift bridges first',
      );
      expect(
        declared,
        equals(_pigeonChannelNames.toSet()),
        reason:
            'these names are hardcoded again in the Kotlin and Swift '
            'bridges; the sides meet only at runtime, so a rename that is '
            'not byte-identical everywhere leaves calls unanswered and the '
            'tunnel never starts',
      );
    });
  });

  group('notification channels', () {
    test('the tunnel channel keeps the 1vpn id', () {
      final service = _read(
        'android/app/src/main/kotlin/net/yuandev/onexray/vpn/'
        'OneVpnService.kt',
      );
      expect(service, isNotNull, reason: 'OneVpnService.kt moved');
      expect(
        RegExp(r'val channelId = "([^"]+)"').firstMatch(service!)?.group(1),
        equals('com.one.vpnapp.tunnel'),
        reason:
            'the id is user-visible in system notification settings, and '
            'Android keys per-channel user choices to it; a rename discards '
            'those choices and strands the old channel',
      );
    });

    // The first shown notification creates the Dart-side channel lazily.
    // Its id and labels appear in system settings, so both carry the 1vpn
    // identity.
    test('the app channel carries the 1vpn id and label', () {
      final service = _read('lib/service/shared/notification/service.dart');
      expect(service, isNotNull, reason: 'notification service moved');
      final details = RegExp(
        r"AndroidNotificationDetails\(\s*'([^']+)',\s*'([^']+)',",
      ).firstMatch(service!);
      expect(details, isNotNull, reason: 'channel construction moved');
      expect(details!.group(1), equals('com.one.vpnapp'));
      expect(details.group(2), equals('1VPN'));
    });
  });

  // The label names the launcher activity, the quick-settings tile, and
  // the tunnel notification channel. The brand name is not translated, so
  // every locale carries the same value.
  group('android launcher and tile label', () {
    const locales = ['values', 'values-fa', 'values-ru', 'values-zh'];
    for (final locale in locales) {
      test('$locale pins the 1VPN label', () {
        final strings = _read('android/app/src/main/res/$locale/strings.xml');
        expect(strings, isNotNull, reason: '$locale/strings.xml moved');
        expect(
          RegExp(r'name="quick_settings_tile_label">([^<]+)<')
              .firstMatch(strings!)
              ?.group(1),
          equals('1VPN'),
        );
      });
    }
  });
}
