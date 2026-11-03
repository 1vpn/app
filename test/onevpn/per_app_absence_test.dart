// Pins the Android per-app VPN decision: saved per-app scopes never
// compile into the tunnel start request. The compiled TunJson is the
// only conduit into the native per-app calls on VpnService.Builder. A
// compile without per-app fields keeps the tunnel capturing every
// installed app.

import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/service/advanced/platform_policy.dart';
import 'package:onexray/service/connect/settings.dart';

void main() {
  test('saved per-app scopes never compile into the tunnel start', () {
    // Stale states an upgraded install can carry: an empty include list
    // and lists naming apps that may no longer be installed. Each compiled
    // per-app field would either narrow the tunnel silently or fail the
    // native require(allowed > 0) guard at connect.
    for (final stale in [
      {'appScope': 'included', 'includedAppPackageNames': <String>[]},
      {
        'appScope': 'included',
        'includedAppPackageNames': ['com.example.stale'],
      },
      {
        'appScope': 'excluded',
        'excludedAppPackageNames': ['com.example.stale'],
      },
    ]) {
      final policy = PlatformPolicy.fromJson({'android': stale});
      final tun = policy.toTun(ConnectionPlatform.android);
      expect(tun.perAppVPNMode, isNull);
      expect(tun.allowAppList, isNull);
      expect(tun.disallowAppList, isNull);
      final json = tun.toJson();
      expect(json, isNot(contains('perAppVPNMode')));
      expect(json, isNot(contains('allowAppList')));
      expect(json, isNot(contains('disallowAppList')));
    }
  });
}
