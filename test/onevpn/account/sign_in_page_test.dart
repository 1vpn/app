// The dual-mode auth screen:
//
// - the mode toggle and prefill
// - the opening focus on the first editable field
// - a successful adopt
// - the two-factor reveal on 1001, and the resubmit
// - the log-in recovery for an existing account
// - the rate-limit, invalid-credentials, and unreachable error copy
//
// The account transport is scripted. Nothing dials the network.
//
// The suite pins the default authentication handler over a real router.
// The purchase funnel awaits this route and grants straight after. The
// adoption must land before the route answers.
//
// The form is one column capped at 420dp at 360x800 and at 800x360. At
// 800x360 a keyboard inset keeps the focused field and the submit button in
// view.

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/l10n/localizations/app_localizations.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/account/sign_in_page.dart';
import 'package:onexray/onevpn/data/account_api.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations_en.dart';
import 'package:onexray/onevpn/model/user_data.dart';
import 'package:onexray/onevpn/net/api_transport.dart';
import 'package:onexray/onevpn/shell/layout.dart';
import 'package:onexray/onevpn/shell/links.dart';
import 'package:onexray/onevpn/shell/routes.dart';
import 'package:onexray/pages/theme/theme.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:url_launcher_platform_interface/link.dart';
// ignore: depend_on_referenced_packages
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../support/ink.dart';
import '../support/localizations.dart';
import '../support/viewports.dart';

OneVpnUserData _userData(String email) => OneVpnUserData(
  username: 'someone',
  email: email,
  isPremium: false,
  sessionAuthToken: 'tok',
  credentials: const OneVpnCredentials(uuid: 'u', publicKey: 'p', shortId: 's'),
  locations: const <OneVpnApiLocation>[],
);

OneVpnApiRejected<OneVpnUserData> _rejected(
  int status,
  String message, {
  int? code,
}) => OneVpnApiRejected<OneVpnUserData>(
  status: status,
  message: message,
  code: code,
);

/// An account transport that answers from a script and dials nothing.
class _ScriptedAuthApi extends OneVpnAccountApi {
  _ScriptedAuthApi()
    : super(
        transport: OneVpnApiTransport(
          memory: OneVpnEphemeralDomainMemory(),
          dio: Dio(),
        ),
      );

  final List<OneVpnApiResult<OneVpnUserData>> loginResults = [];
  final List<OneVpnApiResult<OneVpnUserData>> signupResults = [];
  final List<String> calls = [];
  String? lastToken;

  @override
  Future<OneVpnApiResult<OneVpnUserData>> logIn({
    required String email,
    required String password,
    String? twoFactorToken,
  }) async {
    calls.add('logIn');
    lastToken = twoFactorToken;
    if (loginResults.isEmpty) throw StateError('logIn not scripted');
    return loginResults.removeAt(0);
  }

  @override
  Future<OneVpnApiResult<OneVpnUserData>> signUp({
    required String email,
    required String password,
  }) async {
    calls.add('signUp');
    if (signupResults.isEmpty) throw StateError('signUp not scripted');
    return signupResults.removeAt(0);
  }
}

Future<void> _pump(
  WidgetTester tester,
  Widget page, {
  Size size = kPortraitViewport,
}) async {
  await setViewport(tester, size);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('en'),
      localizationsDelegates: oneVpnLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: page,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _enterCreds(
  WidgetTester tester, {
  String email = 'user@example.invalid',
  String password = 'hunter2hunter2',
}) async {
  await tester.enterText(find.byType(TextField).at(0), email);
  await tester.enterText(find.byType(TextField).at(1), password);
}

Finder _submit(String label) => find.widgetWithText(InkWell, label);

/// Records each launched URL and opens every one.
class _RecordingLauncher extends UrlLauncherPlatform {
  final launched = <String>[];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> supportsMode(PreferredLaunchMode mode) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add(url);
    return true;
  }
}

/// The keyboard action key of the [index]th field.
TextInputAction? _actionOf(WidgetTester tester, int index) =>
    tester.widget<TextField>(find.byType(TextField).at(index)).textInputAction;

/// Whether the [index]th field holds focus.
bool _focused(WidgetTester tester, int index) => tester
    .widget<EditableText>(
      find.descendant(
        of: find.byType(TextField).at(index),
        matching: find.byType(EditableText),
      ),
    )
    .focusNode
    .hasFocus;

void main() {
  final l = OneVpnLocalizationsEn();

  testWidgets('opens in log-in mode with the email prefilled', (tester) async {
    await _pump(
      tester,
      OneVpnSignInPage(
        initialEmail: 'prefilled@example.invalid',
        api: _ScriptedAuthApi(),
        onAuthenticated: (_, _) async {},
      ),
    );

    expect(find.text('prefilled@example.invalid'), findsOneWidget);
    expect(find.text(l.onevpnAuthCreateAccount), findsOneWidget);
    expect(find.widgetWithText(InkWell, l.onevpnLogIn), findsOneWidget);
  });

  testWidgets('the primary button flashes white and keeps the theme focus and '
      'hover colors', (tester) async {
    await _pump(
      tester,
      OneVpnSignInPage(
        api: _ScriptedAuthApi(),
        onAuthenticated: (_, _) async {},
      ),
    );

    expectSolidInk(tester, [
      find.descendant(
        of: _submit(l.onevpnLogIn),
        matching: find.text(l.onevpnLogIn),
      ),
    ]);
  });

  testWidgets('toggles to sign-up mode', (tester) async {
    await _pump(
      tester,
      OneVpnSignInPage(
        api: _ScriptedAuthApi(),
        onAuthenticated: (_, _) async {},
      ),
    );

    await tester.ensureVisible(find.text(l.onevpnAuthCreateAccount));
    await tester.tap(find.text(l.onevpnAuthCreateAccount));
    await tester.pumpAndSettle();

    // The sign-up form's switch link reads differently from the log-in title.
    expect(find.text(l.onevpnAuthHaveAccount), findsOneWidget);
    expect(find.text(l.onevpnLogIn), findsNothing);
    expect(find.widgetWithText(InkWell, l.onevpnSignUp), findsOneWidget);

    // The link switches back, and the log-in form keeps its own title.
    await tester.ensureVisible(find.text(l.onevpnAuthHaveAccount));
    await tester.tap(find.text(l.onevpnAuthHaveAccount));
    await tester.pumpAndSettle();
    expect(find.text(l.onevpnAuthCreateAccount), findsOneWidget);
    expect(find.text(l.onevpnLogIn), findsWidgets);
  });

  testWidgets('a successful log-in adopts the session', (tester) async {
    final api = _ScriptedAuthApi()
      ..loginResults.add(
        OneVpnApiSuccess<OneVpnUserData>(_userData('user@example.invalid')),
      );
    OneVpnUserData? authed;
    await _pump(
      tester,
      OneVpnSignInPage(
        api: api,
        onAuthenticated: (_, data) async => authed = data,
      ),
    );

    await _enterCreds(tester);
    await tester.tap(_submit(l.onevpnLogIn));
    await tester.pumpAndSettle();

    expect(api.calls, contains('logIn'));
    expect(authed?.email, 'user@example.invalid');
    // The handler left the page on top, so the form is idle again.
    expect(_submit(l.onevpnLogIn), findsOneWidget);
  });

  testWidgets('a successful log-in whose handler covers the page frees the '
      'form', (tester) async {
    final api = _ScriptedAuthApi()
      ..loginResults.add(
        OneVpnApiSuccess<OneVpnUserData>(_userData('user@example.invalid')),
      );
    await _pump(
      tester,
      OneVpnSignInPage(
        api: api,
        onAuthenticated: (context, _) async {
          unawaited(
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Text('cover')),
              ),
            ),
          );
        },
      ),
    );

    await _enterCreds(tester);
    await tester.tap(_submit(l.onevpnLogIn));
    await tester.pumpAndSettle();
    expect(find.text('cover'), findsOneWidget);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();

    // The page comes back idle, not busy.
    expect(_submit(l.onevpnLogIn), findsOneWidget);
    expect(_submit(l.onevpnAuthSubmitting), findsNothing);
  });

  testWidgets('a successful log-in that pops keeps the loading label through '
      'the pop', (tester) async {
    final api = _ScriptedAuthApi()
      ..loginResults.add(
        OneVpnApiSuccess<OneVpnUserData>(_userData('user@example.invalid')),
      );
    await _pump(tester, const Scaffold());
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .push(
          MaterialPageRoute<void>(
            builder: (_) => OneVpnSignInPage(
              api: api,
              onAuthenticated: (context, _) async =>
                  Navigator.of(context).pop(),
            ),
          ),
        );
    await tester.pumpAndSettle();

    await _enterCreds(tester);
    await tester.tap(_submit(l.onevpnLogIn));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // The page is mid-pop and its button still reads as loading.
    expect(_submit(l.onevpnAuthSubmitting), findsOneWidget);
    expect(_submit(l.onevpnLogIn), findsNothing);

    await tester.pumpAndSettle();
    expect(find.byType(OneVpnSignInPage), findsNothing);
  });

  testWidgets('1001 reveals the two-factor field, and a resubmit with the '
      'token succeeds', (tester) async {
    final api = _ScriptedAuthApi()
      ..loginResults.add(
        _rejected(400, 'Invalid or missing 2FA token', code: 1001),
      )
      ..loginResults.add(
        OneVpnApiSuccess<OneVpnUserData>(_userData('user@example.invalid')),
      );
    OneVpnUserData? authed;
    await _pump(
      tester,
      OneVpnSignInPage(
        api: api,
        onAuthenticated: (_, data) async => authed = data,
      ),
    );

    await _enterCreds(tester);
    await tester.tap(_submit(l.onevpnLogIn));
    await tester.pumpAndSettle();

    // The field shows focused, and the user is not yet authenticated.
    expect(find.text(l.onevpnAuthTwoFactorLabel), findsOneWidget);
    expect(_focused(tester, 2), isTrue);
    expect(authed, isNull);

    await tester.enterText(find.byType(TextField).at(2), '123456');
    await tester.tap(_submit(l.onevpnLogIn));
    await tester.pumpAndSettle();

    expect(api.lastToken, '123456');
    expect(authed?.email, 'user@example.invalid');
  });

  testWidgets('the two-factor field takes an eight-character backup code on '
      'a text keyboard with no autocorrect', (tester) async {
    final api = _ScriptedAuthApi()
      ..loginResults.add(
        _rejected(400, 'Invalid or missing 2FA token', code: 1001),
      )
      ..loginResults.add(
        OneVpnApiSuccess<OneVpnUserData>(_userData('user@example.invalid')),
      );
    OneVpnUserData? authed;
    await _pump(
      tester,
      OneVpnSignInPage(
        api: api,
        onAuthenticated: (_, data) async => authed = data,
      ),
    );

    await _enterCreds(tester);
    await tester.tap(_submit(l.onevpnLogIn));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField).at(2));
    expect(field.keyboardType, TextInputType.text);
    expect(field.autocorrect, isFalse);
    expect(field.enableSuggestions, isFalse);

    await tester.enterText(find.byType(TextField).at(2), 'ABCD2345');
    await tester.tap(_submit(l.onevpnLogIn));
    await tester.pumpAndSettle();

    expect(api.lastToken, 'ABCD2345');
    expect(authed?.email, 'user@example.invalid');
  });

  testWidgets('a wrong code on 2FA resubmit surfaces an error and keeps the '
      'field', (tester) async {
    // The backend answers 1001 twice: once to prompt for the second factor,
    // and again for the wrong token.
    final api = _ScriptedAuthApi()
      ..loginResults.add(
        _rejected(400, 'Invalid or missing 2FA token', code: 1001),
      )
      ..loginResults.add(
        _rejected(400, 'Invalid or missing 2FA token', code: 1001),
      );
    OneVpnUserData? authed;
    await _pump(
      tester,
      OneVpnSignInPage(
        api: api,
        onAuthenticated: (_, data) async => authed = data,
      ),
    );

    await _enterCreds(tester);
    await tester.tap(_submit(l.onevpnLogIn));
    await tester.pumpAndSettle();

    // First 1001: the field appears focused with no error.
    expect(find.text(l.onevpnAuthTwoFactorLabel), findsOneWidget);
    expect(_focused(tester, 2), isTrue);
    expect(find.text(l.onevpnAuthInvalidTwoFactor), findsNothing);

    // A wrong code resubmit: the invalid-code error shows and the field stays.
    await tester.enterText(find.byType(TextField).at(2), '000000');
    await tester.tap(_submit(l.onevpnLogIn));
    await tester.pumpAndSettle();

    expect(api.lastToken, '000000');
    expect(find.text(l.onevpnAuthInvalidTwoFactor), findsOneWidget);
    expect(find.text(l.onevpnAuthTwoFactorLabel), findsOneWidget);
    expect(_focused(tester, 2), isTrue);
    expect(authed, isNull);
  });

  testWidgets('an existing-account sign-up offers log in instead, prefilled', (
    tester,
  ) async {
    final api = _ScriptedAuthApi()
      ..signupResults.add(_rejected(400, 'Email is already used'));
    await _pump(
      tester,
      OneVpnSignInPage(
        initialMode: OneVpnSignInMode.signUp,
        api: api,
        onAuthenticated: (_, _) async {},
      ),
    );

    await _enterCreds(tester, email: 'taken@example.invalid');
    await tester.tap(_submit(l.onevpnSignUp));
    await tester.pumpAndSettle();

    expect(find.text(l.onevpnAuthEmailInUse), findsOneWidget);
    expect(find.text(l.onevpnAuthLogInInstead), findsOneWidget);
    // One log-in affordance on the collision state. The mode-switch link
    // yields to the dedicated recovery link.
    expect(find.text(l.onevpnLogIn), findsNothing);

    await tester.ensureVisible(find.text(l.onevpnAuthLogInInstead));
    await tester.tap(find.text(l.onevpnAuthLogInInstead));
    await tester.pumpAndSettle();

    // The screen is now in log-in mode with the email carried over.
    expect(find.widgetWithText(InkWell, l.onevpnLogIn), findsOneWidget);
    expect(find.text('taken@example.invalid'), findsOneWidget);
  });

  testWidgets('a locked email field cannot take focus', (tester) async {
    await _pump(
      tester,
      OneVpnSignInPage(
        initialMode: OneVpnSignInMode.signUp,
        initialEmail: 'linked@example.invalid',
        lockEmail: true,
        api: _ScriptedAuthApi(),
        onAuthenticated: (_, _) async {},
      ),
    );

    final email = tester.widget<TextField>(find.byType(TextField).first);
    expect(email.readOnly, isTrue);
    expect(email.canRequestFocus, isFalse);
  });

  testWidgets('the email field takes focus when the page opens', (
    tester,
  ) async {
    await _pump(
      tester,
      OneVpnSignInPage(
        api: _ScriptedAuthApi(),
        onAuthenticated: (_, _) async {},
      ),
    );

    expect(_focused(tester, 0), isTrue);
  });

  testWidgets('with a locked email, the password field takes focus when the '
      'page opens', (tester) async {
    await _pump(
      tester,
      OneVpnSignInPage(
        initialMode: OneVpnSignInMode.signUp,
        initialEmail: 'linked@example.invalid',
        lockEmail: true,
        api: _ScriptedAuthApi(),
        onAuthenticated: (_, _) async {},
      ),
    );

    expect(_focused(tester, 1), isTrue);
  });

  testWidgets('a rate-limited attempt shows the rate-limit copy', (
    tester,
  ) async {
    final api = _ScriptedAuthApi()
      ..loginResults.add(_rejected(403, 'Request was throttled.'));
    await _pump(
      tester,
      OneVpnSignInPage(api: api, onAuthenticated: (_, _) async {}),
    );

    await _enterCreds(tester);
    await tester.tap(_submit(l.onevpnLogIn));
    await tester.pumpAndSettle();

    expect(find.text(l.onevpnAuthRateLimited), findsOneWidget);
  });

  testWidgets('wrong credentials collapse to one generic message', (
    tester,
  ) async {
    final api = _ScriptedAuthApi()
      ..loginResults.add(_rejected(400, 'Invalid credentials'));
    await _pump(
      tester,
      OneVpnSignInPage(api: api, onAuthenticated: (_, _) async {}),
    );

    await _enterCreds(tester);
    await tester.tap(_submit(l.onevpnLogIn));
    await tester.pumpAndSettle();

    expect(find.text(l.onevpnAuthInvalidCredentials), findsOneWidget);
  });

  testWidgets('an unreachable backend shows a connection error', (
    tester,
  ) async {
    final api = _ScriptedAuthApi()
      ..loginResults.add(
        const OneVpnApiUnreachable<OneVpnUserData>(<OneVpnApiAttempt>[]),
      );
    await _pump(
      tester,
      OneVpnSignInPage(api: api, onAuthenticated: (_, _) async {}),
    );

    await _enterCreds(tester);
    await tester.tap(_submit(l.onevpnLogIn));
    await tester.pumpAndSettle();

    expect(find.text(l.onevpnAuthUnreachable), findsOneWidget);
  });

  testWidgets('an empty password is caught client-side and never dials the '
      'network', (tester) async {
    final api = _ScriptedAuthApi();
    await _pump(
      tester,
      OneVpnSignInPage(api: api, onAuthenticated: (_, _) async {}),
    );

    await tester.enterText(
      find.byType(TextField).at(0),
      'user@example.invalid',
    );
    // The password stays blank.
    await tester.tap(_submit(l.onevpnLogIn));
    await tester.pumpAndSettle();

    expect(find.text(l.onevpnAuthFieldsRequired), findsOneWidget);
    expect(api.calls, isEmpty);
  });

  testWidgets('a malformed email is caught client-side', (tester) async {
    final api = _ScriptedAuthApi();
    await _pump(
      tester,
      OneVpnSignInPage(api: api, onAuthenticated: (_, _) async {}),
    );

    await _enterCreds(tester, email: 'nope');
    await tester.tap(_submit(l.onevpnLogIn));
    await tester.pumpAndSettle();

    expect(find.text(l.onevpnAuthInvalidEmail), findsOneWidget);
    expect(api.calls, isEmpty);
  });

  testWidgets('a malformed API response shows the generic error', (
    tester,
  ) async {
    final api = _ScriptedAuthApi()
      ..loginResults.add(
        const OneVpnApiMalformed<OneVpnUserData>('unparseable body'),
      );
    await _pump(
      tester,
      OneVpnSignInPage(api: api, onAuthenticated: (_, _) async {}),
    );

    await _enterCreds(tester);
    await tester.tap(_submit(l.onevpnLogIn));
    await tester.pumpAndSettle();

    expect(find.text(l.onevpnAuthGenericError), findsOneWidget);
  });

  testWidgets('the default handler adopts the session before the route '
      'answers with the completed mode', (tester) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();

    // The router builds this screen with no onAuthenticated.
    final api = _ScriptedAuthApi()
      ..signupResults.add(
        OneVpnApiSuccess<OneVpnUserData>(_userData('buyer@example.invalid')),
      );
    final account = OneVpnAccountService.instance;

    final order = <String>[];
    void onState() {
      if (account.state.value is OneVpnAccountSignedIn) order.add('adopt');
    }

    account.state.addListener(onState);
    addTearDown(() => account.state.removeListener(onState));

    await setViewport(tester, kPortraitViewport);

    final router = GoRouter(
      initialLocation: kOneVpnConnectRoute,
      routes: [
        GoRoute(
          path: kOneVpnConnectRoute,
          builder: (_, _) => const Scaffold(body: Text('host')),
        ),
        GoRoute(
          path: kOneVpnSignInRoute,
          builder: (_, _) =>
              OneVpnSignInPage(initialMode: OneVpnSignInMode.signUp, api: api),
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

    OneVpnSignInMode? answered;
    unawaited(
      router.push<OneVpnSignInMode>(kOneVpnSignInRoute).then((value) {
        order.add('pop');
        answered = value;
      }),
    );
    await tester.pumpAndSettle();

    await _enterCreds(tester, email: 'buyer@example.invalid');
    await tester.tap(_submit(l.onevpnSignUp));
    await tester.pumpAndSettle();

    expect(api.calls, contains('signUp'));
    // The route answers with the completed mode, and the adoption landed
    // first. A handler that popped without awaiting would grant against a
    // session that has not flipped, which records nothing.
    expect(answered, OneVpnSignInMode.signUp);
    expect(order, ['adopt', 'pop']);
    expect(account.session?.email, 'buyer@example.invalid');
    expect(find.text('host'), findsOneWidget);
  });

  group('the keyboard action key', () {
    testWidgets('Next on the email moves to the password', (tester) async {
      await _pump(
        tester,
        OneVpnSignInPage(
          api: _ScriptedAuthApi(),
          onAuthenticated: (_, _) async {},
        ),
      );
      expect(_actionOf(tester, 0), TextInputAction.next);
      expect(_actionOf(tester, 1), TextInputAction.done);

      await tester.showKeyboard(find.byType(TextField).at(0));
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();

      expect(_focused(tester, 1), isTrue);
    });

    testWidgets('Done on the password submits the log-in', (tester) async {
      final api = _ScriptedAuthApi()
        ..loginResults.add(
          const OneVpnApiMalformed<OneVpnUserData>('unparseable body'),
        );
      await _pump(
        tester,
        OneVpnSignInPage(api: api, onAuthenticated: (_, _) async {}),
      );

      await _enterCreds(tester);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(api.calls, ['logIn']);
    });

    testWidgets('Done on the password submits the sign-up', (tester) async {
      final api = _ScriptedAuthApi()
        ..signupResults.add(
          const OneVpnApiMalformed<OneVpnUserData>('unparseable body'),
        );
      await _pump(
        tester,
        OneVpnSignInPage(
          initialMode: OneVpnSignInMode.signUp,
          api: api,
          onAuthenticated: (_, _) async {},
        ),
      );

      await _enterCreds(tester);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(api.calls, ['signUp']);
    });

    testWidgets('with the code field shown, the password moves to the code and '
        'Done on the code submits', (tester) async {
      final api = _ScriptedAuthApi()
        ..loginResults.add(
          const OneVpnApiRejected<OneVpnUserData>(
            status: 200,
            code: 1001,
            message: 'two factor required',
          ),
        )
        ..loginResults.add(
          const OneVpnApiMalformed<OneVpnUserData>('unparseable body'),
        );
      await _pump(
        tester,
        OneVpnSignInPage(api: api, onAuthenticated: (_, _) async {}),
      );
      await _enterCreds(tester);
      await tester.tap(_submit(l.onevpnLogIn));
      await tester.pumpAndSettle();

      expect(_actionOf(tester, 1), TextInputAction.next);
      expect(_actionOf(tester, 2), TextInputAction.done);

      await tester.showKeyboard(find.byType(TextField).at(1));
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      expect(_focused(tester, 2), isTrue);

      await tester.enterText(find.byType(TextField).at(2), '123456');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(api.calls, ['logIn', 'logIn']);
      expect(api.lastToken, '123456');
    });
  });

  for (final mode in OneVpnSignInMode.values) {
    testWidgets('Forgot password opens the hosted reset page in ${mode.name}', (
      tester,
    ) async {
      final launcher = _RecordingLauncher();
      final previous = UrlLauncherPlatform.instance;
      UrlLauncherPlatform.instance = launcher;
      addTearDown(() => UrlLauncherPlatform.instance = previous);
      await _pump(
        tester,
        OneVpnSignInPage(
          initialMode: mode,
          api: _ScriptedAuthApi(),
          onAuthenticated: (_, _) async {},
        ),
      );

      await tester.ensureVisible(find.text(l.onevpnAuthForgotPassword));
      await tester.tap(find.text(l.onevpnAuthForgotPassword));
      await tester.pumpAndSettle();

      expect(launcher.launched, [OneVpnLinks.passwordReset.toString()]);
    });
  }

  test('the reset page is the hosted 1vpn page', () {
    expect(
      OneVpnLinks.passwordReset.toString(),
      'https://1vpn.org/password-reset-request/',
    );
  });

  group('the layout', () {
    void expectForm() {
      expect(find.byType(TextField), findsNWidgets(2));
      expect(_submit(l.onevpnLogIn), findsOneWidget);
      expect(find.text(l.onevpnAuthCreateAccount), findsOneWidget);
      expect(find.text(l.onevpnAuthForgotPassword), findsOneWidget);
    }

    for (final size in [kPortraitViewport, kLandscapeViewport]) {
      testWidgets('at ${size.width.toInt()}x${size.height.toInt()} the form '
          'is one capped column', (tester) async {
        await _pump(
          tester,
          OneVpnSignInPage(api: _ScriptedAuthApi()),
          size: size,
        );

        expect(tester.takeException(), isNull);
        expect(find.byKey(OneVpnConstrainedBody.stackedKey), findsOneWidget);
        expect(find.byKey(OneVpnAdaptiveBody.splitKey), findsNothing);
        expectForm();
      });
    }

    testWidgets('at 800x360 the column caps at 420dp', (tester) async {
      await _pump(
        tester,
        OneVpnSignInPage(api: _ScriptedAuthApi()),
        size: kLandscapeViewport,
      );

      expect(find.byKey(OneVpnConstrainedBody.stackedKey), findsOneWidget);
      final field = tester.getRect(find.byType(TextField).first);
      // The form insets 24dp each side inside the 420dp column.
      expect(field.width, OneVpnLayout.formCap - 48);
      expect(field.center.dx, kLandscapeViewport.width / 2);
      final submit = tester.getRect(_submit(l.onevpnLogIn));
      expect(submit.width, field.width);
    });

    group('at 800x360 with the keyboard up', () {
      const keyboard = 160.0;
      const visibleBottom = 360 - keyboard;

      Future<void> focus(WidgetTester tester, int field) async {
        await _pump(
          tester,
          OneVpnSignInPage(api: _ScriptedAuthApi()),
          size: kLandscapeViewport,
        );
        await tester.tap(find.byType(TextField).at(field));
        await tester.pump();
        tester.view.viewInsets = const FakeViewPadding(bottom: keyboard);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
      }

      testWidgets('the focused email field stays in view', (tester) async {
        await focus(tester, 0);

        expect(tester.takeException(), isNull);
        final field = tester.getRect(find.byType(TextField).at(0));
        expect(field.top, greaterThanOrEqualTo(kToolbarHeight));
        expect(field.bottom, lessThanOrEqualTo(visibleBottom));
      });

      testWidgets('the focused password field and the submit button stay in '
          'view', (tester) async {
        await focus(tester, 1);

        expect(tester.takeException(), isNull);
        final field = tester.getRect(find.byType(TextField).at(1));
        expect(field.top, greaterThanOrEqualTo(kToolbarHeight));
        expect(field.bottom, lessThanOrEqualTo(visibleBottom));
        final submit = tester.getRect(_submit(l.onevpnLogIn));
        expect(submit.bottom, lessThanOrEqualTo(visibleBottom));
        expect(_submit(l.onevpnLogIn).hitTestable(), findsOneWidget);
      });

      /// Raises the keyboard over whatever field has focus.
      Future<void> raiseKeyboard(WidgetTester tester) async {
        tester.view.viewInsets = const FakeViewPadding(bottom: keyboard);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
      }

      /// Asserts that [field] and the submit button end above the keyboard,
      /// and that the button takes a tap.
      void expectFieldAndSubmit(WidgetTester tester, Finder field) {
        expect(tester.takeException(), isNull);
        expect(tester.getRect(field).bottom, lessThanOrEqualTo(visibleBottom));
        expect(
          tester.getRect(_submit(l.onevpnLogIn)).bottom,
          lessThanOrEqualTo(visibleBottom),
        );
        expect(_submit(l.onevpnLogIn).hitTestable(), findsOneWidget);
      }

      testWidgets('after a failed submit, the refocused password field and '
          'the submit button stay in view', (tester) async {
        final api = _ScriptedAuthApi()
          ..loginResults.add(_rejected(401, 'Invalid credentials'));
        await _pump(
          tester,
          OneVpnSignInPage(api: api),
          size: kLandscapeViewport,
        );
        await _enterCreds(tester);
        await tester.tap(_submit(l.onevpnLogIn));
        await tester.pumpAndSettle();
        // The error now sits between the field and the button. The field
        // was disabled while submitting, so it lost focus.
        expect(find.text(l.onevpnAuthInvalidCredentials), findsOneWidget);

        await tester.tap(find.byType(TextField).at(1));
        await tester.pump();
        await raiseKeyboard(tester);

        expectFieldAndSubmit(tester, find.byType(TextField).at(1));
      });

      testWidgets('after a 1001, the focused two-factor field and the submit '
          'button stay in view', (tester) async {
        final api = _ScriptedAuthApi()
          ..loginResults.add(
            _rejected(400, 'Invalid or missing 2FA token', code: 1001),
          );
        await _pump(
          tester,
          OneVpnSignInPage(api: api),
          size: kLandscapeViewport,
        );
        await _enterCreds(tester);
        await raiseKeyboard(tester);
        await tester.tap(_submit(l.onevpnLogIn));
        await tester.pumpAndSettle();
        // The two-factor field now sits above the button.
        expect(find.byType(TextField), findsNWidgets(3));

        await tester.tap(find.byType(TextField).at(2));
        await tester.pumpAndSettle();

        expectFieldAndSubmit(tester, find.byType(TextField).at(2));
      });

      testWidgets('under a 24dp top inset, the focused password field and '
          'the submit button stay in view', (tester) async {
        tester.view.padding = const FakeViewPadding(top: 24);
        tester.view.viewPadding = const FakeViewPadding(top: 24);
        addTearDown(tester.view.resetPadding);
        addTearDown(tester.view.resetViewPadding);
        await focus(tester, 1);

        expectFieldAndSubmit(tester, find.byType(TextField).at(1));
      });
    });
  });
}
