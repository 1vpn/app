// The location picker's view state over the catalogue value, the provisioned
// rows, and the committed selection.

import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/core/db/database/database.dart';
import 'package:onexray/onevpn/account/session.dart';
import 'package:onexray/onevpn/catalogue/catalogue.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations_en.dart';
import 'package:onexray/onevpn/location/location_picker_model.dart';
import 'package:onexray/onevpn/model/user_data.dart';
import 'package:onexray/service/connect/settings.dart';

CoreConfigData _node(String name, {int id = 1}) => CoreConfigData(
  id: id,
  name: name,
  type: 'outbound',
  tags: 'vless',
  delay: 20,
  subId: 0,
  countryCode: null,
  favorite: false,
  data: '',
);

OneVpnSession _premium({
  List<OneVpnApiLocation> locations = const <OneVpnApiLocation>[],
}) => OneVpnSession(
  sessionAuthToken: 'token',
  username: 'someone',
  email: 'someone@example.invalid',
  isPremium: true,
  credentials: const OneVpnCredentials(uuid: 'u', publicKey: 'p', shortId: 's'),
  locations: locations,
);

/// One provisioned row for each of the three free connectable cities.
List<CoreConfigData> _freeFloorRows() => [
  _node('1vpn·free·ams·1', id: 1),
  _node('1vpn·free·sgp·1', id: 2),
  _node('1vpn·free·lax·1', id: 3),
];

void main() {
  test('the free catalogue renders three locations and twenty-nine teasers, '
      'Automatic selected by default', () {
    final model = OneVpnLocationPickerModel.from(
      catalogue: OneVpnCatalogue.forSession(null),
      servers: _freeFloorRows(),
      selection: const ServerSelection.automatic(),
    );
    expect(model.automaticSelected, isTrue);
    expect(model.locations.map((l) => l.city), [
      'Amsterdam',
      'Singapore',
      'Los Angeles',
    ]);
    expect(model.locations.every((l) => l.freeTier), isTrue);
    expect(model.locations.every((l) => l.available), isTrue);
    expect(model.locations.every((l) => !l.selected), isTrue);
    // The data holds thirty teasers. The model drops the Singapore duplicate.
    expect(model.teasers, hasLength(29));
    expect(model.teasers.any((t) => t.city == 'Singapore'), isFalse);
    expect(model.degraded, isFalse);
    expect(model.empty, isFalse);
  });

  test('a location selection marks its row and clears Automatic', () {
    final model = OneVpnLocationPickerModel.from(
      catalogue: OneVpnCatalogue.forSession(null),
      servers: _freeFloorRows(),
      selection: const ServerSelection.location('1vpn·free·ams'),
    );
    expect(model.automaticSelected, isFalse);
    final amsterdam = model.locations.firstWhere((l) => l.city == 'Amsterdam');
    expect(amsterdam.selected, isTrue);
    expect(amsterdam.stem, '1vpn·free·ams');
    expect(model.locations.where((l) => l.selected).map((l) => l.city), [
      'Amsterdam',
    ]);
  });

  test('a free location is available with no provisioned row', () {
    final model = OneVpnLocationPickerModel.from(
      catalogue: OneVpnCatalogue.forSession(null),
      // Only Amsterdam is provisioned. Singapore and Los Angeles have no node.
      servers: [_node('1vpn·free·ams·1', id: 1)],
      selection: const ServerSelection.automatic(),
    );
    expect(model.locations.map((l) => l.city), [
      'Amsterdam',
      'Singapore',
      'Los Angeles',
    ]);
    expect(model.locations.every((l) => l.available), isTrue);
  });

  test('a premium location with no provisioned row is unavailable', () {
    const own = OneVpnApiLocation(
      city: 'Tokyo',
      cityCode: 'nrt',
      country: 'Japan',
      countryCode: 'jp',
      servers: <OneVpnApiServer>[
        OneVpnApiServer(host: 'nrt-1.example.invalid'),
      ],
    );
    final model = OneVpnLocationPickerModel.from(
      catalogue: OneVpnCatalogue.forSession(_premium(locations: [own])),
      servers: _freeFloorRows(),
      selection: const ServerSelection.automatic(),
    );
    final tokyo = model.locations.firstWhere((l) => l.city == 'Tokyo');
    expect(tokyo.available, isFalse);
  });

  test('a premium account with its own locations lists the free nodes then '
      'its own, with no teasers, once the failover window passes', () {
    const own = OneVpnApiLocation(
      city: 'Tokyo',
      cityCode: 'nrt',
      country: 'Japan',
      countryCode: 'jp',
      servers: <OneVpnApiServer>[
        OneVpnApiServer(host: 'nrt-1.example.invalid'),
      ],
    );
    final model = OneVpnLocationPickerModel.from(
      catalogue: OneVpnCatalogue.forSession(_premium(locations: [own])),
      servers: _freeFloorRows(),
      selection: const ServerSelection.automatic(),
      failoverElapsed: true,
    );
    expect(model.freeHidden, isFalse);
    expect(model.locations.map((l) => l.city), [
      'Amsterdam',
      'Singapore',
      'Los Angeles',
      'Tokyo',
    ]);
    final tokyo = model.locations.firstWhere((l) => l.city == 'Tokyo');
    expect(tokyo.freeTier, isFalse);
    expect(tokyo.stem, '1vpn·acct·nrt');
    expect(model.teasers, isEmpty);
    expect(model.degraded, isFalse);
  });

  group('a premium account hides the free nodes', () {
    const own = OneVpnApiLocation(
      city: 'Tokyo',
      cityCode: 'nrt',
      country: 'Japan',
      countryCode: 'jp',
      servers: <OneVpnApiServer>[
        OneVpnApiServer(host: 'nrt-1.example.invalid'),
      ],
    );
    final premium = OneVpnCatalogue.forSession(_premium(locations: [own]));
    final premiumRow = _node('1vpn·acct·nrt·1', id: 9);

    List<String> cities({
      required List<CoreConfigData> servers,
      required bool failoverElapsed,
      ServerSelection selection = const ServerSelection.automatic(),
    }) => OneVpnLocationPickerModel.from(
      catalogue: premium,
      servers: servers,
      selection: selection,
      failoverElapsed: failoverElapsed,
    ).locations.map((l) => l.city).toList();

    test('while a premium node is available', () {
      final model = OneVpnLocationPickerModel.from(
        catalogue: premium,
        servers: [..._freeFloorRows(), premiumRow],
        selection: const ServerSelection.automatic(),
      );
      expect(model.freeHidden, isTrue);
      expect(model.locations.map((l) => l.city), ['Tokyo']);
    });

    test('past the failover window while a premium node is available', () {
      expect(
        cities(
          servers: [..._freeFloorRows(), premiumRow],
          failoverElapsed: true,
        ),
        ['Tokyo'],
      );
    });

    test('inside the failover window with no premium node yet', () {
      expect(cities(servers: _freeFloorRows(), failoverElapsed: false), [
        'Tokyo',
      ]);
    });

    test('and lists them once the window passes with no premium node', () {
      expect(cities(servers: _freeFloorRows(), failoverElapsed: true), [
        'Amsterdam',
        'Singapore',
        'Los Angeles',
        'Tokyo',
      ]);
    });

    test('except a kept free node, which stays listed', () {
      final model = OneVpnLocationPickerModel.from(
        catalogue: premium,
        servers: [..._freeFloorRows(), premiumRow],
        selection: const ServerSelection.automatic(),
        kept: const {'1vpn·free·sgp'},
      );
      expect(model.locations.map((l) => l.city), ['Singapore', 'Tokyo']);
    });

    test('unless the free nodes are already listed', () {
      final model = OneVpnLocationPickerModel.from(
        catalogue: premium,
        servers: [..._freeFloorRows(), premiumRow],
        selection: const ServerSelection.automatic(),
        freeListed: true,
      );
      expect(model.freeHidden, isFalse);
      expect(model.locations.map((l) => l.city), [
        'Amsterdam',
        'Singapore',
        'Los Angeles',
        'Tokyo',
      ]);
    });

    test('except a selected free node, which stays listed', () {
      expect(
        cities(
          servers: [..._freeFloorRows(), premiumRow],
          failoverElapsed: false,
          selection: const ServerSelection.location('1vpn·free·ams'),
        ),
        ['Amsterdam', 'Tokyo'],
      );
    });
  });

  test('the failover window starts at eight seconds', () {
    expect(kOneVpnPremiumFailoverWindow, const Duration(seconds: 8));
  });

  test('the free tier never hides its free nodes', () {
    final model = OneVpnLocationPickerModel.from(
      catalogue: OneVpnCatalogue.forSession(null),
      servers: const [],
      selection: const ServerSelection.automatic(),
    );
    expect(model.freeHidden, isFalse);
    expect(model.locations, hasLength(3));
  });

  test('a premium account with nothing usable is degraded: the free nodes, no '
      'teasers, the degraded flag set', () {
    final model = OneVpnLocationPickerModel.from(
      catalogue: OneVpnCatalogue.forSession(_premium()),
      servers: _freeFloorRows(),
      selection: const ServerSelection.automatic(),
    );
    expect(model.degraded, isTrue);
    expect(model.locations.map((l) => l.city), [
      'Amsterdam',
      'Singapore',
      'Los Angeles',
    ]);
    expect(model.teasers, isEmpty);
    expect(model.empty, isFalse);
  });

  test('an empty catalogue is the terminal contact-support state', () {
    final model = OneVpnLocationPickerModel.from(
      catalogue: const OneVpnCatalogue(
        tier: OneVpnTier.free,
        entries: <OneVpnCatalogueEntry>[],
      ),
      servers: const <CoreConfigData>[],
      selection: const ServerSelection.automatic(),
    );
    expect(model.empty, isTrue);
    expect(model.locations, isEmpty);
    expect(model.teasers, isEmpty);
  });

  group('OneVpnLocationNaming', () {
    test('maps every location stem to its city', () {
      final cities = OneVpnLocationNaming.citiesByStem(
        OneVpnCatalogue.forSession(null),
        OneVpnLocalizationsEn(),
      );
      expect(cities['1vpn·free·ams'], 'Amsterdam');
      expect(cities['1vpn·free·sgp'], 'Singapore');
      expect(cities['1vpn·free·lax'], 'Los Angeles');
    });

    test('recovers the stem from a provisioned row name', () {
      expect(
        OneVpnLocationNaming.stemOfRowName('1vpn·free·ams·1'),
        '1vpn·free·ams',
      );
      expect(
        OneVpnLocationNaming.stemOfRowName('1vpn·acct·nrt·2'),
        '1vpn·acct·nrt',
      );
      expect(OneVpnLocationNaming.stemOfRowName('nostemhere'), isNull);
    });
  });
}
