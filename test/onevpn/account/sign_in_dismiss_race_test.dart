// A dismissed sign-in whose success returns after a later sign-in. The file
// holds one test. The harness states the reason.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/account/sign_in_page.dart';
import 'package:onexray/onevpn/shell/routes.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'sign_in_dismiss_harness.dart';

void main() {
  testWidgets('a dismissed success that returns after a later sign-in leaves '
      'the later session in place', (tester) async {
    SharedPreferencesAsyncPlatform.instance = HeldPrefs();
    final api = DismissApi();
    final router = await pumpSignInOverBeneath(tester, api);

    // The first request holds while its page is dismissed.
    final first = Completer<void>();
    api.hold = first;
    await submitSignIn(tester, 'first@example.invalid');
    router.pop();
    await tester.pumpAndSettle();
    expect(find.byType(OneVpnSignInPage), findsNothing);

    // A second page signs in to another account and closes.
    final second = Completer<void>();
    api.hold = second;
    unawaited(router.push<OneVpnSignInMode>(kOneVpnSignInRoute));
    await tester.pumpAndSettle();
    await submitSignIn(tester, 'second@example.invalid');
    second.complete();
    await tester.pumpAndSettle();
    expect(
      OneVpnAccountService.instance.session?.email,
      'second@example.invalid',
    );
    expect(find.byType(OneVpnSignInPage), findsNothing);

    first.complete();
    await tester.pumpAndSettle();

    expect(api.calls, ['logIn', 'logIn']);
    expect(
      OneVpnAccountService.instance.session?.email,
      'second@example.invalid',
    );
    expect(find.text('beneath'), findsOneWidget);
  });
}
