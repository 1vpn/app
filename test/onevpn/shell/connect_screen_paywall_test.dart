// Where the recurring paywall is asked for, over the real connect screen
// and a real router.
//
// The screen fires the trigger at two moments: after the first frame, and
// on every resume. A resume asks only while the connect route is topmost.
// The showing never lands over the picker, the sign-in form, or a paywall
// already open.
//
// The trigger is injected with a hand-moved clock and a settled audience.
// What the trigger itself decides is pinned in its own suite.

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/l10n/localizations/app_localizations.dart';
import 'package:onexray/onevpn/paywall/paywall_cadence.dart';
import 'package:onexray/onevpn/paywall/paywall_trigger.dart';
import 'package:onexray/onevpn/shell/connect_screen.dart';
import 'package:onexray/onevpn/theme/brand_lockup.dart';
import 'package:onexray/onevpn/theme/palettes.dart';
import 'package:onexray/onevpn/theme/premium.dart';
import 'package:onexray/onevpn/shell/routes.dart';
import 'package:onexray/pages/theme/theme.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../support/invoke_channel_stub.dart';
import '../support/ink.dart';
import '../support/localizations.dart';
import '../support/viewports.dart';

/// A settled audience. Its restore is done before the screen asks.
class _Audience implements OneVpnPaywallAudience {
  @override
  bool entitled = false;

  @override
  Future<void> whenRestored() async {}
}

/// Advances frames without waiting for a quiet tree. The connect screen
/// holds a live database stream, so it never settles.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

Future<void> _resume(WidgetTester tester) async {
  WidgetsBinding.instance.handleAppLifecycleStateChanged(
    AppLifecycleState.inactive,
  );
  WidgetsBinding.instance.handleAppLifecycleStateChanged(
    AppLifecycleState.resumed,
  );
  await _settle(tester);
}

void main() {
  late DateTime now;
  late GoRouter router;
  late _Audience audience;
  late int paywalls;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    now = DateTime.utc(2026, 9, 21, 9);
    audience = _Audience();
    paywalls = 0;
  });

  /// Mounts the connect screen at the router root, with the paywall and the
  /// picker pushable over it. Every paywall push increments [paywalls].
  Future<void> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
  }) async {
    stubInvokeChannel();
    await setViewport(tester, kPortraitViewport);

    final trigger = OneVpnPaywallTrigger(
      cadence: OneVpnPaywallCadence(now: () => now),
      audience: audience,
    );
    router = GoRouter(
      initialLocation: kOneVpnConnectRoute,
      routes: [
        GoRoute(
          path: kOneVpnConnectRoute,
          builder: (_, _) => OneVpnConnectScreen(paywallTrigger: trigger),
        ),
        GoRoute(
          path: kOneVpnPaywallRoute,
          builder: (_, _) {
            paywalls++;
            return const Scaffold(body: Text('paywall'));
          },
        ),
        GoRoute(
          path: kOneVpnLocationRoute,
          builder: (_, _) => const Scaffold(body: Text('picker')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.material(brightness),
        locale: const Locale('en'),
        localizationsDelegates: oneVpnLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await _settle(tester);
  }

  testWidgets('entry opens the paywall when the cadence is due', (
    tester,
  ) async {
    await pump(tester);

    expect(paywalls, 1);
    expect(find.text('paywall'), findsOneWidget);
  });

  testWidgets('entry opens nothing inside the interval', (tester) async {
    await pump(tester);
    expect(paywalls, 1);

    router.pop();
    await _settle(tester);
    now = now.add(const Duration(hours: 11));

    await _resume(tester);

    expect(paywalls, 1);
    expect(find.byType(OneVpnBrandLockup), findsOneWidget);
  });

  testWidgets('a resume past the interval asks again', (tester) async {
    await pump(tester);
    expect(paywalls, 1);

    router.pop();
    await _settle(tester);
    now = now.add(kOneVpnPaywallCadence);

    await _resume(tester);

    // The process outlives one cold start, so a resume past the interval
    // shows the paywall again.
    expect(paywalls, 2);
  });

  testWidgets('a resume over a pushed route opens nothing', (tester) async {
    await pump(tester);
    router.pop();
    await _settle(tester);

    // The user is in the picker. The paywall never lands on top of it.
    router.push(kOneVpnLocationRoute);
    await _settle(tester);
    now = now.add(kOneVpnPaywallCadence);

    await _resume(tester);

    expect(paywalls, 1);
    expect(find.text('picker'), findsOneWidget);
  });

  testWidgets('a resume over the paywall itself opens nothing', (tester) async {
    await pump(tester);
    expect(find.text('paywall'), findsOneWidget);
    now = now.add(kOneVpnPaywallCadence);

    await _resume(tester);

    expect(paywalls, 1);
  });

  testWidgets('an entitled account is asked at neither moment', (tester) async {
    audience.entitled = true;

    await pump(tester);
    expect(paywalls, 0);

    now = now.add(kOneVpnPaywallCadence);
    await _resume(tester);

    expect(paywalls, 0);
    expect(find.byType(OneVpnBrandLockup), findsOneWidget);
  });

  group('the upgrade banner', () {
    /// The WCAG contrast ratio between two opaque colors.
    double contrast(Color a, Color b) {
      final la = a.computeLuminance();
      final lb = b.computeLuminance();
      return (la > lb ? la + 0.05 : lb + 0.05) /
          (la > lb ? lb + 0.05 : la + 0.05);
    }

    for (final brightness in Brightness.values) {
      testWidgets('fills with primarySolid in the ${brightness.name} theme', (
        tester,
      ) async {
        await pump(tester, brightness: brightness);
        router.pop();
        await _settle(tester);

        final banner = tester.widget<Material>(
          find.byKey(const ValueKey('onevpn-upgrade-banner')),
        );
        final palette = OneVpnPalettes.tokens(brightness).palette;
        expect(banner.color, palette.primarySolid);
        expect(
          contrast(Colors.white, banner.color!),
          greaterThanOrEqualTo(4.5),
        );
        final star = tester.widget<OneVpnPremiumStar>(
          find.descendant(
            of: find.byKey(const ValueKey('onevpn-upgrade-banner')),
            matching: find.byType(OneVpnPremiumStar),
          ),
        );
        expect(star.outlined, isTrue);
        expect(star.color, palette.primaryForeground);
        expect(
          contrast(palette.primaryForeground, banner.color!),
          greaterThanOrEqualTo(4.5),
        );
      });
    }

    testWidgets('flashes white when pressed and keeps the theme focus and '
        'hover colors', (tester) async {
      await pump(tester);
      router.pop();
      await _settle(tester);

      expectSolidInk(tester, [
        find.descendant(
          of: find.byKey(const ValueKey('onevpn-upgrade-banner')),
          matching: find.byType(OneVpnPremiumStar),
        ),
      ]);
    });
  });
}
