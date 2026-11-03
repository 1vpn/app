// Transport for the 1vpn account API: backup-domain failover, made
// sticky.
//
// Some networks block the account API, so four domains serve it.
//
// [OneVpnDomainMemory] makes the winning domain sticky and persistent. A
// blocked primary then costs its full timeout once per outage, not once
// per call. The memory survives a cold start, because a domain that a
// national resolver blocks stays blocked on every launch.
//
// A 2xx JSON object or a genuine API rejection ends the walk. A 4xx counts
// as a rejection only when its JSON body carries one of
// [kOneVpnApiRejectionKeys]. An HTML block page, such as a captive
// portal's 403 or an injected 404, falls through to the next domain on an
// idempotent call. A non-idempotent call ends there, unanswered. See
// [OneVpnApiTransport._classify].
//
// Limits of this transport:
//  * The walk tries one domain at a time, never several in parallel. A
//    parallel POST would submit credentials to every domain, suspect ones
//    included.
//  * There is no retry within a domain. A timeout is a failover signal on
//    an idempotent call. A non-idempotent call ends at its one domain on
//    any failure: a timeout, a dropped connection or a non-API answer.
//  * Failover after a timeout or a dropped connection re-sends the
//    request. A POST whose response was lost then reaches the server
//    twice. This is benign for login, signup and the user-data fetch: a
//    duplicate signup returns "email exists". It is not benign for the
//    token refresh. The rotation retires the token it presents, so a
//    re-sent rotation draws a 401. A non-idempotent call therefore dials
//    one domain, and a failure there ends the call. A payment endpoint
//    needs a fresh review before it uses this transport.
//  * There is no `Retry-After`, exponential backoff, circuit breaker, or
//    per-call budget. The callers are background work or interactive
//    flows that render the walk.
//
// The transport owns a bare Dio and never uses the tree's `NetClient`.
// `NetClient` is the geodata downloader: a process-wide singleton with a
// 60 s receive timeout and a download user agent. Sign-in is a small
// request made before any tunnel exists.
// test/onevpn/transport_import_sweep_test.dart enforces the split.
//
// On Android the app is excluded from its own tunnel. These calls leave
// from the underlying network at all times. On iOS they ride the tunnel
// while it is up and go clearnet otherwise. Every path ships. The client
// never inspects or steers by tunnel state.

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:onexray/onevpn/net/failover_domains.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The `code` value the API returns when a login needs a second factor.
///
/// This is the only API code the client models. Codes 1002 and 1003 come
/// from a prototype's mock server, not from the API.
const int kOneVpnTwoFactorRequiredCode = 1001;

/// The JSON keys whose presence makes a 4xx an answer from this API
/// rather than an interception.
///
/// `error` and `code` are the legacy ErrorResponse shape. `detail` is the
/// Django REST Framework default. The account API's TokenAuthentication
/// rejects with `{"detail": "Invalid token."}`, which carries neither of
/// the other two keys. `detail` makes that 401 an answer, so the walk
/// stops. It never re-sends the stale token to all four domains or reports
/// an ended session as censorship.
///
/// The deployed server's 401 body is unconfirmed, so all three shapes
/// count.
const List<String> kOneVpnApiRejectionKeys = <String>[
  'error',
  'code',
  'detail',
];

/// Per-attempt timeout for one domain, applied to connect, send, and
/// receive each.
///
/// On device, `POST /api/login/` through an active tunnel takes up to
/// 5.33 s. The in-tunnel path ships on iOS. A 5 s limit would make every
/// domain give up early on a healthy service. The app would then report
/// that no server answered. The 10 s value also matches the command
/// channel's bound on its non-lifecycle calls.
///
/// A walk over dead domains costs:
///  * about 0 s when they refuse,
///  * 40 s or more when they time out on connect,
///  * at most about 120 s when every phase of every domain stalls.
///
/// The sticky winning domain limits that cost to once per outage.
const Duration kOneVpnApiTimeout = Duration(seconds: 10);

/// Which set of hosts to talk to.
///
/// The seam is injectable so tests can drive a walk over reserved names
/// without reaching the network. There is no staging environment: the
/// only hosts the product may dial are [OneVpnFailoverDomains.all].
class OneVpnApiEnvironment {
  const OneVpnApiEnvironment({required this.domains, this.basePath = '/api'});

  /// In priority order. The first is the primary. The rest are the
  /// censorship fallbacks and are otherwise identical.
  final List<String> domains;
  final String basePath;

  static const production = OneVpnApiEnvironment(
    domains: OneVpnFailoverDomains.all,
  );
}

// ───────────────────────────── results ─────────────────────────────

/// One domain that was tried and why it did not answer.
///
/// The attempts tell a censored user which domains failed and how. A bug
/// report from such a user carries them. Nothing leaves the device, so
/// these outcomes are the whole failure record the field produces.
class OneVpnApiAttempt {
  const OneVpnApiAttempt({required this.domain, required this.reason});

  final String domain;
  final String reason;

  @override
  String toString() => '$domain: $reason';
}

sealed class OneVpnApiResult<T> {
  const OneVpnApiResult();
}

final class OneVpnApiSuccess<T> extends OneVpnApiResult<T> {
  const OneVpnApiSuccess(this.data);

  final T data;
}

/// Failures carry no payload. [cast] re-types a failure from a raw map
/// result to a DTO result. The reason needs no re-allocation.
sealed class OneVpnApiFailure<T> extends OneVpnApiResult<T> {
  const OneVpnApiFailure();

  OneVpnApiFailure<R> cast<R>();

  /// One line, safe to show and to paste into a report. It uses only
  /// exception types and answer origins, never a request body or an
  /// exception's text.
  String get description;
}

/// The API answered and said no. A real, authoritative rejection.
final class OneVpnApiRejected<T> extends OneVpnApiFailure<T> {
  const OneVpnApiRejected({
    required this.status,
    required this.message,
    this.code,
  });

  final int status;
  final String message;

  /// The API's own code, when it sent one. The client branches only on
  /// [kOneVpnTwoFactorRequiredCode].
  final int? code;

  bool get isTwoFactorRequired => code == kOneVpnTwoFactorRequiredCode;

  /// The stored token is no longer accepted, so the session should end.
  ///
  /// 401 only. The API is not known to return 403 for an expired token,
  /// so a 403 never counts as expiry.
  ///
  /// The real 401 body carries no `code` field at all, so [code] stays
  /// nullable and never gates classification.
  ///
  /// This transport holds no session and signs nobody out. The session
  /// owner consumes this predicate.
  bool get isUnauthorised => status == 401;

  @override
  OneVpnApiRejected<R> cast<R>() =>
      OneVpnApiRejected<R>(status: status, message: message, code: code);

  @override
  String get description => 'rejected (HTTP $status, code $code)';
}

/// Every domain the call dialed failed. A non-idempotent call dials one.
/// This is the censorship signal. A caller says so and never blames the
/// password. On its own it is never evidence that a session ended.
final class OneVpnApiUnreachable<T> extends OneVpnApiFailure<T> {
  const OneVpnApiUnreachable(this.attempts);

  final List<OneVpnApiAttempt> attempts;

  @override
  OneVpnApiUnreachable<R> cast<R>() => OneVpnApiUnreachable<R>(attempts);

  @override
  String get description =>
      'unreachable after ${attempts.length} domain(s): '
      '${attempts.join('; ')}';
}

/// A domain answered a well-formed JSON object that is not the expected
/// payload. An example is a login response with no `sessionAuthToken`.
///
/// Only the decoding layer emits this, never the transport. The transport
/// treats a 2xx that is not a JSON object as interception and fails over.
/// The transport still remembers the winning domain, because it got an
/// answer.
final class OneVpnApiMalformed<T> extends OneVpnApiFailure<T> {
  const OneVpnApiMalformed(this.reason);

  final String reason;

  @override
  OneVpnApiMalformed<R> cast<R>() => OneVpnApiMalformed<R>(reason);

  @override
  String get description => 'malformed response: $reason';
}

// ────────────────────────── sticky domain memory ──────────────────────

/// Remembers which domain last answered.
abstract interface class OneVpnDomainMemory {
  /// The remembered domain, or null if there is none or it has gone
  /// stale.
  Future<String?> read();

  Future<void> write(String domain);

  Future<void> clear();
}

/// Persistent memory on the tree's existing `shared_preferences`
/// dependency. It adds no package.
///
/// The TTL is the load-bearing part. The sticky choice expires after
/// [ttl], and the next call walks the list from the top again. A transient
/// outage therefore never pins a user to a fallback for good.
class OneVpnPrefsDomainMemory implements OneVpnDomainMemory {
  const OneVpnPrefsDomainMemory({this.ttl = const Duration(days: 7), this.now});

  static const _key = 'onevpn.api.domain.v1';

  final Duration ttl;

  /// Injectable clock, so the expiry is testable without waiting a week.
  final DateTime Function()? now;

  static SharedPreferencesAsync get _prefs => SharedPreferencesAsync();

  DateTime get _nowValue => (now ?? DateTime.now)();

  @override
  Future<String?> read() async =>
      domainFromRecord(await _prefs.getString(_key), now: _nowValue, ttl: ttl);

  @override
  Future<void> write(String domain) =>
      _prefs.setString(_key, encodeRecord(domain, _nowValue));

  /// The expiry decision, as a pure function that tests drive with a
  /// clock. Returns null for an absent, unparseable, or stale record. Each
  /// of those cases means "walk the list from the top".
  static String? domainFromRecord(
    String? text, {
    required DateTime now,
    required Duration ttl,
  }) {
    if (text == null || text.isEmpty) return null;
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) return null;
      final domain = decoded['domain'] as String?;
      final at = decoded['at'] as int?;
      if (domain == null || domain.isEmpty || at == null) return null;
      final age = now.difference(DateTime.fromMillisecondsSinceEpoch(at));
      // A negative age means the device clock moved backwards, which
      // happens routinely on phones. A record from the future reads as
      // stale, so it never pins the domain until the clock catches up.
      if (age.isNegative || age > ttl) return null;
      return domain;
    } catch (_) {
      return null;
    }
  }

  static String encodeRecord(String domain, DateTime at) => jsonEncode(
    <String, dynamic>{'domain': domain, 'at': at.millisecondsSinceEpoch},
  );

  @override
  Future<void> clear() => _prefs.remove(_key);
}

/// In-memory memory, for tests and for a session that should not persist.
class OneVpnEphemeralDomainMemory implements OneVpnDomainMemory {
  OneVpnEphemeralDomainMemory([this._domain]);

  String? _domain;

  @override
  Future<String?> read() async => _domain;

  @override
  Future<void> write(String domain) async => _domain = domain;

  @override
  Future<void> clear() async => _domain = null;
}

// ──────────────────────── reachability stamp ──────────────────────────

/// Remembers when [OneVpnApiTransport.probeReachability] last found an
/// answering domain.
abstract interface class OneVpnReachabilityStamp {
  /// The stamp, or null when no probe has found a domain.
  Future<DateTime?> read();

  Future<void> write(DateTime at);

  Future<void> clear();
}

/// The shipping stamp, backed by preferences. It stores milliseconds since
/// the epoch.
class OneVpnPrefsReachabilityStamp implements OneVpnReachabilityStamp {
  const OneVpnPrefsReachabilityStamp();

  static const key = 'onevpn.api.lastReachabilityAt';

  static SharedPreferencesAsync get _prefs => SharedPreferencesAsync();

  @override
  Future<DateTime?> read() async {
    final value = await _prefs.getInt(key);
    return value == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
  }

  @override
  Future<void> write(DateTime at) =>
      _prefs.setInt(key, at.millisecondsSinceEpoch);

  @override
  Future<void> clear() => _prefs.remove(key);
}

/// In-memory stamp, for tests.
class OneVpnEphemeralReachabilityStamp implements OneVpnReachabilityStamp {
  OneVpnEphemeralReachabilityStamp([this.stamp]);

  DateTime? stamp;

  @override
  Future<DateTime?> read() async => stamp;

  @override
  Future<void> write(DateTime at) async => stamp = at;

  @override
  Future<void> clear() async => stamp = null;
}

// ───────────────────────────── transport ─────────────────────────────

/// Walks the failover domains for one API call and classifies the answer.
///
/// One instance per process. The constructor takes every dependency. Two
/// live instances share the persisted record but hold separate
/// [backupDomainInUse] notifiers. A second instance would drive the banner
/// from a transport nobody uses.
class OneVpnApiTransport {
  /// [timeout] applies to an injected [dio] as well as to the one built
  /// here.
  ///
  /// It fills only an unset timeout (`??=`). A caller that configured its
  /// own timeout keeps it.
  OneVpnApiTransport({
    this.environment = OneVpnApiEnvironment.production,
    OneVpnDomainMemory? memory,
    OneVpnReachabilityStamp? reachabilityStamp,
    DateTime Function()? now,
    Dio? dio,
    Duration timeout = kOneVpnApiTimeout,
  }) : _memory = memory ?? const OneVpnPrefsDomainMemory(),
       _reachabilityStamp =
           reachabilityStamp ?? const OneVpnPrefsReachabilityStamp(),
       _now = now ?? DateTime.now,
       _dio = (dio ?? Dio())
         ..options.connectTimeout ??= timeout
         ..options.receiveTimeout ??= timeout
         ..options.sendTimeout ??= timeout;

  /// The transport shared by every account call in the process.
  static final OneVpnApiTransport instance = OneVpnApiTransport();

  final OneVpnApiEnvironment environment;
  final OneVpnDomainMemory _memory;
  final OneVpnReachabilityStamp _reachabilityStamp;
  final DateTime Function() _now;
  final Dio _dio;

  /// The remembered domain, or null when there is none or the store
  /// cannot be read.
  ///
  /// `shared_preferences` is platform IO and can fail. A failed read means
  /// "walk the list from the top". A store that will not open costs
  /// stickiness, never the call that needed it.
  Future<String?> _stickyDomain() async {
    try {
      return await _memory.read();
    } catch (_) {
      return null;
    }
  }

  /// Sticky domain first, then the configured order with that domain
  /// removed.
  Future<List<String>> _domainOrder() async {
    final sticky = await _stickyDomain();
    if (sticky == null || !environment.domains.contains(sticky)) {
      return environment.domains;
    }
    return <String>[sticky, ...environment.domains.where((d) => d != sticky)];
  }

  /// Records the winner only when the choice changes.
  ///
  /// The 7-day TTL measures the record's timestamp. Re-stamping an
  /// unchanged choice on every use would keep the record from aging out.
  /// The primary would then never be retried. The method therefore reads
  /// the record before it writes.
  ///
  /// A stale record reads as null, per
  /// [OneVpnPrefsDomainMemory.domainFromRecord]. After a walk from the top,
  /// the winner is a fresh decision. Its clock starts now, even for the same
  /// domain.
  ///
  /// The store read is the only guard. No in-process cache sits in front of
  /// it. A cache could suppress a needed write after the stored record went
  /// stale. A backwards clock change does that, as does a process that
  /// outlives the TTL.
  Future<void> _remember(String domain) async {
    // Set on every answer, before the short-circuit below. The notice is
    // live request state, not the record. A first call to an already-sticky
    // backup writes nothing, and the notice must still come up.
    _backupDomainInUse.value = _asBackup(domain);
    try {
      if (await _memory.read() == domain) return;
      await _memory.write(domain);
    } catch (_) {
      // The answer has already arrived. A store that will not record the
      // winner costs the next call a walk, never this call its result.
    }
  }

  /// The domain to use for web links: password reset, the account page,
  /// contact.
  ///
  /// Returns the sticky domain when there is one, so the browser opens a
  /// domain known to answer. A link to a blocked primary would not load.
  ///
  /// It reads the remembered choice and makes no network call.
  Future<String> activeBaseUrl() async {
    final order = await _domainOrder();
    return 'https://${order.first}';
  }

  /// Which backup domain is answering right now, or null when the primary
  /// is.
  ///
  /// It is a censored user's only signal that the primary domain is blocked
  /// for them. It describes their own network, not the service.
  ///
  /// The value is live request state, because the failover matters
  /// mid-session. It updates in the session where the failover happens. It
  /// clears when the primary answers or no domain answers.
  ///
  /// Never disposed: one transport lives as long as the process.
  /// Listeners must remove themselves.
  ValueListenable<String?> get backupDomainInUse => _backupDomainInUse;
  final ValueNotifier<String?> _backupDomainInUse = ValueNotifier<String?>(
    null,
  );

  String? _asBackup(String domain) =>
      domain == environment.domains.first ? null : domain;

  /// Seeds [backupDomainInUse] from the remembered choice before any call
  /// in this process. This covers a cold start into a network where the
  /// primary was blocked last time. It reads the preference and nothing
  /// more.
  Future<void> refreshBackupDomainNotice() async {
    final order = await _domainOrder();
    _backupDomainInUse.value = _asBackup(order.first);
  }

  /// Forgets the persisted domain choice, clears the live notice, and
  /// clears the reachability stamp.
  ///
  /// No app path calls it. Sign-out keeps the record and calls
  /// [clearReachabilityStamp]. Tests use it to reset the process-wide
  /// transport.
  ///
  /// A failed stamp clear never fails this call. A failed memory clear
  /// still clears the stamp.
  Future<void> forgetDomain() async {
    try {
      await _reachabilityStamp.clear();
    } catch (_) {
      // A stamp left in place costs at most one day without a probe.
    }
    await _memory.clear();
    _backupDomainInUse.value = null;
  }

  /// Clears the reachability stamp and keeps the remembered domain.
  ///
  /// Sign-out is its only caller. The cleared stamp makes the next
  /// signed-out launch probe. The remembered domain and
  /// [backupDomainInUse] stay as they are, and no walk starts. A failed
  /// clear throws.
  Future<void> clearReachabilityStamp() => _reachabilityStamp.clear();

  /// When [probeReachability] last found an answering domain, or null when
  /// none has or the stamp cannot be read.
  Future<DateTime?> lastReachabilityAt() async {
    try {
      return await _reachabilityStamp.read();
    } catch (_) {
      // A lost stamp costs at most one early probe.
      return null;
    }
  }

  /// Walks the domains with `HEAD https://<domain>/ping/` and returns the
  /// first domain that answers, or null when none does.
  ///
  /// The walk starts at the primary, whatever the sticky domain, so a
  /// primary that answers again replaces a remembered backup. [send] keeps
  /// the remembered domain first. The walk takes the timeout [send] takes
  /// and no redirects. Any HTTP status counts as an answer. The winner is
  /// remembered as for an API answer, so [activeBaseUrl] and
  /// [backupDomainInUse] follow it. A walk that finds a domain stamps
  /// [lastReachabilityAt]. A walk that finds none writes nothing.
  ///
  /// The path is the root `/ping/`, outside [OneVpnApiEnvironment.basePath].
  /// The request carries no body, no token, and no API headers.
  Future<String?> probeReachability() async {
    final answered = await _walk<String>(
      <OneVpnApiAttempt>[],
      (domain) => _dio.request<dynamic>(
        'https://$domain/ping/',
        options: Options(
          method: 'HEAD',
          responseType: ResponseType.plain,
          validateStatus: (_) => true,
          followRedirects: false,
        ),
      ),
      (domain, _) => domain,
      fromTop: true,
    );
    if (answered == null) return null;
    try {
      await _reachabilityStamp.write(_now());
    } catch (_) {
      // The record already holds the winner. A lost stamp costs one early
      // probe on the next launch.
    }
    return answered;
  }

  /// Sends [path] against each domain in turn until one answers
  /// authoritatively.
  ///
  /// [sendClientType] and [query] vary per endpoint. `refresh_token/` sends
  /// no `Client-Type` header and no `?type` query. The other three send
  /// both.
  ///
  /// [idempotent] false marks a request whose effect the server may have
  /// applied before its answer was lost. Such a request dials only the
  /// first domain of the walk, the remembered one or the primary. Any
  /// failure there ends the call as [OneVpnApiUnreachable] with that one
  /// attempt. `refresh_token/` is the one such call.
  Future<OneVpnApiResult<Map<String, dynamic>>> send({
    required String method,
    required String path,
    Map<String, String>? query,
    Object? body,
    String? authToken,
    bool sendClientType = true,
    bool idempotent = true,
  }) async {
    final attempts = <OneVpnApiAttempt>[];
    final answered = await _walk<OneVpnApiResult<Map<String, dynamic>>>(
      attempts,
      (domain) => _dio.request<dynamic>(
        'https://$domain${environment.basePath}/$path',
        data: body,
        queryParameters: query,
        options: Options(
          method: method,
          headers: <String, String>{
            'Content-Type': 'application/json',
            if (sendClientType) 'Client-Type': 'app',
            if (authToken != null && authToken.isNotEmpty)
              'Authorization': 'Token $authToken',
          },
          responseType: ResponseType.json,
          // Set per request, not on the Dio's BaseOptions, so an injected
          // Dio cannot restore throwing on 4xx. [_classify] handles every
          // status. A thrown rejection would look like a network failure
          // and trigger failover to every backup domain.
          validateStatus: (_) => true,
          // dio follows up to five redirects by default. This transport
          // follows none. dart:io re-sends the request headers on a
          // same-scheme hop. A followed redirect would carry the
          // `Authorization` token wherever a hijacked or intercepted
          // domain points. A 3xx reaches [_classify] as a non-answer, like
          // a 5xx. It falls through to the next domain with its body
          // unread.
          //
          // The answering host is therefore always the dialed host, and
          // the transport never checks it. `Response.realUri` is the last
          // followed redirect, or the dialed URI when there is none. Under
          // these options it is always the dialed URI. TLS verification
          // guards against a host that answers on the dialed name.
          followRedirects: false,
        ),
      ),
      (_, response) => _classify(response),
      idempotent: idempotent,
    );
    return answered ?? OneVpnApiUnreachable<Map<String, dynamic>>(attempts);
  }

  /// Tries each domain in [_domainOrder] until [accept] returns a value.
  /// A non-[idempotent] walk tries the first domain only.
  ///
  /// [request] dials one domain. [accept] returns null to mean "try the
  /// next domain". The first accepted domain is remembered through
  /// [_remember], and its value is returned. Each failed domain adds one
  /// entry to [attempts].
  ///
  /// Returns null when no domain is accepted. The backup notice is then
  /// cleared.
  Future<T?> _walk<T extends Object>(
    List<OneVpnApiAttempt> attempts,
    Future<Response<dynamic>> Function(String domain) request,
    T? Function(String domain, Response<dynamic> response) accept, {
    bool fromTop = false,
    bool idempotent = true,
  }) async {
    final order = fromTop ? environment.domains : await _domainOrder();
    for (final domain in idempotent ? order : order.take(1)) {
      Response<dynamic> response;
      try {
        response = await request(domain);
      } on DioException catch (e) {
        attempts.add(
          OneVpnApiAttempt(domain: domain, reason: _describeDioError(e)),
        );
        continue;
      } catch (e) {
        // Type only, never the value. See [_describeDioError].
        attempts.add(
          OneVpnApiAttempt(
            domain: domain,
            reason: 'request failed (${e.runtimeType})',
          ),
        );
        continue;
      }

      final accepted = accept(domain, response);
      if (accepted != null) {
        await _remember(domain);
        return accepted;
      }
      attempts.add(
        OneVpnApiAttempt(
          domain: domain,
          reason: 'HTTP ${response.statusCode}, not an API response',
        ),
      );
    }

    // No domain answered, or the one domain of a non-idempotent call did
    // not, so no backup domain carries traffic. Clearing the notice stops
    // it naming the last winner.
    _backupDomainInUse.value = null;
    return null;
  }

  /// Returns null to mean "try the next domain".
  OneVpnApiResult<Map<String, dynamic>>? _classify(Response<dynamic> response) {
    final status = response.statusCode ?? 0;
    final body = _asMap(response.data);

    if (status >= 200 && status < 300) {
      // A 2xx without a JSON object body is an interception. An example is
      // a block page served as 200 instead of 403. It falls through to the
      // next domain like any other non-answer. Returning Malformed here
      // would count as an answer and stop the failover.
      if (body == null) return null;
      return OneVpnApiSuccess<Map<String, dynamic>>(body);
    }

    if (status >= 400 && status < 500) {
      // A 4xx counts only when it carries this API's rejection shape. A
      // censor's HTML block page falls through to the next domain and
      // never reaches the user as a login failure.
      if (!_carriesRejectionShape(body)) return null;
      final code = body?['code'];
      return OneVpnApiRejected<Map<String, dynamic>>(
        status: status,
        message: _rejectionMessage(body),
        code: code is int ? code : null,
      );
    }

    return null;
  }

  /// The text the API sent with a rejection, or a neutral stand-in when
  /// it sent none. `error` is the legacy field and wins over `detail`, the
  /// DRF field.
  static String _rejectionMessage(Map<String, dynamic>? body) {
    for (final key in const <String>['error', 'detail']) {
      final value = body?[key];
      if (value is String && value.isNotEmpty) return value;
    }
    return 'request rejected';
  }

  /// Whether [body] carries one of [kOneVpnApiRejectionKeys] with the
  /// type that key is sent as. `code` is an integer. The other keys are
  /// strings.
  static bool _carriesRejectionShape(Map<String, dynamic>? body) {
    if (body == null) return false;
    return kOneVpnApiRejectionKeys.any((key) {
      final value = body[key];
      return key == 'code' ? value is int : value is String;
    });
  }

  static Map<String, dynamic>? _asMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    // dio hands back a String when the server mislabels its content type.
    if (data is String && data.isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Describes a failure without quoting the exception.
  ///
  /// `DioException.message` and `toString()` can carry the failed request:
  /// its URL, headers and body. For `login/` that body holds the password
  /// and the 2FA code. This string reaches
  /// [OneVpnApiUnreachable.description], which the user sees and pastes
  /// into bug reports. The string therefore uses only the exception's type,
  /// never its text. The fallback names the underlying error's runtime type
  /// instead of printing it.
  static String _describeDioError(DioException e) => switch (e.type) {
    DioExceptionType.connectionTimeout => 'connect timeout',
    DioExceptionType.sendTimeout => 'send timeout',
    DioExceptionType.receiveTimeout => 'receive timeout',
    DioExceptionType.connectionError => 'connection error',
    DioExceptionType.badCertificate => 'bad TLS certificate',
    DioExceptionType.cancel => 'cancelled',
    DioExceptionType.badResponse => 'unexpected response',
    DioExceptionType.transformTimeout => 'transform timeout',
    DioExceptionType.unknown => 'request failed (${e.error.runtimeType})',
  };
}
