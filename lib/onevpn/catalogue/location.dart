// The catalogue's domain model: a location, its servers, and the node identity
// the provisioner keys database rows on.
//
// A location holds zero or more servers, each dialed with per-user REALITY
// credentials. Row naming and display identity are separate values. Each
// declaration states which it is.

import 'package:onexray/onevpn/model/user_data.dart';

/// The REALITY SNI a server takes when the API sends none.
///
/// The app presents it to the node as TLS camouflage. It is never a dialed
/// destination.
const kOneVpnDefaultRealityServerName = 'www.cloudflare.com';

/// A single node endpoint.
///
/// [sni] is REALITY's `serverName`, and it varies per server. [ip] and [ip6]
/// are the optional dial literals. The outbound dials a present literal and
/// skips resolution. With neither literal, it resolves [host].
class OneVpnServer {
  const OneVpnServer({
    required this.host,
    required this.sni,
    this.ip,
    this.ip6,
  });

  final String host;
  final String sni;

  /// The IPv4 literal, or null. [dialAddress] picks the address to dial.
  final String? ip;

  /// The IPv6 literal, or null.
  final String? ip6;

  /// The address the outbound dials.
  ///
  /// Prefers [ip], then [ip6] when it is the only literal, then [host]. The
  /// compile strips the outbound domain strategy, so a hostname resolves
  /// through libXray's process resolver. The query goes in plaintext to port
  /// 53 of the TUN DNS address, on a protected socket outside the tunnel.
  /// Free nodes dial build-time literals. Only an account server delivered
  /// without an address resolves by name. The REALITY [sni] stays the same.
  /// Only the dial address changes.
  String get dialAddress => ip ?? ip6 ?? host;

  @override
  bool operator ==(Object other) =>
      other is OneVpnServer &&
      other.host == host &&
      other.sni == sni &&
      other.ip == ip &&
      other.ip6 == ip6;

  @override
  int get hashCode => Object.hash(host, sni, ip, ip6);
}

/// A user-facing location.
///
/// [code] is the stable row key, so renaming the display label never orphans a
/// node. It is distinct from [displayCode], the code a place name is translated
/// by. See that getter for why the two differ.
class OneVpnLocation {
  const OneVpnLocation({
    required this.code,
    required this.city,
    required this.country,
    required this.countryCode,
    required this.servers,
    this.premium = false,
    this.freeTier = true,
  });

  final String code;
  final String city;
  final String country;
  final String countryCode;
  final List<OneVpnServer> servers;

  /// The teaser flag from the free catalogue: a teaser requires premium.
  /// This is not a tier flag. The account's own locations come back with this
  /// false or absent. Use [freeTier] to ask which list a location came from.
  final bool premium;

  /// True when the location came from the compiled-in free list rather than
  /// from the account.
  final bool freeTier;

  /// Maps the wire shape onto the domain model.
  ///
  /// A teaser arrives with `servers == null` and becomes `servers: []`. The
  /// provisioner then skips it with no special case. `cityCode` and `city` are
  /// nullable on the wire. The country stands in for either. A server with no
  /// `realityServerName` takes the default SNI.
  static OneVpnLocation fromApi(
    OneVpnApiLocation location, {
    required bool freeTier,
  }) => OneVpnLocation(
    code: location.cityCode ?? location.countryCode,
    city: location.city ?? location.country,
    country: location.country,
    countryCode: location.countryCode,
    servers: <OneVpnServer>[
      for (final server in location.servers ?? const <OneVpnApiServer>[])
        OneVpnServer(
          host: server.host,
          sni: server.realityServerName ?? kOneVpnDefaultRealityServerName,
          ip: server.ip,
          ip6: server.ip6,
        ),
    ],
    premium: location.isPremium,
    freeTier: freeTier,
  );

  /// The code [city] must be translated by, or null when there is none.
  ///
  /// [code] is the row key: `cityCode ?? countryCode`, then disambiguated
  /// within its tier. When the API sends a city with no cityCode, [code] is
  /// the country's code. A place-name table would then answer `jp` with
  /// "Japan" over a row named "Osaka". A consumer looks a translation up by
  /// this getter, not by [code]. It never returns the country's code while a
  /// city name is on screen:
  ///
  ///  * When [code] differs from [countryCode], it returns [code]. That is a
  ///    city code, or a disambiguated code that has no translation and falls
  ///    back.
  ///  * Otherwise, when [city] is [country], the name shown is the country's
  ///    own name. It returns [countryCode].
  ///  * Otherwise there is nothing to look up. It returns null, and a consumer
  ///    falls back to the server-sent name.
  String? get displayCode {
    if (code != countryCode) return code;
    return city == country ? countryCode : null;
  }

  /// The prefix shared by every row this app provisions, free floor and
  /// account alike. A sweep scopes to it, so a row a user added by hand is out
  /// of reach.
  static const rowNamePrefix = '1vpn·';

  /// The prefix of account rows, provisioned with the session credentials.
  /// Sign-out removes these. The free floor outlives the session.
  static const accountRowNamePrefix = '${rowNamePrefix}acct·';

  /// The prefix of the embedded free-floor rows, provisioned at boot with the
  /// build-time free triple. These survive sign-out.
  static const freeRowNamePrefix = '${rowNamePrefix}free·';

  /// The name-stem every one of this location's rows shares.
  ///
  /// A location selection scopes to its rows by this stem. The tier segment
  /// is part of it for the same reason it is part of [rowName].
  String get rowNameStem =>
      '${freeTier ? freeRowNamePrefix : accountRowNamePrefix}$code';

  /// The name a node row carries in the database. The name is deterministic,
  /// so each sync overwrites the row of the same name instead of adding a
  /// duplicate.
  ///
  /// The tier segment is load-bearing. A premium account sees the free nodes
  /// alongside its own. Both catalogues carry an Amsterdam with cityCode `ams`
  /// on different hosts. The segment keeps their rows apart: `1vpn·free·ams·1`
  /// and `1vpn·acct·ams·1`. With one shared name, one row would overwrite the
  /// other. The survivor would pair one tier's host with the other tier's
  /// credentials.
  String rowName(int serverIndex) => '$rowNameStem·${serverIndex + 1}';
}
