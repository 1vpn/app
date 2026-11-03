// The app-build guard for the free node IP literals.
//
// A build that carries the free triple needs a clean define that names every
// free host. The guard reads the define file alone, the one source the build
// passes to Flutter. Fixtures use placeholder triples, reserved hostnames, and
// RFC 5737 literals. No fixture reads env/local.json.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/catalogue/free_floor.dart';

import '../../../tool/check_free_node_ips.dart' as guard;

const _triple = <String, String>{
  'ONEVPN_UUID': 'test-uuid',
  'ONEVPN_PBK': 'test-pbk',
  'ONEVPN_SID': 'test-sid',
};

/// A define with a TEST-NET literal for every free host but [skip].
String _define({String? skip}) => <String>[
  for (final (i, host) in kOneVpnFreeHosts.indexed)
    if (host != skip) '$host=192.0.2.${i + 1}',
].join(',');

void main() {
  late Directory dir;
  late StringBuffer out;
  late StringBuffer err;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('free_node_ips_guard');
    addTearDown(() => dir.deleteSync(recursive: true));
    out = StringBuffer();
    err = StringBuffer();
  });

  /// Writes [defines] as the define file and returns its path.
  String file(Map<String, String> defines) {
    final path = '${dir.path}/local.json';
    File(path).writeAsStringSync(jsonEncode(defines));
    return path;
  }

  int run(String path) => guard.run([path], out: out, err: err);

  test('a build without the full triple passes with no define', () {
    expect(run('${dir.path}/absent.json'), 0);
    expect(
      run(file({'ONEVPN_UUID': 'test-uuid', 'ONEVPN_PBK': 'test-pbk'})),
      0,
    );
    expect(out.toString(), contains('free triple not set'));
    expect(err.toString(), isEmpty);
  });

  test('the triple with an empty define fails', () {
    expect(run(file({..._triple, 'ONEVPN_FREE_NODE_IPS': ''})), 1);
    expect(err.toString(), contains('ONEVPN_FREE_NODE_IPS is empty'));
  });

  test('the triple with a host missing fails and names it', () {
    final missing = kOneVpnFreeHosts.last;
    final path = file({
      ..._triple,
      'ONEVPN_FREE_NODE_IPS': _define(skip: missing),
    });

    expect(run(path), 1);
    expect(err.toString(), contains('names no literal for $missing'));
    expect('$out$err', isNot(contains('192.0.2.')));
  });

  test('a complete define passes in any letter case', () {
    final define = _define().toUpperCase();

    expect(run(file({..._triple, 'ONEVPN_FREE_NODE_IPS': define})), 0);
    expect(out.toString(), contains('names all 6 free hosts'));
    expect(err.toString(), isEmpty);
  });

  test('a rejected or unknown entry fails without printing an address', () {
    final define = '${_define()},192.0.2.9,other.example.invalid=192.0.2.8';

    expect(run(file({..._triple, 'ONEVPN_FREE_NODE_IPS': define})), 1);
    expect(err.toString(), contains('rejects entry 7'));
    expect(err.toString(), contains('unknown host other.example.invalid'));
    expect('$out$err', isNot(contains('192.0.2.')));
  });

  test('the guard never reads the environment', () {
    // The build passes the define file alone to Flutter. A value set only in
    // the environment never reaches the app, so it never counts here.
    final source = File('tool/check_free_node_ips.dart').readAsStringSync();

    expect(source, isNot(contains('Platform.environment')));
    expect(source, isNot(contains('environment:')));
  });

  test('a define file that is not JSON fails without echoing it', () {
    final path = '${dir.path}/local.json';
    File(path).writeAsStringSync('ONEVPN_UUID=test-secret-value');

    expect(run(path), 1);
    expect(err.toString(), contains('is not a JSON object'));
    expect('$out$err', isNot(contains('test-secret-value')));
  });
}
