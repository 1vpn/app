// The free tier's embedded catalogue: 33 entries, 3 connectable, 30 teasers.
//
// The 30 teasers have no servers. They route to the paywall, so the free branch
// never filters them out. That decision lives in [OneVpnCatalogue]. A test
// pins the list order.
//
// The hosts are 1vpn's own public free nodes, not authentication material. The
// endpoint sweep allows them as node domains, apart from the API domains and
// the DoH resolver. The two SNI names (`www.apple.com`, `www.cloudflare.com`)
// are REALITY camouflage, never dialed destinations. The repo is public, so
// the free REALITY credentials and the node IP literals arrive by
// `--dart-define`.

import 'package:onexray/onevpn/account/session.dart';
import 'package:onexray/onevpn/catalogue/free_node_ips.dart';
import 'package:onexray/onevpn/model/user_data.dart';

/// The free tier a session dials: its locations, teasers included, and the
/// REALITY triple its nodes take.
typedef OneVpnFreeFloor = ({
  List<OneVpnApiLocation> locations,
  OneVpnCredentials credentials,
});

/// The free tier for [session].
///
/// A signed-in session without a premium entitlement takes the free tier its
/// user data carries when that tier is complete. Its connectable locations
/// replace the compiled connectable entries, and the compiled teasers follow
/// them. Its triple replaces [kOneVpnFreeCredentials].
///
/// The user data's tier is complete with a complete triple and at least one
/// connectable location that is not a teaser. Each such location carries a
/// city code, and each of its servers an IP literal. Any other session,
/// signed out included, takes [kOneVpnFreeCatalogue] and
/// [kOneVpnFreeCredentials]. Sign-out returns the provisioned floor rows to
/// the compiled set.
OneVpnFreeFloor oneVpnFreeFloor(OneVpnSession? session) {
  final OneVpnFreeFloor compiled = (
    locations: kOneVpnFreeCatalogue,
    credentials: kOneVpnFreeCredentials,
  );
  if (session == null ||
      session.isPremiumEntitled ||
      !session.credentials.isComplete) {
    return compiled;
  }
  final served = [
    for (final location in session.locations)
      if (location.isConnectable && !location.isPremium) location,
  ];
  final complete =
      served.isNotEmpty &&
      served.every(
        (location) =>
            (location.cityCode?.isNotEmpty ?? false) &&
            location.servers!.every(
              (server) => server.ip != null || server.ip6 != null,
            ),
      );
  if (!complete) return compiled;
  return (
    locations: List<OneVpnApiLocation>.unmodifiable([
      ...served,
      for (final location in kOneVpnFreeCatalogue)
        if (!location.isConnectable) location,
    ]),
    credentials: session.credentials,
  );
}

/// The build-time free-tier REALITY triple.
///
/// Empty by default. The values arrive at build time via `--dart-define`
/// (`ONEVPN_UUID`, `ONEVPN_PBK`, `ONEVPN_SID`), so git history holds no
/// credential. An unconfigured triple reports `isComplete` false. The
/// provisioner then skips the floor's nodes and records the reason instead of
/// building a dead config.
const kOneVpnFreeCredentials = OneVpnCredentials(
  uuid: String.fromEnvironment('ONEVPN_UUID'),
  publicKey: String.fromEnvironment('ONEVPN_PBK'),
  shortId: String.fromEnvironment('ONEVPN_SID'),
);

/// The build-time IP literals for the free nodes.
///
/// Empty by default, like the triple. The value arrives at build time via
/// `--dart-define` (`ONEVPN_FREE_NODE_IPS`) in the format
/// [OneVpnFreeNodeIps.parse] reads. A free node with no literal is
/// unprovisionable. The provisioner reports it by hostname.
final kOneVpnFreeNodeIps = OneVpnFreeNodeIps.parse(
  const String.fromEnvironment('ONEVPN_FREE_NODE_IPS'),
  hosts: kOneVpnFreeHosts,
);

/// The free nodes' hostnames, lowercased, in catalogue order.
final List<String> kOneVpnFreeHosts = List<String>.unmodifiable(<String>[
  for (final location in _compiledIn)
    for (final server in location.servers ?? const <OneVpnApiServer>[])
      server.host.toLowerCase(),
]);

/// The free tier's locations, in the pinned order, with the build-time IP
/// literals set on the servers they name.
final List<OneVpnApiLocation> kOneVpnFreeCatalogue = kOneVpnFreeNodeIps.applyTo(
  _compiledIn,
);

/// The free tier's locations as compiled in. The servers carry hostnames only.
const _compiledIn = <OneVpnApiLocation>[
  OneVpnApiLocation(
    city: 'Amsterdam',
    cityCode: 'ams',
    country: 'Netherlands',
    countryCode: 'nl',
    servers: <OneVpnApiServer>[
      OneVpnApiServer(
        host: 'free-amsterdam-node-1.cloudwidecdn.com',
        realityServerName: 'www.apple.com',
      ),
      OneVpnApiServer(
        host: 'free-amsterdam-node-2.cloudwidecdn.com',
        realityServerName: 'www.cloudflare.com',
      ),
    ],
  ),
  OneVpnApiLocation(
    city: 'Singapore',
    cityCode: 'sgp',
    country: 'Singapore',
    countryCode: 'sg',
    servers: <OneVpnApiServer>[
      OneVpnApiServer(
        host: 'free-singapore-node-1.cloudwidecdn.com',
        realityServerName: 'www.apple.com',
      ),
      OneVpnApiServer(
        host: 'free-singapore-node-2.cloudwidecdn.com',
        realityServerName: 'www.cloudflare.com',
      ),
    ],
  ),
  OneVpnApiLocation(
    city: 'Los Angeles',
    cityCode: 'lax',
    country: 'United States',
    countryCode: 'us',
    servers: <OneVpnApiServer>[
      OneVpnApiServer(
        host: 'free-los-angeles-node-1.cloudwidecdn.com',
        realityServerName: 'www.apple.com',
      ),
      OneVpnApiServer(
        host: 'free-los-angeles-node-2.cloudwidecdn.com',
        realityServerName: 'www.cloudflare.com',
      ),
    ],
  ),
  OneVpnApiLocation(
    city: 'Melbourne',
    cityCode: 'mel',
    country: 'Australia',
    countryCode: 'au',
    isPremium: true,
  ),
  OneVpnApiLocation(
    city: 'Sydney',
    cityCode: 'syd',
    country: 'Australia',
    countryCode: 'au',
    isPremium: true,
  ),
  OneVpnApiLocation(
    city: 'Sao Paulo',
    cityCode: 'sao',
    country: 'Brazil',
    countryCode: 'br',
    isPremium: true,
  ),
  OneVpnApiLocation(
    city: 'Toronto',
    cityCode: 'yto',
    country: 'Canada',
    countryCode: 'ca',
    isPremium: true,
  ),
  OneVpnApiLocation(
    city: 'Santiago',
    cityCode: 'scl',
    country: 'Chile',
    countryCode: 'cl',
    isPremium: true,
  ),
  OneVpnApiLocation(
    city: 'Paris',
    cityCode: 'cdg',
    country: 'France',
    countryCode: 'fr',
    isPremium: true,
  ),
  OneVpnApiLocation(
    city: 'Frankfurt',
    cityCode: 'fra',
    country: 'Germany',
    countryCode: 'de',
    isPremium: true,
  ),
  OneVpnApiLocation(
    city: 'Delhi',
    cityCode: 'del',
    country: 'India',
    countryCode: 'in',
    isPremium: true,
  ),
  OneVpnApiLocation(
    city: 'Mumbai',
    cityCode: 'bom',
    country: 'India',
    countryCode: 'in',
    isPremium: true,
  ),
  OneVpnApiLocation(
    city: 'Bangalore',
    cityCode: 'blr',
    country: 'India',
    countryCode: 'in',
    isPremium: true,
  ),
  OneVpnApiLocation(
    city: 'Tel Aviv',
    cityCode: 'tlv',
    country: 'Israel',
    countryCode: 'il',
    isPremium: true,
  ),
  OneVpnApiLocation(
    city: 'Osaka',
    cityCode: 'itm',
    country: 'Japan',
    countryCode: 'jp',
    isPremium: true,
  ),
  OneVpnApiLocation(
    city: 'Tokyo',
    cityCode: 'nrt',
    country: 'Japan',
    countryCode: 'jp',
    isPremium: true,
  ),
  OneVpnApiLocation(
    city: 'Seoul',
    cityCode: 'icn',
    country: 'South Korea',
    countryCode: 'kr',
    isPremium: true,
  ),
  OneVpnApiLocation(
    city: 'Mexico City',
    cityCode: 'mex',
    country: 'Mexico',
    countryCode: 'mx',
    isPremium: true,
  ),
  OneVpnApiLocation(
    city: 'Warsaw',
    cityCode: 'waw',
    country: 'Poland',
    countryCode: 'pl',
    isPremium: true,
  ),
  OneVpnApiLocation(
    city: 'Singapore',
    cityCode: 'sgp',
    country: 'Singapore',
    countryCode: 'sg',
    isPremium: true,
  ),
  OneVpnApiLocation(
    city: 'Johannesburg',
    cityCode: 'jnb',
    country: 'South Africa',
    countryCode: 'za',
    isPremium: true,
  ),
  OneVpnApiLocation(
    city: 'Madrid',
    cityCode: 'mad',
    country: 'Spain',
    countryCode: 'es',
    isPremium: true,
  ),
  OneVpnApiLocation(
    city: 'Stockholm',
    cityCode: 'sto',
    country: 'Sweden',
    countryCode: 'se',
    isPremium: true,
  ),
  OneVpnApiLocation(
    city: 'London',
    cityCode: 'lhr',
    country: 'United Kingdom',
    countryCode: 'uk',
    isPremium: true,
  ),
  OneVpnApiLocation(
    city: 'Manchester',
    cityCode: 'man',
    country: 'United Kingdom',
    countryCode: 'uk',
    isPremium: true,
  ),
  OneVpnApiLocation(
    city: 'Chicago',
    cityCode: 'ord',
    country: 'United States',
    countryCode: 'us',
    isPremium: true,
  ),
  OneVpnApiLocation(
    city: 'Dallas',
    cityCode: 'dfw',
    country: 'United States',
    countryCode: 'us',
    isPremium: true,
  ),
  OneVpnApiLocation(
    city: 'Seattle',
    cityCode: 'sea',
    country: 'United States',
    countryCode: 'us',
    isPremium: true,
  ),
  OneVpnApiLocation(
    city: 'San Francisco',
    cityCode: 'sjc',
    country: 'United States',
    countryCode: 'us',
    isPremium: true,
  ),
  OneVpnApiLocation(
    city: 'Miami',
    cityCode: 'mia',
    country: 'United States',
    countryCode: 'us',
    isPremium: true,
  ),
  OneVpnApiLocation(
    city: 'Honolulu',
    cityCode: 'hnl',
    country: 'United States',
    countryCode: 'us',
    isPremium: true,
  ),
  OneVpnApiLocation(
    city: 'New York',
    cityCode: 'ewr',
    country: 'United States',
    countryCode: 'us',
    isPremium: true,
  ),
  OneVpnApiLocation(
    city: 'Atlanta',
    cityCode: 'atl',
    country: 'United States',
    countryCode: 'us',
    isPremium: true,
  ),
];
