// Pins the fork locale list, its text directions, and the fork resolver.
// The list equals the set of fork ARB files.

import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations.dart';
import 'package:onexray/onevpn/l10n/locales.dart';

/// The language tag of each fork ARB file, from its file name.
Set<String> _arbTags() => Directory('lib/onevpn/l10n')
    .listSync()
    .whereType<File>()
    .map((file) => file.uri.pathSegments.last)
    .where((name) => name.startsWith('onevpn_') && name.endsWith('.arb'))
    .map(
      (name) => name
          .substring('onevpn_'.length, name.length - '.arb'.length)
          .replaceAll('_', '-'),
    )
    .toSet();

const _supported = [
  Locale('en'),
  Locale('fa'),
  Locale('ru'),
  Locale('zh'),
  Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  Locale('pt'),
];

Locale _resolve(Locale? locale, {Abi abi = Abi.androidArm64}) =>
    oneVpnResolveLocale(locale, _supported, abi: abi);

void main() {
  group('the fork locale list', () {
    test('equals the set of fork ARB files', () {
      final tags = _arbTags();
      // Anti-vacuity guard. The template and four translations are present.
      expect(tags, containsAll(['en', 'fa', 'ru', 'zh', 'zh-Hant']));
      expect(kOneVpnLocales.map((locale) => locale.tag).toSet(), tags);
      expect(
        OneVpnLocalizations.supportedLocales.map((l) => l.toLanguageTag()),
        unorderedEquals(tags),
        reason: 'the generated bundle is stale: run tool/gen_onevpn_l10n.sh',
      );
    });

    test('names every locale in its own script', () {
      for (final locale in kOneVpnLocales) {
        expect(kOneVpnNativeNames, contains(locale.tag), reason: locale.tag);
        expect(locale.nativeName, kOneVpnNativeNames[locale.tag]);
      }
    });

    test('is sorted by language tag', () {
      final tags = [for (final locale in kOneVpnLocales) locale.tag];
      expect(tags, [...tags]..sort());
      expect(tags, contains('en'));
    });

    test('lists the 26 shipped locales in picker order with their native '
        'names and directions', () {
      expect(
        [
          for (final locale in kOneVpnLocales)
            (locale.tag, locale.nativeName, locale.textDirection),
        ],
        [
          ('am', 'አማርኛ', TextDirection.ltr),
          ('ar', 'العربية', TextDirection.rtl),
          ('az', 'Azərbaycan', TextDirection.ltr),
          ('bn', 'বাংলা', TextDirection.ltr),
          ('de', 'Deutsch', TextDirection.ltr),
          ('en', 'English', TextDirection.ltr),
          ('es', 'Español', TextDirection.ltr),
          ('fa', 'فارسی', TextDirection.rtl),
          ('fr', 'Français', TextDirection.ltr),
          ('hi', 'हिन्दी', TextDirection.ltr),
          ('id', 'Bahasa Indonesia', TextDirection.ltr),
          ('it', 'Italiano', TextDirection.ltr),
          ('ja', '日本語', TextDirection.ltr),
          ('ko', '한국어', TextDirection.ltr),
          ('my', 'မြန်မာ', TextDirection.ltr),
          ('pl', 'Polski', TextDirection.ltr),
          ('pt', 'Português', TextDirection.ltr),
          ('ru', 'Русский', TextDirection.ltr),
          ('th', 'ไทย', TextDirection.ltr),
          ('tk', 'Türkmençe', TextDirection.ltr),
          ('tr', 'Türkçe', TextDirection.ltr),
          ('uk', 'Українська', TextDirection.ltr),
          ('ur', 'اردو', TextDirection.rtl),
          ('vi', 'Tiếng Việt', TextDirection.ltr),
          ('zh', '简体中文', TextDirection.ltr),
          ('zh-Hant', '繁體中文', TextDirection.ltr),
        ],
      );
    });

    test('finds a locale by tag and nothing for an unknown tag', () {
      expect(oneVpnLocaleForTag('zh-Hant')?.locale, _supported[4]);
      expect(oneVpnLocaleForTag('zh_Hant'), isNull);
      expect(oneVpnLocaleForTag('xx'), isNull);
      expect(oneVpnLocaleForTag(null), isNull);
    });
  });

  group('text direction', () {
    test('is right to left for Arabic, Farsi and Urdu', () {
      expect(oneVpnTextDirection(const Locale('ar')), TextDirection.rtl);
      expect(oneVpnTextDirection(const Locale('fa')), TextDirection.rtl);
      expect(oneVpnTextDirection(const Locale('ur')), TextDirection.rtl);
      expect(oneVpnTextDirection(const Locale('ur', 'PK')), TextDirection.rtl);
      expect(oneVpnTextDirection(const Locale('ar', 'EG')), TextDirection.rtl);
    });

    test('is left to right for every other prepared locale', () {
      for (final tag in kOneVpnNativeNames.keys) {
        if (const {'ar', 'fa', 'ur'}.contains(tag)) continue;
        expect(
          oneVpnTextDirection(Locale.fromSubtags(languageCode: tag)),
          TextDirection.ltr,
          reason: tag,
        );
      }
    });

    test('of each fork locale follows its language', () {
      for (final locale in kOneVpnLocales) {
        expect(
          locale.textDirection,
          oneVpnTextDirection(locale.locale),
          reason: locale.tag,
        );
      }
    });
  });

  group('the resolver', () {
    test('resolves a null locale to English', () {
      expect(_resolve(null), const Locale('en'));
    });

    test('returns an exact match', () {
      for (final locale in _supported) {
        expect(_resolve(locale), locale, reason: locale.toLanguageTag());
      }
    });

    test('falls back to a language match', () {
      expect(_resolve(const Locale('ru', 'UA')), const Locale('ru'));
      expect(_resolve(const Locale('pt', 'BR')), const Locale('pt'));
      expect(_resolve(const Locale('pt', 'PT')), const Locale('pt'));
      expect(_resolve(const Locale('fa', 'IR')), const Locale('fa'));
    });

    test('prefers the matching Chinese script', () {
      const hant = Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant');
      expect(
        _resolve(
          const Locale.fromSubtags(
            languageCode: 'zh',
            scriptCode: 'Hant',
            countryCode: 'TW',
          ),
        ),
        hant,
      );
      expect(_resolve(const Locale('zh', 'TW')), hant);
      expect(_resolve(const Locale('zh', 'HK')), hant);
      expect(_resolve(const Locale('zh', 'MO')), hant);
      expect(_resolve(const Locale('zh', 'CN')), const Locale('zh'));
      expect(
        _resolve(
          const Locale.fromSubtags(
            languageCode: 'zh',
            scriptCode: 'Hans',
            countryCode: 'CN',
          ),
        ),
        const Locale('zh'),
      );
    });

    test('falls back to English for an unsupported language', () {
      expect(_resolve(const Locale('he')), const Locale('en'));
      expect(_resolve(const Locale('xx', 'YY')), const Locale('en'));
    });

    test('resolves Chinese, Japanese and Korean to English on Linux ARM64', () {
      for (final code in ['zh', 'ja', 'ko']) {
        expect(
          _resolve(Locale(code), abi: Abi.linuxArm64),
          const Locale('en'),
          reason: code,
        );
      }
      expect(_resolve(const Locale('ru'), abi: Abi.linuxArm64), _supported[2]);
    });

    test('resolves every fork locale to itself', () {
      final supported = [for (final locale in kOneVpnLocales) locale.locale];
      for (final locale in supported) {
        expect(
          oneVpnResolveLocale(locale, supported, abi: Abi.androidArm64),
          locale,
        );
      }
    });
  });
}
