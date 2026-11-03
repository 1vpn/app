import 'dart:convert';
import 'dart:io';

import 'package:onexray/core/model/tun_json.dart';
import 'package:onexray/core/pigeon/model.dart';
import 'package:onexray/onevpn/app/held_tunnel.dart';
import 'package:onexray/onevpn/handover/handover.g.dart';
import 'package:onexray/onevpn/handover/handover_host.dart';
import 'package:onexray/onevpn/handover/reload_policy.dart';
import 'package:onexray/service/connect/compiler.dart';
import 'package:onexray/service/connect/runtime.dart';
import 'package:onexray/service/connect/settings.dart';

/// The reload channel. [onReload] answers each reload, and [supported]
/// answers each support query.
class FakeReloadHost extends OneVpnHandoverHost {
  bool supported = true;
  int supportQueries = 0;
  final requests = <String>[];
  Future<ReloadResult> Function(String requestId) onReload = (_) async =>
      ReloadResult.applied;

  @override
  Future<bool> reloadSupported() async {
    supportQueries++;
    return supported;
  }

  @override
  Future<ReloadResult> reload(String requestId) {
    requests.add(requestId);
    return onReload(requestId);
  }
}

/// A stage that writes nothing, for tests on the widget test clock.
class MemoryReloadStage extends OneVpnReloadStage {
  @override
  Future<void> write(
    StartVpnRequest request, {
    required String requestId,
  }) async {}

  @override
  Future<void> clear() async {}
}

/// A policy over [host] that prepares with [prepare], accepts every config,
/// and stages through [stage], in memory by default. [held] answers the
/// held signal the policy reads when no core runs, false by default.
OneVpnReloadPolicy fakeReloadPolicy({
  required FakeReloadHost host,
  required ConnectionRuntime Function(ConnectionConfiguration next) prepare,
  bool supported = true,
  OneVpnReloadStage? stage,
  Future<bool> Function()? held,
}) => OneVpnReloadPolicy(
  held: OneVpnHeldTunnel(read: held ?? () async => false, supported: true),
  host: host,
  events: OneVpnHandoverEvents(),
  supported: supported,
  prepare: (_, next, _) async => prepare(next),
  validate: (_) async => '',
  stage: stage ?? MemoryReloadStage(),
  withFiles: (action) => action(),
);

/// The runtime the staged request in [file] describes, as the native side
/// promotes it over start.json.
ConnectionRuntime promotedRuntime(File file) => ConnectionRuntime.fromRequest(
  StartVpnRequest.fromJson(
    jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
  ),
);

/// A runtime for [configuration] on the node [entryId] named [entryName],
/// with the metrics port [metricsPort] and a fixed TUN.
ConnectionRuntime reloadRuntime(
  ConnectionConfiguration configuration, {
  required String metricsPort,
  int entryId = 1,
  String? entryName,
  bool ipv6 = false,
  String? notice,
}) {
  final entries = [
    ResolvedServer(
      id: entryId,
      sourceId: 0,
      outbound: {'protocol': 'freedom', 'tag': entryName ?? 'node-$entryId'},
    ),
  ];
  final compiled = CompiledConnection(
    xrayJson: jsonEncode({
      'outbounds': [for (final entry in entries) entry.outbound],
    }),
    entries: entries,
    finalExit: null,
    nodeTags: const {},
  );
  return ConnectionRuntime.create(
    configuration: configuration,
    compiled: compiled,
    platform: ConnectionPlatform.android,
    notice: notice,
    request: StartVpnRequest(
      TunJson.fromJson({'tunDnsIPv4': '1.1.1.1', 'enableIPv6': ipv6}),
      null,
      metricsPort,
      jsonEncode(
        LibXrayInvokeRequest(
          method: LibXrayMethod.runXray,
          payload: RunXrayRequest(compiled.xrayJson).toJson(),
        ).toJson(),
      ),
    ),
  );
}

/// A configuration whose selection is [selection].
ConnectionConfiguration reloadConfiguration(ServerSelection selection) =>
    ConnectionConfiguration(
      connection: ConnectionSettings(selection: selection),
    );
