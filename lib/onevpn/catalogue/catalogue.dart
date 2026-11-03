// Which locations this account may see, and which it may actually dial.
// The free tier is never filtered. Tier decides the entry set.

import 'package:onexray/onevpn/account/session.dart';
import 'package:onexray/onevpn/catalogue/free_floor.dart';
import 'package:onexray/onevpn/model/user_data.dart';

enum OneVpnTier { free, premium }

/// A location plus the list it came from.
///
/// Tier is a property of the source list, not of any wire field. On a location,
/// `isPremium` marks a teaser to upgrade to. That meaning holds only inside the
/// free catalogue. Use [freeTier] to ask which list a location came from.
class OneVpnCatalogueEntry {
  const OneVpnCatalogueEntry({required this.location, required this.freeTier});

  final OneVpnApiLocation location;

  /// True when this came from the compiled-in free list rather than from the
  /// account. Drives the free badge and the row-name tier segment.
  final bool freeTier;
}

/// The catalogue derived from a session, as pure state.
///
/// Everything a consumer needs to render is here: the entries with their tier
/// origin, the connectable subset, the paywall subset, the tier, and whether
/// the catalogue is a degraded stand-in. No widget is built here.
class OneVpnCatalogue {
  const OneVpnCatalogue({
    required this.tier,
    required this.entries,
    this.isDegraded = false,
  });

  /// All entries from one source: the free catalogue, or an account's own list.
  factory OneVpnCatalogue.of({
    required OneVpnTier tier,
    required List<OneVpnApiLocation> locations,
    required bool freeTier,
    bool isDegraded = false,
  }) => OneVpnCatalogue(
    tier: tier,
    isDegraded: isDegraded,
    entries: <OneVpnCatalogueEntry>[
      for (final location in locations)
        OneVpnCatalogueEntry(location: location, freeTier: freeTier),
    ],
  );

  final OneVpnTier tier;

  /// Everything to show, tagged with its origin. For the free tier this
  /// includes the 30 teasers beside the three connectable entries.
  final List<OneVpnCatalogueEntry> entries;

  /// A premium account currently shown the free catalogue, because its own
  /// list is unavailable or empty. Marks "we could not load what you have"
  /// apart from "you have nothing".
  final bool isDegraded;

  List<OneVpnApiLocation> get locations =>
      entries.map((e) => e.location).toList(growable: false);

  /// What can actually be dialed.
  List<OneVpnApiLocation> get connectable => entries
      .map((e) => e.location)
      .where((l) => l.isConnectable)
      .toList(growable: false);

  /// What routes to the paywall instead of to a tunnel.
  ///
  /// Never a location the user can already dial from this catalogue. The free
  /// list carries Singapore twice: a connectable entry and a teaser on the same
  /// codes. This getter drops that teaser, so the paywall never sells a
  /// location the user already has.
  List<OneVpnApiLocation> get teasers {
    final dialable = connectable
        .map((l) => '${l.countryCode}/${l.cityCode}')
        .toSet();
    return entries
        .map((e) => e.location)
        .where((l) => !l.isConnectable)
        .where((l) => !dialable.contains('${l.countryCode}/${l.cityCode}'))
        .toList(growable: false);
  }

  /// The only place that makes the tier decision.
  ///
  /// The free branch never filters: it returns every entry, teasers included.
  /// Tier is the session's entitlement, which already reflects an unconfirmed
  /// premium grant. A completed purchase therefore unlocks the catalogue with
  /// no logic here. A null or unreadable session takes the free path, like a
  /// signed-out one. The free path lists [oneVpnFreeFloor] for the session.
  static OneVpnCatalogue forSession(OneVpnSession? session) {
    if (session == null || !session.isPremiumEntitled) {
      // Every entry, teasers included. The free branch never filters.
      return OneVpnCatalogue.of(
        tier: OneVpnTier.free,
        locations: oneVpnFreeFloor(session).locations,
        freeTier: true,
      );
    }

    final usable = session.locations
        .where((l) => l.isConnectable)
        .toList(growable: false);

    if (usable.isNotEmpty) {
      // Premium lists the free nodes first, marked free, then its own. Only the
      // three connectable free entries come across. The 30 teasers sell
      // locations a premium account already has.
      return OneVpnCatalogue(
        tier: OneVpnTier.premium,
        entries: <OneVpnCatalogueEntry>[
          for (final location in _freeConnectable)
            OneVpnCatalogueEntry(location: location, freeTier: true),
          for (final location in usable)
            OneVpnCatalogueEntry(location: location, freeTier: false),
        ],
      );
    }

    // A premium account with no usable entry gets the three connectable free
    // entries, not all 33. A degraded catalogue carries no teasers: it means
    // "we could not load what you have", never "buy what you have".
    return OneVpnCatalogue.of(
      tier: OneVpnTier.premium,
      locations: _freeConnectable,
      freeTier: true,
      isDegraded: true,
    );
  }

  /// The three free entries that can actually be dialed.
  ///
  /// Inside the free catalogue `isPremium` marks a teaser, so this filter
  /// drops the teasers. That meaning holds only for [kOneVpnFreeCatalogue].
  static List<OneVpnApiLocation> get _freeConnectable => kOneVpnFreeCatalogue
      .where((l) => l.isConnectable && !l.isPremium)
      .toList(growable: false);
}
