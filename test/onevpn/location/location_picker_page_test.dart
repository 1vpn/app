// The location picker page: its rows, the teaser tap-through to the paywall
// seam, the location-selection write, and the degraded and terminal states.
//
// At 360x800 the rows form one column. At 800x360 the tiles flow into a
// two-column grid, with the degraded banner and the Upgrade header spanning
// both columns. A selection made in the grid returns to the connect screen.

import 'dart:async';

import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/core/db/database/database.dart';
import 'package:onexray/core/pigeon/messages.g.dart';
import 'package:onexray/l10n/localizations/app_localizations.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/account/session.dart';
import 'package:onexray/onevpn/catalogue/catalogue.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations_en.dart';
import 'package:onexray/onevpn/location/flag.dart';
import 'package:onexray/onevpn/location/location_picker_model.dart';
import 'package:onexray/onevpn/location/location_picker_page.dart';
import 'package:onexray/onevpn/model/user_data.dart';
import 'package:onexray/onevpn/paywall/paywall_cadence.dart';
import 'package:onexray/onevpn/paywall/paywall_trigger.dart';
import 'package:onexray/onevpn/shell/connect_screen.dart';
import 'package:onexray/onevpn/shell/layout.dart';
import 'package:onexray/onevpn/shell/routes.dart';
import 'package:onexray/onevpn/theme/backdrop.dart';
import 'package:onexray/onevpn/theme/card.dart';
import 'package:onexray/pages/theme/color.dart';
import 'package:onexray/pages/theme/theme.dart';
import 'package:onexray/service/connect/coordinator.dart';
import 'package:onexray/service/connect/runtime_host.dart';
import 'package:onexray/service/connect/settings.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../support/held_tunnel_stub.dart';
import '../support/invoke_channel_stub.dart';
import '../support/ink.dart';
import '../support/localizations.dart';
import '../support/viewports.dart';

CoreConfigData _node(String name, {int id = 1}) => CoreConfigData(
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

List<CoreConfigData> _freeFloorRows() => [
  _node('1vpn·free·ams·1', id: 1),
  _node('1vpn·free·sgp·1', id: 2),
  _node('1vpn·free·lax·1', id: 3),
];

OneVpnSession _premium() => const OneVpnSession(
  sessionAuthToken: 'token',
  username: 'someone',
  email: 'someone@example.invalid',
  isPremium: true,
  credentials: OneVpnCredentials(uuid: 'u', publicKey: 'p', shortId: 's'),
  locations: <OneVpnApiLocation>[],
);

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
      builder: (context, child) => ShadTheme(
        data: AppTheme.shad(Brightness.light),
        child: ShadToaster(child: child!),
      ),
      home: page,
    ),
  );
  await tester.pumpAndSettle();
}

/// A premium session with one account location, Tokyo.
OneVpnSession _premiumWithTokyo() => const OneVpnSession(
  sessionAuthToken: 'token',
  username: 'someone',
  email: 'someone@example.invalid',
  isPremium: true,
  credentials: OneVpnCredentials(uuid: 'u', publicKey: 'p', shortId: 's'),
  locations: <OneVpnApiLocation>[
    OneVpnApiLocation(
      city: 'Tokyo',
      cityCode: 'nrt',
      country: 'Japan',
      countryCode: 'jp',
      servers: <OneVpnApiServer>[
        OneVpnApiServer(host: 'nrt-1.example.invalid'),
      ],
    ),
  ],
);

/// Twenty account cities, `c01` to `c20`. At 360x800 the last ones sit past
/// the fold.
final _cityCodes = [for (var i = 1; i <= 20; i++) 'c${'$i'.padLeft(2, '0')}'];

/// A picker over [_cityCodes], every city provisioned, with [selection]
/// committed.
OneVpnLocationPickerPage _cityPicker({
  required ServerSelection selection,
  Future<void> Function(BuildContext, ServerSelection, String)? onSelect,
}) => OneVpnLocationPickerPage(
  accountState: ValueNotifier(
    OneVpnAccountSignedIn(
      OneVpnSession(
        sessionAuthToken: 'token',
        username: 'someone',
        email: 'someone@example.invalid',
        isPremium: true,
        credentials: const OneVpnCredentials(
          uuid: 'u',
          publicKey: 'p',
          shortId: 's',
        ),
        locations: [
          for (final code in _cityCodes)
            OneVpnApiLocation(
              city: 'City $code',
              cityCode: code,
              country: 'Japan',
              countryCode: 'jp',
              servers: [OneVpnApiServer(host: '$code.example.invalid')],
            ),
        ],
      ),
    ),
  ),
  serversStream: Stream.value([
    for (var i = 0; i < _cityCodes.length; i++)
      _node('1vpn·acct·${_cityCodes[i]}·1', id: 10 + i),
  ]),
  initialSelection: selection,
  selectionStream: const Stream.empty(),
  onSelect: onSelect ?? (_, _, _) async {},
  onPaywall: (_) {},
  onRetry: () async {},
);

/// An entitled audience, so the recurring paywall never opens.
class _EntitledAudience implements OneVpnPaywallAudience {
  @override
  bool get entitled => true;

  @override
  Future<void> whenRestored() async {}
}

void main() {
  final l = OneVpnLocalizationsEn();

  testWidgets('a premium picker lists the free nodes only after the failover '
      'window passes with no premium node', (tester) async {
    await _pump(
      tester,
      OneVpnLocationPickerPage(
        accountState: ValueNotifier(OneVpnAccountSignedIn(_premiumWithTokyo())),
        serversStream: Stream.value(_freeFloorRows()),
        selectionStream: Stream.value(const ServerSelection.automatic()),
        onSelect: (_, _, _) async {},
        onPaywall: (_) {},
        onRetry: () async {},
      ),
    );
    expect(find.text('Tokyo'), findsOneWidget);
    expect(find.text('Amsterdam'), findsNothing);

    // The settle above advanced the clock by under a second.
    await tester.pump(
      kOneVpnPremiumFailoverWindow - const Duration(seconds: 1),
    );
    expect(find.text('Amsterdam'), findsNothing);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Amsterdam'), findsOneWidget);
    expect(find.text('Tokyo'), findsOneWidget);
  });

  testWidgets('a premium picker with a premium node keeps the free nodes '
      'hidden past the failover window', (tester) async {
    await _pump(
      tester,
      OneVpnLocationPickerPage(
        accountState: ValueNotifier(OneVpnAccountSignedIn(_premiumWithTokyo())),
        serversStream: Stream.value([
          ..._freeFloorRows(),
          _node('1vpn·acct·nrt·1', id: 9),
        ]),
        selectionStream: Stream.value(const ServerSelection.automatic()),
        onSelect: (_, _, _) async {},
        onPaywall: (_) {},
        onRetry: () async {},
      ),
    );
    await tester.pump(kOneVpnPremiumFailoverWindow);
    expect(find.text('Tokyo'), findsOneWidget);
    expect(find.text('Amsterdam'), findsNothing);
  });

  testWidgets('a premium picker keeps the free nodes once it lists them', (
    tester,
  ) async {
    final servers = StreamController<List<CoreConfigData>>();
    addTearDown(servers.close);
    await _pump(
      tester,
      OneVpnLocationPickerPage(
        accountState: ValueNotifier(OneVpnAccountSignedIn(_premiumWithTokyo())),
        serversStream: servers.stream,
        selectionStream: Stream.value(const ServerSelection.automatic()),
        onSelect: (_, _, _) async {},
        onPaywall: (_) {},
        onRetry: () async {},
      ),
    );
    servers.add(_freeFloorRows());
    await tester.pump(kOneVpnPremiumFailoverWindow);
    expect(find.text('Amsterdam'), findsOneWidget);

    // A premium node provisions late.
    servers.add([..._freeFloorRows(), _node('1vpn·acct·nrt·1', id: 9)]);
    await tester.pumpAndSettle();
    expect(find.text('Amsterdam'), findsOneWidget);
    expect(find.text('Tokyo'), findsOneWidget);
  });

  testWidgets('the failover window restarts when the account first turns '
      'premium', (tester) async {
    final account = ValueNotifier<OneVpnAccountState>(
      const OneVpnAccountSignedOut(),
    );
    addTearDown(account.dispose);
    await _pump(
      tester,
      OneVpnLocationPickerPage(
        accountState: account,
        serversStream: Stream.value(_freeFloorRows()),
        selectionStream: Stream.value(const ServerSelection.automatic()),
        onSelect: (_, _, _) async {},
        onPaywall: (_) {},
        onRetry: () async {},
      ),
    );
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Amsterdam'), findsOneWidget);

    account.value = OneVpnAccountSignedIn(_premiumWithTokyo());
    await tester.pump();
    expect(find.text('Amsterdam'), findsNothing);

    await tester.pump(
      kOneVpnPremiumFailoverWindow - const Duration(seconds: 1),
    );
    expect(find.text('Amsterdam'), findsNothing);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Amsterdam'), findsOneWidget);
  });

  testWidgets('a premium picker seeded with Automatic lists no free nodes on '
      'its first frame', (tester) async {
    final selection = StreamController<ServerSelection>();
    addTearDown(selection.close);
    await setViewport(tester, kPortraitViewport);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        localizationsDelegates: oneVpnLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OneVpnLocationPickerPage(
          accountState: ValueNotifier(
            OneVpnAccountSignedIn(_premiumWithTokyo()),
          ),
          serversStream: Stream.value([
            ..._freeFloorRows(),
            _node('1vpn·acct·nrt·1', id: 9),
          ]),
          selectionStream: selection.stream,
          initialSelection: const ServerSelection.automatic(),
          onSelect: (_, _, _) async {},
          onPaywall: (_) {},
          onRetry: () async {},
        ),
      ),
    );
    expect(find.text('Tokyo'), findsOneWidget);
    expect(find.text('Amsterdam'), findsNothing);

    await tester.pumpAndSettle();
    expect(find.text('Amsterdam'), findsNothing);
  });

  testWidgets('a premium picker holds the free nodes until the selection '
      'loads, then keeps every selected one', (tester) async {
    final selection = StreamController<ServerSelection>();
    addTearDown(selection.close);
    await _pump(
      tester,
      OneVpnLocationPickerPage(
        accountState: ValueNotifier(OneVpnAccountSignedIn(_premiumWithTokyo())),
        serversStream: Stream.value([
          ..._freeFloorRows(),
          _node('1vpn·acct·nrt·1', id: 9),
        ]),
        selectionStream: selection.stream,
        onSelect: (_, _, _) async {},
        onPaywall: (_) {},
        onRetry: () async {},
      ),
    );
    expect(find.text('Amsterdam'), findsOneWidget);

    selection.add(const ServerSelection.location('1vpn·free·ams'));
    await tester.pumpAndSettle();
    expect(find.text('Amsterdam'), findsOneWidget);
    expect(find.text('Los Angeles'), findsNothing);

    // The new selection lands while the page pops.
    selection.add(const ServerSelection.location('1vpn·acct·nrt'));
    await tester.pumpAndSettle();
    expect(find.text('Amsterdam'), findsOneWidget);
    expect(find.text('Los Angeles'), findsNothing);
  });

  testWidgets('the Automatic row reads its title over its subtitle and '
      'every row carries the card outline', (tester) async {
    await _pump(
      tester,
      OneVpnLocationPickerPage(
        accountState: ValueNotifier(const OneVpnAccountSignedOut()),
        serversStream: Stream.value(_freeFloorRows()),
        selectionStream: Stream.value(const ServerSelection.automatic()),
        onSelect: (_, _, _) async {},
        onPaywall: (_) {},
        onRetry: () async {},
      ),
    );
    expect(
      find.descendant(
        of: find
            .ancestor(
              of: find.text(l.onevpnAutomaticSelection),
              matching: find.byType(InkWell),
            )
            .first,
        matching: find.text(l.onevpnAutomaticSubtitle),
      ),
      findsOneWidget,
    );
    final automatic = tester.widget<Material>(
      find
          .ancestor(
            of: find.text(l.onevpnAutomaticSelection),
            matching: find.byType(Material),
          )
          .first,
    );
    final shape = automatic.shape! as RoundedRectangleBorder;
    final palette = ColorManager.palette(
      tester.element(find.text(l.onevpnAutomaticSelection)),
    );
    // The selected row takes the selected fill and a primary outline.
    expect(
      shape.side,
      BorderSide(color: palette.primary, width: OneVpnCard.outline),
    );
    expect(automatic.color, palette.selectedSurface);

    final amsterdam = tester.widget<Material>(
      find
          .ancestor(of: find.text('Amsterdam'), matching: find.byType(Material))
          .first,
    );
    expect(
      (amsterdam.shape! as RoundedRectangleBorder).side,
      BorderSide(color: palette.border, width: OneVpnCard.outline),
    );
    expect(amsterdam.color, palette.card);
  });

  group('the tier treatment', () {
    for (final size in [kPortraitViewport, kLandscapeViewport]) {
      testWidgets('at ${size.width.toInt()}x${size.height.toInt()} an '
          'all-free list takes a Free header and no per-row label', (
        tester,
      ) async {
        await _pump(
          tester,
          OneVpnLocationPickerPage(
            accountState: ValueNotifier(const OneVpnAccountSignedOut()),
            serversStream: Stream.value(_freeFloorRows()),
            selectionStream: Stream.value(const ServerSelection.automatic()),
            onSelect: (_, _, _) async {},
            onPaywall: (_) {},
            onRetry: () async {},
          ),
          size: size,
        );
        expect(tester.takeException(), isNull);
        // The header is the one Free label on the page.
        expect(find.text(l.onevpnFree), findsOneWidget);
        final header = tester.getRect(find.text(l.onevpnFree));
        expect(
          header.bottom,
          lessThan(tester.getRect(find.text('Amsterdam')).top),
        );
        expect(
          header.top,
          greaterThan(
            tester.getRect(find.text(l.onevpnAutomaticSelection)).bottom,
          ),
        );
        expect(find.text('Netherlands'), findsOneWidget);
        expect(find.text(l.onevpnFreeSubtitle('Netherlands')), findsNothing);
      });
    }

    testWidgets('a free row among premium rows names its tier in the second '
        'line, under no Free header', (tester) async {
      final servers = StreamController<List<CoreConfigData>>();
      addTearDown(servers.close);
      await _pump(
        tester,
        OneVpnLocationPickerPage(
          accountState: ValueNotifier(
            OneVpnAccountSignedIn(_premiumWithTokyo()),
          ),
          serversStream: servers.stream,
          selectionStream: Stream.value(const ServerSelection.automatic()),
          onSelect: (_, _, _) async {},
          onPaywall: (_) {},
          onRetry: () async {},
        ),
      );
      servers.add(_freeFloorRows());
      await tester.pump(kOneVpnPremiumFailoverWindow);
      servers.add([..._freeFloorRows(), _node('1vpn·acct·nrt·1', id: 9)]);
      await tester.pumpAndSettle();

      expect(find.text('Tokyo'), findsOneWidget);
      expect(find.text('Japan'), findsOneWidget);
      expect(find.text(l.onevpnFreeSubtitle('Netherlands')), findsOneWidget);
      expect(find.text(l.onevpnFree), findsNothing);
    });
  });

  for (final size in [kPortraitViewport, kLandscapeViewport]) {
    final split = size == kLandscapeViewport;
    testWidgets('at ${size.width.toInt()}x${size.height.toInt()} the '
        'Automatic bolt sits on a flag-sized square, and the list starts 22dp '
        '${split ? 'down the grid' : 'under the app bar'}', (tester) async {
      await _pump(
        tester,
        OneVpnLocationPickerPage(
          accountState: ValueNotifier(const OneVpnAccountSignedOut()),
          serversStream: Stream.value(_freeFloorRows()),
          selectionStream: Stream.value(const ServerSelection.automatic()),
          onSelect: (_, _, _) async {},
          onPaywall: (_) {},
          onRetry: () async {},
        ),
        size: size,
      );
      expect(tester.takeException(), isNull);
      final grid = find.byKey(OneVpnLocationPickerPage.gridKey);
      expect(grid, split ? findsOneWidget : findsNothing);
      final square = find.ancestor(
        of: find.byIcon(LucideIcons.zap),
        matching: find.byType(OneVpnBackdropSquare),
      );
      expect(tester.getSize(square), const Size.square(OneVpnFlag.defaultSize));
      // The Automatic title starts where the flag rows' titles start.
      expect(
        tester.getTopLeft(find.text(l.onevpnAutomaticSelection)).dx,
        tester.getTopLeft(find.text('Amsterdam')).dx,
      );
      final automatic = tester.getRect(
        find
            .ancestor(
              of: find.text(l.onevpnAutomaticSelection),
              matching: find.byType(InkWell),
            )
            .first,
      );
      final top = split
          ? tester.getRect(grid).top
          : tester.getRect(find.byType(AppBar)).bottom;
      // The list's 16dp inset and the tile's 6dp inset.
      expect(automatic.top - top, 22);
    });
  }

  testWidgets('renders Automatic on top, the three free cities, and teasers', (
    tester,
  ) async {
    await _pump(
      tester,
      OneVpnLocationPickerPage(
        accountState: ValueNotifier(const OneVpnAccountSignedOut()),
        serversStream: Stream.value(_freeFloorRows()),
        selectionStream: Stream.value(const ServerSelection.automatic()),
        onSelect: (_, _, _) async {},
        onPaywall: (_) {},
        onRetry: () async {},
      ),
    );

    expect(find.text(l.onevpnAutomaticSelection), findsOneWidget);
    expect(find.text('Amsterdam'), findsOneWidget);
    // Singapore is both city and country, so it titles and subtitles its row.
    expect(find.text('Singapore'), findsWidgets);
    expect(find.text('Los Angeles'), findsOneWidget);
    // Automatic is the pinned top row.
    expect(
      tester.getTopLeft(find.text(l.onevpnAutomaticSelection)).dy,
      lessThan(tester.getTopLeft(find.text('Amsterdam')).dy),
    );
    // The teasers render locked.
    expect(find.byIcon(LucideIcons.lock), findsWidgets);
  });

  testWidgets('screen readers hear one group with the committed row '
      'selected, and a teaser reads as locked', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(
      tester,
      OneVpnLocationPickerPage(
        accountState: ValueNotifier(const OneVpnAccountSignedOut()),
        serversStream: Stream.value(_freeFloorRows()),
        selectionStream: Stream.value(
          const ServerSelection.location('1vpn·free·ams'),
        ),
        onSelect: (_, _, _) async {},
        onPaywall: (_) {},
        onRetry: () async {},
      ),
    );
    Finder row(Finder child) =>
        find.ancestor(of: child, matching: find.byType(InkWell)).first;

    for (final title in [l.onevpnAutomaticSelection, 'Amsterdam']) {
      expect(
        tester.getSemantics(row(find.text(title))),
        isSemantics(
          hasSelectedState: true,
          isSelected: title == 'Amsterdam',
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
        ),
        reason: title,
      );
    }
    final teaser = tester.getSemantics(
      row(find.byIcon(LucideIcons.lock).first),
    );
    expect(teaser.label, contains(l.onevpnLocationLocked));
    expect(
      teaser,
      isSemantics(
        hasSelectedState: false,
        isInMutuallyExclusiveGroup: false,
        hasTapAction: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('a teaser tap targets the paywall seam', (tester) async {
    var paywalled = 0;
    await _pump(
      tester,
      OneVpnLocationPickerPage(
        accountState: ValueNotifier(const OneVpnAccountSignedOut()),
        serversStream: Stream.value(_freeFloorRows()),
        selectionStream: Stream.value(const ServerSelection.automatic()),
        onSelect: (_, _, _) async {},
        onPaywall: (_) => paywalled++,
        onRetry: () async {},
      ),
    );
    await tester.tap(find.byIcon(LucideIcons.lock).first);
    await tester.pump();
    expect(paywalled, 1);
  });

  testWidgets('a location tap writes the location selection', (tester) async {
    ServerSelection? written;
    String? label;
    await _pump(
      tester,
      OneVpnLocationPickerPage(
        accountState: ValueNotifier(const OneVpnAccountSignedOut()),
        serversStream: Stream.value(_freeFloorRows()),
        selectionStream: Stream.value(const ServerSelection.automatic()),
        onSelect: (_, selection, rowLabel) async {
          written = selection;
          label = rowLabel;
        },
        onPaywall: (_) {},
        onRetry: () async {},
      ),
    );
    await tester.tap(find.text('Amsterdam'));
    await tester.pump();
    expect(written?.kind, SelectionKind.location);
    expect(written?.location, '1vpn·free·ams');
    expect(label, 'Amsterdam');
  });

  testWidgets('Automatic tap writes the automatic selection', (tester) async {
    ServerSelection? written;
    await _pump(
      tester,
      OneVpnLocationPickerPage(
        accountState: ValueNotifier(const OneVpnAccountSignedOut()),
        serversStream: Stream.value(_freeFloorRows()),
        selectionStream: Stream.value(const ServerSelection.automatic()),
        onSelect: (_, selection, _) async => written = selection,
        onPaywall: (_) {},
        onRetry: () async {},
      ),
    );
    await tester.tap(find.text(l.onevpnAutomaticSelection));
    await tester.pump();
    expect(written?.kind, SelectionKind.automatic);
  });

  group('the tapped row', () {
    /// A signed-out picker over the free floor. Its select call ends when
    /// [done] completes.
    OneVpnLocationPickerPage page({
      required Future<void> done,
      Stream<ServerSelection>? selection,
    }) => OneVpnLocationPickerPage(
      accountState: ValueNotifier(const OneVpnAccountSignedOut()),
      serversStream: Stream.value(_freeFloorRows()),
      selectionStream:
          selection ?? Stream.value(const ServerSelection.automatic()),
      initialSelection: const ServerSelection.automatic(),
      onSelect: (_, _, _) => done,
      onPaywall: (_) {},
      onRetry: () async {},
    );

    /// The check mark in the row titled [title].
    Finder checkOn(String title) => find.descendant(
      of: find
          .ancestor(of: find.text(title), matching: find.byType(InkWell))
          .first,
      matching: find.byIcon(LucideIcons.check),
    );

    testWidgets('reads as selected at once, before the change applies', (
      tester,
    ) async {
      final done = Completer<void>();
      await _pump(tester, page(done: done.future));
      expect(checkOn(l.onevpnAutomaticSelection), findsOneWidget);

      await tester.tap(find.text('Singapore').first);
      await tester.pump();

      expect(checkOn('Singapore'), findsOneWidget);
      expect(checkOn(l.onevpnAutomaticSelection), findsNothing);
      done.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('keeps the selection once the committed selection lands', (
      tester,
    ) async {
      final done = Completer<void>();
      final committed = StreamController<ServerSelection>();
      addTearDown(committed.close);
      await _pump(tester, page(done: done.future, selection: committed.stream));
      committed.add(const ServerSelection.automatic());
      await tester.pump();

      await tester.tap(find.text('Singapore').first);
      await tester.pump();
      committed.add(const ServerSelection.location('1vpn·free·sgp'));
      done.complete();
      await tester.pumpAndSettle();

      expect(checkOn('Singapore'), findsOneWidget);
      expect(checkOn(l.onevpnAutomaticSelection), findsNothing);
    });

    testWidgets('reverts to the committed row when the change does not '
        'apply', (tester) async {
      final done = Completer<void>();
      await _pump(tester, page(done: done.future));

      await tester.tap(find.text('Singapore').first);
      await tester.pump();
      expect(checkOn('Singapore'), findsOneWidget);
      // The select call ends and no new selection was committed. A
      // rolled-back reload and a failed save both end this way.
      done.complete();
      await tester.pumpAndSettle();

      expect(checkOn('Singapore'), findsNothing);
      expect(checkOn(l.onevpnAutomaticSelection), findsOneWidget);
    });

    testWidgets('announces the update to screen readers while it applies', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final done = Completer<void>();
      await _pump(tester, page(done: done.future));
      expect(
        tester.getSemantics(checkOn(l.onevpnAutomaticSelection)),
        isNot(isSemantics(label: l.onevpnStatusUpdating)),
      );

      await tester.tap(find.text('Singapore').first);
      await tester.pump();

      expect(
        tester.getSemantics(checkOn('Singapore')),
        isSemantics(label: l.onevpnStatusUpdating, isLiveRegion: true),
      );
      done.complete();
      await tester.pumpAndSettle();
      semantics.dispose();
    });

    testWidgets('leaves focus and hover to the theme and shows nothing when '
        'pressed', (tester) async {
      await _pump(tester, page(done: Future<void>.value()));

      expectQuietInk(tester, [
        find.text(l.onevpnAutomaticSelection),
        find.text('Singapore').first,
      ]);
    });
  });

  testWidgets('the degraded state shows a retry that runs the retry action', (
    tester,
  ) async {
    var retries = 0;
    await _pump(
      tester,
      OneVpnLocationPickerPage(
        accountState: ValueNotifier(OneVpnAccountSignedIn(_premium())),
        serversStream: Stream.value(_freeFloorRows()),
        selectionStream: Stream.value(const ServerSelection.automatic()),
        onSelect: (_, _, _) async {},
        onPaywall: (_) {},
        onRetry: () async => retries++,
      ),
    );
    expect(find.text(l.onevpnLocationsLoadFailed), findsOneWidget);
    await tester.tap(find.text(l.onevpnRetry));
    await tester.pump();
    expect(retries, 1);
    // A degraded premium is shown the free nodes and no teasers.
    expect(find.text('Amsterdam'), findsOneWidget);
    expect(find.byIcon(LucideIcons.lock), findsNothing);
  });

  testWidgets('an emptied catalogue reaches the terminal contact-support '
      'state', (tester) async {
    await _pump(
      tester,
      OneVpnLocationPickerPage(
        accountState: ValueNotifier(const OneVpnAccountSignedOut()),
        serversStream: Stream.value(const <CoreConfigData>[]),
        selectionStream: Stream.value(const ServerSelection.automatic()),
        onSelect: (_, _, _) async {},
        onPaywall: (_) {},
        onRetry: () async {},
        // The compiled floor always yields locations. The terminal state is
        // reachable only when the floor itself fails validation, so the test
        // sabotages it.
        catalogue: const OneVpnCatalogue(
          tier: OneVpnTier.free,
          entries: <OneVpnCatalogueEntry>[],
        ),
      ),
    );
    expect(find.text(l.onevpnLocationsUnavailable), findsOneWidget);
    expect(find.text(l.onevpnContactUs), findsOneWidget);
    expect(find.text('Amsterdam'), findsNothing);
  });

  testWidgets('a free location never reads temporarily unavailable', (
    tester,
  ) async {
    await _pump(
      tester,
      OneVpnLocationPickerPage(
        accountState: ValueNotifier(const OneVpnAccountSignedOut()),
        // With no provisioned rows, the free locations still read as free.
        serversStream: Stream.value(const <CoreConfigData>[]),
        selectionStream: Stream.value(const ServerSelection.automatic()),
        onSelect: (_, _, _) async {},
        onPaywall: (_) {},
        onRetry: () async {},
      ),
    );

    expect(find.text('Amsterdam'), findsOneWidget);
    expect(find.text(l.onevpnTemporarilyUnavailable), findsNothing);
    expect(find.text('Netherlands'), findsOneWidget);
  });

  testWidgets('a zero-valid-node premium location reads and selects like '
      'any other', (tester) async {
    final selected = <(ServerSelection, String)>[];
    await _pump(
      tester,
      OneVpnLocationPickerPage(
        accountState: ValueNotifier(OneVpnAccountSignedIn(_premiumWithTokyo())),
        // The free rows are provisioned and Tokyo has no row. That is the
        // server-side zero-valid-node state.
        serversStream: Stream.value(_freeFloorRows()),
        selectionStream: Stream.value(const ServerSelection.automatic()),
        onSelect: (_, selection, label) async =>
            selected.add((selection, label)),
        onPaywall: (_) {},
        onRetry: () async {},
      ),
    );

    // Tokyo carries its country, as a working location does.
    expect(find.text('Tokyo'), findsOneWidget);
    expect(find.text('Japan'), findsOneWidget);
    expect(find.text(l.onevpnTemporarilyUnavailable), findsNothing);

    // A tap selects Tokyo. Its connect then fails with an error.
    await tester.tap(find.text('Tokyo'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(selected, hasLength(1));
    final (selection, label) = selected.single;
    expect(selection.kind, SelectionKind.location);
    expect(selection.location, '1vpn·acct·nrt');
    expect(label, 'Tokyo');
  });

  group('the layout', () {
    OneVpnLocationPickerPage page({
      ValueNotifier<OneVpnAccountState>? account,
      Future<void> Function(BuildContext, ServerSelection, String)? onSelect,
      ServerSelection? initialSelection,
    }) => OneVpnLocationPickerPage(
      accountState: account ?? ValueNotifier(const OneVpnAccountSignedOut()),
      serversStream: Stream.value(_freeFloorRows()),
      selectionStream: initialSelection == null
          ? Stream.value(const ServerSelection.automatic())
          : const Stream.empty(),
      initialSelection: initialSelection,
      onSelect: onSelect ?? (_, _, _) async {},
      onPaywall: (_) {},
      onRetry: () async {},
    );

    /// The tile that carries [title].
    Rect tile(WidgetTester tester, String title) => tester.getRect(
      find.ancestor(of: find.text(title), matching: find.byType(InkWell)).first,
    );

    /// The rows every layout shows. [teasers] also expects the Upgrade
    /// header and a lock, which a short split window scrolls to.
    void expectRows({bool teasers = true}) {
      expect(find.text(l.onevpnAutomaticSelection), findsOneWidget);
      expect(find.text(l.onevpnAutomaticSubtitle), findsOneWidget);
      expect(find.text('Amsterdam'), findsOneWidget);
      expect(find.text('Los Angeles'), findsOneWidget);
      if (!teasers) return;
      expect(find.text(l.onevpnUpgrade), findsOneWidget);
      expect(find.byIcon(LucideIcons.lock), findsWidgets);
    }

    testWidgets('at 360x800 the rows form one column', (tester) async {
      await _pump(tester, page());

      expect(tester.takeException(), isNull);
      expect(find.byKey(OneVpnConstrainedBody.stackedKey), findsOneWidget);
      expect(find.byKey(OneVpnLocationPickerPage.gridKey), findsNothing);
      expectRows();
      final automatic = tile(tester, l.onevpnAutomaticSelection);
      final amsterdam = tile(tester, 'Amsterdam');
      expect(amsterdam.left, automatic.left);
      expect(amsterdam.width, automatic.width);
      expect(amsterdam.top, greaterThan(automatic.bottom));
    });

    testWidgets('a wide stacked window caps the column at 560dp', (
      tester,
    ) async {
      await _pump(tester, page(), size: const Size(768, 1024));

      expect(find.byKey(OneVpnConstrainedBody.stackedKey), findsOneWidget);
      final automatic = tile(tester, l.onevpnAutomaticSelection);
      // The tiles inset the card margin each side inside the 560dp column.
      expect(automatic.width, OneVpnLayout.listCap - 2 * OneVpnCard.margin);
      expect(automatic.center.dx, 768 / 2);
    });

    testWidgets('at 800x360 the tiles flow into two columns', (tester) async {
      await _pump(tester, page(), size: kLandscapeViewport);

      expect(tester.takeException(), isNull);
      expect(find.byKey(OneVpnLocationPickerPage.gridKey), findsOneWidget);
      expect(find.byKey(OneVpnConstrainedBody.stackedKey), findsNothing);
      expectRows(teasers: false);
      // Reading order: Automatic, then the Free header across both columns,
      // then Amsterdam | Singapore, Los Angeles.
      final automatic = tile(tester, l.onevpnAutomaticSelection);
      final free = tester.getRect(find.text(l.onevpnFree));
      final amsterdam = tile(tester, 'Amsterdam');
      final singapore = tile(tester, 'Singapore');
      final losAngeles = tile(tester, 'Los Angeles');
      expect(free.top, greaterThan(automatic.bottom));
      expect(amsterdam.top, greaterThan(free.bottom));
      expect(singapore.top, amsterdam.top);
      expect(singapore.height, amsterdam.height);
      // The gutter sits inside card-margin edge insets.
      expect(automatic.left, OneVpnCard.margin);
      expect(amsterdam.left, automatic.left);
      expect(
        singapore.left - amsterdam.right,
        OneVpnLocationPickerPage.gridGutter,
      );
      expect(singapore.right, kLandscapeViewport.width - OneVpnCard.margin);
      expect(singapore.width, automatic.width);
      expect(losAngeles.top, greaterThan(amsterdam.bottom));
      expect(losAngeles.left, amsterdam.left);
      // The Upgrade header spans both columns: the first teaser starts a
      // fresh row below it, in the first column.
      await tester.scrollUntilVisible(
        find.text(l.onevpnUpgrade),
        80,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(LucideIcons.lock), findsWidgets);
      final header = tester.getRect(find.text(l.onevpnUpgrade));
      final teaser = tester.getRect(
        find
            .ancestor(
              of: find.byIcon(LucideIcons.lock).first,
              matching: find.byType(InkWell),
            )
            .first,
      );
      expect(teaser.top, greaterThan(header.bottom));
      expect(teaser.left, automatic.left);
    });

    testWidgets('a wide split window caps the grid and centers it', (
      tester,
    ) async {
      const size = Size(1366, 1024);
      await _pump(tester, page(), size: size);

      expect(tester.takeException(), isNull);
      expect(find.byKey(OneVpnLocationPickerPage.gridKey), findsOneWidget);
      final automatic = tile(tester, l.onevpnAutomaticSelection);
      final amsterdam = tile(tester, 'Amsterdam');
      final singapore = tile(tester, 'Singapore');
      const inset = (1366 - OneVpnLocationPickerPage.gridCap) / 2;
      expect(automatic.left, inset + OneVpnCard.margin);
      expect(amsterdam.left, automatic.left);
      expect(singapore.right, size.width - inset - OneVpnCard.margin);
      expect(
        singapore.left - amsterdam.right,
        OneVpnLocationPickerPage.gridGutter,
      );
      expect(automatic.width, OneVpnLayout.paneCap);
    });

    testWidgets('at 1024x768 the grid starts at the top', (tester) async {
      await _pump(tester, page(), size: kTabletLandscapeViewport);

      expect(find.byKey(OneVpnLocationPickerPage.gridKey), findsOneWidget);
      final grid = tester.getRect(find.byKey(OneVpnLocationPickerPage.gridKey));
      // The list's 16dp top inset and the tile's 6dp inset.
      expect(tile(tester, l.onevpnAutomaticSelection).top, grid.top + 22);
    });

    testWidgets('in the grid, the degraded banner spans both columns', (
      tester,
    ) async {
      var retries = 0;
      await _pump(
        tester,
        OneVpnLocationPickerPage(
          accountState: ValueNotifier(OneVpnAccountSignedIn(_premium())),
          serversStream: Stream.value(_freeFloorRows()),
          selectionStream: Stream.value(const ServerSelection.automatic()),
          onSelect: (_, _, _) async {},
          onPaywall: (_) {},
          onRetry: () async => retries++,
        ),
        size: kLandscapeViewport,
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(OneVpnLocationPickerPage.gridKey), findsOneWidget);
      final automatic = tile(tester, l.onevpnAutomaticSelection);
      final retry = tester.getRect(find.text(l.onevpnRetry));
      expect(retry.left, greaterThan(automatic.right));
      expect(retry.top, greaterThan(automatic.bottom));
      await tester.tap(find.text(l.onevpnRetry));
      await tester.pump();
      expect(retries, 1);
    });

    testWidgets('in the grid, a tap writes the selection and the seed shows '
        'selected', (tester) async {
      ServerSelection? written;
      await _pump(
        tester,
        page(
          initialSelection: const ServerSelection.location('1vpn·free·sgp'),
          onSelect: (_, selection, _) async => written = selection,
        ),
        size: kLandscapeViewport,
      );

      Finder checkIn(String title) => find.descendant(
        of: find
            .ancestor(of: find.text(title), matching: find.byType(InkWell))
            .first,
        matching: find.byIcon(LucideIcons.check),
      );
      expect(checkIn('Singapore'), findsOneWidget);
      expect(find.byIcon(LucideIcons.check), findsOneWidget);

      await tester.tap(find.text('Amsterdam'));
      await tester.pump();
      expect(written?.kind, SelectionKind.location);
      expect(written?.location, '1vpn·free·ams');
    });

    testWidgets('a selection made in the grid reaches the split connect '
        'row', (tester) async {
      // Synchronous stream close: the connect screen's watch queries leave
      // no timer behind when the tree unmounts.
      final db = AppDatabase.forTesting(
        DatabaseConnection(
          NativeDatabase.memory(),
          closeStreamsSynchronously: true,
        ),
      );
      addTearDown(db.close);
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      stubInvokeChannel();
      stubHeldTunnelChannel();
      await setViewport(tester, kLandscapeViewport);

      final coordinator = ConnectionCoordinator(
        database: db,
        inspect: (_) async => const HostConnection(VpnStatus.disconnected),
        readRuntime: () async => null,
        statusEvents: const Stream.empty(),
        observeStatus: () async {},
        disposeStatus: () {},
      );
      addTearDown(coordinator.dispose);
      await coordinator.initialize(observe: false);

      final router = GoRouter(
        initialLocation: kOneVpnConnectRoute,
        routes: [
          GoRoute(
            path: kOneVpnConnectRoute,
            builder: (_, _) => OneVpnConnectScreen(
              coordinator: coordinator,
              database: db,
              paywallTrigger: OneVpnPaywallTrigger(
                cadence: OneVpnPaywallCadence(now: DateTime.now),
                audience: _EntitledAudience(),
              ),
            ),
          ),
          // The production picker route's seed, with the test coordinator
          // and the free-floor rows. The default tap commits and pops.
          GoRoute(
            path: kOneVpnLocationRoute,
            builder: (_, state) => OneVpnLocationPickerPage(
              accountState: ValueNotifier(const OneVpnAccountSignedOut()),
              serversStream: Stream.value(_freeFloorRows()),
              selectionStream: const Stream.empty(),
              initialSelection: state.extra is ServerSelection
                  ? state.extra! as ServerSelection
                  : null,
              coordinator: coordinator,
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
          builder: (context, child) => ShadTheme(
            data: AppTheme.shad(Brightness.light),
            child: ShadToaster(child: child!),
          ),
          routerConfig: router,
        ),
      );
      Future<void> settle() async {
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 250));
        }
      }

      await settle();
      expect(find.byKey(OneVpnAdaptiveBody.splitKey), findsOneWidget);
      expect(find.text('Amsterdam'), findsNothing);

      await tester.tap(find.byIcon(LucideIcons.zap));
      await settle();
      expect(find.byKey(OneVpnLocationPickerPage.gridKey), findsOneWidget);

      await tester.tap(find.text('Amsterdam'));
      await settle();

      expect(tester.takeException(), isNull);
      expect(find.byType(OneVpnLocationPickerPage), findsNothing);
      expect(find.byKey(OneVpnAdaptiveBody.splitKey), findsOneWidget);
      // The connect row reads the committed selection back.
      expect(
        find.descendant(
          of: find.byKey(OneVpnAdaptiveBody.endPaneKey),
          matching: find.text('Amsterdam'),
        ),
        findsOneWidget,
      );
      final stored = await coordinator.configuration;
      expect(stored.connection.selection.location, '1vpn·free·ams');
    });
  });

  testWidgets('the selected row past the fold is in view on open and after '
      'each layout change', (tester) async {
    await _pump(
      tester,
      _cityPicker(selection: const ServerSelection.location('1vpn·acct·c20')),
    );
    final selected = find.text('City c20').hitTestable();

    expect(find.byKey(OneVpnConstrainedBody.stackedKey), findsOneWidget);
    expect(selected, findsOneWidget);

    await setViewport(tester, kLandscapeViewport);
    await tester.pumpAndSettle();
    expect(find.byKey(OneVpnLocationPickerPage.gridKey), findsOneWidget);
    expect(selected, findsOneWidget);

    await setViewport(tester, kPortraitViewport);
    await tester.pumpAndSettle();
    expect(find.byKey(OneVpnConstrainedBody.stackedKey), findsOneWidget);
    expect(selected, findsOneWidget);
  });

  testWidgets('a selected row already in view opens the list at the top', (
    tester,
  ) async {
    await _pump(
      tester,
      _cityPicker(selection: const ServerSelection.location('1vpn·acct·c04')),
      size: kLandscapeViewport,
    );

    // City c04 sits whole in view, below the list's middle.
    expect(find.byKey(OneVpnLocationPickerPage.gridKey), findsOneWidget);
    expect(find.text('City c04').hitTestable(), findsOneWidget);
    final position = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    expect(position.pixels, 0);
  });

  testWidgets('a tap scrolls nothing when the committed selection marks no '
      'row', (tester) async {
    // The change stays in flight, so the tapped row reads as selected.
    final applied = Completer<void>();
    addTearDown(applied.complete);
    await _pump(
      tester,
      _cityPicker(
        selection: const ServerSelection.location('1vpn·acct·gone'),
        onSelect: (_, _, _) => applied.future,
      ),
    );
    final position = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    position.jumpTo(450);
    await tester.pumpAndSettle();

    await tester.tap(find.text('City c12'));
    await tester.pumpAndSettle();

    expect(position.pixels, 450);
  });

  testWidgets('focus stays on the row a key press selects', (tester) async {
    // The change stays in flight, so the tapped row reads as selected.
    final applied = Completer<void>();
    addTearDown(applied.complete);
    final selected = <ServerSelection>[];
    await _pump(
      tester,
      _cityPicker(
        selection: const ServerSelection.automatic(),
        onSelect: (_, selection, _) {
          selected.add(selection);
          return applied.future;
        },
      ),
    );
    FocusNode rowFocus() => Focus.of(tester.element(find.text('City c02')));
    rowFocus().requestFocus();
    await tester.pumpAndSettle();
    expect(rowFocus().hasPrimaryFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(selected.map((s) => s.location), ['1vpn·acct·c02']);
    expect(rowFocus().hasPrimaryFocus, isTrue);
  });
}
