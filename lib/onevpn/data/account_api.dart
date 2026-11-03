// The four account endpoints, typed.
//
// Each call sends the exact request shape of the legacy client, quirks
// included. The note on each call names its quirk. This layer owns only
// request shape and decoding. OneVpnApiTransport owns domain failover and
// answer classification.

import 'package:onexray/onevpn/model/user_data.dart';
import 'package:onexray/onevpn/net/api_transport.dart';

class OneVpnAccountApi {
  OneVpnAccountApi({OneVpnApiTransport? transport})
    : transport = transport ?? OneVpnApiTransport.instance;

  final OneVpnApiTransport transport;

  /// Three of the four endpoints carry `?type=xray`. `refresh_token/`
  /// carries no query.
  static const Map<String, String> _xrayQuery = <String, String>{
    'type': 'xray',
  };

  /// `POST /api/login/?type=xray`
  ///
  /// The first attempt omits [twoFactorToken]. A rejection with
  /// [OneVpnApiRejected.isTwoFactorRequired] is a normal branch of the flow,
  /// not an error. The caller asks for the code and calls this again with it.
  Future<OneVpnApiResult<OneVpnUserData>> logIn({
    required String email,
    required String password,
    String? twoFactorToken,
  }) async {
    final raw = await transport.send(
      method: 'POST',
      path: 'login/',
      query: _xrayQuery,
      body: <String, dynamic>{
        'email': email,
        'password': password,
        if (twoFactorToken != null && twoFactorToken.isNotEmpty)
          'token': twoFactorToken,
      },
    );
    return _decodeUserData(raw);
  }

  /// `POST /api/signup/?type=xray`
  ///
  /// Returns a full [OneVpnUserData], session token included. Signup
  /// therefore signs the user in with no separate login round trip.
  Future<OneVpnApiResult<OneVpnUserData>> signUp({
    required String email,
    required String password,
  }) async {
    final raw = await transport.send(
      method: 'POST',
      path: 'signup/',
      query: _xrayQuery,
      body: <String, dynamic>{'email': email, 'password': password},
    );
    return _decodeUserData(raw);
  }

  /// `POST /api/get_user_data_api/?type=xray`
  ///
  /// The method is POST, like all four endpoints. The written spec's `GET`
  /// for this endpoint is wrong.
  ///
  /// The request sends a zero-length body, never `{}`. That is the only body
  /// shape the server is known to accept.
  Future<OneVpnApiResult<OneVpnUserData>> fetchUserData({
    required String authToken,
  }) async {
    final raw = await transport.send(
      method: 'POST',
      path: 'get_user_data_api/',
      query: _xrayQuery,
      authToken: authToken,
    );
    // The only endpoint whose decode treats the session token as optional.
    // This call reads entitlement, and its payload may omit the token. See
    // OneVpnUserData.fromJson.
    return _decodeUserData(raw, requireToken: false);
  }

  /// `POST /api/refresh_token/`
  ///
  /// Sends no `Client-Type` header and no `?type` query, unlike the other
  /// three endpoints.
  ///
  /// The rotation retires the presented token, so the call is not
  /// idempotent. The transport sends it to one domain and never fails it
  /// over. A failure there returns [OneVpnApiUnreachable].
  ///
  /// Returns only the new token, not a full payload.
  Future<OneVpnApiResult<String>> refreshToken({
    required String authToken,
  }) async {
    final raw = await transport.send(
      method: 'POST',
      path: 'refresh_token/',
      authToken: authToken,
      sendClientType: false,
      idempotent: false,
    );
    return _decode<String>(raw, (json) {
      final token = json['sessionAuthToken'];
      if (token is! String || token.isEmpty) return null;
      return token;
    }, 'no sessionAuthToken in refresh response');
  }

  Future<OneVpnApiResult<OneVpnUserData>> _decodeUserData(
    OneVpnApiResult<Map<String, dynamic>> raw, {
    bool requireToken = true,
  }) async => _decode<OneVpnUserData>(
    raw,
    (json) => OneVpnUserData.fromJson(json, requireToken: requireToken),
    'response did not contain a usable UserData',
  );

  /// Re-types a raw transport result into a decoded one. A failure passes
  /// through unchanged. A 2xx body that will not parse becomes
  /// [OneVpnApiMalformed], never an empty object.
  ///
  /// Here a decode failure becomes a result. This method catches every
  /// throw out of [parse], whatever its type. The caller of an endpoint
  /// gets an [OneVpnApiResult] and never an exception. The DTOs also
  /// validate field by field. The catch covers any shape they miss.
  static OneVpnApiResult<T> _decode<T>(
    OneVpnApiResult<Map<String, dynamic>> raw,
    T? Function(Map<String, dynamic>) parse,
    String malformedReason,
  ) {
    switch (raw) {
      case OneVpnApiSuccess<Map<String, dynamic>>(:final data):
        final T? parsed;
        try {
          parsed = parse(data);
        } catch (_) {
          // The fixed reason reaches the user. The exception's text stays
          // out, because it can carry the body that produced it.
          return OneVpnApiMalformed<T>(malformedReason);
        }
        if (parsed == null) return OneVpnApiMalformed<T>(malformedReason);
        return OneVpnApiSuccess<T>(parsed);
      case OneVpnApiFailure<Map<String, dynamic>>():
        return raw.cast<T>();
    }
  }
}
