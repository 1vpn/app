// The connect-screen location-row label. With a connected Automatic
// selection, the row names the resolved node as "Automatic · {city}". The
// label maps the runtime entry id through the provisioned row name to the
// catalogue city. A disconnected Automatic tunnel reads the bare
// "Automatic". A kept location missing from the catalogue takes its city
// from the account's full list, then from the free catalogue's teasers. A
// location nothing names reads "Automatic", never "Temporarily
// unavailable".

import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/core/db/database/database.dart';
import 'package:onexray/onevpn/account/session.dart';
import 'package:onexray/onevpn/catalogue/catalogue.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations_en.dart';
import 'package:onexray/onevpn/model/user_data.dart';
import 'package:onexray/onevpn/shell/connect_screen.dart';
import 'package:onexray/service/connect/settings.dart';
import 'package:onexray/service/servers/catalog.dart';

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

void main() {
  final l = OneVpnLocalizationsEn();
  // The free catalogue maps the stem 1vpn·free·ams to Amsterdam.
  final catalogue = OneVpnCatalogue.forSession(null);
  // A provisioned row for the Amsterdam free node, id 1.
  final catalog = ServerCatalog(servers: [_node('1vpn·free·ams·1', id: 1)]);
  const automatic = ServerSelection.automatic();

  test('a disconnected Automatic selection reads the bare label', () {
    expect(
      OneVpnConnectRowLabel.locationRow(
        l: l,
        selection: automatic,
        connected: false,
        resolvedNodeId: 1,
        catalog: catalog,
        catalogue: catalogue,
      ),
      l.onevpnAutomaticSelection,
    );
  });

  test('a connected Automatic selection names the resolved node', () {
    final label = OneVpnConnectRowLabel.locationRow(
      l: l,
      selection: automatic,
      connected: true,
      resolvedNodeId: 1,
      catalog: catalog,
      catalogue: catalogue,
    );
    expect(label, l.onevpnAutomaticResolved('Amsterdam'));
    // Anti-vacuity: the connected label is not the bare selection label, and
    // it names the resolved city.
    expect(label, isNot(l.onevpnAutomaticSelection));
    expect(label, contains('Amsterdam'));
  });

  test('a connected Automatic with an unknown node falls back to bare', () {
    expect(
      OneVpnConnectRowLabel.locationRow(
        l: l,
        selection: automatic,
        connected: true,
        resolvedNodeId: 999,
        catalog: catalog,
        catalogue: catalogue,
      ),
      l.onevpnAutomaticSelection,
    );
  });

  group('a location selection', () {
    String label(ServerSelection selection, OneVpnSession? session) {
      final catalogues = OneVpnConnectRowLabel.namingCatalogues(session);
      return OneVpnConnectRowLabel.locationRow(
        l: l,
        selection: selection,
        connected: false,
        resolvedNodeId: null,
        catalog: catalog,
        catalogue: catalogues.first,
        fallbacks: catalogues.skip(1),
      );
    }

    OneVpnSession session(List<OneVpnApiLocation> locations) => OneVpnSession(
      sessionAuthToken: 'token',
      username: 'someone',
      email: 'someone@example.invalid',
      isPremium: true,
      credentials: const OneVpnCredentials(
        uuid: 'u',
        publicKey: 'p',
        shortId: 's',
      ),
      locations: locations,
    );

    test('a premium location with no server names its city from the '
        "account's full list", () {
      final account = session(const [
        OneVpnApiLocation(
          city: 'Osaka',
          cityCode: 'kix',
          country: 'Japan',
          countryCode: 'JP',
          servers: [],
        ),
        OneVpnApiLocation(
          city: 'Tokyo',
          cityCode: 'nrt',
          country: 'Japan',
          countryCode: 'JP',
          servers: [OneVpnApiServer(host: 'nrt.example.invalid')],
        ),
      ]);
      // Anti-vacuity: the account's catalogue leaves Osaka out.
      expect(
        OneVpnCatalogue.forSession(account).locations.map((e) => e.city),
        isNot(contains('Osaka')),
      );

      expect(
        label(const ServerSelection.location('1vpn·acct·kix'), account),
        'Osaka',
      );
    });

    test("a premium city takes its name from the free catalogue's teasers "
        "while the account's list is not loaded", () {
      final unloaded = session(const []);
      expect(OneVpnCatalogue.forSession(unloaded).isDegraded, isTrue);

      expect(
        label(const ServerSelection.location('1vpn·acct·syd'), unloaded),
        'Sydney',
      );
      expect(
        label(const ServerSelection.location('1vpn·acct·syd'), null),
        'Sydney',
      );
    });

    test('a location nothing names reads Automatic', () {
      final named = label(
        const ServerSelection.location('1vpn·acct·zzz'),
        null,
      );
      expect(named, l.onevpnAutomaticSelection);
      expect(named, isNot(l.onevpnTemporarilyUnavailable));
    });
  });
}
