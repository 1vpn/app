// Where the node list comes from.
//
// Two sources share one shape. The free tier is compiled in
// ([kOneVpnFreeCatalogue]). Premium comes from the account API on the persisted
// session. Both are [OneVpnApiLocation] lists. Both map to the domain model
// through [OneVpnLocation.fromApi], so no downstream code knows the source.
//
// The tier decision lives only in [OneVpnCatalogue].

import 'package:onexray/onevpn/account/session.dart';
import 'package:onexray/onevpn/catalogue/catalogue.dart';
import 'package:onexray/onevpn/catalogue/location.dart';

abstract interface class OneVpnNodeCatalog {
  Future<List<OneVpnLocation>> locations();
}

/// Maps the catalogue onto the domain model, giving every location a code that
/// is unique within its tier.
///
/// [OneVpnLocation.fromApi] derives the code as `cityCode ?? countryCode`, and
/// `cityCode` is nullable on the wire. Two account locations in one country
/// with no cityCode then share a code and a row name. The later one takes a
/// numeric suffix, starting at `-2`. Only an actual collision adds a suffix,
/// so ordinary catalogues keep their plain codes. A suffixed code has no
/// translation and falls back to the server-sent name.
///
/// The tier is part of the key because free and account entries may share a
/// code. The free Amsterdam and the account's Amsterdam are different hosts.
/// [OneVpnLocation.rowName] already separates them by tier.
List<OneVpnLocation> _toDomain(List<OneVpnCatalogueEntry> entries) =>
    List<OneVpnLocation>.unmodifiable(
      oneVpnCatalogueDomainPairs(entries).map((pair) => pair.location),
    );

/// A catalogue entry paired with the domain location the provisioner derives
/// for it.
typedef OneVpnCatalogueDomainPair = ({
  OneVpnCatalogueEntry entry,
  OneVpnLocation location,
});

/// Pairs each catalogue entry with its domain location, codes disambiguated
/// exactly as the provisioner names its rows.
///
/// The location picker keys provisioned rows on the paired location's
/// [OneVpnLocation.rowNameStem]. It must see the provisioner's
/// disambiguation. Both therefore derive the stem from this function, not
/// from the raw wire code.
List<OneVpnCatalogueDomainPair> oneVpnCatalogueDomainPairs(
  List<OneVpnCatalogueEntry> entries,
) {
  final taken = <String>{};
  final out = <OneVpnCatalogueDomainPair>[];
  for (final entry in entries) {
    final mapped = OneVpnLocation.fromApi(
      entry.location,
      freeTier: entry.freeTier,
    );
    final tier = entry.freeTier ? 'free' : 'acct';
    var code = mapped.code;
    for (var n = 2; !taken.add('$tier·$code'); n++) {
      code = '${mapped.code}-$n';
    }
    final location = code == mapped.code
        ? mapped
        : OneVpnLocation(
            code: code,
            city: mapped.city,
            country: mapped.country,
            countryCode: mapped.countryCode,
            servers: mapped.servers,
            premium: mapped.premium,
            freeTier: mapped.freeTier,
          );
    out.add((entry: entry, location: location));
  }
  return List<OneVpnCatalogueDomainPair>.unmodifiable(out);
}

/// The free tier, all 33 entries.
///
/// The list includes the 30 teasers, which have no servers. They map to
/// `servers: []`, so the provisioner walks past them with no special case.
/// The free branch never filters them out. See [OneVpnCatalogue].
class OneVpnStaticCatalog implements OneVpnNodeCatalog {
  const OneVpnStaticCatalog();

  @override
  Future<List<OneVpnLocation>> locations() async =>
      _toDomain(OneVpnCatalogue.forSession(null).entries);
}

/// The catalogue an actual account sees: premium's own locations when there
/// are any, the free list otherwise.
class OneVpnSessionCatalog implements OneVpnNodeCatalog {
  const OneVpnSessionCatalog(this.session);

  final OneVpnSession? session;

  OneVpnCatalogue get catalogue => OneVpnCatalogue.forSession(session);

  @override
  Future<List<OneVpnLocation>> locations() async =>
      _toDomain(catalogue.entries);
}
