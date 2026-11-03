// Pins the location selection. A location scopes resolution to the rows
// that share its name stem. Automatic ranks every row by delay, then by id.
// The selection round-trips through JSON.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/core/db/database/constants.dart';
import 'package:onexray/core/db/database/database.dart';
import 'package:onexray/service/connect/resolver.dart';
import 'package:onexray/service/connect/settings.dart';

void main() {
  test(
    'a location selection scopes to the rows sharing its name stem',
    () async {
      final rows = [
        _row(1, delay: 40, name: '1vpn·free·ams·1'),
        _row(2, delay: 10, name: '1vpn·free·ams·2'),
        // A sibling code that shares the stem's prefix but not the stem: the
        // trailing separator must keep it out of scope.
        _row(3, delay: 1, name: '1vpn·free·ams2·1'),
        _row(4, delay: 5, name: '1vpn·acct·nrt·1'),
      ];
      final resolver = _oneShot(rows);
      final resolved = await resolver.resolve(
        ConnectionSettings(
          selection: const ServerSelection.location('1vpn·free·ams'),
        ),
      );
      // Only the two Amsterdam rows are eligible. The healthier one wins.
      expect(resolved.single.id, 2);
      await expectLater(
        _oneShot(rows).resolve(
          ConnectionSettings(
            selection: const ServerSelection.location('1vpn·free·nowhere'),
          ),
        ),
        _fails(ConnectionResolutionFailure.selectionUnavailable),
      );
    },
  );

  test(
    'Automatic picks the lowest-latency reachable node, ties broken by id',
    () async {
      // The documented automatic server choice: every provisioned row is in
      // scope. Successful rows sort by delay, then by id. The resolver takes
      // the healthiest. Rows 2 and 3 tie on delay, so the lower id wins.
      final resolver = _oneShot([
        _row(1, delay: 90),
        _row(2, delay: 10),
        _row(3, delay: 10),
        _row(4, delay: PingDelayConstants.timeout),
      ]);
      final resolved = await resolver.resolve(
        ConnectionSettings(selection: const ServerSelection.automatic()),
      );
      expect(resolved.single.id, 2);
    },
  );

  test('a location selection round-trips through JSON', () {
    const selection = ServerSelection.location('1vpn·acct·nrt');
    final restored = ServerSelection.fromJson(selection.toJson());
    expect(restored.kind, SelectionKind.location);
    expect(restored.location, '1vpn·acct·nrt');
  });
}

ConnectionResolver _oneShot(List<CoreConfigData> rows) => ConnectionResolver(
  rows: () => Stream.value(rows),
  probe: (_) async {
    fail('This selection must not probe');
  },
);

Matcher _fails(ConnectionResolutionFailure reason) => throwsA(
  isA<ConnectionResolutionException>().having(
    (error) => error.reason,
    'reason',
    reason,
  ),
);

CoreConfigData _row(
  int id, {
  int delay = 10,
  int source = 0,
  String region = 'US',
  String type = 'outbound',
  String name = 'Same name',
}) => CoreConfigData(
  id: id,
  name: name,
  type: type,
  tags: 'socks',
  delay: delay,
  subId: source,
  countryCode: region,
  favorite: false,
  data: base64Encode(
    utf8.encode(
      jsonEncode({
        'outbounds': [
          {
            'tag': name,
            'protocol': 'socks',
            'settings': {'address': '127.0.0.1', 'port': 1080},
          },
        ],
      }),
    ),
  ),
);
