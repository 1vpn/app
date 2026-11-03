// Pins the custom-geodata source cut at its call sites. Routing data
// reaches the app only as the bundled defaults and their pinned update
// downloads. The upstream service keeps its custom import API. No file the
// two app entries reach calls that API. The defaults publication is the one
// live path that inserts a geo_data row. The upstream geo_data table and
// its dao stay.

import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/core/db/database/database.dart';
import 'package:onexray/service/advanced/xray/geodata/service.dart';
import 'package:onexray/service/shared/event_bus/service.dart';
import 'package:path/path.dart' as p;

import 'support/lib_closure.dart';

const _service = 'lib/service/advanced/xray/geodata/service.dart';

/// The custom import API. Each member stages, writes, or deletes a custom
/// source.
const _customMembers = {
  'add',
  'updateAll',
  'updateCustom',
  'prepareImports',
  'deleteGeoDat',
};

/// The class member in [source] whose line starts with [signature] at a
/// two-space indent, through its closing brace at that indent.
String _member(String source, String signature) {
  final lines = source.split('\n');
  final start = lines.indexWhere((line) => line.startsWith('  $signature'));
  expect(start, isNot(-1), reason: 'the service lacks $signature');
  final end = lines.indexWhere((line) => line == '  }', start);
  expect(end, isNot(-1), reason: '$signature has no closing brace');
  return lines.sublist(start, end + 1).join('\n');
}

void main() {
  late Map<String, String> contents;

  setUpAll(() {
    contents = {
      for (final file in libClosureSources())
        file.path: file.readAsStringSync(),
    };
  });

  test('no reachable file calls the custom Geodata import API', () {
    // Anti-vacuity guard: the API and the dao are present, and both
    // scheduled update paths are in the closure.
    expect(contents[_service], contains('prepareImports('));
    expect(contents['lib/core/db/dao/geo_data.dart'], contains('GeoDataDao'));
    for (final path in const [
      'lib/service/advanced/xray/data_update/service.dart',
      'lib/service/shared/menu/tray/service.dart',
    ]) {
      expect(contents[path], contains('GeoDataService().updateDefaults()'));
    }
    final reference = RegExp(r'\bGeoDataService\b(?:\(\)\s*\.\s*(\w+))?');
    for (final entry in contents.entries) {
      if (entry.key == _service) continue;
      for (final match in reference.allMatches(entry.value)) {
        // Every reference is a call on the singleton. A stored or typed
        // reference could reach the API out of sight.
        final member = match.group(1);
        expect(
          member,
          isNotNull,
          reason: '${entry.key} holds a GeoDataService reference',
        );
        expect(
          _customMembers,
          isNot(contains(member)),
          reason: '${entry.key} calls GeoDataService().$member',
        );
      }
      for (final marker in const [
        'GeoDataImport',
        'prepareAssets',
        'GeoDataValidator',
      ]) {
        expect(
          entry.value,
          isNot(contains(marker)),
          reason:
              '${entry.key} reintroduces a custom Geodata source path '
              'via $marker',
        );
      }
    }
  });

  test('only the defaults publication inserts a live geo_data row', () {
    final service = contents[_service]!;
    final defaults = _member(service, 'Future<void> _publishDefaults(');
    final imports = _member(service, 'Future<GeoDataImport> prepareImports(');
    // Anti-vacuity guard: each member holds its insert.
    expect(defaults, contains('geoDataDao.insertRow('));
    expect(imports, contains('geoDataDao.insertRow('));
    // The import draft holds the one other insert. The test above keeps it
    // unreachable.
    expect(
      service.replaceFirst(defaults, '').replaceFirst(imports, ''),
      isNot(contains('geoDataDao.insertRow')),
    );
    for (final entry in contents.entries) {
      if (entry.key == _service) continue;
      expect(
        entry.value,
        isNot(contains('geoDataDao.insertRow')),
        reason: '${entry.key} inserts a geo_data row',
      );
    }
  });

  test(
    'the defaults update downloads exactly the two pinned sources',
    () async {
      final bus = AppEventBus();
      addTearDown(bus.close);
      final fixtures = await Directory('../references/onexray-tests').absolute
          .create(recursive: true);
      final workspace = await fixtures.createTemp('geodata-cut-');
      addTearDown(() => workspace.delete(recursive: true));
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final urls = <String>[];
      final service = GeoDataService.forTesting(
        database: db,
        directory: p.join(workspace.path, 'dat'),
        download: (url, file) async {
          urls.add(url);
          await file.writeAsString('updated');
        },
        count: (path, name, type) => File(p.join(path, '$name.json'))
            .writeAsString(
              jsonEncode({
                'categoryCount': 1,
                'ruleCount': 2,
                'codes': [
                  {'code': 'cn', 'ruleCount': 2},
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
      expect(urls, isEmpty, reason: 'installation is bundled, never fetched');

      await service.updateDefaults();

      expect(urls.toSet(), {
        'https://github.com/v2fly/geoip/releases/latest/download/geoip.dat',
        'https://github.com/v2fly/domain-list-community/releases/latest/'
            'download/dlc.dat',
      });
      expect(urls, hasLength(2));
      final rows = await db.geoDataDao.publishedRows;
      expect(rows.map((row) => row.id).toSet(), {-1, -2});
      expect(await db.geoDataDao.allRows, isEmpty);
    },
  );
}
