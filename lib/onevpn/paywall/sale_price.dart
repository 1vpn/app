// The plan card prices: the per-month figure a plan card shows, and the
// yearly plan's saving over twelve monthly payments. Both write the digits
// of the locale's number format.

import 'package:intl/intl.dart';

/// The per-month figure one plan card shows, as a plain amount in the
/// locale's number format.
class OneVpnSaleFigures {
  const OneVpnSaleFigures({required this.perMonth});

  /// The plan's price per month, to two decimals.
  final String perMonth;

  /// The figures for a plan priced [price] in [locale], or null without a
  /// price.
  ///
  /// A [locale] with no intl number data, such as Turkmen, formats as
  /// English.
  ///
  /// A [yearly] plan's price divides by 12, truncated to the micro-unit.
  /// The per-month price shows rounded half up to the cent.
  static OneVpnSaleFigures? of({
    required double? price,
    required bool yearly,
    required String locale,
  }) {
    if (price == null || price <= 0) return null;
    final micros = (price * 1000000).round();
    final monthlyMicros = yearly ? micros ~/ 12 : micros;
    // Whole cents: a half cent held as a double can format low.
    final cents = (monthlyMicros + 5000) ~/ 10000;
    return OneVpnSaleFigures(
      perMonth: _numberFormat('0.00', locale).format(cents / 100),
    );
  }
}

/// The yearly plan's saving over twelve monthly payments, as a whole
/// percent rounded half away from zero.
///
/// The saving is `100 * (1 - yearly / (12 * monthly))` on the two numeric
/// prices. It is null when either price is missing or not positive, or when
/// either currency is missing or the two differ. A yearly price above twelve
/// monthly payments gives a negative percent. Equal monthly costs give 0.
int? oneVpnYearlySavingPercent({
  required double? yearlyPrice,
  required String? yearlyCurrency,
  required double? monthlyPrice,
  required String? monthlyCurrency,
}) {
  if (yearlyPrice == null || monthlyPrice == null) return null;
  if (yearlyPrice <= 0 || monthlyPrice <= 0) return null;
  if (yearlyCurrency == null || yearlyCurrency != monthlyCurrency) return null;
  return (100 * (1 - yearlyPrice / (12 * monthlyPrice))).round();
}

/// The saving [percent] as a whole number in the number format of [locale].
/// It writes the digits of [OneVpnSaleFigures.perMonth] in [locale].
///
/// A [locale] with no intl number data, such as Turkmen, formats as
/// English.
String oneVpnSavingPercentText(int percent, {required String locale}) =>
    _numberFormat('0', locale).format(percent);

/// The number format for [pattern] in [locale]. A [locale] with no intl
/// number data formats as English.
NumberFormat _numberFormat(String pattern, String locale) => NumberFormat(
  pattern,
  Intl.verifiedLocale(
    locale,
    NumberFormat.localeExists,
    onFailure: (_) => 'en',
  ),
);
