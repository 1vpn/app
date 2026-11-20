import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:onexray/core/constants/preferences.dart';
import 'package:onexray/core/db/database/database.dart';
import 'package:onexray/core/tools/logger.dart';
import 'package:onexray/service/connect/runtime.dart';
import 'package:onexray/service/connect/settings.dart';
import 'package:onexray/service/launch/app_startup.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A named correction applied on every boot. Corrections must be idempotent.
/// Every boot re-applies the whole list. Applying a correction twice must leave
/// the same state as applying it once.
final class BootCorrection {
  final String name;
  final Future<void> Function() apply;

  const BootCorrection({required this.name, required this.apply});
}

/// Stamps privacy acceptance on first boot, with no click-through.
///
/// Downloading the app is acceptance. This writes the acceptance flag when it
/// is unset, so no screen ever asks. It also suppresses connect-on-launch for
/// the first-boot pass. A fresh install never auto-connects before the shell
/// settles. On every later boot the flag is already set, and this does nothing.
final BootCorrection acceptPrivacyOnFirstBoot = BootCorrection(
  name: "accept privacy on first boot",
  apply: () async {
    final preferences = PreferencesKey();
    if (await preferences.readPrivacyAccepted()) return;
    AppStartupService().suppressConnectOnAppLaunch();
    await preferences.savePrivacyAccepted(true);
  },
);

/// The one-time flag that records the default-posture normalization ran. It
/// lives in the fork's own preference namespace, never upstream's.
const _postureNormalizedKey = 'onevpn.defaultPostureNormalized';

/// Rewrites a persisted upstream default to the fork default. An upgraded
/// install is then fully tunnelled like a fresh one. The upstream default is
/// smart with directRegions ['CN']. The fork default is allVpn with no direct
/// region. The rewrite runs once, guarded by a one-time flag. The picker maps a
/// CN choice to the same smart + ['CN'] shape. A per-boot rewrite would erase
/// that choice. A fresh store already parses to allVpn, and the rewrite leaves
/// it untouched.
Future<void> normalizeStoredPosture(AppDatabase db) async {
  final preferences = SharedPreferencesAsync();
  if (await preferences.getBool(_postureNormalizedKey) ?? false) return;
  final dao = db.connectionConfigDao;
  final stored = ConnectionConfiguration.fromJson(
    jsonDecode((await dao.read()).configurationJson) as Map<String, dynamic>,
  );
  final connection = stored.connection;
  final isUpstreamDefault =
      connection.trafficMode == TrafficMode.smart &&
      const ListEquality<String>().equals(
        connection.smart.directRegions,
        const ['CN'],
      );
  if (isUpstreamDefault) {
    final next = ConnectionConfiguration(
      connection: ConnectionSettings.fromJson({
        ...connection.toJson(),
        'trafficMode': TrafficMode.allVpn.name,
        'smart': {
          ...connection.smart.toJson(),
          'directRegions': const <String>[],
        },
      }),
      policy: stored.policy,
    );
    await dao.commit(configurationJson: next.encode());
  }
  await preferences.setBool(_postureNormalizedKey, true);
}

/// Carries the upstream default routing posture to the fork default on the
/// first boot after upgrade.
final BootCorrection normalizeDefaultPosture = BootCorrection(
  name: "normalize default routing posture",
  apply: () => normalizeStoredPosture(AppDatabase()),
);

/// The one-time flag that records the direct-region switch correction ran.
/// It lives in the fork's own preference namespace, never upstream's.
const _regionSwitchesClearedKey = 'onevpn.directRegionSwitchesCleared';

/// Turns the Apple and Windows switches off in a stored region pick. The
/// stored region then sends direct only its own names and the local-network
/// names, as a fresh pick does. The rewrite applies to smart with a direct
/// region and either switch on. Every other setting stays as stored, and so
/// does every other stored shape. The rewrite runs once, guarded by a
/// one-time flag. A second pass without the flag finds nothing to rewrite.
/// The launch refresh then brings a connected tunnel onto the stored routing.
/// Nothing retries a refresh that skips until the next launch.
Future<void> clearStoredRegionSwitches(AppDatabase db) async {
  final preferences = SharedPreferencesAsync();
  if (await preferences.getBool(_regionSwitchesClearedKey) ?? false) return;
  final dao = db.connectionConfigDao;
  final stored = ConnectionConfiguration.fromJson(
    jsonDecode((await dao.read()).configurationJson) as Map<String, dynamic>,
  );
  final connection = stored.connection;
  final smart = connection.smart;
  final carriesSwitches =
      connection.trafficMode == TrafficMode.smart &&
      smart.directRegions.isNotEmpty &&
      (smart.directApple || smart.directWindows);
  if (carriesSwitches) {
    final next = ConnectionConfiguration(
      connection: ConnectionSettings.fromJson({
        ...connection.toJson(),
        'smart': {
          ...smart.toJson(),
          'directApple': false,
          'directWindows': false,
        },
      }),
      policy: stored.policy,
    );
    await dao.commit(configurationJson: next.encode());
  }
  await preferences.setBool(_regionSwitchesClearedKey, true);
}

/// Carries a stored region pick to the region-only direct routing on the
/// first boot that finds the one-time flag unset.
final BootCorrection clearRegionSwitches = BootCorrection(
  name: "clear the direct-region switches",
  apply: () => clearStoredRegionSwitches(AppDatabase()),
);

/// The once-ever flag that records an upgrade from v2. It lives in the fork's
/// own preference namespace, never upstream's.
const upgradedFromV2Key = 'onevpn.upgradedFromV2';

/// Deletes v2's store from an install upgraded from v2.
///
/// v2's store is the MMKV store in the `mmkv` directory under the app's files
/// directory. The upgrade leaves it in place. The store is the sign of a v2
/// install that this correction uses.
///
/// The order is the contract. When the store exists, this sets
/// [upgradedFromV2Key] before it deletes the store. A later reader can then
/// rely on the flag. A failed flag write stops before the delete, and the next
/// boot retries both. A failed delete leaves the flag set and the store in
/// place, and the next boot deletes the store. Setting the flag again is
/// harmless. A fresh install has no store, so it gets no flag and no delete.
/// This touches nothing else under [filesDirectory].
Future<void> deleteV2Store(
  Directory filesDirectory,
  SharedPreferencesAsync preferences,
) async {
  final store = Directory(p.join(filesDirectory.path, 'mmkv'));
  if (!await store.exists()) return;
  await preferences.setBool(upgradedFromV2Key, true);
  await store.delete(recursive: true);
  ygLogger("boot correction deleted the v2 store");
}

/// Deletes v2's store on the first boot after the upgrade. The files
/// directory is the application support directory. On Android that is the
/// app's files directory, which holds v2's store.
final BootCorrection deleteV2StoreAfterUpgrade = BootCorrection(
  name: "delete the v2 store",
  apply: () async => deleteV2Store(
    await getApplicationSupportDirectory(),
    SharedPreferencesAsync(),
  ),
);

/// The production correction list. Corrections land here so blank-store
/// defaults reach fresh installs and upgraded installs alike.
final List<BootCorrection> bootCorrections = [
  acceptPrivacyOnFirstBoot,
  normalizeDefaultPosture,
  clearRegionSwitches,
  deleteV2StoreAfterUpgrade,
];

/// Applies every correction in order. A failing correction is logged and
/// skipped so one bad correction cannot block the rest of the list.
Future<void> applyBootDefaults(List<BootCorrection> corrections) async {
  for (final correction in corrections) {
    try {
      await correction.apply();
    } catch (error, stackTrace) {
      ygLogger(
        "boot correction ${correction.name} failed: $error\n$stackTrace",
      );
    }
  }
}
