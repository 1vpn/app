// Pins the Xray editor cut against upstream merges. The product ships no
// configuration editing UI. Five surfaces stay absent from lib:
//
// - the Raw JSON editor and the connect page's expert mode
// - the per-server outbound editor
// - the raw import branch
// - the node import service
// - the runtime-configuration viewer and its credential-bearing export
//
// The sweep reads every file the two app entries reach. Restored upstream
// code joins it once an entry imports it.

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
  // below counts. The node import service stays absent.
  test('discovers the tree and finds no node import service', () {
    expect(sources.length, greaterThan(200));
    expect(
      File('lib/service/servers/import.dart').existsSync(),
      isFalse,
      reason: 'lib/service/servers/import.dart returned',
    );
  });

  test('the editor pages, their services, and their routes are gone', () {
    for (final path in const [
      'lib/pages/connect/raw_editor',
      'lib/pages/connect/json_editor',
      'lib/service/connect/raw',
      'lib/pages/servers',
      'lib/pages/advanced/xray/config',
    ]) {
      expect(Directory(path).existsSync(), isFalse, reason: '$path returned');
    }
    for (final entry in contents.entries) {
      for (final marker in const [
        'RawEditorPage',
        'RawEditorService',
        'ServerEditorPage',
        'ServerEditDraft',
        'ConfigFileViewerPage',
        'raw-editor',
        'server-editor',
        'config-file-viewer',
        'ServerAction.edit',
      ]) {
        expect(
          entry.value,
          isNot(contains(marker)),
          reason: '${entry.key} reintroduces an editor surface via $marker',
        );
      }
    }
  });

  test('the connect page carries no expert raw-selection mode', () {
    for (final entry in contents.entries) {
      for (final marker in const [
        'expertView',
        'toggleExpert',
        'onRawAdd',
        'onRawSelect',
        'showRawActions',
      ]) {
        expect(
          entry.value,
          isNot(contains(marker)),
          reason: '${entry.key} reintroduces the expert mode via $marker',
        );
      }
    }
  });

  test('the import path accepts no raw configurations', () {
    for (final entry in contents.entries) {
      for (final marker in const ['XrayRawValidator', 'XrayRawDb']) {
        expect(
          entry.value,
          isNot(contains(marker)),
          reason:
              '${entry.key} reintroduces the raw import branch via '
              '$marker',
        );
      }
    }
  });

  test('the runtime-configuration viewer and its export are gone', () {
    for (final entry in contents.entries) {
      for (final marker in const [
        'readConfiguration',
        'exportConfiguration',
        'OneXray-runtime.json',
      ]) {
        expect(
          entry.value,
          isNot(contains(marker)),
          reason:
              '${entry.key} reintroduces the runtime-configuration '
              'viewer via $marker',
        );
      }
    }
  });
}
