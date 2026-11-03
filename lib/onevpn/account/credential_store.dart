// Persistence for the session document and the refresh cooldown stamp.
//
// The store is an interface with the preferences implementation behind
// it. Swapping the backing medium is one binding. Nothing above this seam
// knows which medium answers.

import 'dart:convert';

import 'package:onexray/onevpn/account/session.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The result of reading the persisted session.
///
/// Absent and unreadable are separate answers. Absent is a signed-out
/// user. Unreadable is a signed-in user whose document did not decode.
/// Unreadable never reads as signed out: that would discard a paid session
/// and its catalogue.
sealed class OneVpnStoredSession {
  const OneVpnStoredSession();
}

/// No document is stored. The user is signed out.
final class OneVpnSessionAbsent extends OneVpnStoredSession {
  const OneVpnSessionAbsent();
}

/// A document was stored and decoded.
final class OneVpnSessionRestored extends OneVpnStoredSession {
  const OneVpnSessionRestored(this.session);

  final OneVpnSession session;
}

/// A document is stored but could not be read.
///
/// Covers a document that did not decode and a store that would not
/// answer. To a caller, both mean a session may exist unseen. No caller
/// may act as though the user signed out.
///
/// [detail] is one line, safe to show. It names the shape of the failure
/// and never the stored value.
final class OneVpnSessionUnreadable extends OneVpnStoredSession {
  const OneVpnSessionUnreadable(this.detail);

  final String detail;
}

/// Persistence for one session document and one cooldown stamp.
///
/// [read] is never destructive. An unreadable document stays on disk, and
/// only [write] or [clear] removes it.
abstract interface class OneVpnCredentialStore {
  Future<OneVpnStoredSession> read();

  /// Replaces the stored document, marker included, in one write.
  Future<void> write(OneVpnSession session);

  /// Removes the stored document and the marker inside it.
  Future<void> clear();

  /// When a refresh last succeeded or a sign-in adopted the session, or
  /// null when neither has.
  Future<DateTime?> readLastRefreshAt();

  Future<void> writeLastRefreshAt(DateTime at);

  Future<void> clearLastRefreshAt();
}

/// Keys this store owns. The `onevpn.` namespace is the fork's. Upstream
/// allocates from `app2.`.
abstract final class OneVpnAccountKeys {
  static const session = 'onevpn.account.session';
  static const lastRefreshAt = 'onevpn.account.lastRefreshAt';
}

/// The shipping store, backed by preferences.
class OneVpnPrefsCredentialStore implements OneVpnCredentialStore {
  const OneVpnPrefsCredentialStore();

  static SharedPreferencesAsync get _prefs => SharedPreferencesAsync();

  @override
  Future<OneVpnStoredSession> read() async {
    final String? text;
    try {
      text = await _prefs.getString(OneVpnAccountKeys.session);
    } catch (error) {
      // Platform IO failed. Whether a session exists is unknown. Absent
      // would report a signed-in user as signed out.
      return OneVpnSessionUnreadable(
        'session store unavailable: ${error.runtimeType}',
      );
    }
    if (text == null) return const OneVpnSessionAbsent();
    if (text.isEmpty) {
      return const OneVpnSessionUnreadable('session document is empty');
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } catch (_) {
      // The detail names the type, never the value. The detail reaches a
      // debug surface. The document carries a live token.
      return const OneVpnSessionUnreadable('session document is not JSON');
    }
    if (decoded is! Map<String, dynamic>) {
      return const OneVpnSessionUnreadable(
        'session document is not a JSON object',
      );
    }

    final OneVpnSession? session;
    try {
      session = OneVpnSession.fromJson(decoded);
    } catch (error) {
      return OneVpnSessionUnreadable(
        'session document did not decode: ${error.runtimeType}',
      );
    }
    if (session == null) {
      return const OneVpnSessionUnreadable(
        'session document is missing a token or an entitlement',
      );
    }
    return OneVpnSessionRestored(session);
  }

  @override
  Future<void> write(OneVpnSession session) =>
      _prefs.setString(OneVpnAccountKeys.session, jsonEncode(session.toJson()));

  @override
  Future<void> clear() => _prefs.remove(OneVpnAccountKeys.session);

  @override
  Future<DateTime?> readLastRefreshAt() async {
    final int? value;
    try {
      value = await _prefs.getInt(OneVpnAccountKeys.lastRefreshAt);
    } catch (_) {
      // Losing the stamp costs at most one early refresh.
      return null;
    }
    return value == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
  }

  @override
  Future<void> writeLastRefreshAt(DateTime at) =>
      _prefs.setInt(OneVpnAccountKeys.lastRefreshAt, at.millisecondsSinceEpoch);

  @override
  Future<void> clearLastRefreshAt() =>
      _prefs.remove(OneVpnAccountKeys.lastRefreshAt);
}

/// In-memory store, for tests and for a session that should not persist.
///
/// Holds the encoded document, not the object. A test seeds text that
/// will not decode to exercise the unreadable branch.
class OneVpnEphemeralCredentialStore implements OneVpnCredentialStore {
  OneVpnEphemeralCredentialStore([this.document]);

  String? document;
  DateTime? stamp;

  @override
  Future<OneVpnStoredSession> read() async {
    final text = document;
    if (text == null) return const OneVpnSessionAbsent();
    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } catch (_) {
      return const OneVpnSessionUnreadable('session document is not JSON');
    }
    if (decoded is! Map<String, dynamic>) {
      return const OneVpnSessionUnreadable(
        'session document is not a JSON object',
      );
    }
    final session = OneVpnSession.fromJson(decoded);
    if (session == null) {
      return const OneVpnSessionUnreadable(
        'session document is missing a token or an entitlement',
      );
    }
    return OneVpnSessionRestored(session);
  }

  @override
  Future<void> write(OneVpnSession session) async =>
      document = jsonEncode(session.toJson());

  @override
  Future<void> clear() async => document = null;

  @override
  Future<DateTime?> readLastRefreshAt() async => stamp;

  @override
  Future<void> writeLastRefreshAt(DateTime at) async => stamp = at;

  @override
  Future<void> clearLastRefreshAt() async => stamp = null;
}
