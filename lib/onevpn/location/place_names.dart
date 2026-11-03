// Localized country and city names for catalogue locations.

import 'package:onexray/onevpn/l10n/generated/onevpn_localizations.dart';

/// Names a catalogue location in the active locale.
///
/// Each name falls back to the string the API sent when the locale has no
/// entry for the code. A location the app has never seen therefore shows its
/// English names.
abstract final class OneVpnPlaceNames {
  /// Catalogue country codes that differ from their ISO 3166 code, mapped to
  /// that ISO code. The US catalogue splits into east, south, and west.
  static const isoAliases = {'uk': 'GB', 'use': 'US', 'uss': 'US', 'usw': 'US'};

  /// The direction marks a table value can carry: LRM, RLM, and the
  /// isolates LRI, RLI, FSI and PDI.
  static final _directionMarks = RegExp('[\u200E\u200F\u2066-\u2069]');

  /// The upper-case ISO 3166 code for the catalogue [countryCode], in any
  /// letter case.
  static String isoCode(String countryCode) {
    final lower = countryCode.toLowerCase();
    return isoAliases[lower] ?? lower.toUpperCase();
  }

  /// The localized name of the catalogue [countryCode], or [country] when the
  /// country-name table has no entry for it. CN renders "China".
  ///
  /// A miss is a table value that equals the code once its direction marks
  /// are stripped. A hit returns the table value unchanged, marks included.
  static String country(
    OneVpnLocalizations l, {
    required String countryCode,
    required String country,
  }) {
    final iso = isoCode(countryCode);
    if (iso == 'CN') return l.onevpnRegionChina;
    // The table returns the code itself for a code it lacks. Some locales
    // wrap that code in direction marks.
    final name = l.onevpnCountryRegionName(iso);
    return name.replaceAll(_directionMarks, '') == iso ? country : name;
  }

  /// The localized city name for a location, or [city] when the city-name
  /// table has no entry.
  ///
  /// [displayCode] is the location's `displayCode`. Null shows [city]. A code
  /// equal to [countryCode] names the country itself and takes the country
  /// name. Any other code is looked up in lower case.
  static String city(
    OneVpnLocalizations l, {
    required String? displayCode,
    required String countryCode,
    required String city,
  }) {
    if (displayCode == null) return city;
    final code = displayCode.toLowerCase();
    if (code == countryCode.toLowerCase()) {
      return country(l, countryCode: countryCode, country: city);
    }
    return l.onevpnCityName(code, city);
  }
}
