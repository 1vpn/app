// The persisted session document: everything a signed-in account needs to
// work without a network round trip, plus the pending-premium marker.

import 'package:onexray/onevpn/model/user_data.dart';

/// The whole account session as it is persisted.
///
/// The document holds the session token, the account identity, the
/// entitlement, the locations payload with its per-account REALITY
/// credentials, and the pending-premium marker. The UI process dies
/// routinely while the tunnel runs. The persisted session lets a restart
/// work offline.
///
/// [premiumPendingSince] lives inside this document. Clearing the session
/// clears the marker in the same write. No code path can produce a marker
/// with no session.
class OneVpnSession {
  const OneVpnSession({
    required this.sessionAuthToken,
    required this.username,
    required this.email,
    required this.isPremium,
    required this.credentials,
    required this.locations,
    this.premiumPendingSince,
  });

  /// The bearer token for every authenticated call.
  final String sessionAuthToken;

  final String username;
  final String email;

  /// The entitlement the server last reported.
  final bool isPremium;

  /// The per-account REALITY triple. Empty for a free account.
  final OneVpnCredentials credentials;

  /// The catalogue payload as the server last sent it.
  final List<OneVpnApiLocation> locations;

  /// When an optimistic premium grant was recorded, or null when no grant
  /// is pending. A completed purchase sets it. Only a refresh outcome
  /// clears it.
  ///
  /// The timestamp is in UTC. The window it is measured against stays
  /// fixed across time zones.
  final DateTime? premiumPendingSince;

  /// True while a premium grant is recorded but unconfirmed.
  bool get isPremiumPending => premiumPendingSince != null;

  /// The entitlement the catalogue acts on. A pending grant reads as
  /// premium. A completed purchase unlocks before the server confirms it.
  bool get isPremiumEntitled => isPremium || isPremiumPending;

  OneVpnSession copyWith({
    String? sessionAuthToken,
    String? username,
    String? email,
    bool? isPremium,
    OneVpnCredentials? credentials,
    List<OneVpnApiLocation>? locations,
    DateTime? premiumPendingSince,
    bool clearPremiumPendingSince = false,
  }) => OneVpnSession(
    sessionAuthToken: sessionAuthToken ?? this.sessionAuthToken,
    username: username ?? this.username,
    email: email ?? this.email,
    isPremium: isPremium ?? this.isPremium,
    credentials: credentials ?? this.credentials,
    locations: locations ?? this.locations,
    premiumPendingSince: clearPremiumPendingSince
        ? null
        : (premiumPendingSince ?? this.premiumPendingSince),
  );

  /// Builds the first session document of a sign-in from a server
  /// payload. Carries no marker: a fresh sign-in has no pending grant.
  static OneVpnSession fromUserData(OneVpnUserData data) => OneVpnSession(
    sessionAuthToken: data.sessionAuthToken,
    username: data.username,
    email: data.email,
    isPremium: data.isPremium,
    credentials: data.credentials,
    locations: data.locations,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'sessionAuthToken': sessionAuthToken,
    'username': username,
    'email': email,
    'isPremium': isPremium,
    'uuid': credentials.uuid,
    'publicKey': credentials.publicKey,
    'shortId': credentials.shortId,
    'locations': locations
        .map((location) => location.toJson())
        .toList(growable: false),
    if (premiumPendingSince != null)
      'premiumPendingSince': premiumPendingSince!.millisecondsSinceEpoch,
  };

  /// Decodes a persisted document, or returns null when the text is not
  /// one.
  ///
  /// Returns null rather than throwing. Only a missing token or a missing
  /// entitlement returns null. Every other field falls back.
  ///
  /// A location row that will not parse is dropped. The rest of the
  /// document survives.
  static OneVpnSession? fromJson(Map<String, dynamic> json) {
    final token = json['sessionAuthToken'];
    if (token is! String || token.isEmpty) return null;

    final isPremium = json['isPremium'];
    if (isPremium is! bool) return null;

    final rawLocations = json['locations'];
    final locations = <OneVpnApiLocation>[
      if (rawLocations is List)
        for (final entry in rawLocations)
          if (entry is Map<String, dynamic>) ?OneVpnApiLocation.fromJson(entry),
    ];

    final pending = json['premiumPendingSince'];

    return OneVpnSession(
      sessionAuthToken: token,
      username: _string(json, 'username') ?? '',
      email: _string(json, 'email') ?? '',
      isPremium: isPremium,
      credentials: OneVpnCredentials(
        uuid: _string(json, 'uuid') ?? '',
        publicKey: _string(json, 'publicKey') ?? '',
        shortId: _string(json, 'shortId') ?? '',
      ),
      locations: locations,
      premiumPendingSince: pending is int
          ? DateTime.fromMillisecondsSinceEpoch(pending, isUtc: true)
          : null,
    );
  }
}

/// Reads [key] as a [String], or null when it is absent or another type.
String? _string(Map<String, dynamic> json, String key) {
  final value = json[key];
  return value is String ? value : null;
}
