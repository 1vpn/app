// Pins the settings trim against upstream merges. The app ships one
// identity icon. The sweep reads every file the two app entries reach.
// Restored upstream code joins it once an entry imports it.
//
// The picker surface is the alternate-icon page, its settings row, and its
// route. The tests pin these facts:
//
// - lib/pages/settings/app_icon stays absent.
// - No reached file names the picker surface or the twelve strings only it
//   reads. The check skips lib/l10n/localizations. That directory declares
//   every upstream key.
// - No reached file outside lib/core/pigeon names setAppIcon or
//   getCurrentAppIcon.
// - The only preview PNG in assets/app_icon is blue.png.
// - assets/macos_icon stays absent. No reached file and no pubspec.yaml
//   entry names the dock previews.
// - pubspec.yaml carries no image dev dependency.
// - The fork Support page is reached. The upstream About page, settings
//   controller, and data cleanup service stay absent.
//
// The theme, language, and desktop settings pages stay out of scope. No app
// entry reaches them. The pigeon icon channels are frozen identifiers. They
// keep their bridge code.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/lib_closure.dart';

void main() {
  late List<File> sources;
  late Map<String, String> contents;

  setUpAll(() {
    sources = libClosureSources();
    contents = {for (final file in sources) file.path: file.readAsStringSync()};
  });

  // Anti-vacuity guard: the sweep reads a real tree before any negative
  // below counts. The fork Support page, which it must not flag, is present.
  test('discovers the tree and reads the fork Support page', () {
    expect(sources.length, greaterThan(200));
    expect(
      contents['lib/onevpn/shell/support_page.dart'],
      contains('OneVpnSupportPage'),
    );
    for (final path in const [
      'lib/pages/settings/about/page.dart',
      'lib/pages/settings/controller.dart',
      'lib/service/settings/data_cleanup.dart',
    ]) {
      expect(File(path).existsSync(), isFalse, reason: '$path returned');
    }
  });

  test('the icon picker page, its settings row, and its route are gone', () {
    expect(
      Directory('lib/pages/settings/app_icon').existsSync(),
      isFalse,
      reason: 'lib/pages/settings/app_icon returned',
    );
    for (final entry in contents.entries) {
      // The generated localizations declare every upstream key. Only a
      // read elsewhere brings the picker back.
      if (entry.key.startsWith('lib/l10n/localizations/')) continue;
      for (final marker in const [
        'AppIconPage',
        'AppIconChoiceView',
        'AppIconController',
        'appIconLabel',
        '"app-icon"',
        'prototypeAppIcon',
        'appIconPageSetFailed',
        'prototypeIconBlue',
        'prototypeIconBlack',
        'prototypeIconGreen',
        'prototypeIconOrange',
        'prototypeIconPurple',
        'prototypeIconRed',
        'prototypeHomeScreenIconHint',
        'prototypeDockIconHint',
        'prototypeHomeScreenPreview',
        'prototypeDockPreview',
      ]) {
        expect(
          entry.value,
          isNot(contains(marker)),
          reason: '${entry.key} reintroduces the icon picker via $marker',
        );
      }
    }
  });

  test('nothing outside the pigeon bridge switches the app icon', () {
    // The bridge keeps the frozen icon channels. Its wrappers have no
    // callers. A caller outside lib/core/pigeon means a picker surface has
    // returned.
    for (final entry in contents.entries) {
      if (entry.key.startsWith('lib/core/pigeon/')) continue;
      for (final marker in const ['setAppIcon', 'getCurrentAppIcon']) {
        expect(
          entry.value,
          isNot(contains(marker)),
          reason: '${entry.key} reintroduces the icon switch via $marker',
        );
      }
    }
  });

  test('one identity icon ships', () {
    final previewAssets =
        Directory('assets/app_icon')
            .listSync()
            .whereType<File>()
            .map((file) => file.uri.pathSegments.last)
            .where((name) => name.endsWith('.png'))
            .toList()
          ..sort();
    expect(previewAssets, [
      'blue.png',
    ], reason: 'assets/app_icon carries alternate icon previews');
    expect(
      Directory('assets/macos_icon').existsSync(),
      isFalse,
      reason: 'assets/macos_icon returned',
    );
    for (final entry in contents.entries) {
      for (final marker in const ['macosIcon', 'dockAssetImage']) {
        expect(
          entry.value,
          isNot(contains(marker)),
          reason:
              '${entry.key} reintroduces the alternate icon assets '
              'via $marker',
        );
      }
    }
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(
      pubspec,
      isNot(contains('assets/macos_icon')),
      reason: 'pubspec.yaml declares the dock preview assets',
    );
    // The pubspec carries no image dev dependency. share_surface_sweep
    // keeps lib clean of image imports.
    expect(
      RegExp(r'^\s+image: ', multiLine: true).hasMatch(pubspec),
      isFalse,
      reason: 'pubspec.yaml reintroduces the image dev dependency',
    );
  });
}
