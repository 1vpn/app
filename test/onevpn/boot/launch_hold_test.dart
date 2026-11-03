// The launch hold. It defers the first frame once and lets it through once,
// whatever the call count, so the native splash covers the launch. A release
// requests a frame, and a release with nothing held requests none.

import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/boot/launch_hold.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('hold and release are idempotent', () {
    expect(OneVpnLaunchHold.held, isFalse);

    OneVpnLaunchHold.hold();
    OneVpnLaunchHold.hold();
    expect(OneVpnLaunchHold.held, isTrue);

    OneVpnLaunchHold.release();
    OneVpnLaunchHold.release();
    expect(OneVpnLaunchHold.held, isFalse);
  });

  test('release with nothing held does nothing', () {
    OneVpnLaunchHold.release();
    expect(OneVpnLaunchHold.held, isFalse);
  });

  testWidgets('a release requests a frame', (tester) async {
    OneVpnLaunchHold.hold();
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);

    OneVpnLaunchHold.release();

    expect(tester.binding.hasScheduledFrame, isTrue);
  });

  testWidgets('a release with nothing held requests no frame', (tester) async {
    await tester.pump();

    OneVpnLaunchHold.release();

    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
