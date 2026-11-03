// The harness the sign-in dismiss suites share.
//
// Each suite that adopts holds one test. The process-wide account service restores once
// per process, under the fake clock of the first test that adopts. A later
// test in the same file awaits that restore under a clock that never runs
// it, so its adoption never completes.

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/l10n/localizations/app_localizations.dart';
import 'package:onexray/onevpn/account/sign_in_page.dart';
import 'package:onexray/onevpn/data/account_api.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations_en.dart';
import 'package:onexray/onevpn/model/user_data.dart';
import 'package:onexray/onevpn/net/api_transport.dart';
import 'package:onexray/onevpn/shell/routes.dart';
import 'package:onexray/pages/theme/theme.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/types.dart';

import '../support/localizations.dart';
import '../support/viewports.dart';

/// An account transport whose log-in and sign-up answer with one signed-in
/// account for the submitted address, or with [failure] when set. While
/// [hold] is set, the answer waits on it.
final class DismissApi extends OneVpnAccountApi {
  DismissApi()
    : super(
        transport: OneVpnApiTransport(
          memory: OneVpnEphemeralDomainMemory(),
          dio: Dio(),
        ),
      );

  /// The calls made, by name: `logIn` or `signUp`.
  final List<String> calls = [];

  Completer<void>? hold;
  OneVpnApiFailure<OneVpnUserData>? failure;

  @override
  Future<OneVpnApiResult<OneVpnUserData>> logIn({
    required String email,
    required String password,
    String? twoFactorToken,
  }) {
    calls.add('logIn');
    return _answer(email);
  }

  @override
  Future<OneVpnApiResult<OneVpnUserData>> signUp({
    required String email,
    required String password,
  }) {
    calls.add('signUp');
    return _answer(email);
  }

  Future<OneVpnApiResult<OneVpnUserData>> _answer(String email) async {
    final gate = hold;
    if (gate != null) await gate.future;
    final failed = failure;
    if (failed != null) return failed;
    return OneVpnApiSuccess<OneVpnUserData>(
      OneVpnUserData(
        username: 'someone',
        email: email,
        isPremium: false,
        sessionAuthToken: 'tok',
        credentials: const OneVpnCredentials(
          uuid: 'u',
          publicKey: 'p',
          shortId: 's',
        ),
        locations: const <OneVpnApiLocation>[],
      ),
    );
  }
}

/// In-memory preferences whose string writes wait on [hold] while it is
/// set, so a test can hold a session adoption open.
final class HeldPrefs extends InMemorySharedPreferencesAsync {
  HeldPrefs() : super.empty();

  Completer<void>? hold;

  @override
  Future<bool> setString(
    String key,
    String value,
    SharedPreferencesOptions options,
  ) async {
    final gate = hold;
    if (gate != null) await gate.future;
    return super.setString(key, value, options);
  }
}

/// Pumps the app at the reference viewport with the sign-in page in [mode]
/// pushed over a route that reads "beneath". [onAuthenticated] passes
/// through to the page. Returns the router.
Future<GoRouter> pumpSignInOverBeneath(
  WidgetTester tester,
  OneVpnAccountApi api, {
  OneVpnSignInMode mode = OneVpnSignInMode.logIn,
  OneVpnAuthenticated? onAuthenticated,
}) async {
  await setViewport(tester, kPortraitViewport);

  final router = GoRouter(
    initialLocation: kOneVpnConnectRoute,
    routes: [
      GoRoute(
        path: kOneVpnConnectRoute,
        builder: (_, _) => const Scaffold(body: Text('host')),
      ),
      GoRoute(
        path: '/beneath',
        builder: (_, _) => const Scaffold(body: Text('beneath')),
      ),
      GoRoute(
        path: kOneVpnSignInRoute,
        builder: (_, _) => OneVpnSignInPage(
          api: api,
          initialMode: mode,
          onAuthenticated: onAuthenticated,
        ),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    MaterialApp.router(
      theme: AppTheme.light,
      locale: const Locale('en'),
      localizationsDelegates: oneVpnLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
  await tester.pumpAndSettle();
  unawaited(router.push<void>('/beneath'));
  await tester.pumpAndSettle();
  unawaited(router.push<OneVpnSignInMode>(kOneVpnSignInRoute));
  await tester.pumpAndSettle();
  return router;
}

/// Fills the form with [email] and submits it in [mode].
Future<void> submitSignIn(
  WidgetTester tester,
  String email, {
  OneVpnSignInMode mode = OneVpnSignInMode.logIn,
}) async {
  final l = OneVpnLocalizationsEn();
  await tester.enterText(find.byType(TextField).at(0), email);
  await tester.enterText(find.byType(TextField).at(1), 'hunter2hunter2');
  final submit = mode == OneVpnSignInMode.logIn
      ? l.onevpnLogIn
      : l.onevpnSignUp;
  await tester.tap(find.widgetWithText(InkWell, submit));
  await tester.pump();
}
