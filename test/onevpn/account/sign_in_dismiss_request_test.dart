// The sign-in page dismissed while its request is in flight. The file
// holds one test. The harness states the reason.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/account/sign_in_page.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations_en.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'sign_in_dismiss_harness.dart';

void main() {
  final l = OneVpnLocalizationsEn();

  testWidgets('a log-in or sign-up success that returns after a dismiss '
      'adopts the session and leaves the route beneath in place', (
    tester,
  ) async {
    SharedPreferencesAsyncPlatform.instance = HeldPrefs();

    // The sign-up round adopts over the session the log-in round adopted.
    // Its submit is the newest, so a signed-in session does not block it.

    for (final mode in OneVpnSignInMode.values) {
      final api = DismissApi();
      final router = await pumpSignInOverBeneath(tester, api, mode: mode);
      final email = '${mode.name}.dismissed@example.invalid';

      // The request itself holds.
      final gate = Completer<void>();
      api.hold = gate;
      await tester.enterText(find.byType(TextField).at(0), email);
      await tester.enterText(find.byType(TextField).at(1), 'hunter2hunter2');
      final submit = mode == OneVpnSignInMode.logIn
          ? l.onevpnLogIn
          : l.onevpnSignUp;
      await tester.tap(find.widgetWithText(InkWell, submit));
      await tester.pump();
      expect(api.calls, [mode.name]);

      // The dismiss completes before the answer. The page is gone.
      router.pop();
      await tester.pumpAndSettle();
      expect(find.byType(OneVpnSignInPage), findsNothing);

      gate.complete();
      await tester.pumpAndSettle();

      expect(OneVpnAccountService.instance.session?.email, email);
      expect(find.text('beneath'), findsOneWidget);
    }
  });
}
