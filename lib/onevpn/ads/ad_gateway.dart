// The fork-owned ads seam.
//
// The connect gate, the Support page, and every test speak only these fork
// types. Exactly one file imports google_mobile_ads: the live gateway in
// admob_ad_gateway.dart. Tests inject a fake gateway.
//
// Nothing here throws to report an outcome. A gateway answers false, not
// ready, or failed where the SDK errs or is absent.

/// How showing a cached interstitial ended.
enum OneVpnAdShowResult {
  /// The ad showed and the user closed it.
  closed,

  /// The ad did not show.
  failed,

  /// The app ended the wait while the ad still showed in its own task. It
  /// counts as closed without reward.
  abandoned,
}

/// The path that requested an interstitial load.
enum OneVpnAdLoadSource {
  /// The connect screen's entry.
  entry,

  /// A location change.
  location,

  /// A disconnect.
  disconnect,

  /// A change from an exempt account to a free one.
  account,

  /// A connect tap with no ad cached.
  tap,

  /// A location switch with no ad cached.
  switching,
}

/// The interstitial ads source the connect gate drives.
abstract interface class OneVpnAdGateway {
  /// Refreshes the consent information and resolves whether ads may be
  /// requested now.
  ///
  /// It shows no form. It starts the ads SDK once ads may be requested. It
  /// resolves false when ads may not be requested or the SDK is absent.
  Future<bool> updateConsent();

  /// Shows the consent form where the consent platform requires one, and
  /// resolves whether ads may be requested after it.
  ///
  /// It is the one call that shows consent UI. It reads the status that the
  /// last [updateConsent] fetched. It starts the ads SDK once ads may be
  /// requested. It resolves false when ads may not be requested or the SDK
  /// is absent.
  Future<bool> gatherConsent();

  /// Whether the consent platform requires an in-app entry to the privacy
  /// options form. Meaningful once [updateConsent] has resolved.
  Future<bool> privacyOptionsRequired();

  /// Shows the privacy options form. Resolves when the form closes or fails.
  Future<void> showPrivacyOptions();

  /// Starts loading an interstitial for [source]. A no-op while one is
  /// cached or loading. Resolves once the load has started, never on its
  /// completion.
  Future<void> preload(OneVpnAdLoadSource source);

  /// Resolves once the load in flight ends, loaded or failed. Resolves at
  /// once with no load in flight.
  Future<void> loadSettled();

  /// Whether an interstitial is cached and ready to show.
  bool get isReady;

  /// Shows the cached interstitial. Resolves when the user closes it, or as
  /// failed when it cannot show. A cached ad shows at most once.
  Future<OneVpnAdShowResult> show();

  /// Ends the show in flight as [OneVpnAdShowResult.abandoned] and releases
  /// the ad. A no-op with no show in flight. A close that lands afterwards
  /// leaves the result unchanged.
  void abandonShow();
}
