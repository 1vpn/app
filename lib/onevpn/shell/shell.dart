import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:onexray/core/tools/platform.dart';
import 'package:onexray/onevpn/boot/launch_hold.dart';
import 'package:onexray/onevpn/feedback/failure_message.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations.dart';
import 'package:onexray/onevpn/shell/connect_screen.dart';
import 'package:onexray/onevpn/theme/button.dart';
import 'package:onexray/pages/main/menu_actions.dart';
import 'package:onexray/service/manager.dart';
import 'package:onexray/service/shared/failure.dart';
import 'package:onexray/service/shared/menu/tray/service.dart';

/// How long the shell waits for the runtime service initialization before it
/// shows the failure screen. Normal startup takes about a second, and a slow
/// first launch that installs the bundled geodata stays inside the bound. The
/// initialization keeps running past the bound, and Retry waits on it again.
const Duration kOneVpnStartupTimeout = Duration(seconds: 20);

/// The one-screen shell mounted at the router's root. It runs the runtime
/// service initialization, then mounts the connect screen. At launch the
/// native splash covers the initialization, and the first frame it releases
/// is the connect screen.
///
/// A failure, or an initialization that outlasts [startupTimeout], releases
/// the first frame and shows an error with a retry. The error stays on screen
/// while a retry runs, with its button disabled. The shell has no tabs and no
/// bottom navigation.
///
/// On desktop it owns the tray configuration callback. The connect screen it
/// mounts handles the start shortcut.
class OneVpnShell extends StatefulWidget {
  const OneVpnShell({
    super.key,
    this.initializeServices,
    this.startupTimeout = kOneVpnStartupTimeout,
    this.connectScreen,
  });

  /// Overrides the runtime service initialization in tests.
  final Future<void> Function(BuildContext context)? initializeServices;

  /// How long the initialization may run before the shell shows the failure
  /// screen. Tests shorten it.
  final Duration startupTimeout;

  /// Overrides the screen mounted once startup succeeds, in tests.
  final Widget? connectScreen;

  @override
  State<OneVpnShell> createState() => _OneVpnShellState();
}

class _OneVpnShellState extends State<OneVpnShell> {
  Future<void>? _servicesReady;
  Timer? _startupTimer;
  bool _trayAttached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _servicesReady ??= _initializeServices();
  }

  /// Runs the initialization under [OneVpnShell.startupTimeout]. A run past
  /// the bound fails with a `startupTimeout` failure. The initialization
  /// itself keeps going, and its late result is dropped.
  Future<void> _initializeServices() {
    final startup = Completer<void>();
    final limit = widget.startupTimeout;
    final timer = Timer(limit, () {
      if (startup.isCompleted) return;
      startup.completeError(
        AppFailure(
          FailureCategory.runtime,
          'startupTimeout',
          cause: TimeoutException(
            'service initialization exceeded its deadline',
            limit,
          ),
        ),
      );
    });
    _startupTimer = timer;
    void settle(void Function() complete) {
      timer.cancel();
      if (!startup.isCompleted) complete();
    }

    unawaited(
      (widget.initializeServices ?? ServiceManager.serviceInit)(context).then(
        (_) => settle(startup.complete),
        onError: (Object error, StackTrace stackTrace) =>
            settle(() => startup.completeError(error, stackTrace)),
      ),
    );
    // The builder subscribes on the next frame. The error is already handled.
    startup.future.ignore();
    return startup.future;
  }

  void _attachTray() {
    if (_trayAttached || !AppPlatform.isDesktop) return;
    _trayAttached = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      TrayService().onConfigurationChange = (values, label, validate) =>
          applyTrayConfiguration(context, values, label, validate);
    });
  }

  void _retry() {
    setState(() {
      _servicesReady = _initializeServices();
    });
  }

  @override
  void dispose() {
    _startupTimer?.cancel();
    if (AppPlatform.isDesktop) TrayService().onConfigurationChange = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _servicesReady,
      builder: (context, snapshot) {
        final running = snapshot.connectionState != ConnectionState.done;
        // A retry keeps the snapshot's last error until it ends, so the
        // failure screen stays up while it runs.
        if (running && !snapshot.hasError) {
          return const Scaffold(body: SizedBox.shrink());
        }
        if (!running) {
          // The hold lifts after the frame that draws the connect screen or the
          // error. The release requests the next frame, the first one sent.
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => OneVpnLaunchHold.release(),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SelectableText(
                      oneVpnAppFailureMessage(
                        OneVpnLocalizations.of(context)!,
                        snapshot.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const ValueKey('service-initialization-retry'),
                      style: OneVpnButton.style,
                      onPressed: running ? null : _retry,
                      child: Text(
                        OneVpnLocalizations.of(context)!.onevpnButtonRetry,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        _attachTray();
        return widget.connectScreen ?? const OneVpnConnectScreen();
      },
    );
  }
}
