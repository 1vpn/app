// The boot step bounds. A critical step that throws or hangs past its bound
// aborts with a StateError. An optional step that throws or hangs past its
// bound completes normally, so boot reaches runApp.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/boot/boot_steps.dart';

const _bound = Duration(milliseconds: 20);

Future<void> _hang() => Completer<void>().future;

void main() {
  test('each boot step is bounded at 10 s', () {
    expect(kOneVpnBootStepTimeout, const Duration(seconds: 10));
  });

  test('a hanging critical step aborts with a StateError', () async {
    await expectLater(
      oneVpnCriticalStep(_hang, timeout: _bound),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          startsWith('critical boot step failed: TimeoutException'),
        ),
      ),
    );
  });

  test('a throwing critical step aborts with a StateError', () async {
    await expectLater(
      oneVpnCriticalStep(() async => throw Exception('no dir')),
      throwsA(isA<StateError>()),
    );
  });

  test('a critical step runs its synchronous prefix before returning', () {
    var ran = false;
    final pending = oneVpnCriticalStep(() async {
      ran = true;
      await _hang();
    }, timeout: _bound);
    expect(ran, isTrue);
    expect(pending, throwsA(isA<StateError>()));
  });

  test('a hanging optional step completes after its bound', () async {
    await expectLater(
      oneVpnOptionalStep('hang', _hang, timeout: _bound),
      completes,
    );
  });

  test('a throwing optional step completes normally', () async {
    await expectLater(
      oneVpnOptionalStep('throw', () async => throw Exception('store')),
      completes,
    );
  });
}
