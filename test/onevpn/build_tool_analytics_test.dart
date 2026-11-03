// Pins the tool analytics and version-check suppression in tool/build.sh.
//
// The build script never reports tool analytics. It never checks the SDK
// version upstream. The export reaches the children flutter starts. Every
// flutter call carries both flags. Every dart call carries the analytics flag.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _flutterFlags = '--suppress-analytics --no-version-check';
const _dartFlags = '--suppress-analytics';

/// [path] with comment lines and line continuations dropped, and whitespace
/// collapsed to one space.
String _normalizedShell(String path) => File(path)
    .readAsLinesSync()
    .where((line) => !RegExp(r'^\s*#').hasMatch(line))
    .map(
      (line) => line.endsWith(r'\') ? line.substring(0, line.length - 1) : line,
    )
    .join(' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// Each call of [tool] in [source], as the next 100 characters.
///
/// A call starts after a space, an open paren, or the source start. A quoted
/// step label never starts one. A path ending in ".dart" never starts one.
List<String> _calls(String source, String tool) =>
    RegExp('(?<=^|[ (])$tool ').allMatches(source).map((match) {
      final end = (match.start + 100).clamp(0, source.length);
      return source.substring(match.start, end);
    }).toList();

void main() {
  late String build;

  setUpAll(() => build = _normalizedShell('tool/build.sh'));

  test('the script exports the flutter analytics switch first', () {
    const export = 'export FLUTTER_SUPPRESS_ANALYTICS=true';
    expect(build, contains(export));
    expect(
      build.indexOf(export),
      lessThan(build.indexOf('flutter $_flutterFlags ')),
    );
  });

  test('every flutter call carries both flags', () {
    final calls = _calls(build, 'flutter');
    // Anti-vacuity: the scan finds calls at each position the script uses.
    for (final call in const [
      'flutter $_flutterFlags pub get --enforce-lockfile',
      'flutter $_flutterFlags --version |',
      'flutter $_flutterFlags analyze --no-pub',
      'flutter $_flutterFlags test "\${TEST_FLAGS[@]}"',
    ]) {
      expect(calls, anyElement(startsWith(call)));
    }
    for (final call in calls) {
      expect(call, startsWith('flutter $_flutterFlags '));
    }
  });

  test('every dart call carries the analytics flag', () {
    final calls = _calls(build, 'dart');
    expect(calls, anyElement(startsWith('dart $_dartFlags format ')));
    expect(calls, anyElement(startsWith('dart $_dartFlags run ffigen')));
    // The pigeon generator is a child of the gate.
    expect(build, contains('tool/gen_onevpn_pigeon.sh'));
    final pigeon = _calls(
      _normalizedShell('tool/gen_onevpn_pigeon.sh'),
      'dart',
    );
    expect(pigeon, hasLength(1));
    for (final call in [...calls, ...pigeon]) {
      expect(call, startsWith('dart $_dartFlags '));
    }
  });
}
