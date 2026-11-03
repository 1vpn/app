import 'package:onexray/core/tools/logger.dart';

/// The bound on each awaited boot step.
const Duration kOneVpnBootStepTimeout = Duration(seconds: 10);

/// Runs a critical boot step within [timeout].
///
/// [action] starts synchronously, so its work before the first await runs
/// before this call returns. A throw or an expired [timeout] rethrows as a
/// [StateError] with the original stack trace. A step that completes after
/// the bound has no effect.
Future<void> oneVpnCriticalStep(
  Future<void> Function() action, {
  Duration timeout = kOneVpnBootStepTimeout,
}) async {
  try {
    await action().timeout(timeout);
  } catch (error, stackTrace) {
    Error.throwWithStackTrace(
      StateError("critical boot step failed: $error"),
      stackTrace,
    );
  }
}

/// Runs an optional boot step within [timeout].
///
/// A throw or an expired [timeout] is logged under [name], and the returned
/// future completes normally. A step that completes or throws after the
/// bound has no effect.
Future<void> oneVpnOptionalStep(
  String name,
  Future<void> Function() action, {
  Duration timeout = kOneVpnBootStepTimeout,
}) async {
  try {
    await action().timeout(timeout);
  } catch (error, stackTrace) {
    ygLogger("boot step $name failed: $error\n$stackTrace");
  }
}
