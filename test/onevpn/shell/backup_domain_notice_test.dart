// The connect screen's backup-domain line. It renders nothing on the primary
// domain, and one muted text button naming the bare host on a backup. The
// locale's string places the host, isolated in the right-to-left locales. A
// tap opens the backup domain's home page. It follows the live value. The
// connect screen places it at the foot, under the location row and the
// upgrade banner, in both layouts.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations.dart';
import 'package:onexray/onevpn/shell/backup_domain_notice.dart';
import 'package:onexray/pages/theme/color.dart';
import 'package:onexray/pages/theme/theme.dart';

void main() {
  final text = find.byKey(OneVpnBackupDomainNotice.textKey);

  late List<Uri> opened;

  setUp(() => opened = []);

  Future<void> pump(WidgetTester tester, ValueListenable<String?> backup) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: OneVpnLocalizations.localizationsDelegates,
          supportedLocales: OneVpnLocalizations.supportedLocales,
          home: Scaffold(
            body: Column(
              children: [
                OneVpnBackupDomainNotice(
                  backupDomain: backup,
                  open: (_, uri) async => opened.add(uri),
                ),
              ],
            ),
          ),
        ),
      );

  testWidgets('renders nothing on the primary domain', (tester) async {
    await pump(tester, ValueNotifier<String?>(null));

    expect(text, findsNothing);
    expect(tester.getSize(find.byType(OneVpnBackupDomainNotice)).height, 0);
  });

  testWidgets('reads the localized line with the bare host as a muted text '
      'button', (tester) async {
    await pump(tester, ValueNotifier<String?>('1vpn.co'));

    expect(
      tester.widget<Text>(text).data,
      'Main domain is unreachable. Using backup: 1vpn.co',
    );
    final button = find.byType(TextButton);
    final style = tester.widget<TextButton>(button).style!;
    expect(
      style.foregroundColor?.resolve({}),
      ColorManager.palette(tester.element(button)).mutedForeground,
    );
  });

  test('the right-to-left locales isolate the host', () {
    const host = '1vpn.co';
    for (final code in ['fa', 'ar', 'ur']) {
      final line = lookupOneVpnLocalizations(Locale(code))
          .onevpnBackupDomainBlocked(host);
      expect(line, endsWith('\u2066$host\u200e\u2069'), reason: code);
    }
  });

  testWidgets('a tap opens the backup domain', (tester) async {
    await pump(tester, ValueNotifier<String?>('1vpn.co'));

    await tester.tap(text);
    await tester.pump();

    expect(opened, [Uri.parse('https://1vpn.co/')]);
  });

  testWidgets('follows the live value', (tester) async {
    final backup = ValueNotifier<String?>(null);
    await pump(tester, backup);
    expect(text, findsNothing);

    backup.value = 'onevpn.com';
    await tester.pump();
    expect(tester.widget<Text>(text).data, endsWith('onevpn.com'));

    backup.value = null;
    await tester.pump();
    expect(text, findsNothing);
  });

  test('the connect screen places it under the location row and the upgrade '
      'banner, both layouts', () {
    final source = File('lib/onevpn/shell/connect_screen.dart')
        .readAsStringSync()
        .replaceAll(RegExp(r'\s+'), ' ');
    expect(
      '_row(l, palette), _banner(l, palette), '
              'const OneVpnBackupDomainNotice(),'
          .allMatches(source)
          .length,
      2,
    );
  });
}
