// The rating prompt and its dialog.
//
// The dialog renders its question, Yes, and No at the reference handset size
// in every fork locale. Each answer records its value and time. Yes opens
// the review flow. Yes resolves once the answer is stored, while the review
// flow is still open, and a failed review flow leaves the answer stored. No
// closes the dialog and opens nothing. An answer ends the prompt for good. A
// barrier tap records the dismissal time and leaves the prompt due. The Play
// launcher requests the native review sheet and opens the store listing when
// the sheet does not cover the app.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_review/in_app_review.dart';
// ignore: depend_on_referenced_packages
import 'package:in_app_review_platform_interface/in_app_review_platform_interface.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/l10n/localizations/app_localizations.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations.dart';
import 'package:onexray/onevpn/rating/rating_prompt.dart';
import 'package:onexray/pages/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../support/localizations.dart';
import '../support/viewports.dart';
import 'fake_review_launcher.dart';

/// A store platform that logs each call. [failsRequest] makes the review
/// request throw. [covers] makes the request take the app through inactive
/// and back, as a shown sheet does. [failsListing] makes the store listing
/// throw.
class _FakeStore extends InAppReviewPlatform {
  _FakeStore({
    this.failsRequest = false,
    this.covers = false,
    this.failsListing = false,
  });

  final bool failsRequest;
  final bool covers;
  final bool failsListing;
  final List<String> log = [];

  @override
  Future<bool> isAvailable() async {
    log.add('isAvailable');
    return true;
  }

  @override
  Future<void> requestReview() async {
    log.add('requestReview');
    if (failsRequest) throw Exception('no store');
    if (covers) {
      final binding = WidgetsBinding.instance;
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    }
  }

  @override
  Future<void> openStoreListing({
    String? appStoreId,
    String? microsoftStoreId,
  }) async {
    log.add('openStoreListing');
    if (failsListing) throw Exception('no store');
  }
}

final _now = DateTime.utc(2026, 10, 15, 12);

void main() {
  late FakeReviewLauncher launcher;
  late OneVpnRatingPrompt prompt;
  late SharedPreferencesAsync preferences;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    preferences = SharedPreferencesAsync();
    launcher = FakeReviewLauncher();
    prompt = OneVpnRatingPrompt(now: () => _now, launcher: launcher);
  });

  /// Mounts a button that runs the prompt, in [locale], and taps it.
  Future<void> open(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    await setViewport(tester, kPortraitViewport);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: locale,
        localizationsDelegates: oneVpnLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => prompt.afterUserDisconnect(context),
                child: const Text('disconnect'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('disconnect'));
    await tester.pumpAndSettle();
  }

  Future<bool?> answer(WidgetTester tester) => tester.runAsync<bool?>(
    () => preferences.getBool(OneVpnRatingPrompt.answerKey),
  );

  Future<int?> stamp(WidgetTester tester, String key) =>
      tester.runAsync<int?>(() => preferences.getInt(key));

  testWidgets('the dialog renders its question, Yes, and No', (tester) async {
    await open(tester);

    expect(find.byType(OneVpnRatingDialog), findsOneWidget);
    expect(find.text('Are You Enjoying 1VPN?'), findsOneWidget);
    expect(find.text('Yes'), findsOneWidget);
    expect(find.text('No'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the dialog lays out in every fork locale', (tester) async {
    for (final locale in OneVpnLocalizations.supportedLocales) {
      await open(tester, locale: locale);
      expect(find.byType(OneVpnRatingDialog), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '$locale');
      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('yes records the answer and opens the review flow', (
    tester,
  ) async {
    await open(tester);

    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();

    expect(find.byType(OneVpnRatingDialog), findsNothing);
    expect(await answer(tester), isTrue);
    expect(
      await stamp(tester, OneVpnRatingPrompt.answeredAtKey),
      _now.millisecondsSinceEpoch,
    );
    expect(launcher.opens, 1);
    expect(await tester.runAsync(prompt.isDue), isFalse);
  });

  test('yes resolves while the review flow is still open', () async {
    final hanging = FakeReviewLauncher(hangs: true);
    final prompt = OneVpnRatingPrompt(now: () => _now, launcher: hanging);
    var resolved = false;
    unawaited(prompt.answer(true).then((_) => resolved = true));
    await pumpEventQueue();

    expect(hanging.opens, 1);
    expect(resolved, isTrue);
    expect(await preferences.getBool(OneVpnRatingPrompt.answerKey), isTrue);
  });

  test('a failed review flow leaves the answer stored', () async {
    final failing = FakeReviewLauncher(fails: true);
    final prompt = OneVpnRatingPrompt(now: () => _now, launcher: failing);
    await prompt.answer(true);
    // An unhandled failure surfaces here and fails the test.
    await pumpEventQueue();

    expect(failing.opens, 1);
    expect(await preferences.getBool(OneVpnRatingPrompt.answerKey), isTrue);
  });

  testWidgets('no records the answer and opens nothing', (tester) async {
    await open(tester);

    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();

    expect(find.byType(OneVpnRatingDialog), findsNothing);
    expect(await answer(tester), isFalse);
    expect(
      await stamp(tester, OneVpnRatingPrompt.answeredAtKey),
      _now.millisecondsSinceEpoch,
    );
    expect(launcher.opens, 0);
    expect(await tester.runAsync(prompt.isDue), isFalse);
  });

  testWidgets('an answer ends the prompt for good', (tester) async {
    await open(tester);
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('disconnect'));
    await tester.pumpAndSettle();

    expect(find.byType(OneVpnRatingDialog), findsNothing);
  });

  testWidgets('a barrier tap records a dismissal and the prompt returns', (
    tester,
  ) async {
    await open(tester);

    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();

    expect(find.byType(OneVpnRatingDialog), findsNothing);
    expect(
      await stamp(tester, OneVpnRatingPrompt.dismissedAtKey),
      _now.millisecondsSinceEpoch,
    );
    expect(await answer(tester), isNull);
    expect(launcher.opens, 0);

    await tester.tap(find.text('disconnect'));
    await tester.pumpAndSettle();
    expect(find.byType(OneVpnRatingDialog), findsOneWidget);
  });

  group('the Play launcher', () {
    late InAppReviewPlatform original;

    setUp(() => original = InAppReviewPlatform.instance);
    tearDown(() => InAppReviewPlatform.instance = original);

    Future<List<String>> run(WidgetTester tester, _FakeStore store) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      InAppReviewPlatform.instance = store;
      await OneVpnPlayReviewLauncher(review: InAppReview.instance).openReview();
      return store.log;
    }

    testWidgets('a shown sheet opens nothing more', (tester) async {
      expect(await run(tester, _FakeStore(covers: true)), ['requestReview']);
    });

    testWidgets('a sheet the store holds back opens the store listing', (
      tester,
    ) async {
      expect(await run(tester, _FakeStore()), [
        'requestReview',
        'openStoreListing',
      ]);
    });

    testWidgets('a failed request opens the store listing', (tester) async {
      expect(await run(tester, _FakeStore(failsRequest: true)), [
        'requestReview',
        'openStoreListing',
      ]);
    });

    testWidgets('a failed store listing resolves quietly', (tester) async {
      expect(await run(tester, _FakeStore(failsListing: true)), [
        'requestReview',
        'openStoreListing',
      ]);
    });
  });
}
