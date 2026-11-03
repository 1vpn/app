// Hygiene contract for the fork boot surface: the entry point and every
// Dart file under lib/onevpn/ except the post-boot UI under
// lib/onevpn/shell/. The boot surface runs before the shell mounts. It
// must not import window_manager, call desktop window glue, or branch on a
// desktop platform check. It must not reference service initialization.
// That runs when the shell mounts. A boot-surface reference would run
// connect on app launch before the first-boot correction can suppress it.
// It must not touch the permission surface: no permission dialog blocks the
// first frame. New files and directories under lib/onevpn/ join every sweep
// automatically, except the shell. The shell is the post-boot UI the router
// mounts. It owns the tray and the service initialization.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Strips comments, so a commented-out call cannot trip the sweep and a
/// commented-out import cannot hide one.
String _withoutComments(String source) =>
    source.replaceAll(RegExp(r'^\s*//.*$', multiLine: true), '');

/// True when [identifier] appears as a whole word in [source]. The word
/// boundaries keep a longer identifier that merely contains the token
/// out of the match. A WindowServiceX therefore passes a WindowService
/// check.
bool _usesIdentifier(String source, String identifier) =>
    RegExp('\\b${RegExp.escape(identifier)}\\b').hasMatch(source);

/// Every Dart file in the fork boot surface: the entry point and the whole
/// lib/onevpn/ tree. The tree is walked rather than path-pinned, so a new
/// fork directory joins the sweep once it exists.
Map<String, String> _bootSurfaceSources() {
  final files = <File>[
    File("lib/main_1vpn.dart"),
    ...Directory("lib/onevpn")
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith(".dart"))
        // The shell is the post-boot UI the router mounts, so it stays out
        // of the boot-surface sweep. It owns the service initialization and
        // the desktop tray.
        .where(
          (file) => !file.path
              .replaceAll(Platform.pathSeparator, "/")
              .contains("/onevpn/shell/"),
        ),
  ];
  // listSync emits the platform separator. The keys normalize to forward
  // slashes so the guard's literals hold on every host.
  return {
    for (final file in files)
      file.path.replaceAll(Platform.pathSeparator, "/"): _withoutComments(
        file.readAsStringSync(),
      ),
  };
}

/// Anti-vacuity guard shared by every sweep. The walk really found the
/// entry point, the boot defaults, and the root widget, and every
/// swept source is non-empty.
void _expectSweptSurface(Map<String, String> sources) {
  expect(sources.keys, contains("lib/main_1vpn.dart"));
  expect(sources.keys, contains("lib/onevpn/boot/defaults.dart"));
  expect(sources.keys, contains("lib/onevpn/app/app.dart"));
  expect(sources.length, greaterThanOrEqualTo(5));
  sources.forEach((path, source) {
    expect(source.trim(), isNotEmpty, reason: path);
  });
}

void main() {
  // The token is an import path, so the check is a plain substring. It
  // matches any occurrence, string literals included. That fails closed: a
  // flagged literal is a false positive to rename, not a leak.
  test('the boot surface imports no window_manager', () {
    final sources = _bootSurfaceSources();

    _expectSweptSurface(sources);
    sources.forEach((path, source) {
      expect(
        source,
        isNot(contains("window_manager")),
        reason: "$path imports window_manager",
      );
    });
  });

  test('the boot surface makes no desktop-only calls', () {
    const forbidden = [
      "windowManager",
      "WindowOptions",
      "waitUntilReadyToShow",
      "onWindowReady",
      "WindowService",
      "TrayService",
      "AppPlatform.isDesktop",
    ];
    final sources = _bootSurfaceSources();

    _expectSweptSurface(sources);
    sources.forEach((path, source) {
      for (final token in forbidden) {
        expect(
          _usesIdentifier(source, token),
          isFalse,
          reason: "$path contains $token",
        );
      }
    });
  });

  // ServiceManager.serviceInit runs when the main shell mounts. It ends
  // with AppStartupService().handleServicesReady(), which performs connect
  // on app launch. The splash suppresses that connect on the not-accepted
  // path before the shell can mount. A boot-surface reference to any of
  // these would start a VPN before the privacy gate runs.
  test('the boot surface never references service initialization', () {
    const forbidden = [
      "ServiceManager",
      "serviceInit",
      "asyncInitService",
      "handleServicesReady",
      "startDefaultVpn",
    ];
    final sources = _bootSurfaceSources();

    _expectSweptSurface(sources);
    sources.forEach((path, source) {
      for (final token in forbidden) {
        expect(
          _usesIdentifier(source, token),
          isFalse,
          reason: "$path contains $token",
        );
      }
    });
  });

  // Permission prompts belong to the post-boot surface. The word-boundary
  // pattern matches the permission_handler Permission class and leaves
  // identifiers that merely end in Permission alone. permission_handler
  // itself is an import path, so it stays a plain substring check.
  test('the boot surface never touches the permission surface', () {
    final sources = _bootSurfaceSources();

    _expectSweptSurface(sources);
    sources.forEach((path, source) {
      expect(
        source,
        isNot(contains("permission_handler")),
        reason: "$path imports permission_handler",
      );
      expect(
        _usesIdentifier(source, "requestNotificationsPermission"),
        isFalse,
        reason: "$path calls requestNotificationsPermission",
      );
      expect(
        RegExp(r'\bPermission\.').hasMatch(source),
        isFalse,
        reason: "$path uses Permission.",
      );
    });
  });
}
