// The location picker's view state, derived from the catalogue value, the
// provisioned rows, and the committed selection.
//
// Pure state. It builds no widget and reads no singleton, so it pins under a
// plain unit test. The catalogue and the provisioner sit below the waterline.
// This model consumes them and never reimplements them.

import 'package:onexray/core/db/database/database.dart';
import 'package:onexray/onevpn/catalogue/catalogue.dart';
import 'package:onexray/onevpn/catalogue/node_catalog.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations.dart';
import 'package:onexray/onevpn/location/place_names.dart';
import 'package:onexray/service/connect/settings.dart';

/// How long a premium picker waits for a premium node before it lists the
/// free nodes. The window starts when the picker opens, or when the account
/// first turns premium while the picker is open. The value is tunable.
const Duration kOneVpnPremiumFailoverWindow = Duration(seconds: 8);

/// One dialable location on the picker.
class OneVpnLocationChoice {
  const OneVpnLocationChoice({
    required this.stem,
    required this.city,
    required this.country,
    required this.countryCode,
    required this.freeTier,
    required this.selected,
    required this.available,
    this.displayCode,
  });

  /// The row-name stem a selection of this location scopes to. It is what a
  /// tap writes into [ServerSelection.location].
  final String stem;

  final String city;
  final String country;
  final String countryCode;

  /// The code [city] is translated by. See [OneVpnLocation.displayCode].
  final String? displayCode;

  /// True when the location came from the compiled-in free list. The row
  /// then carries the free badge.
  final bool freeTier;

  /// The committed selection points at this location.
  final bool selected;

  /// At least one of this location's nodes is provisioned. False is the
  /// zero-valid-node state. The condition is server-side, and no user retry
  /// clears it. The picker still lists and selects the location, and its
  /// connect fails with an error. A free location is always true, because
  /// the free nodes are compiled in.
  final bool available;
}

/// One premium teaser on the picker. A tap routes to the paywall, never to a
/// tunnel.
class OneVpnLocationTeaser {
  const OneVpnLocationTeaser({
    required this.city,
    required this.country,
    required this.countryCode,
    this.displayCode,
  });

  final String city;
  final String country;
  final String countryCode;

  /// The code [city] is translated by. See [OneVpnLocation.displayCode].
  final String? displayCode;
}

/// The picker's rows and the degraded flags the states render from.
class OneVpnLocationPickerModel {
  const OneVpnLocationPickerModel({
    required this.automaticSelected,
    required this.locations,
    required this.teasers,
    required this.degraded,
    this.freeHidden = false,
  });

  /// The pinned Automatic row is selected.
  final bool automaticSelected;

  /// The connectable locations, in catalogue order. The list includes
  /// zero-valid-node locations, flagged unavailable.
  final List<OneVpnLocationChoice> locations;

  /// The premium teasers, minus any teaser that duplicates a connectable
  /// location, such as Singapore.
  final List<OneVpnLocationTeaser> teasers;

  /// A premium account shown the free nodes because its own list did not load.
  /// Drives the load-failed caption and the retry affordance.
  final bool degraded;

  /// A premium account's free nodes are left out of [locations].
  final bool freeHidden;

  /// Nothing can be shown: no location and no teaser. This is the terminal
  /// contact-support state. Only a failed validation of the embedded floor
  /// reaches it.
  bool get empty => locations.isEmpty && teasers.isEmpty;

  /// Builds the model for one session's [catalogue] against the provisioned
  /// [servers] and the committed [selection].
  ///
  /// A free location is always available. Any other location is available
  /// when a provisioned row carries its stem. The
  /// pairing runs the provisioner's own code disambiguation, so a stem here is
  /// the stem the provisioner wrote.
  ///
  /// A premium catalogue lists only its own locations while one of them is
  /// available. With none available, the free nodes appear once
  /// [failoverElapsed] is true. [freeListed] lists them regardless. A free
  /// location that is selected or whose stem is in [kept] always appears. A
  /// degraded catalogue holds only free nodes and lists them all.
  factory OneVpnLocationPickerModel.from({
    required OneVpnCatalogue catalogue,
    required List<CoreConfigData> servers,
    required ServerSelection selection,
    bool failoverElapsed = false,
    bool freeListed = false,
    Set<String> kept = const {},
  }) {
    final pairs = oneVpnCatalogueDomainPairs(catalogue.entries);
    final dialableCodes = <String>{
      for (final pair in pairs)
        if (pair.entry.location.isConnectable)
          '${pair.entry.location.countryCode}/${pair.entry.location.cityCode}',
    };

    final locations = <OneVpnLocationChoice>[];
    final teasers = <OneVpnLocationTeaser>[];
    for (final pair in pairs) {
      final api = pair.entry.location;
      final domain = pair.location;
      if (api.isConnectable) {
        final stem = domain.rowNameStem;
        locations.add(
          OneVpnLocationChoice(
            stem: stem,
            city: domain.city,
            country: domain.country,
            countryCode: domain.countryCode,
            displayCode: domain.displayCode,
            freeTier: pair.entry.freeTier,
            selected:
                selection.kind == SelectionKind.location &&
                selection.location == stem,
            available:
                pair.entry.freeTier ||
                servers.any((row) => row.name.startsWith('$stem·')),
          ),
        );
        continue;
      }
      // Drop a teaser that duplicates a connectable location. The paywall
      // never sells a location the user can already dial.
      if (dialableCodes.contains('${api.countryCode}/${api.cityCode}')) {
        continue;
      }
      teasers.add(
        OneVpnLocationTeaser(
          city: domain.city,
          country: domain.country,
          countryCode: domain.countryCode,
          displayCode: domain.displayCode,
        ),
      );
    }

    final premiumAvailable = locations.any(
      (location) => !location.freeTier && location.available,
    );
    final freeHidden =
        catalogue.tier == OneVpnTier.premium &&
        !catalogue.isDegraded &&
        !freeListed &&
        (premiumAvailable || !failoverElapsed);
    if (freeHidden) {
      locations.removeWhere(
        (location) =>
            location.freeTier &&
            !location.selected &&
            !kept.contains(location.stem),
      );
    }

    return OneVpnLocationPickerModel(
      automaticSelected: selection.kind == SelectionKind.automatic,
      freeHidden: freeHidden,
      locations: List.unmodifiable(locations),
      teasers: List.unmodifiable(teasers),
      degraded: catalogue.isDegraded,
    );
  }
}

/// Maps provisioned nodes back to their location, for the connect screen.
///
/// The connect screen names a location selection and the node Automatic
/// resolved to. Both need the provisioned stem to resolve to a city, which
/// lives in the catalogue. Names are localized through [OneVpnPlaceNames].
abstract final class OneVpnLocationNaming {
  /// Stem to localized city, for every location in [catalogue].
  static Map<String, String> citiesByStem(
    OneVpnCatalogue catalogue,
    OneVpnLocalizations l,
  ) => {
    for (final pair in oneVpnCatalogueDomainPairs(catalogue.entries))
      pair.location.rowNameStem: OneVpnPlaceNames.city(
        l,
        displayCode: pair.location.displayCode,
        countryCode: pair.location.countryCode,
        city: pair.location.city,
      ),
  };

  /// Stem to localized country, for every location in [catalogue].
  static Map<String, String> countriesByStem(
    OneVpnCatalogue catalogue,
    OneVpnLocalizations l,
  ) => {
    for (final pair in oneVpnCatalogueDomainPairs(catalogue.entries))
      pair.location.rowNameStem: OneVpnPlaceNames.country(
        l,
        countryCode: pair.location.countryCode,
        country: pair.location.country,
      ),
  };

  /// The stems of the free-tier locations in [catalogue].
  static Set<String> freeStems(OneVpnCatalogue catalogue) => {
    for (final pair in oneVpnCatalogueDomainPairs(catalogue.entries))
      if (pair.entry.freeTier) pair.location.rowNameStem,
  };

  /// Stem to country code, for every location in [catalogue].
  static Map<String, String> countryCodesByStem(OneVpnCatalogue catalogue) => {
    for (final pair in oneVpnCatalogueDomainPairs(catalogue.entries))
      pair.location.rowNameStem: pair.location.countryCode,
  };

  /// The stem of a provisioned row name, or null when the name is not a
  /// provisioned node. A row is named `<stem>·<index>`.
  static String? stemOfRowName(String name) {
    final cut = name.lastIndexOf('·');
    return cut <= 0 ? null : name.substring(0, cut);
  }
}
