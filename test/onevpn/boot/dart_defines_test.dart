// Build-time configuration: the names, the template, and the ignore rules.
//
// Every value the app reads at build time is a --dart-define. A developer
// supplies them from env/local.json. The app builds pick that file up when
// it exists. CI has no such file and passes no defines, so its builds read
// the empty-string fallbacks. The suite never reads that file, on any
// machine.
//
// This suite pins five silent breaks:
//
// - a template that drifts from the names the code reads
// - an app build that stops passing the file
// - a test run that starts passing the file
// - an app build that skips the free node guard
// - an ignore rule that lets a real file with a key be committed

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Whether git excludes [path]. The check asks git rather than reading the
/// ignore file. The pattern shape holds, not the names spelled out in it.
bool _ignores(String path) =>
    Process.runSync('git', ['check-ignore', '-q', path]).exitCode == 0;

/// The build script's flutter and dart call prefixes.
const _flutter = 'flutter --suppress-analytics --no-version-check';
const _dart = 'dart --suppress-analytics';

/// Whether [line] is the app build that starts with [command]. The
/// `--config-only` call writes the Gradle wrapper and builds no app.
bool _appBuild(String line, String command) =>
    line.trim().startsWith(command) && !line.contains('--config-only');

/// The defines the app reads, and the file each one is read in.
const _defineSites = <String, String>{
  'ONEVPN_RC_SDK_KEY': 'lib/onevpn/purchase/purchase_config.dart',
  'ONEVPN_UUID': 'lib/onevpn/catalogue/free_floor.dart',
  'ONEVPN_PBK': 'lib/onevpn/catalogue/free_floor.dart',
  'ONEVPN_SID': 'lib/onevpn/catalogue/free_floor.dart',
  'ONEVPN_FREE_NODE_IPS': 'lib/onevpn/catalogue/free_floor.dart',
  'ONEVPN_FAKE_PURCHASES': 'lib/onevpn/purchase/purchase_backend.dart',
  'ONEVPN_ADMOB_APP_ID_ANDROID': 'tool/admob.gradle',
  'ONEVPN_ADMOB_INTERSTITIAL_ANDROID': 'lib/onevpn/ads/admob_ad_gateway.dart',
};

/// The template entries that carry Google's published AdMob test ids. They
/// are public sample values, never secrets.
const _testIds = <String, String>{
  'ONEVPN_ADMOB_APP_ID_ANDROID': 'ca-app-pub-3940256099942544~3347511713',
  'ONEVPN_ADMOB_INTERSTITIAL_ANDROID': 'ca-app-pub-3940256099942544/1033173712',
};

void main() {
  late String build;
  late Map<String, dynamic> template;

  setUpAll(() {
    build = File('tool/build.sh').readAsStringSync();
    template = jsonDecode(
      File('env/local.example.json').readAsStringSync(),
    ) as Map<String, dynamic>;
  });

  test('every define the app reads is named in the template', () {
    for (final entry in _defineSites.entries) {
      final source = File(entry.value).readAsStringSync();
      // Anti-vacuity: the name is really read where the map says it is.
      expect(
        source,
        contains("'${entry.key}'"),
        reason: '${entry.key} is no longer read in ${entry.value}',
      );
      expect(
        template.keys,
        contains(entry.key),
        reason: '${entry.key} is missing from env/local.example.json',
      );
    }
  });

  test('the template names keys and carries no secrets', () {
    // A committed template that grew a real key would publish it. Only the
    // toggle, the explanatory field, and Google's AdMob test ids carry
    // content.
    for (final entry in template.entries) {
      if (entry.key == '_readme' || entry.key == 'ONEVPN_FAKE_PURCHASES') {
        continue;
      }
      if (_testIds.containsKey(entry.key)) {
        expect(entry.value, _testIds[entry.key], reason: entry.key);
        continue;
      }
      expect(
        entry.value,
        '',
        reason: '${entry.key} carries a value in the committed template',
      );
    }
    expect(template['_readme'], isA<String>());
    expect(template.keys, containsAll(_defineSites.keys));
  });

  test('the app builds pass the define file when it exists', () {
    expect(build, contains('DEFINE_FILE=env/local.json'));
    expect(build, contains('--dart-define-from-file="\$DEFINE_FILE"'));
    // The build reads the file only when it exists. A checkout without the
    // file still builds.
    expect(build, contains('if [ -f "\$DEFINE_FILE" ]; then'));
  });

  test('the define file is passed ahead of the entry point', () {
    // The file flag comes first, so the explicit flags read last. Ordering
    // does not decide precedence.
    for (final command in const [
      '$_flutter build apk',
      '$_flutter build ios',
      '$_flutter build appbundle',
    ]) {
      final line = build
          .split('\n')
          .firstWhere((line) => _appBuild(line, command));
      expect(
        line.indexOf('DART_DEFINES'),
        lessThan(line.indexOf('-t ')),
        reason: '$command must pass the define file before the entry point',
      );
    }
  });

  test('the suite never takes the define file', () {
    // A developer's env/local.json can carry a real store key. Forwarding
    // it into the suite would make the gate answer differently on their
    // machine than on CI.
    final line = build
        .split('\n')
        .firstWhere((line) => line.trim().startsWith('$_flutter test'));

    expect(line, isNot(contains('DART_DEFINES')));
    expect(line, isNot(contains('dart-define')));
  });

  test('the app builds run the free node guard before they build', () {
    final lines = build.split('\n').map((line) => line.trim()).toList();
    final guard = lines.indexOf(
      '$_dart run tool/check_free_node_ips.dart "\$DEFINE_FILE"',
    );

    expect(guard, greaterThan(1));
    // The guard runs for the three app builds and never for the suite.
    expect(
      lines[guard - 2],
      'if [ "\$MODE" = "--apk" ] || [ "\$MODE" = "--ios" ] || '
      '[ "\$MODE" = "--aab" ]; then',
    );
    for (final command in const [
      '$_flutter build apk',
      '$_flutter build ios',
      '$_flutter build appbundle',
    ]) {
      expect(
        lines.indexWhere((line) => _appBuild(line, command)),
        greaterThan(guard),
        reason: '$command must run after the free node guard',
      );
    }
  });

  test('a real define file can never be committed', () {
    // The rule is a shape: deny everything under env/ and re-admit the one
    // template. A name nobody has thought of yet lands ignored with no
    // .gitignore edit.
    for (final name in const [
      'env/local.json',
      'env/sandbox.json',
      'env/prod.json',
      'env/prod-ios.json',
      'env/whatever-the-next-one-is.json',
    ]) {
      expect(_ignores(name), isTrue, reason: '$name is not ignored');
    }
    // The names-only template is the one file that stays tracked.
    expect(_ignores('env/local.example.json'), isFalse);
    expect(File('env/local.example.json').existsSync(), isTrue);
  });
}
