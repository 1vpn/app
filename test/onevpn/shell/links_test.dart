// The hosted-page handoff opens in the platform browser view where one
// exists, so closing it returns to the app. It opens the external browser
// when the platform has no browser view or the view fails. It never
// requests an app webview.
//
// Each tap resolves the page onto the domain the account API reached. The
// page constant stands when the read fails or names a foreign host. A page
// off the 1vpn domains opens as given.

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/l10n/localizations/app_localizations.dart';
import 'package:onexray/onevpn/net/api_transport.dart';
import 'package:onexray/onevpn/net/failover_domains.dart';
import 'package:onexray/onevpn/shell/links.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:url_launcher_platform_interface/link.dart';
// ignore: depend_on_referenced_packages
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../support/localizations.dart';

/// Records each launch request and answers with the configured outcome.
class _FakeLauncher extends UrlLauncherPlatform {
  _FakeLauncher({
    required this.browserViewSupported,
    this.browserViewOpens = true,
    this.browserViewThrows = false,
  });

  final bool browserViewSupported;
  final bool browserViewOpens;
  final bool browserViewThrows;
  final launches = <(String, PreferredLaunchMode)>[];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> supportsMode(PreferredLaunchMode mode) async =>
      mode == PreferredLaunchMode.inAppBrowserView
      ? browserViewSupported
      : mode == PreferredLaunchMode.externalApplication;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launches.add((url, options.mode));
    if (options.mode == PreferredLaunchMode.inAppBrowserView) {
      if (browserViewThrows) {
        throw PlatformException(code: 'ACTIVITY_NOT_FOUND');
      }
      return browserViewOpens;
    }
    return true;
  }
}

/// A transport with a scripted active base. A null base fails the read.
class _ScriptedTransport extends OneVpnApiTransport {
  _ScriptedTransport(this.base);

  final String? base;

  @override
  Future<String> activeBaseUrl() async => base ?? (throw StateError('no base'));
}

/// The seven hosted pages.
final _pages = [
  OneVpnLinks.passwordReset,
  OneVpnLinks.faq,
  OneVpnLinks.termsOfService,
  OneVpnLinks.privacyPolicy,
  OneVpnLinks.contactUs,
  OneVpnLinks.refundPolicy,
  OneVpnLinks.account,
];

final _uri = Uri.parse('https://1vpn.org/faq');

Future<void> _open(
  WidgetTester tester,
  _FakeLauncher launcher, [
  Uri? uri,
]) async {
  final previous = UrlLauncherPlatform.instance;
  UrlLauncherPlatform.instance = launcher;
  addTearDown(() => UrlLauncherPlatform.instance = previous);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: oneVpnLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => openExternalLink(context, uri ?? _uri),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a supported browser view opens the page once, in the view', (
    tester,
  ) async {
    final launcher = _FakeLauncher(browserViewSupported: true);
    await _open(tester, launcher);
    expect(launcher.launches, [
      ('$_uri', PreferredLaunchMode.inAppBrowserView),
    ]);
  });

  testWidgets('no browser view opens the external browser directly', (
    tester,
  ) async {
    final launcher = _FakeLauncher(browserViewSupported: false);
    await _open(tester, launcher);
    expect(launcher.launches, [
      ('$_uri', PreferredLaunchMode.externalApplication),
    ]);
  });

  testWidgets('a browser view that declines falls back to external', (
    tester,
  ) async {
    final launcher = _FakeLauncher(
      browserViewSupported: true,
      browserViewOpens: false,
    );
    await _open(tester, launcher);
    expect(launcher.launches, [
      ('$_uri', PreferredLaunchMode.inAppBrowserView),
      ('$_uri', PreferredLaunchMode.externalApplication),
    ]);
  });

  testWidgets('a browser view that throws falls back to external', (
    tester,
  ) async {
    final launcher = _FakeLauncher(
      browserViewSupported: true,
      browserViewThrows: true,
    );
    await _open(tester, launcher);
    expect(launcher.launches, [
      ('$_uri', PreferredLaunchMode.inAppBrowserView),
      ('$_uri', PreferredLaunchMode.externalApplication),
    ]);
  });

  testWidgets('no launch ever requests an app webview', (tester) async {
    for (final supported in [true, false]) {
      final launcher = _FakeLauncher(
        browserViewSupported: supported,
        browserViewOpens: false,
      );
      await _open(tester, launcher);
      expect(
        launcher.launches.map((launch) => launch.$2),
        isNot(contains(PreferredLaunchMode.inAppWebView)),
      );
    }
  });

  group('a hosted page resolves onto the active domain', () {
    test('every page follows each change of the active domain', () async {
      final memory = OneVpnEphemeralDomainMemory();
      final transport = OneVpnApiTransport(memory: memory);
      Future<String> resolved(Uri page) async =>
          '${await OneVpnLinks.resolve(page, transport: transport)}';

      for (final domain in OneVpnFailoverDomains.all.reversed) {
        await memory.write(domain);
        for (final page in _pages) {
          expect(
            await resolved(page),
            '$page'.replaceFirst('https://1vpn.org/', 'https://$domain/'),
          );
        }
      }
      await memory.write('cloudlogcdn.com');
      expect(
        await resolved(OneVpnLinks.passwordReset),
        'https://cloudlogcdn.com/password-reset-request/',
      );
      expect(await resolved(OneVpnLinks.faq), 'https://cloudlogcdn.com/#faq');
    });

    test('with no remembered domain every page is its constant', () async {
      final transport = OneVpnApiTransport(
        memory: OneVpnEphemeralDomainMemory(),
      );
      for (final page in _pages) {
        expect(await OneVpnLinks.resolve(page, transport: transport), page);
      }
    });

    test('a failed read falls back to the constant', () async {
      final transport = _ScriptedTransport(null);
      for (final page in _pages) {
        expect(await OneVpnLinks.resolve(page, transport: transport), page);
      }
    });

    test(
      'a base outside the failover domains falls back to the constant',
      () async {
        for (final base in const [
          'https://mirror.example.com',
          'https://1vpn.co.example.com',
          'http://1vpn.co',
          '',
        ]) {
          final transport = _ScriptedTransport(base);
          for (final page in _pages) {
            expect(
              await OneVpnLinks.resolve(page, transport: transport),
              page,
              reason: base,
            );
          }
        }
      },
    );

    test('a page off the 1vpn domains stays as given', () async {
      final transport = _ScriptedTransport('https://1vpn.co');
      expect(
        await OneVpnLinks.resolve(
          OneVpnStoreLinks.playSubscriptions,
          transport: transport,
        ),
        OneVpnStoreLinks.playSubscriptions,
      );
    });

    testWidgets('each tap opens the page on the domain active at that tap', (
      tester,
    ) async {
      final previous = SharedPreferencesAsyncPlatform.instance;
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      addTearDown(() => SharedPreferencesAsyncPlatform.instance = previous);
      const memory = OneVpnPrefsDomainMemory();
      final launcher = _FakeLauncher(browserViewSupported: true);

      await memory.write('1vpn.co');
      await _open(tester, launcher, OneVpnLinks.account);
      await memory.write('cloudlogcdn.com');
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(launcher.launches.map((launch) => launch.$1), [
        'https://1vpn.co/account/',
        'https://cloudlogcdn.com/account/',
      ]);
    });
  });

  test('the manifest makes Custom Tabs providers visible', () {
    // Required on API 30+: package visibility hides providers no query names.
    // The browser view then reports unsupported on every device.
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    expect(
      manifest,
      contains(
        '<action android:name='
        '"android.support.customtabs.action.CustomTabsService" />',
      ),
    );
  });
}
