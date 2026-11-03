// Pins the closure the marker sweeps read. The walk starts at both app
// entries. It reaches every fork source under lib/onevpn.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/lib_closure.dart';

void main() {
  final paths = libClosureSources().map((file) => file.path).toSet();

  // Anti-vacuity guard: the walk follows imports and parts into
  // generated sources.
  test('the walk reaches both entries, a part, and generated sources', () {
    expect(
      paths,
      containsAll(const [
        ...libClosureEntries,
        'lib/core/db/database/database.g.dart',
        'lib/l10n/localizations/app_localizations.dart',
      ]),
    );
  });

  test('the walk reaches every fork source under lib/onevpn', () {
    final fork = [
      for (final entity in Directory('lib/onevpn').listSync(recursive: true))
        if (entity is File && entity.path.endsWith('.dart'))
          entity.path.replaceAll(r'\', '/'),
    ];
    expect(fork, isNotEmpty);
    expect(fork.where((path) => !paths.contains(path)), isEmpty);
  });
}
