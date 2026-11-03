import 'package:material_ui/material_ui.dart';
import 'package:onexray/pages/shared/connection_action.dart';
import 'package:onexray/service/connect/coordinator.dart';
import 'package:onexray/service/launch/app_startup.dart';

/// Reuses the normal page's confirmation and commit implementation. Only an
/// actual reconnect confirmation needs to bring the desktop window forward.
Future<void> applyTrayConfiguration(
  BuildContext context,
  Map<String, dynamic> values,
  String label,
  Future<void> Function() validate,
) async {
  final coordinator = ConnectionCoordinator.instance;
  await coordinator.refresh();
  if (coordinator.state.value.phase == ConnectionPhase.connected) {
    await AppStartupService().showMainWindow();
  }
  if (!context.mounted) return;
  await applyConnectionChange(
    context,
    coordinator,
    values,
    label: (_) => label,
    validateAssets: validate,
    rethrowErrors: true,
  );
}
