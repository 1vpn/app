import 'package:onexray/onevpn/paywall/paywall_trigger.dart';
import 'package:onexray/onevpn/purchase/offerings_cache.dart';
import 'package:onexray/onevpn/purchase/purchase_backend.dart';
import 'package:onexray/onevpn/purchase/purchase_service.dart';

/// Loads the plan prices at launch for an account that is not premium, so the
/// paywall opens with them.
///
/// Waits for [audience] to settle the stored session, so it belongs after the
/// boot step that restores the account. A premium account never sees the
/// paywall, so the warm-up makes no store call for it. A session that cannot
/// be read counts as not premium. [service] defaults to the build's purchase
/// service, and [audience] to the process-wide account service. Never throws,
/// and nothing waits for it.
Future<void> oneVpnWarmPlanPricesAtLaunch({
  OneVpnPurchaseService? service,
  OneVpnPaywallAudience? audience,
}) async {
  try {
    final settled = audience ?? const OneVpnServicePaywallAudience();
    await settled.whenRestored();
    if (settled.entitled) return;
    await OneVpnOfferingsCache.warm(service ?? oneVpnPurchaseBackend());
  } catch (_) {
    // A failed warm-up leaves the paywall to load on open.
  }
}
