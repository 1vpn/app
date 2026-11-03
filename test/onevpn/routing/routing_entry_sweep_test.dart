// Pins the RC's routing entry points. The fork Direct-regions picker is the
// only routing surface. The fork router declares its route. The hamburger
// menu carries the entry to it. The connect-screen header indicator pushes
// it. The connect screen has no Direct-regions row. Its only route
// reference is the header indicator. The parked OneXray routing surfaces
// reach no entry point. No fork source references the smart-routing editor,
// its service, or the final-exit picker. No old routing route survives in
// the fork tree.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every Dart source under the fork tree. The fork owns all entry points, so
/// a routing surface reachable from the RC would be referenced here.
Map<String, String> _forkSources() => {
  for (final file
      in Directory('lib/onevpn')
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart')))
    file.path: file.readAsStringSync(),
};

void main() {
  late Map<String, String> fork;

  setUpAll(() {
    fork = _forkSources();
  });

  test('the fork router declares the Direct-regions route to the picker', () {
    // Anti-vacuity guard. The sweep reads the real fork tree.
    expect(fork.length, greaterThan(20));
    final routes = fork['lib/onevpn/shell/routes.dart'];
    final router = fork['lib/onevpn/shell/router.dart'];
    expect(routes, contains('kOneVpnDirectRegionsRoute'));
    expect(router, contains('kOneVpnDirectRegionsRoute'));
    expect(router, contains('OneVpnDirectRegionsPage'));
  });

  test('the header indicator carries the connect-screen route reference', () {
    final connect = fork['lib/onevpn/shell/connect_screen.dart'];
    expect(connect, isNotNull);
    // The connect screen has no Direct-regions row. Its route reference lives
    // in the header routing indicator, mounted in the AppBar actions.
    expect(connect, contains('OneVpnRouteIndicator'));
    expect(connect, contains('kOneVpnDirectRegionsRoute'));
  });

  test('the hamburger menu carries the Direct-regions entry', () {
    final menu = fork['lib/onevpn/shell/menu.dart'];
    expect(menu, isNotNull);
    // The entry pushes the page over the menu, which stays beneath it.
    expect(
      menu,
      contains('onTap: () => context.push(kOneVpnDirectRegionsRoute)'),
    );
  });

  test('no fork source reaches the parked routing surfaces', () {
    for (final entry in fork.entries) {
      for (final marker in const [
        'SmartRoutingEditorPage',
        'SmartRoutingEditorController',
        'SmartRoutingEditorService',
        'ServerExitPickerPage',
        'ServerExitPickerController',
        '/setup/region',
        'AppSecondaryDestination.directRegions',
      ]) {
        expect(
          entry.value,
          isNot(contains(marker)),
          reason: '${entry.key} reaches a parked routing surface via $marker',
        );
      }
    }
  });
}
