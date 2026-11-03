// Contract for the Dart side of the reload channel, over the generated
// channels with a fake native side. Every call resolves to a value.
// reloadSupported reads a missing handler as false. Every reload failure,
// a missing handler included, answers timeout.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/handover/handover.g.dart';
import 'package:onexray/onevpn/handover/handover_host.dart';

const _prefix = 'dev.flutter.pigeon.onevpn';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  BasicMessageChannel<Object?> hostChannel(String method) =>
      BasicMessageChannel<Object?>(
        '$_prefix.OneVpnHandoverHostApi.$method',
        OneVpnHandoverHostApi.pigeonChannelCodec,
      );

  void mockHost(
    String method,
    Future<Object?> Function(Object? message) handler,
  ) {
    final channel = hostChannel(method);
    messenger.setMockDecodedMessageHandler<Object?>(channel, handler);
    addTearDown(() => messenger.setMockDecodedMessageHandler(channel, null));
  }

  group('reloadSupported', () {
    test('a missing handler answers false', () async {
      expect(await OneVpnHandoverHost().reloadSupported(), isFalse);
    });

    for (final supported in [true, false]) {
      test('passes the native answer $supported through', () async {
        mockHost('reloadSupported', (_) async => <Object?>[supported]);
        expect(await OneVpnHandoverHost().reloadSupported(), supported);
      });
    }

    test('a native error answers false', () async {
      mockHost(
        'reloadSupported',
        (_) async => <Object?>['nativeError', 'message', null],
      );
      expect(await OneVpnHandoverHost().reloadSupported(), isFalse);
    });

    test('an undecodable reply answers false', () async {
      mockHost('reloadSupported', (_) async => <Object?>['notABool']);
      expect(await OneVpnHandoverHost().reloadSupported(), isFalse);
    });

    testWidgets('a hung channel answers false at its bound', (tester) async {
      mockHost('reloadSupported', (_) => Completer<Object?>().future);
      bool? observed;
      unawaited(
        OneVpnHandoverHost().reloadSupported().then((v) => observed = v),
      );
      await tester.pump(
        OneVpnHandoverDeadlines.reloadSupported -
            const Duration(milliseconds: 1),
      );
      expect(observed, isNull);
      await tester.pump(const Duration(milliseconds: 1));
      expect(observed, isFalse);
    });
  });

  group('reload', () {
    test('a missing handler answers timeout', () async {
      expect(await OneVpnHandoverHost().reload('r1'), ReloadResult.timeout);
    });

    test('sends the request id and passes every result through', () async {
      for (final result in ReloadResult.values) {
        final sent = <String>[];
        mockHost('reload', (message) async {
          final request = (message! as List<Object?>).single! as ReloadRequest;
          sent.add(request.requestId);
          return <Object?>[result];
        });
        expect(await OneVpnHandoverHost().reload('r-${result.name}'), result);
        expect(sent, ['r-${result.name}']);
      }
    });

    test('a native error answers timeout', () async {
      mockHost(
        'reload',
        (_) async => <Object?>['nativeError', 'message', null],
      );
      expect(await OneVpnHandoverHost().reload('r1'), ReloadResult.timeout);
    });

    test('an undecodable reply answers timeout', () async {
      mockHost('reload', (_) async => <Object?>['notAResult']);
      expect(await OneVpnHandoverHost().reload('r1'), ReloadResult.timeout);
    });

    testWidgets('a hung reload answers timeout at its bound', (tester) async {
      final late = Completer<Object?>();
      var calls = 0;
      mockHost('reload', (_) {
        calls += 1;
        if (calls == 1) return late.future;
        return Future.value(<Object?>[ReloadResult.applied]);
      });
      final results = <ReloadResult>[];
      unawaited(OneVpnHandoverHost().reload('r1').then(results.add));

      await tester.pump(
        OneVpnHandoverDeadlines.reload - const Duration(milliseconds: 1),
      );
      expect(results, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      expect(results, [ReloadResult.timeout]);

      // A late native error is swallowed. An uncaught error would fail the
      // test.
      late.complete(<Object?>['nativeError', 'm', null]);
      await tester.pump();
      expect(results, [ReloadResult.timeout]);

      // The next reload gets its own answer.
      unawaited(OneVpnHandoverHost().reload('r2').then(results.add));
      await tester.pump();
      expect(results, [ReloadResult.timeout, ReloadResult.applied]);
      expect(calls, 2);
    });

    test('the bounds are pinned', () {
      expect(OneVpnHandoverDeadlines.nativeReload, const Duration(seconds: 15));
      expect(OneVpnHandoverDeadlines.reload, const Duration(seconds: 20));
      expect(
        OneVpnHandoverDeadlines.reloadSupported,
        const Duration(seconds: 10),
      );
    });
  });

  group('events', () {
    const eventChannel = '$_prefix.OneVpnHandoverFlutterApi.reloadEvent';

    ByteData encode(ReloadEvent event) => OneVpnHandoverFlutterApi
        .pigeonChannelCodec
        .encodeMessage(<Object?>[event])!;

    Future<void> sendEvent(ReloadEvent event) =>
        messenger.handlePlatformMessage(eventChannel, encode(event), (_) {});

    ReloadEvent started(String id) => ReloadEvent(
      requestId: id,
      trigger: ReloadTrigger.settings,
      phase: ReloadPhase.started,
    );

    List<String?> ids(List<ReloadEvent> events) =>
        events.map((e) => e.requestId).toList();

    OneVpnHandoverEvents receiver(List<ReloadEvent> into) {
      final events = OneVpnHandoverEvents();
      addTearDown(events.close);
      addTearDown(events.detach);
      final subscription = events.events.listen(into.add);
      addTearDown(subscription.cancel);
      return events;
    }

    test('an attached receiver republishes events in order', () async {
      final received = <ReloadEvent>[];
      receiver(received).attach();

      await sendEvent(started('r1'));
      await sendEvent(
        ReloadEvent(
          requestId: 'r1',
          trigger: ReloadTrigger.settings,
          phase: ReloadPhase.finished,
          result: ReloadResult.applied,
        ),
      );
      await pumpEventQueue();

      expect(received.map((e) => (e.requestId, e.phase, e.result)), [
        ('r1', ReloadPhase.started, null),
        ('r1', ReloadPhase.finished, ReloadResult.applied),
      ]);
    });

    test('attach replays the last event sent while detached', () async {
      // Engine messages with no handler wait in the channel buffers, which
      // hold one message per channel.
      ui.channelBuffers.push(eventChannel, encode(started('old')), (_) {});
      ui.channelBuffers.push(eventChannel, encode(started('last')), (_) {});
      final received = <ReloadEvent>[];
      final events = receiver(received);
      await pumpEventQueue();
      expect(received, isEmpty);

      events.attach();
      await pumpEventQueue();
      expect(ids(received), ['last']);
    });

    test('a stale detach leaves the newer receiver attached', () async {
      final first = <ReloadEvent>[];
      final second = <ReloadEvent>[];
      final older = receiver(first)..attach();
      receiver(second).attach();
      older.detach();

      await sendEvent(started('r1'));
      await pumpEventQueue();
      expect(first, isEmpty);
      expect(ids(second), ['r1']);
    });

    test('a detached receiver gets nothing', () async {
      final received = <ReloadEvent>[];
      receiver(received)
        ..attach()
        ..detach();

      await sendEvent(started('r1'));
      await pumpEventQueue();
      expect(received, isEmpty);
    });
  });
}
