// The censorship warning shows once ever, on the first connect tap of a free
// account whose app language is Russian, Persian or Chinese in either script.
// It stamps the fork flag when it fires. Any other language never shows it and
// never stamps. The message is centre-aligned. Continue dismisses it and the
// connect follows. A preference store that throws shows no warning and never
// fails the connect tap. The screen renders at the reference handset size.

import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/core/db/database/database.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/ads/connect_ad_gate.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations.dart';
import 'package:onexray/onevpn/l10n/locales.dart';
import 'package:onexray/onevpn/paywall/paywall_cadence.dart';
import 'package:onexray/onevpn/paywall/paywall_trigger.dart';
import 'package:onexray/onevpn/rating/rating_prompt.dart';
import 'package:onexray/onevpn/shell/censorship_warning.dart';
import 'package:onexray/onevpn/shell/connect_control.dart';
import 'package:onexray/onevpn/shell/connect_screen.dart';
import 'package:onexray/onevpn/shell/first_connect_explainer.dart';
import 'package:onexray/onevpn/shell/notification_prompt.dart';
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

/// A coordinator over [database] that logs each connect and disconnect into
/// [log] and moves the phase.
class _ScriptedCoordinator extends ConnectionCoordinator {
  _ScriptedCoordinator(AppDatabase database, this.log)
    : super(
        database: database,
        statusEvents: const Stream.empty(),
        observeStatus: () async {},
        disposeStatus: () {},
      );

  final List<String> log;

  @override
  Future<void> connect() async {
    log.add('connect');
    state.value = const ConnectionView(phase: ConnectionPhase.connected);
  }

  @override
  Future<void> disconnect() async {
    log.add('disconnect');
    state.value = const ConnectionView(phase: ConnectionPhase.disconnected);
  }
}

class _EntitledAudience implements OneVpnPaywallAudience {
  @override
  bool get entitled => true;

  @override
  Future<void> whenRestored() async {}
}

/// The stored configuration with the automatic selection.
String _configuration() {
  final base = ConnectionConfiguration.fromJson({});
  return jsonEncode({
    ...base.toJson(),
    'connection': {
      ...base.connection.toJson(),
      'selection': const ServerSelection.automatic().toJson(),
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
  expect(done, isTrue, reason: 'the future never finished');
  return value;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

/// Preferences whose boolean reads and writes throw for the once-ever keys
/// of the censorship warning and the ad gate.
final class _FailingOnceEverKeys extends InMemorySharedPreferencesAsync {
  _FailingOnceEverKeys({this.readThrows = true, this.writeThrows = true})
    : super.empty();

  final bool readThrows;
  final bool writeThrows;

  static bool _fails(String key) =>
      key == OneVpnCensorshipWarning.seenKey ||
      key == OneVpnConnectAdGate.firstConnectKey;

  @override
  Future<bool?> getBool(String key, SharedPreferencesOptions options) =>
      readThrows && _fails(key)
      ? Future<bool?>.error(StateError('prefs unavailable'))
      : super.getBool(key, options);

  @override
  Future<bool> setBool(
    String key,
    bool value,
    SharedPreferencesOptions options,
  ) => writeThrows && _fails(key)
      ? Future<bool>.error(StateError('prefs unavailable'))
      : super.setBool(key, value, options);
}

const _hant = Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant');

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  Future<bool?> seen() =>
      SharedPreferencesAsync().getBool(OneVpnCensorshipWarning.seenKey);

  group('the once-ever gate', () {
    test('the flag lives in the fork namespace', () {
      expect(OneVpnCensorshipWarning.seenKey, startsWith('onevpn.'));
      expect(
        OneVpnCensorshipWarning.seenKey,
        isNot(OneVpnFirstConnectExplainer.seenKey),
      );
    });

    for (final locale in const [Locale('ru'), Locale('fa'), Locale('zh')]) {
      test(
        'under ${locale.toLanguageTag()} it fires once and stamps',
        () async {
          final first = OneVpnCensorshipWarning();
          expect(
            await first.consumeFirstConnect(locale, premium: false),
            isTrue,
          );
          expect(await seen(), isTrue);
          expect(
            await first.consumeFirstConnect(locale, premium: false),
            isFalse,
          );
          // A fresh instance reads the stamped flag.
          expect(
            await OneVpnCensorshipWarning().consumeFirstConnect(
              locale,
              premium: false,
            ),
            isFalse,
          );
        },
      );
    }

    test('it applies to Traditional Chinese as well', () {
      expect(OneVpnCensorshipWarning.appliesTo(_hant, premium: false), isTrue);
    });

    for (final locale in const [Locale('en'), Locale('uk'), Locale('ar')]) {
      test(
        'under ${locale.toLanguageTag()} it never fires and never stamps',
        () async {
          expect(
            await OneVpnCensorshipWarning().consumeFirstConnect(
              locale,
              premium: false,
            ),
            isFalse,
          );
          expect(await seen(), isNull);
        },
      );
    }

    for (final (name, read, write) in const [
      ('read', true, false),
      ('stamp', false, true),
    ]) {
      test('a $name that throws resolves false', () async {
        SharedPreferencesAsyncPlatform.instance = _FailingOnceEverKeys(
          readThrows: read,
          writeThrows: write,
        );
        expect(
          await OneVpnCensorshipWarning().consumeFirstConnect(
            const Locale('ru'),
            premium: false,
          ),
          isFalse,
        );
      });
    }

    test('a premium account never fires and never stamps', () async {
      expect(
        await OneVpnCensorshipWarning().consumeFirstConnect(
          const Locale('ru'),
          premium: true,
        ),
        isFalse,
      );
      expect(await seen(), isNull);
    });
  });

  group('on the connect screen', () {
    late AppDatabase db;
    late _ScriptedCoordinator coordinator;
    late List<String> log;

    /// Mounts the connect screen for a signed-out user in [locale].
    Future<void> pump(WidgetTester tester, Locale locale) async {
      // The store holds no session: the account state settles signed out.
      await tester.runAsync(OneVpnAccountService.instance.whenRestored);
      log = <String>[];
      db = AppDatabase.forTesting(NativeDatabase.memory());
      coordinator = _ScriptedCoordinator(db, log);
      addTearDown(coordinator.dispose);
      await _drain(
        tester,
        db.connectionConfigDao.commit(configurationJson: _configuration()),
      );
      await _drain(
        tester,
        SharedPreferencesAsync().setBool(
          OneVpnFirstConnectExplainer.seenKey,
          true,
        ),
      );
      await _drain(
        tester,
        SharedPreferencesAsync().setBool(
          OneVpnNotificationPrompt.askedKey,
          true,
        ),
      );
      // A stored answer ends the rating prompt. Its dialog otherwise covers
      // the control after the disconnect tap.
      await _drain(
        tester,
        SharedPreferencesAsync().setBool(OneVpnRatingPrompt.answerKey, true),
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
              adGate: OneVpnConnectAdGate(
                gateway: FakeAdGateway(loads: false, log: <String>[]),
              ),
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
          locale: locale,
          localizationsDelegates: oneVpnLocalizationsDelegates,
          supportedLocales: [for (final l in kOneVpnLocales) l.locale],
          localeResolutionCallback: oneVpnResolveLocale,
          routerConfig: router,
        ),
      );
      await _settle(tester);
    }

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

    Future<String> message(Locale locale) async =>
        (await OneVpnLocalizations.delegate.load(locale))
            .onevpnCensorshipWarning;

    for (final locale in const [
      Locale('ru'),
      Locale('fa'),
      Locale('zh'),
      _hant,
    ]) {
      testWidgets('under ${locale.toLanguageTag()} the first tap shows the '
          'warning once, and the connect follows Continue', (tester) async {
        await pump(tester, locale);
        final text = await message(locale);

        await tapControl(tester);
        expect(find.byType(OneVpnCensorshipWarningDialog), findsOneWidget);
        expect(find.text(text), findsOneWidget);
        expect(
          tester.widget<Text>(find.text(text)).textAlign,
          TextAlign.center,
        );
        expect(await _drain(tester, seen()), isTrue);
        // The connect waits for the dismissal.
        expect(log, isEmpty);

        await tester.tap(find.byType(FilledButton));
        await _settle(tester);
        expect(find.byType(OneVpnCensorshipWarningDialog), findsNothing);
        expect(log, ['connect']);

        await tapControl(tester);
        await tapControl(tester);
        expect(log, ['connect', 'disconnect', 'connect']);
        expect(find.byType(OneVpnCensorshipWarningDialog), findsNothing);
        expect(tester.takeException(), isNull);
        await unmount(tester);
      });
    }

    testWidgets('under en the tap connects with no warning and no stamp', (
      tester,
    ) async {
      await pump(tester, const Locale('en'));

      await tapControl(tester);
      expect(find.byType(OneVpnCensorshipWarningDialog), findsNothing);
      expect(log, ['connect']);
      expect(await _drain(tester, seen()), isNull);
      await unmount(tester);
    });

    testWidgets('under ru a store that throws shows no warning and the tap '
        'connects', (tester) async {
      SharedPreferencesAsyncPlatform.instance = _FailingOnceEverKeys();
      await pump(tester, const Locale('ru'));

      await tapControl(tester);
      expect(find.byType(OneVpnCensorshipWarningDialog), findsNothing);
      expect(log, ['connect']);
      expect(tester.takeException(), isNull);
      await unmount(tester);
    });
  });
}
