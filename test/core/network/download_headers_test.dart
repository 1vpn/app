import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/core/network/client.dart';
import 'package:onexray/core/network/user_agent.dart';
import 'package:package_info_plus/package_info_plus.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUpAll(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    PackageInfo.setMockInitialValues(
      appName: 'OneXray',
      packageName: 'net.yuandev.onexray',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  test('uses the default browser UA for an unrelated download', () async {
    String? receivedAgeHeader;
    String? receivedUserAgent;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      receivedAgeHeader = request.headers.value('X-Age-Public-Key');
      receivedUserAgent = request.headers.value(HttpHeaders.userAgentHeader);
      request.response.write('plain subscription');
      await request.response.close();
    });

    final text = await NetClient().getText(_serverUrl(server));

    expect(text, 'plain subscription');
    expect(receivedAgeHeader, isNull);
    expect(receivedUserAgent, DownloadUserAgent.windows);
    expect(NetClient().downloadUserAgent, receivedUserAgent);
  });
}

String _serverUrl(HttpServer server) =>
    'http://${server.address.address}:${server.port}';
