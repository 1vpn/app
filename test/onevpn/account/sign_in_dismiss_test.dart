// The sign-in page dismissed while its default handler adopts the session.
// The file holds one test. The harness states the reason.

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

  testWidgets('an adoption that completes after a dismiss leaves the route '
      'beneath in place', (tester) async {
    final prefs = HeldPrefs();
    SharedPreferencesAsyncPlatform.instance = prefs;
    final api = DismissApi();
    final router = await pumpSignInOverBeneath(tester, api);

    // The adoption holds on the session write.
    final gate = Completer<void>();
    prefs.hold = gate;
    await tester.enterText(
      find.byType(TextField).at(0),
      'late@example.invalid',
    );
    await tester.enterText(find.byType(TextField).at(1), 'hunter2hunter2');
    await tester.tap(find.widgetWithText(InkWell, l.onevpnLogIn));
    await tester.pump();
    expect(api.calls, ['logIn']);

    // The dismiss starts the exit. The page stays mounted through it.
    router.pop();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(OneVpnSignInPage), findsOneWidget);

    prefs.hold = null;
    gate.complete();
    await tester.pumpAndSettle();

    expect(
      OneVpnAccountService.instance.session?.email,
      'late@example.invalid',
    );
    expect(find.byType(OneVpnSignInPage), findsNothing);
    expect(find.text('beneath'), findsOneWidget);
  });
}
