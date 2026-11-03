import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/account/session.dart';
import 'package:onexray/onevpn/catalogue/catalogue.dart';
import 'package:onexray/onevpn/feedback/confirm_dialog.dart';
import 'package:onexray/onevpn/feedback/connection_actions.dart';
import 'package:onexray/onevpn/feedback/failure_message.dart';
import 'package:onexray/onevpn/feedback/notice.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations.dart';
import 'package:onexray/onevpn/location/flag.dart';
import 'package:onexray/onevpn/routing/direct_regions_apply.dart';
import 'package:onexray/onevpn/routing/direct_regions_controller.dart';
import 'package:onexray/onevpn/shell/close_app_bar.dart';
import 'package:onexray/onevpn/shell/connect_screen.dart';
import 'package:onexray/onevpn/shell/edge_dismiss.dart';
import 'package:onexray/onevpn/shell/layout.dart';
import 'package:onexray/onevpn/shell/routes.dart';
import 'package:onexray/onevpn/theme/backdrop.dart';
import 'package:onexray/onevpn/theme/card.dart';
import 'package:onexray/onevpn/theme/headline_card.dart';
import 'package:onexray/pages/theme/color.dart';
import 'package:onexray/pages/theme/font.dart';
import 'package:onexray/service/connect/routing/region_catalog.dart';
import 'package:onexray/service/connect/settings.dart';

/// The picker's region label for the ISO 3166 [code], in any letter case.
/// CN renders "China". Every other code takes its name from the fork
/// region-name table. An unknown code renders as itself.
String oneVpnDirectRegionLabel(OneVpnLocalizations l, String code) {
  final upper = code.toUpperCase();
  return upper == 'CN' ? l.onevpnRegionChina : l.onevpnCountryRegionName(upper);
}

/// The fork Direct-regions picker: the RC's only routing surface. It is
/// single-select. An outlined explainer card sits at the top and carries the
/// real-IP disclosure. A pinned Off (Default) row sits above the curated
/// region rows. Selecting Off (Default) tunnels everything. Selecting a
/// region routes that region direct, off-tunnel, from the user's real IP.
/// A fallback to Off, from no stored region or one the geodata dropped,
/// stores All via VPN.
///
/// The tapped row reads as selected at once. An applied choice keeps the page
/// open with the new row selected. A declined reconnect, a change that does
/// not apply, or a failed apply restores the previous row. A change that
/// does not apply and a failure outside the red state both show a notice.
/// The notice appears even after the page closes. A failure that lands in
/// the red state returns to the connect screen.
///
/// Stacked, the page caps at [OneVpnLayout.listCap]. The card keeps the card
/// margin on every side. It pins above the scrolling rows while it takes at
/// most half the body height. A taller card scrolls with the rows. Split, the
/// card fills the start pane and the rows start at the top of the end pane.
class OneVpnDirectRegionsPage extends StatefulWidget {
  const OneVpnDirectRegionsPage({
    super.key,
    this.loadCatalog,
    this.applyService,
    this.loadSelection,
  });

  /// Overrides the catalogue load in tests.
  final Future<RegionCatalog> Function()? loadCatalog;

  /// Overrides the apply service in tests.
  final OneVpnDirectRegionsApplyService? applyService;

  /// Overrides the stored-selection read in tests.
  final Future<String?> Function()? loadSelection;

  @override
  State<OneVpnDirectRegionsPage> createState() =>
      _OneVpnDirectRegionsPageState();
}

class _OneVpnDirectRegionsPageState extends State<OneVpnDirectRegionsPage> {
  OneVpnDirectRegionsApplyService? _lazyApply;
  OneVpnDirectRegionsController? _controller;
  bool _loading = true;
  bool _applying = false;

  OneVpnDirectRegionsApplyService get _apply =>
      widget.applyService ?? (_lazyApply ??= OneVpnDirectRegionsApplyService());

  OneVpnSession? get _session =>
      switch (OneVpnAccountService.instance.state.value) {
        OneVpnAccountSignedIn(:final session) => session,
        _ => null,
      };

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final selected = await (widget.loadSelection ?? _apply.currentSelection)();
    final controller = OneVpnDirectRegionsController(
      selected: selected,
      loadCatalog: widget.loadCatalog,
    );
    await controller.load();
    // A stored region the geodata no longer carries falls back to Off.
    if (selected != null && controller.selected == null) {
      await _apply.storeOff();
    }
    if (!mounted) return;
    setState(() {
      _controller = controller;
      _loading = false;
    });
  }

  Future<void> _choose(String? code, String label) async {
    final controller = _controller;
    if (controller == null || _applying) return;
    final previous = controller.selected;
    setState(() {
      if (code == null) {
        controller.selectAllViaVpn();
      } else {
        controller.selectRegion(code);
      }
      _applying = true;
    });
    final noticeTarget = OneVpnNoticeTarget.of(context);
    final l = OneVpnLocalizations.of(context)!;
    try {
      final coordinator = _apply.coordinator;
      final picked = (await coordinator.configuration).connection.selection;
      final outcome = await _apply.apply(
        regionCode: code,
        // The page can close while the reload runs. A closed page declines.
        confirmReconnect: () async =>
            mounted && await showOneVpnReconnectDialog(context, label: label),
      );
      switch (outcome) {
        case OneVpnDirectRegionsOutcome.applied:
          return;
        case OneVpnDirectRegionsOutcome.selectionReset:
          // A change can replace the picked location with Automatic. The
          // notice names the location picked before it.
          if (picked.kind != SelectionKind.automatic) {
            final city = OneVpnConnectRowLabel.cityOf(
              l,
              picked,
              OneVpnCatalogue.forSession(_session),
            );
            noticeTarget.info(
              city == null
                  ? l.onevpnSelectionResetUnnamed
                  : l.onevpnSelectionReset(city),
            );
          }
          return;
        case OneVpnDirectRegionsOutcome.unchanged:
          if (mounted) setState(() => controller.selected = previous);
        case OneVpnDirectRegionsOutcome.rolledBack:
          if (mounted) setState(() => controller.selected = previous);
          noticeTarget.error(l.onevpnReloadRolledBackSettings);
      }
    } catch (error) {
      if (mounted) setState(() => controller.selected = previous);
      if (await oneVpnFailureOnScreen(_apply.coordinator, _apply.held)) {
        // The red state carries the failure on the connect screen.
        if (mounted) context.go(kOneVpnConnectRoute);
        return;
      }
      noticeTarget.error(oneVpnConnectionFailureMessage(l, error: error));
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = OneVpnLocalizations.of(context)!;
    return OneVpnSnackBarAnchor(
      child: Scaffold(
        appBar: oneVpnCloseAppBar(context, l.onevpnDirectRegions),
        body: SafeArea(child: _body(context, l)),
      ),
    );
  }

  Widget _body(BuildContext context, OneVpnLocalizations l) {
    final controller = _controller;
    if (_loading || controller == null) {
      return const SizedBox.shrink();
    }
    final card = OneVpnHeadlineCard(
      icon: LucideIcons.info,
      body: l.onevpnDirectRegionsCardBody,
    );
    final tiles = _tiles(context, l, controller);
    if (OneVpnLayout.isSplit(context)) {
      return OneVpnAdaptiveBody(
        start: Padding(
          padding: const EdgeInsets.all(OneVpnCard.margin),
          child: card,
        ),
        end: Padding(
          padding: const EdgeInsets.fromLTRB(
            OneVpnCard.margin,
            OneVpnCard.margin,
            OneVpnCard.margin,
            8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: tiles,
          ),
        ),
        endAlignment: Alignment.topCenter,
      );
    }
    return OneVpnConstrainedBody(
      maxWidth: OneVpnLayout.listCap,
      child: CustomScrollView(
        controller: OneVpnEdgeScope.scrollControllerOf(context),
        slivers: [
          _OneVpnCardSliver(
            child: ColoredBox(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Padding(
                padding: const EdgeInsets.all(OneVpnCard.margin),
                child: card,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              OneVpnCard.margin,
              0,
              OneVpnCard.margin,
              8,
            ),
            sliver: SliverList.list(children: tiles),
          ),
        ],
      ),
    );
  }

  /// The pinned Off (Default) row over the curated region rows.
  List<Widget> _tiles(
    BuildContext context,
    OneVpnLocalizations l,
    OneVpnDirectRegionsController controller,
  ) => [
    _tile(
      context,
      selected: controller.selected == null,
      title: l.onevpnDirectRegionsOff,
      subtitle: l.onevpnAllViaVpnSubtitle,
      leadingIcon: LucideIcons.globe,
      onTap: () => _choose(null, l.onevpnDirectRegionsOff),
    ),
    for (final code in controller.codes)
      _tile(
        context,
        selected: controller.selected == code,
        title: oneVpnDirectRegionLabel(l, code),
        code: code,
        onTap: () => _choose(code, oneVpnDirectRegionLabel(l, code)),
      ),
  ];

  /// A region row. It leads with the [code] on a flag-sized square, or
  /// [leadingIcon] when there is no code, in a flag-sized slot. While a change
  /// applies, the selected row's check announces the update to screen readers.
  /// Screen readers hear the rows as one group with the [selected] row
  /// selected.
  Widget _tile(
    BuildContext context, {
    required bool selected,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
    String? code,
    IconData? leadingIcon,
  }) {
    final palette = ColorManager.palette(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        container: true,
        selected: selected,
        inMutuallyExclusiveGroup: true,
        child: Material(
          animationDuration: Duration.zero,
          color: selected ? palette.selectedSurface : palette.card,
          borderRadius: BorderRadius.circular(OneVpnCard.radius),
          child: InkWell(
            borderRadius: BorderRadius.circular(OneVpnCard.radius),
            highlightColor: Colors.transparent,
            splashFactory: OneVpnCard.noSplash,
            onTap: _applying ? null : onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(OneVpnCard.radius),
                border: Border.all(
                  color: selected ? palette.primary : palette.border,
                  width: OneVpnCard.outline,
                ),
              ),
              padding: OneVpnCard.padding,
              child: Row(
                children: [
                  // One fixed leading slot, so every title starts at one x.
                  SizedBox(
                    width: OneVpnFlag.defaultSize,
                    child: Center(
                      child: code != null
                          ? OneVpnBackdropSquare(
                              color: palette.muted,
                              border: palette.border,
                              // One line, scaled down to fit the square.
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  code,
                                  maxLines: 1,
                                  softWrap: false,
                                  style: AppTypography.routingRegionCode,
                                ),
                              ),
                            )
                          : Icon(leadingIcon, color: palette.mutedForeground),
                    ),
                  ),
                  const SizedBox(width: OneVpnCard.leadingGap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppTypography.settingsRow),
                        if (subtitle != null) ...[
                          Text(
                            subtitle,
                            style: AppTypography.settingsValueLabel.copyWith(
                              color: palette.mutedForeground,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (selected)
                    Semantics(
                      container: true,
                      liveRegion: _applying,
                      label: _applying
                          ? OneVpnLocalizations.of(context)!
                                .onevpnStatusUpdating
                          : null,
                      child: Icon(LucideIcons.check, color: palette.primary),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Holds the card at the top of the scroll view while the card takes at most
/// half the viewport height. A taller card scrolls away with the rows.
class _OneVpnCardSliver extends SingleChildRenderObjectWidget {
  const _OneVpnCardSliver({required Widget super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderOneVpnCardSliver();
}

class _RenderOneVpnCardSliver extends RenderSliverSingleBoxAdapter {
  bool _pinned = false;

  @override
  double childMainAxisPosition(RenderBox child) =>
      _pinned ? 0 : -constraints.scrollOffset;

  @override
  void performLayout() {
    final child = this.child!;
    child.layout(constraints.asBoxConstraints(), parentUsesSize: true);
    final extent = child.size.height;
    _pinned = extent <= constraints.viewportMainAxisExtent / 2;
    if (!_pinned) {
      final painted = calculatePaintOffset(constraints, from: 0, to: extent);
      geometry = SliverGeometry(
        scrollExtent: extent,
        paintExtent: painted,
        maxPaintExtent: extent,
        hitTestExtent: painted,
        cacheExtent: calculateCacheOffset(constraints, from: 0, to: extent),
        hasVisualOverflow:
            extent > constraints.remainingPaintExtent ||
            constraints.scrollOffset > 0,
      );
      setChildParentData(child, constraints, geometry!);
      return;
    }
    geometry = SliverGeometry(
      scrollExtent: extent,
      paintOrigin: constraints.overlap,
      paintExtent: math.min(
        extent,
        constraints.remainingPaintExtent - constraints.overlap,
      ),
      layoutExtent: clampDouble(
        extent - constraints.scrollOffset,
        0,
        constraints.remainingPaintExtent,
      ),
      maxPaintExtent: extent,
      maxScrollObstructionExtent: extent,
      cacheExtent: calculateCacheOffset(constraints, from: 0, to: extent),
      hasVisualOverflow: true,
    );
    (child.parentData! as SliverPhysicalParentData).paintOffset = Offset.zero;
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    // A pinned card stays on screen while the rows scroll beneath it.
    if (_pinned && (geometry?.layoutExtent ?? 0) < child!.size.height) {
      config.addTagForChildren(RenderViewport.excludeFromScrolling);
    }
  }
}
