// Pins the bundled geodata timestamp.
//
// tool/geodata_timestamp.sh prints the Unix seconds of the older pinned v2fly
// release. The release workflow writes that value to assets/dat/timestamp.txt
// after the digest check and before the bundle build. The app reads the file
// as a positive integer of at most 64 bytes. tool/build.sh rewrites the same
// value on every run.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _script = 'tool/geodata_timestamp.sh';

ProcessResult _run(List<String> args) =>
    Process.runSync('bash', [_script, ...args]);

int _seconds(DateTime utc) => utc.millisecondsSinceEpoch ~/ 1000;

/// The value of [key] in tool/pins.env.
String _pin(String key) => RegExp(
  '^$key=(.+)\$',
  multiLine: true,
).firstMatch(File('tool/pins.env').readAsStringSync())!.group(1)!.trim();

void main() {
  test('a fixed pair prints the older release time in UTC seconds', () {
    final result = _run(['202608050239', '20260819144818']);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    expect(
      (result.stdout as String).trim(),
      '${_seconds(DateTime.utc(2026, 8, 5, 2, 39))}',
    );
  });

  test('the older release wins in either position', () {
    final result = _run(['202603011200', '20240229235959']);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    expect(
      (result.stdout as String).trim(),
      '${_seconds(DateTime.utc(2024, 2, 29, 23, 59, 59))}',
    );
  });

  test('a malformed tag fails with exit 2 and prints nothing', () {
    for (final args in const [
      ['20260805023', '20260819144818'],
      ['202608050239', '202608191448'],
      ['202613050239', '20260819144818'],
      ['202608050260', '20260819144818'],
      ['199912312359', '20260819144818'],
      ['2026080502a9', '20260819144818'],
      ['202602300000', '20260819144818'],
      ['202604310000', '20260819144818'],
      ['202302290000', '20260819144818'],
      ['202608050239', '20230229000000'],
      ['202608050239'],
    ]) {
      final result = _run(args);
      expect(result.exitCode, 2, reason: '$args');
      expect(result.stdout, isEmpty, reason: '$args');
    }
  });

  test('without arguments the pins in tool/pins.env set the value', () {
    final pinned = _run(const []);
    final explicit = _run([_pin('GEOIP_RELEASE'), _pin('GEOSITE_RELEASE')]);
    expect(pinned.exitCode, 0, reason: '${pinned.stderr}');
    expect(pinned.stdout, explicit.stdout);
    final text = (pinned.stdout as String).trim();
    expect(text.length, lessThanOrEqualTo(64));
    expect(int.parse(text), greaterThan(0));
  });

  test('the release staging writes timestamp.txt before the build', () {
    final workflow = File('.github/workflows/release.yml').readAsStringSync();
    const write = '$_script > assets/dat/timestamp.txt';
    final fetch = workflow.indexOf('- name: Fetch the geodata');
    final check = workflow.indexOf('sha256sum --check --strict', fetch);
    final stage = workflow.indexOf(write);
    final build = workflow.indexOf('- name: Build the release bundle');
    expect(fetch, isNonNegative);
    expect(check, greaterThan(fetch));
    expect(stage, greaterThan(check));
    expect(build, greaterThan(stage));
    expect(workflow.indexOf('- name:', fetch + 1), build);
  });

  test('the build script rewrites timestamp.txt with the helper', () {
    final build = File('tool/build.sh').readAsStringSync();
    expect(build, contains('$_script > assets/dat/timestamp.txt.tmp\n'));
    expect(
      build,
      contains('mv assets/dat/timestamp.txt.tmp assets/dat/timestamp.txt\n'),
    );
    expect(build, isNot(contains('[ -e assets/dat/timestamp.txt ]')));
  });

  test('a leap day passes only in a leap year', () {
    final result = _run(['202402290000', '20260819144818']);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    expect(
      (result.stdout as String).trim(),
      '${_seconds(DateTime.utc(2024, 2, 29))}',
    );
  });

  test('a missing pin fails with exit 2 and one line', () {
    final dir = Directory.systemTemp.createTempSync('geodata_ts_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final tool = Directory('${dir.path}/tool')..createSync();
    File(_script).copySync('${tool.path}/geodata_timestamp.sh');
    File('${tool.path}/pins.env')
        .writeAsStringSync('GEOIP_RELEASE=202608050239\n');
    final result = Process.runSync('bash', [
      '${tool.path}/geodata_timestamp.sh',
    ]);
    expect(result.exitCode, 2);
    expect(result.stdout, isEmpty);
    expect((result.stderr as String).trim().split('\n'), hasLength(1));
  });
}
