// The cooldown decision, pinned against a clock rather than against a
// day of wall time.

import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/account/refresh_cooldown.dart';

void main() {
  final now = DateTime.utc(2026, 9, 15, 12);

  test('the shipped cooldown is 24 hours', () {
    expect(kOneVpnRefreshCooldown, const Duration(hours: 24));
  });

  test('a device that never refreshed is due', () {
    expect(isRefreshDue(null, now), isTrue);
  });

  test('a refresh inside the window is not due', () {
    expect(isRefreshDue(now.subtract(const Duration(hours: 23)), now), isFalse);
    expect(
      isRefreshDue(now.subtract(const Duration(hours: 23, minutes: 59)), now),
      isFalse,
    );
  });

  test('a refresh exactly a cooldown ago is due', () {
    expect(isRefreshDue(now.subtract(const Duration(hours: 24)), now), isTrue);
  });

  test('a refresh past the window is due', () {
    expect(isRefreshDue(now.subtract(const Duration(days: 9)), now), isTrue);
  });

  // Phone clocks move backwards. A stamp from the future must not pin the
  // cooldown shut until wall time catches up.
  test('a stamp in the future reads as due', () {
    expect(isRefreshDue(now.add(const Duration(days: 30)), now), isTrue);
    expect(isRefreshDue(now.add(const Duration(seconds: 1)), now), isTrue);
  });

  test('the window is a parameter, so a caller can shorten it', () {
    final stamp = now.subtract(const Duration(minutes: 30));
    expect(
      isRefreshDue(stamp, now, cooldown: const Duration(hours: 1)),
      isFalse,
    );
    expect(
      isRefreshDue(stamp, now, cooldown: const Duration(minutes: 15)),
      isTrue,
    );
  });
}
