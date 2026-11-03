// The launch reachability probe. A signed-out account probes once per
// cooldown. A signed-in account never probes. Only a probe that found a
// domain stamps the cooldown. Sign-out clears the stamp, keeps the
// remembered domain, and starts no walk.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/account/credential_store.dart';
import 'package:onexray/onevpn/account/outcomes.dart';
import 'package:onexray/onevpn/account/refresh_cooldown.dart';
import 'package:onexray/onevpn/boot/launch_reachability.dart';
import 'package:onexray/onevpn/data/account_api.dart';
import 'package:onexray/onevpn/net/api_transport.dart';

import '../account/support.dart';

/// Records every request and answers it unless [answers] is false.
class _Adapter implements HttpClientAdapter {
  /// Whether a request gets an HTTP answer or a refused connection.
  bool answers = true;

  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (!answers) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'refused',
      );
    }
    return ResponseBody.fromString('1', 200);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  final launchedAt = DateTime.utc(2026, 10, 6, 12);
  late _Adapter adapter;
  late OneVpnEphemeralReachabilityStamp stamp;
  late OneVpnEphemeralDomainMemory memory;
  late OneVpnApiTransport transport;

  setUp(() {
    adapter = _Adapter();
    stamp = OneVpnEphemeralReachabilityStamp();
    memory = OneVpnEphemeralDomainMemory();
    transport = OneVpnApiTransport(
      memory: memory,
      reachabilityStamp: stamp,
      now: () => launchedAt,
      dio: Dio()..httpClientAdapter = adapter,
    );
  });

  OneVpnAccountService account({bool signedIn = false}) => OneVpnAccountService(
    store: OneVpnEphemeralCredentialStore(
      signedIn ? jsonEncode(testSession().toJson()) : null,
    ),
    api: OneVpnAccountApi(transport: transport),
    stopTunnel: () async => true,
    sweepProvisioned: () async => OneVpnSweepResult.unwired,
    clearReachabilityStamp: transport.clearReachabilityStamp,
  );

  Future<void> launch(OneVpnAccountService service) =>
      oneVpnProbeReachabilityAtLaunch(
        transport: transport,
        account: service,
        now: () => launchedAt,
      );

  test('a signed-out launch with no stamp probes and stamps', () async {
    await launch(account());

    expect(adapter.requests.map((r) => r.method), <String>['HEAD']);
    expect(adapter.requests.single.uri.path, '/ping/');
    expect(stamp.stamp, launchedAt);
  });

  test('a signed-out launch after the cooldown probes again', () async {
    stamp.stamp = launchedAt.subtract(kOneVpnRefreshCooldown);

    await launch(account());

    expect(adapter.requests, hasLength(1));
    expect(stamp.stamp, launchedAt);
  });

  test('a signed-out launch inside the cooldown sends nothing', () async {
    final earlier = launchedAt.subtract(const Duration(hours: 23));
    stamp.stamp = earlier;

    await launch(account());

    expect(adapter.requests, isEmpty);
    expect(stamp.stamp, earlier);
  });

  test('an unreadable stored session sends nothing', () async {
    final service = OneVpnAccountService(
      store: OneVpnEphemeralCredentialStore('not json'),
      api: OneVpnAccountApi(transport: transport),
    );

    await launch(service);

    expect(service.state.value, isA<OneVpnAccountUnreadable>());
    expect(adapter.requests, isEmpty);
    expect(stamp.stamp, isNull);
  });

  test('a stamp in the future reads as due and is restamped', () async {
    // A clock moved backwards never holds the cooldown shut.
    stamp.stamp = launchedAt.add(const Duration(hours: 1));

    await launch(account());

    expect(adapter.requests, hasLength(1));
    expect(stamp.stamp, launchedAt);
  });

  test('a signed-in launch sends nothing', () async {
    await launch(account(signedIn: true));

    expect(adapter.requests, isEmpty);
    expect(stamp.stamp, isNull);
  });

  test('a probe that finds no domain leaves the stamp unset', () async {
    adapter.answers = false;

    await launch(account());

    expect(adapter.requests, hasLength(4));
    expect(stamp.stamp, isNull);

    // The next launch probes again.
    adapter
      ..answers = true
      ..requests.clear();
    await launch(account());

    expect(adapter.requests, hasLength(1));
    expect(stamp.stamp, launchedAt);
  });

  test('sign-out clears the stamp, so the next launch probes', () async {
    stamp.stamp = launchedAt.subtract(const Duration(hours: 1));
    final service = account(signedIn: true);

    final report = await service.signOut();

    expect(report.reachabilityStampCleared, isTrue);
    expect(stamp.stamp, isNull);

    await launch(service);

    expect(adapter.requests, hasLength(1));
    expect(stamp.stamp, launchedAt);
  });

  test('sign-out keeps the remembered domain and starts no walk', () async {
    final backup = transport.environment.domains[1];
    await memory.write(backup);
    await transport.refreshBackupDomainNotice();
    final service = account(signedIn: true);

    final report = await service.signOut();
    await pumpEventQueue();

    expect(report.reachabilityStampCleared, isTrue);
    expect(await memory.read(), backup);
    expect(transport.backupDomainInUse.value, backup);
    expect(await transport.activeBaseUrl(), 'https://$backup');
    expect(adapter.requests, isEmpty);
  });
}
