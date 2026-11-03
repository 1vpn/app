// The picker and the connect-row label name locations in the active locale.
// A location the app has never seen shows the API's English names and the
// globe. Right-to-left rows keep the flag in the leading slot.

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/core/db/database/database.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/account/session.dart';
import 'package:onexray/onevpn/catalogue/catalogue.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations_ja.dart';
import 'package:onexray/onevpn/l10n/locales.dart';
import 'package:onexray/onevpn/location/flag.dart';
import 'package:onexray/onevpn/location/location_picker_page.dart';
import 'package:onexray/onevpn/model/user_data.dart';
import 'package:onexray/onevpn/shell/connect_screen.dart';
import 'package:onexray/pages/theme/theme.dart';
import 'package:onexray/service/connect/settings.dart';
import 'package:onexray/service/servers/catalog.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/localizations.dart';
import '../support/viewports.dart';

CoreConfigData _node(String name, int id) => CoreConfigData(
  id: id,
  name: name,
  type: 'outbound',
  tags: 'vless',
  delay: 20,
  subId: 0,
  countryCode: null,
  favorite: false,
  data: '',
);

OneVpnApiLocation _api(
  String city,
  String cityCode,
  String country,
  String countryCode,
) => OneVpnApiLocation(
  city: city,
  cityCode: cityCode,
  country: country,
  countryCode: countryCode,
  servers: [OneVpnApiServer(host: '$cityCode.example.invalid')],
);

/// A premium session with a seeded city, a new city, and an unseen one.
final _session = OneVpnSession(
  sessionAuthToken: 'token',
  username: 'someone',
  email: 'someone@example.invalid',
  isPremium: true,
  credentials: const OneVpnCredentials(uuid: 'u', publicKey: 'p', shortId: 's'),
  locations: [
    _api('Tokyo', 'nrt', 'Japan', 'jp'),
    _api('Zurich', 'zrh', 'Switzerland', 'ch'),
    _api('Atlantis City', 'xyz', 'Atlantis', 'zz'),
  ],
);

Future<void> _pump(WidgetTester tester, Locale locale) async {
  await setViewport(tester, kPortraitViewport);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: locale,
      localizationsDelegates: oneVpnLocalizationsDelegates,
      supportedLocales: [for (final l in kOneVpnLocales) l.locale],
      builder: (context, child) => Directionality(
        textDirection: oneVpnTextDirection(Localizations.localeOf(context)),
        child: ShadTheme(
          data: AppTheme.shad(Brightness.light),
          child: ShadToaster(child: child!),
        ),
      ),
      home: OneVpnLocationPickerPage(
        accountState: ValueNotifier(OneVpnAccountSignedIn(_session)),
        serversStream: Stream.value([
          _node('1vpn·acct·nrt·1', 1),
          _node('1vpn·acct·zrh·1', 2),
          _node('1vpn·acct·xyz·1', 3),
        ]),
        selectionStream: Stream.value(const ServerSelection.automatic()),
        onSelect: (_, _, _) async {},
        onPaywall: (_) {},
        onRetry: () async {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The row tile that carries [title].
Finder _tile(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(InkWell)).first;

void main() {
  for (final (locale, tokyo, japan, zurich, switzerland) in const [
    (Locale('ja'), '東京', '日本', 'チューリッヒ', 'スイス'),
    (Locale('de'), 'Tokio', 'Japan', 'Zürich', 'Schweiz'),
    (Locale('ar'), 'طوكيو', 'اليابان', 'زيورخ', 'سويسرا'),
  ]) {
    testWidgets('under ${locale.languageCode}, rows name the city and '
        'country in the locale', (tester) async {
      await _pump(tester, locale);
      expect(find.text(tokyo), findsOneWidget);
      expect(find.text(japan), findsOneWidget);
      expect(find.text(zurich), findsOneWidget);
      expect(find.text(switzerland), findsOneWidget);
      // Anti-vacuity: the English API names are gone from these rows.
      expect(find.text('Tokyo'), findsNothing);
      expect(find.text('Zurich'), findsNothing);
    });
  }

  testWidgets('an unseen location shows the API names and the globe', (
    tester,
  ) async {
    await _pump(tester, const Locale('ja'));
    expect(find.text('Atlantis City'), findsOneWidget);
    expect(find.text('Atlantis'), findsOneWidget);
    expect(
      find.descendant(
        of: _tile('Atlantis City'),
        matching: find.byIcon(LucideIcons.globe),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: _tile('Atlantis City'),
        matching: find.byType(OneVpnFlag),
      ),
      findsNothing,
    );
  });

  testWidgets('under ar, the row reads right to left with the flag leading', (
    tester,
  ) async {
    await _pump(tester, const Locale('ar'));
    final title = find.text('طوكيو');
    expect(Directionality.of(tester.element(title)), TextDirection.rtl);
    final flag = find.descendant(
      of: _tile('طوكيو'),
      matching: find.byType(OneVpnFlag),
    );
    expect(flag, findsOneWidget);
    // The leading slot sits at the right edge in a right-to-left row.
    expect(tester.getRect(flag).left, greaterThan(tester.getRect(title).right));
    // The unseen city keeps its Latin name inside the Arabic fallback.
    expect(find.textContaining('Atlantis City'), findsOneWidget);
  });

  test('the connect-row label names the city in the locale', () {
    final l = OneVpnLocalizationsJa();
    final catalogue = OneVpnCatalogue.forSession(_session);
    String label(String stem) => OneVpnConnectRowLabel.locationRow(
      l: l,
      selection: ServerSelection.location(stem),
      connected: false,
      resolvedNodeId: null,
      catalog: ServerCatalog(servers: const []),
      catalogue: catalogue,
    );
    expect(label('1vpn·acct·nrt'), '東京');
    expect(label('1vpn·acct·zrh'), 'チューリッヒ');
    expect(label('1vpn·acct·xyz'), 'Atlantis City');
    expect(
      OneVpnConnectRowLabel.cityOf(
        l,
        const ServerSelection.location('1vpn·acct·zrh'),
        catalogue,
      ),
      'チューリッヒ',
    );
  });
}
