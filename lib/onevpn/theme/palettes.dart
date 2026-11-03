// The fork palettes, built from upstream's AppPalette instances.
//
// Every field forwards from the upstream instance. The blue family reads
// the brand.dart ramp instead. Listing every field is the contract: an
// upstream field addition fails to compile here until it is reconciled.

import 'package:material_ui/material_ui.dart';
import 'package:onexray/onevpn/theme/brand.dart';
import 'package:onexray/pages/theme/color.dart';

/// The fork light and dark palettes and their color tokens.
abstract final class OneVpnPalettes {
  static final AppPalette light = _fork(
    AppPalette.light,
    readable: OneVpnBrand.primary,
    readableHover: OneVpnBrand.brandBlueHover,
  );
  static final AppPalette dark = _fork(
    AppPalette.dark,
    readable: OneVpnBrand.brandBlueLight,
    readableHover: OneVpnBrand.brandBlueLightHover,
  );

  static final AppColorTokens lightTokens = AppColorTokens(light);
  static final AppColorTokens darkTokens = AppColorTokens(dark);

  /// The tokens for [brightness].
  static AppColorTokens tokens(Brightness brightness) =>
      brightness == Brightness.light ? lightTokens : darkTokens;

  /// [base] with its blue family replaced by the brand ramp. [readable] is
  /// the blue for text, icons, and rings on this theme's ground. Solid fills
  /// read [OneVpnBrand.primary] in both themes. The accent tints forward.
  static AppPalette _fork(
    AppPalette base, {
    required Color readable,
    required Color readableHover,
  }) => AppPalette(
    background: base.background,
    foreground: base.foreground,
    card: base.card,
    cardForeground: base.cardForeground,
    popover: base.popover,
    popoverForeground: base.popoverForeground,
    primary: readable,
    primaryHover: readableHover,
    primarySolid: OneVpnBrand.primary,
    primarySolidHover: OneVpnBrand.brandBlueHover,
    primaryForeground: base.primaryForeground,
    surfaceHover: base.surfaceHover,
    secondary: base.secondary,
    secondaryForeground: base.secondaryForeground,
    muted: base.muted,
    mutedForeground: base.mutedForeground,
    mutedStrong: base.mutedStrong,
    accent: base.accent,
    accentForeground: readable,
    destructive: base.destructive,
    destructiveSolid: base.destructiveSolid,
    destructiveSolidHover: base.destructiveSolidHover,
    destructiveForeground: base.destructiveForeground,
    border: base.border,
    borderStrong: base.borderStrong,
    input: base.input,
    ring: readable,
    selection: base.selection,
    scannerBackground: base.scannerBackground,
    overlay: base.overlay,
    header: base.header,
    brand: base.brand,
    sidebar: base.sidebar,
    sidebarForeground: base.sidebarForeground,
    sidebarPrimary: readable,
    sidebarPrimaryForeground: base.sidebarPrimaryForeground,
    sidebarAccent: base.sidebarAccent,
    sidebarAccentForeground: base.sidebarAccentForeground,
    sidebarBorder: base.sidebarBorder,
    sidebarRing: readable,
    selectedSurface: base.selectedSurface,
    running: base.running,
    runningText: base.runningText,
    runningBadge: base.runningBadge,
    runningBadgeForeground: base.runningBadgeForeground,
    runningForeground: base.runningForeground,
    runningSurface: base.runningSurface,
    restarting: base.restarting,
    restartingText: base.restartingText,
    warningSurface: base.warningSurface,
    destructiveSurface: base.destructiveSurface,
    chart1: base.chart1,
    chart2: base.chart2,
    chart3: base.chart3,
    chart4: base.chart4,
    chart5: base.chart5,
  );
}
