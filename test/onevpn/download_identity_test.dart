// Pins the geodata download identity. The default download User-Agent is
// the fixed Windows browser string on every platform, not the identifying
// oneXray string. A manual or scheduled geodata fetch therefore leaves no
// app fingerprint on the wire. The oneXray mode stays wired as a
// below-waterline stored-preference option. The test fails if the default
// reverts to oneXray. It also fails if the browser string gains an
// identifying token.

import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/core/network/user_agent.dart';

void main() {
  // Stands in for the identifying string NetClient builds. It holds no
  // host, address, or URL shape, so the endpoint sweep reads past it.
  const identifying = 'OneXray/v26 (pkg-onexray; build:42; android)';

  test('the default download identity is the browser User-Agent', () async {
    expect(DownloadUserAgentMode.defaultMode, DownloadUserAgentMode.system);

    final resolved = await DownloadUserAgent.resolve(
      mode: DownloadUserAgentMode.defaultMode,
      oneXrayUserAgent: identifying,
    );
    expect(resolved, DownloadUserAgent.windows);
    expect(resolved, isNot(equals(identifying)));
    expect(resolved.toLowerCase(), isNot(contains('onexray')));
  });

  test('the browser User-Agent names no app or vendor identity', () {
    final ua = DownloadUserAgent.windows.toLowerCase();
    expect(ua, isNot(contains('onexray')));
    expect(ua, isNot(contains('onevpn')));
    expect(ua, isNot(contains('1vpn')));
  });

  test('a missing or unknown stored mode falls back to system', () {
    expect(
      DownloadUserAgentMode.fromString(null),
      DownloadUserAgentMode.system,
    );
    expect(
      DownloadUserAgentMode.fromString('unknown'),
      DownloadUserAgentMode.system,
    );
  });

  test(
    'the oneXray mode stays selectable and returns the built string',
    () async {
      expect(
        DownloadUserAgentMode.fromString('oneXray'),
        DownloadUserAgentMode.oneXray,
      );
      final resolved = await DownloadUserAgent.resolve(
        mode: DownloadUserAgentMode.oneXray,
        oneXrayUserAgent: identifying,
      );
      expect(resolved, identifying);
    },
  );
}
