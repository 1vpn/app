// The per-month figure: the division, the rounding, and the number format.
// The yearly saving: the percent and the cases that give none. The saving
// percent text: the locale digits, and English digits where intl has no
// number data.

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:onexray/onevpn/paywall/sale_price.dart';

void main() {
  setUpAll(() => initializeDateFormatting());

  test('a yearly price reads per month', () {
    final figures = OneVpnSaleFigures.of(
      price: 23.88,
      yearly: true,
      locale: 'en',
    )!;
    expect(figures.perMonth, '1.99');
  });

  test('a monthly price keeps its amount', () {
    final figures = OneVpnSaleFigures.of(
      price: 4.99,
      yearly: false,
      locale: 'en',
    )!;
    expect(figures.perMonth, '4.99');
  });

  test('the yearly division truncates to the micro-unit', () {
    // 10.00 over 12 is 0.8333... The micro-unit truncation keeps 0.833333.
    final figures = OneVpnSaleFigures.of(
      price: 10,
      yearly: true,
      locale: 'en',
    )!;
    expect(figures.perMonth, '0.83');
  });

  test('the per-month price rounds half up to the cent', () {
    // 12.06 over 12 is exactly 1.005.
    final figures = OneVpnSaleFigures.of(
      price: 12.06,
      yearly: true,
      locale: 'en',
    )!;
    expect(figures.perMonth, '1.01');
  });

  test('the amount takes the locale number format', () {
    final figures = OneVpnSaleFigures.of(
      price: 23.88,
      yearly: true,
      locale: 'de',
    )!;
    expect(figures.perMonth, '1,99');
  });

  test('a locale with no intl number data formats as English', () {
    final figures = OneVpnSaleFigures.of(
      price: 23.88,
      yearly: true,
      locale: 'tk',
    )!;
    expect(figures.perMonth, '1.99');
  });

  test('a missing or zero price yields no figures', () {
    expect(
      OneVpnSaleFigures.of(price: null, yearly: true, locale: 'en'),
      isNull,
    );
    expect(OneVpnSaleFigures.of(price: 0, yearly: false, locale: 'en'), isNull);
  });

  group('the yearly saving', () {
    int? saving(
      double? yearly,
      double? monthly, {
      String? yearlyCurrency = 'USD',
      String? monthlyCurrency = 'USD',
    }) => oneVpnYearlySavingPercent(
      yearlyPrice: yearly,
      yearlyCurrency: yearlyCurrency,
      monthlyPrice: monthly,
      monthlyCurrency: monthlyCurrency,
    );

    test('1.99 a month against 4.99 saves 60 percent', () {
      expect(saving(23.88, 4.99), 60);
    });

    test('equal monthly costs save 0 percent', () {
      expect(saving(59.88, 4.99), 0);
    });

    test('a yearly price above twelve monthly payments is negative', () {
      expect(saving(71.88, 4.99), -20);
    });

    test('the percent rounds to the nearest whole', () {
      // 39.99 against 83.88 saves 52.33 percent.
      expect(saving(39.99, 6.99), 52);
    });

    test('a missing price gives none', () {
      expect(saving(null, 4.99), isNull);
      expect(saving(23.88, null), isNull);
      expect(saving(null, null), isNull);
    });

    test('a price that is not positive gives none', () {
      expect(saving(0, 4.99), isNull);
      expect(saving(23.88, 0), isNull);
    });

    test('a missing or differing currency gives none', () {
      expect(saving(23.88, 4.99, yearlyCurrency: null), isNull);
      expect(saving(23.88, 4.99, monthlyCurrency: null), isNull);
      expect(saving(23.88, 4.99, monthlyCurrency: 'EUR'), isNull);
    });
  });

  group('the saving percent text', () {
    // The Test Store prices: 23.88 a year against 4.99 a month.
    final percent = oneVpnYearlySavingPercent(
      yearlyPrice: 23.88,
      yearlyCurrency: 'USD',
      monthlyPrice: 4.99,
      monthlyCurrency: 'USD',
    )!;

    test('the Test Store saving reads 60 in Persian digits under fa', () {
      expect(oneVpnSavingPercentText(percent, locale: 'fa'), '۶۰');
      // Anti-vacuity: the per-month price writes Persian digits too.
      expect(
        OneVpnSaleFigures.of(
          price: 23.88,
          yearly: true,
          locale: 'fa',
        )!.perMonth,
        '۱٫۹۹',
      );
    });

    test('bn and my write their own digits', () {
      expect(oneVpnSavingPercentText(percent, locale: 'bn'), '৬০');
      expect(oneVpnSavingPercentText(percent, locale: 'my'), '၆၀');
    });

    test('a locale with no intl number data reads 60 in English digits', () {
      expect(oneVpnSavingPercentText(percent, locale: 'tk'), '60');
    });
  });
}
