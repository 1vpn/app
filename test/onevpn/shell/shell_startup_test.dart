// The shell's startup. The launch hold stays on until startup ends. A startup
// that succeeds lifts it on the frame that draws the connect screen. A startup
// that fails, or outlasts its limit, lifts it on the failure screen with
// Retry. A retry keeps that screen up with its button disabled until it ends.
// The limit's timer dies with the shell.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/l10n/localizations/app_localizations.dart';
import 'package:onexray/onevpn/boot/launch_hold.dart';
import 'package:onexray/onevpn/shell/shell.dart';
import 'package:onexray/pages/theme/theme.dart';

import '../support/localizations.dart';
import '../support/viewports.dart';

const _retryKey = ValueKey('service-initialization-retry');
const _limit = Duration(seconds: 5);

/// Mounts the shell over [initialize], with a short limit and a stub for the
/// connect screen.
Future<void> _pumpShell(
  WidgetTester tester,
  Future<void> Function(BuildContext context) initialize,
) async {
  await setViewport(tester, kPortraitViewport);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('en'),
      localizationsDelegates: oneVpnLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: OneVpnShell(
        initializeServices: initialize,
        startupTimeout: _limit,
        connectScreen: const Text('connect'),
      ),
    ),
  );
}

void main() {
  setUp(() {
    OneVpnLaunchHold.hold();
    addTearDown(OneVpnLaunchHold.release);
  });

  testWidgets('the hold stays on while startup runs and lifts when it '
      'succeeds', (tester) async {
    final startup = Completer<void>();
    await _pumpShell(tester, (_) => startup.future);
    await tester.pump(const Duration(seconds: 1));

    expect(OneVpnLaunchHold.held, isTrue);
    expect(find.text('connect'), findsNothing);
    expect(find.byKey(_retryKey), findsNothing);

    startup.complete();
    await tester.pumpAndSettle();

    expect(find.text('connect'), findsOneWidget);
    expect(OneVpnLaunchHold.held, isFalse);
  });

  testWidgets('a failed startup lifts the hold and shows the failure with '
      'Retry', (tester) async {
    await _pumpShell(tester, (_) => Future<void>.error(StateError('boom')));
    await tester.pumpAndSettle();

    expect(find.byKey(_retryKey), findsOneWidget);
    expect(find.textContaining('boom'), findsOneWidget);
    expect(find.text('connect'), findsNothing);
    expect(OneVpnLaunchHold.held, isFalse);
  });

  testWidgets('a startup that outlasts its limit lifts the hold and shows the '
      'failure with Retry', (tester) async {
    await _pumpShell(tester, (_) => Completer<void>().future);
    await tester.pump(_limit - const Duration(seconds: 1));

    expect(OneVpnLaunchHold.held, isTrue);
    expect(find.byKey(_retryKey), findsNothing);

    await tester.pump(const Duration(seconds: 2));

    expect(find.byKey(_retryKey), findsOneWidget);
    expect(find.textContaining('exceeded its deadline'), findsOneWidget);
    expect(find.text('connect'), findsNothing);
    expect(OneVpnLaunchHold.held, isFalse);
  });

  testWidgets('a startup that ends in time is not cut off by the limit', (
    tester,
  ) async {
    final startup = Completer<void>();
    await _pumpShell(tester, (_) => startup.future);
    await tester.pump(_limit - const Duration(seconds: 1));
    startup.complete();
    await tester.pumpAndSettle();
    await tester.pump(_limit * 2);

    expect(find.text('connect'), findsOneWidget);
    expect(find.byKey(_retryKey), findsNothing);
  });

  testWidgets('a late finish after the limit leaves the failure screen up', (
    tester,
  ) async {
    final startup = Completer<void>();
    await _pumpShell(tester, (_) => startup.future);
    await tester.pump(_limit + const Duration(seconds: 1));
    expect(find.byKey(_retryKey), findsOneWidget);

    startup.complete();
    await tester.pumpAndSettle();

    expect(find.byKey(_retryKey), findsOneWidget);
    expect(find.text('connect'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Retry after a timeout picks up the run that finished '
      'meanwhile', (tester) async {
    final startup = Completer<void>();
    await _pumpShell(tester, (_) => startup.future);
    await tester.pump(_limit + const Duration(seconds: 1));
    startup.complete();

    await tester.tap(find.byKey(_retryKey));
    await tester.pumpAndSettle();

    expect(find.text('connect'), findsOneWidget);
    expect(find.byKey(_retryKey), findsNothing);
  });

  testWidgets('a retry that outlasts the limit fails again', (tester) async {
    await _pumpShell(tester, (_) => Completer<void>().future);
    await tester.pump(_limit + const Duration(seconds: 1));

    await tester.tap(find.byKey(_retryKey));
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byKey(_retryKey)).onPressed,
      isNull,
    );

    await tester.pump(_limit + const Duration(seconds: 1));

    expect(
      tester.widget<FilledButton>(find.byKey(_retryKey)).onPressed,
      isNotNull,
    );
    expect(find.textContaining('exceeded its deadline'), findsOneWidget);
  });

  testWidgets('Retry keeps the failure screen up while it runs', (
    tester,
  ) async {
    var runs = 0;
    final second = Completer<void>();
    await _pumpShell(tester, (_) {
      runs++;
      return runs == 1 ? Future<void>.error(StateError('boom')) : second.future;
    });
    await tester.pumpAndSettle();
    expect(find.byKey(_retryKey), findsOneWidget);

    await tester.tap(find.byKey(_retryKey));
    await tester.pump();

    expect(runs, 2);
    expect(find.byKey(_retryKey), findsOneWidget);
    expect(find.textContaining('boom'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byKey(_retryKey)).onPressed,
      isNull,
    );

    second.complete();
    await tester.pumpAndSettle();

    expect(find.text('connect'), findsOneWidget);
    expect(find.byKey(_retryKey), findsNothing);
  });

  testWidgets('a retry that fails again enables Retry', (tester) async {
    var runs = 0;
    final second = Completer<void>();
    await _pumpShell(tester, (_) {
      runs++;
      return runs == 1
          ? Future<void>.error(StateError('first'))
          : second.future;
    });
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_retryKey));
    await tester.pump();

    second.completeError(StateError('second'));
    await tester.pumpAndSettle();

    expect(find.textContaining('second'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byKey(_retryKey)).onPressed,
      isNotNull,
    );
  });

  testWidgets('disposing the shell during startup cancels the limit', (
    tester,
  ) async {
    await _pumpShell(tester, (_) => Completer<void>().future);

    await tester.pumpWidget(const SizedBox());

    // No time passes. A timer the shell left behind fails the test at its
    // end.
    expect(tester.takeException(), isNull);
  });
}
