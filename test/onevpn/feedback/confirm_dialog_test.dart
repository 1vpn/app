// The fork confirm dialog: its answers, its shape at the reference sizes,
// and the reconnect confirm built on it.

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/l10n/localizations/app_localizations.dart';
import 'package:onexray/onevpn/feedback/confirm_dialog.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations_en.dart';
import 'package:onexray/pages/theme/theme.dart';

import '../support/localizations.dart';
import '../support/viewports.dart';

Future<Future<bool>> _open(
  WidgetTester tester,
  Future<bool> Function(BuildContext context) show, {
  Size size = kPortraitViewport,
}) async {
  await setViewport(tester, size);
  late BuildContext context;
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('en'),
      localizationsDelegates: oneVpnLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (value) {
          context = value;
          return const Scaffold();
        },
      ),
    ),
  );
  final answer = show(context);
  await tester.pumpAndSettle();
  return answer;
}

Future<bool> _plain(BuildContext context) => showOneVpnConfirmDialog(
  context,
  title: 'Title',
  body: 'Body',
  detail: const Text('Detail'),
  confirmLabel: 'Confirm',
  cancelLabel: 'Cancel',
);

void main() {
  final l = OneVpnLocalizationsEn();

  testWidgets('confirm answers true', (tester) async {
    final answer = await _open(tester, _plain);
    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Body'), findsOneWidget);
    expect(find.text('Detail'), findsOneWidget);
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(await answer, isTrue);
  });

  testWidgets('cancel answers false', (tester) async {
    final answer = await _open(tester, _plain);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await answer, isFalse);
  });

  testWidgets('a barrier tap answers false', (tester) async {
    final answer = await _open(tester, _plain);
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(find.byType(OneVpnConfirmDialog), findsNothing);
    expect(await answer, isFalse);
  });

  for (final size in [
    kPortraitViewport,
    kLandscapeViewport,
    kTabletLandscapeViewport,
  ]) {
    final name = '${size.width.toInt()}x${size.height.toInt()}';
    testWidgets('at $name the dialog is centered and capped', (tester) async {
      await _open(tester, _plain, size: size);
      expect(tester.takeException(), isNull);
      // The Dialog widget spans the inset area. Its Material is the surface.
      final dialog = tester.getRect(
        find
            .descendant(
              of: find.byType(Dialog),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(dialog.width, lessThanOrEqualTo(OneVpnConfirmDialog.maxWidth));
      expect(dialog.center.dx, closeTo(size.width / 2, 0.5));
      expect(find.text('Confirm').hitTestable(), findsOneWidget);
    });
  }

  testWidgets('the reconnect confirm names what the tunnel will use', (
    tester,
  ) async {
    final answer = await _open(
      tester,
      (context) => showOneVpnReconnectDialog(context, label: 'Amsterdam'),
    );
    expect(find.text(l.onevpnApplyChange), findsOneWidget);
    expect(find.text(l.onevpnWillUseName('Amsterdam')), findsOneWidget);
    await tester.tap(find.text(l.onevpnApplyAndReconnect));
    await tester.pumpAndSettle();
    expect(await answer, isTrue);
  });
}
