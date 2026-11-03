// Writes the 1vpn catalogue into the config database.
//
// The provisioner builds on the outbound primitive `outboundCompanion` and the
// core config dao, and edits no upstream file. It stores nodes as
// `CoreConfigType.outbound`. The runtime builds the config around them, and the
// connect screen and the tray see them through `ServerCatalog.watch`.
//
// Each sync rewrites every row it provisions. Row names derive from the
// location code ([OneVpnLocation.rowName]). A rewrite overwrites the row of
// the same name, so a row keeps its id across syncs. The native connect pins
// and reloads by row id.

import 'package:onexray/core/db/database/database.dart';
import 'package:onexray/core/db/database/enum.dart';
import 'package:onexray/core/tools/logger.dart';
import 'package:onexray/onevpn/account/session.dart';
import 'package:onexray/onevpn/catalogue/free_floor.dart';
import 'package:onexray/onevpn/catalogue/free_node_ips.dart';
import 'package:onexray/onevpn/catalogue/location.dart';
import 'package:onexray/onevpn/catalogue/node_catalog.dart';
import 'package:onexray/onevpn/model/user_data.dart';
import 'package:onexray/onevpn/provision/outbound_builder.dart';
import 'package:onexray/service/servers/outbound/state_db.dart';

/// The all-empty triple a signed-out or credential-less session presents.
const _noCredentials = OneVpnCredentials(uuid: '', publicKey: '', shortId: '');

/// One provisioned node: a catalogue entry paired with its database row id.
class OneVpnNode {
  const OneVpnNode({
    required this.configId,
    required this.location,
    required this.server,
    required this.rowName,
  });

  final int configId;
  final OneVpnLocation location;
  final OneVpnServer server;
  final String rowName;
}

/// What one sync wrote: the runnable nodes and the errors it recorded.
class OneVpnProvisionResult {
  const OneVpnProvisionResult({required this.nodes, required this.errors});

  final List<OneVpnNode> nodes;
  final List<String> errors;
}

class OneVpnNodeProvisioner {
  OneVpnNodeProvisioner({
    AppDatabase? database,
    this.catalog = const OneVpnStaticCatalog(),
  }) : _db = database ?? AppDatabase();

  final AppDatabase _db;
  final OneVpnNodeCatalog catalog;

  /// Provisions the catalogue derived from [session]: the free floor for a
  /// signed-out or free session, the account's locations beside the floor for a
  /// premium one. It is idempotent, so boot and the reload owner both call it
  /// to rebuild.
  ///
  /// Account nodes take the session's triple. Floor nodes take the triple of
  /// [oneVpnFreeFloor] for the session: the user data's for a signed-in free
  /// session whose free tier is complete, the build-time one otherwise. A
  /// null or credential-less session provisions the floor alone.
  Future<OneVpnProvisionResult> provisionForSession(OneVpnSession? session) =>
      sync(
        session?.credentials ?? _noCredentials,
        freeCredentials: oneVpnFreeFloor(session).credentials,
        catalogOverride: OneVpnSessionCatalog(session),
      );

  /// Builds every catalogue node's config and writes it over the row of the
  /// same name, or into a new row. Deletes ours that the catalogue dropped.
  /// Returns what is now runnable.
  ///
  /// Account nodes take [credentials]. Nodes from the compiled-in free
  /// catalogue take [freeCredentials] when given. The two triples are not
  /// interchangeable. A premium account sees the free nodes alongside its own.
  /// A free node rejects the account's REALITY triple, and its tunnel then
  /// carries nothing. The sync skips and records a node with an incomplete
  /// credential, and never substitutes another. The sync skips and records a
  /// free node with no IP literal the same way. A free node never dials its
  /// hostname. The sync deletes the row of a free node with no literal, even
  /// when nothing provisions.
  ///
  /// The sync runs in one transaction, so two overlapping syncs never write
  /// the same name twice. It deletes every repeat of a provisioned name and
  /// keeps the row with the lowest id.
  Future<OneVpnProvisionResult> sync(
    OneVpnCredentials credentials, {
    OneVpnCredentials? freeCredentials,
    OneVpnNodeCatalog? catalogOverride,
  }) async {
    final locations = await (catalogOverride ?? catalog).locations();
    return _db.transaction(
      () => _write(locations, credentials, freeCredentials),
    );
  }

  Future<OneVpnProvisionResult> _write(
    List<OneVpnLocation> locations,
    OneVpnCredentials credentials,
    OneVpnCredentials? freeCredentials,
  ) async {
    final rows = await _outboundRows()
      ..sort((a, b) => a.id.compareTo(b.id));
    // The lowest id holds each name.
    final existing = <String, CoreConfigData>{};
    for (final row in rows) {
      existing.putIfAbsent(row.name, () => row);
    }

    final nodes = <OneVpnNode>[];
    final errors = <String>[];
    // The row names of free nodes with no IP literal.
    final hostOnly = <String>{};

    for (final location in locations) {
      for (var i = 0; i < location.servers.length; i++) {
        final server = location.servers[i];
        final name = location.rowName(i);
        final noLiteral =
            location.freeTier && server.ip == null && server.ip6 == null;
        if (noLiteral) hostOnly.add(name);

        // Each node picks its own triple.
        final creds = location.freeTier
            ? (freeCredentials ?? credentials)
            : credentials;
        if (!creds.isComplete) {
          final message = location.freeTier
              ? _freeUnconfiguredError
              : 'No usable credentials for ${location.city}.';
          if (!errors.contains(message)) errors.add(message);
          continue;
        }
        if (noLiteral) {
          final message = _freeNoLiteralError(server.host);
          if (!errors.contains(message)) errors.add(message);
          continue;
        }

        final companion = outboundCompanion(
          OneVpnOutboundBuilder.build(server: server, credentials: creds),
          databaseName: name,
        );
        final prior = existing[name];
        if (prior != null) {
          await _db.coreConfigDao.updateRow(
            prior.copyWith(tags: companion.tags.value, data: companion.data),
          );
        }
        final configId =
            prior?.id ?? await _db.coreConfigDao.insertRow(companion);

        nodes.add(
          OneVpnNode(
            configId: configId,
            location: location,
            server: server,
            rowName: name,
          ),
        );
      }
    }

    // Deletes our repeated rows and our rows the catalogue no longer
    // contains. A sync that provisions nothing deletes only the repeats and
    // the free rows with no literal: an empty catalogue is a failure to load.
    final keep = {for (final node in nodes) node.rowName};
    for (final row in rows) {
      if (!row.name.startsWith(OneVpnLocation.rowNamePrefix)) continue;
      final repeat = existing[row.name]!.id != row.id;
      final dropped = nodes.isEmpty
          ? hostOnly.contains(row.name)
          : !keep.contains(row.name);
      if (repeat || dropped) await _db.coreConfigDao.deleteRow(row);
    }

    return OneVpnProvisionResult(nodes: nodes, errors: errors);
  }

  /// Sign-out: delete the account rows, leaving the free floor.
  ///
  /// The account rows are a derived cache of the catalogue and the
  /// credentials. Removing them costs nothing, and the VPN uuid no longer
  /// outlives the session on disk. The sweep scopes to the account prefix.
  /// The embedded free floor and any hand-added row both survive, so a
  /// signed-out device stays a working free client.
  Future<int> forgetProvisionedNodes() async {
    var removed = 0;
    for (final row in await _outboundRows()) {
      if (!row.name.startsWith(OneVpnLocation.accountRowNamePrefix)) continue;
      await _db.coreConfigDao.deleteRow(row);
      removed += 1;
    }
    return removed;
  }

  /// Sign-out: deletes the account rows, then returns the free floor to the
  /// compiled set.
  ///
  /// A signed-in free session can provision the floor from its user data.
  /// Every free row the compiled floor does not name is deleted, and the
  /// signed-out provision rewrites the rest with the build-time triple.
  /// Resolves the number of rows deleted before that provision.
  Future<int> forgetSessionNodes() async {
    var removed = await forgetProvisionedNodes();
    final compiled = {
      for (final location in await const OneVpnStaticCatalog().locations())
        for (var i = 0; i < location.servers.length; i++) location.rowName(i),
    };
    for (final row in await _outboundRows()) {
      if (!row.name.startsWith(OneVpnLocation.freeRowNamePrefix) ||
          compiled.contains(row.name)) {
        continue;
      }
      await _db.coreConfigDao.deleteRow(row);
      removed += 1;
    }
    await provisionForSession(null);
    return removed;
  }

  Future<List<CoreConfigData>> _outboundRows() => (_db.select(
    _db.coreConfig,
  )..where((row) => row.type.equals(CoreConfigType.outbound.name))).get();
}

/// Logs every error in [result], then every entry the free node define rejects
/// or does not know.
///
/// [freeNodeIps] defaults to the build's define. Each line names a hostname, a
/// city, or an entry position, never an address. The lines go to [ygLogger].
void oneVpnLogProvision(
  OneVpnProvisionResult result, {
  OneVpnFreeNodeIps? freeNodeIps,
}) {
  final ips = freeNodeIps ?? kOneVpnFreeNodeIps;
  for (final error in result.errors) {
    ygLogger('OneVpnNodeProvisioner: $error');
  }
  for (final key in ips.malformed) {
    ygLogger('OneVpnNodeProvisioner: ONEVPN_FREE_NODE_IPS rejects $key.');
  }
  for (final host in ips.unknown) {
    ygLogger(
      'OneVpnNodeProvisioner: ONEVPN_FREE_NODE_IPS names unknown host $host.',
    );
  }
}

/// The error a free node records when the build-time triple is unconfigured.
///
/// The floor cannot dial without the triple. An unconfigured build fails
/// visibly instead of provisioning a dead config.
const _freeUnconfiguredError =
    'The free-tier REALITY credentials are not configured. Build with '
    '--dart-define ONEVPN_UUID / ONEVPN_PBK / ONEVPN_SID.';

/// The error a free node records when the build names no IP literal for it.
///
/// A free node dials its literal only. The sync skips a free node without one.
/// Both provision callers log this error. The app-build guard fails a build
/// that sets the free triple but not every free node's literal.
String _freeNoLiteralError(String host) =>
    'The free node $host has no IP literal. Build with '
    '--dart-define ONEVPN_FREE_NODE_IPS.';
