// The live ads gateway over Google's Mobile Ads SDK and its User Messaging
// Platform. This is the only file that imports google_mobile_ads.
//
// Four inputs, supplied at build time.
//
//   flutter build apk -t lib/main_1vpn.dart \
//     --dart-define=ONEVPN_ADMOB_INTERSTITIAL_ANDROID=... \
//     --dart-define=ONEVPN_UMP_DEBUG_GEOGRAPHY=eea \
//     --dart-define=ONEVPN_UMP_TEST_DEVICE=... \
//     --dart-define=ONEVPN_ADS_TEST_DEVICE=...
//
// An empty or absent interstitial id takes Google's published test unit. The
// two consent defines and the ads test device are empty by default and serve
// demo builds only. The AdMob app id reaches the merged manifest through
// tool/admob.gradle, not through Dart.

import 'dart:async';
import 'dart:io';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:onexray/core/tools/logger.dart';
import 'package:onexray/onevpn/ads/ad_gateway.dart';

/// Google's published test interstitial unit for Android.
const kOneVpnAdMobTestInterstitialAndroid =
    'ca-app-pub-3940256099942544/1033173712';

const _interstitialDefine = String.fromEnvironment(
  'ONEVPN_ADMOB_INTERSTITIAL_ANDROID',
);

/// The interstitial unit this build requests. An empty define resolves to
/// [kOneVpnAdMobTestInterstitialAndroid].
const kOneVpnAdMobInterstitialAndroid = _interstitialDefine == ''
    ? kOneVpnAdMobTestInterstitialAndroid
    : _interstitialDefine;

const _umpDebugGeographyDefine = String.fromEnvironment(
  'ONEVPN_UMP_DEBUG_GEOGRAPHY',
);

const _umpTestDeviceDefine = String.fromEnvironment('ONEVPN_UMP_TEST_DEVICE');

const _adsTestDeviceDefine = String.fromEnvironment('ONEVPN_ADS_TEST_DEVICE');

/// The ads request configuration for this build, or null for none.
///
/// A non-empty [testDevice] is the hashed device id the Mobile Ads SDK logs.
/// It becomes the one test device id, so that device receives test
/// creatives. An empty [testDevice] yields null. The default reads the build
/// define.
RequestConfiguration? oneVpnAdsRequestConfiguration({
  String testDevice = _adsTestDeviceDefine,
}) {
  if (testDevice.isEmpty) return null;
  return RequestConfiguration(testDeviceIds: [testDevice]);
}

/// The consent request parameters for this build.
///
/// A [geography] of `eea` or `other` forces that debug geography. Any other
/// value, empty included, yields parameters with no debug settings. A
/// non-empty [testDevice] is the hashed device id the consent platform logs.
/// It becomes the one test identifier. The platform honours a debug geography
/// only on a listed test device. The defaults read the build defines.
ConsentRequestParameters oneVpnConsentRequestParameters({
  String geography = _umpDebugGeographyDefine,
  String testDevice = _umpTestDeviceDefine,
}) {
  final debugGeography = switch (geography) {
    'eea' => DebugGeography.debugGeographyEea,
    'other' => DebugGeography.debugGeographyOther,
    _ => null,
  };
  if (debugGeography == null) return ConsentRequestParameters();
  return ConsentRequestParameters(
    consentDebugSettings: ConsentDebugSettings(
      debugGeography: debugGeography,
      testIdentifiers: testDevice.isEmpty ? null : [testDevice],
    ),
  );
}

/// Resolves [load] within [limit], or fails with a [TimeoutException].
///
/// A value that arrives after the limit goes to [onLate]. An error that
/// arrives after the limit is dropped.
Future<T> oneVpnBoundedLoad<T>(
  Future<T> load,
  Duration limit, {
  required void Function(T value) onLate,
}) {
  var expired = false;
  return load
      .then((value) {
        if (expired) onLate(value);
        return value;
      })
      .timeout(
        limit,
        onTimeout: () {
          expired = true;
          throw TimeoutException('the load exceeded its bound', limit);
        },
      );
}

/// The [OneVpnAdGateway] over AdMob.
///
/// A gateway that is not live answers false, not ready, or failed on each
/// call, and never touches the SDK. The SDK starts inside [updateConsent] or
/// [gatherConsent], only once the consent platform allows ad requests.
class OneVpnAdMobAdGateway implements OneVpnAdGateway {
  /// [live] says whether the gateway reaches the SDK. Null reads the host
  /// operating system, so the gateway is live on Android only. The SDK links
  /// into the iOS build too, and its app id comes from Info.plist. The
  /// gateway stays inert there.
  OneVpnAdMobAdGateway({
    this.adUnitId = kOneVpnAdMobInterstitialAndroid,
    bool? live,
  }) : _live = live ?? Platform.isAndroid;

  /// The interstitial unit requested on each load.
  final String adUnitId;

  /// Whether the gateway reaches the SDK.
  final bool _live;

  bool _started = false;

  /// The load in flight. It completes when the load ends.
  Completer<void>? _load;
  InterstitialAd? _ad;

  /// Ends the show in flight as abandoned, or null with no show in flight.
  void Function()? _abandon;

  @override
  Future<bool> updateConsent() async {
    if (!_live) return false;
    try {
      final updated = Completer<void>();
      // A failed update leaves the previous session's consent status in force.
      ConsentInformation.instance.requestConsentInfoUpdate(
        oneVpnConsentRequestParameters(),
        updated.complete,
        (_) => updated.complete(),
      );
      await updated.future;
      return await _startIfAllowed();
    } catch (_) {
      return false;
    }
  }

  /// The bound on loading the consent form. Showing it has no bound.
  static const formLoadTimeout = Duration(seconds: 20);

  /// Shows the consent form only while the consent status is required.
  ///
  /// The form load is bounded by [formLoadTimeout]. A load that fails or
  /// times out resolves false. The shown form waits for the user.
  @override
  Future<bool> gatherConsent() async {
    if (!_live) return false;
    try {
      if (await ConsentInformation.instance.getConsentStatus() ==
          ConsentStatus.required) {
        final form = await oneVpnBoundedLoad(
          _loadConsentForm(),
          formLoadTimeout,
          onLate: (form) => unawaited(form.dispose()),
        );
        try {
          final dismissed = Completer<void>();
          form.show((_) {
            if (!dismissed.isCompleted) dismissed.complete();
          });
          await dismissed.future;
        } finally {
          unawaited(form.dispose());
        }
      }
      return await _startIfAllowed();
    } catch (_) {
      return false;
    }
  }

  /// Loads the consent form. Fails with the platform's [FormError].
  static Future<ConsentForm> _loadConsentForm() {
    final loaded = Completer<ConsentForm>();
    ConsentForm.loadConsentForm(loaded.complete, loaded.completeError);
    return loaded.future;
  }

  /// The SDK start, shared by every pass that overlaps it. A start that
  /// throws clears it, so the next pass starts again.
  Future<void>? _start;

  /// Starts the SDK once the consent platform allows ad requests. Resolves
  /// whether it allows them. A pass during a start waits for that start and
  /// shares its outcome. A start that throws leaves the SDK unstarted.
  Future<bool> _startIfAllowed() async {
    if (!await ConsentInformation.instance.canRequestAds()) return false;
    final start = _start ??= _startSdk();
    try {
      await start;
    } catch (_) {
      if (identical(_start, start)) _start = null;
      rethrow;
    }
    _started = true;
    return true;
  }

  /// Applies this build's request configuration, then initializes the SDK.
  static Future<void> _startSdk() async {
    // Must precede initialize: the first ad request reads the test ids.
    final configuration = oneVpnAdsRequestConfiguration();
    if (configuration != null) {
      await MobileAds.instance.updateRequestConfiguration(configuration);
    }
    await MobileAds.instance.initialize();
  }

  @override
  Future<bool> privacyOptionsRequired() async {
    if (!_live) return false;
    try {
      return await ConsentInformation.instance
              .getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> showPrivacyOptions() async {
    if (!_live) return;
    try {
      final closed = Completer<void>();
      await ConsentForm.showPrivacyOptionsForm((_) => closed.complete());
      await closed.future;
    } catch (_) {}
  }

  @override
  Future<void> preload(OneVpnAdLoadSource source) async {
    if (!_live || !_started || _ad != null || _load != null) return;
    final load = _load = Completer<void>();
    // Ends the load once. Must run after a loaded ad is cached: a waiter
    // reads isReady once the load ends.
    void end() {
      if (identical(_load, load)) _load = null;
      if (!load.isCompleted) load.complete();
    }

    ygLogger('OneVpnAdMobAdGateway: load requested, ${source.name}');
    try {
      await InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _ad = ad;
            end();
            ygLogger('OneVpnAdMobAdGateway: load loaded');
          },
          onAdFailedToLoad: (error) {
            end();
            ygLogger('OneVpnAdMobAdGateway: load failed, code ${error.code}');
          },
        ),
      );
    } catch (_) {
      end();
      ygLogger('OneVpnAdMobAdGateway: load failed, thrown');
    }
  }

  @override
  Future<void> loadSettled() => _load?.future ?? Future<void>.value();

  @override
  bool get isReady => _ad != null;

  @override
  Future<OneVpnAdShowResult> show() async {
    final ad = _ad;
    _ad = null;
    if (ad == null) return OneVpnAdShowResult.failed;
    final ended = Completer<OneVpnAdShowResult>();
    // Settles the show once. A callback after an abandon finds it settled.
    void end(OneVpnAdShowResult result) {
      if (ended.isCompleted) return;
      _abandon = null;
      ygLogger('OneVpnAdMobAdGateway: show ${result.name}');
      unawaited(ad.dispose());
      ended.complete(result);
    }

    _abandon = () => end(OneVpnAdShowResult.abandoned);
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (_) => end(OneVpnAdShowResult.closed),
      onAdFailedToShowFullScreenContent: (_, _) =>
          end(OneVpnAdShowResult.failed),
    );
    try {
      await ad.show();
    } catch (_) {
      end(OneVpnAdShowResult.failed);
    }
    return ended.future;
  }

  /// Ends the show in flight as abandoned.
  ///
  /// Disposing the ad releases only the plugin's handle. The SDK's ad
  /// activity stays in its own task until the user closes it. That close
  /// reaches no callback, because the disposed ad is no longer registered.
  @override
  void abandonShow() => _abandon?.call();
}
