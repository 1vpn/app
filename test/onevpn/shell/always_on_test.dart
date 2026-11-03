// The Android always-on VPN guidance. The menu row shows on Android only. The
// guide is a full page pushed over the menu, titled in its app bar. A
// headline card states that always-on reconnects a dropped VPN. It sits over
// four numbered steps. The steps sit on the card's content inset. Each number
// square sits under the card's glyph, and each step's text sits under the
// card's body. At 800x360 the card fills the start pane and the steps fill the
// end pane.
//
// The guide's button closes the guide and the menu. It asks the fork channel
// to open the system VPN settings screen. The close button, system back, and
// predictive back ask nothing and return to the menu. The settings button
// closes the menu from the top drawer and from the end drawer. It also closes
// the menu after a mode change while the guide is open. The channel call
// answers false off Android, on a platform error, and with no handler.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/l10n/localizations/app_localizations.dart';
import 'package:onexray/l10n/localizations/app_localizations_en.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/app/platform_channel.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations_en.dart';
import 'package:onexray/onevpn/shell/always_on.dart';
import 'package:onexray/onevpn/shell/layout.dart';
import 'package:onexray/onevpn/shell/menu.dart';
import 'package:onexray/onevpn/shell/router.dart';
import 'package:onexray/onevpn/shell/routes.dart';
import 'package:onexray/onevpn/theme/backdrop.dart';
import 'package:onexray/onevpn/theme/headline_card.dart';
import 'package:onexray/pages/theme/theme.dart';

import '../support/localizations.dart';
import '../support/viewports.dart';

const _channel = MethodChannel(OneVpnPlatformChannel.name);

/// Answers every channel call with [answer] and records the method names.
List<String> _mockChannel({Object? answer = true, bool throws = false}) {
  final calls = <String>[];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, (call) async {
        calls.add(call.method);
        if (throws) throw PlatformException(code: 'failed');
        return answer;
      });
  addTearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null),
  );
  return calls;
}

GoRouter _router() => GoRouter(
  initialLocation: kOneVpnConnectRoute,
  routes: [
    GoRoute(
      path: kOneVpnConnectRoute,
      builder: (context, _) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => showOneVpnMenu(
              context,
              accountState: ValueNotifier<OneVpnAccountState>(
                const OneVpnAccountSignedOut(),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
    ...OneVpnRouter.menuSurfaces(),
  ],
);

Future<void> _openMenu(
  WidgetTester tester, {
  Size size = kPortraitViewport,
}) async {
  await setViewport(tester, size);
  await tester.pumpWidget(
    MaterialApp.router(
      theme: AppTheme.light,
      locale: const Locale('en'),
      localizationsDelegates: oneVpnLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _router(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  final l = OneVpnLocalizationsEn();
  final upstream = AppLocalizationsEn();

  testWidgets('the menu carries the always-on row on Android', (tester) async {
    await _openMenu(tester);
    expect(find.text(l.onevpnAlwaysOnTitle), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets(
    'the menu omits the always-on row off Android',
    (tester) async {
      await _openMenu(tester);
      expect(find.text(l.onevpnSupport), findsOneWidget);
      expect(find.text(l.onevpnAlwaysOnTitle), findsNothing);
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.iOS,
      TargetPlatform.macOS,
    }),
  );

  testWidgets('the row opens the guidance and its button opens VPN settings', (
    tester,
  ) async {
    final calls = _mockChannel();
    await _openMenu(tester);
    await tester.tap(find.text(l.onevpnAlwaysOnTitle));
    await tester.pumpAndSettle();

    expect(find.text(l.onevpnAlwaysOnIntro), findsOneWidget);
    expect(calls, isEmpty);

    // The headline card and the steps push the button below the fold.
    await tester.ensureVisible(find.text(l.onevpnAlwaysOnOpenSettings));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.onevpnAlwaysOnOpenSettings));
    await tester.pumpAndSettle();
    expect(calls, ['openVpnSettings']);
    expect(find.text(l.onevpnAlwaysOnIntro), findsNothing);
    expect(find.text(l.onevpnSupport), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('the close button returns to the menu without opening settings', (
    tester,
  ) async {
    final calls = _mockChannel();
    await _openMenu(tester);
    await tester.tap(find.text(l.onevpnAlwaysOnTitle));
    await tester.pumpAndSettle();
    expect(find.text(upstream.prototypeClose), findsNothing);
    expect(find.text(upstream.prototypeBack), findsNothing);
    await tester.tap(
      find.descendant(
        of: find.byType(OneVpnAlwaysOnPage),
        matching: find.byType(CloseButton),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l.onevpnAlwaysOnIntro), findsNothing);
    expect(find.text(l.onevpnSupport), findsOneWidget);
    expect(find.text(l.onevpnAlwaysOnTitle), findsOneWidget);
    expect(calls, isEmpty);
  });

  testWidgets('system back returns to the menu', (tester) async {
    await _openMenu(tester);
    await tester.tap(find.text(l.onevpnAlwaysOnTitle));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text(l.onevpnAlwaysOnIntro), findsNothing);
    expect(find.text(l.onevpnSupport), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('a committed predictive back returns to the menu', (
    tester,
  ) async {
    await _openMenu(tester);
    await tester.tap(find.text(l.onevpnAlwaysOnTitle));
    await tester.pumpAndSettle();
    Future<void> gesture(String method, [Object? arguments]) =>
        tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          SystemChannels.backGesture.name,
          SystemChannels.backGesture.codec.encodeMethodCall(
            MethodCall(method, arguments),
          ),
          (_) {},
        );
    await gesture('startBackGesture', <String, Object?>{
      'touchOffset': <double>[5, 400],
      'progress': 0.0,
      'swipeEdge': 0,
    });
    await gesture('commitBackGesture');
    await tester.pumpAndSettle();

    expect(find.text(l.onevpnAlwaysOnIntro), findsNothing);
    expect(find.text(l.onevpnSupport), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('the close button returns to the menu', (tester) async {
    await _openMenu(tester);
    await tester.tap(find.text(l.onevpnAlwaysOnTitle));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(OneVpnAlwaysOnPage),
        matching: find.byType(CloseButton),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l.onevpnAlwaysOnIntro), findsNothing);
    expect(find.text(l.onevpnSupport), findsOneWidget);
  });

  testWidgets('settings still close the menu after a mode change', (
    tester,
  ) async {
    final calls = _mockChannel();
    await _openMenu(tester);
    await tester.tap(find.text(l.onevpnAlwaysOnTitle));
    await tester.pumpAndSettle();

    // The menu page beneath becomes the drawer while the guide is open.
    await setViewport(tester, kLandscapeViewport);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(l.onevpnAlwaysOnOpenSettings));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.onevpnAlwaysOnOpenSettings));
    await tester.pumpAndSettle();

    expect(calls, ['openVpnSettings']);
    expect(find.text(l.onevpnAlwaysOnIntro), findsNothing);
    expect(find.byKey(OneVpnMenu.stackedKey), findsNothing);
    expect(find.byKey(OneVpnMenu.drawerKey), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('settings from the drawer close the drawer', (tester) async {
    final calls = _mockChannel();
    await _openMenu(tester, size: kLandscapeViewport);
    await tester.tap(find.text(l.onevpnAlwaysOnTitle));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(l.onevpnAlwaysOnOpenSettings));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.onevpnAlwaysOnOpenSettings));
    await tester.pumpAndSettle();

    expect(calls, ['openVpnSettings']);
    expect(find.text(l.onevpnAlwaysOnIntro), findsNothing);
    expect(find.byKey(OneVpnMenu.drawerKey), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('the guide is a full page titled in its AppBar', (tester) async {
    await _openMenu(tester);
    await tester.tap(find.text(l.onevpnAlwaysOnTitle));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsNothing);
    final page = find.byType(OneVpnAlwaysOnPage);
    expect(tester.getRect(page), Offset.zero & kPortraitViewport);
    final appBar = find.descendant(of: page, matching: find.byType(AppBar));
    expect(
      find.descendant(of: appBar, matching: find.text(l.onevpnAlwaysOnTitle)),
      findsOneWidget,
    );
    // The headline card carries the shield glyph beside its title and the
    // intro.
    final card = find.descendant(
      of: page,
      matching: find.byType(OneVpnHeadlineCard),
    );
    expect(
      find.descendant(of: card, matching: find.byIcon(LucideIcons.info)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text(l.onevpnAlwaysOnIntro)),
      findsOneWidget,
    );
    for (final number in ['1', '2', '3', '4']) {
      expect(find.descendant(of: page, matching: find.text(number)), findsOne);
    }
    // Each number square sits under the card's glyph, and each step's text
    // under the card's body.
    final title = tester.getRect(find.text(l.onevpnAlwaysOnIntro));
    final glyph = tester.getRect(
      find.descendant(of: card, matching: find.byIcon(LucideIcons.info)),
    );
    for (final (number, step) in [
      ('1', l.onevpnAlwaysOnStep1),
      ('4', l.onevpnAlwaysOnStep4),
    ]) {
      final square = tester.getRect(
        find.ancestor(
          of: find.text(number),
          matching: find.byType(OneVpnBackdropSquare),
        ),
      );
      expect(square.size, const Size.square(32));
      expect(square.center.dx, moreOrLessEquals(glyph.center.dx, epsilon: 0.5));
      expect(
        tester.getTopLeft(find.text(step)).dx,
        moreOrLessEquals(title.left, epsilon: 0.5),
      );
    }
  });

  for (final size in [kPortraitViewport, kLandscapeViewport]) {
    final name = '${size.width.toInt()}x${size.height.toInt()}';
    final split = size == kLandscapeViewport;
    testWidgets('at $name the guide lays out with no overflow', (tester) async {
      await _openMenu(tester, size: size);
      await tester.tap(find.text(l.onevpnAlwaysOnTitle));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final page = find.byType(OneVpnAlwaysOnPage);
      expect(
        find.descendant(
          of: page,
          matching: find.byKey(OneVpnConstrainedBody.stackedKey),
        ),
        split ? findsNothing : findsOneWidget,
      );
      expect(
        find.descendant(
          of: page,
          matching: find.byKey(OneVpnAdaptiveBody.splitKey),
        ),
        split ? findsOneWidget : findsNothing,
      );
      if (split) {
        // The card fills the start pane. The steps fill the end pane.
        expect(
          find.descendant(
            of: find.byKey(OneVpnAdaptiveBody.startPaneKey),
            matching: find.byType(OneVpnHeadlineCard),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(OneVpnAdaptiveBody.endPaneKey),
            matching: find.text(l.onevpnAlwaysOnStep1),
          ),
          findsOneWidget,
        );
      } else {
        final card = tester.getRect(find.byType(OneVpnHeadlineCard));
        expect(card.width, lessThanOrEqualTo(OneVpnLayout.listCap));
        expect(card.center.dx, closeTo(size.width / 2, 0.01));
      }
      await tester.ensureVisible(find.text(l.onevpnAlwaysOnOpenSettings));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.text(l.onevpnAlwaysOnOpenSettings).hitTestable(),
        findsOneWidget,
      );
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));
  }

  testWidgets('in split, the close button returns to the drawer', (
    tester,
  ) async {
    await _openMenu(tester, size: kLandscapeViewport);
    expect(find.byKey(OneVpnMenu.drawerKey), findsOneWidget);
    await tester.tap(find.text(l.onevpnAlwaysOnTitle));
    await tester.pumpAndSettle();
    expect(find.text(l.onevpnAlwaysOnIntro), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(OneVpnAlwaysOnPage),
        matching: find.byType(CloseButton),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(l.onevpnAlwaysOnIntro), findsNothing);
    expect(find.byKey(OneVpnMenu.drawerKey), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  test('the copy walks the system list and states the reconnect rule', () {
    expect(
      l.onevpnAlwaysOnStep1,
      contains('Tap ${l.onevpnAlwaysOnOpenSettings} below'),
    );
    expect(l.onevpnAlwaysOnStep2, contains('Find 1VPN in the list'));
    expect(
      l.onevpnAlwaysOnStep2,
      contains('It appears after your first connect'),
    );
    expect(l.onevpnAlwaysOnStep3, contains('Tap the gear icon next to 1VPN'));
    expect(l.onevpnAlwaysOnStep4, contains('Turn on Always-on VPN'));
    expect(
      l.onevpnAlwaysOnIntro,
      'The tunnel stays up when you close the app. After a restart or an app '
      'update, Always-on VPN reconnects it automatically.',
    );
  });

  group('openVpnSettings', () {
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('answers the native result on Android', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      _mockChannel(answer: true);
      expect(await OneVpnPlatformChannel.openVpnSettings(), isTrue);
    });

    test('answers false off Android and never calls the channel', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final calls = _mockChannel();
      expect(await OneVpnPlatformChannel.openVpnSettings(), isFalse);
      expect(calls, isEmpty);
    });

    test('answers false on a platform error', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      _mockChannel(throws: true);
      expect(await OneVpnPlatformChannel.openVpnSettings(), isFalse);
    });

    test('answers false with no handler', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(await OneVpnPlatformChannel.openVpnSettings(), isFalse);
    });
  });

  test('the Android side declares the fork channel name', () {
    final handler = File(
      'android/app/src/main/kotlin/net/yuandev/onexray/onevpn/'
      'OneVpnPlatformChannel.kt',
    ).readAsStringSync();

    expect(
      handler,
      contains('CHANNEL: String = "${OneVpnPlatformChannel.name}"'),
    );
  });
}
