import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/l10n/localizations/app_localizations.dart';
import 'package:onexray/service/settings/language/locale.dart';
import 'package:onexray/pages/settings/language/controller.dart';
import 'package:onexray/pages/settings/language/page.dart';
import 'package:onexray/pages/theme/theme.dart';
import 'package:onexray/service/shared/event_bus/enum.dart';
import 'package:onexray/service/shared/event_bus/service.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

void main() {
  Widget app(Locale locale, Widget child) => MaterialApp(
    theme: AppTheme.light,
    locale: locale,
    localizationsDelegates: AppLocalePolicy.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => ShadTheme(
      data: ShadThemeData(colorScheme: const ShadBlueColorScheme.light()),
      child: child ?? const SizedBox.shrink(),
    ),
    home: Scaffold(body: child),
  );

  test('language selection stays a draft until save', () async {
    final bus = AppEventBus();
    final initial = bus.state.languageCode;
    final controller = LanguageController();
    controller.updateLanguageCode(LanguageCode.fa);
    expect(controller.state.languageCode, LanguageCode.fa);
    expect(bus.state.languageCode, initial);
    await controller.close();
    expect(bus.state.languageCode, initial);
    await bus.close();
  });

  for (final locale in const [
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    Locale('en'),
    Locale('ru'),
    Locale('fa'),
  ]) {
    testWidgets(
      'settings language choices fit and select in ${locale.toLanguageTag()}',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        LanguageCode? language;
        await tester.pumpWidget(
          app(
            locale,
            LanguageChoiceView(
              selected: LanguageCode.zh,
              onSelected: (value) => language = value,
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (final label in ['简体中文', '繁體中文', 'English', 'Русский', 'فارسی']) {
          expect(find.text(label), findsWidgets);
        }
        await tester.tap(find.text('فارسی').first);
        expect(language, LanguageCode.fa);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
