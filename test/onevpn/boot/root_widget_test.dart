// Contract for the fork root widget. The root:
//
// - composes at the reference handset size
// - mounts the one-screen connect shell first
// - carries the 1VPN title
// - resolves RTL from each RTL fork locale through the builder's Directionality
// - resolves unsupported RTL system locales to English rendered LTR
// - picks the theme metrics by the shortest side
// - passes exactly the five localization delegates, the fork delegate first
//   and the upstream fallback delegate second
//
// The shell runs the runtime service initialization on mount. The test
// therefore isolates the paths and taps the bridge channels, like the
// suppression pin. The database open and the platform calls stay inside
// the test's control. The test also records the fork reload channels:
// mounting the root sends nothing on them.

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/l10n/localizations/app_localizations.dart';
import 'package:onexray/core/db/database/database.dart';
import 'package:onexray/onevpn/app/app.dart';
import 'package:onexray/onevpn/handover/handover_host.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations.dart';
import 'package:onexray/onevpn/l10n/locales.dart';
import 'package:onexray/onevpn/l10n/upstream_delegate.dart';
import 'package:onexray/onevpn/shell/shell.dart';
import 'package:onexray/onevpn/theme/palettes.dart';
import 'package:onexray/pages/theme/theme.dart';
import 'package:onexray/service/shared/event_bus/service.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../support/reload_channels.dart';
import '../support/viewports.dart';

/// Resolves the two path_provider lookups the database open makes to a
/// per-test directory, so the open stays inside the test's control.
final class _IsolatedPaths extends PathProviderPlatform {
  _IsolatedPaths(this.path);
  final String path;

  @override
  Future<String?> getApplicationDocumentsPath() async => path;

  @override
  Future<String?> getTemporaryPath() async => path;
}

List<String> _hostApiMethods() {
  final source = File("lib/core/pigeon/messages.g.dart").readAsStringSync();
  return RegExp(r'dev\.flutter\.pigeon\.onexray\.BridgeHostApi\.(\w+)')
      .allMatches(source)
      .map((match) => match.group(1)!)
      .toSet()
      .toList();
}

/// The reference handset viewport every widget test runs at.
Future<void> _useHandsetViewport(WidgetTester tester) =>
    setViewport(tester, kPortraitViewport);

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const trayChannel = MethodChannel("tray_manager");
  final hostApiMethods = _hostApiMethods();
  final forkReloadChannels = reloadChannels();
  final reloadCalls = <String>[];
  late Directory tempDirectory;
  late PathProviderPlatform previousPaths;

  setUp(() async {
    // The static late AppEventBus.instance must exist before anything reads
    // it. The root widget then creates and owns the real bus.
    AppEventBus();
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    tempDirectory = await Directory.systemTemp.createTemp('root-widget-');
    previousPaths = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _IsolatedPaths(tempDirectory.path);
    for (final method in hostApiMethods) {
      binding.defaultBinaryMessenger.setMockMessageHandler(
        "dev.flutter.pigeon.onexray.BridgeHostApi.$method",
        (message) async => null,
      );
    }
    reloadCalls.clear();
    for (final channel in forkReloadChannels) {
      binding.defaultBinaryMessenger.setMockMessageHandler(channel, (
        message,
      ) async {
        reloadCalls.add(channel);
        return null;
      });
    }
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      trayChannel,
      (call) async => null,
    );
  });

  tearDown(() async {
    for (final method in hostApiMethods) {
      binding.defaultBinaryMessenger.setMockMessageHandler(
        "dev.flutter.pigeon.onexray.BridgeHostApi.$method",
        null,
      );
    }
    for (final channel in forkReloadChannels) {
      binding.defaultBinaryMessenger.setMockMessageHandler(channel, null);
    }
    binding.defaultBinaryMessenger.setMockMethodCallHandler(trayChannel, null);
    await AppDatabase.resetAfterOpenFailure();
    PathProviderPlatform.instance = previousPaths;
    await tempDirectory.delete(recursive: true);
  });

  testWidgets('the root composes at 360x800 and mounts the connect shell', (
    tester,
  ) async {
    await _useHandsetViewport(tester);

    await tester.pumpWidget(const OneVpnApp());

    expect(find.byType(OneVpnShell), findsOneWidget);
    // The builder wraps the routed child in the shad theme and toaster.
    expect(find.byType(ShadToaster), findsOneWidget);
  });

  testWidgets('mounting the root sends nothing on the reload channels', (
    tester,
  ) async {
    await _useHandsetViewport(tester);

    // Positive control: the recorder intercepts reload traffic, so an
    // empty record below means no traffic and not a dead tap.
    expect(forkReloadChannels, hasLength(2));
    bool? supported;
    unawaited(
      OneVpnHandoverHost().reloadSupported().then((v) => supported = v),
    );
    await tester.pump();
    expect(supported, isFalse);
    expect(reloadCalls, [
      'dev.flutter.pigeon.onevpn.OneVpnHandoverHostApi.reloadSupported',
    ]);
    reloadCalls.clear();

    await tester.pumpWidget(const OneVpnApp());
    await tester.pump();
    await tester.pump();

    expect(find.byType(OneVpnShell), findsOneWidget);
    expect(reloadCalls, isEmpty);
  });

  testWidgets('the app title is 1VPN', (tester) async {
    await _useHandsetViewport(tester);

    await tester.pumpWidget(const OneVpnApp());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.title, "1VPN");
  });

  final rtlLocales = [
    for (final locale in kOneVpnLocales)
      if (locale.textDirection == TextDirection.rtl) locale.locale,
  ];

  test('the RTL fork locales include Farsi', () {
    expect(rtlLocales, contains(const Locale("fa")));
  });

  for (final locale in rtlLocales) {
    testWidgets('the ${locale.toLanguageTag()} locale resolves RTL under the '
        'app', (tester) async {
      await _useHandsetViewport(tester);
      tester.platformDispatcher.localeTestValue = locale;
      tester.platformDispatcher.localesTestValue = [locale];
      addTearDown(tester.platformDispatcher.clearLocaleTestValue);
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      await tester.pumpWidget(const OneVpnApp());
      // The choice starts on the system language. It passes a null app
      // locale, so the platform locale drives resolution. Extra pumps let the
      // stored language preference read land and rebuild.
      await tester.pump();
      await tester.pump();

      final navigatorContext = tester.element(find.byType(Navigator).first);
      // Anti-vacuity guard. The locale actually resolved as the app locale,
      // so the direction assertion tests the resolved locale and not a
      // fallback.
      expect(Localizations.localeOf(navigatorContext), locale);
      expect(Directionality.of(navigatorContext), TextDirection.rtl);
    });
  }

  // A system locale with no translations resolves to English and renders
  // left to right. Direction follows the resolved locale. Hebrew is an RTL
  // language the fork does not ship.
  testWidgets('an unsupported RTL system locale resolves to English '
      'and renders LTR', (tester) async {
    await _useHandsetViewport(tester);
    // Anti-vacuity guard. Hebrew is RTL and outside the fork list.
    expect(oneVpnTextDirection(const Locale("he")), TextDirection.rtl);
    expect(kOneVpnLocales.map((l) => l.tag), isNot(contains("he")));
    tester.platformDispatcher.localeTestValue = const Locale("he");
    tester.platformDispatcher.localesTestValue = const [Locale("he")];
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(const OneVpnApp());
    await tester.pump();
    await tester.pump();

    final navigatorContext = tester.element(find.byType(Navigator).first);
    expect(Localizations.localeOf(navigatorContext), const Locale("en"));
    expect(Directionality.of(navigatorContext), TextDirection.ltr);
  });

  testWidgets('app bar icons draw in the foreground color in both themes', (
    tester,
  ) async {
    await _useHandsetViewport(tester);

    await tester.pumpWidget(const OneVpnApp());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    for (final (theme, brightness) in [
      (app.theme!, Brightness.light),
      (app.darkTheme!, Brightness.dark),
    ]) {
      final foreground = OneVpnPalettes.tokens(brightness).palette.foreground;
      expect(theme.appBarTheme.iconTheme?.color, foreground);
      expect(theme.appBarTheme.actionsIconTheme?.color, foreground);
    }
  });

  // Theme metrics key on the shortest side. A landscape phone keeps the
  // mobile metrics, and a landscape tablet takes the desktop metrics.
  for (final (size, mobile) in const [
    (kLandscapeViewport, true),
    (kTabletLandscapeViewport, false),
  ]) {
    testWidgets('at ${size.width.toInt()}x${size.height.toInt()} the theme '
        'takes the ${mobile ? 'mobile' : 'desktop'} metrics', (tester) async {
      await setViewport(tester, size);

      await tester.pumpWidget(const OneVpnApp());

      double? spacing(bool mobile) => AppTheme.material(
        Brightness.light,
        mobile: mobile,
      ).appBarTheme.titleSpacing;
      // Anti-vacuity guard. The two metric sets differ on this value.
      expect(spacing(true), isNot(spacing(false)));
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.theme?.appBarTheme.titleSpacing, spacing(mobile));
      expect(app.darkTheme?.appBarTheme.titleSpacing, spacing(mobile));
    });
  }

  // The assertion fails when a delegate is added, removed, or reordered.
  // The fork delegate leads, then the upstream fallback delegate. The tail
  // is material_ui's global list, each in an English fallback.
  testWidgets('the localization delegate list is pinned', (tester) async {
    await _useHandsetViewport(tester);

    await tester.pumpWidget(const OneVpnApp());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final delegates = app.localizationsDelegates?.toList();
    expect(delegates, isNotNull);
    expect(delegates, hasLength(5));
    expect(delegates![0], OneVpnLocalizations.delegate);
    expect(delegates[1], const OneVpnUpstreamLocalizationsDelegate());
    expect(delegates, isNot(contains(AppLocalizations.delegate)));
    expect(delegates.sublist(2), [
      for (final builtIn in GlobalMaterialLocalizations.delegates)
        OneVpnEnglishFallbackDelegate(builtIn),
    ]);
  });
}
