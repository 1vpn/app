// The inline email capture on the Get Premium step.
//
// It returns the address, or null when the buyer backs out. It refuses an
// address the store could not link. It stays whole on a short viewport with
// the keyboard up.

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/l10n/localizations/app_localizations.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations_en.dart';
import 'package:onexray/onevpn/paywall/purchase_email_prompt.dart';
import 'package:onexray/pages/theme/theme.dart';

import '../support/ink.dart';
import '../support/localizations.dart';
import '../support/viewports.dart';

void main() {
  final l = OneVpnLocalizationsEn();

  late List<String?> answers;

  setUp(() => answers = <String?>[]);

  /// Mounts a screen whose button opens the prompt, and opens it. Every
  /// answer the prompt gives lands in [answers].
  Future<void> open(WidgetTester tester, {String initial = ''}) async {
    await setViewport(tester, kPortraitViewport);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        localizationsDelegates: oneVpnLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async => answers.add(
                  await showOneVpnPurchaseEmailPrompt(
                    context,
                    initial: initial,
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.tap(find.text(l.onevpnContinue));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the email field and Continue', (tester) async {
    await open(tester);

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text(l.onevpnContinue), findsOneWidget);
  });

  testWidgets('Continue flashes white and keeps the theme focus and hover '
      'colors', (tester) async {
    await open(tester);

    expectSolidInk(tester, [find.text(l.onevpnContinue)]);
  });

  testWidgets('answers with the address entered', (tester) async {
    await open(tester);

    await submit(tester, 'buyer@example.invalid');

    expect(answers, ['buyer@example.invalid']);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('trims surrounding space', (tester) async {
    await open(tester);

    await submit(tester, '  buyer@example.invalid  ');

    expect(answers, ['buyer@example.invalid']);
  });

  testWidgets('refuses an address the store could not link', (tester) async {
    await open(tester);

    await submit(tester, 'not-an-address');

    // The sheet stays open, carrying the auth screen's own message.
    expect(answers, isEmpty);
    expect(find.text(l.onevpnAuthInvalidEmail), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // A corrected address goes through.
    await submit(tester, 'buyer@example.invalid');
    expect(answers, ['buyer@example.invalid']);
  });

  testWidgets('prefills a known address', (tester) async {
    await open(tester, initial: 'known@example.invalid');

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'known@example.invalid');
  });

  testWidgets('backing out answers nothing', (tester) async {
    await open(tester);

    Navigator.of(tester.element(find.byType(TextField))).pop();
    await tester.pumpAndSettle();

    expect(answers, [null]);
  });

  // A short device with the keyboard up, in portrait and in landscape. The
  // insets leave the sheet less height than its content needs, so the
  // content has to scroll.
  for (final (size, keyboard) in const [
    (Size(360, 560), 300.0),
    (kLandscapeViewport, 160.0),
  ]) {
    testWidgets('the keyboard at ${size.width.toInt()}x${size.height.toInt()} '
        'leaves Continue reachable', (tester) async {
      await setViewport(tester, size);
      tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
      addTearDown(tester.view.resetViewInsets);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: oneVpnLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async =>
                      answers.add(await showOneVpnPurchaseEmailPrompt(context)),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // The content scrolls instead of overflowing its box.
      expect(tester.takeException(), isNull);

      // Continue is reachable, and it still answers.
      await tester.enterText(find.byType(TextField), 'buyer@example.invalid');
      await tester.ensureVisible(find.text(l.onevpnContinue));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.onevpnContinue));
      await tester.pumpAndSettle();

      expect(answers, ['buyer@example.invalid']);
    });
  }
}
