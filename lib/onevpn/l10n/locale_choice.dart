import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:onexray/core/constants/preferences.dart';
import 'package:onexray/onevpn/l10n/locales.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app language the user picked, as a fork language tag. Null follows
/// the system language.
///
/// The state starts null. [load] reads the stored choice. [choose] stores a
/// new one. A stored tag outside [kOneVpnLocales] reads as null.
class OneVpnLocaleChoice extends Cubit<String?> {
  OneVpnLocaleChoice({
    SharedPreferencesAsync? preferences,
    Future<String?> Function()? readUpstreamLanguage,
  }) : _injected = preferences,
       _readUpstreamLanguage =
           readUpstreamLanguage ?? (() => PreferencesKey().readLanguageCode()),
       super(null);

  final SharedPreferencesAsync? _injected;

  /// The store, created on first use. Construction never touches it.
  late final SharedPreferencesAsync _preferences =
      _injected ?? SharedPreferencesAsync();
  final Future<String?> Function() _readUpstreamLanguage;

  /// True once [choose] runs. A later [load] result then emits nothing.
  bool _chosen = false;

  /// The fork's own key. It holds a language tag such as `zh-Hant`. An
  /// absent key follows the system language.
  static const tagKey = 'onevpn.languageTag';

  /// Marks the one-time migration from the upstream language preference as
  /// done.
  static const migratedKey = 'onevpn.languageTagMigrated';

  /// The locale for [state], or null to follow the system language.
  Locale? get locale => oneVpnLocaleForTag(state)?.locale;

  /// Reads the stored choice and emits it.
  ///
  /// The first load migrates the upstream language preference. A
  /// non-system upstream value that names a fork locale becomes the fork
  /// choice. The upstream value stays as it is. A failed read leaves the
  /// state unchanged. A [choose] call made while the load runs wins over
  /// the stored value.
  Future<void> load() async {
    try {
      if (await _preferences.getBool(migratedKey) != true) {
        await _migrate();
      }
      final tag = await _preferences.getString(tagKey);
      if (!_chosen && !isClosed) emit(oneVpnLocaleForTag(tag)?.tag);
    } catch (_) {
      // An unreadable store leaves the state unchanged.
    }
  }

  Future<void> _migrate() async {
    final stored = await _readUpstreamLanguage();
    // The upstream value is an enum name such as zh_Hant, or system.
    final upstream = oneVpnLocaleForTag(stored?.replaceAll('_', '-'));
    if (upstream != null && await _preferences.getString(tagKey) == null) {
      await _preferences.setString(tagKey, upstream.tag);
    }
    await _preferences.setBool(migratedKey, true);
  }

  /// Stores [tag] and emits it. Null removes the key and follows the system
  /// language. A failed store throws and leaves the state unchanged.
  Future<void> choose(String? tag) async {
    final choice = oneVpnLocaleForTag(tag)?.tag;
    _chosen = true;
    if (choice == null) {
      await _preferences.remove(tagKey);
    } else {
      await _preferences.setString(tagKey, choice);
    }
    if (!isClosed) emit(choice);
  }
}
