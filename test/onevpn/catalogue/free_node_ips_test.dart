// The free-node IP define: its parse, its application to the free catalogue,
// and its coverage of every free host. Fixtures use reserved hostnames and the
// RFC 5737 and RFC 3849 documentation literals.

import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/catalogue/free_floor.dart';
import 'package:onexray/onevpn/catalogue/free_node_ips.dart';
import 'package:onexray/onevpn/catalogue/location.dart';
import 'package:onexray/onevpn/model/user_data.dart';

/// Every host in the free catalogue, in catalogue order.
List<String> _freeHosts() => <String>[
  for (final location in kOneVpnFreeCatalogue)
    for (final server in location.servers ?? const <OneVpnApiServer>[])
      server.host,
];

/// A complete define: one TEST-NET literal for every free host.
String _completeDefine() => <String>[
  for (final (i, host) in _freeHosts().indexed) '$host=192.0.2.${i + 1}',
].join(',');

/// The fixture hosts the parse pins name.
const _hosts = <String>[
  'node-a.example.invalid',
  'node-b.example.invalid',
  'node-c.example.invalid',
  'node-d.example.invalid',
  'node-e.example.invalid',
  'node-f.example.invalid',
  'node-g.example.invalid',
  'node-1.example.invalid',
  'node-2.example.invalid',
  'node-3.example.invalid',
  'node-4.example.invalid',
  'node-5.example.invalid',
  'node-6.example.invalid',
];

/// Locations that set every field the model writes: a connectable location
/// and a teaser.
const _fixtureJson = <Map<String, dynamic>>[
  {
    'city': 'Example City',
    'cityCode': 'exc',
    'country': 'Example Country',
    'countryCode': 'ex',
    'servers': [
      {
        'host': 'Node-A.Example.Invalid',
        'realityServerName': 'www.example.invalid',
      },
      {
        'host': 'node-b.example.invalid',
        'realityServerName': 'www.example.invalid',
        'ip': '192.0.2.99',
        'ip6': '2001:db8::99',
      },
    ],
    'isPremium': false,
  },
  {
    'city': 'Teaser City',
    'cityCode': 'tsc',
    'country': 'Example Country',
    'countryCode': 'ex',
    'isPremium': true,
  },
];

/// Expects [ips] applied to [originals] to add the literals it names and
/// keep every other field. Compares the JSON each location writes.
void _expectOnlyLiteralsAdded(
  List<OneVpnApiLocation> originals,
  OneVpnFreeNodeIps ips,
) {
  final applied = ips.applyTo(originals);

  expect(applied, hasLength(originals.length));
  for (final (i, original) in originals.indexed) {
    final expected = original.toJson();
    if (expected['servers'] case final List<dynamic> servers) {
      expected['servers'] = <Map<String, dynamic>>[
        for (final server in servers.cast<Map<String, dynamic>>())
          if (ips.byHost[(server['host'] as String).toLowerCase()]
              case final literals?)
            <String, dynamic>{
              for (final entry in server.entries)
                if (entry.key != 'ip' && entry.key != 'ip6')
                  entry.key: entry.value,
              'ip': literals.ip,
              if (literals.ip6 != null) 'ip6': literals.ip6,
            }
          else
            server,
      ];
    }
    expect(applied[i].toJson(), expected, reason: original.cityCode);
  }
}

/// Parses [raw] against the fixture hosts.
OneVpnFreeNodeIps _parse(String raw) =>
    OneVpnFreeNodeIps.parse(raw, hosts: _hosts);

/// Parses [raw] against the free catalogue's hosts.
OneVpnFreeNodeIps _parseFree(String raw) =>
    OneVpnFreeNodeIps.parse(raw, hosts: kOneVpnFreeHosts);

void main() {
  group('parse', () {
    test('an empty define names no host and rejects nothing', () {
      final ips = _parse('');

      expect(ips.byHost, isEmpty);
      expect(ips.malformed, isEmpty);
      expect(ips.unknown, isEmpty);
    });

    test('one entry sets the IPv4 literal alone', () {
      final ips = _parse('node-a.example.invalid=192.0.2.1');

      expect(ips.byHost, <String, OneVpnNodeLiterals>{
        'node-a.example.invalid': (ip: '192.0.2.1', ip6: null),
      });
      expect(ips.malformed, isEmpty);
    });

    test('six entries set six hosts', () {
      final ips = _parse(
        [for (var i = 1; i <= 6; i++) 'node-$i.example.invalid=192.0.2.$i']
            .join(','),
      );

      expect(ips.byHost, hasLength(6));
      expect(ips.byHost['node-6.example.invalid']?.ip, '192.0.2.6');
      expect(ips.malformed, isEmpty);
    });

    test('an entry with an IPv6 literal sets both', () {
      final ips = _parse('node-a.example.invalid=192.0.2.1/2001:db8::1');

      expect(ips.byHost['node-a.example.invalid'], (
        ip: '192.0.2.1',
        ip6: '2001:db8::1',
      ));
    });

    test('a malformed entry is reported by hostname and sets nothing', () {
      final ips = _parse(
        [
          'node-a.example.invalid=192.0.2.1',
          'node-b.example.invalid=not-an-address',
          'node-c.example.invalid=2001:db8::3',
          'node-d.example.invalid=192.0.2.4/192.0.2.5',
          'node-e.example.invalid=192.0.2.6/2001:db8::6/2001:db8::7',
          'node-f.example.invalid=',
          'node-g.example.invalid',
        ].join(','),
      );

      expect(ips.byHost.keys, <String>['node-a.example.invalid']);
      expect(ips.malformed, <String>[
        'node-b.example.invalid',
        'node-c.example.invalid',
        'node-d.example.invalid',
        'node-e.example.invalid',
        'node-f.example.invalid',
        'node-g.example.invalid',
      ]);
    });

    test('a hostname named twice is reported once and sets nothing', () {
      final ips = _parse(
        'node-a.example.invalid=192.0.2.1,'
        'node-a.example.invalid=192.0.2.2,'
        'node-a.example.invalid=192.0.2.3',
      );

      expect(ips.byHost, isEmpty);
      expect(ips.malformed, <String>['node-a.example.invalid']);
    });

    test('whitespace around every part and a blank entry are tolerated', () {
      final ips = _parse(
        '  node-a.example.invalid = 192.0.2.1 / 2001:db8::1 ,'
        '\tnode-b.example.invalid=192.0.2.2\n, ,',
      );

      expect(ips.byHost, <String, OneVpnNodeLiterals>{
        'node-a.example.invalid': (ip: '192.0.2.1', ip6: '2001:db8::1'),
        'node-b.example.invalid': (ip: '192.0.2.2', ip6: null),
      });
      expect(ips.malformed, isEmpty);
    });

    test('an entry with no hostname is reported by its position', () {
      final ips = _parse(
        '=192.0.2.1,192.0.2.2, ,node-a.example.invalid=192.0.2.4,'
        '2001:db8::5=192.0.2.5,192.0.2.6/2001:db8::6',
      );

      expect(ips.byHost.keys, <String>['node-a.example.invalid']);
      expect(ips.malformed, <String>[
        'entry 1',
        'entry 2',
        'entry 5',
        'entry 6',
      ]);
      for (final key in [...ips.malformed, ...ips.unknown]) {
        expect(key, isNot(contains('192.0.2.')));
        expect(key, isNot(contains('2001:db8')));
      }
    });

    test('an entry with no = counts toward the repeat rule', () {
      for (final raw in const [
        'node-a.example.invalid,node-a.example.invalid=192.0.2.1',
        'node-a.example.invalid=192.0.2.1,node-a.example.invalid',
      ]) {
        final ips = _parse(raw);

        expect(ips.byHost, isEmpty, reason: raw);
        expect(ips.malformed, <String>['node-a.example.invalid'], reason: raw);
      }
    });

    test('a hostname matches in any letter case', () {
      final ips = OneVpnFreeNodeIps.parse(
        'NODE-A.Example.INVALID=192.0.2.1,node-b.example.invalid=192.0.2.2',
        hosts: const ['node-a.example.invalid', 'Node-B.Example.Invalid'],
      );

      expect(ips.byHost, <String, OneVpnNodeLiterals>{
        'node-a.example.invalid': (ip: '192.0.2.1', ip6: null),
        'node-b.example.invalid': (ip: '192.0.2.2', ip6: null),
      });
      expect(ips.malformed, isEmpty);
      expect(ips.unknown, isEmpty);
    });

    test('a hostname named twice in two cases is a repeat', () {
      final ips = _parse(
        'node-a.example.invalid=192.0.2.1,NODE-A.example.invalid=192.0.2.2',
      );

      expect(ips.byHost, isEmpty);
      expect(ips.malformed, <String>['node-a.example.invalid']);
    });

    test('a hostname no free node carries is unknown and sets nothing', () {
      final ips = _parse(
        'node-a.example.invalid=192.0.2.1,'
        'other.example.invalid=192.0.2.2,'
        'OTHER.example.invalid=not-an-address',
      );

      expect(ips.byHost.keys, <String>['node-a.example.invalid']);
      expect(ips.unknown, <String>['other.example.invalid']);
      expect(ips.malformed, isEmpty);
    });
  });

  group('the free catalogue', () {
    test('the host list is the catalogue hosts, lowercased', () {
      expect(kOneVpnFreeHosts, hasLength(6));
      expect(kOneVpnFreeHosts, [for (final h in _freeHosts()) h.toLowerCase()]);
    });

    test('a define host outside the catalogue is unknown', () {
      final ips = _parseFree(
        '${_completeDefine()},free-node.example.invalid=192.0.2.9',
      );

      expect(ips.byHost, hasLength(6));
      expect(ips.unknown, <String>['free-node.example.invalid']);
    });

    test('applying matches a server host in any letter case', () {
      final ips = _parse('node-a.example.invalid=192.0.2.1');
      final applied = ips.applyTo(const [
        OneVpnApiLocation(
          country: 'Example',
          countryCode: 'ex',
          servers: [OneVpnApiServer(host: 'Node-A.Example.Invalid')],
        ),
      ]);

      expect(applied.single.servers!.single.ip, '192.0.2.1');
      expect(applied.single.servers!.single.host, 'Node-A.Example.Invalid');
    });

    test('without the define, no free server carries a literal', () {
      expect(kOneVpnFreeNodeIps.byHost, isEmpty);
      for (final location in kOneVpnFreeCatalogue) {
        for (final server in location.servers ?? const <OneVpnApiServer>[]) {
          expect(server.ip, isNull, reason: server.host);
          expect(server.ip6, isNull, reason: server.host);
        }
      }
    });

    test('a complete define covers every free host', () {
      final hosts = _freeHosts();
      final applied = _parseFree(_completeDefine())
          .applyTo(kOneVpnFreeCatalogue);
      final servers = <OneVpnServer>[
        for (final location in applied)
          ...OneVpnLocation.fromApi(location, freeTier: true).servers,
      ];

      expect(hosts, hasLength(6));
      expect(servers.map((s) => s.host), hosts);
      for (final (i, server) in servers.indexed) {
        expect(server.ip, '192.0.2.${i + 1}', reason: server.host);
        expect(server.dialAddress, server.ip, reason: server.host);
      }
    });

    test('applying adds the literals and keeps every other field', () {
      final fixture = [
        for (final json in _fixtureJson) OneVpnApiLocation.fromJson(json)!,
      ];
      // Anti-vacuity: the fixture writes back every key it was read from.
      expect([for (final location in fixture) location.toJson()], _fixtureJson);

      _expectOnlyLiteralsAdded(
        fixture,
        _parse('node-a.example.invalid=192.0.2.1/2001:db8::1'),
      );
      _expectOnlyLiteralsAdded(
        kOneVpnFreeCatalogue,
        _parseFree(
          <String>[
            for (final (i, host) in _freeHosts().indexed)
              '$host=192.0.2.${i + 1}/2001:db8::${i + 1}',
          ].join(','),
        ),
      );
    });

    test('a host the define does not name keeps its hostname only', () {
      final first = _freeHosts().first;
      final applied = _parseFree('$first=192.0.2.1')
          .applyTo(kOneVpnFreeCatalogue);
      final servers = <OneVpnApiServer>[
        for (final location in applied) ...?location.servers,
      ];

      expect(servers.first.ip, '192.0.2.1');
      for (final server in servers.skip(1)) {
        expect(server.ip, isNull, reason: server.host);
        expect(server.ip6, isNull, reason: server.host);
      }
    });
  });
}
