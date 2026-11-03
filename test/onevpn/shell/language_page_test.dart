import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/core/constants/preferences.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations_en.dart';
import 'package:onexray/onevpn/l10n/locale_choice.dart';
import 'package:onexray/onevpn/l10n/locales.dart';
import 'package:onexray/onevpn/shell/language_page.dart';
import 'package:onexray/onevpn/shell/router.dart';
import 'package:onexray/onevpn/shell/routes.dart';
import 'package:onexray/pages/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../support/localizations.dart';
import '../support/viewports.dart';

/// A host page under the picker. It shows the fork Language string, so the
/// test reads the language the app renders in.
GoRouter _router() => GoRouter(
  initialLocation: kOneVpnConnectRoute,
  routes: [
    GoRoute(
      path: kOneVpnConnectRoute,
      builder: (context, _) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => context.push(kOneVpnLanguageRoute),
            child: Text(OneVpnLocalizations.of(context)!.onevpnLanguage),
          ),
        ),
      ),
    ),
    ...OneVpnRouter.menuSurfaces(),
  ],
);

/// Mounts the host with its locale bound to [choice] the way the app binds
/// it, then opens the picker.
Future<void> _open(
  WidgetTester tester,
  OneVpnLocaleChoice choice, {
  Size size = kPortraitViewport,
}) async {
  await setViewport(tester, size);
  // One router for the mount, as in the app: a rebuild keeps the page stack.
  final router = _router();
  await tester.pumpWidget(
    BlocProvider.value(
      value: choice,
      child: BlocBuilder<OneVpnLocaleChoice, String?>(
        builder: (context, _) => MaterialApp.router(
          theme: AppTheme.light,
          locale: choice.locale,
          localizationsDelegates: oneVpnLocalizationsDelegates,
          supportedLocales: [for (final l in kOneVpnLocales) l.locale],
          localeResolutionCallback: oneVpnResolveLocale,
          routerConfig: router,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byType(TextButton));
  await tester.pumpAndSettle();
}

/// The picker row titled [title].
Finder _row(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(InkWell)).first;

/// Whether the row titled [title] ends in the check.
bool _checked(WidgetTester tester, String title) => tester.any(
  find.descendant(of: _row(title), matching: find.byIcon(LucideIcons.check)),
);

/// The stored fork choice.
Future<String?> _storedTag() =>
    SharedPreferencesAsync().getString(OneVpnLocaleChoice.tagKey);

void main() {
  final l = OneVpnLocalizationsEn();
  final names = [for (final locale in kOneVpnLocales) locale.nativeName];
  final titles = [l.onevpnLanguageSystem, ...names];
  final rtlLocales = [
    for (final locale in kOneVpnLocales)
      if (locale.textDirection == TextDirection.rtl) locale,
  ];

  // One store for the file: the preferences singleton binds the platform on
  // first use, so a later swap never reaches it.
  setUpAll(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('the picker lists System default, then each language under its '
      'own name in language-tag order', (tester) async {
    await _open(tester, OneVpnLocaleChoice());

    expect(find.byType(OneVpnLanguagePage), findsOneWidget);
    // Anti-vacuity guard. The five shipped locales lead the sorted list.
    expect(
      titles,
      containsAllInOrder([
        'System Default',
        'English',
        'فارسی',
        'Русский',
        '简体中文',
        '繁體中文',
      ]),
    );
    final tags = [for (final locale in kOneVpnLocales) locale.tag];
    expect(tags, [...tags]..sort());
    final tops = [
      for (final title in titles) tester.getTopLeft(_row(title)).dy,
    ];
    expect(tops, [...tops]..sort());
    // Every row is one height, the checked one included.
    final heights = {
      for (final title in titles) tester.getSize(_row(title)).height,
    };

    expect(heights, hasLength(1));
  });

  testWidgets('the stored choice reads as selected', (tester) async {
    final choice = OneVpnLocaleChoice();
    await choice.choose('zh-Hant');
    await _open(tester, choice);

    // The page renders in Traditional Chinese, System default included.
    final system = OneVpnLocalizations.of(
      tester.element(find.byType(OneVpnLanguagePage)),
    )!.onevpnLanguageSystem;
    for (final title in [system, ...names]) {
      expect(_checked(tester, title), title == '繁體中文', reason: title);
    }
  });

  testWidgets('screen readers hear one group with the stored choice '
      'selected', (tester) async {
    final semantics = tester.ensureSemantics();
    final choice = OneVpnLocaleChoice();
    await choice.choose('en');
    await _open(tester, choice);

    for (final title in titles) {
      expect(
        tester.getSemantics(_row(title)),
        isSemantics(
          label: title,
          isSelected: title == 'English',
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
        ),
        reason: title,
      );
    }
    semantics.dispose();
  });

  testWidgets('a tap stores the language under the fork key, the app '
      'switches, and the picker stays open on it', (tester) async {
    final upstream = await PreferencesKey().readLanguageCode();
    final choice = OneVpnLocaleChoice();
    await choice.choose(null);
    await _open(tester, choice);
    expect(_checked(tester, 'System Default'), isTrue);

    await tester.ensureVisible(_row('Русский'));
    await tester.pumpAndSettle();
    await tester.tap(_row('Русский'));
    await tester.pumpAndSettle();

    expect(choice.state, 'ru');
    expect(await _storedTag(), 'ru');
    // The upstream preference is never written.
    expect(await PreferencesKey().readLanguageCode(), upstream);
    // The picker now renders in Russian with the new row selected.
    expect(find.byType(OneVpnLanguagePage), findsOneWidget);
    expect(find.text('Язык'), findsWidgets);
    expect(_checked(tester, 'Русский'), isTrue);
    expect(_checked(tester, 'Как в системе'), isFalse);
  });

  test('the RTL locales are Arabic, Farsi and Urdu', () {
    expect([for (final locale in rtlLocales) locale.tag], ['ar', 'fa', 'ur']);
  });

  testWidgets('the picker shows all 26 languages in language-tag order', (
    tester,
  ) async {
    await _open(tester, OneVpnLocaleChoice());

    expect(names, [
      'አማርኛ',
      'العربية',
      'Azərbaycan',
      'বাংলা',
      'Deutsch',
      'English',
      'Español',
      'فارسی',
      'Français',
      'हिन्दी',
      'Bahasa Indonesia',
      'Italiano',
      '日本語',
      '한국어',
      'မြန်မာ',
      'Polski',
      'Português',
      'Русский',
      'ไทย',
      'Türkmençe',
      'Türkçe',
      'Українська',
      'اردو',
      'Tiếng Việt',
      '简体中文',
      '繁體中文',
    ]);
    for (final name in names) {
      await tester.ensureVisible(_row(name));
      await tester.pumpAndSettle();
      expect(find.text(name), findsOneWidget, reason: name);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('a tap on Turkmen renders the app in Turkmen with English '
      'Material strings', (tester) async {
    final choice = OneVpnLocaleChoice();
    await choice.choose(null);
    await _open(tester, choice);

    await tester.ensureVisible(_row('Türkmençe'));
    await tester.pumpAndSettle();
    await tester.tap(_row('Türkmençe'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(choice.state, 'tk');
    final page = tester.element(find.byType(OneVpnLanguagePage));
    expect(Localizations.localeOf(page), const Locale('tk'));
    expect(Directionality.of(page), TextDirection.ltr);
    expect(MaterialLocalizations.of(page).backButtonTooltip, 'Back');
    final title = OneVpnLocalizations.of(page)!.onevpnLanguage;
    expect(title, isNot(l.onevpnLanguage));
    expect(find.text(title), findsWidgets);
    expect(_checked(tester, 'Türkmençe'), isTrue);
  });

  for (final locale in rtlLocales) {
    testWidgets('a tap on ${locale.tag} switches the app to right to left', (
      tester,
    ) async {
      final choice = OneVpnLocaleChoice();
      await choice.choose(null);
      await _open(tester, choice);

      await tester.ensureVisible(_row(locale.nativeName));
      await tester.pumpAndSettle();
      await tester.tap(_row(locale.nativeName));
      await tester.pumpAndSettle();

      expect(choice.state, locale.tag);
      final page = tester.element(find.byType(OneVpnLanguagePage));
      expect(Localizations.localeOf(page), locale.locale);
      expect(Directionality.of(page), TextDirection.rtl);
      final title = OneVpnLocalizations.of(page)!.onevpnLanguage;
      expect(find.text(title), findsWidgets);
      expect(_checked(tester, locale.nativeName), isTrue);
    });
  }

  testWidgets('a tap on the selected row stores nothing', (tester) async {
    final choice = OneVpnLocaleChoice();
    await choice.choose('fa');
    await _open(tester, choice);
    await SharedPreferencesAsync().setString(
      OneVpnLocaleChoice.tagKey,
      'sentinel',
    );

    await tester.ensureVisible(_row('فارسی'));
    await tester.pumpAndSettle();
    await tester.tap(_row('فارسی'));
    await tester.pumpAndSettle();

    expect(find.byType(OneVpnLanguagePage), findsOneWidget);
    // A store would have overwritten the sentinel.
    expect(await _storedTag(), 'sentinel');
  });

  testWidgets('at 800x360 every row is reachable with no overflow', (
    tester,
  ) async {
    await _open(tester, OneVpnLocaleChoice(), size: kLandscapeViewport);

    expect(tester.takeException(), isNull);
    final last = names.last;
    await tester.ensureVisible(_row(last));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(_row(last).hitTestable(), findsOneWidget);
  });
}
