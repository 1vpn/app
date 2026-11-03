// Pins the radius that decides when the android check compiles, and the
// staged native core pin that local builds share with the check.
//
// The changes job in .github/workflows/ci.yml runs the compile when a diff
// touches a path in the Android radius. Beside android/, the radius holds
// every file outside it that the Gradle build reads. This test scans the
// Gradle scripts, and each script they apply, for quoted paths with a parent
// step. A path it resolves outside the radius fails it. A path it cannot
// resolve fails it too, as does an applied script it cannot read. A path
// that code builds without a quoted parent step is outside the scan.
//
// The job checks the release aar against LIBXRAY_AAR_SHA256 in tool/pins.env.
// tool/build.sh checks the staged aar against the same pin before --kotlin,
// --apk and --aab, and fails with exit 3 on a missing or different aar. With
// --unpinned-core it fails on a missing aar alone and prints the aar's hash
// beside the pin. No workflow passes the flag.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// The SHA-256 of an empty file, the staged aar in these trees.
const _emptySha256 =
    'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

/// A pin that no staged aar here matches.
const _otherSha256 =
    '1111111111111111111111111111111111111111111111111111111111111111';

/// The absolute path of [tool] on this machine, or null when it is missing.
String? _which(String tool) {
  final result = Process.runSync('bash', ['-c', 'command -v $tool']);
  return result.exitCode == 0 ? (result.stdout as String).trim() : null;
}

final _bash = _which('bash')!;
final _shasum = _which('shasum');

/// The radius pattern that the changes job passes to `grep -qE`.
String _radius() {
  final ci = File('.github/workflows/ci.yml').readAsStringSync();
  final line = RegExp(
    r"""if grep -qE '([^']+)' <<< "\$PATHS"; then ANDROID=true; fi""",
  ).firstMatch(ci);
  expect(line, isNotNull, reason: 'the radius line of the changes job');
  return line!.group(1)!;
}

/// The paths among [paths] that the radius misses, by the job's own grep.
List<String> _outsideRadius(Iterable<String> paths) {
  expect(paths, isNotEmpty);
  final result = Process.runSync('bash', [
    '-c',
    r'printf "%s\n" "${@:2}" | grep -vE -- "$1"',
    'radius',
    _radius(),
    ...paths,
  ]);
  // grep exits 1 when it prints no path, and 2 on an error.
  expect(result.exitCode, lessThan(2), reason: '${result.stderr}');
  return const LineSplitter().convert(result.stdout as String);
}

/// The Gradle scripts the build starts from, each with the directory its
/// relative paths resolve against.
const _entryScripts = [
  (path: 'android/settings.gradle.kts', project: 'android'),
  (path: 'android/build.gradle.kts', project: 'android'),
  (path: 'android/app/build.gradle.kts', project: 'android/app'),
];

/// Scans [_entryScripts] and every script they apply, recursively, for quoted
/// paths. [read] returns a script's text, or null when it is missing.
///
/// An apply through `file(...)` or `rootProject.file(...)` counts as a plain
/// apply, so the applied script is scanned in turn. An applied script and
/// `file(...)` resolve against the directory of their project, and
/// `rootProject.file(...)` against android/. The `source` of the flutter block
/// names the Flutter project, whose pubspec and lock the build reads. The
/// inputs are the resolved paths outside android/. The unknown list holds each
/// path with `$` and a parent step, each other path with a parent step in a
/// form the scan does not know, and each applied script it cannot read. The
/// build output `../../build` is the one path the scan skips.
({Set<String> inputs, List<String> unknown}) _scanGradle(
  String? Function(String path) read,
) {
  final inputs = <String>{};
  final unknown = <String>[];
  final queue = [..._entryScripts];
  final scanned = <String>{};
  while (queue.isNotEmpty) {
    final script = queue.removeAt(0);
    if (!scanned.add(script.path)) continue;
    final text = read(script.path);
    if (text == null) {
      unknown.add('${script.path}: cannot be read');
      continue;
    }
    final code = text
        .split('\n')
        .where((line) => !RegExp(r'^\s*(//|/\*|\*)').hasMatch(line))
        .join('\n');
    for (final quoted in RegExp(
      r'"([^"\n]*)"'
      r"|'([^'\n]*)'",
    ).allMatches(code)) {
      final value = quoted.group(1) ?? quoted.group(2)!;
      final before = code.substring(
        code.lastIndexOf('\n', quoted.start) + 1,
        quoted.start,
      );
      String resolve(String base) => p.normalize(p.join(base, value));
      final steps = RegExp(r'(^|/)\.\.(/|$)').hasMatch(value);
      // Gradle expands a path that holds $ at run time, so the scan cannot
      // resolve it.
      if (steps && value.contains(r'$')) {
        unknown.add('${script.path}: $value');
        continue;
      }
      final apply = RegExp(
        r'apply\s*\(?\s*from\s*[=:]\s*(?:((?:rootProject|project)\.)?file\(\s*)?$',
      ).firstMatch(before);
      if (apply != null) {
        final applied = resolve(
          apply.group(1) == 'rootProject.' ? 'android' : script.project,
        );
        inputs.add(applied);
        queue.add((path: applied, project: script.project));
        continue;
      }
      // The scan resolves only paths with a parent step or a leading slash.
      if (!steps && !p.isAbsolute(value)) continue;
      if (RegExp(r'rootProject\.file\(\s*$').hasMatch(before)) {
        inputs.add(resolve('android'));
      } else if (RegExp(r'(^|[^\w.])(project\.)?file\(\s*$').hasMatch(before)) {
        inputs.add(resolve(script.project));
      } else if (RegExp(r'(^|[^\w.])source\s*=\s*$').hasMatch(before)) {
        final project = resolve(script.project);
        inputs
          ..add(p.normalize(p.join(project, 'pubspec.yaml')))
          ..add(p.normalize(p.join(project, 'pubspec.lock')));
      } else if (value != '../../build' ||
          !RegExp(r'buildDirectory\.dir\(\s*$').hasMatch(before)) {
        unknown.add('${script.path}: $value');
      }
    }
  }
  return (
    inputs: {
      for (final path in inputs)
        if (path != 'android' && !p.isWithin('android', path)) path,
    },
    unknown: unknown,
  );
}

/// The text of [path] in the working tree, or null when it is missing.
String? _readTree(String path) {
  final file = File(path);
  return file.existsSync() ? file.readAsStringSync() : null;
}

/// The staged aar check of tool/build.sh, require_pinned_aar with its
/// comment.
String _pinCheck() {
  final build = File('tool/build.sh').readAsStringSync();
  const open = '# The staged aar must be the pinned build.';
  const close = '# The Kotlin compile needs the Gradle wrapper';
  final start = build.indexOf(open);
  final end = build.indexOf(close, start);
  expect(start, isNonNegative, reason: 'the start of the core checks');
  expect(end, greaterThan(start), reason: 'the end of the core checks');
  return build.substring(start, end);
}

/// The argument parse of tool/build.sh, from the mode to the entry point.
String _arguments() {
  final build = File('tool/build.sh').readAsStringSync();
  const open = r'MODE="${1:---test}"';
  const close = '# App builds compile this entry point.';
  final start = build.indexOf(open);
  final end = build.indexOf(close, start);
  expect(start, isNonNegative, reason: 'the start of the argument parse');
  expect(end, greaterThan(start), reason: 'the end of the argument parse');
  return build.substring(start, end);
}

/// Runs the argument parse of tool/build.sh on [args] and prints the mode
/// and both flags. [environment] adds variables to the inherited environment.
ProcessResult _parse(List<String> args, {Map<String, String>? environment}) =>
    Process.runSync(_bash, [
      '-c',
      'set -euo pipefail\n'
          '${_arguments()}'
          r'echo "$MODE signed=$SIGNED unpinned=$UNPINNED_CORE"',
      'parse',
      ...args,
    ], environment: environment);

/// Runs require_pinned_aar after the argument parse of tool/build.sh on
/// [args], in a tree whose tool/pins.env pins [pin], with an empty staged
/// aar, or none when [staged] is false. [path] replaces PATH.
ProcessResult _checkCore({
  required String pin,
  bool staged = true,
  String? path,
  List<String> args = const ['--kotlin'],
}) {
  final dir = Directory.systemTemp.createTempSync('android_check_');
  addTearDown(() => dir.deleteSync(recursive: true));
  File('${dir.path}/tool/pins.env')
    ..createSync(recursive: true)
    ..writeAsStringSync(
      'LIBXRAY_SHA=0123456789abcdef0123456789abcdef01234567\n'
      'LIBXRAY_AAR_SHA256=$pin\n',
    );
  if (staged) {
    File('${dir.path}/android/app/libs/libXray.aar')
        .createSync(recursive: true);
  }
  final script = File('${dir.path}/check.sh')
    ..writeAsStringSync(
      'set -euo pipefail\n'
      'step() { echo "==> \$1"; }\n'
      '${_arguments()}'
      '${_pinCheck()}'
      'require_pinned_aar\n'
      'echo checked\n',
    );
  return Process.runSync(
    _bash,
    [script.path, ...args],
    workingDirectory: dir.path,
    environment: {'PATH': ?path},
  );
}

void main() {
  group('radius', () {
    test(
      'every file outside android/ that the Gradle build reads is in it',
      () {
        final scan = _scanGradle(_readTree);
        expect(
          scan.unknown,
          isEmpty,
          reason: 'paths in a form the scan does not know',
        );
        final inputs = scan.inputs;
        expect(
          inputs,
          containsAll(const [
            'tool/release_signing.gradle',
            'tool/admob.gradle',
            'tool/admob/AndroidManifest.xml',
            'pubspec.yaml',
            'pubspec.lock',
          ]),
        );
        for (final path in inputs) {
          expect(File(path).existsSync(), isTrue, reason: path);
        }
        expect(_outsideRadius(inputs), isEmpty);
      },
    );

    test('the scan reads each path form and follows applied scripts', () {
      const scripts = {
        'android/settings.gradle.kts': 'include(":app")\n',
        'android/build.gradle.kts':
            'val out = rootProject.layout.buildDirectory.dir("../../build")\n',
        'android/app/build.gradle.kts':
            'flutter {\n    source = "../.."\n}\n'
            'apply(from = "../../tool/one.gradle")\n'
            'val extra = file("../../tool/flags/extra.properties")\n',
        'tool/one.gradle':
            "def overlay = rootProject.file('../tool/one/AndroidManifest.xml')\n"
            "apply from: '../../tool/release/two.gradle'\n",
        'tool/release/two.gradle': "copy { from '../../assets/x' }\n",
      };
      final scan = _scanGradle((path) => scripts[path]);
      expect(scan.inputs, {
        'pubspec.yaml',
        'pubspec.lock',
        'tool/one.gradle',
        'tool/flags/extra.properties',
        'tool/one/AndroidManifest.xml',
        'tool/release/two.gradle',
      });
      expect(scan.unknown, ['tool/release/two.gradle: ../../assets/x']);
      // The job's grep misses three of them.
      expect(
        _outsideRadius(scan.inputs),
        unorderedEquals(const [
          'tool/flags/extra.properties',
          'tool/one/AndroidManifest.xml',
          'tool/release/two.gradle',
        ]),
      );
    });

    test('the scan lists each path it cannot resolve as unknown', () {
      const scripts = {
        'android/settings.gradle.kts': '',
        'android/build.gradle.kts': '',
        'android/app/build.gradle.kts':
            'file("\$rootDir/../tool/flags/extra.properties")\n'
            'apply(from = "\$rootDir/../tool/release/extra4.gradle")\n'
            'apply(from = rootProject.file("../tool/extra3.gradle"))\n'
            'apply(from = "../../tool/missing.gradle")\n',
        'tool/extra3.gradle':
            "def extra = file('../../tool/flags/extra.properties')\n",
      };
      final scan = _scanGradle((path) => scripts[path]);
      expect(scan.unknown, [
        'android/app/build.gradle.kts: \$rootDir/../tool/flags/extra.properties',
        'android/app/build.gradle.kts: \$rootDir/../tool/release/extra4.gradle',
        'tool/missing.gradle: cannot be read',
      ]);
      // The script applied through rootProject.file is scanned in turn.
      expect(scan.inputs, {
        'tool/extra3.gradle',
        'tool/missing.gradle',
        'tool/flags/extra.properties',
      });
      expect(_outsideRadius(scan.inputs), ['tool/flags/extra.properties']);
    });

    test('the pins, the job script and the workflows are in it', () {
      // tool/pins.env pins the Flutter SDK, whose Gradle plugin the build
      // includes, and the aar the job compiles against.
      expect(
        _outsideRadius(const [
          'android/app/build.gradle.kts',
          'tool/pins.env',
          'tool/build.sh',
          '.github/workflows/ci.yml',
        ]),
        isEmpty,
      );
    });

    test('paths the compile never reads stay outside it', () {
      const paths = [
        'lib/main_1vpn.dart',
        'test/onevpn/android_check_test.dart',
        'tool/conventions.sh',
        'tool/release.env',
        'docs/onevpn/building.md',
      ];
      expect(_outsideRadius(paths), paths);
    });
  });

  group('staged core pin', () {
    test('an aar at the pin passes', () {
      final result = _checkCore(pin: _emptySha256);
      expect(result.exitCode, 0, reason: '${result.stderr}');
      expect(
        result.stdout,
        contains(
          'the staged libXray.aar matches the pin: sha256 e3b0c44298fc\n',
        ),
      );
      expect(result.stdout, endsWith('checked\n'));
    });

    test('an aar off the pin fails with exit 3 and names both hashes', () {
      final result = _checkCore(pin: _otherSha256);
      expect(result.exitCode, 3);
      expect(result.stdout, isNot(contains('checked')));
      expect(
        result.stderr,
        allOf(
          contains('does not match the pin: android/app/libs/libXray.aar\n'),
          contains('expected sha256 111111111111 '),
          contains('actual e3b0c44298fc\n'),
          contains('the release asset libxray-0123456\n'),
        ),
      );
    });

    test('a missing aar fails with exit 3 and names the release asset', () {
      final result = _checkCore(pin: _emptySha256, staged: false);
      expect(result.exitCode, 3);
      expect(
        result.stderr,
        'missing staged native library: android/app/libs/libXray.aar\n'
        'stage the aar built at LIBXRAY_SHA, the release asset libxray-0123456\n',
      );
    });

    test('without sha256sum the check hashes with shasum', () {
      // A PATH that holds shasum alone finds no sha256sum.
      final bin = Directory.systemTemp.createTempSync('android_check_bin_');
      addTearDown(() => bin.deleteSync(recursive: true));
      Link('${bin.path}/shasum').createSync(_shasum!);
      final pass = _checkCore(pin: _emptySha256, path: bin.path);
      expect(pass.exitCode, 0, reason: '${pass.stderr}');
      expect(pass.stdout, contains('matches the pin: sha256 e3b0c44298fc\n'));
      final fail = _checkCore(pin: _otherSha256, path: bin.path);
      expect(fail.exitCode, 3);
      expect(fail.stderr, contains('actual e3b0c44298fc\n'));
    }, skip: _shasum == null ? 'shasum is not installed' : false);

    test(
      '--kotlin, --apk and --aab check the staged aar before they build',
      () {
        final code = File('tool/build.sh')
            .readAsLinesSync()
            .where((line) => !RegExp(r'^\s*#').hasMatch(line))
            .join('\n');
        for (final (mode, build) in const [
          ('--kotlin', 'build apk --config-only'),
          ('--apk', r'build apk ${DART_DEFINES'),
          ('--aab', 'build appbundle'),
        ]) {
          final call = code.indexOf('--no-version-check $build');
          expect(call, isNonNegative, reason: mode);
          final open = code.lastIndexOf(
            'if [ "\$MODE" = "$mode" ]; then',
            call,
          );
          expect(open, isNonNegative, reason: mode);
          expect(
            code.substring(open, call),
            contains('\n  require_pinned_aar\n'),
            reason: mode,
          );
        }
        // Every staged aar check goes through the pin. --ios checks that the
        // xcframework is staged.
        expect(
          RegExp(r'^\s*require_pinned_aar$', multiLine: true).allMatches(code),
          hasLength(3),
        );
        expect(code, isNot(contains('require_prebuilt -f')));
        expect(
          code,
          contains('\n  require_prebuilt -d swift/All/LibXray.xcframework\n'),
        );
      },
    );
  });

  group('unpinned core', () {
    const unpinnedLine =
        'unpinned core: sha256 e3b0c44298fc (the release pin is 111111111111)\n';

    test('--kotlin and --apk with the flag pass an aar off the pin', () {
      for (final mode in const ['--kotlin', '--apk']) {
        final result = _checkCore(
          pin: _otherSha256,
          args: [mode, '--unpinned-core'],
        );
        expect(result.exitCode, 0, reason: '$mode ${result.stderr}');
        expect(result.stdout, contains(unpinnedLine), reason: mode);
        expect(result.stdout, isNot(contains('matches the pin')), reason: mode);
        expect(result.stdout, endsWith('checked\n'), reason: mode);
        expect(result.stderr, isEmpty, reason: mode);
      }
    });

    test('with the flag a missing aar still fails with exit 3', () {
      final result = _checkCore(
        pin: _emptySha256,
        staged: false,
        args: const ['--apk', '--unpinned-core'],
      );
      expect(result.exitCode, 3);
      expect(result.stdout, isNot(contains('unpinned core')));
      expect(
        result.stderr,
        'missing staged native library: android/app/libs/libXray.aar\n'
        'stage the aar built at LIBXRAY_SHA, the release asset libxray-0123456\n',
      );
    });

    test('a release bundle with the flag logs the unpinned line', () {
      for (final args in const [
        ['--aab', '--unpinned-core'],
        ['--aab', '--signed', '--unpinned-core'],
        ['--aab', '--unpinned-core', '--signed'],
      ]) {
        final result = _checkCore(pin: _otherSha256, args: args);
        expect(result.exitCode, 0, reason: '$args ${result.stderr}');
        expect(result.stdout, contains(unpinnedLine), reason: '$args');
      }
      // Without the flag the same aar fails on the pin.
      final pinned = _checkCore(pin: _otherSha256, args: const ['--aab']);
      expect(pinned.exitCode, 3);
      expect(pinned.stdout, isNot(contains('unpinned core')));
    });

    test('the flag follows any mode once and is off by default', () {
      for (final (args, parsed) in const [
        (['--aab'], '--aab signed=false unpinned=false'),
        (['--aab', '--signed'], '--aab signed=true unpinned=false'),
        (['--test', '--unpinned-core'], '--test signed=false unpinned=true'),
        (['--ios', '--unpinned-core'], '--ios signed=false unpinned=true'),
        (
          ['--aab', '--unpinned-core', '--signed'],
          '--aab signed=true unpinned=true',
        ),
      ]) {
        final result = _parse(args);
        expect(result.exitCode, 0, reason: '$args ${result.stderr}');
        expect(result.stdout, '$parsed\n', reason: '$args');
      }
      // UNPINNED_CORE in the environment leaves the flag off.
      final inherited = _parse(
        const ['--kotlin'],
        environment: const {'UNPINNED_CORE': 'true'},
      );
      expect(inherited.exitCode, 0, reason: '${inherited.stderr}');
      expect(inherited.stdout, '--kotlin signed=false unpinned=false\n');
      for (final args in const [
        ['--unpinned-core'],
        ['--unpinned-core', '--apk'],
        ['--apk', '--unpinned-core', '--unpinned-core'],
        ['--apk', '--signed', '--unpinned-core'],
        ['--aab', '--signed', '--signed'],
      ]) {
        final result = _parse(args);
        expect(result.exitCode, 2, reason: '$args');
        expect(result.stdout, isEmpty, reason: '$args');
      }
      // The parse sets the flag and the pin check is its one reader. The
      // modes that run no pin check ignore it.
      int count(String text) => 'UNPINNED_CORE'.allMatches(text).length;
      expect(
        count(File('tool/build.sh').readAsStringSync()),
        count(_arguments()) + count(_pinCheck()),
      );
    });

    test('no workflow passes the flag', () {
      final workflows = {
        for (final file in Directory(
          '.github/workflows',
        ).listSync(recursive: true).whereType<File>())
          file.path: file.readAsStringSync(),
      };
      // The scan reads the workflows that run the app builds.
      expect(
        workflows['.github/workflows/ci.yml'],
        contains('run: tool/build.sh --kotlin\n'),
      );
      expect(
        workflows['.github/workflows/release.yml'],
        contains('run: tool/build.sh --aab\n'),
      );
      for (final MapEntry(key: path, value: text) in workflows.entries) {
        expect(text, isNot(contains('--unpinned-core')), reason: path);
        expect(text, isNot(contains('UNPINNED_CORE')), reason: path);
      }
    });
  });
}
