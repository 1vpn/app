// Pins the VPN-permission posture. The OS permission prompt fires at the
// first connect intent, never at app launch. Startup initialize keeps the
// upstream request-once mechanism but supplies no action. It only publishes
// the un-granted state: issue permissionRequired, with the permission
// payload. The connect screen requests when the user acts on that state.
// Connect-on-launch follows the same posture. An un-granted state shows the
// main window instead of dialing past the prompt.
//
// The upstream coordinator test covers the behavior of both coordinator
// sides. Its test 'initialization exposes a missing platform permission'
// covers the promptless path. These content anchors pin which side the fork
// wires where.
//
// The anchors name three files. The census below lists every prompt call
// site the two app entries reach. A prompt wired into a fourth file fails
// it. The opt-in of the requirements check can re-arm a launch prompt
// without touching an anchored file. The census holds that opt-in at zero
// callers.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/lib_closure.dart';

/// Every reachable prompt call site as `path | line`, both trimmed, in path
/// order. The pigeon wrapper and the generated channel call carry the
/// request. The list also holds the opt-in branch of the requirements check
/// and the intent site on the connect screen. Only the connect-screen line
/// runs in production. The test below holds the opt-in at zero callers. A
/// new entry is a new place the OS prompt can fire. It lands here with the
/// decision behind it.
const _promptCensus = [
  'lib/core/pigeon/host_api.dart | '
      'Future<PlatformPermissionResult> requestPlatformPermission() async {',
  'lib/core/pigeon/host_api.dart | '
      'final permission = await _api.requestPlatformPermission();',
  'lib/core/pigeon/messages.g.dart | '
      'Future<PlatformPermissionResult> requestPlatformPermission() async {',
  'lib/onevpn/shell/connect_screen.dart | '
      'final result = await AppHostApi().requestPlatformPermission();',
  'lib/service/connect/platform_requirements.dart | '
      'return host.requestPlatformPermission();',
];

void main() {
  test('startup initializes the coordinator without a permission prompt', () {
    final manager = File('lib/service/manager.dart').readAsStringSync();
    // Anti-vacuity: startup still initializes the coordinator here.
    expect(
      manager,
      contains('await ConnectionCoordinator.instance.initialize()'),
    );
    // The upstream request-at-shell wiring stays out.
    expect(manager, isNot(contains('requestPermission')));
    expect(manager, isNot(contains('requestPlatformPermission')));
  });

  test('the connect intent carries the permission request', () {
    final connectScreen = File('lib/onevpn/shell/connect_screen.dart')
        .readAsStringSync();
    // The connect branch requests the permission where the published
    // un-granted state surfaces. The ad gate, the release of a held TUN,
    // and the connect follow. A declined permission reads grey, so its tap
    // reaches this branch.
    final intent = RegExp(
      r"if \(view\.issue == 'permissionRequired' && view\.permission != null\) \{\s*"
      r"final result = await AppHostApi\(\)\.requestPlatformPermission\(\);"
      r"[^}]*\}\s*"
      r"(//[^\n]*\s*)*"
      r"if \(permitted &&\s*!await _adGate\.beforeConnect\(\s*_account,\s*"
      r"switching: switchTo != null,\s*\)\) \{\s*return;\s*\}\s*"
      r"await _held\.release\(_coordinator\);\s*"
      r"await _coordinator\.connect\(\);",
    );
    expect(intent.hasMatch(connectScreen), isTrue);
  });

  test('connect-on-launch never dials past an un-granted permission', () {
    final startup = File('lib/service/launch/app_startup.dart')
        .readAsStringSync();
    final guard = RegExp(
      r"if \(ConnectionCoordinator\.instance\.state\.value\.issue ==\s*"
      r"'permissionRequired'\) \{\s*await showMainWindow\(\);\s*return;",
    );
    expect(guard.hasMatch(startup), isTrue);
  });

  test('the prompt is called from exactly the pinned sites in lib', () {
    final sources = libClosureSources();

    // Anti-vacuity: the sweep reads the real tree, and the intent site
    // the posture depends on is in what it read.
    expect(sources.length, greaterThan(200));

    final census = [
      for (final file in sources)
        for (final line in file.readAsLinesSync())
          if (line.contains('requestPlatformPermission('))
            '${file.path} | ${line.trim()}',
    ];
    expect(
      census,
      contains(
        'lib/onevpn/shell/connect_screen.dart | '
        'final result = await AppHostApi().requestPlatformPermission();',
      ),
    );

    expect(
      census,
      _promptCensus,
      reason:
          'the OS permission prompt fires at the first connect intent '
          'and nowhere else; a new call site must land in the census '
          'with the decision that put it there',
    );
  });

  test('nothing in lib asks the requirements check to prompt', () {
    final requirements = File('lib/service/connect/platform_requirements.dart')
        .readAsStringSync();

    // Anti-vacuity: the opt-in still exists and still reaches the prompt.
    // The negative below then counts the callers of a live mechanism.
    expect(requirements, contains('check({bool request = false})'));
    expect(requirements, contains('return host.requestPlatformPermission();'));

    for (final file in libClosureSources()) {
      expect(
        file.readAsStringSync(),
        isNot(contains('check(request')),
        reason:
            '${file.path} opts the requirements check into prompting; '
            'that re-arms the prompt wherever the check runs, launch '
            'paths included',
      );
    }
  });
}
