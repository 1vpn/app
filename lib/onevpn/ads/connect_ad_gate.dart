import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:onexray/core/tools/logger.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/ads/ad_gateway.dart';
import 'package:onexray/onevpn/ads/admob_ad_gateway.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The interstitial gate on the connect control's tap and on a free location
/// switch.
///
/// [beforeConnect] answers whether the connect proceeds. A switch follows
/// every rule a tap follows. Rules 5 and 10 add its wait, and rule 6 adds
/// its check that the app is in front. Rule 11 lets its abandoned show
/// proceed. The contract:
///
/// 1. A premium or pending-premium session proceeds. It never touches the
///    gateway. A restoring account state does the same: no consent run, no
///    preload, no ad, and no first-connect stamp.
/// 2. The first connect of a free account is ad-free. The first connect tap
///    ever stamps [firstConnectKey] and proceeds. It shows no ad and no
///    consent form. This check runs first after the exemption check. A
///    preference store that throws never fails the tap. A read that throws
///    counts as the first connect, and the stamp is best effort.
/// 3. A later tap while ads are not yet allowed first waits on an update
///    in flight, for at most [pendingUpdateWait]. A wait that runs out
///    proceeds with no ad and no form, and the update keeps running. When
///    the update allows ads, the tap follows rules 5 to 7. Otherwise the
///    tap shows the consent form, waits for it, and proceeds with no ad. An
///    allowing form starts no load. The ad stays before the connect and off
///    the tunnel, its request included. A load started after the form can
///    send its request after tunnel-up. The disconnect preload fills the
///    cache for the next tap.
/// 4. A form that does not allow ads, or throws, proceeds with no ad. The
///    next preload reruns the update, and the next such tap runs the form
///    again. The consent platform shows the form only while it requires
///    one. A tap during a pending form proceeds with no ad and no second
///    form.
/// 5. A tap while ads are allowed and no ad is cached starts a load and
///    proceeds. A switch first starts a load when none is in flight. It
///    then waits on the load in flight for at most [switchLoadWait]. An ad
///    that lands within the wait shows as rule 6 says. Otherwise the switch
///    proceeds as the tap does. A load still in flight keeps running.
/// 6. A cached ad shows. Its close proceeds and starts no load. The next
///    cached ad comes from the preloads of rule 8. A switch shows the ad
///    only while [inFront] answers true, after any wait of rule 5.
///    Otherwise the switch proceeds with no show, and the ad stays cached.
/// 7. A failed show cancels the connect.
/// 8. Preloads run for free accounts on screen entry, location change,
///    disconnect, and a change from an exempt account to a free one,
///    through [preload]. A preload runs only while the tunnel is down. A
///    preload requested while the tunnel is up or held starts no consent
///    update and no ad load. The tunnel state is read again after the
///    consent update, so an update that lands once the tunnel is up starts
///    no load. The disconnect preload covers the next tap.
/// 9. A preload refreshes the consent information first, with no form. A
///    preload loads an ad only once ads are allowed. An update that does
///    not allow ads, or fails, reruns on the next preload.
/// 10. The gate waits on the network only on a tap while ads are not yet
///     allowed, and on a switch under rule 5. That tap waits on a pending
///     update for at most [pendingUpdateWait], then on the form. The switch
///     waits on the load for at most [switchLoadWait].
/// 11. A show still open when the app resumes ends after [resumeGrace]
///     through [onAppResumed]. The app must stay in front for the whole
///     grace: [onAppHidden] cancels it. A second resume does not restart it.
///     A connect tap inside the grace ends the show at once through
///     [abandonOnTap]. The abandoned show counts as closed without reward.
///     It cancels a tap's connect. A switch proceeds with no further show
///     and no load. A close within the grace proceeds as rule 6. The next
///     tap runs as a fresh tap under rules 5 and 6. So does the abandoning
///     tap, once a cancelled chain ends.
///
/// In a region that needs consent, tap one shows no ad and no form. Tap two
/// shows the consent form and no ad. Tap three shows the first ad. Elsewhere
/// tap one shows no ad and tap two shows the first ad.
///
/// A free account is a settled state that is not a premium-entitled
/// session: signed out, unreadable, or a signed-in session whose
/// `isPremiumEntitled` is false. A switch is a free account's pick of a new
/// location while the connect control reads connected. The connect screen
/// stops the tunnel and commits the pick, then runs its tap chain as a
/// Connect tap. Only the connect screen's tap chain calls [beforeConnect]. A
/// Connect tap, a start-shortcut launch and a switch run it. A Connect tap or
/// a start-shortcut launch inside the grace of rule 11 ends the show through
/// [abandonOnTap]. Every other tunnel start shows no ad.
class OneVpnConnectAdGate {
  OneVpnConnectAdGate({
    required this._gateway,
    this.pendingUpdateWait = const Duration(seconds: 5),
    this.switchLoadWait = const Duration(seconds: 5),
    this.resumeGrace = const Duration(seconds: 3),
    this.inFront = _resumed,
  });

  /// The shared gate over the live AdMob gateway.
  static final OneVpnConnectAdGate instance = OneVpnConnectAdGate(
    gateway: OneVpnAdMobAdGateway(),
  );

  /// The fork once-ever key. It stamps on the first connect tap of a free
  /// account and keeps that tap ad-free.
  static const firstConnectKey = 'onevpn.firstConnectAdSkipped';

  final OneVpnAdGateway _gateway;

  /// The longest a connect tap waits on a consent information update in
  /// flight.
  final Duration pendingUpdateWait;

  /// The longest a switch waits on the ad load in flight.
  final Duration switchLoadWait;

  /// How long a show stays open after the app resumes before the gate
  /// abandons it. A normal close can resume the app before its close
  /// callback lands. The grace lets that callback settle the show.
  final Duration resumeGrace;

  /// Whether the app is in front. A switch reads it right before its show.
  /// The default answers true only while the app lifecycle reads resumed.
  /// Tests inject one.
  final bool Function() inFront;

  /// Whether the app lifecycle reads resumed.
  static bool _resumed() =>
      SchedulerBinding.instance.lifecycleState == AppLifecycleState.resumed;

  /// Whether a show is in flight.
  bool _showing = false;

  /// The pending abandon of the show in flight.
  Timer? _abandon;

  // Opened on first use: the shared gate exists before any preference read.
  late final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  /// Whether ads may be requested in this process.
  bool _allowed = false;

  /// The consent information update in flight, shared by concurrent
  /// preloads.
  Future<bool>? _update;

  /// The consent form run in flight. At most one runs at a time.
  Future<bool>? _form;

  final ValueNotifier<bool> _privacyOptionsRequired = ValueNotifier(false);

  /// Whether the app must offer the privacy options entry. It follows each
  /// consent information update and the consent form.
  ValueListenable<bool> get privacyOptionsRequired => _privacyOptionsRequired;

  /// Whether [account] is exempt from the gate. A restoring state is
  /// exempt: the store has not answered, so the account may be premium.
  static bool exempts(OneVpnAccountState account) => switch (account) {
    OneVpnAccountRestoring() => true,
    OneVpnAccountSignedIn(:final session) => session.isPremiumEntitled,
    OneVpnAccountSignedOut() || OneVpnAccountUnreadable() => false,
  };

  /// Starts a preload from [source] for a free [account] while [tunnelDown]
  /// answers true.
  /// An exempt account starts nothing, and so does a tunnel that is up or
  /// held. Until ads are allowed, it refreshes the consent information first
  /// and shows no form. [tunnelDown] is read again once the update lands,
  /// and the load starts only while it still answers true. Returns at once
  /// and never waits on the load.
  void preload(
    OneVpnAccountState account, {
    required bool Function() tunnelDown,
    required OneVpnAdLoadSource source,
  }) {
    if (!tunnelDown() || exempts(account)) return;
    unawaited(_preload(tunnelDown, source));
  }

  Future<void> _preload(
    bool Function() tunnelDown,
    OneVpnAdLoadSource source,
  ) async {
    if (!_allowed && !await (_update ??= _runUpdate())) return;
    if (!tunnelDown()) return;
    await _gateway.preload(source);
  }

  /// Runs one consent information update and feeds the privacy options
  /// entry. A thrown update counts as not allowed. It clears [_update] at
  /// its end, so the next preload reruns it.
  Future<bool> _runUpdate() async {
    try {
      if (await _gateway.updateConsent()) _allowed = true;
    } catch (_) {
      // Not allowed. The next preload retries.
    }
    await _refreshPrivacyOptions();
    _update = null;
    return _allowed;
  }

  /// Runs the consent form, records its answer, and feeds the privacy
  /// options entry.
  Future<bool> _runForm() async {
    try {
      if (await _gateway.gatherConsent()) _allowed = true;
    } catch (_) {
      // A thrown form does not allow ads. The next tap runs it again.
    }
    await _refreshPrivacyOptions();
    return _allowed;
  }

  /// Reads the privacy options requirement into [privacyOptionsRequired].
  Future<void> _refreshPrivacyOptions() async {
    try {
      _privacyOptionsRequired.value = await _gateway.privacyOptionsRequired();
    } catch (_) {}
  }

  /// Starts the grace for the show in flight. The show is abandoned once
  /// [resumeGrace] passes with the ad still open. A no-op with no show in
  /// flight or with a grace already running, so a second resume does not
  /// restart it. The connect screen calls it each time the app resumes.
  void onAppResumed() {
    if (!_showing || _abandon != null) return;
    ygLogger('OneVpnConnectAdGate: resumed during a show');
    _abandon = Timer(resumeGrace, () {
      _abandon = null;
      ygLogger('OneVpnConnectAdGate: show abandoned after the grace');
      _gateway.abandonShow();
    });
  }

  /// Cancels a running grace. A no-op with none running. The connect screen
  /// calls it each time the app is hidden or paused, since the user may be
  /// back on the ad.
  void onAppHidden() {
    final abandon = _abandon;
    if (abandon == null) return;
    abandon.cancel();
    _abandon = null;
    ygLogger('OneVpnConnectAdGate: grace cancelled in the background');
  }

  /// Abandons the show in flight at once while a grace runs, and answers
  /// whether it did. A connect tap or a start-shortcut launch calls it.
  /// Either one inside the grace reached the connect screen, so the screen is
  /// in front of the ad.
  bool abandonOnTap() {
    final abandon = _abandon;
    if (abandon == null) return false;
    abandon.cancel();
    _abandon = null;
    ygLogger('OneVpnConnectAdGate: show abandoned on a tap');
    _gateway.abandonShow();
    return true;
  }

  /// Shows the consent platform's privacy options form.
  Future<void> showPrivacyOptions() => _gateway.showPrivacyOptions();

  /// Runs the gate for a connect tap by [account]. Resolves true when the
  /// connect proceeds. It waits on a showing ad, on a pending update while
  /// ads are not allowed, and on the consent form. With [switching] it runs
  /// for a switch. With no ad cached, the switch starts a load when none is
  /// in flight, then waits on the load for at most [switchLoadWait]. A
  /// switch while [inFront] answers false resolves true with no show. A
  /// failed show resolves false. An abandoned show resolves false on a tap
  /// and true on a switch. It never throws on a preference store failure.
  Future<bool> beforeConnect(
    OneVpnAccountState account, {
    bool switching = false,
  }) async {
    if (exempts(account)) return true;
    // Must run first after the exemption: the first connect is ad-free.
    if (await _consumeFirstConnect()) return true;
    // The form reads the status of the last update. A pending update must
    // land first, or the form shows against stale consent information.
    final update = _update;
    if (!_allowed && update != null) {
      final landed = await update
          .then((_) => true)
          .timeout(pendingUpdateWait, onTimeout: () => false);
      if (!landed) return true;
    }
    if (!_allowed) {
      if (_form != null) return true;
      // No load follows the form. Its request would leave after the
      // connect, through the tunnel.
      await (_form = _runForm());
      _form = null;
      return true;
    }
    if (switching && !_gateway.isReady) {
      ygLogger('OneVpnConnectAdGate: switch waits on the load');
      await _switchLoad().timeout(switchLoadWait, onTimeout: () {});
      ygLogger(
        'OneVpnConnectAdGate: switch wait ended, '
        '${_gateway.isReady ? 'ad ready' : 'no ad'}',
      );
    }
    if (!_gateway.isReady) {
      // The tap runs before the connect: the tunnel is down.
      unawaited(_preload(() => true, OneVpnAdLoadSource.tap));
      return true;
    }
    // Must run after the wait: an app that leaves the front during it shows
    // no ad. The ad stays cached for the next tap or switch.
    if (switching && !inFront()) {
      ygLogger('OneVpnConnectAdGate: switch not in front, ad kept');
      return true;
    }
    _showing = true;
    try {
      final result = await _gateway.show();
      // A switch stopped a running tunnel. Its abandoned show proceeds to
      // the reconnect with no further ad.
      if (switching && result == OneVpnAdShowResult.abandoned) {
        ygLogger('OneVpnConnectAdGate: switch show abandoned, reconnecting');
        return true;
      }
      return result == OneVpnAdShowResult.closed;
    } finally {
      _showing = false;
      _abandon?.cancel();
      _abandon = null;
    }
  }

  /// Starts a load for the switch when none is in flight, then resolves once
  /// the load in flight ends. A load the stop started is the one awaited.
  Future<void> _switchLoad() async {
    // The switch runs after the stop: the tunnel is down.
    await _preload(() => true, OneVpnAdLoadSource.switching);
    await _gateway.loadSettled();
  }

  /// Whether this tap is the first connect, stamping [firstConnectKey] when
  /// it is. A key that reads stamped resolves false. A key that reads
  /// unstamped, or a read that throws, resolves true. The stamp is best
  /// effort.
  Future<bool> _consumeFirstConnect() async {
    try {
      if (await _preferences.getBool(firstConnectKey) ?? false) return false;
    } catch (_) {
      // Reads as the first connect.
    }
    try {
      await _preferences.setBool(firstConnectKey, true);
    } catch (_) {
      // The next tap reads the key again.
    }
    return true;
  }
}
