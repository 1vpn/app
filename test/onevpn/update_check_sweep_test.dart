// Pins the update-check strip: the app performs no GitHub release check
// and carries none of the update-check machinery. Store distribution owns
// updates. The sweep fails when the endpoint, the service, or its UI
// returns through an upstream merge. It reads every file the two app
// entries reach.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/lib_closure.dart';

/// Source strings only the removed update-check surface contains.
/// `api.github.com` is the endpoint itself. The identifiers are the removed
/// service, its model, and the dialog push. Any reference revives the
/// surface. Preference keys and ARB strings stay as dead data and match
/// none of these.
const _banned = [
  'api.github.com',
  'AppUpdateService',
  'AppUpdateInfo',
  'pushAppUpdateDialog',
  'checkForUpdate',
];

void main() {
  final sources = libClosureSources();

  test('the sweep sees the tree it guards', () {
    // A floor and known files guard against a silently empty walk. The
    // positive matches prove that reads return file content.
    expect(sources.length, greaterThan(100));
    final paths = sources.map((file) => file.path).toSet();
    expect(paths, contains('lib/service/manager.dart'));
    expect(paths, contains('lib/onevpn/shell/shell.dart'));
    // Positive control: a string known to be present in manager.dart. It
    // proves that the read returns file content.
    expect(
      File('lib/service/manager.dart').readAsStringSync(),
      contains('BackgroundTaskService().init('),
    );
  });

  test('services start fires no update check', () {
    // The kept geodata scheduler keeps `data_update` in the manager's
    // imports. The banned tokens name only the removed app-update path.
    final source = File('lib/service/manager.dart').readAsStringSync();
    expect(source, contains('BackgroundTaskService().init('));
    for (final banned in ['checkUpdate', ..._banned]) {
      expect(source, isNot(contains(banned)), reason: 'manager: $banned');
    }
  });

  test('no update-check endpoint or machinery reference in lib', () {
    final violations = <String>[];
    for (final file in sources) {
      final source = file.readAsStringSync();
      for (final banned in _banned) {
        if (source.contains(banned)) {
          violations.add('${file.path}: $banned');
        }
      }
    }
    expect(violations, isEmpty);
  });
}
