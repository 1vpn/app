// The geodata refresh's failure backoff. A failed refresh stores a "not
// before" time 24 hours ahead, and every refresh before it is skipped. A
// refresh that succeeds clears it. A stored time beyond the backoff reads
// as passed. The data update service runs its default refresh through the
// shared backoff.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/net/geodata_refresh_backoff.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late DateTime now;
  late int calls;

  OneVpnGeoDataBackoff backoff() => OneVpnGeoDataBackoff(now: () => now);

  Future<void> ok() async => calls++;
  Future<void> fails() async {
    calls++;
    throw const SocketException('unreachable');
  }

  Future<int?> stored() =>
      SharedPreferencesAsync().getInt(OneVpnGeoDataBackoff.notBeforeKey);

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    now = DateTime.utc(2026, 10, 21, 9);
    calls = 0;
  });

  test('the backoff is 24 hours', () {
    expect(kOneVpnGeoDataRetryAfter, const Duration(hours: 24));
    expect(backoff().retryAfter, kOneVpnGeoDataRetryAfter);
  });

  test(
    'a failed refresh rethrows and skips every refresh for 24 hours',
    () async {
      await expectLater(backoff().run(fails), throwsA(isA<SocketException>()));
      expect(calls, 1);
      expect(
        await stored(),
        now.add(const Duration(hours: 24)).millisecondsSinceEpoch,
      );

      for (final later in [
        const Duration(hours: 1),
        const Duration(hours: 23, minutes: 59),
      ]) {
        now = DateTime.utc(2026, 10, 21, 9).add(later);
        await backoff().run(ok);
      }
      expect(calls, 1);

      now = DateTime.utc(2026, 10, 22, 9);
      await backoff().run(ok);
      expect(calls, 2);
      expect(await stored(), isNull);
    },
  );

  test(
    'a refresh with no stored time runs, and success stores nothing',
    () async {
      await backoff().run(ok);
      await backoff().run(ok);
      expect(calls, 2);
      expect(await stored(), isNull);
    },
  );

  test('a failure after the wait stores a new time', () async {
    await expectLater(backoff().run(fails), throwsA(anything));
    now = now.add(const Duration(hours: 25));
    await expectLater(backoff().run(fails), throwsA(anything));
    expect(calls, 2);
    expect(
      await stored(),
      now.add(const Duration(hours: 24)).millisecondsSinceEpoch,
    );
  });

  test('a stored time beyond the backoff reads as passed', () async {
    await SharedPreferencesAsync().setInt(
      OneVpnGeoDataBackoff.notBeforeKey,
      now.add(const Duration(days: 30)).millisecondsSinceEpoch,
    );
    await backoff().run(ok);
    expect(calls, 1);
    expect(await stored(), isNull);
  });

  test('the data update service runs the default refresh through the '
      'backoff', () {
    final source = File('lib/service/advanced/xray/data_update/service.dart')
        .readAsStringSync()
        .replaceAll(RegExp(r'\s+'), '');
    expect(
      source,
      contains(
        'awaitOneVpnGeoDataBackoff.instance.run(()=>GeoDataService().updateDefaults(),);',
      ),
    );
    expect('updateDefaults'.allMatches(source), hasLength(1));
  });
}
