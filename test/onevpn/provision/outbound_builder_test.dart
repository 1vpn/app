// The fork-owned outbound map. The tests cover its flattened v26 shape and
// the dial-address preference across all four literal shapes. The neither
// case compiles byte-identical to the hostname outbound, with the DoH
// cascade unchanged.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/catalogue/location.dart';
import 'package:onexray/onevpn/model/user_data.dart';
import 'package:onexray/onevpn/provision/outbound_builder.dart';
import 'package:onexray/service/connect/compiler.dart';
import 'package:onexray/service/connect/settings.dart';

import '../support/compiler_fixtures.dart';

const _credentials = OneVpnCredentials(
  uuid: '00000000-0000-4000-8000-000000000000',
  publicKey: 'test-public-key',
  shortId: 'deadbeef',
);

// The host is an RFC 2606 name. The literals are RFC 5737 and RFC 3849
// documentation addresses.
const _host = 'node-1.example.invalid';
const _sni = 'sni.example.invalid';
const _v4 = '192.0.2.10';
const _v6 = '2001:db8::10';

Map<String, dynamic> _build(OneVpnServer server) =>
    OneVpnOutboundBuilder.build(server: server, credentials: _credentials);

void main() {
  group('the flattened v26 outbound shape', () {
    final outbound = _build(const OneVpnServer(host: _host, sni: _sni));

    test('protocol and flattened settings', () {
      expect(outbound['protocol'], 'vless');
      final settings = outbound['settings'] as Map;
      expect(settings['address'], _host);
      expect(settings['port'], 443);
      expect(settings['id'], _credentials.uuid);
      expect(settings['flow'], 'xtls-rprx-vision');
      expect(settings['encryption'], 'none');
      expect(settings.containsKey('vnext'), isFalse);
    });

    test('REALITY stream settings, key in the field the core reads', () {
      final stream = outbound['streamSettings'] as Map;
      expect(stream['network'], 'raw');
      expect(stream['security'], 'reality');
      final reality = stream['realitySettings'] as Map;
      expect(reality['serverName'], _sni);
      expect(reality['shortId'], _credentials.shortId);
      expect(reality['fingerprint'], 'chrome');
      // Xray-core accepts realitySettings.password and publicKey alike.
      expect(reality['password'], _credentials.publicKey);
    });

    test('we build ONLY an outbound — no inbounds, routing or DNS from us', () {
      expect(outbound.containsKey('inbounds'), isFalse);
      expect(outbound.containsKey('routing'), isFalse);
      expect(outbound.containsKey('dns'), isFalse);
    });
  });

  group('dial-address preference, four shapes', () {
    String addressFor({String? ip, String? ip6}) {
      final server = OneVpnServer(host: _host, sni: _sni, ip: ip, ip6: ip6);
      // The domain getter and the built outbound must agree.
      final built = (_build(server)['settings'] as Map)['address'] as String;
      expect(built, server.dialAddress);
      return built;
    }

    test('ip only dials the v4 literal', () {
      expect(addressFor(ip: _v4), _v4);
    });

    test('ip6 only dials the v6 literal', () {
      expect(addressFor(ip6: _v6), _v6);
    });

    test('both present prefers v4', () {
      expect(addressFor(ip: _v4, ip6: _v6), _v4);
    });

    test('neither dials the hostname', () {
      expect(addressFor(), _host);
    });

    test(
      'the SNI is the camouflage domain in every shape, never a literal',
      () {
        for (final server in <OneVpnServer>[
          const OneVpnServer(host: _host, sni: _sni, ip: _v4),
          const OneVpnServer(host: _host, sni: _sni, ip6: _v6),
          const OneVpnServer(host: _host, sni: _sni, ip: _v4, ip6: _v6),
          const OneVpnServer(host: _host, sni: _sni),
        ]) {
          final reality =
              (_build(server)['streamSettings'] as Map)['realitySettings']
                  as Map;
          expect(reality['serverName'], _sni);
        }
      },
    );
  });

  test('the neither case is byte-identical to a host-only outbound', () {
    final neither = _build(
      const OneVpnServer(host: _host, sni: _sni, ip: null, ip6: null),
    );
    final hostOnly = _build(const OneVpnServer(host: _host, sni: _sni));
    expect(jsonEncode(neither), jsonEncode(hostOnly));
  });

  test('a hostname outbound compiles with the DoH cascade unchanged', () {
    // The neither case rides the same compiled DNS as any hostname node.
    final plan = ConnectionCompiler.compile(
      settings: ConnectionSettings(trafficMode: TrafficMode.allVpn),
      entries: [
        ResolvedServer(
          id: 1,
          sourceId: 1,
          outbound: _build(const OneVpnServer(host: _host, sni: _sni)),
        ),
      ],
      regions: compilerCatalog,
      options: compilerOptions(),
    );

    final config = jsonDecode(plan.xrayJson) as Map<String, dynamic>;
    final outbound = (config['outbounds'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((o) => o['protocol'] == 'vless');
    expect((outbound['settings'] as Map)['address'], _host);
    // The standard in-tunnel DoH cascade, unperturbed by the provisioned node.
    expect(plan.xrayJson, contains('https://dns10.quad9.net/dns-query'));
    expect(plan.xrayJson, contains('https://1.1.1.1/dns-query'));
  });
}
