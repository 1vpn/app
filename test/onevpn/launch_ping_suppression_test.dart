// Pins the absence of a launch-time probe burst. Service init never calls
// startAutomatic. The boot provisioner fills the outbound table with the whole
// node floor. A launch-path call would probe every node before any connect
// intent. The method itself stays for the setup and manual paths. The sweep
// fails when an upstream merge restores the launch trigger.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('service init starts no background probe burst', () {
    final manager = File('lib/service/manager.dart').readAsStringSync();
    // Positive control: a call that service init is known to hold. It proves
    // the read returns file content before the absence below counts.
    expect(manager, contains('BackgroundTaskService().init('));
    expect(
      manager,
      isNot(contains('.startAutomatic(')),
      reason:
          'the launch-time probe burst is removed; connect-time '
          'probe-and-pick is the only prober the product runs',
    );
  });

  test('startAutomatic itself stays for the setup and manual paths', () {
    // The method stays. Setup imports and the manual path still enable
    // background probing.
    expect(
      File('lib/service/shared/ping/service.dart').readAsStringSync(),
      contains('void startAutomatic()'),
    );
  });
}
