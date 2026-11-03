// The sign-out sweep's composition: both halves run, each is reported, and a
// throw in one is recorded without skipping the other. The node half and the
// runtime-file half are injected, so this drives the wiring without a database
// or a filesystem.

import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/provision/sign_out_sweep.dart';

void main() {
  test(
    'a clean sweep reports both halves done and carries no detail',
    () async {
      final calls = <String>[];
      final result = await oneVpnSignOutSweep(
        forgetNodes: () async {
          calls.add('nodes');
          return 3;
        },
        clearRuntimeFiles: () async => calls.add('files'),
      );

      expect(calls, <String>['nodes', 'files']);
      expect(result.nodesSwept, isTrue);
      expect(result.filesCleared, isTrue);
      expect(result.detail, isNull);
    },
  );

  test(
    'a throwing node sweep is recorded and the file sweep still runs',
    () async {
      var filesCleared = false;
      final result = await oneVpnSignOutSweep(
        forgetNodes: () async => throw StateError('db gone'),
        clearRuntimeFiles: () async => filesCleared = true,
      );

      expect(result.nodesSwept, isFalse);
      expect(filesCleared, isTrue);
      expect(result.filesCleared, isTrue);
      expect(result.detail, contains('node sweep failed'));
    },
  );

  test(
    'a throwing file sweep is recorded and does not undo the node sweep',
    () async {
      final result = await oneVpnSignOutSweep(
        forgetNodes: () async => 1,
        clearRuntimeFiles: () async => throw StateError('fs gone'),
      );

      expect(result.nodesSwept, isTrue);
      expect(result.filesCleared, isFalse);
      expect(result.detail, contains('runtime file sweep failed'));
    },
  );
}
