// Asserts the iOS Info.plist as a file. The test gate runs no Apple
// build, so source is the only surface these checks can reach. Xcode
// copies Info.plist into the bundle, variable substitution aside, so the
// literal keys asserted here survive into the shipped artifact.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Strips comments, so commented-out XML can neither satisfy nor violate an
/// assertion.
String _withoutComments(String xml) =>
    xml.replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');

/// Null when the file is missing. Callers treat null as failure because
/// `isNot(contains(...))` passes against a null actual.
String? _readPlist(String path) {
  final file = File(path);
  return file.existsSync() ? _withoutComments(file.readAsStringSync()) : null;
}

/// Every shipping Apple app-target plist. A new target adds its plist here.
const Map<String, String> _plists = {'iOS': 'ios/Runner/Info.plist'};

void main() {
  for (final MapEntry(key: platform, value: path) in _plists.entries) {
    group('$platform Info.plist', () {
      String? plist;

      setUp(() {
        plist = _readPlist(path);
      });

      // Anti-vacuity guard: every negative below reads this same load. A bad
      // path fails here instead of passing vacuously there.
      test('loads and still declares its bundle identity', () {
        expect(plist, isNotNull, reason: '$path is missing');
        expect(plist, contains('<plist'));
        expect(
          plist,
          contains('<key>CFBundleIdentifier</key>'),
          reason:
              'a plist without a bundle identifier was misread, not hardened',
        );
      });

      // No shipped feature uses the camera or the photo library, so no
      // usage-description key may be declared. Plists do not merge. The pin
      // covers the whole surface.
      test('declares no usage-description key', () {
        expect(plist, isNotNull, reason: '$path is missing');
        final keys = RegExp(r'<key>([^<>]*UsageDescription)</key>')
            .allMatches(plist!)
            .map((m) => m.group(1)!)
            .toList();
        expect(keys, isEmpty, reason: 'found: ${keys.join(', ')}');
      });

      // No deep links ship. An onexray:// URL type would be an entry point
      // with no handler in the product.
      test('registers no URL type', () {
        expect(plist, allOf(isNotNull, isNot(contains('CFBundleURLTypes'))));
        // Case-sensitive: the scheme and the reverse-DNS URL name are
        // lowercase. The OneXray display name is a separate identity surface.
        expect(plist, allOf(isNotNull, isNot(contains('onexray'))));
      });
    });
  }

  // iPhone supports portrait and both landscapes. iPad supports all four
  // orientations, which keeps multitasking without UIRequiresFullScreen.
  group('iOS orientations', () {
    /// The strings in the array under [key], or null when the key is absent.
    List<String>? orientations(String plist, String key) {
      final array = RegExp(
        '<key>${RegExp.escape(key)}</key>'
        r'\s*<array>(.*?)</array>',
        dotAll: true,
      ).firstMatch(plist)?.group(1);
      if (array == null) return null;
      return RegExp(r'<string>([^<]*)</string>')
          .allMatches(array)
          .map((match) => match.group(1)!)
          .toList();
    }

    test('iPhone rotates to portrait and both landscapes, iPad to all '
        'four', () {
      final plist = _readPlist('ios/Runner/Info.plist');
      expect(plist, isNotNull, reason: 'ios/Runner/Info.plist is missing');
      expect(
        orientations(plist!, 'UISupportedInterfaceOrientations'),
        unorderedEquals(const [
          'UIInterfaceOrientationPortrait',
          'UIInterfaceOrientationLandscapeLeft',
          'UIInterfaceOrientationLandscapeRight',
        ]),
      );
      expect(
        orientations(plist, 'UISupportedInterfaceOrientations~ipad'),
        unorderedEquals(const [
          'UIInterfaceOrientationPortrait',
          'UIInterfaceOrientationPortraitUpsideDown',
          'UIInterfaceOrientationLandscapeLeft',
          'UIInterfaceOrientationLandscapeRight',
        ]),
      );
      expect(plist, isNot(contains('UIRequiresFullScreen')));
    });
  });
}
