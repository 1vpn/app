// The fork connection actions. A failure shows a notice with its message. A
// cancel by the user shows nothing. A fallback to Automatic names the
// selection it started from, or no location when that selection has no
// name. An apply returns the current configuration when nothing changes. It
// commits a disconnected change with no dialog. On a platform with no
// in-place reload, a connected change reconnects with no dialog. A change
// over a held TUN releases it first. A failure that lands in the red state
// with its detail line shows no notice. A change while the tunnel prepares
// or connects reloads in place with no dialog.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/core/db/database/database.dart';
import 'package:onexray/core/errors/failure.dart';
import 'package:onexray/core/pigeon/messages.g.dart';
import 'package:onexray/l10n/localizations/app_localizations.dart';
import 'package:onexray/l10n/localizations/app_localizations_en.dart';
import 'package:onexray/onevpn/app/held_tunnel.dart';
import 'package:onexray/onevpn/feedback/connection_actions.dart';
import 'package:onexray/onevpn/handover/reload_policy.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations_en.dart';
import 'package:onexray/pages/theme/theme.dart';
import 'package:onexray/service/connect/coordinator.dart';
import 'package:onexray/service/connect/resolver.dart';
import 'package:onexray/service/connect/runtime.dart';
import 'package:onexray/service/connect/runtime_host.dart';

import '../support/localizations.dart';

/// An in-memory coordinator over a host that reports disconnected. It
/// records each apply's reconnect permission and can report [issue] after
/// the apply.
class _RecordingCoordinator extends ConnectionCoordinator {
  _RecordingCoordinator(AppDatabase db)
    : super(
        database: db,
        readRuntime: () async => null,
        inspect: (_) async => const HostConnection(VpnStatus.disconnected),
        start: (_) async => throw StateError('the host never starts'),
      );

  final allowReconnect = <bool>[];
  String? issue;
  int disconnects = 0;

  /// Runs inside each disconnect.
  void Function()? onDisconnect;

  @override
  Future<void> disconnect() async {
    disconnects++;
    onDisconnect?.call();
  }

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
    this.allowReconnect.add(allowReconnect);
    await super.apply(
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
    final issue = this.issue;
    if (issue != null) {
      state.value = ConnectionView(phase: state.value.phase, issue: issue);
    }
  }
}

/// A reload policy that records the phase of each in-place reload and
/// answers applied.
class _RecordingReloadPolicy extends OneVpnReloadPolicy {
  _RecordingReloadPolicy(this.coordinator) : super(supported: true);

  final ConnectionCoordinator coordinator;
  final phases = <ConnectionPhase>[];

  @override
  Future<OneVpnReloadResult> applyInPlace(
    ConnectionCoordinator coordinator,
    ConnectionConfiguration next, {
    required String expectedConfiguration,
    OneVpnReloadPrepare? prepare,
  }) async {
    phases.add(coordinator.state.value.phase);
    return (outcome: OneVpnReloadOutcome.applied, notice: null);
  }
}

/// Pumps a screen and returns its context.
Future<BuildContext> _host(WidgetTester tester) async {
  late BuildContext context;
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('en'),
      localizationsDelegates: oneVpnLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (value) {
          context = value;
          return const Scaffold();
        },
      ),
    ),
  );
  return context;
}

/// Runs [action] as a connection action and resolves whether it completed.
Future<bool?> _run(WidgetTester tester, Future<void> Function() action) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final coordinator = ConnectionCoordinator(database: db);
  addTearDown(db.close);
  addTearDown(coordinator.dispose);
  final context = await _host(tester);
  bool? succeeded;
  oneVpnRunConnectionAction(context, coordinator, () async {
    await action();
  }).then((value) => succeeded = value);
  await tester.pump();
  await tester.pump();
  return succeeded;
}

void main() {
  final l = OneVpnLocalizationsEn();
  final upstream = AppLocalizationsEn();

  testWidgets('a cancelled app failure shows nothing', (tester) async {
    final succeeded = await _run(
      tester,
      () async => throw const AppFailure(FailureCategory.runtime, 'cancelled'),
    );
    expect(succeeded, isFalse);
    expect(find.byType(SnackBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a coordinator cancel followed by a generic throw shows '
      'nothing', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final coordinator = ConnectionCoordinator(database: db);
    addTearDown(db.close);
    addTearDown(coordinator.dispose);
    final context = await _host(tester);
    bool? succeeded;
    oneVpnRunConnectionAction(context, coordinator, () async {
      coordinator.state.value = const ConnectionView(issue: 'cancelled');
      throw StateError('interrupted');
    }).then((value) => succeeded = value);
    await tester.pump();
    await tester.pump();
    expect(succeeded, isFalse);
    expect(find.byType(SnackBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a fallback with no label names no location when asked', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final coordinator = ConnectionCoordinator(database: db);
    addTearDown(db.close);
    addTearDown(coordinator.dispose);
    final context = await _host(tester);
    oneVpnRunConnectionAction(
      context,
      coordinator,
      () async => coordinator.state.value = const ConnectionView(
        phase: ConnectionPhase.connected,
        issue: 'selectionReset',
      ),
      notifyFallback: true,
    );
    await tester.pump();
    await tester.pump();
    expect(
      find.widgetWithText(SnackBar, l.onevpnSelectionResetUnnamed),
      findsOneWidget,
    );
  });

  group('an apply', () {
    late AppDatabase db;
    late _RecordingCoordinator coordinator;
    late ConnectionConfiguration before;
    const change = {'expert': true, 'rawId': 5};

    // A platform with no in-place reload: a connected change reconnects.
    final unsupported = OneVpnReloadPolicy(supported: false);

    Future<void> setUpCoordinator(WidgetTester tester) async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      coordinator = _RecordingCoordinator(db);
      addTearDown(db.close);
      addTearDown(coordinator.dispose);
      await tester.runAsync(() async {
        await coordinator.initialize(observe: false);
        before = await coordinator.configuration;
      });
    }

    /// Starts an apply of [values] and lets it run.
    Future<Future<ConnectionConfiguration?>> start(
      WidgetTester tester,
      Map<String, dynamic> values, {
      OneVpnHeldTunnel? held,
      OneVpnReloadPolicy? reloadPolicy,
    }) async {
      final context = await _host(tester);
      late Future<ConnectionConfiguration?> result;
      await tester.runAsync(() async {
        result = oneVpnApplyConnectionChange(
          context,
          coordinator,
          values,
          label: 'Amsterdam',
          held: held,
          reloadPolicy: reloadPolicy ?? unsupported,
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      return result;
    }

    Future<T> settle<T>(WidgetTester tester, Future<T> result) async {
      late T value;
      await tester.runAsync(() async => value = await result);
      await tester.pumpAndSettle();
      return value;
    }

    Future<String> stored(WidgetTester tester) async {
      late String encoded;
      await tester.runAsync(
        () async => encoded = (await coordinator.configuration).encode(),
      );
      return encoded;
    }

    testWidgets('of an unchanged value returns the current configuration '
        'with no dialog', (tester) async {
      await setUpCoordinator(tester);
      final result = await start(tester, before.connection.toJson());
      expect(find.byType(Dialog), findsNothing);
      final saved = await settle(tester, result);
      expect(saved!.encode(), before.encode());
      expect(coordinator.allowReconnect, isEmpty);
    });

    testWidgets('while disconnected commits with no dialog and keeps the '
        'policy', (tester) async {
      await setUpCoordinator(tester);
      final result = await start(tester, change);
      expect(find.byType(Dialog), findsNothing);
      final saved = await settle(tester, result);
      expect((saved!.connection.expert, saved.connection.rawId), (true, 5));
      expect(saved.policy.toJson(), before.policy.toJson());
      expect(coordinator.allowReconnect, [false]);
      expect(await stored(tester), saved.encode());
    });

    testWidgets('while connected applies with reconnect allowed and no '
        'dialog', (tester) async {
      await setUpCoordinator(tester);
      coordinator.state.value = const ConnectionView(
        phase: ConnectionPhase.connected,
      );
      final result = await start(tester, change);
      expect(find.byType(Dialog), findsNothing);
      final saved = await settle(tester, result);
      expect(coordinator.allowReconnect, [true]);
      expect((saved!.connection.expert, saved.connection.rawId), (true, 5));
      expect(await stored(tester), saved.encode());
    });

    for (final phase in const [
      ConnectionPhase.preparing,
      ConnectionPhase.connecting,
    ]) {
      testWidgets('while ${phase.name} reloads in place with no dialog', (
        tester,
      ) async {
        await setUpCoordinator(tester);
        coordinator.state.value = ConnectionView(phase: phase);
        final policy = _RecordingReloadPolicy(coordinator);
        final result = await start(tester, change, reloadPolicy: policy);
        expect(find.byType(Dialog), findsNothing);
        expect(await settle(tester, result), isNotNull);
        expect(policy.phases, [phase]);
        expect(coordinator.allowReconnect, isEmpty);
      });
    }

    testWidgets('over a held TUN releases it, then commits', (tester) async {
      await setUpCoordinator(tester);
      var heldAnswer = true;
      coordinator.onDisconnect = () => heldAnswer = false;
      final held = OneVpnHeldTunnel(
        read: () async => heldAnswer,
        supported: true,
        pollInterval: const Duration(milliseconds: 10),
      );
      addTearDown(held.dispose);

      final result = await start(tester, change, held: held);
      final saved = await settle(tester, result);

      expect(coordinator.disconnects, 1);
      expect(find.byType(Dialog), findsNothing);
      expect(coordinator.allowReconnect, [false]);
      expect(await stored(tester), saved!.encode());
    });

    testWidgets('with nothing held never disconnects', (tester) async {
      await setUpCoordinator(tester);
      final held = OneVpnHeldTunnel(read: () async => false, supported: true);
      addTearDown(held.dispose);

      final result = await start(tester, change, held: held);
      await settle(tester, result);

      expect(coordinator.disconnects, 0);
      expect(coordinator.allowReconnect, [false]);
    });

    testWidgets('that falls back to Automatic names the label', (tester) async {
      await setUpCoordinator(tester);
      coordinator.issue = 'selectionReset';
      final result = await start(tester, change);
      await settle(tester, result);
      expect(
        find.widgetWithText(SnackBar, l.onevpnSelectionReset('Amsterdam')),
        findsOneWidget,
      );
    });
  });

  for (final (error, message) in [
    (
      const ConnectionResolutionException(
        ConnectionResolutionFailure.selectionUnavailable,
      ),
      'Connection failed',
    ),
    (
      const ConnectionResolutionException(
        ConnectionResolutionFailure.cancelled,
      ),
      null,
    ),
  ]) {
    testWidgets('a failed action: ${error.reason.name}', (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final coordinator = ConnectionCoordinator(database: db);
      addTearDown(db.close);
      addTearDown(coordinator.dispose);
      bool? succeeded;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: oneVpnLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                child: const Text('Connect'),
                onPressed: () async {
                  succeeded = await oneVpnRunConnectionAction(
                    context,
                    coordinator,
                    () async => throw error,
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Connect'));
      await tester.pump();
      await tester.pump();
      expect(succeeded, isFalse);
      if (message != null) {
        expect(find.widgetWithText(SnackBar, message), findsOneWidget);
      } else {
        expect(find.byType(SnackBar), findsNothing);
      }
      expect(tester.takeException(), isNull);
    });
  }

  for (final heldAnswer in [true, false]) {
    testWidgets(
      'a failed start with ${heldAnswer ? 'a held TUN shows no '
                'notice' : 'nothing held shows its notice'}',
      (tester) async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        final coordinator = ConnectionCoordinator(database: db);
        final held = OneVpnHeldTunnel(
          read: () async => heldAnswer,
          supported: true,
        );
        addTearDown(db.close);
        addTearDown(coordinator.dispose);
        addTearDown(held.dispose);
        final context = await _host(tester);
        bool? succeeded;
        oneVpnRunConnectionAction(context, coordinator, () async {
          coordinator.state.value = const ConnectionView(
            phase: ConnectionPhase.failed,
            issue: 'startFailed',
          );
          throw const ConnectionHostException('startFailed');
        }, held: held).then((value) => succeeded = value);
        await tester.pump();
        await tester.pump();

        expect(succeeded, isFalse);
        expect(
          find.widgetWithText(SnackBar, upstream.prototypeConnectionFailed),
          heldAnswer ? findsNothing : findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final label in ['Singapore', null]) {
    testWidgets('a fallback to Automatic with label $label', (tester) async {
      final l = OneVpnLocalizationsEn();
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final coordinator = ConnectionCoordinator(database: db);
      addTearDown(db.close);
      addTearDown(coordinator.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: oneVpnLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                child: const Text('Connect'),
                onPressed: () => oneVpnRunConnectionAction(
                  context,
                  coordinator,
                  () async => coordinator.state.value = const ConnectionView(
                    phase: ConnectionPhase.connected,
                    issue: 'selectionReset',
                  ),
                  selectionLabel: label,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Connect'));
      await tester.pump();
      await tester.pump();
      if (label != null) {
        expect(
          find.widgetWithText(SnackBar, l.onevpnSelectionReset(label)),
          findsOneWidget,
        );
      } else {
        expect(find.byType(SnackBar), findsNothing);
      }
    });
  }

  testWidgets('a completed action answers true and shows nothing', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final coordinator = ConnectionCoordinator(database: db);
    addTearDown(db.close);
    addTearDown(coordinator.dispose);
    bool? succeeded;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              child: const Text('Connect'),
              onPressed: () async {
                succeeded = await oneVpnRunConnectionAction(
                  context,
                  coordinator,
                  () async {},
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Connect'));
    await tester.pump();
    expect(succeeded, isTrue);
    expect(find.byType(SnackBar), findsNothing);
  });
}
