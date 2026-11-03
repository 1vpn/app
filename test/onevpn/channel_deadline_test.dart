// The pigeon channel deadlines. AppHostApi sends on the binding's messenger.
// Each mock routes that send through a ChannelDeadlineMessenger to a fake
// native side. The suite therefore observes the bounds the app binding
// applies, through the real pigeon client.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/core/pigeon/host_api.dart';
import 'package:onexray/core/tools/platform.dart';
import 'package:onexray/core/pigeon/messages.g.dart';
import 'package:onexray/onevpn/app/channel_deadlines.dart';
import 'package:onexray/service/shared/command_serial_executor.dart';

/// One command channel under observation: the pigeon channel name, the
/// deadline, a success reply for the fake native side, and the wrapper
/// call reduced to a comparable observation string.
final class _Command {
  final String name;
  final Duration bound;
  final List<Object?> successReply;
  final Future<String> Function() observe;
  final String onSuccess;
  final String onExpiry;
  final String expiryLog;

  _Command({
    required this.name,
    required this.bound,
    required this.successReply,
    required this.observe,
    required this.onSuccess,
    required this.onExpiry,
    required this.expiryLog,
  });
}

/// The native side under the decorator. Each channel answers through its
/// decoded handler. A channel with no handler answers null.
final class _NativeSide extends BinaryMessenger {
  final handlers = <String, Future<Object?> Function(Object? message)>{};

  @override
  Future<ByteData?>? send(String channel, ByteData? message) {
    final handler = handlers[channel];
    if (handler == null) {
      return Future<ByteData?>.value();
    }
    const codec = BridgeHostApi.pigeonChannelCodec;
    return handler(codec.decodeMessage(message)).then(codec.encodeMessage);
  }

  @override
  void setMessageHandler(String channel, MessageHandler? handler) {}

  @override
  Future<void> handlePlatformMessage(
    String channel,
    ByteData? data,
    PlatformMessageResponseCallback? callback,
  ) async {}
}

const _androidConnectionPath =
    'android/app/src/main/kotlin/net/yuandev/onexray/vpn/'
    'VpnStatusConnection.kt';
const _appleVpnPath = 'swift/App/Vpn.swift';

/// Every `withTimeout(...)` line of the Android command path, trimmed,
/// in file order:
///
/// - the command's own completion wait: 30s while connecting and 15s
///   while disconnecting
/// - the wait on a bind already in flight
/// - the wait on a fresh bind
///
/// A change here moves a native budget. The Dart bounds below must then
/// be re-derived.
const _androidTimeoutLines = [
  'withTimeout(if (wanted == VpnStatus.CONNECTED) 30_000L else 15_000L) '
      '{ completion.await() }',
  'service?.let { return withTimeout(3_000) { it.await() } }',
  'return withTimeout(3_000) { connected.await() }',
];

/// Every status wait of the Apple command path, trimmed, in file
/// order: the macOS system-extension activation wait, the
/// system-extension connected wait, the direct connected wait, and the
/// stop wait. Same contract as [_androidTimeoutLines].
const _appleStatusWaitLines = [
  'session: session, accepted: [.connecting, .connected, .reasserting], '
      'timeout: 10',
  'try await waitForStatus(session: session, accepted: [.connected], '
      'timeout: 30)',
  'try await waitForStatus(session: session, accepted: [.connected], '
      'timeout: 30) {',
  'try await waitForStatus(session: session, accepted: [.disconnected, '
      '.invalid], timeout: 15) {',
];

/// Every extension round trip inside syncDatAndStart, trimmed, in file
/// order. listDat and startXray run on every macOS system-extension
/// start. clearDat, putDat, and commitDat run only when the extension's
/// dat manifest differs. putDat runs once per staged file.
const _appleSyncRequestLines = [
  'let listResp = try await sendTunnelRequest(session: session, .listDat, '
      'timeoutSeconds: 10)',
  'guard case .ok = try await sendTunnelRequest(session: session, .clearDat, '
      'timeoutSeconds: 10) else {',
  'guard case .ok = try await sendTunnelRequest(session: session, '
      '.putDat(name: name, content: content, mtimeMs: mtime), '
      'timeoutSeconds: 10) else {',
  'guard case .ok = try await sendTunnelRequest(session: session, .commitDat, '
      'timeoutSeconds: 10) else {',
  'guard case .ok = try await sendTunnelRequest(session: session, .startXray, '
      'timeoutSeconds: 10) else {',
];

/// The macOS system-extension start chain, the longest fully bounded
/// native start: activation 10s, then syncDatAndStart's listDat 10s and
/// startXray 10s, then the connected wait 30s.
const _appleStartBudget = Duration(seconds: 10 + 10 + 10 + 30);

/// The Apple stop chain: one wait for the disconnected status.
const _appleStopBudget = Duration(seconds: 15);

/// The Android start chain: command() reads the current status first,
/// which can spend a bind, before it arms its own completion wait.
const _androidStartBudget = Duration(seconds: 3 + 30);

/// The Android stop chain: the same status read, then the stop wait.
const _androidStopBudget = Duration(seconds: 3 + 15);

/// Every line of [path] holding [pattern], trimmed, in file order.
List<String> _matchingLines(String path, Pattern pattern) {
  final file = File(path);
  expect(file.existsSync(), isTrue, reason: '$path is missing');
  return file
      .readAsLinesSync()
      .map((line) => line.trim())
      .where((line) => line.contains(pattern))
      .toList();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final native = _NativeSide();
  final bounded = ChannelDeadlineMessenger(native);

  void mock(String name, Future<Object?> Function(Object? message) handler) {
    final channel = '${ChannelDeadlineMessenger.channelPrefix}$name';
    native.handlers[channel] = handler;
    messenger.setMockMessageHandler(
      channel,
      (message) => bounded.send(channel, message),
    );
    addTearDown(() {
      native.handlers.remove(channel);
      messenger.setMockMessageHandler(channel, null);
    });
  }

  // The widget test binding verifies debugPrint is restored before the test
  // body returns, so the capture cannot live in a tearDown.
  Future<void> captureDebugPrint(
    List<String?> logs,
    Future<void> Function() body,
  ) async {
    final previous = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) => logs.add(message);
    try {
      await body();
    } finally {
      debugPrint = previous;
    }
  }

  NativeVpnCommandResult commandReply() => NativeVpnCommandResult(
    state: NativeVpnCommandState.success,
    status: VpnStatus.connected,
    message: 'nativeReply',
  );

  Future<String> observeCommand(
    Future<NativeVpnCommandResult> Function() call,
  ) async {
    final result = await call();
    return '${result.state.name}:${result.message}';
  }

  final commands = <_Command>[
    _Command(
      name: 'readVpnStatus',
      bound: ChannelDeadlines.readVpnStatus,
      successReply: <Object?>[commandReply()],
      observe: () => observeCommand(AppHostApi().readVpnStatus),
      onSuccess: 'success:nativeReply',
      onExpiry: 'failed:channelDeadline',
      expiryLog: 'BridgeHostApi.readVpnStatus failed: channelDeadline',
    ),
    _Command(
      name: 'startVpn',
      bound: ChannelDeadlines.startVpn,
      successReply: <Object?>[commandReply()],
      observe: () => observeCommand(AppHostApi().startVpn),
      onSuccess: 'success:nativeReply',
      onExpiry: 'failed:channelDeadline',
      expiryLog: 'BridgeHostApi.startVpn failed: channelDeadline',
    ),
    _Command(
      name: 'stopVpn',
      bound: ChannelDeadlines.stopVpn,
      successReply: <Object?>[commandReply()],
      observe: () => observeCommand(AppHostApi().stopVpn),
      onSuccess: 'success:nativeReply',
      onExpiry: 'failed:channelDeadline',
      expiryLog: 'BridgeHostApi.stopVpn failed: channelDeadline',
    ),
    _Command(
      name: 'invoke',
      bound: ChannelDeadlines.invoke,
      successReply: <Object?>[
        jsonEncode({'success': true, 'data': {}, 'error': ''}),
      ],
      observe: () async => 'invoke:${await AppHostApi().testXray('{}')}',
      onSuccess: 'invoke:',
      onExpiry: 'invoke:channelDeadline',
      expiryLog: 'BridgeHostApi.invoke failed: channelDeadline',
    ),
  ];

  group('Channel deadlines', () {
    // The wrappers reach the pigeon branch only on mobile and macOS. The
    // override makes that branch reachable on any test host, so the gate
    // runs these on CI too.
    setUp(() => AppPlatform.debugOperatingSystemOverride = 'android');
    tearDown(() => AppPlatform.debugOperatingSystemOverride = null);

    for (final command in commands) {
      testWidgets('a hung ${command.name} fails at its bound with the '
          'sentinel', (tester) async {
        final logs = <String?>[];
        await captureDebugPrint(logs, () async {
          mock(command.name, (_) => Completer<Object?>().future);

          String? observed;
          unawaited(command.observe().then((value) => observed = value));
          await tester.pump(command.bound - const Duration(milliseconds: 1));
          expect(observed, isNull);

          await tester.pump(const Duration(milliseconds: 1));
          expect(observed, command.onExpiry);
        });
        expect(logs, contains(command.expiryLog));
      });

      testWidgets('a fast ${command.name} reply passes through', (
        tester,
      ) async {
        mock(command.name, (_) async => command.successReply);

        String? observed;
        unawaited(command.observe().then((value) => observed = value));
        await tester.pump();
        expect(observed, command.onSuccess);
      });
    }

    testWidgets('a fast reply keeps every result field', (tester) async {
      mock(
        'readVpnStatus',
        (_) async => <Object?>[
          NativeVpnCommandResult(
            state: NativeVpnCommandState.success,
            status: VpnStatus.connected,
            permission: PlatformPermissionResult(
              kind: PlatformPermissionKind.androidVpn,
              state: PlatformPermissionState.granted,
            ),
            message: 'nativeReply',
          ),
        ],
      );

      NativeVpnCommandResult? observed;
      unawaited(
        AppHostApi().readVpnStatus().then((result) => observed = result),
      );
      await tester.pump();
      expect(observed!.state, NativeVpnCommandState.success);
      expect(observed!.status, VpnStatus.connected);
      expect(observed!.message, 'nativeReply');
      expect(observed!.permission!.kind, PlatformPermissionKind.androidVpn);
      expect(observed!.permission!.state, PlatformPermissionState.granted);
    });

    // The expiry value copies AppHostApi's failed command result. The
    // envelope alignment pins hold the upstream shape it copies.
    testWidgets('an expired command carries the upstream failed shape', (
      tester,
    ) async {
      mock('stopVpn', (_) => Completer<Object?>().future);

      NativeVpnCommandResult? observed;
      unawaited(AppHostApi().stopVpn().then((result) => observed = result));
      await tester.pump(ChannelDeadlines.stopVpn);
      expect(observed!.state, NativeVpnCommandState.failed);
      expect(observed!.status, isNull);
      expect(observed!.message, ChannelDeadlines.expired);
      expect(observed!.permission!.kind, PlatformPermissionKind.none);
      expect(observed!.permission!.state, PlatformPermissionState.failed);
      expect(observed!.permission!.message, isNull);
    });

    testWidgets('an unbounded bridge call waits past every bound', (
      tester,
    ) async {
      final reply = Completer<Object?>();
      mock('queryPlatformPermission', (_) => reply.future);

      PlatformPermissionResult? observed;
      unawaited(
        AppHostApi().queryPlatformPermission().then(
          (result) => observed = result,
        ),
      );
      await tester.pump(ChannelDeadlines.startVpn * 2);
      expect(observed, isNull);

      reply.complete(<Object?>[
        PlatformPermissionResult(
          kind: PlatformPermissionKind.androidVpn,
          state: PlatformPermissionState.granted,
        ),
      ]);
      await tester.pump();
      expect(observed!.state, PlatformPermissionState.granted);
    });

    testWidgets('a reply after expiry is dropped', (tester) async {
      final reply = Completer<Object?>();
      mock('readVpnStatus', (_) => reply.future);

      final results = <NativeVpnCommandResult>[];
      unawaited(AppHostApi().readVpnStatus().then(results.add));
      await tester.pump(ChannelDeadlines.readVpnStatus);
      expect(results, hasLength(1));
      expect(results.single.state, NativeVpnCommandState.failed);
      expect(results.single.message, ChannelDeadlines.expired);

      reply.complete(<Object?>[commandReply()]);
      await tester.pump();
      expect(results, hasLength(1));
      expect(results.single.state, NativeVpnCommandState.failed);
      expect(results.single.message, ChannelDeadlines.expired);
    });

    testWidgets('an error after expiry is swallowed', (tester) async {
      final reply = Completer<Object?>();
      mock('readVpnStatus', (_) => reply.future);

      final results = <NativeVpnCommandResult>[];
      unawaited(AppHostApi().readVpnStatus().then(results.add));
      await tester.pump(ChannelDeadlines.readVpnStatus);
      expect(results, hasLength(1));
      expect(results.single.message, ChannelDeadlines.expired);

      // An unhandled error would fail the test. The drop must be silent.
      reply.completeError(PlatformException(code: 'lateNativeError'));
      await tester.pump();
      expect(results, hasLength(1));
      expect(results.single.message, ChannelDeadlines.expired);
    });

    testWidgets('the serial queue drains after an expiry', (tester) async {
      var calls = 0;
      mock('readVpnStatus', (_) {
        calls++;
        if (calls == 1) return Completer<Object?>().future;
        return Future<Object?>.value(<Object?>[commandReply()]);
      });

      final executor = CommandSerialExecutor();
      final observed = <String>[];
      unawaited(
        executor
            .run(AppHostApi().readVpnStatus)
            .then((result) => observed.add('first:${result.message}')),
      );
      unawaited(
        executor
            .run(AppHostApi().readVpnStatus)
            .then((result) => observed.add('second:${result.status?.name}')),
      );
      await tester.pump(
        ChannelDeadlines.readVpnStatus - const Duration(milliseconds: 1),
      );
      expect(observed, isEmpty);

      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      expect(observed, ['first:channelDeadline', 'second:connected']);
      expect(calls, 2);
    });
  });

  // A start or stop command awaits its native completion. Each bound must
  // therefore outlive the budget the native side spends before it replies.
  // A bound at or below that budget expires first on every slow but healthy
  // connect. The user then gets a failure carrying `channelDeadline` while
  // the tunnel comes up seconds later. The native error that names the real
  // cause is dropped. These pins hold the native arithmetic against the
  // Dart bounds, so a native budget change fails here.
  //
  // Only start and stop are covered: their native chains are bounded end to
  // end. The status read ends in a synchronous binder transact with no
  // native timer. No budget can be derived for it.
  group('native completion budgets', () {
    test('the Android command path waits exactly the budgeted times', () {
      expect(
        _matchingLines(_androidConnectionPath, 'withTimeout('),
        _androidTimeoutLines,
      );
    });

    test('the Apple command path waits exactly the budgeted times', () {
      expect(
        _matchingLines(_appleVpnPath, RegExp(r'timeout: \d')),
        _appleStatusWaitLines,
      );
      expect(
        _matchingLines(_appleVpnPath, RegExp(r'timeoutSeconds: \d')),
        _appleSyncRequestLines,
      );
    });

    test('each command bound outlives every native budget', () {
      for (final budget in const {
        'macOS system extension': _appleStartBudget,
        'Android': _androidStartBudget,
      }.entries) {
        expect(
          ChannelDeadlines.startVpn,
          greaterThan(budget.value),
          reason:
              'the ${budget.key} start replies by ${budget.value.inSeconds}s '
              'on its own timers; a shorter bound reports channelDeadline '
              'first and drops that reply',
        );
      }
      for (final budget in const {
        'Apple': _appleStopBudget,
        'Android': _androidStopBudget,
      }.entries) {
        expect(
          ChannelDeadlines.stopVpn,
          greaterThan(budget.value),
          reason:
              'the ${budget.key} stop replies by ${budget.value.inSeconds}s '
              'on its own timers; a shorter bound reports channelDeadline '
              'first and drops that reply',
        );
      }
    });
  });

  test('the bounds are pinned', () {
    expect(ChannelDeadlines.startVpn, const Duration(seconds: 75));
    expect(ChannelDeadlines.stopVpn, const Duration(seconds: 25));
    expect(ChannelDeadlines.readVpnStatus, const Duration(seconds: 10));
    expect(ChannelDeadlines.invoke, const Duration(seconds: 10));
    expect(ChannelDeadlines.expired, 'channelDeadline');
  });
}
