// Pins the candidate tag scheme and the two rule tags. A candidate tag
// carries the row's tier and id, and the id round-trips. A string outside
// the scheme has no id and is not an account tag.

import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/connect/native_auto_contracts.dart';
import 'package:onexray/service/connect/compiler.dart';

void main() {
  test('the candidate prefix is app-cand-', () {
    expect(OneVpnCandidateTags.prefix, 'app-cand-');
  });

  test('an account row takes the account segment and round-trips', () {
    final tag = OneVpnCandidateTags.tagFor(_server(17, '1vpn·acct·ams·1'));
    expect(tag, 'app-cand-acct-17');
    expect(tag, startsWith(OneVpnCandidateTags.prefix));
    expect(OneVpnCandidateTags.idOf(tag), 17);
    expect(OneVpnCandidateTags.isAccount(tag), isTrue);
  });

  test('a free row takes the free segment and round-trips', () {
    final tag = OneVpnCandidateTags.tagFor(_server(3, '1vpn·free·ams·1'));
    expect(tag, 'app-cand-free-3');
    expect(tag, startsWith(OneVpnCandidateTags.prefix));
    expect(OneVpnCandidateTags.idOf(tag), 3);
    expect(OneVpnCandidateTags.isAccount(tag), isFalse);
  });

  test('a row outside the free prefix takes the account segment', () {
    final tag = OneVpnCandidateTags.tagFor(_server(5, 'hand-added'));
    expect(tag, 'app-cand-acct-5');
    expect(OneVpnCandidateTags.idOf(tag), 5);
    expect(OneVpnCandidateTags.isAccount(tag), isTrue);
  });

  test('a string outside the scheme has no id and is not an account', () {
    for (final tag in const [
      'app-entry-0',
      'block',
      'direct',
      'app-cand-',
      'app-cand-acct-',
      'app-cand-free-',
      'app-cand-acct-x',
      'app-cand-acct-017',
      'app-cand-acct-+5',
      'app-cand-free-3 ',
      'app-cand-other-5',
    ]) {
      expect(OneVpnCandidateTags.idOf(tag), isNull, reason: tag);
      expect(OneVpnCandidateTags.isAccount(tag), isFalse, reason: tag);
    }
  });

  test('the rule tags spell app-measure-block and app-catch-all', () {
    expect(oneVpnMeasureBlockRuleTag, 'app-measure-block');
    expect(oneVpnCatchAllRuleTag, 'app-catch-all');
  });
}

ResolvedServer _server(int id, String name) => ResolvedServer(
  id: id,
  sourceId: 0,
  outbound: {'tag': name, 'protocol': 'vless'},
);
