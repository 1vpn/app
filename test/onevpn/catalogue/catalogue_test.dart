// The free/premium boundary: the free tier is never filtered.
//
// Pins three rules. The free catalogue keeps all 33 entries. A premium
// account gets the free nodes first, then its own, with no teasers. A
// premium account with nothing usable falls back to the free floor and marks
// it degraded. A signed-in free session takes the free tier its user data
// carries when complete, and the compiled floor when absent or incomplete.

import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/account/session.dart';
import 'package:onexray/onevpn/catalogue/catalogue.dart';
import 'package:onexray/onevpn/catalogue/free_floor.dart';
import 'package:onexray/onevpn/catalogue/location.dart';
import 'package:onexray/onevpn/catalogue/node_catalog.dart';
import 'package:onexray/onevpn/model/user_data.dart';

OneVpnSession _session({
  required bool isPremium,
  List<OneVpnApiLocation> locations = const <OneVpnApiLocation>[],
  DateTime? premiumPendingSince,
}) => OneVpnSession(
  sessionAuthToken: 'token-abc',
  username: 'someone',
  email: 'someone@example.invalid',
  isPremium: isPremium,
  credentials: const OneVpnCredentials(uuid: 'u', publicKey: 'p', shortId: 's'),
  locations: locations,
  premiumPendingSince: premiumPendingSince,
);

const _premiumLocation = OneVpnApiLocation(
  city: 'Tokyo',
  cityCode: 'nrt',
  country: 'Japan',
  countryCode: 'jp',
  isPremium: true,
  servers: <OneVpnApiServer>[
    OneVpnApiServer(host: 'premium-nrt-1.example.invalid'),
  ],
);

const _premiumTeaser = OneVpnApiLocation(
  city: 'London',
  cityCode: 'lhr',
  country: 'United Kingdom',
  countryCode: 'gb',
  isPremium: true,
);

void main() {
  group('the free catalogue matches v2', () {
    test('33 entries, 3 connectable, 30 teasers', () {
      expect(kOneVpnFreeCatalogue, hasLength(33));
      expect(kOneVpnFreeCatalogue.where((l) => l.isConnectable), hasLength(3));
    });

    test('the three connectable cities are Amsterdam, Singapore and Los '
        'Angeles', () {
      final connectable = kOneVpnFreeCatalogue
          .where((l) => l.isConnectable)
          .map((l) => l.city)
          .toList();
      // The list names each city, so a swapped city fails where a count
      // passes.
      expect(connectable, <String>['Amsterdam', 'Singapore', 'Los Angeles']);
    });

    test(
      'every connectable city has two servers, and every teaser has none',
      () {
        for (final location in kOneVpnFreeCatalogue) {
          expect(
            location.servers?.length ?? 0,
            location.isConnectable ? 2 : 0,
            reason: location.city,
          );
        }
      },
    );

    test('every teaser is flagged premium, and no connectable one is', () {
      // isPremium routes a tap to the paywall. It must always match "has no
      // servers".
      for (final location in kOneVpnFreeCatalogue) {
        expect(
          location.isPremium,
          !location.isConnectable,
          reason: location.city,
        );
      }
    });
  });

  group('the trap', () {
    test(
      'the premium filter applied to the free list would delete 30 of 33',
      () {
        // This test runs no catalogue code. It applies the premium filter to
        // the free list and counts the loss.
        final filtered = kOneVpnFreeCatalogue
            .where((l) => l.isConnectable)
            .toList();

        expect(filtered, hasLength(3));
        expect(kOneVpnFreeCatalogue.length - filtered.length, 30);
      },
    );

    test('the free catalogue keeps every teaser', () {
      final catalogue = OneVpnCatalogue.forSession(null);

      expect(catalogue.tier, OneVpnTier.free);
      expect(catalogue.locations, hasLength(33));
      // The data holds 30 teasers, and the catalogue shows 29. It drops the
      // Singapore teaser, which duplicates a connectable Singapore.
      expect(catalogue.teasers, hasLength(29));
      expect(catalogue.connectable, hasLength(3));
      expect(catalogue.isDegraded, isFalse);
    });
  });

  group('tier resolution', () {
    test('a signed-out user gets the free catalogue', () {
      expect(OneVpnCatalogue.forSession(null).tier, OneVpnTier.free);
    });

    test('a signed-in NON-premium user still gets the free catalogue', () {
      final catalogue = OneVpnCatalogue.forSession(
        _session(
          isPremium: false,
          locations: <OneVpnApiLocation>[_premiumLocation],
        ),
      );

      // An account is not a paid account. The server never sends these to a
      // free account, and the client must not rely on that.
      expect(catalogue.tier, OneVpnTier.free);
      expect(catalogue.locations, hasLength(33));
    });

    test('an unconfirmed premium grant unlocks the catalogue', () {
      // The persisted optimistic grant reads as entitled. A completed
      // purchase therefore unlocks before the server confirms it. The
      // catalogue adds no logic for this.
      final catalogue = OneVpnCatalogue.forSession(
        _session(
          isPremium: false,
          premiumPendingSince: DateTime.now().toUtc(),
          locations: <OneVpnApiLocation>[_premiumLocation],
        ),
      );

      expect(catalogue.tier, OneVpnTier.premium);
      expect(catalogue.connectable.map((l) => l.city), contains('Tokyo'));
    });

    test('a premium user gets the free nodes first, then their own', () {
      final catalogue = OneVpnCatalogue.forSession(
        _session(
          isPremium: true,
          locations: <OneVpnApiLocation>[_premiumLocation, _premiumTeaser],
        ),
      );

      expect(catalogue.tier, OneVpnTier.premium);
      // An account entry with no servers is unusable. The teaser is dropped,
      // and Tokyo stays.
      expect(catalogue.locations.map((l) => l.city).toList(), <String>[
        'Amsterdam',
        'Singapore',
        'Los Angeles',
        'Tokyo',
      ], reason: 'free nodes first, in catalogue order, then the account');
      expect(catalogue.isDegraded, isFalse);
    });

    test('premium does NOT inherit the 30 teasers', () {
      final catalogue = OneVpnCatalogue.forSession(
        _session(
          isPremium: true,
          locations: <OneVpnApiLocation>[_premiumLocation],
        ),
      );

      // Teasers sell locations a premium account already has.
      expect(catalogue.teasers, isEmpty);
      expect(catalogue.connectable, hasLength(4));
    });

    test(
      'an account location that reports isPremium FALSE is still not free',
      () {
        // The API sends an account's own locations with isPremium false or
        // absent. Tier comes from the source list, never from the wire.
        const wireSaysNotPremium = OneVpnApiLocation(
          city: 'Melbourne',
          cityCode: 'mel',
          country: 'Australia',
          countryCode: 'au',
          isPremium: false,
          servers: <OneVpnApiServer>[
            OneVpnApiServer(host: 'premium-mel.example.invalid'),
          ],
        );

        final catalogue = OneVpnCatalogue.forSession(
          _session(
            isPremium: true,
            locations: <OneVpnApiLocation>[wireSaysNotPremium],
          ),
        );

        final melbourne = catalogue.entries.firstWhere(
          (e) => e.location.city == 'Melbourne',
        );
        expect(melbourne.freeTier, isFalse);
        expect(
          catalogue.entries.where((e) => e.freeTier).length,
          3,
          reason: 'exactly the three compiled-in free nodes, and nothing else',
        );
      },
    );

    test('the free nodes are tagged from their source list', () {
      final catalogue = OneVpnCatalogue.forSession(
        _session(
          isPremium: true,
          locations: <OneVpnApiLocation>[_premiumLocation],
        ),
      );

      final free = catalogue.entries
          .where((e) => e.freeTier)
          .map((e) => e.location.city)
          .toList();
      expect(free, <String>['Amsterdam', 'Singapore', 'Los Angeles']);
    });

    test('a premium user with nothing usable falls back, and says so', () {
      for (final locations in <List<OneVpnApiLocation>>[
        <OneVpnApiLocation>[],
        <OneVpnApiLocation>[_premiumTeaser],
      ]) {
        final catalogue = OneVpnCatalogue.forSession(
          _session(isPremium: true, locations: locations),
        );

        // The fallback shows the three free locations. The tier stays
        // premium, and the catalogue marks itself degraded.
        expect(catalogue.tier, OneVpnTier.premium);
        expect(catalogue.isDegraded, isTrue);
        expect(catalogue.connectable, hasLength(3));
      }
    });

    test('the degraded fallback carries no teasers either', () {
      // A premium account whose own list failed to load sees no locked rows.
      // It already pays for those locations.
      for (final locations in <List<OneVpnApiLocation>>[
        <OneVpnApiLocation>[],
        <OneVpnApiLocation>[_premiumTeaser],
      ]) {
        final catalogue = OneVpnCatalogue.forSession(
          _session(isPremium: true, locations: locations),
        );

        expect(catalogue.isDegraded, isTrue);
        expect(catalogue.teasers, isEmpty);
        expect(
          catalogue.entries.every((e) => e.location.isConnectable),
          isTrue,
          reason: 'nothing in a premium catalogue may route to the paywall',
        );
        expect(catalogue.connectable, hasLength(3));
      }
    });
  });

  group('the free tier of a signed-in free session', () {
    const served = OneVpnCredentials(
      uuid: 'served-uuid',
      publicKey: 'served-pbk',
      shortId: 'served-sid',
    );
    const frankfurt = OneVpnApiLocation(
      city: 'Frankfurt',
      cityCode: 'fra',
      country: 'Germany',
      countryCode: 'de',
      servers: <OneVpnApiServer>[
        OneVpnApiServer(
          host: 'free-fra-1.example.invalid',
          realityServerName: 'www.example.invalid',
          ip: '192.0.2.30',
        ),
      ],
    );

    OneVpnSession free({
      OneVpnCredentials credentials = served,
      List<OneVpnApiLocation> locations = const [frankfurt],
    }) => OneVpnSession(
      sessionAuthToken: 'token-abc',
      username: 'someone',
      email: 'someone@example.invalid',
      isPremium: false,
      credentials: credentials,
      locations: locations,
    );

    final compiledTeasers = kOneVpnFreeCatalogue
        .where((l) => !l.isConnectable)
        .toList();

    test('the user data wins when its tier is complete', () {
      final floor = oneVpnFreeFloor(free());
      expect(floor.credentials, same(free().credentials));
      expect(floor.locations, [frankfurt, ...compiledTeasers]);

      final catalogue = OneVpnCatalogue.forSession(free());
      expect(catalogue.tier, OneVpnTier.free);
      expect(catalogue.connectable, [frankfurt]);
      expect(catalogue.entries.every((e) => e.freeTier), isTrue);
    });

    test('the compiled floor stands when the user data carries no free '
        'tier', () {
      for (final session in [
        free(locations: const []),
        free(locations: const [_premiumLocation]),
        null,
      ]) {
        final floor = oneVpnFreeFloor(session);
        expect(floor.locations, same(kOneVpnFreeCatalogue));
        expect(floor.credentials, same(kOneVpnFreeCredentials));
        expect(
          OneVpnCatalogue.forSession(session).locations,
          kOneVpnFreeCatalogue,
        );
      }
    });

    test('the compiled floor stands when the user data tier is '
        'incomplete', () {
      const hostOnly = OneVpnApiLocation(
        city: 'Frankfurt',
        cityCode: 'fra',
        country: 'Germany',
        countryCode: 'de',
        servers: <OneVpnApiServer>[
          OneVpnApiServer(host: 'free-fra-1.example.invalid'),
        ],
      );
      const noCityCode = OneVpnApiLocation(
        country: 'Germany',
        countryCode: 'de',
        servers: <OneVpnApiServer>[
          OneVpnApiServer(host: 'free-fra-1.example.invalid', ip: '192.0.2.30'),
        ],
      );
      for (final session in [
        free(
          credentials: const OneVpnCredentials(
            uuid: 'served-uuid',
            publicKey: '',
            shortId: '',
          ),
        ),
        free(locations: const [frankfurt, hostOnly]),
        free(locations: const [noCityCode]),
      ]) {
        final floor = oneVpnFreeFloor(session);
        expect(floor.locations, same(kOneVpnFreeCatalogue));
        expect(floor.credentials, same(kOneVpnFreeCredentials));
      }
    });

    test('a premium session keeps the compiled free nodes', () {
      final premium = _session(
        isPremium: true,
        locations: const [_premiumLocation, frankfurt],
      );
      expect(
        oneVpnFreeFloor(premium).credentials,
        same(kOneVpnFreeCredentials),
      );
      expect(
        OneVpnCatalogue.forSession(premium).entries
            .where((e) => e.freeTier)
            .map((e) => e.location.city),
        ['Amsterdam', 'Singapore', 'Los Angeles'],
      );
    });
  });

  group('mapping onto the domain model', () {
    test('a teaser becomes an empty server list, which is what makes the '
        'provisioner skip it', () {
      final teaser = OneVpnLocation.fromApi(_premiumTeaser, freeTier: false);

      expect(teaser.servers, isEmpty);
      expect(teaser.premium, isTrue);
    });

    test('the free catalogue yields exactly 6 provisionable servers', () {
      final domain = kOneVpnFreeCatalogue
          .map((l) => OneVpnLocation.fromApi(l, freeTier: true))
          .toList();

      expect(domain, hasLength(33));
      expect(
        domain.fold<int>(0, (int sum, l) => sum + l.servers.length),
        6,
        reason: '3 cities x 2 servers; the 30 teasers contribute nothing',
      );
    });

    test('a missing SNI falls back to the default rather than to empty', () {
      final mapped = OneVpnLocation.fromApi(_premiumLocation, freeTier: false);

      expect(mapped.servers.single.sni, kOneVpnDefaultRealityServerName);
    });

    test('free and account nodes with the same city do NOT collide on a row '
        'name', () {
      const shared = OneVpnApiLocation(
        city: 'Amsterdam',
        cityCode: 'ams',
        country: 'Netherlands',
        countryCode: 'nl',
        servers: <OneVpnApiServer>[
          OneVpnApiServer(host: 'premium-ams.example.invalid'),
        ],
        isPremium: true,
      );
      final freeAms = OneVpnLocation.fromApi(
        kOneVpnFreeCatalogue.firstWhere((l) => l.cityCode == 'ams'),
        freeTier: true,
      );
      final acctAms = OneVpnLocation.fromApi(shared, freeTier: false);

      expect(freeAms.code, acctAms.code, reason: 'same city code');
      expect(freeAms.rowName(0), isNot(acctAms.rowName(0)));
      expect(freeAms.rowNameStem, isNot(acctAms.rowNameStem));
    });

    test('a missing city or cityCode falls back to the country', () {
      const bare = OneVpnApiLocation(country: 'Iceland', countryCode: 'is');

      final mapped = OneVpnLocation.fromApi(bare, freeTier: true);

      expect(mapped.code, 'is');
      expect(mapped.city, 'Iceland');
      // The country stands in for a missing city, so displayCode is the
      // country code rather than null.
      expect(mapped.displayCode, 'is');
    });

    test('a city with no cityCode looks up nothing, not the country', () {
      // Osaka with no cityCode keys on `jp`. A place-name table would then
      // answer "Japan" for a row named Osaka. displayCode is null, so a
      // consumer falls back to the server-sent name.
      const cityNoCode = OneVpnApiLocation(
        city: 'Osaka',
        country: 'Japan',
        countryCode: 'jp',
        servers: <OneVpnApiServer>[
          OneVpnApiServer(host: 'nrt.example.invalid'),
        ],
      );

      final mapped = OneVpnLocation.fromApi(cityNoCode, freeTier: false);

      expect(mapped.code, 'jp');
      expect(mapped.displayCode, isNull);
    });

    test(
      'two locations in one country with no cityCode stay distinct',
      () async {
        // cityCode is nullable on the wire, and the row key falls back to
        // countryCode. Two account locations in one country with no cityCode
        // then share a row name unless disambiguated. The surviving row would
        // hold the second location's host under the first's label.
        const first = OneVpnApiLocation(
          city: 'Reykjavik',
          country: 'Iceland',
          countryCode: 'is',
          servers: <OneVpnApiServer>[
            OneVpnApiServer(host: 'is-1.example.invalid'),
          ],
        );
        const second = OneVpnApiLocation(
          city: 'Akureyri',
          country: 'Iceland',
          countryCode: 'is',
          servers: <OneVpnApiServer>[
            OneVpnApiServer(host: 'is-2.example.invalid'),
          ],
        );

        final locations = await OneVpnSessionCatalog(
          _session(
            isPremium: true,
            locations: <OneVpnApiLocation>[first, second],
          ),
        ).locations();
        final account = locations.where((l) => !l.freeTier).toList();

        expect(account.map((l) => l.city), <String>['Reykjavik', 'Akureyri']);
        expect(
          account[0].rowName(0),
          isNot(account[1].rowName(0)),
          reason:
              'one row name for two different hosts is one row in the '
              'database, and the loser is undialable forever',
        );
      },
    );

    test('a location that collides with nothing keeps its plain code', () async {
      // The control. A suffix on each location would satisfy the test above. It
      // would also break synced users' row names and the place-name lookup.
      const only = OneVpnApiLocation(
        city: 'Reykjavik',
        country: 'Iceland',
        countryCode: 'is',
        servers: <OneVpnApiServer>[
          OneVpnApiServer(host: 'is-1.example.invalid'),
        ],
      );

      final locations = await OneVpnSessionCatalog(
        _session(isPremium: true, locations: <OneVpnApiLocation>[only]),
      ).locations();

      expect(locations.where((l) => !l.freeTier).single.code, 'is');
      expect(
        locations.where((l) => l.freeTier).map((l) => l.code),
        <String>['ams', 'sgp', 'lax'],
        reason:
            'the free three are untouched, and their codes are what a '
            'place-name table is keyed on',
      );
    });
  });

  group('the catalogue source', () {
    test('the static catalogue carries all 33', () async {
      expect(await const OneVpnStaticCatalog().locations(), hasLength(33));
    });

    test('the session catalogue follows the tier', () async {
      expect(await const OneVpnSessionCatalog(null).locations(), hasLength(33));
      expect(
        await OneVpnSessionCatalog(
          _session(
            isPremium: true,
            locations: <OneVpnApiLocation>[_premiumLocation],
          ),
        ).locations(),
        hasLength(4),
        reason: 'the three free nodes plus the one from the account',
      );
    });

    test(
      'an unreadable session yields the free catalogue like signed-out',
      () async {
        // The session getter returns null for anything but signed-in, so an
        // unreadable state reaches forSession as null and the free path.
        expect(
          await const OneVpnSessionCatalog(null).locations(),
          hasLength(33),
        );
        expect(OneVpnCatalogue.forSession(null).tier, OneVpnTier.free);
      },
    );
  });

  group('a teaser never duplicates a location the user can already dial', () {
    test('the free catalogue lists Singapore once', () {
      final catalogue = OneVpnCatalogue.forSession(null);
      final dialable = catalogue.connectable
          .map((l) => '${l.countryCode}/${l.cityCode}')
          .toSet();
      for (final teaser in catalogue.teasers) {
        expect(
          dialable,
          isNot(contains('${teaser.countryCode}/${teaser.cityCode}')),
          reason: '${teaser.city} is dialable and still offered as an upsell',
        );
      }
      // The data carries both Singapore entries. The shown list carries one.
      final shown = [...catalogue.connectable, ...catalogue.teasers];
      expect(shown.where((l) => l.cityCode == 'sgp'), hasLength(1));
    });
  });
}
