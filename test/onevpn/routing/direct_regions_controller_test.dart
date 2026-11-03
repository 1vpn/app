// Pins the Direct-regions picker's row set, its fork pin order, and
// single-select. The rows are exactly the geosite-overlay codes that
// installed geodata carries. The controller derives them through the
// catalogue's public domainRules filter and orders them CN, RU, IR, TM. The
// ~250-code geoip union is never a row. Selecting a region caps to one code.
// Null selects All via VPN.

import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/routing/direct_regions_controller.dart';
import 'package:onexray/service/connect/routing/region_catalog.dart';

// A geoip census far wider than the four curated overlays. A rendered row
// set equal to the union fails the test.
const _geoipCountries = [
  'CN',
  'IR',
  'RU',
  'TM',
  'US',
  'DE',
  'FR',
  'JP',
  'GB',
  'BR',
];

RegionCatalog _catalog() => RegionCatalog.fromJson(
  {
    'geosite': {
      'CN': ['CN'],
      'IR': ['CATEGORY-IR'],
      'RU': ['CATEGORY-RU'],
      'TM': ['TM'],
    },
    'geoip': {
      for (final code in _geoipCountries) code: [code],
    },
  },
  geositeCodes: const ['CN', 'CATEGORY-IR', 'CATEGORY-RU', 'TM'],
  geoipCodes: _geoipCountries,
);

void main() {
  test('rows are the four geosite-overlay codes in the fork pin order', () {
    final catalog = _catalog();

    // Anti-vacuity guard. The catalogue carries the wide union.
    expect(catalog.regionCodes.length, _geoipCountries.length);

    final rows = OneVpnDirectRegionsController.curatedCodes(catalog);
    // The pin order is CN, RU, IR, TM, not the sorted union CN, IR, RU, TM.
    expect(rows, ['CN', 'RU', 'IR', 'TM']);
    expect(rows, isNot(equals(catalog.regionCodes)));
    // A geoip-only country carries no overlay and is never a row.
    expect(rows, isNot(contains('US')));
  });

  test(
    'load derives the four in pin order and drops a stale selection',
    () async {
      final controller = OneVpnDirectRegionsController(
        selected: 'US',
        loadCatalog: () async => _catalog(),
      );
      await controller.load();
      expect(controller.busy, isFalse);
      expect(controller.failed, isFalse);
      expect(controller.codes, ['CN', 'RU', 'IR', 'TM']);
      // 'US' is no row, so a stale selection falls back to All via VPN.
      expect(controller.selected, isNull);
    },
  );

  test('single-select caps to one region and All via VPN clears it', () async {
    final controller = OneVpnDirectRegionsController(
      loadCatalog: () async => _catalog(),
    );
    await controller.load();

    controller.selectRegion('CN');
    expect(controller.selected, 'CN');
    controller.selectRegion('RU');
    expect(controller.selected, 'RU');
    controller.selectAllViaVpn();
    expect(controller.selected, isNull);
    // A code outside the row set is ignored.
    controller.selectRegion('US');
    expect(controller.selected, isNull);
  });
}
