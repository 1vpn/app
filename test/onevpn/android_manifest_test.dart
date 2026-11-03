// Asserts the shipped Android manifest and data-extraction rules as files.
// Nothing else loads them before an APK exists. This reads the source
// manifest only. The merged manifest can gain dependency entries and lives
// under gitignored build/. The aapt2 audit of a built APK covers it.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Strips comments, so commented-out XML can neither satisfy nor violate an
/// assertion.
String _withoutComments(String xml) =>
    xml.replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');

String _readManifest() => _withoutComments(
  File('android/app/src/main/AndroidManifest.xml').readAsStringSync(),
);

/// [xml] without its `<queries>` block. A query makes other apps visible
/// and claims no scheme.
String _withoutQueries(String xml) =>
    xml.replaceAll(RegExp(r'<queries\b.*?</queries>', dotAll: true), '');

/// Null when the file is missing. Callers treat null as failure because
/// `isNot(contains(...))` passes against a null actual.
String? _readExtractionRules() {
  final file = File('android/app/src/main/res/xml/data_extraction_rules.xml');
  return file.existsSync() ? _withoutComments(file.readAsStringSync()) : null;
}

/// android:name values of `<uses-permission>` elements. With [removals]
/// true, returns the `tools:node="remove"` elements instead. A removal
/// subtracts a dependency-merged permission.
Iterable<String> _usesPermissionNames(
  String manifest, {
  required bool removal,
}) => RegExp(r'<uses-permission\b([^>]*)>', dotAll: true)
    .allMatches(manifest)
    .map((m) => m.group(1)!)
    .where(
      (attrs) =>
          RegExp(r'tools:node\s*=\s*"remove"').hasMatch(attrs) == removal,
    )
    .map(
      (attrs) =>
          RegExp(r'android:name="([^"]+)"').firstMatch(attrs)?.group(1) ??
          '(uses-permission without android:name)',
    );

/// Permissions the manifest requests.
Iterable<String> _requestedPermissions(String manifest) =>
    _usesPermissionNames(manifest, removal: false);

/// Permissions the manifest subtracts from the merge.
Iterable<String> _removedPermissions(String manifest) =>
    _usesPermissionNames(manifest, removal: true);

/// The inner XML of the first `<tag …>…</tag>` element, or null if absent.
String? _elementBody(String xml, String tag) => RegExp(
  '<$tag\\b[^>]*>(.*?)</$tag>',
  dotAll: true,
).firstMatch(xml)?.group(1);

/// Only path-less excludes count: `<exclude domain=".." path=".."/>` leaves
/// the rest of that domain extractable.
Set<String> _domainsFullyExcluded(String section) =>
    RegExp(r'<exclude\b([^>]*)>')
        .allMatches(section)
        .map((m) => m.group(1)!)
        .where((attrs) => !RegExp(r'\bpath\s*=').hasMatch(attrs))
        .map(
          (attrs) =>
              RegExp(r'\bdomain\s*=\s*"([^"]+)"').firstMatch(attrs)?.group(1),
        )
        .whereType<String>()
        .toSet();

/// All nine domains the format can name. The format has no wildcard.
const Set<String> _everyStorageDomain = {
  'root',
  'file',
  'database',
  'sharedpref',
  'external',
  'device_root',
  'device_file',
  'device_database',
  'device_sharedpref',
};

/// All three channels. An absent section is not "off". It falls back to
/// the platform default, which extracts app data.
const List<String> _everyChannel = [
  'cloud-backup',
  'device-transfer',
  'cross-platform-transfer',
];

void main() {
  late String manifest;

  setUp(() {
    manifest = _readManifest();
  });

  group('Android manifest', () {
    // Anti-vacuity guard: every negative below reads this same parse. A bad
    // path or regex fails here instead of passing vacuously there.
    test('parses and still declares a launchable entry point', () {
      expect(manifest, contains('<manifest'));
      expect(
        _requestedPermissions(manifest),
        contains('android.permission.INTERNET'),
        reason:
            'a VPN app that stops requesting INTERNET was misparsed, '
            'not hardened',
      );
      expect(
        RegExp(r'<intent-filter\b.*?</intent-filter>', dotAll: true)
            .allMatches(manifest)
            .where(
              (m) =>
                  m.group(0)!.contains('android.intent.action.MAIN') &&
                  m.group(0)!.contains('android.intent.category.LAUNCHER'),
            ),
        hasLength(1),
        reason: 'the app must keep exactly one home-screen entry point',
      );
    });

    // No deep links ship. A browsable onexray://onexray.com filter would be
    // an entry point with no handler in the product.
    test('claims no deep-link surface', () {
      expect(manifest, isNot(contains('android.intent.category.BROWSABLE')));
      expect(
        _withoutQueries(manifest),
        isNot(contains('android:scheme=')),
        reason: 'no element may claim a URI scheme, whatever its value',
      );
      expect(
        manifest,
        isNot(matches(RegExp('onexray', caseSensitive: false))),
        reason:
            'covers the onexray scheme and the onexray.com host in any casing',
      );
    });

    // The product offers no per-app routing, so it requests neither
    // inventory permission.
    test('requests no app-inventory permission', () {
      final permissions = _requestedPermissions(manifest).toList();
      expect(permissions, isNotEmpty);
      expect(
        permissions,
        isNot(contains('android.permission.QUERY_ALL_PACKAGES')),
      );
      expect(
        permissions,
        isNot(contains('com.android.permission.GET_INSTALLED_APPS')),
      );
      // Neither name appears anywhere in the manifest.
      expect(manifest, isNot(contains('QUERY_ALL_PACKAGES')));
      expect(manifest, isNot(contains('GET_INSTALLED_APPS')));
    });

    // Pins the complete permission surface. A permission enters either set
    // only when a shipped consumer justifies it. The pin is source-level.
    // The APK audit catches dependency-merged permissions.
    test('requests exactly the approved permissions', () {
      expect(
        _requestedPermissions(manifest).toSet(),
        equals(const {
          // The tunnel, and every network check.
          'android.permission.INTERNET',
          'android.permission.ACCESS_NETWORK_STATE',
          // The tunnel's network monitor requests the network the core
          // dials on, the best one with internet access that is not a VPN.
          'android.permission.CHANGE_NETWORK_STATE',
          // Android 16 gates LAN traffic behind this permission. The
          // setup flow requests it. Without the grant, local-network
          // bypass routing breaks on targetSdk 37 and later.
          'android.permission.ACCESS_LOCAL_NETWORK',
          // The connected notification needs it on API 33 and later. The
          // connect shell asks for it once, at the first connect tap.
          'android.permission.POST_NOTIFICATIONS',
          // The VPN foreground service (specialUse subtype "VPN service").
          'android.permission.FOREGROUND_SERVICE',
          'android.permission.FOREGROUND_SERVICE_SPECIAL_USE',
        }),
      );
    });

    // flutter_local_notifications merges VIBRATE. At this minSdk, the
    // system vibrates for notifications, not the app. No current dependency
    // merges CAMERA. The CAMERA entry blocks any future dependency from
    // adding it silently.
    test('removes exactly the ungrounded dependency-merged permissions', () {
      expect(
        _removedPermissions(manifest).toSet(),
        equals(const {
          'android.permission.CAMERA',
          'android.permission.VIBRATE',
        }),
      );
    });

    // The main activity follows the system rotation. It handles orientation
    // and size changes in place, so a rotation re-lays out without
    // recreating the activity.
    test('lets the main activity rotate in place', () {
      final activity = RegExp(
        r'<activity\b[^>]*android:name="\.MainActivity"[^>]*>',
        dotAll: true,
      ).firstMatch(manifest)?.group(0);
      expect(
        activity,
        isNotNull,
        reason: 'the launchable .MainActivity element was not found',
      );
      expect(activity, isNot(contains('android:screenOrientation')));
      final changes = RegExp(r'android:configChanges="([^"]*)"')
          .firstMatch(activity!)
          ?.group(1)
          ?.split('|');
      expect(changes, containsAll(const ['orientation', 'screenSize']));
    });

    test('opts out of cloud backup', () {
      expect(
        manifest,
        contains('android:allowBackup="false"'),
        reason:
            'allowBackup defaults to true when unset; node credentials '
            'must not reach a cloud backup',
      );
    });

    test('names extraction rules, and the resource exists', () {
      expect(
        manifest,
        contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
        reason:
            'on API 31+ allowBackup governs cloud backup only; '
            'device-to-device and cross-platform transfer obey '
            'dataExtractionRules',
      );
      expect(
        _readExtractionRules(),
        isNotNull,
        reason:
            'the manifest references @xml/data_extraction_rules, so '
            'android/app/src/main/res/xml/data_extraction_rules.xml must '
            'exist or the build breaks',
      );
    });
  });

  group('data-extraction rules', () {
    test('exclude every storage domain from every channel, in full', () {
      final rules = _readExtractionRules();
      expect(rules, isNotNull);
      for (final channel in _everyChannel) {
        final section = _elementBody(rules!, channel);
        expect(
          section,
          isNotNull,
          reason:
              'no <$channel> section: that channel keeps the platform '
              'default, which extracts app data',
        );
        expect(
          _domainsFullyExcluded(section!),
          equals(_everyStorageDomain),
          reason:
              'every storage domain must be excluded from <$channel> '
              'whole: an unnamed domain is an included one, and a '
              'path-scoped exclude covers only that path',
        );
      }
    });

    test('contain no include rule', () {
      // One <include> flips its section to an allowlist. isNotNull is
      // load-bearing: isNot(contains(...)) passes against a missing file.
      expect(
        _readExtractionRules(),
        allOf(isNotNull, isNot(contains('<include'))),
      );
    });
  });
}
