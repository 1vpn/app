// Pins the bound on the consent form load.
//
// A load within the bound resolves its value. A load past the bound fails
// with a timeout, and its late value goes to the late handler. A load that
// fails within the bound fails with its own error. A late error is dropped.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/ads/admob_ad_gateway.dart';

const _limit = Duration(milliseconds: 20);

void main() {
  test('the form load bound is 20 seconds', () {
    expect(OneVpnAdMobAdGateway.formLoadTimeout, const Duration(seconds: 20));
  });

  test('a load within the bound resolves its value', () async {
    final late = <String>[];
    final value = await oneVpnBoundedLoad(
      Future.value('form'),
      _limit,
      onLate: late.add,
    );

    expect(value, 'form');
    expect(late, isEmpty);
  });

  test('a load past the bound times out and hands its value over', () async {
    final load = Completer<String>();
    final late = <String>[];

    await expectLater(
      oneVpnBoundedLoad(load.future, _limit, onLate: late.add),
      throwsA(isA<TimeoutException>()),
    );
    load.complete('form');
    await Future<void>.delayed(Duration.zero);

    expect(late, ['form']);
  });

  test('a failed load within the bound fails with its error', () async {
    await expectLater(
      oneVpnBoundedLoad<String>(
        Future.error(StateError('no form')),
        _limit,
        onLate: (_) {},
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('a failure past the bound is dropped', () async {
    final load = Completer<String>();
    final late = <String>[];

    await expectLater(
      oneVpnBoundedLoad(load.future, _limit, onLate: late.add),
      throwsA(isA<TimeoutException>()),
    );
    load.completeError(StateError('no form'));
    await Future<void>.delayed(Duration.zero);

    expect(late, isEmpty);
  });
}
