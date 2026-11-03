import 'dart:async';

import 'package:onexray/onevpn/ads/ad_gateway.dart';

/// A scripted [OneVpnAdGateway] that records every call in [calls].
///
/// [allowAds] answers the consent information update. [formAllows] answers
/// the consent form run. An allowing form sets [allowAds], as the consent
/// platform keeps the status for the next update. A set [updateError] or
/// [formError] makes the next update or form throw it, once. A non-null
/// [formPrivacyRequired] becomes [privacyRequired] when the form ends.
/// [loads] answers each preload: true caches an ad, false leaves none.
/// [showResult] answers each show. A held [updateGate], [formGate] or
/// [showGate] keeps that call open until the test completes it. A held
/// [loadGate] keeps each load open the same way. A preload during a held
/// load starts no second load, and [loadSettled] resolves once the held
/// load ends. While
/// [abandonEndsShow] is true, [abandonShow] ends a held show as abandoned.
/// A show settles once: completing its gate after the abandon changes
/// nothing.
class FakeAdGateway implements OneVpnAdGateway {
  FakeAdGateway({
    this.allowAds = true,
    this.formAllows = true,
    this.loads = true,
    this.ready = false,
    this.showResult = OneVpnAdShowResult.closed,
    this.privacyRequired = false,
    List<String>? log,
  }) : calls = log ?? <String>[];

  bool allowAds;
  bool formAllows;
  Object? updateError;
  Object? formError;
  bool? formPrivacyRequired;
  bool loads;
  bool ready;
  OneVpnAdShowResult showResult;
  bool privacyRequired;

  /// Holds an update open while set. The update resolves once it completes.
  Completer<void>? updateGate;

  /// Holds a form open while set. The form resolves once it completes.
  Completer<void>? formGate;

  /// Holds a show open while set. The show resolves once it completes.
  Completer<void>? showGate;

  /// Holds each load open while set. The load caches as [loads] says once
  /// it completes.
  Completer<void>? loadGate;

  /// The held load in flight, or null.
  Future<void>? _load;

  /// Whether [abandonShow] ends the show in flight. False leaves the show
  /// held until its gate completes.
  bool abandonEndsShow = true;

  /// The show in flight, or null.
  Completer<OneVpnAdShowResult>? _showing;

  /// How many shows settled, counted once each.
  int showsSettled = 0;

  /// Every call in order: update, form, privacy, privacyForm, preload, wait,
  /// show, abandon.
  final List<String> calls;

  int count(String call) => calls.where((c) => c == call).length;

  @override
  Future<bool> updateConsent() async {
    calls.add('update');
    await updateGate?.future;
    final error = updateError;
    updateError = null;
    if (error != null) throw error;
    return allowAds;
  }

  @override
  Future<bool> gatherConsent() async {
    calls.add('form');
    await formGate?.future;
    privacyRequired = formPrivacyRequired ?? privacyRequired;
    final error = formError;
    formError = null;
    if (error != null) throw error;
    if (formAllows) allowAds = true;
    return formAllows;
  }

  @override
  Future<bool> privacyOptionsRequired() async {
    calls.add('privacy');
    return privacyRequired;
  }

  @override
  Future<void> showPrivacyOptions() async => calls.add('privacyForm');

  /// The source of each preload, in order.
  final List<OneVpnAdLoadSource> sources = [];

  @override
  Future<void> preload(OneVpnAdLoadSource source) async {
    calls.add('preload');
    sources.add(source);
    if (_load != null) return;
    final gate = loadGate;
    if (gate == null) {
      if (loads) ready = true;
      return;
    }
    _load = gate.future.then((_) {
      if (loads) ready = true;
      _load = null;
    });
  }

  @override
  Future<void> loadSettled() {
    calls.add('wait');
    return _load ?? Future<void>.value();
  }

  @override
  bool get isReady => ready;

  @override
  Future<OneVpnAdShowResult> show() {
    calls.add('show');
    ready = false;
    final showing = _showing = Completer<OneVpnAdShowResult>();
    final gate = showGate;
    if (gate == null) {
      _settle(showing, showResult);
    } else {
      unawaited(gate.future.then((_) => _settle(showing, showResult)));
    }
    return showing.future;
  }

  @override
  void abandonShow() {
    calls.add('abandon');
    final showing = _showing;
    if (showing != null && abandonEndsShow) {
      _settle(showing, OneVpnAdShowResult.abandoned);
    }
  }

  /// Settles [showing] with [result] unless it has settled already.
  void _settle(
    Completer<OneVpnAdShowResult> showing,
    OneVpnAdShowResult result,
  ) {
    if (showing.isCompleted) return;
    if (identical(_showing, showing)) _showing = null;
    showsSettled++;
    showing.complete(result);
  }
}
