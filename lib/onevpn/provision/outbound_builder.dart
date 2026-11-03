// Maps a node and its credentials to a flattened v26 outbound map.
//
// This file builds only the outbound. The config compiler generates everything
// around it: routing, DNS, FakeDNS. The provisioner writes the map through the
// `outboundCompanion` primitive, and the compiled config embeds it verbatim.
//
// The shape is Xray v26's flattened schema. `settings` carries address, port,
// id and flow directly, with no `vnext` array. REALITY takes the public key in
// `realitySettings.password`.

import 'package:onexray/onevpn/catalogue/location.dart';
import 'package:onexray/onevpn/model/user_data.dart';

abstract final class OneVpnOutboundBuilder {
  /// The VLESS + REALITY + XTLS-Vision outbound for one server.
  ///
  /// `settings.address` takes the dial address ([OneVpnServer.dialAddress]): an
  /// IP literal when present, else the hostname. The compile strips the
  /// outbound domain strategy, so a hostname resolves through libXray's process
  /// resolver. The query goes in plaintext to port 53 of the TUN DNS address,
  /// on a protected socket outside the tunnel. Free nodes dial build-time
  /// literals. Only an account server delivered without an address resolves by
  /// name. The REALITY `serverName` is the SNI in every case. Only the dial
  /// address changes between the two.
  static Map<String, dynamic> build({
    required OneVpnServer server,
    required OneVpnCredentials credentials,
  }) => <String, dynamic>{
    'protocol': 'vless',
    'settings': <String, dynamic>{
      'address': server.dialAddress,
      'port': 443,
      'id': credentials.uuid,
      'flow': 'xtls-rprx-vision',
      'encryption': 'none',
    },
    'streamSettings': <String, dynamic>{
      'network': 'raw',
      'security': 'reality',
      'realitySettings': <String, dynamic>{
        'serverName': server.sni,
        'password': credentials.publicKey,
        'shortId': credentials.shortId,
        'fingerprint': 'chrome',
      },
    },
  };
}
