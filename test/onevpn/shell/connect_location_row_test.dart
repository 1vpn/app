// The connect location row in three states: Automatic with no location, a
// connected Automatic that names a flagged city, and a location outside the
// catalogue. The row and the control above it hold one position in every
// state. The leading slot shows the bolt, the flag, or the globe. The
// second line shows Fastest available, the country, or nothing. A connect
// that falls back to Automatic names the catalogue city it started from.
// For a selection outside the catalogue, the fallback names no location.

import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/core/db/database/database.dart';
import 'package:onexray/core/pigeon/model.dart';
import 'package:onexray/l10n/localizations/app_localizations.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations_en.dart';
import 'package:onexray/onevpn/location/flag.dart';
import 'package:onexray/onevpn/paywall/paywall_cadence.dart';
import 'package:onexray/onevpn/paywall/paywall_trigger.dart';
import 'package:onexray/onevpn/shell/connect_control.dart';
import 'package:onexray/onevpn/shell/connect_screen.dart';
import 'package:onexray/onevpn/shell/first_connect_explainer.dart';
import 'package:onexray/onevpn/shell/router.dart';
import 'package:onexray/onevpn/shell/routes.dart';
import 'package:onexray/pages/theme/theme.dart';
import 'package:onexray/service/connect/coordinator.dart';
import 'package:onexray/service/connect/runtime.dart';
import 'package:onexray/service/connect/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../support/held_tunnel_stub.dart';
import '../support/invoke_channel_stub.dart';
import '../support/ink.dart';
import '../support/localizations.dart';
import '../support/viewports.dart';

/// The free Amsterdam stem. The free catalogue names it Amsterdam, in the
/// Netherlands, with the nl flag.
const _amsterdam = '1vpn·free·ams';

/// A coordinator over [database] whose connect reports [connectIssue].
class _ScriptedCoordinator extends ConnectionCoordinator {
  _ScriptedCoordinator(AppDatabase database)
    : super(
        database: database,
        statusEvents: const Stream.empty(),
        observeStatus: () async {},
        disposeStatus: () {},
      );

  String? connectIssue;

  @override
  Future<void> connect() async => state.value = ConnectionView(
    phase: ConnectionPhase.connected,
    issue: connectIssue,
  );
}

class _EntitledAudience implements OneVpnPaywallAudience {
  @override
  bool get entitled => true;

  @override
  Future<void> whenRestored() async {}
}

/// A connected runtime whose one entry is the node row [id].
ConnectionRuntime _runtimeOn(int id) => ConnectionRuntime.fromRequest(
  StartVpnRequest(
    null,
    null,
    '18003',
    jsonEncode(
      LibXrayInvokeRequest(
        method: LibXrayMethod.runXray,
        payload: RunXrayRequest('{}').toJson(),
      ).toJson(),
    ),
    metadataJson: jsonEncode({
      'version': 1,
      'startedAt': 0,
      'platform': 'android',
      'configuration': ConnectionConfiguration.fromJson({}).toJson(),
      'entries': [
        {'id': id, 'name': '$_amsterdam·1'},
      ],
      'finalExit': null,
    }),
  ),
);

/// The stored configuration with [selection].
String _configuration(ServerSelection selection) {
  final base = ConnectionConfiguration.fromJson({});
  return jsonEncode({
    ...base.toJson(),
    'connection': {
      ...base.connection.toJson(),
      'selection': selection.toJson(),
    },
  });
}

/// Resolves [future] by pumping frames. The database runs in the test's
/// fake-async zone, so its work advances only with the clock.
Future<T> _drain<T>(WidgetTester tester, Future<T> future) async {
  var done = false;
  late T value;
  future.then((result) {
    value = result;
    done = true;
  });
  for (var i = 0; i < 100 && !done; i++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
  expect(done, isTrue, reason: 'the database write never finished');
  return value;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

void main() {
  final l = OneVpnLocalizationsEn();
  late AppDatabase db;
  late _ScriptedCoordinator coordinator;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  Future<void> select(WidgetTester tester, ServerSelection selection) => _drain(
    tester,
    db.connectionConfigDao.commit(configurationJson: _configuration(selection)),
  );

  /// Mounts the connect screen over an in-memory database that holds the
  /// provisioned Amsterdam row, id 1, and [selection].
  Future<void> pump(WidgetTester tester, ServerSelection selection) async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    coordinator = _ScriptedCoordinator(db);
    addTearDown(coordinator.dispose);
    await _drain(
      tester,
      db.coreConfigDao.insertRow(
        CoreConfigCompanion.insert(
          name: '$_amsterdam·1',
          type: 'outbound',
          tags: 'vless',
          delay: 20,
          subId: 0,
          id: const Value(1),
        ),
      ),
    );
    await select(tester, selection);
    await _drain(
      tester,
      SharedPreferencesAsync().setBool(
        OneVpnFirstConnectExplainer.seenKey,
        true,
      ),
    );
    stubInvokeChannel();
    stubHeldTunnelChannel();
    await setViewport(tester, kPortraitViewport);
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
        ...OneVpnRouter.menuSurfaces(),
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
    await _settle(tester);
  }

  /// Unmounts the screen, closes the database, and runs out their timers.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpWidget(const SizedBox());
    await _drain(tester, db.close());
    await tester.pump();
  }

  Finder row() => find
      .ancestor(
        of: find.byIcon(LucideIcons.chevronRightDir),
        matching: find.byType(InkWell),
      )
      .first;

  Finder inRow(Finder finder) => find.descendant(of: row(), matching: finder);

  /// The row's second line.
  String subtitle(WidgetTester tester) =>
      tester.widgetList<Text>(inRow(find.byType(Text))).elementAt(1).data!;

  testWidgets('the row leaves focus and hover to the theme and shows nothing '
      'when pressed', (tester) async {
    await pump(tester, const ServerSelection.automatic());

    expectQuietInk(tester, [find.text(l.onevpnAutomaticSelection)]);
    await unmount(tester);
  });

  testWidgets('the row and the control hold one position in three states', (
    tester,
  ) async {
    await pump(tester, const ServerSelection.automatic());

    // Automatic with no location: the bolt and Fastest available.
    final rect = tester.getRect(row());
    final control = tester.getTopLeft(find.byType(OneVpnConnectControl));
    expect(inRow(find.byIcon(LucideIcons.zap)), findsOneWidget);
    expect(inRow(find.text(l.onevpnAutomaticSelection)), findsOneWidget);
    expect(subtitle(tester), l.onevpnAutomaticSubtitle);

    // A connected Automatic names the resolved city with its flag.
    coordinator.state.value = ConnectionView(
      phase: ConnectionPhase.connected,
      runtime: _runtimeOn(1),
    );
    await _settle(tester);
    expect(inRow(find.byType(OneVpnFlag)), findsOneWidget);
    expect(
      tester.widget<OneVpnFlag>(inRow(find.byType(OneVpnFlag))).countryCode,
      'nl',
    );
    expect(inRow(find.byIcon(LucideIcons.zap)), findsNothing);
    expect(
      inRow(find.text(l.onevpnAutomaticResolved('Amsterdam'))),
      findsOneWidget,
    );
    expect(subtitle(tester), 'Netherlands');
    expect(tester.getRect(row()), rect);
    expect(tester.getTopLeft(find.byType(OneVpnConnectControl)), control);

    // A location nothing names: the globe, "Automatic", and an empty
    // second line.
    coordinator.state.value = const ConnectionView();
    await select(tester, const ServerSelection.location('1vpn·free·zzz'));
    await _settle(tester);
    expect(inRow(find.byIcon(LucideIcons.globe)), findsOneWidget);
    expect(inRow(find.byType(OneVpnFlag)), findsNothing);
    expect(inRow(find.text(l.onevpnAutomaticSelection)), findsOneWidget);
    expect(inRow(find.text(l.onevpnTemporarilyUnavailable)), findsNothing);
    expect(subtitle(tester), isEmpty);
    expect(tester.getRect(row()), rect);
    expect(tester.getTopLeft(find.byType(OneVpnConnectControl)), control);
    await unmount(tester);
  });

  testWidgets('a fallback from a catalogue city names the city', (
    tester,
  ) async {
    await pump(tester, const ServerSelection.location(_amsterdam));
    coordinator.connectIssue = 'selectionReset';
    await tester.tap(find.byType(OneVpnConnectControl));
    await _settle(tester);
    expect(
      find.widgetWithText(SnackBar, l.onevpnSelectionReset('Amsterdam')),
      findsOneWidget,
    );
    await unmount(tester);
  });

  testWidgets('a fallback from a location outside the catalogue names no '
      'location', (tester) async {
    await pump(tester, const ServerSelection.location('1vpn·free·zzz'));
    coordinator.connectIssue = 'selectionReset';
    await tester.tap(find.byType(OneVpnConnectControl));
    await _settle(tester);
    expect(
      find.widgetWithText(SnackBar, l.onevpnSelectionResetUnnamed),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.textContaining(l.onevpnTemporarilyUnavailable),
      ),
      findsNothing,
    );
    await unmount(tester);
  });
}
