import 'package:onexray/service/connect/routing/custom/geodata_suggestions.dart';
import 'package:onexray/service/connect/routing/region_catalog.dart';

/// The Direct-regions picker's state, independent of the widget. The rows are
/// the geosite-overlay codes installed geodata carries, in the fork pin order.
/// A null selection is All via VPN, the pinned top row.
class OneVpnDirectRegionsController {
  OneVpnDirectRegionsController({this.selected, this.loadCatalog});

  /// Overrides the catalogue load in tests.
  final Future<RegionCatalog> Function()? loadCatalog;

  /// The selected region code. Null selects All via VPN.
  String? selected;

  List<String> _codes = const [];
  bool _busy = true;
  bool _failed = false;

  List<String> get codes => _codes;
  bool get busy => _busy;
  bool get failed => _failed;

  /// The fork row order. The curated codes render in this order. A derived
  /// code that is not pinned follows them, in derivation order.
  static const _pinOrder = ['CN', 'RU', 'IR', 'TM'];

  /// The rows: the geosite-overlay codes present in installed geodata, in the
  /// fork pin order. The public [RegionCatalog.domainRules] filter derives
  /// them. A code with no overlay yields an empty rule list and drops. The
  /// geoip union is never a row.
  static List<String> curatedCodes(RegionCatalog catalog) {
    final present = catalog.regionCodes
        .where((code) => catalog.domainRules([code]).isNotEmpty)
        .toList();
    return [
      for (final code in _pinOrder)
        if (present.contains(code)) code,
      for (final code in present)
        if (!_pinOrder.contains(code)) code,
    ];
  }

  /// Loads the catalogue and derives the rows. A selection no longer in the
  /// rows falls back to All via VPN.
  Future<void> load() async {
    _busy = true;
    _failed = false;
    try {
      final catalog =
          await (loadCatalog?.call() ??
              RoutingGeodataIndex.load().then(
                (index) => index.regionCatalog(),
              ));
      _codes = curatedCodes(catalog);
      if (selected != null && !_codes.contains(selected)) selected = null;
    } catch (_) {
      _failed = true;
    } finally {
      _busy = false;
    }
  }

  void selectRegion(String code) {
    if (_codes.contains(code)) selected = code;
  }

  void selectAllViaVpn() => selected = null;
}
