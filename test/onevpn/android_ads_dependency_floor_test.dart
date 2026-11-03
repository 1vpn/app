// Pins the ads SDK's WorkManager floor in the fork's ads overlay.
//
// The overlay raises androidx.work:work-runtime to 2.11.2 with a dependency
// constraint that states its reason. A constraint is a floor, so a higher
// version that the ads SDK declares wins. The overlay declares no direct
// WorkManager or Room dependency. Room follows the floor that WorkManager
// declares.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _overlay = 'tool/admob.gradle';

/// The constraint block, as it reads in the normalized script.
final _constraint = RegExp(
  r"dependencies \{ constraints \{ "
  r"implementation\('androidx\.work:work-runtime:2\.11\.2'\) "
  r"\{ because '[^']+' \} \} \}",
);

/// The script in [path] with comment lines dropped and whitespace runs
/// collapsed to single spaces. Fails the test when the file is missing.
String _normalizedScript(String path) {
  final file = File(path);
  expect(file.existsSync(), isTrue, reason: '$path is missing');
  return file
      .readAsLinesSync()
      .where((line) => !RegExp(r'^\s*//').hasMatch(line))
      .join('\n')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

void main() {
  test('the ads overlay raises work-runtime to 2.11.2 with a reason', () {
    expect(_constraint.allMatches(_normalizedScript(_overlay)), hasLength(1));
  });

  test('the ads overlay declares no direct WorkManager or Room dependency', () {
    final rest = _normalizedScript(_overlay).replaceAll(_constraint, '');
    expect(rest, isNot(contains(RegExp(r'androidx\.(work|room)'))));
  });
}
