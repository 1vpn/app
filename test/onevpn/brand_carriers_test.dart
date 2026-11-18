// Pins the in-app and native brand carriers to 1VPN. The Windows
// notification names the app 1VPN. Only the primary iOS icon bundle ships.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the Windows notification names the app 1VPN', () {
    final service = File('lib/service/shared/notification/service.dart')
        .readAsStringSync();
    expect(service, contains("appName: '1VPN'"));
  });

  // swift/ and ios/ are not in the exported public tree.
  final iconSkip =
      Directory('swift/App/AppIcon').existsSync() &&
          File('ios/Runner.xcodeproj/project.pbxproj').existsSync()
      ? false
      : 'swift/App/AppIcon/ or ios/Runner.xcodeproj/project.pbxproj is not in '
            'this tree';

  test('only the primary iOS icon bundle ships', skip: iconSkip, () {
    final bundles = Directory('swift/App/AppIcon')
        .listSync()
        .map((entry) => entry.uri.pathSegments.where((s) => s.isNotEmpty).last)
        .where((name) => name.endsWith('.icon'))
        .toList();
    expect(bundles, ['IconBlue.icon']);
    final project = File('ios/Runner.xcodeproj/project.pbxproj')
        .readAsStringSync();
    expect(project, isNot(contains('ALTERNATE_APPICON_NAMES')));
    expect(project, contains('ASSETCATALOG_COMPILER_APPICON_NAME = IconBlue;'));
  });
}
