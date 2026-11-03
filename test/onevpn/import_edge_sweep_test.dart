// Pins the import-edge cut against upstream merges. Three surfaces stay
// absent from lib: the onexray:// link scheme, the subscription fetch path,
// and the scanner and link-listener packages. The sweep reads every file
// the two app entries reach. Restored upstream code joins it once an entry
// imports it.
//
// The Android manifest keeps its tools:node remove entries for CAMERA and
// VIBRATE. No dependency merges CAMERA. android_manifest_test.dart pins
// both entries.

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

  // Anti-vacuity guard: the sweep reads a real tree, including files the
  // cut left in place, before any negative below counts.
  test('discovers the tree and reads real content', () {
    expect(sources.length, greaterThan(200));
    expect(
      File('lib/service/servers/import.dart').existsSync(),
      isFalse,
      reason: 'lib/service/servers/import.dart returned',
    );
    // The upstream subscription table stays. Its dao proves the sweep sees
    // file bodies, not just names.
    expect(contents, contains('lib/core/db/dao/subscription.dart'));
    expect(
      contents['lib/core/db/dao/subscription.dart'],
      contains('Subscription'),
    );
  });

  test('the onexray link scheme and host appear nowhere in lib', () {
    for (final entry in contents.entries) {
      expect(
        entry.value,
        isNot(contains('onexray://')),
        reason: '${entry.key} carries the upstream app-link scheme',
      );
      expect(
        entry.value.toLowerCase(),
        isNot(contains('onexray.com')),
        reason: '${entry.key} carries the upstream app-link host',
      );
    }
  });

  test('no subscription fetch path exists in lib', () {
    expect(
      Directory('lib/service/servers/subscription').existsSync(),
      isFalse,
      reason: 'the subscription service tree returned',
    );
    for (final entry in contents.entries) {
      for (final marker in const [
        'SubscriptionService',
        'refreshSubscription',
        'insertSubscription',
        'X-Age-Public-Key',
      ]) {
        expect(
          entry.value,
          isNot(contains(marker)),
          reason:
              '${entry.key} reintroduces the subscription fetch path '
              'via $marker',
        );
      }
    }
  });

  test('no lib source imports a scanner or link-listener package', () {
    for (final entry in contents.entries) {
      for (final package in const [
        'package:mobile_scanner/',
        'package:app_links/',
        'package:image_picker/',
      ]) {
        expect(
          entry.value,
          isNot(contains(package)),
          reason:
              '${entry.key} imports $package and the import edge '
              'carries no scanner or link listener',
        );
      }
    }
  });
}
