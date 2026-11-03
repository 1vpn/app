// A location change that lands after the picker starts closing pops nothing
// more. The connect screen under the picker stays.

import 'dart:async';

import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/core/db/database/database.dart';
import 'package:onexray/core/pigeon/messages.g.dart';
import 'package:onexray/l10n/localizations/app_localizations.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/app/held_tunnel.dart';
import 'package:onexray/onevpn/location/location_picker_page.dart';
import 'package:onexray/onevpn/shell/routes.dart';
import 'package:onexray/pages/theme/theme.dart';
import 'package:onexray/service/connect/coordinator.dart';
import 'package:onexray/service/connect/runtime.dart';
import 'package:onexray/service/connect/runtime_host.dart';
import 'package:onexray/service/connect/settings.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/localizations.dart';
import '../support/viewports.dart';

/// A disconnected coordinator whose apply waits on [applyGate].
class _GatedCoordinator extends ConnectionCoordinator {
  _GatedCoordinator(AppDatabase db)
    : super(
        database: db,
        inspect: (_) async => const HostConnection(VpnStatus.disconnected),
        readRuntime: () async => null,
        statusEvents: const Stream.empty(),
        observeStatus: () async {},
        disposeStatus: () {},
      );

  final applyGate = Completer<void>();

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
    await applyGate.future;
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

void main() {
  testWidgets('an apply that lands while the picker closes leaves the '
      'connect screen', (tester) async {
    final db = AppDatabase.forTesting(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    addTearDown(db.close);
    await setViewport(tester, kPortraitViewport);
    final coordinator = _GatedCoordinator(db);
    addTearDown(coordinator.dispose);
    await coordinator.initialize(observe: false);

    const connectKey = ValueKey('connect-screen');
    final router = GoRouter(
      initialLocation: kOneVpnConnectRoute,
      routes: [
        GoRoute(
          path: kOneVpnConnectRoute,
          builder: (_, _) => const Scaffold(key: connectKey),
        ),
        GoRoute(
          path: kOneVpnLocationRoute,
          builder: (_, _) => OneVpnLocationPickerPage(
            accountState: ValueNotifier(const OneVpnAccountSignedOut()),
            serversStream: Stream.value([
              _node('1vpn·free·ams·1', 1),
              _node('1vpn·free·sgp·1', 2),
              _node('1vpn·free·lax·1', 3),
            ]),
            selectionStream: const Stream.empty(),
            initialSelection: const ServerSelection.automatic(),
            coordinator: coordinator,
            heldTunnel: OneVpnHeldTunnel(
              read: () async => false,
              supported: true,
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
        builder: (context, child) => ShadTheme(
          data: AppTheme.shad(Brightness.light),
          child: ShadToaster(child: child!),
        ),
        routerConfig: router,
      ),
    );
    Future<void> settle() async {
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
    }

    unawaited(router.push(kOneVpnLocationRoute));
    await settle();
    await tester.tap(find.text('Amsterdam'));
    await settle();
    expect(find.byType(OneVpnLocationPickerPage), findsOneWidget);

    // The close lands while the apply is in flight. The apply completes
    // inside the close transition, with the picker still mounted.
    await tester.tap(find.byType(CloseButton));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(OneVpnLocationPickerPage), findsOneWidget);
    coordinator.applyGate.complete();
    await tester.pump();
    await tester.pump();
    await settle();

    expect(tester.takeException(), isNull);
    expect(find.byType(OneVpnLocationPickerPage), findsNothing);
    expect(find.byKey(connectKey), findsOneWidget);
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      kOneVpnConnectRoute,
    );
  });
}
