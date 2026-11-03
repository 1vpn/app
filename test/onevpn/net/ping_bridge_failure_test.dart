// Pins the bridge-failure skip. A batch the bridge failed to measure leaves
// its rows unmeasured, so the backlog probes them again. A measured timeout
// still records its delay.

import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/core/db/database/constants.dart';
import 'package:onexray/core/db/database/database.dart';
import 'package:onexray/service/shared/event_bus/service.dart';
import 'package:onexray/service/shared/ping/batch.dart';
import 'package:onexray/service/shared/ping/service.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final bus = AppEventBus();
    addTearDown(bus.close);
    db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
  });

  test('a bridge failure leaves the batch rows unmeasured', () async {
    // A wedged or expired native invoke makes PingBatchRunner return an
    // all-failed batch that measured nothing. Those rows stay unmeasured, not
    // painted error, so the backlog re-probes them.
    final first = await db.coreConfigDao.insertRow(_node('First'));
    final second = await db.coreConfigDao.insertRow(_node('Second'));
    final service = PingService.forTesting(
      database: db,
      runBatch: (sources, _) async => [
        for (final _ in sources) PingBatchResult.failed('bridge wedged'),
      ],
    );

    await service.pingConfigIds([first, second]);

    for (final id in [first, second]) {
      final row = (await db.coreConfigDao.searchRow(id))!;
      expect(row.delay, PingDelayConstants.unknown);
      expect(PingService.isUnmeasured(row), isTrue);
    }
  });

  test('a real probe timeout still records its delay', () async {
    // The bridge-failure skip must not swallow a measured failure: a native
    // response carrying a timeout is real evidence and stays persisted.
    final id = await db.coreConfigDao.insertRow(_node('Timed out'));
    final service = PingService.forTesting(
      database: db,
      runBatch: (_, _) async => const [
        PingBatchResult(false, PingDelayConstants.timeout, 'timeout'),
      ],
    );

    await service.pingConfigIds([id]);

    final row = (await db.coreConfigDao.searchRow(id))!;
    expect(row.delay, PingDelayConstants.timeout);
    expect(PingService.isUnmeasured(row), isFalse);
  });
}

CoreConfigCompanion _node(String name, {int subId = 0}) =>
    CoreConfigCompanion.insert(
      name: name,
      type: 'outbound',
      tags: 'socks',
      delay: PingDelayConstants.unknown,
      subId: subId,
      data: Value(
        base64Encode(
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
      ),
    );
