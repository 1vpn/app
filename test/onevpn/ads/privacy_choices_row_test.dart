// The Support page's Privacy choices row. It is absent until a consent
// information update reports a privacy options entry required. It then
// shows after the links, fits the reference handset, and opens the privacy
// options form.

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/l10n/localizations/app_localizations.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/ads/ad_gateway.dart';
import 'package:onexray/onevpn/ads/connect_ad_gate.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations_en.dart';
import 'package:onexray/onevpn/shell/support_page.dart';
import 'package:onexray/pages/theme/theme.dart';
import 'package:package_info_plus/package_info_plus.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../support/localizations.dart';
import '../support/viewports.dart';
import 'fake_ad_gateway.dart';

void main() {
  final l = OneVpnLocalizationsEn();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  Future<void> pump(WidgetTester tester, OneVpnConnectAdGate gate) async {
    await setViewport(tester, kPortraitViewport);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        localizationsDelegates: oneVpnLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OneVpnSupportPage(
          adGate: gate,
          packageInfo: Future<PackageInfo?>.value(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the row stays absent while no entry is required', (
    tester,
  ) async {
    final gateway = FakeAdGateway();
    final gate = OneVpnConnectAdGate(gateway: gateway);
    gate.preload(
      const OneVpnAccountSignedOut(),
      source: OneVpnAdLoadSource.entry,
      tunnelDown: () => true,
    );
    await tester.pump();
    await pump(tester, gate);

    expect(find.text(l.onevpnPrivacyChoices), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a required entry shows the row, and a tap opens the form', (
    tester,
  ) async {
    final gateway = FakeAdGateway(privacyRequired: true);
    final gate = OneVpnConnectAdGate(gateway: gateway);
    await pump(tester, gate);
    expect(find.text(l.onevpnPrivacyChoices), findsNothing);

    gate.preload(
      const OneVpnAccountSignedOut(),
      source: OneVpnAdLoadSource.entry,
      tunnelDown: () => true,
    );
    await tester.pumpAndSettle();

    final row = find.text(l.onevpnPrivacyChoices);
    expect(row, findsOneWidget);
    expect(
      tester.getTopLeft(row).dy,
      greaterThan(tester.getTopLeft(find.text(l.onevpnRefundPolicy)).dy),
    );
    await tester.tap(row);
    await tester.pump();

    expect(gateway.calls.last, 'privacyForm');
    expect(tester.takeException(), isNull);
  });
}
