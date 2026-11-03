// Pins the fork language choice: its key, its one-time migration from the
// upstream language preference, and its writes.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/l10n/locale_choice.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferencesAsync preferences;
  String? upstream;
  var upstreamReads = 0;

  OneVpnLocaleChoice choice() => OneVpnLocaleChoice(
    preferences: preferences,
    readUpstreamLanguage: () async {
      upstreamReads++;
      return upstream;
    },
  );

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    preferences = SharedPreferencesAsync();
    upstream = null;
    upstreamReads = 0;
  });

  test('the keys carry the onevpn prefix', () {
    expect(OneVpnLocaleChoice.tagKey, startsWith('onevpn.'));
    expect(OneVpnLocaleChoice.migratedKey, startsWith('onevpn.'));
  });

  test('an empty store follows the system language', () async {
    final cubit = choice();
    await cubit.load();
    expect(cubit.state, isNull);
    expect(cubit.locale, isNull);
    expect(await preferences.getString(OneVpnLocaleChoice.tagKey), isNull);
  });

  test('the first load migrates a non-system upstream choice', () async {
    for (final (stored, tag, locale) in const [
      ('ru', 'ru', Locale('ru')),
      ('fa', 'fa', Locale('fa')),
      ('zh', 'zh', Locale('zh')),
      (
        'zh_Hant',
        'zh-Hant',
        Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      ),
    ]) {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      preferences = SharedPreferencesAsync();
      upstream = stored;
      final cubit = choice();
      await cubit.load();
      expect(cubit.state, tag, reason: stored);
      expect(cubit.locale, locale, reason: stored);
      expect(await preferences.getString(OneVpnLocaleChoice.tagKey), tag);
      expect(await preferences.getBool(OneVpnLocaleChoice.migratedKey), isTrue);
    }
  });

  test('a system or unknown upstream value migrates nothing', () async {
    for (final stored in [null, 'system', 'xx']) {
      upstream = stored;
      await preferences.remove(OneVpnLocaleChoice.migratedKey);
      final cubit = choice();
      await cubit.load();
      expect(cubit.state, isNull, reason: stored);
      expect(await preferences.getString(OneVpnLocaleChoice.tagKey), isNull);
      expect(await preferences.getBool(OneVpnLocaleChoice.migratedKey), isTrue);
    }
  });

  test('the migration runs once', () async {
    upstream = 'ru';
    await choice().load();
    expect(upstreamReads, 1);

    // A later system pick survives a reload, though upstream still holds ru.
    final cubit = choice();
    await cubit.load();
    await cubit.choose(null);
    final reloaded = choice();
    await reloaded.load();
    expect(upstreamReads, 1);
    expect(reloaded.state, isNull);
    expect(upstream, 'ru');
  });

  test('the migration keeps an existing fork choice', () async {
    await preferences.setString(OneVpnLocaleChoice.tagKey, 'fa');
    upstream = 'ru';
    final cubit = choice();
    await cubit.load();
    expect(cubit.state, 'fa');
  });

  test('choose stores the tag, and null removes it', () async {
    final cubit = choice();
    await cubit.load();

    await cubit.choose('zh-Hant');
    expect(cubit.state, 'zh-Hant');
    expect(await preferences.getString(OneVpnLocaleChoice.tagKey), 'zh-Hant');

    await cubit.choose(null);
    expect(cubit.state, isNull);
    expect(await preferences.getString(OneVpnLocaleChoice.tagKey), isNull);
  });

  test('a tag outside the fork list reads as the system language', () async {
    await preferences.setBool(OneVpnLocaleChoice.migratedKey, true);
    await preferences.setString(OneVpnLocaleChoice.tagKey, 'xx');
    final cubit = choice();
    await cubit.load();
    expect(cubit.state, isNull);

    await cubit.choose('xx');
    expect(cubit.state, isNull);
    expect(await preferences.getString(OneVpnLocaleChoice.tagKey), isNull);
  });

  test('a choice made during the load wins', () async {
    await preferences.setBool(OneVpnLocaleChoice.migratedKey, true);
    await preferences.setString(OneVpnLocaleChoice.tagKey, 'fa');
    final cubit = choice();
    final loading = cubit.load();
    await cubit.choose('ru');
    await loading;
    expect(cubit.state, 'ru');
  });
}
