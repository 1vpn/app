// The launch warm-up of the plan prices. It waits for the session to settle.
// A premium account makes no store call. Any other account loads the prices
// once, and the paywall then reads them from the cache.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/boot/plan_price_warmup.dart';
import 'package:onexray/onevpn/paywall/paywall_trigger.dart';
import 'package:onexray/onevpn/purchase/fake_purchase_service.dart';
import 'package:onexray/onevpn/purchase/offerings_cache.dart';

/// A session whose restore settles when [restored] completes and whose
/// entitlement reads [entitled] by then.
class _Audience implements OneVpnPaywallAudience {
  _Audience({this.entitled = false, Completer<void>? restored})
    : restored = restored ?? (Completer<void>()..complete());

  final Completer<void> restored;

  @override
  bool entitled;

  @override
  Future<void> whenRestored() => restored.future;
}

class _FailingAudience implements OneVpnPaywallAudience {
  @override
  bool get entitled => false;

  @override
  Future<void> whenRestored() => Future<void>.error(StateError('restore'));
}

void main() {
  test('an account that is not premium loads the prices once', () async {
    final service = OneVpnFakePurchaseService();

    await oneVpnWarmPlanPricesAtLaunch(service: service, audience: _Audience());

    expect(service.calls, ['loadOfferings']);
    expect(OneVpnOfferingsCache.forService(service).loaded, isNotNull);
  });

  test('a premium account makes no store call', () async {
    final service = OneVpnFakePurchaseService();

    await oneVpnWarmPlanPricesAtLaunch(
      service: service,
      audience: _Audience(entitled: true),
    );

    expect(service.calls, isEmpty);
    expect(OneVpnOfferingsCache.forService(service).loaded, isNull);
  });

  test('it waits for the session to settle before it decides', () async {
    final service = OneVpnFakePurchaseService();
    final restored = Completer<void>();
    final audience = _Audience(restored: restored);

    final warmed = oneVpnWarmPlanPricesAtLaunch(
      service: service,
      audience: audience,
    );
    await Future<void>.delayed(Duration.zero);
    expect(service.calls, isEmpty);

    // The restore settles on a premium account.
    audience.entitled = true;
    restored.complete();
    await warmed;

    expect(service.calls, isEmpty);
  });

  test(
    'a restore that settles on a free account then loads the prices',
    () async {
      final service = OneVpnFakePurchaseService();
      final restored = Completer<void>();

      final warmed = oneVpnWarmPlanPricesAtLaunch(
        service: service,
        audience: _Audience(restored: restored),
      );
      await Future<void>.delayed(Duration.zero);
      expect(service.calls, isEmpty);
      restored.complete();
      await warmed;

      expect(service.calls, ['loadOfferings']);
    },
  );

  test(
    'a session that fails to restore never throws and loads nothing',
    () async {
      final service = OneVpnFakePurchaseService();

      await oneVpnWarmPlanPricesAtLaunch(
        service: service,
        audience: _FailingAudience(),
      );

      expect(service.calls, isEmpty);
    },
  );
}
