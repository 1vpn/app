// The geosite categories a refreshed list must carry before it replaces the
// installed one.

import 'package:onexray/core/model/geo_dat.dart';
import 'package:onexray/core/tools/logger.dart';
import 'package:onexray/service/connect/compiler.dart';
import 'package:onexray/service/connect/routing/region_catalog.dart';
import 'package:onexray/service/connect/settings.dart';

/// The geosite categories a refreshed list must carry, upper case.
///
/// The set is every geosite category in the compiler's smart rules with the
/// direct toggles on, ad blocking off and no direct region. It holds no
/// region code. The compiler names a region code only when the installed
/// index carries it.
final Set<String> kOneVpnRequiredGeositeCategories = {
  for (final rule in ConnectionCompiler.smartRules(
    SmartRoutingSettings(
      directPrivate: true,
      directApple: true,
      directWindows: true,
      blockAds: false,
    ),
    const RegionCatalog.empty(),
  ))
    for (final domain in rule.domain ?? const <String>[])
      if (domain.startsWith('geosite:'))
        domain.substring('geosite:'.length).toUpperCase(),
};

/// Throws a [FormatException] when [index] lacks a required category.
///
/// [index] is the category index of a downloaded geosite list. A category
/// counts when its code matches in any case and it holds at least one rule.
/// A refusal logs the missing names.
void oneVpnCheckGeositeCategories(XrayGeoList index) {
  final present = {
    for (final code in RegionCatalog.codesFromIndex(index.toJson()))
      code.toUpperCase(),
  };
  final missing = kOneVpnRequiredGeositeCategories.difference(present).toList()
    ..sort();
  if (missing.isEmpty) return;
  ygLogger(
    'OneVpnGeoData: refused geosite list, missing ${missing.join(', ')}',
  );
  throw const FormatException('Geosite list lacks a required category');
}
