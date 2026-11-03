// Pins the keep-location guard on the native connect's prepare. A location
// prepare that fell back to Automatic fails with selectionUnavailable, so
// the location stays selected. A location prepare that resolved its own
// rows passes through. Automatic and every other selection kind pass
// through, a fallback included. A prepare error passes through unchanged.
// The native connect wraps every prepare it runs.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/core/pigeon/model.dart';
import 'package:onexray/onevpn/connect/native_connect.dart';
import 'package:onexray/service/connect/compiler.dart';
import 'package:onexray/service/connect/resolver.dart';
import 'package:onexray/service/connect/runtime.dart';
import 'package:onexray/service/connect/settings.dart';

void main() {
  const tokyo = ServerSelection.location('1vpn·acct·nrt');

  /// A guarded prepare whose inner prepare answers [notice].
  OneVpnPreparation guarded({String? notice}) => oneVpnKeepLocation(
    (configuration, _, {cancelled, onResolved}) async =>
        _runtime(configuration, notice: notice),
  );

  test('a location that fell back to Automatic fails with '
      'selectionUnavailable', () async {
    await expectLater(
      guarded(notice: 'selectionReset')(_configuration(tokyo), _resolver),
      throwsA(
        isA<ConnectionResolutionException>().having(
          (error) => error.reason,
          'reason',
          ConnectionResolutionFailure.selectionUnavailable,
        ),
      ),
    );
  });

  test('a location that resolved its own rows passes through', () async {
    final runtime = await guarded()(_configuration(tokyo), _resolver);
    expect(runtime.configuration.connection.selection.location, tokyo.location);
  });

  test(
    'Automatic and the other kinds pass through, a fallback included',
    () async {
      for (final selection in [
        const ServerSelection.automatic(),
        const ServerSelection.server(4),
      ]) {
        final runtime = await guarded(notice: 'selectionReset')(
          _configuration(selection),
          _resolver,
        );
        expect(runtime.notice, 'selectionReset', reason: selection.kind.name);
      }
    },
  );

  test('a prepare error passes through unchanged', () async {
    const error = ConnectionResolutionException(
      ConnectionResolutionFailure.insufficientCandidates,
    );
    final prepare = oneVpnKeepLocation(
      (_, _, {cancelled, onResolved}) async => throw error,
    );
    await expectLater(
      prepare(_configuration(tokyo), _resolver),
      throwsA(same(error)),
    );
  });

  test('the native connect guards every prepare it runs', () {
    final source = File('lib/onevpn/connect/native_connect.dart')
        .readAsStringSync()
        .replaceAll(RegExp(r'\s+'), ' ');
    expect(
      source,
      contains('_preparation = oneVpnKeepLocation( preparation ??'),
    );
  });
}

final _resolver = ConnectionResolver(
  rows: () => const Stream.empty(),
  probe: (_) async => fail('The guard never resolves'),
);

ConnectionConfiguration _configuration(ServerSelection selection) =>
    ConnectionConfiguration(
      connection: ConnectionSettings(selection: selection),
    );

ConnectionRuntime _runtime(
  ConnectionConfiguration configuration, {
  String? notice,
}) {
  final entries = [
    ResolvedServer(
      id: 1,
      sourceId: 7,
      outbound: const {'protocol': 'freedom', 'tag': 'server-1'},
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
  final invoke = LibXrayInvokeRequest(
    method: LibXrayMethod.runXray,
    payload: RunXrayRequest(compiled.xrayJson).toJson(),
  );
  return ConnectionRuntime.create(
    configuration: configuration,
    compiled: compiled,
    platform: ConnectionPlatform.android,
    request: StartVpnRequest(null, null, '18001', jsonEncode(invoke.toJson())),
    notice: notice,
  );
}
