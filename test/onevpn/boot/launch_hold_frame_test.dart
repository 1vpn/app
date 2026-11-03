// The launch hold on the real binding. A release from a frame callback sends
// the first frame of a screen with nothing animating. The widget test binding
// forces no frame when the hold lifts, so only the real binding shows whether
// one follows.

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/boot/launch_hold.dart';

void main() {
  final binding = WidgetsFlutterBinding.ensureInitialized();

  test('a release from a frame callback sends a static first frame', () async {
    var released = false;
    final followed = Completer<void>();
    binding.addPersistentFrameCallback((_) {
      if (released && !followed.isCompleted) followed.complete();
    });
    OneVpnLaunchHold.hold();
    runApp(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Text('static'),
      ),
    );
    // The deferred frame is built and not sent. Nothing on screen animates.
    await binding.endOfFrame;

    binding.addPostFrameCallback((_) {
      OneVpnLaunchHold.release();
      released = true;
    });
    binding.scheduleFrame();

    final frameFollowed = await followed.future
        .then((_) => true)
        .timeout(const Duration(seconds: 5), onTimeout: () => false);
    expect(
      frameFollowed,
      isTrue,
      reason: 'no frame followed the release, so the first frame stays held',
    );
  });
}
