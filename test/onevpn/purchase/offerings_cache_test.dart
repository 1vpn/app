// The offerings cache. One service has one cache. A load while a load runs
// shares it. A loaded result is kept, and a failed refresh keeps it. A load
// that outlasts its deadline answers unreachable and frees the next call.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/purchase/offerings_cache.dart';
import 'package:onexray/onevpn/purchase/purchase_service.dart';

const _offerings = OneVpnOfferings(
  yearly: OneVpnPurchasePackage(
    identifier: 'y',
    term: OneVpnPurchaseTerm.yearly,
    priceString: r'US$23.88',
    price: 23.88,
    currencyCode: 'USD',
  ),
);

/// A service that answers each load with the next scripted result and counts
/// the loads.
class _Scripted implements OneVpnPurchaseService {
  _Scripted(this.results);

  final List<Completer<OneVpnOfferingsResult>> results;
  int loads = 0;

  @override
  Future<OneVpnOfferingsResult> loadOfferings() => results[loads++].future;

  @override
  Future<OneVpnPurchaseOutcome> purchase({
    required OneVpnPurchasePackage package,
    required String email,
  }) => throw UnimplementedError();

  @override
  Future<void> identify(String appUserId) => throw UnimplementedError();

  @override
  Future<void> forget() => throw UnimplementedError();

  @override
  Future<bool> restorePurchaseSheet() => throw UnimplementedError();
}

/// A service whose load throws before it returns a future.
class _SyncThrow implements OneVpnPurchaseService {
  int loads = 0;
  bool fails = true;

  @override
  Future<OneVpnOfferingsResult> loadOfferings() {
    loads++;
    if (fails) throw StateError('boom');
    return Future.value(const OneVpnOfferingsUnavailable());
  }

  @override
  Future<OneVpnPurchaseOutcome> purchase({
    required OneVpnPurchasePackage package,
    required String email,
  }) => throw UnimplementedError();

  @override
  Future<void> identify(String appUserId) => throw UnimplementedError();

  @override
  Future<void> forget() => throw UnimplementedError();

  @override
  Future<bool> restorePurchaseSheet() => throw UnimplementedError();
}

void main() {
  test('one service always answers the same cache', () {
    final service = _Scripted([]);

    expect(
      identical(
        OneVpnOfferingsCache.forService(service),
        OneVpnOfferingsCache.forService(service),
      ),
      isTrue,
    );
    expect(
      identical(
        OneVpnOfferingsCache.forService(service),
        OneVpnOfferingsCache.forService(_Scripted([])),
      ),
      isFalse,
    );
  });

  test('nothing is loaded before the first load', () {
    expect(OneVpnOfferingsCache.forService(_Scripted([])).loaded, isNull);
  });

  test('a load while a load runs shares it', () async {
    final first = Completer<OneVpnOfferingsResult>();
    final service = _Scripted([first]);
    final cache = OneVpnOfferingsCache.forService(service);

    final a = cache.refresh();
    final b = cache.refresh();
    first.complete(const OneVpnOfferingsLoaded(_offerings));
    await Future.wait([a, b]);

    expect(service.loads, 1);
    expect(cache.loaded, same(_offerings));
  });

  test('a failed refresh keeps the loaded offerings', () async {
    final first = Completer<OneVpnOfferingsResult>();
    final second = Completer<OneVpnOfferingsResult>();
    final service = _Scripted([first, second]);
    final cache = OneVpnOfferingsCache.forService(service);

    first.complete(const OneVpnOfferingsLoaded(_offerings));
    await cache.refresh();
    second.complete(const OneVpnOfferingsUnreachable());
    final result = await cache.refresh();

    expect(result, isA<OneVpnOfferingsUnreachable>());
    expect(service.loads, 2);
    expect(cache.loaded, same(_offerings));
  });

  test('a load after the first one ends starts a new load', () async {
    final first = Completer<OneVpnOfferingsResult>()
      ..complete(const OneVpnOfferingsUnavailable());
    final second = Completer<OneVpnOfferingsResult>()
      ..complete(const OneVpnOfferingsLoaded(_offerings));
    final service = _Scripted([first, second]);
    final cache = OneVpnOfferingsCache.forService(service);

    await cache.refresh();
    expect(cache.loaded, isNull);
    await cache.refresh();

    expect(service.loads, 2);
    expect(cache.loaded, same(_offerings));
  });

  testWidgets('a stalled load answers unreachable at the deadline and frees '
      'the next call', (tester) async {
    final stalled = Completer<OneVpnOfferingsResult>();
    final second = Completer<OneVpnOfferingsResult>()
      ..complete(const OneVpnOfferingsLoaded(_offerings));
    final service = _Scripted([stalled, second]);
    final cache = OneVpnOfferingsCache.forService(service);
    OneVpnOfferingsResult? first;
    OneVpnOfferingsResult? shared;
    unawaited(cache.refresh().then((r) => first = r));
    unawaited(cache.refresh().then((r) => shared = r));

    await tester.pump(kOneVpnOfferingsDeadline - const Duration(seconds: 1));
    expect(first, isNull);

    await tester.pump(const Duration(seconds: 2));
    expect(first, isA<OneVpnOfferingsUnreachable>());
    expect(shared, isA<OneVpnOfferingsUnreachable>());
    expect(service.loads, 1);

    OneVpnOfferingsResult? next;
    unawaited(cache.refresh().then((r) => next = r));
    await tester.pump();

    expect(service.loads, 2);
    expect(next, isA<OneVpnOfferingsLoaded>());
    expect(cache.loaded, same(_offerings));
  });

  testWidgets('a late result after the deadline still fills the cache', (
    tester,
  ) async {
    final stalled = Completer<OneVpnOfferingsResult>();
    final service = _Scripted([stalled]);
    final cache = OneVpnOfferingsCache.forService(service);
    unawaited(cache.refresh());
    await tester.pump(kOneVpnOfferingsDeadline + const Duration(seconds: 1));

    stalled.complete(const OneVpnOfferingsLoaded(_offerings));
    await tester.pump();

    expect(cache.loaded, same(_offerings));
  });

  test('a load that throws before its first await does not stick', () async {
    final service = _SyncThrow();
    final cache = OneVpnOfferingsCache.forService(service);

    await expectLater(cache.refresh(), throwsStateError);
    service.fails = false;
    final result = await cache.refresh();

    expect(result, isA<OneVpnOfferingsUnavailable>());
    expect(service.loads, 2);
  });

  test('warm never throws and fills the cache', () async {
    final first = Completer<OneVpnOfferingsResult>()
      ..complete(const OneVpnOfferingsLoaded(_offerings));
    final service = _Scripted([first]);

    await OneVpnOfferingsCache.warm(service);

    expect(OneVpnOfferingsCache.forService(service).loaded, same(_offerings));
  });
}
