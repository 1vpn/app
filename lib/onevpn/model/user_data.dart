// The account API's response payload: `UserData` and the two types
// nested in it.
//
// Each field name matches its wire key verbatim: `sessionAuthToken`,
// `isPremium`, `realityServerName` and so on. Renaming a field here makes
// it read as null.
//
// Parsing never throws. A malformed payload yields null, and the caller
// reports it as OneVpnApiMalformed instead of crashing a sign-in. Some
// networks interfere with the API, so an unexpected body is an ordinary
// runtime case.
//
// The parse ignores unknown fields: it neither fails on them nor surfaces
// them. The server can add a field before any client models it.

import 'dart:io';

/// Reads [key] as a [String], or null when it is absent or another type.
///
/// A wrong-typed field reads as absent, so no cast throws out of the
/// decode.
String? _string(Map<String, dynamic> json, String key) {
  final value = json[key];
  return value is String ? value : null;
}

/// Reads [key] as a [bool], or null when it is absent or another type.
bool? _bool(Map<String, dynamic> json, String key) {
  final value = json[key];
  return value is bool ? value : null;
}

/// One VLESS endpoint inside a [OneVpnApiLocation].
class OneVpnApiServer {
  const OneVpnApiServer({
    required this.host,
    this.realityServerName,
    this.ip,
    this.ip6,
  });

  final String host;

  /// The REALITY SNI. Null means "use the default", not "no SNI". The code
  /// that compiles the outbound picks and substitutes the default.
  final String? realityServerName;

  /// The server's IPv4 literal, or null when the API sends none.
  ///
  /// Absent and null are identical: both mean "resolve the host". A
  /// present value lets the dialer skip DoH resolution for this node and
  /// dial the literal. The parse drops a value that is not a syntactic IPv4
  /// address, so the node keeps its hostname path.
  final String? ip;

  /// The server's IPv6 literal, or null. It follows the absent-is-null rule
  /// of [ip] and validates as IPv6.
  final String? ip6;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'host': host,
    if (realityServerName != null) 'realityServerName': realityServerName,
    if (ip != null) 'ip': ip,
    if (ip6 != null) 'ip6': ip6,
  };

  static OneVpnApiServer? fromJson(Map<String, dynamic> json) {
    final host = _string(json, 'host');
    if (host == null || host.isEmpty) return null;
    return OneVpnApiServer(
      host: host,
      realityServerName: _string(json, 'realityServerName'),
      ip: _ipLiteral(json, 'ip', InternetAddressType.IPv4),
      ip6: _ipLiteral(json, 'ip6', InternetAddressType.IPv6),
    );
  }
}

/// Reads [key] as an IP literal of [type]. Returns null when the value is
/// absent, another type, or not a syntactic address of that family.
String? _ipLiteral(
  Map<String, dynamic> json,
  String key,
  InternetAddressType type,
) {
  final value = _string(json, key);
  if (value == null) return null;
  final parsed = InternetAddress.tryParse(value);
  return parsed != null && parsed.type == type ? value : null;
}

/// A location the account may connect to, or may only see.
class OneVpnApiLocation {
  const OneVpnApiLocation({
    this.city,
    this.cityCode,
    required this.country,
    required this.countryCode,
    this.servers,
    this.isPremium = false,
  });

  final String? city;
  final String? cityCode;
  final String country;
  final String countryCode;

  /// Null marks a premium *teaser*: the API sent no endpoints. The list
  /// shows a teaser and routes it to the paywall, not to a tunnel.
  final List<OneVpnApiServer>? servers;

  final bool isPremium;

  /// Whether this location can actually be dialed.
  ///
  /// Null and empty [servers] both mean not connectable. Every code path
  /// must treat the two forms the same way.
  bool get isConnectable => servers != null && servers!.isNotEmpty;

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (city != null) 'city': city,
    if (cityCode != null) 'cityCode': cityCode,
    'country': country,
    'countryCode': countryCode,
    // The serialized form keeps null and empty apart. A teaser's null
    // servers list becomes an absent key, never `[]`.
    if (servers != null)
      'servers': servers!.map((s) => s.toJson()).toList(growable: false),
    'isPremium': isPremium,
  };

  static OneVpnApiLocation? fromJson(Map<String, dynamic> json) {
    final country = _string(json, 'country');
    final countryCode = _string(json, 'countryCode');
    if (country == null || countryCode == null) return null;

    final rawServers = json['servers'];
    List<OneVpnApiServer>? servers;
    if (rawServers is List) {
      servers = <OneVpnApiServer>[
        for (final entry in rawServers)
          if (entry is Map<String, dynamic>) ?OneVpnApiServer.fromJson(entry),
      ];
      // A non-empty list whose rows all fail to parse is not a teaser. The
      // parse drops the whole location.
      if (rawServers.isNotEmpty && servers.isEmpty) return null;
    }

    return OneVpnApiLocation(
      city: _string(json, 'city'),
      cityCode: _string(json, 'cityCode'),
      country: country,
      countryCode: countryCode,
      servers: servers,
      isPremium: _bool(json, 'isPremium') ?? false,
    );
  }
}

/// The REALITY triple the user data carries.
///
/// A premium account's triple dials its account nodes. A free account's
/// carries the free tier's triple, or arrives empty or null. The parse reads
/// empty and null as an empty string, and [isComplete] then reports false.
class OneVpnCredentials {
  const OneVpnCredentials({
    required this.uuid,
    required this.publicKey,
    required this.shortId,
  });

  final String uuid;
  final String publicKey;
  final String shortId;

  bool get isComplete =>
      uuid.isNotEmpty && publicKey.isNotEmpty && shortId.isNotEmpty;
}

/// The whole account payload. Login, signup and get_user_data all return
/// it. Signup therefore signs the user in: its response carries the token.
class OneVpnUserData {
  const OneVpnUserData({
    required this.username,
    required this.email,
    required this.isPremium,
    required this.sessionAuthToken,
    required this.credentials,
    required this.locations,
  });

  final String username;
  final String email;
  final bool isPremium;
  final String sessionAuthToken;
  final OneVpnCredentials credentials;
  final List<OneVpnApiLocation> locations;

  /// [requireToken] is true for login and signup. Those calls exist to
  /// return a session token. Without one there is no session to persist,
  /// so the decode refuses the payload.
  ///
  /// [requireToken] is false for `get_user_data_api`. That endpoint reports
  /// entitlement, not authentication, and its payload may omit the token.
  ///
  /// Every body must carry `isPremium` as a bool, whatever [requireToken]
  /// says. The decode refuses a body with `isPremium` absent or wrong-typed.
  /// Otherwise an error page or a captive-portal 200 would decode as a free
  /// account. That account would have no locations and no credentials. A
  /// session token in the body does not exempt it from this check.
  static OneVpnUserData? fromJson(
    Map<String, dynamic> json, {
    bool requireToken = true,
  }) {
    final token = _string(json, 'sessionAuthToken');
    if (requireToken && (token == null || token.isEmpty)) return null;

    final isPremium = _bool(json, 'isPremium');
    if (isPremium == null) return null;

    final rawLocations = json['locations'];
    final locations = <OneVpnApiLocation>[
      if (rawLocations is List)
        for (final entry in rawLocations)
          if (entry is Map<String, dynamic>) ?OneVpnApiLocation.fromJson(entry),
    ];

    return OneVpnUserData(
      username: _string(json, 'username') ?? '',
      email: _string(json, 'email') ?? '',
      isPremium: isPremium,
      // An absent token becomes empty, never null. The caller then keeps
      // the token it already holds.
      sessionAuthToken: token ?? '',
      credentials: OneVpnCredentials(
        uuid: _string(json, 'uuid') ?? '',
        publicKey: _string(json, 'publicKey') ?? '',
        shortId: _string(json, 'shortId') ?? '',
      ),
      locations: locations,
    );
  }
}
