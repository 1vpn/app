// A geodata refresh replaces each installed file in one rename. A reader of
// the dat directory at any instant sees the old or the new file, never a
// missing one.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/core/db/database/database.dart';
import 'package:onexray/core/model/geo_data_type.dart';
import 'package:onexray/onevpn/net/geodata_category_guard.dart';
import 'package:onexray/service/advanced/xray/geodata/service.dart';
import 'package:onexray/service/shared/event_bus/service.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory workspace;
  late Directory datRoot;
  late AppDatabase db;
  late GeoDataService service;
  var revision = 'bundled';

  setUp(() async {
    final bus = AppEventBus();
    addTearDown(bus.close);
    workspace = await Directory.systemTemp.createTemp('onevpn-geodata-swap-');
    addTearDown(() => workspace.delete(recursive: true));
    datRoot = Directory(p.join(workspace.path, 'dat'));
    db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    revision = 'bundled';
    service = GeoDataService.forTesting(
      database: db,
      directory: datRoot.path,
      download: (url, file) => file.writeAsString(revision),
      count: (path, name, type) =>
          File(p.join(path, '$name.json')).writeAsString(
            jsonEncode({
              'categoryCount': 1,
              'ruleCount': 1,
              'codes': [
                if (type == GeoDataType.ip) {'code': 'CN', 'ruleCount': 1},
                if (type == GeoDataType.domain)
                  for (final code in kOneVpnRequiredGeositeCategories)
                    {'code': code, 'ruleCount': 1},
              ],
            }),
          ),
      copyBundled: (path) async {
        for (final name in ['geoip', 'geosite']) {
          await File(p.join(path, '$name.dat')).writeAsString('bundled');
        }
        await File(p.join(path, 'timestamp.txt')).writeAsString('123');
      },
    );
    await service.ensureInstalled();
  });

  const names = ['geoip.dat', 'geosite.dat', 'geoip.json', 'geosite.json'];

  /// What a reader sees of each installed file while [action] runs: the
  /// bytes of a dat file, `index` for an index, or `missing`.
  Future<Map<String, Set<String>>> watch(Future<void> Function() action) async {
    final seen = <String, Set<String>>{for (final name in names) name: {}};
    var samples = 0;
    // Reads synchronously on every event-loop turn, between the swap's
    // asynchronous file steps.
    final poller = Timer.periodic(Duration.zero, (_) {
      samples++;
      for (final name in names) {
        final file = File(p.join(datRoot.path, name));
        try {
          seen[name]!.add(
            file.existsSync()
                ? (name.endsWith('.dat') ? file.readAsStringSync() : 'index')
                : 'missing',
          );
        } on PathNotFoundException {
          // The file left between the existence check and the read.
          seen[name]!.add('missing');
        }
      }
    });
    try {
      await action();
    } finally {
      poller.cancel();
    }
    expect(samples, greaterThan(0));
    for (final name in names) {
      expect(seen[name], isNot(contains('missing')), reason: name);
    }
    return seen;
  }

  test('a read during a refresh swap sees old or new bytes, never a missing '
      'file', () async {
    final seen = await watch(() async {
      for (final next in ['two', 'three', 'four']) {
        revision = next;
        await service.updateDefaults();
      }
    });
    expect(seen['geosite.dat'], containsAll(['two', 'three', 'four']));
    expect(
      File(p.join(datRoot.path, 'geosite.dat')).readAsStringSync(),
      'four',
    );
  });

  test('a read during a refresh rollback sees old or new bytes, never a '
      'missing file', () async {
    // The default rows refuse every update, so each refresh swaps its files
    // in and then rolls them back.
    await db.customStatement(
      'CREATE TRIGGER fail_default BEFORE UPDATE ON geo_data '
      'WHEN OLD.id < 0 BEGIN SELECT RAISE(FAIL, \'fixture\'); END',
    );
    final rows = await db.geoDataDao.publishedRows;
    final seen = await watch(() async {
      for (final next in ['two', 'three', 'four']) {
        revision = next;
        await expectLater(service.updateDefaults(), throwsA(anything));
      }
    });
    expect(seen['geosite.dat'], contains('bundled'));
    for (final name in ['geoip.dat', 'geosite.dat']) {
      expect(
        File(p.join(datRoot.path, name)).readAsStringSync(),
        'bundled',
        reason: name,
      );
    }
    expect(await db.geoDataDao.publishedRows, rows);
  });
}
