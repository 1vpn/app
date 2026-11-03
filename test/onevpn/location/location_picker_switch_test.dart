// The free location switch on the picker, at 360x800.
//
// A free account's connected tap on another location applies nothing and
// pops the page with the pick. The pick reads as selected while the page
// leaves. A signed-in free account switches as a signed-out one, and
// Automatic counts as a pick. A back-out pops no pick. A tap on the committed
// row, an exempt account's tap, and a free tap while the connect control
// reads anything but connected take the change path. Where no in-place
// reload runs, an exempt connected tap marks its row at once and reconnects
// with no dialog.

import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/core/db/database/database.dart';
import 'package:onexray/core/pigeon/messages.g.dart';
import 'package:onexray/l10n/localizations/app_localizations.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/account/session.dart';
import 'package:onexray/onevpn/app/held_tunnel.dart';
import 'package:onexray/onevpn/handover/reload_policy.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations_en.dart';
import 'package:onexray/onevpn/location/location_picker_page.dart';
import 'package:onexray/onevpn/model/user_data.dart';
import 'package:onexray/pages/theme/theme.dart';
import 'package:onexray/service/connect/coordinator.dart';
import 'package:onexray/service/connect/runtime.dart';
import 'package:onexray/service/connect/runtime_host.dart';
import 'package:onexray/service/connect/settings.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/localizations.dart';
import '../support/viewports.dart';

const _ams = '1vpn·free·ams';
const _sgp = '1vpn·free·sgp';

/// A coordinator over [db] whose host reads disconnected. It records each
/// apply. A set [applyGate] holds each apply until it completes.
class _RecordingCoordinator extends ConnectionCoordinator {
  _RecordingCoordinator(AppDatabase db)
    : super(
        database: db,
        inspect: (_) async => const HostConnection(VpnStatus.disconnected),
        readRuntime: () async => null,
        statusEvents: const Stream.empty(),
        observeStatus: () async {},
        disposeStatus: () {},
      );

  final applies = <bool>[];
  Completer<void>? applyGate;

  @override
  Future<void> apply(
    ConnectionConfiguration next, {
    bool connect = false,
    bool disconnect = false,
    bool affectsRuntime = true,
    bool allowReconnect = true,
    String? expectedConfiguration,
    Future<void> Function()? writeAssets,
    Future<void> Function()? validateAssets,
    PrepareConnection? prepare,
  }) async {
    applies.add(allowReconnect);
    await applyGate?.future;
    return super.apply(
      next,
      connect: connect,
      disconnect: disconnect,
      affectsRuntime: affectsRuntime,
      allowReconnect: allowReconnect,
      expectedConfiguration: expectedConfiguration,
      writeAssets: writeAssets,
      validateAssets: validateAssets,
      prepare: prepare,
    );
  }
}

/// A policy that records each in-place reload and answers applied.
class _RecordingReloadPolicy extends OneVpnReloadPolicy {
  _RecordingReloadPolicy() : super(supported: true);

  int reloads = 0;

  @override
  Future<OneVpnReloadResult> applyInPlace(
    ConnectionCoordinator coordinator,
    ConnectionConfiguration next, {
    required String expectedConfiguration,
    OneVpnReloadPrepare? prepare,
  }) async {
    reloads++;
    return (outcome: OneVpnReloadOutcome.applied, notice: null);
  }
}

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

OneVpnSession _session({bool premium = false, DateTime? pendingSince}) =>
    OneVpnSession(
      sessionAuthToken: 'token',
      username: 'someone',
      email: 'someone@example.invalid',
      isPremium: premium,
      credentials: const OneVpnCredentials(
        uuid: '',
        publicKey: '',
        shortId: '',
      ),
      locations: const [],
      premiumPendingSince: pendingSince,
    );

void main() {
  final l = OneVpnLocalizationsEn();
  late AppDatabase db;
  late _RecordingCoordinator coordinator;
  late _RecordingReloadPolicy policy;
  late OneVpnHeldTunnel held;
  late ValueNotifier<bool> measuring;
  late ValueNotifier<bool> allDead;

  /// Whether the page popped, and the pick it popped with.
  late bool popped;
  ServerSelection? result;

  /// Sets up a coordinator connected on Amsterdam.
  Future<void> setUpConnected(WidgetTester tester) async {
    db = AppDatabase.forTesting(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    addTearDown(db.close);
    coordinator = _RecordingCoordinator(db);
    addTearDown(coordinator.dispose);
    await coordinator.initialize(observe: false);
    final base = ConnectionConfiguration.fromJson({});
    await db.connectionConfigDao.commit(
      configurationJson: jsonEncode({
        ...base.toJson(),
        'connection': {
          ...base.connection.toJson(),
          'selection': const ServerSelection.location(_ams).toJson(),
          'expert': false,
        },
      }),
    );
    coordinator.state.value = const ConnectionView(
      phase: ConnectionPhase.connected,
    );
    policy = _RecordingReloadPolicy();
    addTearDown(policy.state.dispose);
    held = OneVpnHeldTunnel(read: () async => false, supported: true);
    addTearDown(held.dispose);
    measuring = ValueNotifier(false);
    addTearDown(measuring.dispose);
    allDead = ValueNotifier(false);
    addTearDown(allDead.dispose);
    popped = false;
    result = null;
  }

  /// Opens the picker over a host screen for [account], committed on
  /// Amsterdam. The host records the pop.
  Future<void> open(
    WidgetTester tester,
    OneVpnAccountState account, {
    OneVpnReloadPolicy? reloadPolicy,
  }) async {
    final page = OneVpnLocationPickerPage(
      accountState: ValueNotifier(account),
      serversStream: Stream.value([
        _node('$_ams·1', 1),
        _node('$_sgp·1', 2),
        _node('1vpn·free·lax·1', 3),
      ]),
      selectionStream: const Stream.empty(),
      initialSelection: const ServerSelection.location(_ams),
      coordinator: coordinator,
      reloadPolicy: reloadPolicy ?? policy,
      heldTunnel: held,
      measuring: measuring,
      allDead: allDead,
      onPaywall: (_) {},
      onRetry: () async {},
    );
    await setViewport(tester, kPortraitViewport);
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
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await Navigator.of(context).push<ServerSelection>(
                  MaterialPageRoute(builder: (_) => page),
                );
                popped = true;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(OneVpnLocationPickerPage), findsOneWidget);
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  /// The check mark in the picker row titled [title].
  Finder checkOn(String title) => find.descendant(
    of: find
        .ancestor(of: find.text(title), matching: find.byType(InkWell))
        .first,
    matching: find.byIcon(LucideIcons.check),
  );

  for (final (name, account) in [
    ('signed-out', const OneVpnAccountSignedOut() as OneVpnAccountState),
    ('signed-in', OneVpnAccountSignedIn(_session())),
  ]) {
    testWidgets('a $name free connected tap applies nothing and pops with '
        'the pick, which reads as selected while the page leaves', (
      tester,
    ) async {
      await setUpConnected(tester);
      await open(tester, account);
      expect(checkOn('Amsterdam'), findsOneWidget);

      await tester.tap(find.text('Singapore').first);
      await tester.pump();
      expect(checkOn('Singapore'), findsOneWidget);
      expect(checkOn('Amsterdam'), findsNothing);
      await settle(tester);

      expect(popped, isTrue);
      expect(result?.toJson(), const ServerSelection.location(_sgp).toJson());
      expect(find.byType(OneVpnLocationPickerPage), findsNothing);
      expect(coordinator.applies, isEmpty);
      expect(policy.reloads, 0);
      expect(
        (await coordinator.configuration).connection.selection.toJson(),
        const ServerSelection.location(_ams).toJson(),
      );
    });
  }

  testWidgets('an Automatic tap counts as a pick', (tester) async {
    await setUpConnected(tester);
    await open(tester, const OneVpnAccountSignedOut());

    await tester.tap(find.text(l.onevpnAutomaticSelection));
    await settle(tester);

    expect(result?.toJson(), const ServerSelection.automatic().toJson());
    expect(coordinator.applies, isEmpty);
    expect(policy.reloads, 0);
  });

  testWidgets('a back-out pops no pick and applies nothing', (tester) async {
    await setUpConnected(tester);
    await open(tester, const OneVpnAccountSignedOut());

    await tester.tap(find.byType(CloseButton));
    await settle(tester);

    expect(popped, isTrue);
    expect(result, isNull);
    expect(coordinator.applies, isEmpty);
    expect(policy.reloads, 0);
  });

  testWidgets('a tap on the committed row takes the change path', (
    tester,
  ) async {
    await setUpConnected(tester);
    await open(tester, const OneVpnAccountSignedOut());

    await tester.tap(find.text('Amsterdam').first);
    await settle(tester);

    expect(popped, isTrue);
    expect(result, isNull);
    expect(coordinator.applies, isEmpty);
    expect(policy.reloads, 0);
  });

  for (final (name, account) in [
    ('premium', OneVpnAccountSignedIn(_session(premium: true))),
    (
      'pending-premium',
      OneVpnAccountSignedIn(_session(pendingSince: DateTime.utc(2026))),
    ),
    ('restoring', const OneVpnAccountRestoring() as OneVpnAccountState),
  ]) {
    testWidgets('a $name connected tap reloads in place and pops no pick', (
      tester,
    ) async {
      await setUpConnected(tester);
      await open(tester, account);

      await tester.tap(find.text('Singapore').first);
      await settle(tester);

      expect(policy.reloads, 1);
      expect(popped, isTrue);
      expect(result, isNull);
      expect(coordinator.applies, isEmpty);
    });
  }

  for (final (name, arrange) in <(String, void Function())>[
    ('measures', () => measuring.value = true),
    ('holds', () => allDead.value = true),
    ('reads red over a held TUN', () => held.value = true),
    (
      'connects',
      () => coordinator.state.value = const ConnectionView(
        phase: ConnectionPhase.connecting,
      ),
    ),
  ]) {
    testWidgets('a free tap while the tunnel $name reloads in place', (
      tester,
    ) async {
      await setUpConnected(tester);
      arrange();
      await open(tester, const OneVpnAccountSignedOut());

      await tester.tap(find.text('Singapore').first);
      await settle(tester);

      expect(policy.reloads, 1);
      expect(result, isNull);
      expect(coordinator.applies, isEmpty);
    });
  }

  testWidgets('a free tap while disconnected commits and pops no pick', (
    tester,
  ) async {
    await setUpConnected(tester);
    coordinator.state.value = const ConnectionView(
      phase: ConnectionPhase.disconnected,
    );
    await open(tester, const OneVpnAccountSignedOut());

    await tester.tap(find.text('Singapore').first);
    await settle(tester);

    expect(coordinator.applies, [false]);
    expect(policy.reloads, 0);
    expect(popped, isTrue);
    expect(result, isNull);
    expect(
      (await coordinator.configuration).connection.selection.toJson(),
      const ServerSelection.location(_sgp).toJson(),
    );
  });

  testWidgets('where no in-place reload runs, an exempt connected tap marks '
      'its row at once and reconnects with no dialog', (tester) async {
    await setUpConnected(tester);
    final unsupported = OneVpnReloadPolicy(supported: false);
    addTearDown(unsupported.state.dispose);
    coordinator.applyGate = Completer<void>();
    await open(
      tester,
      const OneVpnAccountRestoring(),
      reloadPolicy: unsupported,
    );

    await tester.tap(find.text('Singapore').first);
    await settle(tester);

    expect(find.byType(Dialog), findsNothing);
    expect(checkOn('Singapore'), findsOneWidget);
    expect(checkOn('Amsterdam'), findsNothing);
    expect(coordinator.applies, [true]);

    coordinator.applyGate!.complete();
    await settle(tester);

    expect(popped, isTrue);
    expect(result, isNull);
    expect(
      (await coordinator.configuration).connection.selection.toJson(),
      const ServerSelection.location(_sgp).toJson(),
    );
  });
}
