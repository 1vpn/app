// The flag assets and the flag code list are one set. A code with no asset
// has no flag. The US regional catalogue codes draw the US flag.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/location/flag.dart';

void main() {
  test('the shipped flag assets equal the flag code list', () {
    final assets = Directory('assets/onevpn/flags')
        .listSync()
        .whereType<File>()
        .map((file) => file.uri.pathSegments.last)
        .where((name) => name.endsWith('.svg'))
        .map((name) => name.substring(0, name.length - '.svg'.length))
        .toSet();
    // Anti-vacuity guard. The directory holds the flags.
    expect(assets, isNotEmpty);
    expect(assets, OneVpnFlag.codes);
  });

  test('a code with no asset has no flag', () {
    expect(OneVpnFlag.has('zz'), isFalse);
    expect(OneVpnFlag.has(null), isFalse);
    expect(OneVpnFlag.has('NL'), isTrue);
  });

  test('the US regional codes draw the US flag', () {
    for (final code in ['use', 'uss', 'usw', 'USW']) {
      expect(OneVpnFlag.has(code), isTrue, reason: code);
      expect(OneVpnFlag.assetCode(code), 'us', reason: code);
    }
    // Every alias names a shipped flag.
    expect(OneVpnFlag.codes, containsAll(OneVpnFlag.aliases.values.toSet()));
    expect(OneVpnFlag.assetCode('us'), 'us');
    expect(OneVpnFlag.assetCode('xx'), isNull);
    // The ISO code gb draws the pack's uk asset.
    expect(OneVpnFlag.assetCode('GB'), 'uk');
  });
}
