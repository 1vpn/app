// The stored record of a purchase that waits for an account: the address
// it was made against and the store's id for the customer that made it,
// under two fork keys.
//
// The launch check and the recurring paywall's cadence both read it through
// [OneVpnPendingPurchaseRecord.heldWhileSignedOut].

import 'package:onexray/onevpn/account/account_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether [a] and [b] name the same account address. The match ignores
/// case.
bool oneVpnSameAddress(String a, String b) =>
    a.toLowerCase() == b.toLowerCase();

/// The stored record of a purchase that waits for an account.
///
/// No method throws. An unreadable record reads as absent. A refused write
/// leaves the record as it was.
class OneVpnPendingPurchaseRecord {
  OneVpnPendingPurchaseRecord({SharedPreferencesAsync? preferences})
    : _injected = preferences;

  final SharedPreferencesAsync? _injected;

  late final SharedPreferencesAsync _preferences =
      _injected ?? SharedPreferencesAsync();

  /// The fork's own key. It holds the address the purchase was made
  /// against.
  static const emailKey = 'onevpn.purchasePendingAccountEmail';

  /// The fork's own key. It holds the store's id for the customer that made
  /// the purchase.
  static const customerKey = 'onevpn.purchasePendingAccountCustomer';

  /// Records that a purchase made against [email] by the store customer
  /// [customerId] waits for an account. An empty address records nothing.
  /// A null or empty [customerId] stores the address with no customer.
  Future<void> record(String email, {String? customerId}) async {
    if (email.isEmpty) return;
    try {
      await _preferences.setString(emailKey, email);
      if (customerId == null || customerId.isEmpty) {
        await _preferences.remove(customerKey);
      } else {
        await _preferences.setString(customerKey, customerId);
      }
    } catch (_) {
      // A refused write costs the reminder on later launches.
    }
  }

  /// The address of the purchase that waits for an account, or null when
  /// none waits.
  Future<String?> read() async {
    try {
      final stored = await _preferences.getString(emailKey);
      return stored == null || stored.isEmpty ? null : stored;
    } catch (_) {
      return null;
    }
  }

  /// The store's id for the customer that made the purchase, or null when
  /// the record names none.
  Future<String?> readCustomer() async {
    try {
      final stored = await _preferences.getString(customerKey);
      return stored == null || stored.isEmpty ? null : stored;
    } catch (_) {
      return null;
    }
  }

  /// Removes the record.
  Future<void> clear() async {
    try {
      await _preferences.clear(allowList: {emailKey, customerKey});
    } catch (_) {
      // A refused remove leaves the record. A signed-in launch still never
      // shows the screen.
    }
  }

  /// The address of the purchase that waits for an account while [state]
  /// is signed out, or null. Any other state answers null and reads
  /// nothing.
  Future<String?> heldWhileSignedOut(OneVpnAccountState state) async {
    if (state is! OneVpnAccountSignedOut) return null;
    return read();
  }
}
