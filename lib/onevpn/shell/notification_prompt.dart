import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The once-ever notification permission request at the first connect.
///
/// The connected notification needs the grant on API 33 and later. The
/// Android plugin prompts only there, and below API 33 it answers without a
/// prompt. The flag stamps once the request returns an answer, so later
/// connects never ask. A failed request leaves the flag unstamped. The
/// caller connects whatever the answer.
class OneVpnNotificationPrompt {
  OneVpnNotificationPrompt({
    SharedPreferencesAsync? preferences,
    Future<bool?> Function()? request,
  }) : _preferences = preferences ?? SharedPreferencesAsync(),
       _request = request ?? _requestAndroid;

  final SharedPreferencesAsync _preferences;
  final Future<bool?> Function() _request;

  /// The fork once-ever key for the request.
  static const askedKey = 'onevpn.notificationPermissionAsked';

  /// Requests the permission unless an earlier request got an answer. A null
  /// answer means no Android plugin, and the flag stays unstamped. Never
  /// throws.
  Future<void> askOnce() async {
    try {
      if (await _preferences.getBool(askedKey) ?? false) return;
      if (await _request() == null) return;
      await _preferences.setBool(askedKey, true);
    } catch (_) {}
  }

  static Future<bool?> _requestAndroid() async =>
      FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
}
