import 'dart:ffi' show Abi;

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' show Bidi;
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations.dart';

/// A locale the fork ships, with the name the picker shows for it.
@immutable
class OneVpnLocale {
  const OneVpnLocale(this.locale, this.nativeName);

  /// The locale as gen-l10n emits it from the ARB file name.
  final Locale locale;

  /// The language's name in its own script.
  final String nativeName;

  /// The BCP 47 tag, such as `en` or `zh-Hant`. The stored choice holds it.
  String get tag => locale.toLanguageTag();

  /// The text direction of [locale].
  TextDirection get textDirection => oneVpnTextDirection(locale);
}

/// The native name of every locale the fork ships or prepares, by language
/// tag. A fork ARB file whose tag has no entry here fails the locale tests.
const kOneVpnNativeNames = <String, String>{
  'am': 'አማርኛ',
  'ar': 'العربية',
  'az': 'Azərbaycan',
  'bn': 'বাংলা',
  'de': 'Deutsch',
  'en': 'English',
  'es': 'Español',
  'fa': 'فارسی',
  'fr': 'Français',
  'hi': 'हिन्दी',
  'id': 'Bahasa Indonesia',
  'it': 'Italiano',
  'ja': '日本語',
  'ko': '한국어',
  'my': 'မြန်မာ',
  'pl': 'Polski',
  'pt': 'Português',
  'ru': 'Русский',
  'th': 'ไทย',
  'tk': 'Türkmençe',
  'tr': 'Türkçe',
  'uk': 'Українська',
  'ur': 'اردو',
  'vi': 'Tiếng Việt',
  'zh': '简体中文',
  'zh-Hant': '繁體中文',
};

/// The fork locales for [locales], sorted by language tag. A tag with no
/// native name shows the tag itself.
List<OneVpnLocale> oneVpnLocalesFrom(Iterable<Locale> locales) {
  final list = [
    for (final locale in locales)
      OneVpnLocale(
        locale,
        kOneVpnNativeNames[locale.toLanguageTag()] ?? locale.toLanguageTag(),
      ),
  ];
  return List.unmodifiable(list..sort((a, b) => a.tag.compareTo(b.tag)));
}

/// The fork's supported locales in picker order, sorted by language tag.
///
/// The set is [OneVpnLocalizations.supportedLocales], which gen-l10n emits
/// from the fork ARB files present. Adding an ARB file adds its locale.
final List<OneVpnLocale> kOneVpnLocales = oneVpnLocalesFrom(
  OneVpnLocalizations.supportedLocales,
);

/// The fork locale with [tag], or null when the fork ships no such locale.
OneVpnLocale? oneVpnLocaleForTag(String? tag) {
  for (final locale in kOneVpnLocales) {
    if (locale.tag == tag) return locale;
  }
  return null;
}

/// Right to left for an RTL language such as Arabic, Farsi or Urdu,
/// otherwise left to right. The intl bidi table decides.
TextDirection oneVpnTextDirection(Locale locale) =>
    Bidi.isRtlLanguage(locale.toLanguageTag())
    ? TextDirection.rtl
    : TextDirection.ltr;

const _english = Locale('en');

/// Resolves [locale] against [supportedLocales] for the app.
///
/// The order is an exact match, then a language match, then English. An
/// exact match equals the language, script and country. A language match
/// prefers the supported locale with the same script. A Chinese locale with
/// no script reads as Traditional for TW, HK and MO, and as Simplified
/// otherwise. A null locale resolves to English.
///
/// On Linux ARM64, Chinese, Japanese and Korean resolve to English. [abi]
/// overrides the current ABI in tests.
Locale oneVpnResolveLocale(
  Locale? locale,
  Iterable<Locale> supportedLocales, {
  Abi? abi,
}) {
  if (locale == null) return _english;
  final supported = supportedLocales.toList(growable: false);
  if (const {'zh', 'ja', 'ko'}.contains(locale.languageCode) &&
      (abi ?? Abi.current()) == Abi.linuxArm64) {
    return _english;
  }
  for (final candidate in supported) {
    if (candidate.languageCode == locale.languageCode &&
        candidate.scriptCode == locale.scriptCode &&
        candidate.countryCode == locale.countryCode) {
      return candidate;
    }
  }
  final sameLanguage = [
    for (final candidate in supported)
      if (candidate.languageCode == locale.languageCode) candidate,
  ];
  if (sameLanguage.isEmpty) return _english;
  final script = locale.scriptCode ?? _impliedScript(locale);
  for (final candidate in sameLanguage) {
    if (candidate.scriptCode == script) return candidate;
  }
  for (final candidate in sameLanguage) {
    if (candidate.scriptCode == null) return candidate;
  }
  return sameLanguage.first;
}

/// The script a Chinese region implies. Null for any other locale.
String? _impliedScript(Locale locale) {
  if (locale.languageCode != 'zh') return null;
  return const {'TW', 'HK', 'MO'}.contains(locale.countryCode) ? 'Hant' : null;
}
