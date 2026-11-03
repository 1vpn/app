// Localized place names: catalogue country codes resolve through their ISO
// alias, city names resolve by display code, and every miss falls back to
// the API's own string. A miss falls back the same way in a locale whose
// table wraps the code in direction marks.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/catalogue/location.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations_ar.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations_de.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations_en.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations_ja.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations_ur.dart';
import 'package:onexray/onevpn/location/place_names.dart';

/// The case codes of the `onevpnCityName` select in [path].
List<String> _cityCases(String path) {
  final arb = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  final message = arb['onevpnCityName'] as String;
  return [
    for (final match in RegExp(
      r'(?:, select, |\} )([a-z]+) \{',
    ).allMatches(message))
      if (match.group(1) != 'other') match.group(1)!,
  ];
}

String _city(OneVpnLocalizations l, OneVpnLocation location) =>
    OneVpnPlaceNames.city(
      l,
      displayCode: location.displayCode,
      countryCode: location.countryCode,
      city: location.city,
    );

OneVpnLocation _location({
  required String code,
  required String city,
  required String country,
  required String countryCode,
}) => OneVpnLocation(
  code: code,
  city: city,
  country: country,
  countryCode: countryCode,
  servers: const [],
);

void main() {
  final en = OneVpnLocalizationsEn();
  final ja = OneVpnLocalizationsJa();
  final de = OneVpnLocalizationsDe();
  final ar = OneVpnLocalizationsAr();
  final ur = OneVpnLocalizationsUr();

  group('the country name', () {
    test('maps the catalogue aliases to their ISO code', () {
      expect(OneVpnPlaceNames.isoCode('uk'), 'GB');
      expect(OneVpnPlaceNames.isoCode('use'), 'US');
      expect(OneVpnPlaceNames.isoCode('USS'), 'US');
      expect(OneVpnPlaceNames.isoCode('usw'), 'US');
      expect(OneVpnPlaceNames.isoCode('ch'), 'CH');
      // Anti-vacuity: an alias reads the aliased name, not the raw code.
      expect(
        OneVpnPlaceNames.country(de, countryCode: 'uk', country: 'UK'),
        'Vereinigtes Königreich',
      );
      expect(
        OneVpnPlaceNames.country(ja, countryCode: 'use', country: 'US East'),
        'アメリカ合衆国',
      );
    });

    test('a known code takes the locale name in two locales', () {
      expect(
        OneVpnPlaceNames.country(ja, countryCode: 'ch', country: 'Switzerland'),
        'スイス',
      );
      expect(
        OneVpnPlaceNames.country(de, countryCode: 'ch', country: 'Switzerland'),
        'Schweiz',
      );
    });

    test('an unknown code falls back to the API name in four locales', () {
      for (final l in [ja, de, ar, ur]) {
        expect(
          OneVpnPlaceNames.country(l, countryCode: 'zz', country: 'Atlantis'),
          'Atlantis',
          reason: l.localeName,
        );
      }
    });

    test('a catalogue code the table lacks reads the API name under ar and '
        'ur', () {
      for (final l in [ar, ur]) {
        // Anti-vacuity: the table wraps the bare code in direction marks.
        final raw = l.onevpnCountryRegionName('USC');
        expect(raw, isNot('USC'), reason: l.localeName);
        expect(raw, contains('USC'), reason: l.localeName);
        expect(
          OneVpnPlaceNames.country(
            l,
            countryCode: 'usc',
            country: 'United States',
          ),
          'United States',
          reason: l.localeName,
        );
      }
    });

    test('CN reads China', () {
      expect(
        OneVpnPlaceNames.country(en, countryCode: 'cn', country: 'PRC'),
        en.onevpnRegionChina,
      );
    });
  });

  group('the city name', () {
    final tokyo = _location(
      code: 'nrt',
      city: 'Tokyo',
      country: 'Japan',
      countryCode: 'jp',
    );
    final zurich = _location(
      code: 'zrh',
      city: 'Zurich',
      country: 'Switzerland',
      countryCode: 'ch',
    );

    test('a v2 city takes the seeded name in three locales', () {
      expect(_city(ja, tokyo), '東京');
      expect(_city(de, tokyo), 'Tokio');
      expect(_city(ar, tokyo), 'طوكيو');
    });

    test('a new city takes its name in three locales', () {
      expect(_city(ja, zurich), 'チューリッヒ');
      expect(_city(de, zurich), 'Zürich');
      expect(_city(ar, zurich), 'زيورخ');
    });

    test('an unseeded city falls back to the API name', () {
      final unseen = _location(
        code: 'xyz',
        city: 'Atlantis City',
        country: 'Atlantis',
        countryCode: 'zz',
      );
      expect(_city(ja, unseen), 'Atlantis City');
      expect(_city(de, unseen), 'Atlantis City');
      // The Arabic fallback isolates the Latin name.
      expect(_city(ar, unseen), contains('Atlantis City'));
    });

    test('a city with no city code keeps the API name', () {
      // Osaka under jp: displayCode is null and the country is never shown.
      final osaka = _location(
        code: 'jp',
        city: 'Osaka',
        country: 'Japan',
        countryCode: 'jp',
      );
      expect(osaka.displayCode, isNull);
      expect(_city(ja, osaka), 'Osaka');
    });

    test('a country-named location takes the country name', () {
      final hongKong = _location(
        code: 'hk',
        city: 'Hong Kong',
        country: 'Hong Kong',
        countryCode: 'hk',
      );
      expect(hongKong.displayCode, 'hk');
      expect(_city(de, hongKong), 'Hongkong');
    });

    test('a country-named location the table lacks reads the API name '
        'under ar and ur', () {
      final usc = _location(
        code: 'usc',
        city: 'United States',
        country: 'United States',
        countryCode: 'usc',
      );
      expect(usc.displayCode, 'usc');
      for (final l in [ar, ur]) {
        expect(_city(l, usc), 'United States', reason: l.localeName);
      }
    });

    test('a disambiguated code falls back to the API name', () {
      final second = _location(
        code: 'jp-2',
        city: 'Sapporo',
        country: 'Japan',
        countryCode: 'jp',
      );
      expect(_city(ja, second), 'Sapporo');
    });

    test('every locale carries the same city cases as the template', () {
      final template = _cityCases('lib/onevpn/l10n/onevpn_en.arb');
      // 32 v2 cities and 35 new cities.
      expect(template, hasLength(67));
      expect(template.toSet(), hasLength(67));
      final files = Directory('lib/onevpn/l10n')
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.arb'))
          .toList();
      expect(files.length, greaterThanOrEqualTo(19));
      for (final file in files) {
        expect(_cityCases(file.path), template, reason: file.path);
      }
    });
  });
}
