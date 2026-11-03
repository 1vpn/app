// Pins the probe URL list and the headless ping state. The probe URL is
// the ping URL on the remembered domain, or the primary's with no record or
// a host outside the list. PingState probes that URL and restores only its
// clamped timeout from storage.

import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/core/constants/preferences.dart';
import 'package:onexray/onevpn/net/api_transport.dart';
import 'package:onexray/onevpn/net/probe_endpoints.dart';
import 'package:onexray/service/shared/ping/state.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  test('the endpoint list pins the failover domains in order', () {
    expect(ProbeEndpoints.urls, const [
      'https://1vpn.org/ping/',
      'https://1vpn.co/ping/',
      'https://onevpn.com/ping/',
      'https://cloudlogcdn.com/ping/',
    ]);
  });

  group('the resolved probe URL', () {
    OneVpnApiTransport transport(
      String? remembered, {
      OneVpnApiEnvironment environment = OneVpnApiEnvironment.production,
    }) => OneVpnApiTransport(
      environment: environment,
      memory: OneVpnEphemeralDomainMemory(remembered),
    );

    test('a remembered backup answers its ping URL', () async {
      expect(
        await ProbeEndpoints.resolve(transport: transport('onevpn.com')),
        'https://onevpn.com/ping/',
      );
    });

    test('no record answers the primary', () async {
      expect(
        await ProbeEndpoints.resolve(transport: transport(null)),
        ProbeEndpoints.urls.first,
      );
    });

    test('a remembered domain outside the list answers the primary', () async {
      final foreign = transport(
        'api.example.invalid',
        environment: const OneVpnApiEnvironment(
          domains: ['1vpn.org', 'api.example.invalid'],
        ),
      );
      expect(await foreign.activeBaseUrl(), 'https://api.example.invalid');

      expect(
        await ProbeEndpoints.resolve(transport: foreign),
        ProbeEndpoints.urls.first,
      );
    });

    test('the read writes no record', () async {
      final memory = OneVpnEphemeralDomainMemory();
      await ProbeEndpoints.resolve(
        transport: OneVpnApiTransport(memory: memory),
      );
      expect(await memory.read(), isNull);
    });
  });

  group('PingState', () {
    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
    });

    test('stored timeouts clamp to the valid range', () async {
      for (final (stored, restored) in [
        (1, PingTimeout.min),
        (99, PingTimeout.max),
      ]) {
        await PreferencesKey().savePingState({'timeout': stored});

        final state = PingState();
        await state.readFromPreferences();

        expect(state.timeout, restored, reason: '$stored');
      }
    });

    test('stored target choices from older builds are ignored', () async {
      await PreferencesKey().savePingState({
        'timeout': 5,
        'url': 'Custom',
        'customUrl': 'https://legacy.example.com/ping',
      });

      final restored = PingState();
      await restored.readFromPreferences();

      expect(restored.timeout, 5);
      expect(restored.realUrl, ProbeEndpoints.urls.first);

      // The next save keeps the shared preference key and drops the fields.
      await restored.saveToPreferences();
      expect(await PreferencesKey().readPingState(), {'timeout': 5.0});
    });

    test('the probe URL follows the remembered domain', () async {
      await const OneVpnPrefsDomainMemory().write('1vpn.co');

      final state = PingState();
      expect(state.realUrl, ProbeEndpoints.urls.first);
      await state.readFromPreferences();

      expect(state.realUrl, 'https://1vpn.co/ping/');
    });
  });
}
