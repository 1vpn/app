// The buy-first funnel, end to end over a router: paywall to email to
// purchase to sign-up to the optimistic grant.
//
// This file stands up its own routes, so a test can fake the purchase and
// account seams. The root-parity suite pins the wiring of the app router.
//
// Both branches are pinned. An already-signed-in buyer never meets the
// sign-up step. A signed-out buyer is asked for an email once and buys
// with it. The buyer then lands in sign-up with that address prefilled and
// locked. The backend links the purchase to the account by it. Sign-up
// comes from the bottom edge, like the paywall.
//
// Three orderings are pinned too. The grant runs only after the session has
// flipped. The funnel does not wait for the confirmation poll. A buy-first
// purchase runs before sign-up, and the adopted session is identified to
// the purchase service before the grant.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/l10n/localizations/app_localizations.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/account/credential_store.dart';
import 'package:onexray/onevpn/account/outcomes.dart';
import 'package:onexray/onevpn/account/premium_activation.dart';
import 'package:onexray/onevpn/account/session.dart';
import 'package:onexray/onevpn/account/sign_in_page.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations_en.dart';
import 'package:onexray/onevpn/model/user_data.dart';
import 'package:onexray/onevpn/paywall/paywall_page.dart';
import 'package:onexray/onevpn/paywall/upgrade_funnel.dart';
import 'package:onexray/onevpn/purchase/fake_purchase_service.dart';
import 'package:onexray/onevpn/purchase/purchase_service.dart';
import 'package:onexray/onevpn/shell/routes.dart';
import 'package:onexray/pages/theme/theme.dart';
import 'package:onexray/onevpn/shell/layout.dart';

import '../support/localizations.dart';
import '../support/viewports.dart';

const _buyerEmail = 'buyer@example.invalid';

OneVpnSession _session({required String email, bool isPremium = false}) =>
    OneVpnSession(
      sessionAuthToken: 'token',
      username: 'someone',
      email: email,
      isPremium: isPremium,
      credentials: const OneVpnCredentials(
        uuid: 'u',
        publicKey: 'p',
        shortId: 's',
      ),
      locations: const <OneVpnApiLocation>[],
    );

/// The account seam the funnel and the paywall share, plus the adoption the
/// sign-up step performs.
class _FunnelAccount implements OneVpnPremiumAccount {
  _FunnelAccount([OneVpnAccountState initial = const OneVpnAccountSignedOut()])
    : notifier = ValueNotifier<OneVpnAccountState>(initial);

  final ValueNotifier<OneVpnAccountState> notifier;
  final List<String> calls = <String>[];

  @override
  ValueListenable<OneVpnAccountState> get state => notifier;

  /// The sign-up step's session adoption, recorded so the grant can be
  /// pinned as running after it.
  void adopt(String email) {
    calls.add('adopt');
    notifier.value = OneVpnAccountSignedIn(_session(email: email));
  }

  @override
  Future<bool> markPremiumPending() async {
    calls.add('markPremiumPending');
    return true;
  }

  @override
  Future<OneVpnRefreshOutcome> refresh({required bool manual}) async {
    calls.add('refresh');
    return const OneVpnNoSession();
  }
}

/// The fake purchase service, also writing its purchase and identity calls
/// into the funnel's event log.
class _LoggedPurchases extends OneVpnFakePurchaseService {
  _LoggedPurchases(this.events);

  final List<String> events;

  @override
  Future<OneVpnPurchaseOutcome> purchase({
    required OneVpnPurchasePackage package,
    required String email,
  }) {
    events.add('purchase');
    return super.purchase(package: package, email: email);
  }

  @override
  Future<void> identify(String appUserId) {
    events.add('identify:$appUserId');
    return super.identify(appUserId);
  }
}

const OneVpnPremiumActivationResult _granted = OneVpnPremiumActivationResult(
  signedIn: true,
  alreadyPremium: false,
  markedPending: true,
  confirmed: true,
  attempts: 1,
);

void main() {
  final l = OneVpnLocalizationsEn();

  late _FunnelAccount account;
  late OneVpnFakePurchaseService purchases;
  late List<String> events;
  late Completer<OneVpnPremiumActivationResult> activation;

  /// What the sign-up screen does when its form is submitted. Defaults to a
  /// successful sign-up that adopts the session before it pops.
  late Future<void> Function(BuildContext context, String email) onSignUp;

  setUp(() {
    account = _FunnelAccount();
    purchases = OneVpnFakePurchaseService();
    events = <String>[];
    activation = Completer<OneVpnPremiumActivationResult>();
    onSignUp = (context, email) async {
      account.adopt(email);
      if (context.mounted) context.pop(OneVpnSignInMode.signUp);
    };
  });

  /// The funnel under test, with the grant replaced by a future the test
  /// controls.
  OneVpnUpgradeFunnel funnel() => OneVpnUpgradeFunnel(
    account: account,
    activate: () {
      events.add('activate');
      return activation.future;
    },
  );

  Future<OneVpnUpgradeFunnel> pump(
    WidgetTester tester, {
    String? promptEmail = _buyerEmail,
    Size size = kPortraitViewport,
  }) async {
    await setViewport(tester, size);

    final upgrade = funnel();
    final router = GoRouter(
      initialLocation: kOneVpnConnectRoute,
      routes: [
        GoRoute(
          path: kOneVpnConnectRoute,
          builder: (_, _) => const Scaffold(body: Text('connect')),
        ),
        GoRoute(
          path: kOneVpnPaywallRoute,
          builder: (_, _) => OneVpnPaywallPage(
            service: purchases,
            accountState: account.notifier,
            onPurchaseComplete: upgrade.completePurchase,
            askForEmail: (_, _) async {
              events.add('askForEmail');
              return promptEmail;
            },
          ),
        ),
        GoRoute(
          path: kOneVpnSignInRoute,
          builder: (_, state) {
            final args = state.extra as OneVpnSignInArgs?;
            events.add(
              'signIn(${args?.mode.name},${args?.email},${args?.edge.name})',
            );
            return OneVpnSignInPage(
              initialMode: args?.mode ?? OneVpnSignInMode.logIn,
              initialEmail: args?.email ?? '',
              lockEmail: args?.lockEmail ?? false,
              onAuthenticated: (_, _) async {},
            );
          },
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
    // The paywall is a pushed route in the app, so it is pushed here too.
    // A paywall that is the whole stack cannot dismiss itself.
    router.push(kOneVpnPaywallRoute);
    await tester.pumpAndSettle();
    return upgrade;
  }

  Future<void> tapGetPremium(WidgetTester tester) async {
    await tester.tap(find.text(l.onevpnGetPremium));
    await tester.pumpAndSettle();
  }

  group('the already-signed-in branch', () {
    setUp(() {
      account.notifier.value = OneVpnAccountSignedIn(
        _session(email: _buyerEmail),
      );
    });

    testWidgets('buys with the session email and grants without a sign-up '
        'step', (tester) async {
      await pump(tester);

      await tapGetPremium(tester);

      // The email on file is the join key, so nothing is asked and nothing
      // is pushed. The grant runs and the paywall dismisses.
      expect(events, ['activate']);
      expect(purchases.lastEmail, _buyerEmail);
      expect(find.byType(OneVpnSignInPage), findsNothing);
      expect(find.text('connect'), findsOneWidget);
    });

    testWidgets('does not wait for the confirmation poll', (tester) async {
      final upgrade = await pump(tester);

      await tapGetPremium(tester);

      // The buyer is back on the connect screen while the grant is still in
      // flight. The funnel does not wait for the confirmation poll.
      expect(find.text('connect'), findsOneWidget);
      expect(activation.isCompleted, isFalse);
      expect(upgrade.activation, isNotNull);

      activation.complete(_granted);
    });
  });

  group('the buy-then-sign-up branch', () {
    testWidgets('asks for an email once, buys with it, and opens sign-up '
        'prefilled', (tester) async {
      await pump(tester);

      await tester.tap(find.text(l.onevpnGetPremium));
      await tester.pumpAndSettle();

      expect(purchases.lastEmail, _buyerEmail);
      expect(events, ['askForEmail', 'signIn(signUp,$_buyerEmail,bottom)']);
      expect(find.byType(OneVpnSignInPage), findsOneWidget);
      expect(find.text(l.onevpnSignUp), findsWidgets);
    });

    testWidgets('at 800x360, buys from the split paywall and opens sign-up '
        'prefilled', (tester) async {
      await pump(tester, size: kLandscapeViewport);
      expect(find.byKey(OneVpnAdaptiveBody.splitKey), findsOneWidget);

      await tester.tap(find.text(l.onevpnGetPremium));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(purchases.lastEmail, _buyerEmail);
      expect(events, ['askForEmail', 'signIn(signUp,$_buyerEmail,bottom)']);
      expect(find.byType(OneVpnSignInPage), findsOneWidget);
    });

    testWidgets('locks the sign-up email to the address bought with', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.text(l.onevpnGetPremium));
      await tester.pumpAndSettle();

      final email = tester.widget<TextField>(find.byType(TextField).first);
      expect(email.controller!.text, _buyerEmail);
      // The backend links the purchase by this address, so the field is
      // read-only.
      expect(email.readOnly, isTrue);
      expect(find.text(l.onevpnAuthEmailLockedHint), findsOneWidget);
    });

    testWidgets('grants only after the sign-up session is adopted', (
      tester,
    ) async {
      await pump(tester);
      await tapGetPremium(tester);

      // The sign-up completes: the session is adopted, then the screen pops.
      final signIn = tester.element(find.byType(OneVpnSignInPage));
      await onSignUp(signIn, _buyerEmail);
      await tester.pumpAndSettle();

      // The grant runs after the adoption. An earlier grant would record
      // nothing.
      expect(account.calls, ['adopt']);
      expect(events.last, 'activate');
      expect(find.text('connect'), findsOneWidget);
    });

    testWidgets('buys, then signs up, then identifies, then grants', (
      tester,
    ) async {
      purchases = _LoggedPurchases(events);
      // A real account service adopts the sign-up session, so the identity
      // call comes from the adoption itself.
      final service = OneVpnAccountService(
        store: OneVpnEphemeralCredentialStore(),
        stopTunnel: () async => true,
        clearReachabilityStamp: () async {},
        purchases: purchases,
      );
      onSignUp = (context, email) async {
        events.add('signUp');
        await service.adoptSession(
          OneVpnUserData(
            username: 'account-uuid',
            email: email,
            isPremium: false,
            sessionAuthToken: 'token',
            credentials: const OneVpnCredentials(
              uuid: 'u',
              publicKey: 'p',
              shortId: 's',
            ),
            locations: const <OneVpnApiLocation>[],
          ),
        );
        account.adopt(email);
        if (context.mounted) context.pop(OneVpnSignInMode.signUp);
      };
      await pump(tester);
      await tapGetPremium(tester);

      final signIn = tester.element(find.byType(OneVpnSignInPage));
      await onSignUp(signIn, _buyerEmail);
      await tester.pumpAndSettle();

      expect(events.where((event) => !event.startsWith('signIn(')).toList(), [
        'askForEmail',
        'purchase',
        'signUp',
        'identify:$_buyerEmail',
        'activate',
      ]);
      activation.complete(_granted);
    });

    testWidgets('records nothing when the buyer abandons sign-up', (
      tester,
    ) async {
      await pump(tester);
      await tapGetPremium(tester);
      expect(find.byType(OneVpnSignInPage), findsOneWidget);

      // Backing out of sign-up returns no session, so there is nothing to
      // grant against.
      final signIn = tester.element(find.byType(OneVpnSignInPage));
      GoRouter.of(signIn).pop();
      await tester.pumpAndSettle();

      expect(events, isNot(contains('activate')));
      expect(account.calls, isEmpty);
    });

    testWidgets('backing out of the email prompt buys nothing', (tester) async {
      await pump(tester, promptEmail: null);

      await tapGetPremium(tester);

      expect(purchases.calls, isNot(contains('purchase')));
      expect(events, ['askForEmail']);
      expect(find.text(l.onevpnGetPremium), findsOneWidget);
    });
  });
}
