// The rating prompt on the real connect screen.
//
// A tap that disconnects a connected tunnel shows the rating dialog. Yes
// opens the review flow. A review flow that never returns leaves the control
// free for the next tap. An answered install shows nothing on a later
// disconnect. A failed disconnect, a disconnect from the no-connection
// state, a disconnect the tap did not start, and a connect tap show nothing.
// The screen renders at the reference handset size.

import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/core/db/database/database.dart';
import 'package:onexray/l10n/localizations/app_localizations.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/ads/connect_ad_gate.dart';
import 'package:onexray/onevpn/paywall/paywall_cadence.dart';
import 'package:onexray/onevpn/paywall/paywall_trigger.dart';
import 'package:onexray/onevpn/rating/rating_prompt.dart';
import 'package:onexray/onevpn/shell/connect_control.dart';
import 'package:onexray/onevpn/shell/connect_screen.dart';
import 'package:onexray/onevpn/shell/first_connect_explainer.dart';
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

import '../ads/fake_ad_gateway.dart';
import '../support/held_tunnel_stub.dart';
import '../support/invoke_channel_stub.dart';
import '../support/localizations.dart';
import '../support/viewports.dart';
import 'fake_review_launcher.dart';

/// A coordinator over [database] whose disconnect lands disconnected, or
/// failed with a thrown error when [failsDisconnect] is set.
class _ScriptedCoordinator extends ConnectionCoordinator {
  _ScriptedCoordinator(AppDatabase database)
    : super(
        database: database,
        statusEvents: const Stream.empty(),
        observeStatus: () async {},
        disposeStatus: () {},
      );

  bool failsDisconnect = false;

  @override
  Future<void> connect() async {
    state.value = const ConnectionView(phase: ConnectionPhase.connected);
  }

  @override
  Future<void> disconnect() async {
    if (failsDisconnect) {
      state.value = const ConnectionView(
        phase: ConnectionPhase.failed,
        issue: 'stopFailed',
      );
      throw StateError('stop failed');
    }
    state.value = const ConnectionView(phase: ConnectionPhase.disconnected);
  }
}

class _EntitledAudience implements OneVpnPaywallAudience {
  @override
  bool get entitled => true;

  @override
  Future<void> whenRestored() async {}
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
  expect(done, isTrue, reason: 'the future never finished');
  return value;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

void main() {
  late AppDatabase db;
  late _ScriptedCoordinator coordinator;
  late FakeReviewLauncher launcher;
  late ValueNotifier<bool> allDead;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  /// Mounts the connect screen for a signed-out user with a connected
  /// tunnel. With [answered] an answer is already stored. With
  /// [reviewHangs] the review flow never returns.
  Future<void> pump(
    WidgetTester tester, {
    bool answered = false,
    bool reviewHangs = false,
  }) async {
    await tester.runAsync(OneVpnAccountService.instance.whenRestored);
    launcher = FakeReviewLauncher(hangs: reviewHangs);
    allDead = ValueNotifier(false);
    addTearDown(allDead.dispose);
    db = AppDatabase.forTesting(NativeDatabase.memory());
    coordinator = _ScriptedCoordinator(db);
    addTearDown(coordinator.dispose);
    final base = ConnectionConfiguration.fromJson({});
    await _drain(
      tester,
      db.connectionConfigDao.commit(
        configurationJson: jsonEncode({
          ...base.toJson(),
          'connection': {
            ...base.connection.toJson(),
            'selection': const ServerSelection.automatic().toJson(),
          },
        }),
      ),
    );
    final preferences = SharedPreferencesAsync();
    await _drain(
      tester,
      preferences.setBool(OneVpnFirstConnectExplainer.seenKey, true),
    );
    await _drain(
      tester,
      preferences.setBool(OneVpnConnectAdGate.firstConnectKey, true),
    );
    if (answered) {
      await _drain(
        tester,
        preferences.setBool(OneVpnRatingPrompt.answerKey, false),
      );
    }
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
            allDead: allDead,
            adGate: OneVpnConnectAdGate(gateway: FakeAdGateway(loads: false)),
            ratingPrompt: OneVpnRatingPrompt(launcher: launcher),
            paywallTrigger: OneVpnPaywallTrigger(
              cadence: OneVpnPaywallCadence(now: DateTime.now),
              audience: _EntitledAudience(),
            ),
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
        routerConfig: router,
      ),
    );
    await _settle(tester);
    coordinator.state.value = const ConnectionView(
      phase: ConnectionPhase.connected,
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

  Future<void> tapControl(WidgetTester tester) async {
    await tester.tap(find.byType(OneVpnConnectControl));
    await _settle(tester);
  }

  testWidgets(
    'a disconnect tap shows the dialog, and yes opens the review flow',
    (tester) async {
      await pump(tester);

      await tapControl(tester);

      expect(coordinator.state.value.phase, ConnectionPhase.disconnected);
      expect(find.byType(OneVpnRatingDialog), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Yes'));
      await _settle(tester);

      expect(find.byType(OneVpnRatingDialog), findsNothing);
      expect(launcher.opens, 1);
      expect(
        await _drain(
          tester,
          SharedPreferencesAsync().getBool(OneVpnRatingPrompt.answerKey),
        ),
        isTrue,
      );
      await unmount(tester);
    },
  );

  testWidgets('yes frees the control while the review flow stays open', (
    tester,
  ) async {
    await pump(tester, reviewHangs: true);

    await tapControl(tester);
    expect(find.byType(OneVpnRatingDialog), findsOneWidget);
    await tester.tap(find.text('Yes'));
    await _settle(tester);
    expect(find.byType(OneVpnRatingDialog), findsNothing);
    expect(launcher.opens, 1);

    // The review flow never returns. The next tap still connects.
    await tapControl(tester);

    expect(coordinator.state.value.phase, ConnectionPhase.connected);
    expect(find.byType(OneVpnRatingDialog), findsNothing);
    await unmount(tester);
  });

  testWidgets('an answered install shows nothing on a disconnect tap', (
    tester,
  ) async {
    await pump(tester, answered: true);

    await tapControl(tester);

    expect(coordinator.state.value.phase, ConnectionPhase.disconnected);
    expect(find.byType(OneVpnRatingDialog), findsNothing);
    await unmount(tester);
  });

  testWidgets('a failed disconnect shows nothing', (tester) async {
    await pump(tester);
    coordinator.failsDisconnect = true;

    await tapControl(tester);

    expect(coordinator.state.value.phase, ConnectionPhase.failed);
    expect(find.byType(OneVpnRatingDialog), findsNothing);
    await unmount(tester);
  });

  testWidgets('a disconnect from the no-connection state shows nothing', (
    tester,
  ) async {
    await pump(tester);
    allDead.value = true;
    await _settle(tester);

    await tapControl(tester);

    expect(coordinator.state.value.phase, ConnectionPhase.disconnected);
    expect(find.byType(OneVpnRatingDialog), findsNothing);
    await unmount(tester);
  });

  testWidgets('a disconnect the tap did not start shows nothing', (
    tester,
  ) async {
    await pump(tester);

    // A stop from the notification, the tile, or a lost tunnel reaches the
    // coordinator directly.
    await _drain(tester, coordinator.disconnect());
    await _settle(tester);

    expect(find.byType(OneVpnRatingDialog), findsNothing);
    await unmount(tester);
  });

  testWidgets('a connect tap shows nothing', (tester) async {
    await pump(tester);
    coordinator.state.value = const ConnectionView(
      phase: ConnectionPhase.disconnected,
    );
    await _settle(tester);

    await tapControl(tester);

    expect(coordinator.state.value.phase, ConnectionPhase.connected);
    expect(find.byType(OneVpnRatingDialog), findsNothing);
    await unmount(tester);
  });
}
