import 'package:onexray/onevpn/net/api_transport.dart';
import 'package:onexray/onevpn/net/failover_domains.dart';

/// The liveness probe URLs, one per failover domain.
///
/// Every domain serves `HEAD /ping/`, which answers the literal `1`. An
/// answer proves reachability and nothing more.
abstract final class ProbeEndpoints {
  /// In the order of [OneVpnFailoverDomains.all]. The first entry is the
  /// primary.
  static final urls = [
    for (final domain in OneVpnFailoverDomains.all) 'https://$domain/ping/',
  ];

  /// The probe URL on the domain the account API reached, read at call time.
  ///
  /// The probe egresses from the node, so it fetches the domain the account
  /// walk found answering. A primary that is dead everywhere then holds no
  /// connect once the walk has reached a backup.
  ///
  /// The host comes from [OneVpnApiTransport.activeBaseUrl], which makes no
  /// network call. The probe reads the remembered domain and never writes
  /// it. With no remembered domain, the result is the first entry of
  /// [urls]. A failed read or a host outside [urls] also answers the first
  /// entry.
  ///
  /// [transport] defaults to [OneVpnApiTransport.instance].
  static Future<String> resolve({OneVpnApiTransport? transport}) async {
    try {
      final base = Uri.parse(
        await (transport ?? OneVpnApiTransport.instance).activeBaseUrl(),
      );
      final url = 'https://${base.host}/ping/';
      if (base.scheme == 'https' && urls.contains(url)) return url;
    } catch (_) {
      // Falls through to the primary.
    }
    return urls.first;
  }
}
