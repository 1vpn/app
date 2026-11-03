// Contract for the boot defaults mechanism. Every boot applies every named
// correction in the list. Corrections are idempotent, so a second boot
// leaves state identical. One failing correction cannot block the rest of
// the list. The production list holds three real corrections: "accept
// privacy on first boot", "normalize default routing posture" and "delete
// the v2 store". This suite exercises all three. Fake corrections cover the
// mechanism in isolation.

import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/core/constants/preferences.dart';
import 'package:onexray/core/db/database/database.dart';
import 'package:onexray/onevpn/boot/defaults.dart';
import 'package:onexray/service/connect/runtime.dart';
import 'package:onexray/service/connect/settings.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'a correction applies on first boot and re-applies harmlessly',
    () async {
      // Stands in for a preference store. The correction seeds a default
      // only where no value exists. Real corrections must take this
      // idempotent shape.
      final store = <String, String>{};
      var applyCount = 0;
      final correction = BootCorrection(
        name: "seed example default",
        apply: () async {
          applyCount += 1;
          store.putIfAbsent("mode", () => "safe-default");
        },
      );
      await applyBootDefaults([correction]);

      // Anti-vacuity guard. The correction really ran and really changed
      // state on the first boot.
      expect(applyCount, 1);
      expect(store, {"mode": "safe-default"});
      final stateAfterFirstBoot = Map.of(store);

      await applyBootDefaults([correction]);

      expect(applyCount, 2);
      expect(store, stateAfterFirstBoot);
    },
  );

  test('a failing correction is skipped and the rest still apply', () async {
    final applied = <String>[];
    final corrections = [
      BootCorrection(
        name: "broken",
        apply: () async {
          applied.add("broken:reached");
          throw StateError("correction sabotage");
        },
      ),
      BootCorrection(
        name: "healthy",
        apply: () async => applied.add("healthy"),
      ),
    ];

    await applyBootDefaults(corrections);

    // Anti-vacuity guard. The failing correction really started.
    expect(applied, contains("broken:reached"));
    expect(applied, contains("healthy"));
  });

  // Corrections enter through review, one named entry at a time. An entry
  // appearing here must arrive with its own test.
  test('the production correction list is the reviewed set', () {
    expect(bootCorrections.map((correction) => correction.name).toList(), [
      "accept privacy on first boot",
      "normalize default routing posture",
      "delete the v2 store",
    ]);
  });

  group('normalize default routing posture', () {
    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
    });

    AppDatabase openDatabase() {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      return db;
    }

    Future<void> seed(AppDatabase db, TrafficMode mode, List<String> regions) =>
        db.connectionConfigDao.commit(
          configurationJson: ConnectionConfiguration(
            connection: ConnectionSettings(
              trafficMode: mode,
              smart: SmartRoutingSettings(directRegions: regions),
            ),
          ).encode(),
        );

    Future<ConnectionSettings> read(AppDatabase db) async =>
        ConnectionConfiguration.fromJson(
          jsonDecode((await db.connectionConfigDao.read()).configurationJson)
              as Map<String, dynamic>,
        ).connection;

    test('rewrites the old smart+[CN] default to allVpn+[] once', () async {
      final db = openDatabase();
      await seed(db, TrafficMode.smart, const ['CN']);

      await normalizeStoredPosture(db);
      var connection = await read(db);
      expect(connection.trafficMode, TrafficMode.allVpn);
      expect(connection.smart.directRegions, isEmpty);

      // A second pass leaves the normalized value unchanged.
      await normalizeStoredPosture(db);
      connection = await read(db);
      expect(connection.trafficMode, TrafficMode.allVpn);
      expect(connection.smart.directRegions, isEmpty);
    });

    test('a later deliberate CN selection survives', () async {
      final db = openDatabase();

      // First boot has nothing to migrate. The run-once flag is set.
      await normalizeStoredPosture(db);
      // The picker maps a CN choice to smart + [CN], the old default's shape.
      await seed(db, TrafficMode.smart, const ['CN']);

      await normalizeStoredPosture(db);
      final connection = await read(db);
      expect(connection.trafficMode, TrafficMode.smart);
      expect(connection.smart.directRegions, ['CN']);
    });

    test('a fresh empty store is left untouched', () async {
      final db = openDatabase();
      await normalizeStoredPosture(db);
      expect((await db.connectionConfigDao.read()).configurationJson, '{}');
    });
  });

  group('accept privacy on first boot', () {
    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
    });

    test('stamps acceptance when unset and re-applies harmlessly', () async {
      // Anti-vacuity guard. A fresh install starts not accepted.
      expect(await PreferencesKey().readPrivacyAccepted(), isFalse);

      await acceptPrivacyOnFirstBoot.apply();
      expect(await PreferencesKey().readPrivacyAccepted(), isTrue);

      // Idempotent: a second boot leaves the flag set and does not throw.
      await acceptPrivacyOnFirstBoot.apply();
      expect(await PreferencesKey().readPrivacyAccepted(), isTrue);
    });

    test('leaves an already-accepted install unchanged', () async {
      await PreferencesKey().savePrivacyAccepted(true);
      await acceptPrivacyOnFirstBoot.apply();
      expect(await PreferencesKey().readPrivacyAccepted(), isTrue);
    });
  });

  group('delete the v2 store', () {
    late Directory files;
    late Directory store;
    late File neighbour;

    // The flag write the order pin expects: the flag set while the store is
    // still on disk.
    const flagBeforeDelete = (
      key: upgradedFromV2Key,
      value: true,
      storePresent: true,
    );

    setUp(() async {
      files = await Directory.systemTemp.createTemp('onevpn-files-');
      addTearDown(() => files.delete(recursive: true));
      store = Directory(p.join(files.path, 'mmkv'));
      // The preferences live beside the store. The correction leaves them.
      neighbour = File(p.join(files.path, 'datastore', 'preferences'));
      await neighbour.create(recursive: true);
    });

    // Stands in for v2's store: the directory and two files in it.
    Future<void> seedStore() async {
      await File(p.join(store.path, 'MAIN')).create(recursive: true);
      await File(p.join(store.path, 'MAIN.crc')).create();
    }

    test('sets the flag while the store exists, then deletes it', () async {
      await seedStore();
      final preferences = _RecordingPreferences(store);

      await deleteV2Store(files, preferences);

      expect(preferences.writes, [flagBeforeDelete]);
      expect(store.existsSync(), isFalse);
      expect(neighbour.existsSync(), isTrue);

      // A later boot finds no store and does nothing.
      await deleteV2Store(files, preferences);
      expect(preferences.writes, [flagBeforeDelete]);
    });

    test('a fresh install gets no flag and no delete', () async {
      final preferences = _RecordingPreferences(store);

      await deleteV2Store(files, preferences);

      expect(preferences.writes, isEmpty);
      expect(neighbour.existsSync(), isTrue);
    });

    test('a failed delete keeps the flag, and the next boot deletes', () async {
      await seedStore();
      final preferences = _RecordingPreferences(store);

      await expectLater(
        IOOverrides.runZoned(
          () => deleteV2Store(files, preferences),
          createDirectory: _UndeletableDirectory.new,
        ),
        throwsA(isA<FileSystemException>()),
      );
      expect(preferences.writes, [flagBeforeDelete]);
      expect(store.existsSync(), isTrue);

      // The store is still there, so the next boot deletes it. The second
      // flag write is harmless.
      await deleteV2Store(files, preferences);
      expect(store.existsSync(), isFalse);
      expect(preferences.writes, [flagBeforeDelete, flagBeforeDelete]);
    });

    test('a failed flag write keeps the store for the next boot', () async {
      await seedStore();

      await expectLater(
        deleteV2Store(files, _RecordingPreferences(store, refuseWrites: true)),
        throwsA(isA<StateError>()),
      );
      expect(store.existsSync(), isTrue);

      // The next boot retries both: the flag first, then the delete.
      final preferences = _RecordingPreferences(store);
      await deleteV2Store(files, preferences);
      expect(preferences.writes, [flagBeforeDelete]);
      expect(store.existsSync(), isFalse);
    });
  });
}

/// Records each flag write with whether the store was still on disk at that
/// moment. The record pins the order: the flag first, the delete second. With
/// [refuseWrites], every write throws and records nothing.
final class _RecordingPreferences extends Fake
    implements SharedPreferencesAsync {
  _RecordingPreferences(this._store, {this.refuseWrites = false});

  final Directory _store;
  final bool refuseWrites;
  final writes = <({String key, bool value, bool storePresent})>[];

  @override
  Future<void> setBool(String key, bool value) async {
    if (refuseWrites) throw StateError('flag write refused');
    writes.add((key: key, value: value, storePresent: _store.existsSync()));
  }
}

/// A store whose delete fails, as a store on a failing disk would. Its
/// existence check reads the disk.
final class _UndeletableDirectory extends Fake implements Directory {
  _UndeletableDirectory(this.path);

  @override
  final String path;

  @override
  Future<bool> exists() => FileSystemEntity.isDirectory(path);

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) =>
      Future.error(FileSystemException('delete refused', path));
}
