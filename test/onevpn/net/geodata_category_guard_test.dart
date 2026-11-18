// The geodata refresh refuses a geosite list that lacks a category the
// smart-mode compiler names. A refused list keeps the installed files and
// rows, and the backoff counts it as a failed refresh.

import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/core/db/database/database.dart';
import 'package:onexray/core/model/geo_dat.dart';
import 'package:onexray/core/model/geo_data_type.dart';
import 'package:onexray/onevpn/net/geodata_category_guard.dart';
import 'package:onexray/onevpn/net/geodata_refresh_backoff.dart';
import 'package:onexray/service/advanced/xray/geodata/service.dart';
import 'package:onexray/service/shared/event_bus/service.dart';
import 'package:path/path.dart' as p;
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

XrayGeoList _index(Iterable<String> codes, {int ruleCount = 1}) => XrayGeoList(
  [for (final code in codes) XrayGeoListCodes(code, ruleCount)],
  codes.length,
  codes.length * ruleCount,
);

void main() {
  late Directory workspace;
  late Directory datRoot;
  late AppDatabase db;
  late GeoDataService service;
  late String revision;
  late Set<String> downloadedCodes;

  Future<Map<String, String>> rootFiles() async => {
    await for (final entry in datRoot.list(followLinks: false))
      if (entry is File) p.basename(entry.path): await entry.readAsString(),
  };

  Future<List<String>> stages() async => [
    await for (final entry in workspace.list(followLinks: false))
      if (p.basename(entry.path).startsWith('.onexray-geodata-'))
        p.basename(entry.path),
  ];

  setUp(() async {
    final bus = AppEventBus();
    addTearDown(bus.close);
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    workspace = await Directory.systemTemp.createTemp('onevpn-geodata-');
    addTearDown(() => workspace.delete(recursive: true));
    datRoot = Directory(p.join(workspace.path, 'dat'));
    db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    revision = 'bundled';
    downloadedCodes = {...kOneVpnRequiredGeositeCategories};
    service = GeoDataService.forTesting(
      database: db,
      directory: datRoot.path,
      download: (url, file) => file.writeAsString(revision),
      count: (path, name, type) async {
        // The bundled pair always carries every category. A download
        // carries [downloadedCodes].
        final data = await File(p.join(path, '$name.dat')).readAsString();
        final codes = type == GeoDataType.ip
            ? {'CN'}
            : data == 'bundled'
            ? kOneVpnRequiredGeositeCategories
            : downloadedCodes;
        await File(p.join(path, '$name.json'))
            .writeAsString(jsonEncode(_index(codes).toJson()));
      },
      copyBundled: (path) async {
        for (final name in ['geoip', 'geosite']) {
          await File(p.join(path, '$name.dat')).writeAsString('bundled');
        }
        await File(p.join(path, 'timestamp.txt')).writeAsString('123');
      },
    );
    await service.ensureInstalled();
  });

  test('the required set is the five geosite categories the compiler names '
      'with ad blocking off', () {
    expect(kOneVpnRequiredGeositeCategories, {
      'PRIVATE',
      'APPLE',
      'MICROSOFT',
      'BING',
      'GITHUB',
    });
  });

  test('the check matches codes in any case and needs a rule each', () {
    oneVpnCheckGeositeCategories(
      _index(kOneVpnRequiredGeositeCategories.map((c) => c.toLowerCase())),
    );
    expect(
      () => oneVpnCheckGeositeCategories(
        _index(kOneVpnRequiredGeositeCategories, ruleCount: 0),
      ),
      throwsFormatException,
    );
  });

  test('a list lacking one category is refused and the installed files '
      'stay', () async {
    for (final missing in kOneVpnRequiredGeositeCategories) {
      final files = await rootFiles();
      final rows = await db.geoDataDao.publishedRows;
      revision = 'refreshed';
      downloadedCodes = {...kOneVpnRequiredGeositeCategories}..remove(missing);
      await expectLater(
        service.updateDefaults(),
        throwsFormatException,
        reason: missing,
      );
      expect(await rootFiles(), files, reason: missing);
      expect(files['geosite.dat'], 'bundled');
      expect(await db.geoDataDao.publishedRows, rows, reason: missing);
      expect(await stages(), isEmpty, reason: missing);
      expect(await service.publishedFiles(), hasLength(2));
    }
  });

  test('a complete list is accepted and replaces the installed pair', () async {
    revision = 'refreshed';
    await service.updateDefaults();
    final files = await rootFiles();
    expect(files['geosite.dat'], 'refreshed');
    expect(files['geoip.dat'], 'refreshed');
    expect(await stages(), isEmpty);
  });

  test('the backoff counts a refused list as a failed refresh', () async {
    final now = DateTime.utc(2026, 11, 4, 9);
    final backoff = OneVpnGeoDataBackoff(now: () => now);
    revision = 'refreshed';
    downloadedCodes = {...kOneVpnRequiredGeositeCategories}..remove('GITHUB');
    await expectLater(
      backoff.run(service.updateDefaults),
      throwsFormatException,
    );
    expect(
      await SharedPreferencesAsync().getInt(OneVpnGeoDataBackoff.notBeforeKey),
      now.add(kOneVpnGeoDataRetryAfter).millisecondsSinceEpoch,
    );
    expect((await rootFiles())['geosite.dat'], 'bundled');
  });
}
