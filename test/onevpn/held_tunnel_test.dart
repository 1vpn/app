// The held signal. Where the platform holds no TUN it never reads and stays
// null. Elsewhere it is null until the first answer, publishes each
// answer, and lets only the latest of overlapping reads publish. A release
// disconnects only over a held TUN and waits, bounded, for the interface
// to go down. The channel wrapper answers false off Android and when no
// handler answers.

import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/core/db/database/database.dart';
import 'package:onexray/onevpn/app/held_tunnel.dart';
import 'package:onexray/onevpn/app/platform_channel.dart';
import 'package:onexray/service/connect/coordinator.dart';

/// A coordinator whose disconnect only counts.
class _Coordinator extends ConnectionCoordinator {
  _Coordinator(AppDatabase db)
    : super(
        database: db,
        statusEvents: const Stream.empty(),
        observeStatus: () async {},
        disposeStatus: () {},
      );

  int disconnects = 0;

  /// Runs inside each disconnect.
  void Function()? onDisconnect;

  @override
  Future<void> disconnect() async {
    disconnects++;
    onDisconnect?.call();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Coordinator coordinator;

  setUp(() {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    coordinator = _Coordinator(db);
    addTearDown(coordinator.dispose);
  });

  test('an unsupported platform never reads and stays null', () async {
    var reads = 0;
    final held = OneVpnHeldTunnel(
      read: () async {
        reads++;
        return true;
      },
      supported: false,
    );
    addTearDown(held.dispose);

    expect(await held.refresh(), isFalse);
    expect(await held.release(coordinator), isFalse);
    expect(reads, 0);
    expect(held.value, isNull);
    expect(coordinator.disconnects, 0);
  });

  test('the value is null until the first answer, then the answer', () async {
    var answer = true;
    final held = OneVpnHeldTunnel(read: () async => answer, supported: true);
    addTearDown(held.dispose);

    expect(held.value, isNull);
    expect(await held.refresh(), isTrue);
    expect(held.value, isTrue);
    answer = false;
    expect(await held.refresh(), isFalse);
    expect(held.value, isFalse);
  });

  test('only the latest of overlapping reads publishes', () async {
    final answers = <Completer<bool>>[];
    final held = OneVpnHeldTunnel(
      read: () {
        final answer = Completer<bool>();
        answers.add(answer);
        return answer.future;
      },
      supported: true,
    );
    addTearDown(held.dispose);

    final first = held.refresh();
    final second = held.refresh();
    answers[1].complete(false);
    await second;
    answers[0].complete(true);
    await first;

    expect(held.value, isFalse);
  });

  test('a release over nothing held never disconnects', () async {
    final held = OneVpnHeldTunnel(read: () async => false, supported: true);
    addTearDown(held.dispose);

    expect(await held.release(coordinator), isFalse);
    expect(coordinator.disconnects, 0);
  });

  test('a release disconnects and waits for the interface', () async {
    var answer = true;
    var readsAfterDisconnect = 0;
    final held = OneVpnHeldTunnel(
      read: () async {
        if (coordinator.disconnects > 0) {
          // The interface goes down on the third read after the stop.
          if (++readsAfterDisconnect == 3) answer = false;
        }
        return answer;
      },
      supported: true,
      pollInterval: const Duration(milliseconds: 1),
    );
    addTearDown(held.dispose);

    expect(await held.release(coordinator), isTrue);
    expect(coordinator.disconnects, 1);
    expect(readsAfterDisconnect, 3);
    expect(held.value, isFalse);
  });

  test('a release gives up waiting after its timeout', () async {
    final held = OneVpnHeldTunnel(
      read: () async => true,
      supported: true,
      pollInterval: const Duration(milliseconds: 5),
      releaseTimeout: const Duration(milliseconds: 30),
    );
    addTearDown(held.dispose);

    final waited = Stopwatch()..start();
    expect(await held.release(coordinator), isTrue);
    expect(waited.elapsed, lessThan(const Duration(seconds: 2)));
    expect(coordinator.disconnects, 1);
  });

  group('the channel wrapper', () {
    const channel = MethodChannel(OneVpnPlatformChannel.name);
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      messenger.setMockMethodCallHandler(channel, null);
    });

    test('answers the native tunnelHeld on Android', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final methods = <String>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        methods.add(call.method);
        return true;
      });

      expect(await OneVpnPlatformChannel.tunnelHeld(), isTrue);
      expect(methods, ['tunnelHeld']);
    });

    test('answers false off Android without a call', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      var calls = 0;
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls++;
        return true;
      });

      expect(await OneVpnPlatformChannel.tunnelHeld(), isFalse);
      expect(calls, 0);
    });

    test('answers false when no handler answers', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      expect(await OneVpnPlatformChannel.tunnelHeld(), isFalse);
    });
  });
}
