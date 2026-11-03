// Pins upstream runConnectionAction and applyConnectionChange, the originals
// of the fork's oneVpnRunConnectionAction and oneVpnApplyConnectionChange. A
// failure here means an upstream bump changed an original. Re-check the two
// fork functions in lib/onevpn/feedback/connection_actions.dart against the
// new upstream bodies. Then update the pinned shapes. The fork copies keep
// the upstream cancel filter clause for clause.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _upstream = 'lib/pages/shared/connection_action.dart';
const _fork = 'lib/onevpn/feedback/connection_actions.dart';

const _realign =
    'upstream changed: re-check oneVpnRunConnectionAction and '
    'oneVpnApplyConnectionChange in $_fork';

/// The body of the top-level function in [path] whose first line starts
/// with [signaturePrefix]. It runs from the signature through the closing
/// brace at column zero. Comment lines are dropped, and whitespace runs
/// collapse to single spaces. Formatting cannot move the pin. Statements
/// can.
String _normalizedFunction(String path, String signaturePrefix) {
  final lines = File(path).readAsLinesSync();
  final start = lines.indexWhere((line) => line.startsWith(signaturePrefix));
  expect(start, isNot(-1), reason: '$path lacks $signaturePrefix');
  final body = <String>[];
  for (var index = start; index < lines.length; index++) {
    final line = lines[index];
    if (RegExp(r'^\s*//').hasMatch(line)) {
      continue;
    }
    body.add(line);
    if (line == '}') {
      return body.join('\n').replaceAll(RegExp(r'\s+'), ' ').trim();
    }
  }
  fail('$path: the function at $signaturePrefix never closes at column zero');
}

/// Upstream runConnectionAction, normalized.
const _pinnedRun =
    "Future<bool> runConnectionAction( BuildContext context, "
    "ConnectionCoordinator coordinator, Future<void> Function() action, { "
    "bool rethrowErrors = false, }) async { try { await action(); "
    "return true; } catch (error) { if (rethrowErrors) rethrow; "
    "if (!failureCancelled(error) && "
    "connectionFailureReason(error) != 'cancelled' && "
    "coordinator.state.value.issue != 'cancelled' && context.mounted) { "
    "final l = AppLocalizations.of(context)!; ContextAlert.showToast( "
    "context, connectionFailureMessage(l, error: error), ); } "
    "return false; } }";

/// Upstream applyConnectionChange, normalized.
const _pinnedApply =
    "Future<ConnectionConfiguration?> applyConnectionChange( "
    "BuildContext context, ConnectionCoordinator coordinator, "
    "Map<String, dynamic> values, { "
    "required String Function(ConnectionSettings) label, "
    "Future<void> Function()? writeAssets, "
    "Future<void> Function()? validateAssets, "
    "bool rethrowErrors = false, }) async { "
    "final current = await coordinator.configuration; "
    "final next = ConnectionConfiguration( "
    "connection: ConnectionSettings.fromJson({ "
    "...current.connection.toJson(), ...values, }), "
    "policy: current.policy, ); "
    "if (next.encode() == current.encode() && writeAssets == null) "
    "return current; if (!context.mounted) return null; "
    "final reconnect = "
    "coordinator.state.value.phase == ConnectionPhase.connected; "
    "if (reconnect && !await showApplyAndReconnectDialog( context, "
    "label: label(next.connection), )) { return null; } "
    "if (!context.mounted) return null; ConnectionConfiguration? saved; "
    "await runConnectionAction(context, coordinator, () async { "
    "await coordinator.apply( next, writeAssets: writeAssets, "
    "validateAssets: validateAssets, "
    "expectedConfiguration: current.encode(), "
    "allowReconnect: reconnect, ); "
    "saved = await coordinator.configuration; }, "
    "rethrowErrors: rethrowErrors); return saved; }";

/// The shared cancel filter: a failure shows nothing when any clause marks a
/// cancel by the user.
const _cancelFilter =
    "if (!failureCancelled(error) && "
    "connectionFailureReason(error) != 'cancelled' && "
    "coordinator.state.value.issue != 'cancelled' && context.mounted) {";

/// The shared merge, change check, and reconnect gate of an apply. The fork
/// gate reads the connected phase after any in-place reload and adds the
/// reload's own not-running answer.
const _sharedApplySteps = [
  "final current = await coordinator.configuration;",
  "...current.connection.toJson(), ...values, }), policy: current.policy, );",
  "final reconnect = "
      "coordinator.state.value.phase == ConnectionPhase.connected",
  "expectedConfiguration: current.encode(), allowReconnect: reconnect, );",
  "saved = await coordinator.configuration;",
];

void main() {
  test('upstream runConnectionAction keeps its pinned shape', () {
    final run = _normalizedFunction(
      _upstream,
      'Future<bool> runConnectionAction(',
    );
    // Anti-vacuity guard. The extraction produced the whole function.
    expect(run, contains('return false;'));
    expect(run, _pinnedRun, reason: _realign);
  });

  test('upstream applyConnectionChange keeps its pinned shape', () {
    final apply = _normalizedFunction(
      _upstream,
      'Future<ConnectionConfiguration?> applyConnectionChange(',
    );
    expect(apply, contains('return saved;'));
    expect(apply, _pinnedApply, reason: _realign);
  });

  test('the fork copies keep the upstream cancel filter and apply steps', () {
    final run = _normalizedFunction(
      _fork,
      'Future<bool> oneVpnRunConnectionAction(',
    );
    final apply = _normalizedFunction(
      _fork,
      'Future<ConnectionConfiguration?> oneVpnApplyConnectionChange(',
    );
    expect(_pinnedRun, contains(_cancelFilter));
    expect(
      run,
      contains(_cancelFilter),
      reason: 'oneVpnRunConnectionAction drops an upstream cancel clause',
    );
    for (final step in _sharedApplySteps) {
      expect(_pinnedApply, contains(step));
      expect(
        apply,
        contains(step),
        reason: 'oneVpnApplyConnectionChange drops the upstream step $step',
      );
    }
  });
}
