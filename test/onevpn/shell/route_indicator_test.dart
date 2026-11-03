// The connect-screen header routing indicator. It shows a routing icon and the
// active region's raw ISO code only when a region is active. A null region, All
// via VPN, renders nothing. Tapping it invokes the callback that opens the
// Direct-regions picker. Its 4dp inset sits on the end side in both text
// directions.

import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/l10n/localizations/app_localizations.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations_en.dart';
import 'package:onexray/onevpn/shell/route_indicator.dart';
import 'package:onexray/pages/theme/theme.dart';

import '../support/ink.dart';
import '../support/localizations.dart';

Future<void> _pump(
  WidgetTester tester, {
  required String? region,
  required VoidCallback onTap,
  TextDirection direction = TextDirection.ltr,
}) async {
  await tester.binding.setSurfaceSize(const Size(360, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('en'),
      localizationsDelegates: oneVpnLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) =>
          Directionality(textDirection: direction, child: child!),
      home: Scaffold(
        body: OneVpnRouteIndicator(region: region, onTap: onTap),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final l = OneVpnLocalizationsEn();

  testWidgets('hides when the selection is All via VPN (null region)', (
    tester,
  ) async {
    await _pump(tester, region: null, onTap: () {});

    expect(find.byIcon(LucideIcons.route), findsNothing);
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets(
    'shows the routing icon and raw ISO code when a region is active',
    (tester) async {
      await _pump(tester, region: 'CN', onTap: () {});

      expect(find.byIcon(LucideIcons.route), findsOneWidget);
      // The raw ISO code renders, not a long label.
      expect(find.text('CN'), findsOneWidget);
      expect(find.text(l.onevpnRegionChina), findsNothing);
    },
  );

  testWidgets('leaves focus and hover to the theme and shows nothing when '
      'pressed', (tester) async {
    await _pump(tester, region: 'CN', onTap: () {});

    expectQuietInk(tester, [find.text('CN')]);
  });

  testWidgets('tapping it invokes the picker callback', (tester) async {
    var taps = 0;
    await _pump(tester, region: 'RU', onTap: () => taps++);

    await tester.tap(find.byType(OneVpnRouteIndicator));
    await tester.pumpAndSettle();

    expect(taps, 1);
  });

  for (final direction in TextDirection.values) {
    testWidgets('the end inset sits on the end side in $direction', (
      tester,
    ) async {
      await _pump(tester, region: 'CN', onTap: () {}, direction: direction);

      // The pill fills the widget less its insets: none at the start, 4dp at
      // the end.
      final widget = tester.getRect(find.byType(OneVpnRouteIndicator));
      final pill = tester.getRect(
        find
            .descendant(
              of: find.byType(OneVpnRouteIndicator),
              matching: find.byType(Material),
            )
            .first,
      );
      final (startGap, endGap) = direction == TextDirection.ltr
          ? (pill.left - widget.left, widget.right - pill.right)
          : (widget.right - pill.right, pill.left - widget.left);
      expect(startGap, 0);
      expect(endGap, 4);
    });
  }
}
