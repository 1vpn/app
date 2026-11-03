import 'package:onexray/core/tools/logger.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/account/refresh_cooldown.dart';
import 'package:onexray/onevpn/net/api_transport.dart';

/// The bound on the launch probe as a boot step.
///
/// It covers the slowest walk over four domains: a 10 s connect and a 10 s
/// receive on each. The probe still finishes after the bound, and its
/// result still counts.
const Duration kOneVpnLaunchReachabilityBound = Duration(seconds: 90);

/// Probes the API domains once at launch for a signed-out account.
///
/// The probe is one `HEAD /ping/` walk through [transport]. The answering
/// domain becomes the transport's record, so web links and the backup
/// notice follow it. Only a signed-out account probes. A signed-in account
/// forms the record through its refresh.
///
/// Waits for [account] to settle the stored session, so it belongs after
/// the boot step that restores the account. Runs at most once per
/// [cooldown] after a probe that found a domain. A probe that finds none
/// leaves the stamp alone, so the next launch probes again.
///
/// [transport] and [account] default to the process-wide instances. [now]
/// defaults to the wall clock.
Future<void> oneVpnProbeReachabilityAtLaunch({
  OneVpnApiTransport? transport,
  OneVpnAccountService? account,
  DateTime Function()? now,
  Duration cooldown = kOneVpnRefreshCooldown,
}) async {
  final settled = account ?? OneVpnAccountService.instance;
  await settled.whenRestored();
  if (settled.state.value is! OneVpnAccountSignedOut) return;
  final api = transport ?? OneVpnApiTransport.instance;
  final due = isRefreshDue(
    await api.lastReachabilityAt(),
    (now ?? DateTime.now)(),
    cooldown: cooldown,
  );
  if (!due) return;
  if (await api.probeReachability() == null) {
    ygLogger('launch reachability: no domain answered');
  }
}
