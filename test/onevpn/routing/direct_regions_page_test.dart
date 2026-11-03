// Tests the Direct-regions picker.
//
// The headline card sits at the top. It has no title, leads with the info
// glyph, and carries the real-IP disclosure. Its body starts at the x of the
// region names. The page has no Hint subheading, search field, or
// installed-only note. The first row is Off (Default), with its own subtext.
// CN carries the fork label "China". The rows follow the order CN, RU, IR,
// TM. Every row leads with one flag-sized slot.
//
// An applied choice keeps the page open with its row checked. A declined or
// failed apply restores the previous row. A failed apply also shows a notice.
// A change that did not apply restores the previous row and shows the
// rollback notice. A fallback to Automatic names the location picked before
// it.
//
// A fallback to Off stores allVpn: from an empty stored set, from a region
// the geodata drops after boot, and from an explicit Off pick. An unreadable
// catalogue stores nothing.
//
// Stacked, the card keeps the card margin on every side. It pins above the
// scrolling rows while it takes at most half the body. A taller card scrolls
// with the rows. At 360x800 it pins over rows that fit. At 360x700 it pins
// while the rows scroll beneath it. At 800x360 the card fills the start pane,
// and the rows start at the top of the end pane. At text scale 2.0 a region
// code scales down to one line in its square.

import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/core/db/database/database.dart';
import 'package:onexray/core/pigeon/messages.g.dart';
import 'package:onexray/l10n/localizations/app_localizations.dart';
import 'package:onexray/l10n/localizations/app_localizations_en.dart';
import 'package:onexray/onevpn/app/held_tunnel.dart';
import 'package:onexray/onevpn/handover/reload_policy.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations_en.dart';
import 'package:onexray/onevpn/routing/direct_regions_apply.dart';
import 'package:onexray/onevpn/routing/direct_regions_page.dart';
import 'package:onexray/onevpn/shell/layout.dart';
import 'package:onexray/onevpn/shell/routes.dart';
import 'package:onexray/onevpn/theme/backdrop.dart';
import 'package:onexray/onevpn/theme/card.dart';
import 'package:onexray/onevpn/theme/headline_card.dart';
import 'package:onexray/pages/theme/theme.dart';
import 'package:onexray/service/connect/coordinator.dart';
import 'package:onexray/service/connect/routing/region_catalog.dart';
import 'package:onexray/service/connect/runtime.dart';
import 'package:onexray/service/connect/runtime_host.dart';
import 'package:onexray/service/connect/settings.dart';

import '../support/ink.dart';
import '../support/localizations.dart';
import '../support/viewports.dart';

const _geoip = ['CN', 'IR', 'RU', 'TM', 'US', 'DE', 'FR', 'JP'];

const _geosite = {
  'CN': ['CN'],
  'IR': ['CATEGORY-IR'],
  'RU': ['CATEGORY-RU'],
  'TM': ['TM'],
};

/// The installed catalogue. [drop] leaves that region's overlay out.
RegionCatalog _catalog({String? drop}) => RegionCatalog.fromJson(
  {
    'geosite': {
      for (final MapEntry(:key, :value) in _geosite.entries)
        if (key != drop) key: value,
    },
    'geoip': {
      for (final code in _geoip) code: [code],
    },
  },
  geositeCodes: [
    for (final MapEntry(:key, :value) in _geosite.entries)
      if (key != drop) ...value,
  ],
  geoipCodes: _geoip,
);

// Apply service whose apply() always throws. It stands in for the coordinator
// raising ConnectionHostException on a concurrent config write or a required
// reconnect.
class _ThrowingApplyService extends OneVpnDirectRegionsApplyService {
  _ThrowingApplyService({super.coordinator});

  @override
  Future<OneVpnDirectRegionsOutcome> apply({
    required String? regionCode,
    required Future<bool> Function() confirmReconnect,
  }) async => throw const ConnectionHostException('configurationChanged');
}

// Apply service that holds a reload on [policy] until [gate] completes,
// then answers [outcome].
class _SlowApplyService extends OneVpnDirectRegionsApplyService {
  _SlowApplyService({
    required this.outcome,
    required this.gate,
    required OneVpnReloadPolicy policy,
    super.coordinator,
  }) : super(reloadPolicy: policy);

  final OneVpnDirectRegionsOutcome outcome;
  final Completer<void> gate;

  @override
  Future<OneVpnDirectRegionsOutcome> apply({
    required String? regionCode,
    required Future<bool> Function() confirmReconnect,
  }) async {
    reloadPolicy.state.value = OneVpnReloadState.reloading;
    await gate.future;
    reloadPolicy.state.value = OneVpnReloadState.connected;
    return outcome;
  }
}

// Apply service that asks [confirmReconnect] once [gate] completes and
// records the answer in [answers]. A declined reconnect answers unchanged.
class _ConfirmingApplyService extends OneVpnDirectRegionsApplyService {
  _ConfirmingApplyService({required this.gate, super.coordinator});

  final Completer<void> gate;
  final answers = <bool>[];

  @override
  Future<OneVpnDirectRegionsOutcome> apply({
    required String? regionCode,
    required Future<bool> Function() confirmReconnect,
  }) async {
    await gate.future;
    final confirmed = await confirmReconnect();
    answers.add(confirmed);
    return confirmed
        ? OneVpnDirectRegionsOutcome.applied
        : OneVpnDirectRegionsOutcome.unchanged;
  }
}

// Apply service whose apply lands a double failure: the coordinator reads
// failed over a held TUN, and apply throws.
class _RedApplyService extends OneVpnDirectRegionsApplyService {
  _RedApplyService({super.coordinator, super.held});

  @override
  Future<OneVpnDirectRegionsOutcome> apply({
    required String? regionCode,
    required Future<bool> Function() confirmReconnect,
  }) async {
    coordinator.state.value = const ConnectionView(
      phase: ConnectionPhase.failed,
      issue: 'startFailed',
    );
    throw const ConnectionHostException('startFailed');
  }
}

// Apply service that answers [outcome].
class _StubApplyService extends OneVpnDirectRegionsApplyService {
  _StubApplyService({required this.outcome, super.coordinator});

  final OneVpnDirectRegionsOutcome outcome;

  @override
  Future<OneVpnDirectRegionsOutcome> apply({
    required String? regionCode,
    required Future<bool> Function() confirmReconnect,
  }) async => outcome;
}

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
      home: page,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final l = OneVpnLocalizationsEn();
  final upstream = AppLocalizationsEn();

  testWidgets('the explainer card replaces the Hint, search, and note', (
    tester,
  ) async {
    await _pump(
      tester,
      OneVpnDirectRegionsPage(
        loadCatalog: () async => _catalog(),
        loadSelection: () async => null,
      ),
    );

    // The card renders the disclosure under the info glyph, with no title.
    final card = find.byType(OneVpnHeadlineCard);
    expect(tester.widget<OneVpnHeadlineCard>(card).title, isNull);
    expect(
      find.descendant(of: card, matching: find.byIcon(LucideIcons.info)),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: card,
        matching: find.text(l.onevpnDirectRegionsCardBody),
      ),
      findsOneWidget,
    );
    expect(l.onevpnDirectRegionsCardBody, contains('bypass the VPN'));

    // The page renders no Hint subheading, search field, or installed-only
    // note.
    expect(find.text(upstream.prototypeDirectRegionsHint), findsNothing);
    expect(find.text(upstream.prototypeInstalledRegionsOnly), findsNothing);
    expect(find.byType(TextField), findsNothing);

    // The off row reads as the default, with its own subtext.
    expect(find.text(l.onevpnDirectRegionsOff), findsOneWidget);
    expect(find.text(l.onevpnAllViaVpnSubtitle), findsOneWidget);
    expect(find.text(upstream.prototypeAllViaVpnDescription), findsNothing);
  });

  testWidgets('screen readers hear one group with the stored region '
      'selected', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(
      tester,
      OneVpnDirectRegionsPage(
        loadCatalog: () async => _catalog(),
        loadSelection: () async => 'RU',
      ),
    );

    final selected = oneVpnDirectRegionLabel(l, 'RU');
    for (final title in [
      l.onevpnDirectRegionsOff,
      l.onevpnRegionChina,
      selected,
    ]) {
      expect(
        tester.getSemantics(
          find
              .ancestor(of: find.text(title), matching: find.byType(InkWell))
              .first,
        ),
        isSemantics(
          isSelected: title == selected,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
        ),
        reason: title,
      );
    }
    semantics.dispose();
  });

  testWidgets('the rows render CN, RU, IR, TM with CN under the fork label', (
    tester,
  ) async {
    await _pump(
      tester,
      OneVpnDirectRegionsPage(
        loadCatalog: () async => _catalog(),
        loadSelection: () async => null,
      ),
    );

    // CN renders the fork label, not the shared "Mainland China".
    expect(find.text(l.onevpnRegionChina), findsOneWidget);
    expect(find.text(l.onevpnCountryRegionName('CN')), findsNothing);

    // RU, IR, TM render through the fork region-name table.
    for (final code in ['RU', 'IR', 'TM']) {
      expect(find.text(oneVpnDirectRegionLabel(l, code)), findsWidgets);
    }
    // A geoip-only country never renders a row.
    expect(find.text(oneVpnDirectRegionLabel(l, 'US')), findsNothing);

    // The rendered order is exactly CN, RU, IR, TM top to bottom.
    final labels = [
      l.onevpnRegionChina,
      ...['RU', 'IR', 'TM'].map((c) => oneVpnDirectRegionLabel(l, c)),
    ];
    final centers = labels
        .map((label) => tester.getCenter(find.text(label)).dy)
        .toList();
    final sorted = [...centers]..sort();
    expect(centers, sorted, reason: 'rows are not in CN, RU, IR, TM order');
  });

  testWidgets('a failed apply reverts the optimistic selection', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final coordinator = ConnectionCoordinator(database: db);
    addTearDown(coordinator.dispose);

    await _pump(
      tester,
      OneVpnDirectRegionsPage(
        loadCatalog: () async => _catalog(),
        loadSelection: () async => null,
        applyService: _ThrowingApplyService(coordinator: coordinator),
      ),
    );

    // The check mark lives inside the selected tile's InkWell.
    Finder checkIn(String title) => find.descendant(
      of: find.ancestor(of: find.text(title), matching: find.byType(InkWell)),
      matching: find.byIcon(LucideIcons.check),
    );
    final cn = oneVpnDirectRegionLabel(l, 'CN');

    // Anti-vacuity: Off starts selected, the CN row does not.
    expect(checkIn(l.onevpnDirectRegionsOff), findsOneWidget);
    expect(checkIn(cn), findsNothing);

    await tester.tap(find.text(cn).first);
    await tester.pump();
    await tester.pump();

    // The optimistic CN selection reverts. The CN tile shows no check mark.
    expect(checkIn(cn), findsNothing);
    expect(checkIn(l.onevpnDirectRegionsOff), findsOneWidget);
    // The page shows the failure as a notice.
    expect(find.byType(SnackBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('an apply', () {
    late AppDatabase db;
    late ConnectionCoordinator coordinator;

    /// Opens the page over a stored [selection] with [service].
    Future<void> open(
      WidgetTester tester,
      OneVpnDirectRegionsApplyService Function() service, {
      ServerSelection selection = const ServerSelection.automatic(),
    }) async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      coordinator = ConnectionCoordinator(database: db);
      addTearDown(coordinator.dispose);
      final base = ConnectionConfiguration.fromJson({});
      var written = false;
      db.connectionConfigDao
          .commit(
            configurationJson: jsonEncode({
              ...base.toJson(),
              'connection': {
                ...base.connection.toJson(),
                'selection': selection.toJson(),
              },
            }),
          )
          .then((_) => written = true);
      for (var i = 0; i < 50 && !written; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(written, isTrue);
      await _pump(
        tester,
        OneVpnDirectRegionsPage(
          loadCatalog: () async => _catalog(),
          loadSelection: () async => null,
          applyService: service(),
        ),
      );
    }

    Finder checkIn(String title) => find.descendant(
      of: find.ancestor(of: find.text(title), matching: find.byType(InkWell)),
      matching: find.byIcon(LucideIcons.check),
    );

    Future<void> choose(WidgetTester tester, String title) async {
      await tester.tap(find.text(title).first);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
    }

    testWidgets('an applied choice keeps the page open with its row '
        'checked', (tester) async {
      await open(
        tester,
        () => _StubApplyService(
          outcome: OneVpnDirectRegionsOutcome.applied,
          coordinator: coordinator,
        ),
      );
      final cn = oneVpnDirectRegionLabel(l, 'CN');
      await choose(tester, cn);
      expect(find.byType(OneVpnDirectRegionsPage), findsOneWidget);
      expect(checkIn(cn), findsOneWidget);
      expect(checkIn(l.onevpnDirectRegionsOff), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('a declined choice keeps the page open with the previous '
        'row checked', (tester) async {
      await open(
        tester,
        () => _StubApplyService(
          outcome: OneVpnDirectRegionsOutcome.unchanged,
          coordinator: coordinator,
        ),
      );
      final cn = oneVpnDirectRegionLabel(l, 'CN');
      await choose(tester, cn);
      expect(find.byType(OneVpnDirectRegionsPage), findsOneWidget);
      expect(checkIn(cn), findsNothing);
      expect(checkIn(l.onevpnDirectRegionsOff), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('a fallback to Automatic names the location picked before '
        'it', (tester) async {
      await open(
        tester,
        () => _StubApplyService(
          outcome: OneVpnDirectRegionsOutcome.selectionReset,
          coordinator: coordinator,
        ),
        selection: const ServerSelection.location('1vpn·free·ams'),
      );
      final cn = oneVpnDirectRegionLabel(l, 'CN');
      await choose(tester, cn);
      expect(find.byType(OneVpnDirectRegionsPage), findsOneWidget);
      expect(checkIn(cn), findsOneWidget);
      expect(
        find.widgetWithText(SnackBar, l.onevpnSelectionReset('Amsterdam')),
        findsOneWidget,
      );
    });
  });

  group('a fallback to Off', () {
    late AppDatabase db;
    late ConnectionCoordinator coordinator;

    /// Pumps until [future] completes, and returns its value.
    Future<T> settle<T>(WidgetTester tester, Future<T> future) async {
      T? value;
      Object? error;
      var done = false;
      future.then(
        (result) {
          value = result;
          done = true;
        },
        onError: (Object failure) {
          error = failure;
          done = true;
        },
      );
      for (var i = 0; i < 100 && !done; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(done, isTrue);
      if (error != null) throw error!;
      return value as T;
    }

    /// Stores [regions] under [mode] in a fresh in-memory store.
    Future<void> boot(
      WidgetTester tester,
      TrafficMode mode,
      List<String> regions,
    ) async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      coordinator = ConnectionCoordinator(
        database: db,
        inspect: (_) async => const HostConnection(VpnStatus.disconnected),
        readRuntime: () async => null,
      );
      addTearDown(coordinator.dispose);
      await settle(tester, coordinator.initialize(observe: false));
      await settle(
        tester,
        db.connectionConfigDao.commit(
          configurationJson: ConnectionConfiguration(
            connection: ConnectionSettings(
              trafficMode: mode,
              smart: SmartRoutingSettings(directRegions: regions),
            ),
          ).encode(),
        ),
      );
    }

    /// Opens a fresh page over the store with the real apply service.
    Future<void> open(
      WidgetTester tester,
      Future<RegionCatalog> Function() loadCatalog,
    ) => _pump(
      tester,
      OneVpnDirectRegionsPage(
        key: UniqueKey(),
        loadCatalog: loadCatalog,
        applyService: OneVpnDirectRegionsApplyService(
          coordinator: coordinator,
          held: OneVpnHeldTunnel(read: () async => false, supported: true),
        ),
      ),
    );

    Future<ConnectionSettings> stored(WidgetTester tester) async =>
        (await settle(tester, coordinator.configuration)).connection;

    Finder checkIn(String title) => find.descendant(
      of: find.ancestor(of: find.text(title), matching: find.byType(InkWell)),
      matching: find.byIcon(LucideIcons.check),
    );

    testWidgets('an empty stored set checks Off and stores allVpn', (
      tester,
    ) async {
      await boot(tester, TrafficMode.smart, const []);

      await open(tester, () async => _catalog());

      expect(checkIn(l.onevpnDirectRegionsOff), findsOneWidget);
      final settings = await stored(tester);
      expect(settings.trafficMode, TrafficMode.allVpn);
      expect(settings.smart.directRegions, isEmpty);
    });

    testWidgets('a region the geodata drops after boot falls back to Off and '
        'stores allVpn', (tester) async {
      await boot(tester, TrafficMode.smart, const ['TM']);
      final tm = oneVpnDirectRegionLabel(l, 'TM');

      // At boot the geodata carries TM, so the row stands.
      await open(tester, () async => _catalog());
      expect(checkIn(tm), findsOneWidget);
      expect((await stored(tester)).trafficMode, TrafficMode.smart);

      // A later geodata update drops TM.
      await open(tester, () async => _catalog(drop: 'TM'));
      expect(find.text(tm), findsNothing);
      expect(checkIn(l.onevpnDirectRegionsOff), findsOneWidget);
      final settings = await stored(tester);
      expect(settings.trafficMode, TrafficMode.allVpn);
      expect(settings.smart.directRegions, isEmpty);
    });

    testWidgets('an unreadable catalogue stores nothing', (tester) async {
      await boot(tester, TrafficMode.smart, const ['TM']);

      await open(tester, () async => throw StateError('unreadable geodata'));

      final settings = await stored(tester);
      expect(settings.trafficMode, TrafficMode.smart);
      expect(settings.smart.directRegions, ['TM']);
    });

    testWidgets('an explicit Off pick stores allVpn', (tester) async {
      await boot(tester, TrafficMode.smart, const ['CN']);
      final cn = oneVpnDirectRegionLabel(l, 'CN');
      await open(tester, () async => _catalog());
      expect(checkIn(cn), findsOneWidget);
      expect((await stored(tester)).trafficMode, TrafficMode.smart);

      await tester.tap(find.text(l.onevpnDirectRegionsOff));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }

      expect(checkIn(l.onevpnDirectRegionsOff), findsOneWidget);
      expect(checkIn(cn), findsNothing);
      final settings = await stored(tester);
      expect(settings.trafficMode, TrafficMode.allVpn);
      expect(settings.smart.directRegions, isEmpty);
    });
  });

  group('a change that did not apply', () {
    for (final size in [kPortraitViewport, kLandscapeViewport]) {
      testWidgets('restores the previous row and shows the rollback notice '
          'at ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        final coordinator = ConnectionCoordinator(database: db);
        addTearDown(coordinator.dispose);
        await _pump(
          tester,
          OneVpnDirectRegionsPage(
            loadCatalog: () async => _catalog(),
            loadSelection: () async => null,
            applyService: _StubApplyService(
              outcome: OneVpnDirectRegionsOutcome.rolledBack,
              coordinator: coordinator,
            ),
          ),
          size: size,
        );
        final cn = oneVpnDirectRegionLabel(l, 'CN');
        Finder checkIn(String title) => find.descendant(
          of: find.ancestor(
            of: find.text(title),
            matching: find.byType(InkWell),
          ),
          matching: find.byIcon(LucideIcons.check),
        );

        await tester.tap(find.text(cn).first);
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 10));
        }

        expect(checkIn(cn), findsNothing);
        expect(checkIn(l.onevpnDirectRegionsOff), findsOneWidget);
        expect(
          find.widgetWithText(SnackBar, l.onevpnReloadRolledBackSettings),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('a reload', () {
    late AppDatabase db;
    late ConnectionCoordinator coordinator;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      coordinator = ConnectionCoordinator(database: db);
      addTearDown(coordinator.dispose);
    });

    Finder checkIn(String title) => find.descendant(
      of: find.ancestor(of: find.text(title), matching: find.byType(InkWell)),
      matching: find.byIcon(LucideIcons.check),
    );

    /// Mounts the page over a placeholder connect screen, pushed on top of
    /// it, at [size].
    Future<void> mount(
      WidgetTester tester,
      OneVpnDirectRegionsApplyService service,
      Size size,
    ) async {
      await setViewport(tester, size);
      final router = GoRouter(
        initialLocation: kOneVpnDirectRegionsRoute,
        routes: [
          GoRoute(
            path: kOneVpnConnectRoute,
            builder: (_, _) => const Scaffold(body: Text('connect screen')),
            routes: [
              GoRoute(
                path: kOneVpnDirectRegionsRoute.substring(1),
                builder: (_, _) => OneVpnDirectRegionsPage(
                  loadCatalog: () async => _catalog(),
                  loadSelection: () async => null,
                  applyService: service,
                ),
              ),
            ],
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
    }

    for (final size in [kPortraitViewport, kLandscapeViewport]) {
      final at = '${size.width.toInt()}x${size.height.toInt()}';

      testWidgets('at $at a double failure returns to the connect screen '
          'with no notice', (tester) async {
        final held = OneVpnHeldTunnel(read: () async => true, supported: true);
        addTearDown(held.dispose);
        await mount(
          tester,
          _RedApplyService(coordinator: coordinator, held: held),
          size,
        );

        await tester.tap(find.text(oneVpnDirectRegionLabel(l, 'CN')).first);
        await tester.pumpAndSettle();

        expect(find.byType(OneVpnDirectRegionsPage), findsNothing);
        expect(find.text('connect screen'), findsOneWidget);
        expect(find.byType(SnackBar), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('at $at the tapped row shows no spinner while a reload '
          'holds', (tester) async {
        final policy = OneVpnReloadPolicy(supported: true);
        addTearDown(policy.state.dispose);
        final gate = Completer<void>();
        await mount(
          tester,
          _SlowApplyService(
            outcome: OneVpnDirectRegionsOutcome.applied,
            gate: gate,
            policy: policy,
            coordinator: coordinator,
          ),
          size,
        );
        final cn = oneVpnDirectRegionLabel(l, 'CN');
        final progress = find.byType(CircularProgressIndicator);

        await tester.tap(find.text(cn).first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
        expect(progress, findsNothing);
        await tester.pump(const Duration(milliseconds: 60));
        expect(progress, findsNothing);

        gate.complete();
        await tester.pumpAndSettle();
        expect(progress, findsNothing);
        expect(checkIn(cn), findsOneWidget);
      });

      testWidgets('at $at the applying row announces the update to screen '
          'readers', (tester) async {
        final semantics = tester.ensureSemantics();
        final policy = OneVpnReloadPolicy(supported: true);
        addTearDown(policy.state.dispose);
        final gate = Completer<void>();
        await mount(
          tester,
          _SlowApplyService(
            outcome: OneVpnDirectRegionsOutcome.applied,
            gate: gate,
            policy: policy,
            coordinator: coordinator,
          ),
          size,
        );
        final cn = oneVpnDirectRegionLabel(l, 'CN');

        await tester.tap(find.text(cn).first);
        await tester.pump();

        expect(
          tester.getSemantics(checkIn(cn)),
          isSemantics(label: l.onevpnStatusUpdating, isLiveRegion: true),
        );

        gate.complete();
        await tester.pumpAndSettle();

        expect(
          tester.getSemantics(checkIn(cn)),
          isNot(isSemantics(label: l.onevpnStatusUpdating)),
        );
        semantics.dispose();
      });

      testWidgets('at $at the region rows leave focus and hover to the theme '
          'and show nothing when pressed', (tester) async {
        final policy = OneVpnReloadPolicy(supported: true);
        addTearDown(policy.state.dispose);
        await mount(
          tester,
          _SlowApplyService(
            outcome: OneVpnDirectRegionsOutcome.applied,
            gate: Completer<void>(),
            policy: policy,
            coordinator: coordinator,
          ),
          size,
        );

        expectQuietInk(tester, [
          find.text(l.onevpnDirectRegionsOff),
          find.text(oneVpnDirectRegionLabel(l, 'CN')).first,
        ]);
      });

      testWidgets('at $at a reconnect asked after the page closed declines '
          'with no dialog and no notice', (tester) async {
        final gate = Completer<void>();
        final service = _ConfirmingApplyService(
          gate: gate,
          coordinator: coordinator,
        );
        await mount(tester, service, size);

        await tester.tap(find.text(oneVpnDirectRegionLabel(l, 'CN')).first);
        await tester.pump();
        await tester.tap(find.byType(CloseButton));
        await tester.pumpAndSettle();
        gate.complete();
        await tester.pumpAndSettle();

        expect(service.answers, [false]);
        expect(find.byType(Dialog), findsNothing);
        expect(find.byType(SnackBar), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('at $at the rollback notice shows after the page closed '
          'during the reload', (tester) async {
        final policy = OneVpnReloadPolicy(supported: true);
        addTearDown(policy.state.dispose);
        final gate = Completer<void>();
        await mount(
          tester,
          _SlowApplyService(
            outcome: OneVpnDirectRegionsOutcome.rolledBack,
            gate: gate,
            policy: policy,
            coordinator: coordinator,
          ),
          size,
        );

        await tester.tap(find.text(oneVpnDirectRegionLabel(l, 'CN')).first);
        await tester.pump();
        await tester.tap(find.byType(CloseButton));
        await tester.pumpAndSettle();
        expect(find.text('connect screen'), findsOneWidget);
        gate.complete();
        await tester.pumpAndSettle();

        expect(
          find.widgetWithText(SnackBar, l.onevpnReloadRolledBackSettings),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('the layout', () {
    Widget page() => OneVpnDirectRegionsPage(
      loadCatalog: () async => _catalog(),
      loadSelection: () async => null,
    );

    Finder inPane(Key pane, Finder finder) =>
        find.descendant(of: find.byKey(pane), matching: finder);

    /// The card with its margin, as the scroll view holds it.
    Rect cardBox(WidgetTester tester) => tester.getRect(
      find
          .ancestor(
            of: find.text(l.onevpnDirectRegionsCardBody),
            matching: find.byType(ColoredBox),
          )
          .first,
    );

    Rect scrollBody(WidgetTester tester) =>
        tester.getRect(find.byType(CustomScrollView));

    Future<void> scaleText(WidgetTester tester, double scale) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    }

    final rows = [
      l.onevpnDirectRegionsOff,
      l.onevpnRegionChina,
      ...['RU', 'IR', 'TM'].map((c) => oneVpnDirectRegionLabel(l, c)),
    ];

    void expectContent() {
      expect(find.text(l.onevpnDirectRegionsCardBody), findsOneWidget);
      for (final row in rows) {
        expect(find.text(row), findsWidgets, reason: row);
      }
    }

    testWidgets('at 360x800 the page stacks with no overflow', (tester) async {
      await _pump(tester, page());

      expect(tester.takeException(), isNull);
      expect(find.byKey(OneVpnConstrainedBody.stackedKey), findsOneWidget);
      expect(find.byKey(OneVpnAdaptiveBody.splitKey), findsNothing);
      expectContent();
      expect(
        tester.getRect(find.text(l.onevpnDirectRegionsCardBody)).bottom,
        lessThan(tester.getRect(find.text(l.onevpnDirectRegionsOff)).top),
      );
    });

    testWidgets('at 360x700 the card pins while the rows scroll beneath it', (
      tester,
    ) async {
      await _pump(tester, page(), size: const Size(360, 700));

      expect(tester.takeException(), isNull);
      expect(find.byKey(OneVpnConstrainedBody.stackedKey), findsOneWidget);
      // Anti-vacuity guard. The card fits the rule, and the rows overflow.
      expect(
        cardBox(tester).height,
        lessThanOrEqualTo(scrollBody(tester).height / 2),
      );
      final card = cardBox(tester);
      final row = tester.getTopLeft(find.text(l.onevpnDirectRegionsOff));
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -80));
      await tester.pumpAndSettle();
      expect(cardBox(tester), card);
      expect(
        tester.getTopLeft(find.text(l.onevpnDirectRegionsOff)).dy,
        lessThan(row.dy),
      );
      // The last row takes a tap below the pinned card.
      final last = find.text(oneVpnDirectRegionLabel(l, 'TM'));
      await tester.scrollUntilVisible(last, 40);
      await tester.ensureVisible(last);
      await tester.pumpAndSettle();
      expect(last.hitTestable(), findsOneWidget);
    });

    testWidgets('at 360x800 the card pins over rows that fit', (tester) async {
      await _pump(tester, page());

      expect(tester.takeException(), isNull);
      // The card keeps the card margin on every side.
      final inner = tester.getRect(find.byType(OneVpnHeadlineCard));
      expect(inner.left - cardBox(tester).left, OneVpnCard.margin);
      expect(cardBox(tester).right - inner.right, OneVpnCard.margin);
      expect(inner.top - cardBox(tester).top, OneVpnCard.margin);
      expect(cardBox(tester).bottom - inner.bottom, OneVpnCard.margin);
      // Anti-vacuity guard. The card fits the rule.
      expect(
        cardBox(tester).height,
        lessThanOrEqualTo(scrollBody(tester).height / 2),
      );
      final card = cardBox(tester);
      final row = tester.getTopLeft(find.text(l.onevpnDirectRegionsOff));
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -80));
      await tester.pumpAndSettle();
      // The rows fit the body, so a drag moves neither the card nor the rows.
      expect(cardBox(tester), card);
      expect(tester.getTopLeft(find.text(l.onevpnDirectRegionsOff)), row);
      // The last row takes a tap below the pinned card.
      final last = find.text(oneVpnDirectRegionLabel(l, 'TM'));
      expect(last.hitTestable(), findsOneWidget);
    });

    for (final size in const [Size(360, 480), Size(360, 560)]) {
      testWidgets('at text scale 2.0 and ${size.width.toInt()}x'
          '${size.height.toInt()} a tall card scrolls with the rows', (
        tester,
      ) async {
        await scaleText(tester, 2);
        await _pump(tester, page(), size: size);

        expect(tester.takeException(), isNull);
        expect(find.byKey(OneVpnConstrainedBody.stackedKey), findsOneWidget);
        // Anti-vacuity guard. The card takes more than half the body.
        expect(
          cardBox(tester).height,
          greaterThan(scrollBody(tester).height / 2),
        );
        final before = cardBox(tester).top;
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -120));
        await tester.pumpAndSettle();
        expect(cardBox(tester).top, lessThan(before));
        final last = find.text(oneVpnDirectRegionLabel(l, 'TM'));
        await tester.scrollUntilVisible(last, 80);
        await tester.ensureVisible(last);
        await tester.pumpAndSettle();
        expect(last.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('at text scale 2.0 each region code keeps one line inside '
        'its square', (tester) async {
      await scaleText(tester, 2);
      await _pump(tester, page());
      expect(tester.takeException(), isNull);

      for (final code in ['CN', 'RU', 'IR', 'TM']) {
        await tester.scrollUntilVisible(find.text(code), 80);
        await tester.pumpAndSettle();
        final square = tester.getRect(
          find.ancestor(
            of: find.text(code),
            matching: find.byType(OneVpnBackdropSquare),
          ),
        );
        expect(square.size, const Size.square(32), reason: code);
        final rich = tester.widget<RichText>(
          find.descendant(of: find.text(code), matching: find.byType(RichText)),
        );
        final line = TextPainter(
          text: rich.text,
          textDirection: TextDirection.ltr,
          textScaler: rich.textScaler,
        )..layout();
        final lineSize = line.size;
        line.dispose();
        // Anti-vacuity: one line of the scaled code is wider than the square.
        expect(lineSize.width, greaterThan(square.width), reason: code);
        expect(tester.getSize(find.text(code)), lineSize, reason: code);
        final drawn = tester.getRect(find.text(code));
        expect(square.expandToInclude(drawn), square, reason: code);
      }
    });

    testWidgets('a wide stacked window caps the column at 560dp', (
      tester,
    ) async {
      await _pump(tester, page(), size: const Size(768, 1024));

      expect(find.byKey(OneVpnConstrainedBody.stackedKey), findsOneWidget);
      final row = tester.getRect(
        find
            .ancestor(
              of: find.text(l.onevpnDirectRegionsOff),
              matching: find.byType(InkWell),
            )
            .first,
      );
      // The rows inset the card margin each side inside the 560dp column.
      expect(row.width, OneVpnLayout.listCap - 2 * OneVpnCard.margin);
      expect(row.center.dx, 768 / 2);
    });

    for (final size in [kPortraitViewport, kLandscapeViewport]) {
      testWidgets('at ${size.width.toInt()}x${size.height.toInt()} every row '
          'leads with a flag-sized slot and the names start at one x', (
        tester,
      ) async {
        await _pump(tester, page(), size: size);
        expect(tester.takeException(), isNull);

        final names = [
          l.onevpnDirectRegionsOff,
          l.onevpnRegionChina,
          ...['RU', 'IR', 'TM'].map((c) => oneVpnDirectRegionLabel(l, c)),
        ];
        final x = tester.getTopLeft(find.text(names.first)).dx;
        for (final name in names) {
          expect(tester.getTopLeft(find.text(name)).dx, x, reason: name);
        }
        for (final code in ['CN', 'RU', 'IR', 'TM']) {
          final square = find.ancestor(
            of: find.text(code),
            matching: find.byType(OneVpnBackdropSquare),
          );
          expect(tester.getSize(square), const Size.square(32), reason: code);
        }
        // The card body starts at the region names' x.
        if (size == kPortraitViewport) {
          expect(
            tester.getTopLeft(find.text(l.onevpnDirectRegionsCardBody)).dx,
            x,
          );
        }
      });
    }

    testWidgets('at 800x360 the card fills the start pane and the rows the '
        'end pane', (tester) async {
      await _pump(tester, page(), size: kLandscapeViewport);

      expect(tester.takeException(), isNull);
      expect(find.byKey(OneVpnAdaptiveBody.splitKey), findsOneWidget);
      expect(find.byKey(OneVpnConstrainedBody.stackedKey), findsNothing);
      expectContent();
      const start = OneVpnAdaptiveBody.startPaneKey;
      const end = OneVpnAdaptiveBody.endPaneKey;
      expect(
        inPane(start, find.text(l.onevpnDirectRegionsCardBody)),
        findsOneWidget,
      );
      for (final row in rows) {
        expect(inPane(end, find.text(row)), findsWidgets, reason: row);
      }
      final centers = rows
          .map((row) => tester.getCenter(find.text(row).first).dy)
          .toList();
      expect(centers, [...centers]..sort());
    });

    testWidgets('at 1024x768 the rows start at the top of the end pane and '
        'the card centers in the start pane', (tester) async {
      await _pump(tester, page(), size: kTabletLandscapeViewport);

      expect(tester.takeException(), isNull);
      expect(find.byKey(OneVpnAdaptiveBody.splitKey), findsOneWidget);
      final end = tester.getRect(find.byKey(OneVpnAdaptiveBody.endPaneKey));
      final first = tester.getRect(
        find
            .ancestor(
              of: find.text(l.onevpnDirectRegionsOff),
              matching: find.byType(InkWell),
            )
            .first,
      );
      // The rows sit under the end pane's card-margin top inset.
      expect(first.top, end.top + OneVpnCard.margin);
      final start = tester.getRect(find.byKey(OneVpnAdaptiveBody.startPaneKey));
      final body = tester.getRect(find.text(l.onevpnDirectRegionsCardBody));
      expect(body.top, greaterThan(start.top + 100));
      expect(body.bottom, lessThan(start.bottom - 100));
    });

    testWidgets('a rotation keeps the page mounted and splits with no '
        'overflow', (tester) async {
      await _pump(tester, page());
      final element = tester.element(find.byType(OneVpnDirectRegionsPage));

      await setViewport(tester, kLandscapeViewport);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(OneVpnAdaptiveBody.splitKey), findsOneWidget);
      expect(
        tester.element(find.byType(OneVpnDirectRegionsPage)),
        same(element),
      );
    });
  });
}
