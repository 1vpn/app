// The release bundle mode of tool/build.sh, its signing script, and the
// version every app build carries.
//
// Every app build takes its version from tool/release.env. `--aab` takes its
// defines from the environment. It refuses a bad store key, an empty
// connection or AdMob value, Google's sample AdMob ids and a malformed AdMob
// id before any tool starts. `--apk` and `--ios` keep the empty and sample
// fallbacks. A release signs with the upload config or stays unsigned. Only a
// release-type build that names `debug` signs with the debug config, and
// `--aab` refuses it. The bundle check counts signature entries from a whole
// listing, and a bundle that unzip cannot list stops the build. A push and a
// dispatch of one release candidate share one concurrency group.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _keystore = 'android/keystore/keystore.properties';

/// The release values `--aab` refuses when empty, each set to a placeholder.
/// The `test-` values pass the scrub.
const _required = <String, String>{
  'ONEVPN_UUID': 'test-uuid',
  'ONEVPN_PBK': 'test-pbk',
  'ONEVPN_SID': 'test-sid',
  'ONEVPN_FREE_NODE_IPS': 'test-ips',
  'ONEVPN_ADMOB_APP_ID_ANDROID': 'test-app-id',
  'ONEVPN_ADMOB_INTERSTITIAL_ANDROID': 'test-unit',
};

/// Google's published AdMob test ids, which carry the sample publisher id.
const _sampleIds = <String, String>{
  'ONEVPN_ADMOB_APP_ID_ANDROID': 'ca-app-pub-3940256099942544~3347511713',
  'ONEVPN_ADMOB_INTERSTITIAL_ANDROID': 'ca-app-pub-3940256099942544/1033173712',
};

/// Runs `tool/build.sh` with [args], the store key [key] and the extra
/// environment [env].
///
/// Each case here fails in the input checks, before any tool starts.
ProcessResult _build(
  List<String> args, {
  required String key,
  Map<String, String> env = const {},
}) => Process.runSync(
  'bash',
  ['tool/build.sh', ...args],
  environment: {'ONEVPN_RC_SDK_KEY': key, ...env},
);

/// [path] with `//` and `#` comment lines dropped.
String _code(String path) =>
    File(path)
        .readAsLinesSync()
        .where((line) => !RegExp(r'^\s*(//|#)').hasMatch(line))
        .join('\n');

/// Whether zip and unzip are installed. The bundle check cases build bundles
/// with zip, and the check lists them with unzip.
final _hasZipTools = ['zip', 'unzip'].every(
  (tool) => Process.runSync('bash', ['-c', 'command -v $tool']).exitCode == 0,
);

/// Runs the bundle check of tool/build.sh under the signing [signing], on a
/// bundle that holds [entries]. Null [entries] stands for a file that unzip
/// cannot list. [shims] is a directory put first on PATH.
ProcessResult _checkBundle(
  String signing,
  List<String>? entries, {
  String? shims,
}) {
  final build = File('tool/build.sh').readAsStringSync();
  const open = '  # A signature block entry marks a signed bundle.';
  const close = '  echo "built \$AAB';
  final start = build.indexOf(open);
  final end = build.indexOf(close, start);
  expect(start, isNonNegative, reason: 'the start of the bundle check');
  expect(end, greaterThan(start), reason: 'the end of the bundle check');
  final dir = Directory.systemTemp.createTempSync('bundle_check_');
  addTearDown(() => dir.deleteSync(recursive: true));
  final aab = File('${dir.path}/app-release.aab');
  if (entries == null) {
    aab.writeAsStringSync('not a zip archive');
  } else {
    final tree = Directory('${dir.path}/tree')..createSync();
    for (final entry in entries) {
      File('${tree.path}/$entry')
        ..createSync(recursive: true)
        ..writeAsStringSync(entry);
    }
    final zip = Process.runSync('zip', [
      '-q',
      '-r',
      aab.path,
      '.',
    ], workingDirectory: tree.path);
    expect(zip.exitCode, 0, reason: '${zip.stderr}');
  }
  final script = File('${dir.path}/check.sh')
    ..writeAsStringSync(
      'set -euo pipefail\n'
      'SIGNING=$signing\n'
      "AAB='${aab.path}'\n"
      '${build.substring(start, end)}'
      'echo "checked \$SIGNATURES"\n',
    );
  final path = Platform.environment['PATH'] ?? '';
  return Process.runSync(
    'bash',
    [script.path],
    environment: {'PATH': shims == null ? path : '$shims:$path'},
  );
}

void main() {
  group('release inputs', () {
    test('tool/release.env holds the version label and build number', () {
      final values = {
        for (final line in File('tool/release.env').readAsLinesSync())
          if (line.contains('=') && !line.startsWith('#'))
            line.split('=').first: line.split('=').last,
      };
      expect(
        values.keys,
        unorderedEquals(['RELEASE_VERSION', 'RELEASE_BUILD']),
      );
      expect(values['RELEASE_VERSION'], matches(RegExp(r'^\d+\.\d+\.\d+$')));
      expect(int.parse(values['RELEASE_BUILD']!), greaterThanOrEqualTo(900));
    });

    test('the mode never reads env/local.json', () {
      final build = File('tool/build.sh').readAsStringSync();
      // The define file is replaced before the read, inside the mode guard.
      expect(
        build,
        contains(
          'if [ "\$MODE" = "--aab" ]; then\n'
          '  DEFINE_FILE="\$SCRATCH/release-defines.json"\n'
          '  write_release_defines > "\$DEFINE_FILE"\n'
          'fi\n'
          'if [ -f "\$DEFINE_FILE" ]; then',
        ),
      );
      expect(build, contains('{"ONEVPN_FAKE_PURCHASES":false'));
      for (final name in const [
        'ONEVPN_RC_SDK_KEY',
        'ONEVPN_UUID',
        'ONEVPN_PBK',
        'ONEVPN_SID',
        'ONEVPN_FREE_NODE_IPS',
        'ONEVPN_ADMOB_APP_ID_ANDROID',
        'ONEVPN_ADMOB_INTERSTITIAL_ANDROID',
      ]) {
        expect(build, contains(name));
      }
    });
  });

  group('version', () {
    test('one reader takes tool/release.env for every app build', () {
      final build = File('tool/build.sh').readAsStringSync();
      expect(
        build,
        contains(
          'if [ "\$MODE" = "--apk" ] || [ "\$MODE" = "--ios" ] || '
          '[ "\$MODE" = "--aab" ]; then\n'
          '  . tool/release.env\n',
        ),
      );
      expect(
        RegExp(r'tool/release\.env\n').allMatches(_code('tool/build.sh')),
        hasLength(1),
      );
    });

    test('every app build passes the version from tool/release.env', () {
      final lines = File('tool/build.sh').readAsLinesSync();
      for (final command in const [
        'build apk',
        'build ios',
        'build appbundle',
      ]) {
        final start = lines.indexWhere(
          (line) =>
              line.trim().startsWith('flutter ') &&
              line.contains(command) &&
              !line.contains('--config-only'),
        );
        expect(start, isNonNegative, reason: command);
        var end = start;
        while (lines[end].endsWith('\\')) {
          end++;
        }
        final invocation = lines.sublist(start, end + 1).join('\n');
        expect(
          invocation,
          contains('--build-name "\$RELEASE_VERSION"'),
          reason: command,
        );
        expect(
          invocation,
          contains('--build-number "\$RELEASE_BUILD"'),
          reason: command,
        );
      }
    });

    test('the debug apk stays a debug build', () {
      final line = File('tool/build.sh').readAsLinesSync().firstWhere(
        (line) =>
            line.trim().startsWith('flutter ') &&
            line.contains('build apk') &&
            !line.contains('--config-only'),
      );
      expect(line, contains('--debug'));
      expect(line, isNot(contains('--release')));
    });
  });

  group('refusals', () {
    test('an empty store key fails the build', () {
      final result = _build(['--aab'], key: '');
      expect(result.exitCode, 4);
      expect(result.stderr, contains('ONEVPN_RC_SDK_KEY is empty'));
    });

    test('a test store key fails the build', () {
      final result = _build(['--aab'], key: 'test_placeholder');
      expect(result.exitCode, 4);
      expect(result.stderr, contains('ONEVPN_RC_SDK_KEY is a test key'));
    });

    test('an empty connection or AdMob value fails and names it', () {
      for (final name in _required.keys) {
        final result = _build(
          ['--aab'],
          key: 'goog_placeholder',
          env: {..._required, name: ''},
        );
        expect(result.exitCode, 4, reason: name);
        expect(result.stderr, contains('$name is empty'), reason: name);
      }
    });

    test('an AdMob id with the sample publisher id fails and names it', () {
      for (final MapEntry(key: name, value: id) in _sampleIds.entries) {
        final result = _build(
          ['--aab'],
          key: 'goog_placeholder',
          env: {..._required, name: id},
        );
        expect(result.exitCode, 4, reason: name);
        expect(
          result.stderr,
          contains("$name is Google's sample id"),
          reason: name,
        );
      }
    });

    test('an AdMob id of the wrong shape fails and names it', () {
      // Shaped like a real publisher's ids. The digits are made up. The ids
      // are built at run time, so this file never holds one for the scrub.
      final publisher = '1' * 16;
      final appId = 'ca-app-pub-$publisher~${'2' * 10}';
      final unitId = 'ca-app-pub-$publisher/${'3' * 10}';
      for (final (name, value, message) in [
        ('ONEVPN_ADMOB_APP_ID_ANDROID', unitId, 'not an AdMob app id'),
        ('ONEVPN_ADMOB_INTERSTITIAL_ANDROID', appId, 'not an AdMob ad unit id'),
      ]) {
        final result = _build(
          ['--aab'],
          key: 'goog_placeholder',
          env: {
            ..._required,
            'ONEVPN_ADMOB_APP_ID_ANDROID': appId,
            'ONEVPN_ADMOB_INTERSTITIAL_ANDROID': unitId,
            name: value,
          },
        );
        expect(result.exitCode, 4, reason: name);
        expect(result.stderr, contains('$name is $message'), reason: name);
      }
    });

    test(
      'only the release mode refuses an empty, sample or malformed value',
      () {
        final build = File('tool/build.sh').readAsStringSync();
        const open = 'if [ "\$MODE" = "--aab" ]; then\n  # The store SDK';
        final start = build.indexOf(open);
        expect(start, isNonNegative);
        final guard = build.substring(start, build.indexOf('\nfi\n', start));
        final code = _code('tool/build.sh');
        for (final refusal in const [
          r'echo "refusing the release build: $name is empty"',
          'ca-app-pub-3940256099942544*)',
          'is not an AdMob app id',
          'is not an AdMob ad unit id',
        ]) {
          // The one refusal sits in the `--aab` guard, so `--apk` and `--ios`
          // stay lenient.
          expect(guard, contains(refusal));
          expect(refusal.allMatches(code), hasLength(1), reason: refusal);
        }
        for (final name in _required.keys) {
          expect(guard, contains(name));
        }
      },
    );

    test(
      'a signed build without the keystore properties fails',
      () {
        final result = _build(['--aab', '--signed'], key: 'goog_placeholder');
        expect(result.exitCode, 4);
        expect(result.stderr, contains('$_keystore is missing'));
      },
      // With the file present, this case would run a full build.
      skip: File(_keystore).existsSync() ? '$_keystore is present' : false,
    );

    test('an argument naming the signing fails the build', () {
      final result = _build([
        '--aab',
        '-Ponevpn-release-signing=debug',
      ], key: 'goog_placeholder');
      expect(result.exitCode, 2);
      expect(result.stderr, contains('only --aab takes --signed'));
    });

    test('the debug signing from the environment fails the build', () {
      for (final (name, value) in const [
        ('ORG_GRADLE_PROJECT_onevpn-release-signing', 'debug'),
        ('GRADLE_OPTS', '-Dorg.gradle.project.onevpn-release-signing=debug'),
        ('JAVA_OPTS', '-Dorg.gradle.project.onevpn-release-signing=debug'),
        (
          'JAVA_TOOL_OPTIONS',
          '-Dorg.gradle.project.onevpn-release-signing=debug',
        ),
      ]) {
        final result = _build(
          ['--aab'],
          key: 'goog_placeholder',
          env: {name: value},
        );
        expect(result.exitCode, 4, reason: name);
        expect(
          result.stderr,
          contains('$name sets onevpn-release-signing'),
          reason: name,
        );
      }
    });

    test('the debug signing from the user gradle.properties fails', () {
      final home = Directory.systemTemp.createTempSync('gradle-home');
      addTearDown(() => home.deleteSync(recursive: true));
      final properties = File('${home.path}/gradle.properties')
        ..writeAsStringSync('onevpn-release-signing=debug\n');
      final result = _build(
        ['--aab'],
        key: 'goog_placeholder',
        env: {'GRADLE_USER_HOME': home.path},
      );
      expect(result.exitCode, 4);
      expect(
        result.stderr,
        contains('${properties.path} sets onevpn-release-signing'),
      );
    });

    test('only the release mode takes --signed', () {
      final result = _build(['--apk', '--signed'], key: '');
      expect(result.exitCode, 2);
      expect(result.stderr, contains('only --aab takes --signed'));
    });
  });

  group('signing', () {
    test('the app module applies the release signing script last', () {
      final gradle = _code('android/app/build.gradle.kts');
      const apply = 'apply(from = "../../tool/release_signing.gradle")';
      expect(gradle, contains(apply));
      expect(gradle.indexOf(apply), greaterThan(gradle.indexOf('buildTypes')));
    });

    test('the release signing script selects debug only by name', () {
      final script = _code('tool/release_signing.gradle');
      expect(script, contains('release.signingConfig = upload'));
      expect(script, contains('release.signingConfig = null'));
      // The one debug selection sits under the `debug` case.
      expect(
        script,
        contains(
          "    case 'debug':\n"
          "        release.signingConfig = android.signingConfigs.getByName('debug')\n"
          '        break\n',
        ),
      );
      expect(RegExp('debug').allMatches(script), hasLength(3));
      // Absent keeps the upload-or-unsigned default.
      expect(
        script,
        contains("    case '':\n        release.signingConfig = upload\n"),
      );
      expect(script, contains('default:\n        throw new GradleException('));
    });

    test('the mode never passes the debug signing', () {
      final build = File('tool/build.sh').readAsStringSync();
      expect(build, contains('  SIGNING=none\n'));
      expect(build, contains('  [ "\$SIGNED" = "true" ] && SIGNING=upload\n'));
      expect(_code('tool/build.sh'), isNot(contains('SIGNING=debug')));
    });

    test('the mode passes the signing to Gradle and checks the bundle', () {
      final build = File('tool/build.sh').readAsStringSync();
      expect(
        build,
        contains('--android-project-arg "onevpn-release-signing=\$SIGNING"'),
      );
      expect(build, contains('the unsigned build carries a signature'));
      expect(build, contains('the signed build carries no signature'));
    });

    test('the script runs under errexit, nounset and pipefail', () {
      // The bundle check stops on a failed count only under errexit.
      final first = File('tool/build.sh').readAsLinesSync().firstWhere(
        (line) => line.trim().isNotEmpty && !line.startsWith('#'),
      );
      expect(first, 'set -euo pipefail');
    });

    group('the bundle check', () {
      const content = [
        'META-INF/MANIFEST.MF',
        'base/manifest/AndroidManifest.xml',
      ];
      const signed = [...content, 'META-INF/UPLOAD.RSA'];

      test('passes an unsigned bundle without a signature', () {
        final result = _checkBundle('none', content);
        expect(result.exitCode, 0, reason: '${result.stderr}');
        expect(result.stdout, 'checked 0\n');
      });

      test('passes a signed bundle with a signature', () {
        final result = _checkBundle('upload', signed);
        expect(result.exitCode, 0, reason: '${result.stderr}');
        expect(result.stdout, 'checked 1\n');
      });

      test('fails an unsigned bundle with a signature', () {
        final result = _checkBundle('none', signed);
        expect(result.exitCode, 1);
        expect(
          result.stderr,
          contains('the unsigned build carries a signature'),
        );
      });

      test('fails a signed bundle without a signature', () {
        final result = _checkBundle('upload', content);
        expect(result.exitCode, 1);
        expect(
          result.stderr,
          contains('the signed build carries no signature'),
        );
      });

      test('stops on a bundle that unzip cannot list, for either signing', () {
        for (final signing in const ['none', 'upload']) {
          final result = _checkBundle(signing, null);
          expect(result.exitCode, 1, reason: signing);
          expect(result.stdout, isEmpty, reason: signing);
          expect(
            result.stderr,
            contains('cannot list the entries of the bundle: '),
            reason: signing,
          );
        }
      });

      test('stops when grep fails while it counts', () {
        final shims = Directory.systemTemp.createTempSync('bundle_check_bin_');
        addTearDown(() => shims.deleteSync(recursive: true));
        final grep = File('${shims.path}/grep')
          ..writeAsStringSync('#!/bin/sh\nexit 2\n');
        Process.runSync('chmod', ['+x', grep.path]);
        final result = _checkBundle('none', content, shims: shims.path);
        expect(result.exitCode, isNot(0));
        expect(result.stdout, isEmpty);
        expect(result.stderr, isNot(contains('cannot list')));
      });
    }, skip: _hasZipTools ? false : 'zip or unzip is not installed');
  });

  group('release workflow', () {
    test('a push and a dispatch of one candidate share one group', () {
      final workflow = File('.github/workflows/release.yml').readAsStringSync();
      // A push names the candidate by its full branch ref. A dispatch input
      // without the refs/ prefix is a branch name, so the group takes the
      // full ref for it too.
      expect(
        workflow,
        contains(
          'concurrency:\n'
          "  group: release-\${{ github.event_name == 'workflow_dispatch' && "
          "(startsWith(inputs.ref, 'refs/') && inputs.ref || "
          "format('refs/heads/{0}', inputs.ref)) || github.ref }}\n"
          '  cancel-in-progress: false\n',
        ),
      );
    });
  });
}
