// Pins the custom-routing cut against upstream merges. The product's only
// routing surface is the fork Direct-regions picker. The OneXray
// smart-routing editor page and final-exit picker are cut with the servers
// complex. The smart-routing editor service stays as a frozen
// below-waterline keeper that no UI reaches. Five surfaces stay absent from
// lib:
//
// - the smart-routing editor pages
// - the custom rule editor pages and their routes
// - the custom rule editor service
// - the routing configuration import branch and its preview dialog
// - the configuration transfer service and widget
//
// The sweep reads every file the two app entries reach. Restored upstream
// code joins it once an entry imports it.
//
// The headless custom plumbing is a separate, kept surface. The compiler,
// resolver, and preparation keep their upstream-shaped custom paths. They
// read stored profiles through CustomRoutingService. A stored custom mode
// from an earlier install still compiles until a method change clears it.
// No UI can create or select one.
//
// The traffic method dialog keeps its upstream custom route list. No file
// the two app entries reach mounts it.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/lib_closure.dart';

/// The upstream traffic method dialog. The last test holds it at zero
/// callers, so its custom route list is exempt from the markers.
const _methodDialog = 'lib/pages/connect/dialogs.dart';

void main() {
  late List<File> sources;
  late Map<String, String> contents;

  setUpAll(() {
    sources = libClosureSources();
    contents = {for (final file in sources) file.path: file.readAsStringSync()};
  });

  // Anti-vacuity guard: the sweep reads a real tree before any negative
  // below counts. The kept below-waterline routing surfaces are present, and
  // the sweep must not flag them.
  test('discovers the tree and reads the kept routing surfaces', () {
    expect(sources.length, greaterThan(200));
    expect(
      contents['lib/service/connect/routing/custom/geodata_suggestions.dart'],
      contains('RoutingGeodataIndex'),
    );
    expect(
      contents['lib/service/connect/routing/custom/service.dart'],
      contains('CustomRoutingService'),
    );
    expect(
      File('lib/service/servers/import.dart').existsSync(),
      isFalse,
      reason: 'lib/service/servers/import.dart returned',
    );
  });

  test('the smart-routing editor page and exit picker are gone from lib', () {
    expect(
      Directory('lib/pages/connect/routing').existsSync(),
      isFalse,
      reason: 'lib/pages/connect/routing returned',
    );
    for (final entry in contents.entries) {
      for (final marker in const [
        'SmartRoutingEditorPage',
        'ServerExitPickerController',
        'ServerExitPickerPage',
      ]) {
        expect(
          entry.value,
          isNot(contains(marker)),
          reason: '${entry.key} reintroduces a cut routing page via $marker',
        );
      }
    }
  });

  test('the custom routing editor pages and their routes are gone', () {
    expect(
      Directory('lib/pages/connect/routing/custom').existsSync(),
      isFalse,
      reason: 'lib/pages/connect/routing/custom returned',
    );
    for (final entry in contents.entries) {
      for (final marker in const [
        'CustomRoutingEditor',
        'CustomRoutingRule',
        'custom-routing',
        'custom-rule',
      ]) {
        expect(
          entry.value,
          isNot(contains(marker)),
          reason:
              '${entry.key} reintroduces the custom routing editor via '
              '$marker',
        );
      }
    }
  });

  test('the import path accepts no routing configurations', () {
    for (final entry in contents.entries) {
      for (final marker in const [
        'ConfigurationKind',
        'ConfigurationContent',
        'ServerImportPreviewPage',
        'customRoutes',
      ]) {
        if (entry.key == _methodDialog && marker == 'customRoutes') continue;
        expect(
          entry.value,
          isNot(contains(marker)),
          reason:
              '${entry.key} reintroduces the routing configuration '
              'import branch via $marker',
        );
      }
    }
  });

  test('the configuration transfer service and widget are gone', () {
    for (final path in const [
      'lib/service/shared/share/configuration_transfer.dart',
      'lib/pages/shared/widgets/configuration_transfer.dart',
    ]) {
      expect(File(path).existsSync(), isFalse, reason: '$path returned');
    }
    for (final entry in contents.entries) {
      for (final marker in const [
        'ConfigurationTransfer',
        'ConfigurationImportDraft',
        'saveEditedAsset',
      ]) {
        expect(
          entry.value,
          isNot(contains(marker)),
          reason:
              '${entry.key} reintroduces the configuration transfer '
              'surface via $marker',
        );
      }
    }
  });

  test('no surviving file carries the custom method choice or grouping '
      'toggle', () {
    for (final entry in contents.entries) {
      for (final marker in const [
        'ConnectCustomChoice',
        'ServerGrouping',
        'groupBy',
      ]) {
        if (entry.key == _methodDialog && marker == 'ConnectCustomChoice') {
          continue;
        }
        expect(
          entry.value,
          isNot(contains(marker)),
          reason:
              '${entry.key} reintroduces a cut custom affordance via '
              '$marker',
        );
      }
    }
  });

  test('nothing mounts the traffic method dialog', () {
    // Anti-vacuity guard: the dialog is present, so the negative below
    // counts the callers of a live declaration.
    expect(
      contents[_methodDialog],
      contains('class ConnectTrafficMethodDialog'),
    );
    for (final entry in contents.entries) {
      if (entry.key == _methodDialog) continue;
      for (final marker in const [
        'ConnectTrafficMethodDialog',
        'ConnectTrafficChoice',
        'ConnectCustomChoice',
      ]) {
        expect(
          entry.value,
          isNot(contains(marker)),
          reason: '${entry.key} mounts the traffic method dialog via $marker',
        );
      }
    }
  });
}
