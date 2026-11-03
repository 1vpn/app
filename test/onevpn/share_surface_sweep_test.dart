// Pins the outbound share cut so an upstream merge cannot regress it
// unnoticed. The product ships no share features: sharing a config
// shares node credentials. Three surfaces stay absent from lib: the
// share page and its route, the share entry points, and the share-sheet
// and QR-generation packages. The sweep reads every file the two app
// entries reach. Restored upstream code joins it once an entry imports it.

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
  // below counts. The bridge keeps the inbound converter, which the sweep
  // must not flag.
  test('discovers the tree and reads the inbound converter', () {
    expect(sources.length, greaterThan(200));
    expect(
      contents['lib/core/pigeon/host_api.dart'],
      contains('convertShareLinksToXrayJson'),
    );
  });

  test('the share page, its route, and its entry points are gone from lib', () {
    expect(
      Directory('lib/pages/shared/share').existsSync(),
      isFalse,
      reason: 'the share page tree returned',
    );
    for (final entry in contents.entries) {
      for (final marker in const [
        'SharePage',
        'AppSecondaryDestination.share',
        'share("share")',
        'ServerAction.share',
        'shareAsset',
      ]) {
        expect(
          entry.value,
          isNot(contains(marker)),
          reason: '${entry.key} reintroduces the share surface via $marker',
        );
      }
    }
  });

  test('no lib source imports a share-sheet or QR-generation package', () {
    for (final entry in contents.entries) {
      // None of these packages is a dependency. An import from lib would
      // restore one to the shipped app.
      for (final package in const [
        'package:share_plus/',
        'package:zxing2/',
        'package:image/',
      ]) {
        expect(
          entry.value,
          isNot(contains(package)),
          reason:
              '${entry.key} imports $package and the app generates '
              'no share text or QR output',
        );
      }
    }
  });

  test('the outbound converter stays frozen invoke surface with no caller', () {
    // LibXray invoke methods are frozen native contract. The method and
    // its models stay in the pigeon layer while nothing calls them.
    expect(
      contents['lib/core/pigeon/host_api.dart'],
      contains('convertXrayJsonToShareLinks'),
    );
    for (final entry in contents.entries) {
      if (entry.key.startsWith('lib/core/pigeon/')) continue;
      expect(
        entry.value,
        isNot(contains('convertXrayJsonToShareLinks')),
        reason: '${entry.key} calls the outbound share-link converter',
      );
    }
  });
}
