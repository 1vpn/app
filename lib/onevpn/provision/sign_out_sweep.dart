// The sign-out sweep bound to the account service's step-3 seam.
//
// Removes the account's node rows, returns the free floor rows to the
// compiled set, and clears the runtime files that hold the compiled config. The account's credentials then leave the disk with the
// session. Each half runs under its own guard and reports its outcome. Sign-out
// never fails: the caller records what a step could not do instead of assuming
// it was done.

import 'dart:io';

import 'package:onexray/core/pigeon/constants.dart';
import 'package:onexray/onevpn/account/outcomes.dart';
import 'package:onexray/onevpn/provision/node_provisioner.dart';

/// Sweeps the provisioned rows and the runtime files, reporting each.
///
/// The two steps are injectable, so the composition runs without a database or
/// a filesystem. Production uses the real provisioner and run directory.
Future<OneVpnSweepResult> oneVpnSignOutSweep({
  Future<int> Function()? forgetNodes,
  Future<void> Function()? clearRuntimeFiles,
}) async {
  final detail = <String>[];

  var nodesSwept = false;
  try {
    await (forgetNodes ?? OneVpnNodeProvisioner().forgetSessionNodes)();
    nodesSwept = true;
  } catch (error) {
    detail.add('the node sweep failed: ${error.runtimeType}');
  }

  var filesCleared = false;
  try {
    await (clearRuntimeFiles ?? _clearRuntimeFiles)();
    filesCleared = true;
  } catch (error) {
    detail.add('the runtime file sweep failed: ${error.runtimeType}');
  }

  return OneVpnSweepResult(
    nodesSwept: nodesSwept,
    filesCleared: filesCleared,
    detail: detail.isEmpty ? null : detail.join('; '),
  );
}

/// Deletes the contents of the runtime session directory. A fresh connect
/// recompiles what it needs. Clearing the directory costs nothing and takes the
/// account's compiled config off disk. An absent directory needs no clearing.
Future<void> _clearRuntimeFiles() async {
  final directory = Directory(VpnConstants.runDir);
  if (!await directory.exists()) return;
  await for (final entry in directory.list(followLinks: false)) {
    await entry.delete(recursive: true);
  }
}
