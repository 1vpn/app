// The node-delivery path, driven against a drift database.
//
// Covers the row rewrite, the remove-except sweep, the sign-out sweep, the
// per-node credential choice, and the provision log. Every row assertion
// reads the row back from the database through `readOutboundFromDbData`, the
// reader the app uses. No row assertion reads the written object. The
// database is an in-memory drift, injected into the provisioner and fresh per
// test.

import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/core/db/database/database.dart';
import 'package:onexray/core/db/database/enum.dart';
import 'package:onexray/onevpn/account/session.dart';
import 'package:onexray/onevpn/catalogue/free_node_ips.dart';
import 'package:onexray/onevpn/catalogue/location.dart';
import 'package:onexray/onevpn/catalogue/node_catalog.dart';
import 'package:onexray/onevpn/model/user_data.dart';
import 'package:onexray/onevpn/provision/node_provisioner.dart';
import 'package:onexray/service/servers/outbound/state_db.dart';

const _account = OneVpnCredentials(
  uuid: 'acct-uuid',
  publicKey: 'acct-pbk',
  shortId: 'acct-sid',
);
const _free = OneVpnCredentials(
  uuid: 'free-uuid',
  publicKey: 'free-pbk',
  shortId: 'free-sid',
);
const _incomplete = OneVpnCredentials(uuid: '', publicKey: '', shortId: '');

/// A free node dials its IP literal. The free fixture carries one.
const _freeAmsterdam = OneVpnLocation(
  code: 'ams',
  city: 'Amsterdam',
  country: 'Netherlands',
  countryCode: 'nl',
  freeTier: true,
  servers: [
    OneVpnServer(
      host: 'free-ams.example.invalid',
      sni: 'www.example.invalid',
      ip: '192.0.2.20',
    ),
  ],
);

/// A free node with no IP literal from the build.
const _freeAmsterdamHostOnly = OneVpnLocation(
  code: 'ams',
  city: 'Amsterdam',
  country: 'Netherlands',
  countryCode: 'nl',
  freeTier: true,
  servers: [
    OneVpnServer(host: 'free-ams.example.invalid', sni: 'www.example.invalid'),
  ],
);

const _accountLondon = OneVpnLocation(
  code: 'lhr',
  city: 'London',
  country: 'United Kingdom',
  countryCode: 'gb',
  freeTier: false,
  servers: [
    OneVpnServer(host: 'acct-lhr.example.invalid', sni: 'www.example.invalid'),
  ],
);

/// Two servers under one location, so a test can express one row per server.
const _accountTokyo = OneVpnLocation(
  code: 'nrt',
  city: 'Tokyo',
  country: 'Japan',
  countryCode: 'jp',
  freeTier: false,
  servers: [
    OneVpnServer(host: 'nrt-1.example.invalid', sni: 'www.example.invalid'),
    OneVpnServer(host: 'nrt-2.example.invalid', sni: 'www.example.invalid'),
  ],
);

/// A teaser: premium, with no servers. The provisioner walks past it without
/// a special case.
const _teaser = OneVpnLocation(
  code: 'syd',
  city: 'Sydney',
  country: 'Australia',
  countryCode: 'au',
  freeTier: true,
  premium: true,
  servers: [],
);

/// A server that carries both ip literals: v4 preferred, v6 the only fallback.
const _literalLondon = OneVpnLocation(
  code: 'lhr',
  city: 'London',
  country: 'United Kingdom',
  countryCode: 'gb',
  freeTier: false,
  servers: [
    OneVpnServer(
      host: 'acct-lhr.example.invalid',
      sni: 'www.example.invalid',
      ip: '192.0.2.10',
      ip6: '2001:db8::10',
    ),
  ],
);

class _FakeCatalog implements OneVpnNodeCatalog {
  const _FakeCatalog(this.entries);
  final List<OneVpnLocation> entries;

  @override
  Future<List<OneVpnLocation>> locations() async => entries;
}

void main() {
  late AppDatabase db;
  late OneVpnNodeProvisioner provisioner;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    provisioner = OneVpnNodeProvisioner(database: db);
    addTearDown(db.close);
  });

  Future<Map<String, CoreConfigData>> rowsByName() async {
    final rows = await (db.select(
      db.coreConfig,
    )..where((r) => r.type.equals(CoreConfigType.outbound.name))).get();
    return {for (final row in rows) row.name: row};
  }

  /// The outbound as the app reads it back, decoded by the same reader the
  /// runtime uses.
  Future<Map<String, dynamic>> readBack(int configId) async {
    final row = await db.coreConfigDao.searchRow(configId);
    expect(row, isNotNull, reason: 'row $configId should exist');
    return readOutboundFromDbData(row!);
  }

  Future<void> insertForeignRow(String name) => db.coreConfigDao.insertRow(
    CoreConfigCompanion.insert(
      name: name,
      type: CoreConfigType.outbound.name,
      tags: '',
      delay: 0,
      subId: 0,
    ),
  );

  String address(Map<String, dynamic> outbound) =>
      (outbound['settings'] as Map)['address'] as String;
  Map reality(Map<String, dynamic> outbound) =>
      ((outbound['streamSettings'] as Map)['realitySettings']) as Map;

  group('sync', () {
    test('writes one row per SERVER and returns ids that resolve', () async {
      final result = await provisioner.sync(
        _account,
        freeCredentials: _free,
        catalogOverride: const _FakeCatalog([_accountTokyo]),
      );

      expect(result.errors, isEmpty);
      expect(result.nodes.map((n) => n.rowName), <String>[
        '1vpn·acct·nrt·1',
        '1vpn·acct·nrt·2',
      ]);

      final one = await readBack(result.nodes[0].configId);
      final two = await readBack(result.nodes[1].configId);
      expect(address(one), 'nrt-1.example.invalid');
      expect(address(two), 'nrt-2.example.invalid');
    });

    test('walks past a teaser — no servers, no row, no error', () async {
      final result = await provisioner.sync(
        _account,
        freeCredentials: _free,
        catalogOverride: const _FakeCatalog([_teaser, _accountLondon]),
      );

      expect(result.errors, isEmpty);
      expect(
        (await rowsByName()).keys,
        <String>['1vpn·acct·lhr·1'],
        reason: 'the teaser has nothing to provision and needs no special case',
      );
    });

    test('a second sync rewrites the stored row under the same id', () async {
      final first = await provisioner.sync(
        _account,
        catalogOverride: const _FakeCatalog([_accountLondon]),
      );
      final id = first.nodes.single.configId;

      final second = await provisioner.sync(
        _account,
        catalogOverride: const _FakeCatalog([
          OneVpnLocation(
            code: 'lhr',
            city: 'London',
            country: 'United Kingdom',
            countryCode: 'gb',
            freeTier: false,
            servers: [
              OneVpnServer(
                host: 'acct-lhr-2.example.invalid',
                sni: 'www.example.invalid',
              ),
            ],
          ),
        ]),
      );

      expect(
        second.nodes.single.configId,
        id,
        reason: 'the native connect pins and reloads by row id',
      );
      expect((await rowsByName()).keys, <String>['1vpn·acct·lhr·1']);
      expect(address(await readBack(id)), 'acct-lhr-2.example.invalid');
    });

    test('an ip literal becomes the dial address, SNI intact', () async {
      final result = await provisioner.sync(
        _account,
        catalogOverride: const _FakeCatalog([_literalLondon]),
      );

      final out = await readBack(result.nodes.single.configId);
      expect(address(out), '192.0.2.10', reason: 'v4 preferred over v6');
      expect(reality(out)['serverName'], 'www.example.invalid');
    });
  });

  group('credentials are chosen per node, not per sync', () {
    test(
      'the free node carries the free triple, the account node its own',
      () async {
        final result = await provisioner.sync(
          _account,
          freeCredentials: _free,
          catalogOverride: const _FakeCatalog([_freeAmsterdam, _accountLondon]),
        );

        final byName = {for (final n in result.nodes) n.rowName: n.configId};
        final free = await readBack(byName['1vpn·free·ams·1']!);
        final account = await readBack(byName['1vpn·acct·lhr·1']!);

        expect((free['settings'] as Map)['id'], 'free-uuid');
        expect(reality(free)['password'], 'free-pbk');
        expect(reality(free)['shortId'], 'free-sid');

        expect((account['settings'] as Map)['id'], 'acct-uuid');
        expect(reality(account)['password'], 'acct-pbk');
        expect(reality(account)['shortId'], 'acct-sid');
      },
    );

    test(
      'an unconfigured free triple provisions no free node at all',
      () async {
        // With an incomplete free triple, the account triple never reaches
        // a free host. The provisioner refuses the free node and reports the
        // refusal. It never substitutes the account triple.
        final result = await provisioner.sync(
          _account,
          freeCredentials: _incomplete,
          catalogOverride: const _FakeCatalog([_freeAmsterdam, _accountLondon]),
        );

        expect(result.errors, hasLength(1));
        expect(result.errors.single, contains('ONEVPN_UUID'));
        expect(
          (await rowsByName()).keys,
          <String>['1vpn·acct·lhr·1'],
          reason:
              'no free row, rather than a free row with account credentials',
        );
      },
    );

    test(
      'a free node with no IP literal is skipped and recorded by hostname',
      () async {
        final result = await provisioner.sync(
          _account,
          freeCredentials: _free,
          catalogOverride: const _FakeCatalog([
            _freeAmsterdamHostOnly,
            _accountLondon,
          ]),
        );

        expect(result.errors, <String>[
          'The free node free-ams.example.invalid has no IP literal. Build '
              'with --dart-define ONEVPN_FREE_NODE_IPS.',
        ]);
        expect(
          (await rowsByName()).keys,
          <String>['1vpn·acct·lhr·1'],
          reason: 'no free row, rather than a free row that dials its hostname',
        );
      },
    );

    test(
      'an unconfigured free triple is reported ahead of a missing literal',
      () async {
        final result = await provisioner.sync(
          _account,
          freeCredentials: _incomplete,
          catalogOverride: const _FakeCatalog([_freeAmsterdamHostOnly]),
        );

        expect(result.errors, hasLength(1));
        expect(result.errors.single, contains('ONEVPN_UUID'));
        expect(result.nodes, isEmpty);
      },
    );

    test('a signed-in free session provisions the free tier its user data '
        'carries, with its triple', () async {
      const served = OneVpnSession(
        sessionAuthToken: 'token',
        username: 'someone',
        email: 'someone@example.invalid',
        isPremium: false,
        credentials: _free,
        locations: [
          OneVpnApiLocation(
            city: 'Frankfurt',
            cityCode: 'fra',
            country: 'Germany',
            countryCode: 'de',
            servers: [
              OneVpnApiServer(
                host: 'free-fra-1.example.invalid',
                realityServerName: 'www.example.invalid',
                ip: '192.0.2.30',
              ),
            ],
          ),
        ],
      );

      final result = await provisioner.provisionForSession(served);

      expect(result.nodes.map((n) => n.rowName), ['1vpn·free·fra·1']);
      final outbound = await readBack(result.nodes.single.configId);
      expect(address(outbound), '192.0.2.30');
      expect(reality(outbound)['password'], 'free-pbk');
      expect(reality(outbound)['shortId'], 'free-sid');
      expect(jsonEncode(outbound), contains('free-uuid'));
    });

    test('omitting freeCredentials falls back to the account triple', () async {
      final result = await provisioner.sync(
        _account,
        catalogOverride: const _FakeCatalog([_freeAmsterdam]),
      );

      expect(result.errors, isEmpty);
      expect(
        (await readBack(result.nodes.single.configId))['settings']['id'],
        'acct-uuid',
      );
    });

    test('an incomplete account triple skips the account node, floor survives', () async {
      // The provisioner checks credentials node by node, never once per sync.
      // An incomplete account triple skips only the account node, and the free
      // floor stays. Free credentials never reach the account host.
      final result = await provisioner.sync(
        _incomplete,
        freeCredentials: _free,
        catalogOverride: const _FakeCatalog([_freeAmsterdam, _accountLondon]),
      );

      expect(result.errors, <String>['No usable credentials for London.']);
      expect(
        (await rowsByName()).keys,
        <String>['1vpn·free·ams·1'],
        reason: 'the free floor stays provisioned; the account node is skipped',
      );
      expect(
        (await readBack(result.nodes.single.configId))['settings']['id'],
        'free-uuid',
      );
    });
  });

  group('the remove-except sweep', () {
    test(
      'a free row with no literal goes even when nothing provisions',
      () async {
        await provisioner.sync(
          _account,
          freeCredentials: _free,
          catalogOverride: const _FakeCatalog([_freeAmsterdam, _accountLondon]),
        );
        await insertForeignRow('my own server');

        final result = await provisioner.sync(
          _account,
          freeCredentials: _free,
          catalogOverride: const _FakeCatalog([_freeAmsterdamHostOnly]),
        );

        expect(result.nodes, isEmpty);
        expect((await rowsByName()).keys.toSet(), <String>{
          '1vpn·acct·lhr·1',
          'my own server',
        }, reason: 'only the free row that would dial its hostname goes');
      },
    );

    test(
      'an unconfigured free triple also takes a free row with no literal',
      () async {
        await provisioner.sync(
          _account,
          freeCredentials: _free,
          catalogOverride: const _FakeCatalog([_freeAmsterdam]),
        );

        final result = await provisioner.sync(
          _account,
          freeCredentials: _incomplete,
          catalogOverride: const _FakeCatalog([_freeAmsterdamHostOnly]),
        );

        expect(result.errors.single, contains('ONEVPN_UUID'));
        expect(await rowsByName(), isEmpty);
      },
    );

    test('a location that left the catalogue takes its row with it', () async {
      await provisioner.sync(
        _account,
        freeCredentials: _free,
        catalogOverride: const _FakeCatalog([_freeAmsterdam, _accountLondon]),
      );

      await provisioner.sync(
        _account,
        freeCredentials: _free,
        catalogOverride: const _FakeCatalog([_accountLondon]),
      );

      expect(
        (await rowsByName()).keys,
        <String>['1vpn·acct·lhr·1'],
        reason: 'sign in and the free rows must not linger beside the account',
      );
    });

    test('a repeated name keeps only its lowest id', () async {
      await insertForeignRow('1vpn·acct·lhr·1');
      await insertForeignRow('1vpn·acct·lhr·1');
      final ids = [
        for (final row in await db.select(db.coreConfig).get()) row.id,
      ];

      final result = await provisioner.sync(
        _account,
        catalogOverride: const _FakeCatalog([_accountLondon]),
      );

      final rows = await db.select(db.coreConfig).get();
      expect(rows.map((row) => row.name), <String>['1vpn·acct·lhr·1']);
      expect(rows.single.id, ids.reduce((a, b) => a < b ? a : b));
      expect(result.nodes.single.configId, rows.single.id);
      expect(
        address(await readBack(rows.single.id)),
        'acct-lhr.example.invalid',
      );
    });

    test('a row the user added by hand is never touched', () async {
      await insertForeignRow('a node I pasted in myself');

      await provisioner.sync(
        _account,
        freeCredentials: _free,
        catalogOverride: const _FakeCatalog([_accountLondon]),
      );

      expect(
        (await rowsByName()).keys,
        containsAll(<String>['a node I pasted in myself', '1vpn·acct·lhr·1']),
      );
    });

    test('an empty catalogue deletes nothing', () async {
      await provisioner.sync(
        _account,
        freeCredentials: _free,
        catalogOverride: const _FakeCatalog([_accountLondon]),
      );

      final second = await provisioner.sync(
        _account,
        freeCredentials: _free,
        catalogOverride: const _FakeCatalog([]),
      );

      expect(second.nodes, isEmpty);
      expect((await rowsByName()).keys, <String>['1vpn·acct·lhr·1']);
    });
  });

  group('the provision log', () {
    late List<String?> logs;

    setUp(() {
      logs = <String?>[];
      final previous = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) => logs.add(message);
      addTearDown(() => debugPrint = previous);
    });

    test('names every error, then every define entry it cannot use', () async {
      final result = await provisioner.sync(
        _account,
        freeCredentials: _free,
        catalogOverride: const _FakeCatalog([
          _freeAmsterdamHostOnly,
          _accountLondon,
        ]),
      );
      final ips = OneVpnFreeNodeIps.parse(
        'free-ams.example.invalid=not-an-address,192.0.2.7,'
        'other.example.invalid=192.0.2.8',
        hosts: const ['free-ams.example.invalid'],
      );

      oneVpnLogProvision(result, freeNodeIps: ips);

      expect(logs, <String>[
        'OneVpnNodeProvisioner: The free node free-ams.example.invalid has no '
            'IP literal. Build with --dart-define ONEVPN_FREE_NODE_IPS.',
        'OneVpnNodeProvisioner: ONEVPN_FREE_NODE_IPS rejects '
            'free-ams.example.invalid.',
        'OneVpnNodeProvisioner: ONEVPN_FREE_NODE_IPS rejects entry 2.',
        'OneVpnNodeProvisioner: ONEVPN_FREE_NODE_IPS names unknown host '
            'other.example.invalid.',
      ]);
      for (final line in logs) {
        expect(line, isNot(contains('192.0.2.')));
      }
    });

    test('without the define it logs the provision errors alone', () {
      oneVpnLogProvision(
        const OneVpnProvisionResult(
          nodes: [],
          errors: ['No usable credentials for London.'],
        ),
      );

      expect(logs, <String>[
        'OneVpnNodeProvisioner: No usable credentials for London.',
      ]);
    });
  });

  group('forgetSessionNodes', () {
    test('sign-out after a served free tier returns the floor rows to the '
        'compiled set', () async {
      const served = OneVpnSession(
        sessionAuthToken: 'token',
        username: 'someone',
        email: 'someone@example.invalid',
        isPremium: false,
        credentials: _free,
        locations: [
          OneVpnApiLocation(
            city: 'Frankfurt',
            cityCode: 'fra',
            country: 'Germany',
            countryCode: 'de',
            servers: [
              OneVpnApiServer(
                host: 'free-fra-1.example.invalid',
                ip: '192.0.2.30',
              ),
            ],
          ),
          OneVpnApiLocation(
            city: 'Amsterdam',
            cityCode: 'ams',
            country: 'Netherlands',
            countryCode: 'nl',
            servers: [
              OneVpnApiServer(
                host: 'free-ams-1.example.invalid',
                ip: '192.0.2.31',
              ),
            ],
          ),
        ],
      );
      await insertForeignRow('a node I pasted in myself');
      await provisioner.provisionForSession(served);
      expect(
        (await rowsByName()).keys,
        containsAll(['1vpn·free·fra·1', '1vpn·free·ams·1']),
      );

      await provisioner.forgetSessionNodes();

      // The compiled floor as a fresh signed-out install provisions it.
      final fresh = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(fresh.close);
      final compiled = await OneVpnNodeProvisioner(database: fresh)
          .provisionForSession(null);
      final rows = await rowsByName();
      expect(
        rows.keys,
        unorderedEquals([
          'a node I pasted in myself',
          ...compiled.nodes.map((n) => n.rowName),
        ]),
      );
      for (final row in rows.values) {
        if (row.data != null) {
          expect(
            jsonEncode(readOutboundFromDbData(row)),
            isNot(contains('192.0.2.3')),
          );
        }
      }
    });
  });

  group('forgetProvisionedNodes', () {
    test('removes the account rows, leaving the free floor', () async {
      await insertForeignRow('a node I pasted in myself');
      await provisioner.sync(
        _account,
        freeCredentials: _free,
        catalogOverride: const _FakeCatalog([_freeAmsterdam, _accountTokyo]),
      );
      expect((await rowsByName()).length, 4);

      final removed = await provisioner.forgetProvisionedNodes();

      expect(removed, 2);
      expect(
        (await rowsByName()).keys,
        unorderedEquals(<String>[
          'a node I pasted in myself',
          '1vpn·free·ams·1',
        ]),
        reason:
            'sign-out clears the account uuid from disk. The free floor and a '
            'hand-added row survive, so a signed-out device still dials free.',
      );
    });

    test('is a no-op when there is nothing of ours to forget', () async {
      await insertForeignRow('a node I pasted in myself');

      expect(await provisioner.forgetProvisionedNodes(), 0);
      expect((await rowsByName()).length, 1);
    });
  });
}
