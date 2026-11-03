// Pins the fallback delegates. Every fork locale loads upstream strings and
// the Material, Cupertino and Widgets strings. A locale a bundle lacks loads
// that bundle's English strings.

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/l10n/localizations/app_localizations.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations.dart';
import 'package:onexray/onevpn/l10n/locales.dart';
import 'package:onexray/onevpn/l10n/upstream_delegate.dart';
import 'package:onexray/service/settings/language/locale.dart';

void main() {
  const delegate = OneVpnUpstreamLocalizationsDelegate();

  test('reports every fork and prepared locale as supported', () {
    for (final locale in kOneVpnLocales) {
      expect(delegate.isSupported(locale.locale), isTrue, reason: locale.tag);
    }
    for (final tag in kOneVpnNativeNames.keys) {
      final [language, ...script] = tag.split('-');
      final locale = Locale.fromSubtags(
        languageCode: language,
        scriptCode: script.isEmpty ? null : script.first,
      );
      expect(delegate.isSupported(locale), isTrue, reason: tag);
    }
  });

  test('loads the upstream strings of a locale upstream supports', () async {
    for (final locale in AppLocalizations.supportedLocales) {
      final loaded = await delegate.load(locale);
      final expected = await AppLocalizations.delegate.load(locale);
      expect(loaded.localeName, expected.localeName);
      expect(loaded.prototypeConnect, expected.prototypeConnect);
    }
  });

  test('loads upstream English for a fork locale upstream lacks', () async {
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    // Locales the upstream bundle lacks.
    for (final locale in const [Locale('ar'), Locale('pt'), Locale('de')]) {
      expect(AppLocalizations.delegate.isSupported(locale), isFalse);
      final loaded = await delegate.load(locale);
      expect(loaded.localeName, english.localeName);
      expect(loaded.prototypeConnect, english.prototypeConnect);
    }
  });

  test('replaces the upstream delegate and wraps the rest of its list', () {
    expect(kOneVpnLocalizationsDelegates.first, OneVpnLocalizations.delegate);
    expect(kOneVpnLocalizationsDelegates[1], delegate);
    expect(delegate.type, AppLocalizations.delegate.type);
    expect(kOneVpnLocalizationsDelegates.sublist(2), [
      for (final builtIn in AppLocalePolicy.localizationsDelegates.skip(1))
        OneVpnEnglishFallbackDelegate(builtIn),
    ]);
    expect(
      AppLocalePolicy.localizationsDelegates.first,
      AppLocalizations.delegate,
    );
    expect(
      [for (final d in kOneVpnLocalizationsDelegates.sublist(2)) d.type],
      [for (final d in AppLocalePolicy.localizationsDelegates.skip(1)) d.type],
    );
  });

  group('the built-in fallback', () {
    const tk = Locale('tk');

    test('covers a fork locale Flutter lacks', () {
      // Anti-vacuity guard. Turkmen ships in the fork and not in Flutter.
      expect(kOneVpnLocales.map((locale) => locale.tag), contains('tk'));
      for (final builtIn in GlobalMaterialLocalizations.delegates) {
        expect(builtIn.isSupported(tk), isFalse);
        expect(OneVpnEnglishFallbackDelegate(builtIn).isSupported(tk), isTrue);
      }
    });

    test('loads English for a locale Flutter lacks and the locale itself '
        'otherwise', () async {
      const material = OneVpnEnglishFallbackDelegate(
        GlobalMaterialLocalizations.delegate,
      );
      final turkmen = await material.load(tk) as MaterialLocalizations;
      expect(turkmen.backButtonTooltip, 'Back');
      final urdu = await material.load(const Locale('ur'));
      final expected = await GlobalMaterialLocalizations.delegate.load(
        const Locale('ur'),
      );
      expect(
        (urdu as MaterialLocalizations).backButtonTooltip,
        expected.backButtonTooltip,
      );
      expect(urdu.backButtonTooltip, isNot('Back'));
    });

    testWidgets('a Material page under Turkmen builds with English '
        'built-in strings', (tester) async {
      late BuildContext page;
      await tester.pumpWidget(
        MaterialApp(
          locale: tk,
          localizationsDelegates: kOneVpnLocalizationsDelegates,
          supportedLocales: [for (final l in kOneVpnLocales) l.locale],
          home: Scaffold(
            appBar: AppBar(leading: const BackButton()),
            body: Builder(
              builder: (context) {
                page = context;
                return const TextField();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(Localizations.localeOf(page), tk);
      expect(MaterialLocalizations.of(page).backButtonTooltip, 'Back');
      for (final builtIn in GlobalMaterialLocalizations.delegates) {
        expect(
          Localizations.of<Object>(page, builtIn.type),
          isNotNull,
          reason: '${builtIn.type}',
        );
      }
      expect(WidgetsLocalizations.of(page).textDirection, TextDirection.ltr);
      expect(find.byTooltip('Back'), findsOneWidget);
      expect(OneVpnLocalizations.of(page)!.localeName, 'tk');
    });
  });

  testWidgets('an upstream lookup under a locale upstream lacks returns '
      'English', (tester) async {
    late AppLocalizations? upstream;
    await tester.pumpWidget(
      Localizations(
        locale: const Locale('ar'),
        delegates: [
          delegate,
          ...AppLocalePolicy.localizationsDelegates.skip(1),
        ],
        child: Builder(
          builder: (context) {
            upstream = AppLocalizations.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pump();
    expect(upstream, isNotNull);
    expect(upstream!.localeName, 'en');
  });
}
