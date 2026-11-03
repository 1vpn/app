import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/onevpn/app/channel_deadlines.dart';
import 'package:onexray/onevpn/l10n/locale_choice.dart';
import 'package:onexray/onevpn/l10n/locales.dart';
import 'package:onexray/onevpn/l10n/upstream_delegate.dart';
import 'package:onexray/onevpn/shell/layout.dart';
import 'package:onexray/onevpn/shell/router.dart';
import 'package:onexray/onevpn/theme/card.dart';
import 'package:onexray/pages/theme/color.dart';
import 'package:onexray/pages/theme/layout.dart';
import 'package:onexray/pages/theme/theme.dart';
import 'package:onexray/service/shared/event_bus/service.dart';
import 'package:onexray/service/shared/event_bus/state.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// The 1vpn root widget. It mounts the fork router, which serves the one-screen
/// shell on every platform. It builds the router-driven MaterialApp with the
/// responsive theme and the fork locale policy. The supported locales are
/// [kOneVpnLocales], resolved by [oneVpnResolveLocale]. The [OneVpnLocaleChoice]
/// above the app supplies the locale. A system choice passes a null locale so
/// the platform locale resolves. The builder wraps the routed child in a
/// Directionality from the resolved locale. Arabic and Farsi then render right
/// to left.
///
/// Constructing [AppEventBus] here satisfies the static late
/// AppEventBus.instance global. Nothing before runApp may touch it. The bus
/// starts the stored-theme read on construction. The shell then renders in the
/// stored theme without a splash step.
class OneVpnApp extends StatelessWidget {
  const OneVpnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AppEventBus()..asyncInitTheme()),
        BlocProvider(create: (_) => OneVpnLocaleChoice()..load()),
      ],
      child: BlocBuilder<AppEventBus, AppEventBusState>(
        builder: (context, state) => BlocBuilder<OneVpnLocaleChoice, String?>(
          builder: (context, _) => _buildApp(
            context,
            state,
            context.read<OneVpnLocaleChoice>().locale,
          ),
        ),
      ),
    );
  }

  /// The upstream material theme with the fork app bar and the fork notice
  /// placement. App bar icons draw in the foreground color. Notices float
  /// at the card margin.
  static ThemeData _material(Brightness brightness, {required bool mobile}) {
    final theme = AppTheme.material(brightness, mobile: mobile);
    final palette = theme.extension<AppColorTokens>()!.palette;
    final icons = IconThemeData(color: palette.foreground);
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        toolbarHeight: OneVpnLayout.appBarHeight,
        iconTheme: icons,
        actionsIconTheme: icons,
      ),
      snackBarTheme: theme.snackBarTheme.copyWith(
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.fromLTRB(
          OneVpnCard.margin,
          0,
          OneVpnCard.margin,
          OneVpnCard.margin,
        ),
      ),
    );
  }

  Widget _buildApp(
    BuildContext context,
    AppEventBusState state,
    Locale? locale,
  ) {
    final supportedLocales = [for (final l in kOneVpnLocales) l.locale];
    return LayoutBuilder(
      builder: (context, constraints) {
        // Mobile metrics apply while the shortest side is at most
        // AppLayout.mobileBreakpoint. A phone keeps them in landscape.
        final mobile =
            constraints.biggest.shortestSide <= AppLayout.mobileBreakpoint;
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: "1VPN",
          themeMode: state.themeCode.themeMode,
          theme: _material(Brightness.light, mobile: mobile),
          darkTheme: _material(Brightness.dark, mobile: mobile),
          routerConfig: OneVpnRouter.router,
          scrollBehavior: const OneVpnScrollBehavior(),
          locale: locale,
          localizationsDelegates: kOneVpnLocalizationsDelegates,
          supportedLocales: supportedLocales,
          localeResolutionCallback: oneVpnResolveLocale,
          builder: (context, child) {
            final routedChild = Directionality(
              textDirection: oneVpnTextDirection(
                Localizations.localeOf(context),
              ),
              child: child ?? const SizedBox.shrink(),
            );
            final brightness = Theme.of(context).brightness;
            return ShadTheme(
              data: AppTheme.shad(
                brightness,
                mobile: mobile,
                textScaler: MediaQuery.textScalerOf(context),
              ),
              child: ShadToaster(child: routedChild),
            );
          },
        );
      },
    );
  }
}

/// The 1vpn widgets binding. Its default messenger is a
/// [ChannelDeadlineMessenger]. A bounded bridge host call that gets no reply
/// fails at its [ChannelDeadlines] bound.
class OneVpnBinding extends WidgetsFlutterBinding {
  OneVpnBinding._();

  static OneVpnBinding? _instance;

  @override
  BinaryMessenger createBinaryMessenger() =>
      ChannelDeadlineMessenger(super.createBinaryMessenger());

  /// Returns the binding. The first call creates the [OneVpnBinding].
  ///
  /// Must run before any other binding initializes. A process holds one
  /// binding, and an earlier one keeps the unbounded messenger.
  static WidgetsBinding ensureInitialized() {
    _instance ??= OneVpnBinding._();
    return WidgetsBinding.instance;
  }
}
