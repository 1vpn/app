// The launch and resume triggers for session revalidation.

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/account/refresh_cooldown.dart';

/// Revalidates the session at launch and when the app comes back to the
/// foreground.
///
/// The beacon is its own lifecycle observer. The connection coordinator
/// and the geodata scheduler each register their own.
///
/// There are two triggers. A foregrounded [register] is the launch. It
/// refreshes a signed-in session whatever the cooldown, once per process.
/// A resume refreshes once the cooldown has passed, or while a premium
/// grant is pending. The beacon runs no
/// timer, alarm or scheduled job.
///
/// A signed-out user makes zero calls on this path.
class OneVpnResumeBeacon with WidgetsBindingObserver {
  OneVpnResumeBeacon({OneVpnAccountService? service, DateTime Function()? now})
    : _service = service ?? OneVpnAccountService.instance,
      _now = now ?? DateTime.now;

  /// The beacon the boot sequence registers. One observer per process:
  /// a second would refresh twice on one resume.
  static final OneVpnResumeBeacon instance = OneVpnResumeBeacon();

  final OneVpnAccountService _service;
  final DateTime Function() _now;

  bool _registered = false;
  Future<void> _pending = Future<void>.value();

  /// The work the last resume started. Completes when that resume has
  /// finished deciding and refreshing.
  @visibleForTesting
  Future<void> get pending => _pending;

  /// Starts observing. Idempotent: a second call registers nothing.
  ///
  /// The framework dispatches the first `resumed` during boot, before this
  /// observer is added. That first resume never reaches
  /// [didChangeAppLifecycleState]. A launch that is already foregrounded
  /// counts as an app open. It refreshes a signed-in session whatever the
  /// cooldown.
  void register() {
    if (_registered) return;
    WidgetsBinding.instance.addObserver(this);
    _registered = true;
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      _pending = _pending
          .then((_) => _onResumed(launch: true))
          .catchError((Object _) {});
    }
  }

  void unregister() {
    if (!_registered) return;
    WidgetsBinding.instance.removeObserver(this);
    _registered = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // The framework's callback is synchronous. The refresh runs after it
    // returns, chained behind the previous resume. Two quick resumes never
    // interleave their decisions.
    //
    // The chain absorbs a failure rather than carrying it forward. One
    // fault costs one resume, and later resumes still run.
    _pending = _pending.then((_) => _onResumed()).catchError((Object _) {});
  }

  /// Refreshes a signed-in session. A [launch] skips the cooldown. A resume
  /// reads it, unless a premium grant is pending.
  Future<void> _onResumed({bool launch = false}) async {
    await _service.whenRestored();
    if (!_service.isSignedIn) return;
    // A pending grant refreshes on every foreground. A slow webhook confirms
    // without the daily cooldown wait.
    final pending = _service.session?.isPremiumPending ?? false;
    if (!launch &&
        !pending &&
        !isRefreshDue(
          await _service.lastRefreshAt(),
          _now(),
          cooldown: _service.cooldown,
        )) {
      return;
    }
    await _service.refresh(manual: launch);
  }
}
