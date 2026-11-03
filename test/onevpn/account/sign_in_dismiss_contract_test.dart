// A dismissed sign-in page whose request returns with a custom handler set
// or with an error. Neither test adopts through the account service.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/account/sign_in_page.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations_en.dart';
import 'package:onexray/onevpn/model/user_data.dart';
import 'package:onexray/onevpn/net/api_transport.dart';

import 'sign_in_dismiss_harness.dart';

void main() {
  final l = OneVpnLocalizationsEn();

  testWidgets('a success that returns after a dismiss skips a custom '
      'handler', (tester) async {
    final api = DismissApi();
    final handled = <OneVpnUserData>[];
    final router = await pumpSignInOverBeneath(
      tester,
      api,
      onAuthenticated: (_, data) async => handled.add(data),
    );

    final gate = Completer<void>();
    api.hold = gate;
    await submitSignIn(tester, 'custom@example.invalid');
    router.pop();
    await tester.pumpAndSettle();
    expect(find.byType(OneVpnSignInPage), findsNothing);

    gate.complete();
    await tester.pumpAndSettle();

    expect(api.calls, ['logIn']);
    expect(handled, isEmpty);
    expect(find.text('beneath'), findsOneWidget);
  });

  testWidgets('an error that returns after a dismiss shows nothing', (
    tester,
  ) async {
    final api = DismissApi()
      ..failure = const OneVpnApiUnreachable<OneVpnUserData>([]);
    final router = await pumpSignInOverBeneath(tester, api);

    final gate = Completer<void>();
    api.hold = gate;
    await submitSignIn(tester, 'error@example.invalid');
    router.pop();
    await tester.pumpAndSettle();
    expect(find.byType(OneVpnSignInPage), findsNothing);

    gate.complete();
    await tester.pumpAndSettle();

    expect(api.calls, ['logIn']);
    expect(tester.takeException(), isNull);
    expect(find.text(l.onevpnAuthUnreachable), findsNothing);
    expect(find.text('beneath'), findsOneWidget);
  });
}
