// Endpoint gate: every URL, host name, and IP literal in the scanned
// surface must be on the allowlist below. The scanned surface covers:
//
// - lib and the test tree
// - the native trees and platform config carriers: android, swift, ios
// - bundled asset text
// - the compiled configurations
//
// A hit outside the allowlist fails the sweep and names the file and the
// literal. The sweep is the endpoint check on native files.
//
// Store review flows use the in_app_review OS surface and carry no URL. The
// one store link is the Play subscriptions page the Support page opens in
// the browser, allowed by file below. Any other store URL fails the sweep.
//
// This file is the allowlist and quotes banned literals as data. The file
// sweep skips it by exact path.
//
// Build tooling that never ships is out of scope: build_scripts, tool, and
// fastlane. It runs only on the build machine. The android gradle files are
// in scope. They choose the dependency repositories for the shipped build,
// so the sweep sees a repository swap.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/service/connect/compiler.dart';
import 'package:onexray/service/connect/settings.dart';

import 'support/compiler_fixtures.dart';

/// Hosts the product may reference anywhere: the four failover domains, the
/// DoH resolver host, and the local host name. /ping/ and the API use the
/// failover domains. Subdomains of the failover domains are allowed.
const _allowedHosts = {
  '1vpn.org',
  '1vpn.co',
  'onevpn.com',
  'cloudlogcdn.com',
  'dns10.quad9.net',
  'localhost',
};

/// The node hosts of the embedded free floor: 1vpn production node domains.
/// A free node dials its build-time IP literal, never its hostname. The
/// `ONEVPN_FREE_NODE_IPS` define names each node by this hostname. This
/// node-domain allowance is separate from the failover domains in
/// [_allowedHosts] and from the DoH resolver. It applies only inside the floor
/// file below.
const _floorNodeHosts = {
  'free-amsterdam-node-1.cloudwidecdn.com',
  'free-amsterdam-node-2.cloudwidecdn.com',
  'free-singapore-node-1.cloudwidecdn.com',
  'free-singapore-node-2.cloudwidecdn.com',
  'free-los-angeles-node-1.cloudwidecdn.com',
  'free-los-angeles-node-2.cloudwidecdn.com',
};

/// The REALITY camouflage SNI names the floor presents to its own nodes.
/// These names are never dialed. The app dials a free node's IP literal and
/// sends one of these names as the TLS SNI. They are allowed as source literals
/// only in the floor and the default-SNI constant. They are absent from
/// [_allowedHosts].
const _floorRealitySni = {'www.apple.com', 'www.cloudflare.com'};

/// The geodata downloads, allowed only as these exact URLs. They are the only
/// non-1vpn destinations the app dials. If the dependency moves, a 1vpn-hosted
/// mirror replaces it.
const _allowedUrls = {
  'https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat',
  'https://github.com/v2fly/geoip/releases/latest/download/geoip.dat',
};

/// XML namespace and DTD identifiers, allowed as these exact URLs in any
/// file. XML machinery reads them as names and never dials them. Each
/// entry must still match at least one scanned file. The surface test
/// fails a stale entry.
const _schemaIdentifierUrls = {
  'http://schemas.android.com/apk/res/android',
  'http://schemas.android.com/tools',
  'http://www.w3.org/2000/svg',
  'http://www.apple.com/DTDs/PropertyList-1.0.dtd',
};

/// Literals allowed in one file only, each with its reason. A hit on any
/// other literal in these files still fails. An entry that stops matching
/// fails the staleness check.
const _fileAllowances = <String, Set<String>>{
  // Generated pigeon headers: a documentation link inside a comment.
  'lib/core/pigeon/messages.g.dart': {'https://pub.dev/packages/pigeon'},
  'android/app/src/main/kotlin/net/yuandev/onexray/pigeon/Messages.g.kt': {
    'https://pub.dev/packages/pigeon',
  },
  'swift/App/pigeon/Messages.g.swift': {'https://pub.dev/packages/pigeon'},
  'lib/onevpn/handover/handover.g.dart': {'https://pub.dev/packages/pigeon'},
  'android/app/src/main/kotlin/net/yuandev/onexray/onevpn/handover/Handover.g.kt':
      {'https://pub.dev/packages/pigeon'},
  // The Play subscriptions page the Support page opens in the browser. The
  // app never dials it.
  'lib/onevpn/shell/links.dart': {
    'https://play.google.com/store/account/subscriptions?package=com.one.vpnapp',
  },
  'test/onevpn/shell/support_page_test.dart': {
    'https://play.google.com/store/account/subscriptions?package=com.one.vpnapp',
  },
  // Chrome build token inside the desktop User-Agent string, not an
  // address.
  'lib/core/network/user_agent.dart': {'140.0.0.0'},
  // Documentation links inside a manifest comment.
  'android/app/src/main/AndroidManifest.xml': {
    'https://developer.android.com/training/package-visibility?hl=en',
    'https://developer.android.com/reference/android/content/Intent#ACTION_PROCESS_TEXT.',
  },
  // Dependency repository for the shipped build.
  'android/build.gradle.kts': {'https://jitpack.io'},
  // The pinned gradle wrapper distribution.
  'android/gradle/wrapper/gradle-wrapper.properties': {
    'https://services.gradle.org/distributions/gradle-9.7.1-bin.zip',
  },
  // Documentation link for the adapter pattern the tunnel follows.
  'swift/Tunnel/PacketTunnelProvider.swift': {
    'https://github.com/WireGuard/wireguard-apple/blob/master/Sources/WireGuardKit/WireGuardAdapter.swift',
  },
  // App-group identifier, not a host.
  'swift/All/Constants.swift': {'group.net.yuandev.onexray.se'},
  // Flutter engine bundle identifier, not a host.
  'ios/Flutter/AppFrameworkInfo.plist': {'io.flutter.flutter.app'},
  // Provenance record for the bundled region catalog: the source pages
  // its build step read. Nothing in the app dials them. The asset ships
  // only if pubspec lists it.
  'assets/geodata/regions.sources.json': {
    'https://raw.githubusercontent.com/v2fly/domain-list-community/master/data/cn',
    'https://raw.githubusercontent.com/v2fly/domain-list-community/master/data/category-ir',
    'https://raw.githubusercontent.com/v2fly/domain-list-community/master/data/category-ru',
    'https://raw.githubusercontent.com/v2fly/domain-list-community/master/data/category-tm',
    'https://raw.githubusercontent.com/v2fly/domain-list-community/master/data/category-pt',
  },
  // Upstream's Google-DNS defaults, dormant in the fork. Nothing feeds
  // them into a compiled configuration or a native DNS setter. The
  // platform policy replaces them with the pinned resolver constants at
  // read. RoutingDns compiles the DoH cascade without them. The
  // compiled-config pins hold both rules. The staleness check below fails
  // an entry once its literal leaves its file.
  'lib/service/advanced/platform_policy.dart': {
    '8.8.8.8',
    '2001:4860:4860::8888',
    'dns.google',
  },
  'lib/service/connect/compiler.dart': {'8.8.8.8', '2001:4860:4860::8888'},
  'lib/service/connect/routing/dns.dart': {'8.8.8.8'},
  // Upstream fixtures: sample resolver values that flow through model
  // contracts and Raw passthrough. They are fixture data and are never
  // dialed.
  'test/core/pigeon/native_json_contract_test.dart': {
    '8.8.8.8',
    '2001:4860:4860::8888',
    'dns.google',
  },
  'test/core/ffi/windows_exe_test.dart': {'8.8.8.8'},
  'test/core/ffi/base_ffi_api_test.dart': {'8.8.8.8'},
  'test/core/ffi/linux_ffi_api_test.dart': {'8.8.8.8'},
  'test/core/ffi/windows_msix_test.dart': {'8.8.8.8'},
  'test/service/connect/compiler_test.dart': {
    '8.8.8.8',
    '2001:4860:4860::8888',
    '9.9.9.9',
  },
  'test/service/connect/routing/custom/service_test.dart': {'9.9.9.9'},
  'test/service/connect/routing/custom/state_test.dart': {'8.8.8.8', '9.9.9.9'},
  'test/service/connect/routing/smart/editor_test.dart': {'8.8.8.8', '9.9.9.9'},
  'test/service/shared/xray/validation_test.dart': {'8.8.8.8'},
  'test/pages/shared/widgets/dns_text_field_test.dart': {
    '8.8.8.8',
    '2001:4860:4860::8888',
    'dns.google',
    '9.9.9.9',
  },
  'test/core/ffi/windows_native_api_test.dart': {
    '8.8.8.8',
    '223.5.5.5',
    '2400:3200::1',
  },
  'test/core/model/xray_json_test.dart': {'8.8.8.8', '2001:4860:4860::8888'},
  'test/service/connect/runtime_network_policy_test.dart': {
    '8.8.8.8',
    '2001:4860:4860::8888',
    'https://dns.google/dns-query',
  },
  // Fixtures for the pinned-resolver contract. A CIDR that covers the
  // resolver range is rejected input. The override discards the stored
  // foreign resolver values. The dormant Google defaults are excludable
  // ranges like any other.
  'test/service/advanced/platform_policy_test.dart': {
    '9.9.0.0',
    'cloudflare-dns.com',
    '2606:4700:4700::1111',
    '2606:4700:4700::',
    '1.1.1.0',
    '8.8.8.8',
    '2001:4860:4860::8888',
  },
  // Plugin platform-channel names, not hosts.
  'test/core/pigeon/android_permission_test.dart': {'flutter.baseflow.com'},
  'test/pages/shared/alert_test.dart': {'flutter.baseflow.com'},
  'test/onevpn/ads/admob_start_test.dart': {'plugins.flutter.io'},
  'test/onevpn/support/quick_actions_channel.dart': {'plugins.flutter.io'},
  // Fork sweeps quote the endpoints they ban as data.
  'test/onevpn/probe_target_sweep_test.dart': {'cp.cloudflare.com'},
  'test/onevpn/geo_probe_sweep_test.dart': {
    'ip-check-perf.radar.cloudflare.com',
  },
  'test/onevpn/update_check_sweep_test.dart': {'api.github.com'},
  'test/onevpn/import_edge_sweep_test.dart': {'onexray.com'},
  'test/onevpn/branding_test.dart': {'onexray.com'},
  'test/onevpn/android_manifest_test.dart': {
    'onexray.com',
    'onexray://onexray.com',
  },
  'test/onevpn/compiled_config_pins_test.dart': {
    '8.8.8.8',
    '2001:4860:4860::8888',
    'dns.google',
  },
  // The embedded free floor: its six node hosts and the two REALITY SNI
  // names it presents to them. The SNI names are never dialed.
  'lib/onevpn/catalogue/free_floor.dart': {
    ..._floorNodeHosts,
    ..._floorRealitySni,
  },
  // The default REALITY SNI for a server when the API sends none. It is a
  // camouflage name and is never dialed.
  'lib/onevpn/catalogue/location.dart': {'www.cloudflare.com'},
};

/// This file: the allowlist itself, skipped by the file sweep.
const _selfPath = 'test/onevpn/endpoint_allowlist_test.dart';

/// URL literal in any case: a form with any scheme, or a scheme-relative
/// form. A scheme-relative URL inherits the scheme where it is used and dials
/// like a full URL. The scheme-relative branch refuses the tail of a longer
/// token. It requires an authority that starts like a host. A comment leader
/// or a quoted regex fragment therefore holds no match.
final _urlPattern = RegExp(
  r'''[a-z][a-z0-9+.-]*://[^\s'",`<>]+'''
  r'''|(?<![\w:/])//[a-z0-9\[][^\s'",`<>]*''',
  caseSensitive: false,
);

/// Dotted IPv4 shape. The octet range is checked after the match. A dotted
/// token with an octet above 255 is a version string, not an address.
final _ipv4Pattern = RegExp(
  r'(?<![\d.])(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})(?![\d.])',
);

/// IPv6 shape: any hex-group form with a double colon, or four or more
/// plain hex groups.
final _ipv6Pattern = RegExp(
  r'\b[0-9A-Fa-f]{1,4}(?::[0-9A-Fa-f]{1,4})*::'
  r'(?:[0-9A-Fa-f]{1,4}(?::[0-9A-Fa-f]{1,4})*)?'
  r'|\b(?:[0-9A-Fa-f]{1,4}:){4,7}[0-9A-Fa-f]{1,4}\b',
);

/// Bare host name in any case: dotted labels that end in a longstanding
/// TLD. The lookbehind skips matches inside a longer token or after a
/// slash. The URL pattern finds a host that carries a scheme. The trailing
/// guard refuses a match that continues into more labels. A dotted
/// identifier therefore cannot shed its tail and pass as a shorter host.
final _hostPattern = RegExp(
  r'(?<![\w/.-])(?:[a-z0-9][a-z0-9-]*\.)+'
  r'(?:com|org|net|io|co|dev|app|me|cloud|info|xyz|sh|gg|ai|ly|us|uk|de'
  r'|fr|ru|cn|jp|se|ch|nl|ca|au|tv|cc|gov|edu|mil|google|test|example'
  r'|invalid|localhost)'
  r'(?![\w-]|\.[a-z0-9])',
  caseSensitive: false,
);

/// Bare host name on a low-cost TLD. These endings collide with code
/// identifiers such as `bounds.top` and `LucideIcons.link`. They match only
/// where an endpoint literal can live: at the start of a quoted string or
/// an XML text node. A string can be dialed and a comment cannot.
final _quotedHostPattern = RegExp(
  r'''(?<=['">])(?:[a-z0-9][a-z0-9-]*\.)+'''
  r'(?:top|site|online|icu|zip|click|link|live|life|world|today|store'
  r'|shop|tech|space|fun|website|win|vip|men|loan|work|monster|sbs|cfd'
  r'|bond|rest|quest|bid|mobi|biz|asia|pro|buzz|cyou|gdn|eu|su|ir)'
  r'(?![\w-]|\.[a-z0-9])',
  caseSensitive: false,
);

/// Reserved names under RFC 2606 and RFC 6761. They never resolve on the
/// public Internet, so fixtures use them freely.
bool _isReservedHost(String host) {
  for (final tld in ['.test', '.example', '.invalid', '.localhost']) {
    if (host.endsWith(tld)) return true;
  }
  for (final domain in ['example.com', 'example.org', 'example.net']) {
    if (host == domain || host.endsWith('.$domain')) return true;
  }
  return false;
}

bool _isAllowedHost(String host) {
  if (_allowedHosts.contains(host)) return true;
  if (_isReservedHost(host)) return true;
  // Subdomains of the failover domains stay first-party.
  return _allowedHosts.any((allowed) => host.endsWith('.$allowed'));
}

/// Addresses that reach no third party:
///
/// - unspecified and loopback
/// - the private and link-local ranges
/// - the RFC 5737 TEST-NET blocks
/// - the benchmarking range 198.18.0.0/15, which carries the TUN addressing
/// - the reserved 240.0.0.0/4 block, whose shape also covers subnet-mask
///   literals
/// - the two pinned resolver addresses
bool _isAllowedIpv4(String literal) {
  final octets = literal.split('.').map(int.parse).toList();
  if (octets.any((octet) => octet > 255)) return true; // A version string.
  final (a, b, c, _) = (octets[0], octets[1], octets[2], octets[3]);
  if (a == 0 || a == 127 || a == 10) return true;
  if (a >= 240) return true;
  if (a == 172 && b >= 16 && b <= 31) return true;
  if (a == 192 && b == 168) return true;
  if (a == 169 && b == 254) return true;
  if (a == 192 && b == 0 && c == 2) return true;
  if (a == 198 && b == 51 && c == 100) return true;
  if (a == 203 && b == 0 && c == 113) return true;
  if (a == 198 && (b == 18 || b == 19)) return true;
  return literal == '9.9.9.10' || literal == '1.1.1.1';
}

/// The IPv6 counterparts: documentation and unique-local and link-local
/// ranges, the TUN gateway, and the Quad9 resolver range.
bool _isAllowedIpv6(String literal) {
  final value = literal.toLowerCase();
  if (value.startsWith('2001:db8') || value.startsWith('2001:0db8')) {
    return true;
  }
  if (RegExp(r'^f[cd][0-9a-f]{2}:').hasMatch(value)) return true;
  if (value.startsWith('fe80:')) return true;
  return value.startsWith('2620:fe:');
}

/// One detector find: the literal and whether the allowlist admits it.
typedef _Hit = ({String literal, bool allowed});

/// Host part of a matched URL: scheme and path stripped, userinfo and
/// port removed, brackets kept off an IPv6 host.
String _urlHost(String url) {
  var rest = url.substring(url.indexOf('//') + 2);
  final slash = rest.indexOf('/');
  if (slash >= 0) rest = rest.substring(0, slash);
  final at = rest.lastIndexOf('@');
  if (at >= 0) rest = rest.substring(at + 1);
  if (rest.startsWith('[')) {
    final close = rest.indexOf(']');
    return close >= 0 ? rest.substring(1, close) : rest.substring(1);
  }
  final colon = rest.indexOf(':');
  return (colon >= 0 ? rest.substring(0, colon) : rest).toLowerCase();
}

/// A Dart interpolation placeholder inside a scanned literal.
final _interpolation = RegExp(r'\$\{[^}]*\}|\$[A-Za-z_][A-Za-z0-9_]*');

bool _isAllowedUrl(String url) {
  // A placeholder holds no literal endpoint. A plain label replaces it, so
  // literal host fragments around it stay checkable.
  final resolved = url.contains(r'$')
      ? url.replaceAll(_interpolation, 'x')
      : url;
  if (_allowedUrls.contains(resolved)) return true;
  if (_schemaIdentifierUrls.contains(resolved)) return true;
  final host = _urlHost(resolved);
  if (host.isEmpty) return true; // A URL with no authority has no endpoint.
  // A dotless host has no public DNS name. A fully interpolated host
  // reduces to one placeholder label.
  if (!host.contains('.') && !host.contains(':')) return true;
  if (_isAllowedHost(host)) return true;
  if (_ipv4Pattern.hasMatch(host) && !host.contains(RegExp(r'[^\d.]'))) {
    return _isAllowedIpv4(host);
  }
  if (host.contains(':')) return _isAllowedIpv6(host);
  return false;
}

/// Every endpoint-shaped literal in [content] with its verdict. With
/// [joinsAdjacentStrings], the scan first joins adjacent string literals
/// the way Dart concatenates them. A URL split across source lines is then
/// checked whole. Non-Dart text keeps its quotes apart. A plist DTD line
/// holds adjacent quoted names that are separate values.
List<_Hit> _scan(String content, {bool joinsAdjacentStrings = true}) {
  // Escaped whitespace separates literals like real whitespace. Left in
  // place, it glues an address to the text before it and breaks the match
  // anchor. The escaped colon is the Java-properties spelling. Unescaping
  // it restores the URL shape.
  var text = content.replaceAll(RegExp(r'\\[ntr]'), ' ').replaceAll(r'\:', ':');
  if (joinsAdjacentStrings) {
    text = text
        .replaceAll(RegExp("'[ \\t\\r\\n]+'"), '')
        .replaceAll(RegExp('"[ \\t\\r\\n]+"'), '');
  }
  final hits = <_Hit>[];
  final urlSpans = <(int, int)>[];
  for (final match in _urlPattern.allMatches(text)) {
    urlSpans.add((match.start, match.end));
    final url = match.group(0)!;
    hits.add((literal: url, allowed: _isAllowedUrl(url)));
  }
  // A host or address inside an already-checked URL is not re-reported.
  bool inUrl(Match match) =>
      urlSpans.any((span) => match.start >= span.$1 && match.end <= span.$2);
  // A host name keeps one case per label. A label that mixes cases is a
  // code identifier (LucideIcons.info, Dispatchers.IO), not a host.
  bool isIdentifier(String token) => token
      .split('.')
      .any(
        (label) => label != label.toLowerCase() && label != label.toUpperCase(),
      );
  for (final pattern in [_hostPattern, _quotedHostPattern]) {
    for (final match in pattern.allMatches(text)) {
      if (inUrl(match)) continue;
      final host = match.group(0)!;
      if (isIdentifier(host)) continue;
      hits.add((literal: host, allowed: _isAllowedHost(host.toLowerCase())));
    }
  }
  for (final match in _ipv4Pattern.allMatches(text)) {
    if (inUrl(match)) continue;
    final literal = match.group(0)!;
    hits.add((literal: literal, allowed: _isAllowedIpv4(literal)));
  }
  for (final match in _ipv6Pattern.allMatches(text)) {
    if (inUrl(match)) continue;
    final literal = match.group(0)!;
    hits.add((literal: literal, allowed: _isAllowedIpv6(literal)));
  }
  return hits;
}

/// Scans one file. Disallowed hits covered by the file's allowance come
/// back allowed. [used] collects which allowance literals matched.
List<_Hit> _scanFile(File file, Map<String, Set<String>> used) {
  final path = file.path.replaceAll(r'\', '/');
  final allowance = _fileAllowances[path] ?? const <String>{};
  final hits = <_Hit>[];
  final content = file.readAsStringSync();
  final joins = path.endsWith('.dart');
  for (final hit in _scan(content, joinsAdjacentStrings: joins)) {
    if (!hit.allowed && allowance.contains(hit.literal)) {
      (used[path] ??= {}).add(hit.literal);
      hits.add((literal: hit.literal, allowed: true));
    } else {
      hits.add(hit);
    }
  }
  return hits;
}

/// Extensions that hold no scannable text: images, icons, and binary
/// data files.
const _binaryExtensions = {
  '.png',
  '.ico',
  '.icns',
  '.jpg',
  '.jpeg',
  '.gif',
  '.webp',
  '.ttf',
  '.otf',
  '.dat',
  '.aar',
  '.jar',
  '.so',
  '.dylib',
};

/// Every file under lib plus every Dart file under test. The caller sorts
/// them with the native surface, so the failure listing is deterministic.
/// The walk skips the allowlist file itself.
List<File> _dartSources() =>
    [
      ...Directory('lib').listSync(recursive: true, followLinks: false),
      ...Directory('test').listSync(recursive: true, followLinks: false),
    ].whereType<File>().where((file) {
      final path = file.path.replaceAll(r'\', '/');
      if (path == _selfPath) return false;
      return path.startsWith('lib/') || path.endsWith('.dart');
    }).toList();

/// The native trees, platform config carriers, and bundled asset text.
/// These files ship in the device build or configure it, so their
/// literals are part of the outbound surface:
///
/// - android: Kotlin sources, manifests and resource XML, and the gradle
///   build files, which choose the shipped build's dependency sources.
///   The two properties files are named exactly. The pattern keeps the
///   gitignored local.properties and keystore files out of the walk.
/// - swift: the whole tree. Every committed file is text.
/// - ios: Swift sources, property lists, and entitlements.
/// - assets: bundled text. assets/dat holds locally staged geodata
///   binaries. They are never committed and stay out of the walk.
///
/// Dot-directories (.gradle and peers) and staged frameworks
/// (LibXray.xcframework, CocoaPods output) are local build artifacts,
/// not reviewed surface.
List<File> _nativeSources() {
  bool inScope(String path) {
    if (path.contains('/.') ||
        path.contains('.xcframework/') ||
        path.startsWith('ios/Pods/') ||
        path.startsWith('assets/dat/') ||
        _binaryExtensions.any(path.endsWith)) {
      return false;
    }
    if (path.startsWith('android/')) {
      return path.endsWith('.kt') ||
          path.endsWith('.xml') ||
          path.endsWith('.kts') ||
          path == 'android/gradle.properties' ||
          path == 'android/gradle/wrapper/gradle-wrapper.properties';
    }
    if (path.startsWith('swift/')) return true;
    if (path.startsWith('ios/')) {
      return path.endsWith('.swift') ||
          path.endsWith('.plist') ||
          path.endsWith('.entitlements');
    }
    return path.startsWith('assets/');
  }

  return [
    for (final dir in ['android', 'swift', 'ios', 'assets'])
      ...Directory(dir).listSync(recursive: true, followLinks: false),
  ].whereType<File>().where((file) {
    return inScope(file.path.replaceAll(r'\', '/'));
  }).toList();
}

/// Compiled configurations for every platform and traffic mode the
/// compiler emits, keyed for the failure listing.
Map<String, String> _compiledConfigs() {
  final configs = <String, String>{};
  for (final (label, platform, interfaceName) in [
    ('android', ConnectionPlatform.android, ''),
    ('linux', ConnectionPlatform.linux, 'selected-interface'),
    ('windows', ConnectionPlatform.windows, 'Ethernet 2'),
  ]) {
    // The product ships the smart and all-VPN modes. The dormant custom
    // compile path has no UI and stays out of the compiled sweep.
    for (final mode in [TrafficMode.smart, TrafficMode.allVpn]) {
      final plan = ConnectionCompiler.compile(
        settings: ConnectionSettings(trafficMode: mode),
        entries: [compilerNode(1, address: '192.0.2.10')],
        regions: compilerCatalog,
        options: compilerOptions(
          platform: platform,
          interfaceName: interfaceName,
        ),
      );
      configs['$label-${mode.name}'] = plan.xrayJson;
    }
  }
  return configs;
}

void main() {
  final sources = [..._dartSources(), ..._nativeSources()]
    ..sort((a, b) => a.path.compareTo(b.path));

  test('the sweep sees the trees it guards', () {
    // Count floors and known files guard against a silently empty walk.
    // The positive matches prove that reads return file content.
    final paths = sources.map((file) => file.path).toSet();
    expect(
      paths.where((path) => path.startsWith('lib/')).length,
      greaterThan(100),
    );
    expect(
      paths.where((path) => path.startsWith('test/')).length,
      greaterThan(100),
    );
    expect(paths.where((path) => path.endsWith('.kt')).length, greaterThan(5));
    expect(
      paths.where((p) => p.startsWith('android/') && p.endsWith('.xml')).length,
      greaterThan(10),
    );
    expect(
      paths.where((path) => path.endsWith('.swift')).length,
      greaterThan(10),
    );
    expect(
      paths
          .where((p) => p.endsWith('.plist') || p.endsWith('.entitlements'))
          .length,
      greaterThan(3),
    );
    expect(
      paths.where((path) => path.startsWith('assets/')).length,
      greaterThanOrEqualTo(2),
    );
    expect(paths, contains('lib/onevpn/net/failover_domains.dart'));
    expect(paths, contains('lib/onevpn/net/probe_endpoints.dart'));
    expect(paths, contains('lib/service/connect/compiler.dart'));
    expect(paths, contains('test/service/connect/compiler_test.dart'));
    expect(
      paths,
      contains(
        'android/app/src/main/kotlin/net/yuandev/onexray/vpn/'
        'OneVpnService.kt',
      ),
    );
    expect(paths, contains('android/app/src/main/AndroidManifest.xml'));
    expect(paths, contains('android/app/build.gradle.kts'));
    expect(paths, contains('swift/Tunnel/PacketTunnelProvider.swift'));
    expect(paths, contains('ios/Runner/Info.plist'));
    expect(paths, contains('ios/tunnel/tunnel.entitlements'));
    expect(paths, contains('assets/geodata/regions.sources.json'));
    // The failover domains appear in lib exactly once, in
    // failover_domains.dart. probe_endpoints.dart and the account
    // transport both build their URLs from it. The literals live there,
    // and the sweep must still see them there.
    expect(
      File('lib/onevpn/net/failover_domains.dart').readAsStringSync(),
      contains('1vpn.org'),
    );
    expect(
      File(
        'android/app/src/main/kotlin/net/yuandev/onexray/vpn/OneVpnService.kt',
      ).readAsStringSync(),
      contains('198.18.0.1'),
    );
  });

  test('the detector flags planted endpoints of every shape', () {
    const planted =
        '{"probe": "https://collector.tracker-metrics.com/v1",'
        ' "ws": "wss://stream.evil-collector.com/feed",'
        ' "ftp": "ftp://drop.evil-collector.com/up",'
        ' "rel": "//cdn.evil-collector.com/x.js",'
        ' "upper": "HTTPS://EVIL.COM/path",'
        ' "mixed": "Https://tracker-collect.com/x",'
        ' "host": "smuggled-host.example-corp.com",'
        ' "shout": "TRACKER.EVIL-COLLECTOR.NET",'
        ' "ident": "LucideIcons.info",'
        ' "top": "telemetry.evil-analytics.top",'
        ' "icu": "beacon.xyzcorp.icu",'
        ' "gov": "stats.some-agency.gov",'
        ' "near": "telemetry.example-corp.site",'
        ' "v4": "192.0.0.9", "v6": "2001:2::2"}';
    final violations = _scan(planted)
        .where((hit) => !hit.allowed)
        .map((hit) => hit.literal);
    expect(violations, [
      'https://collector.tracker-metrics.com/v1',
      'wss://stream.evil-collector.com/feed',
      'ftp://drop.evil-collector.com/up',
      '//cdn.evil-collector.com/x.js',
      'HTTPS://EVIL.COM/path',
      'Https://tracker-collect.com/x',
      'smuggled-host.example-corp.com',
      'TRACKER.EVIL-COLLECTOR.NET',
      'stats.some-agency.gov',
      'telemetry.evil-analytics.top',
      'beacon.xyzcorp.icu',
      'telemetry.example-corp.site',
      '192.0.0.9',
      '2001:2::2',
    ]);
  });

  test('every endpoint literal in the scanned surface is allowlisted', () {
    final used = <String, Set<String>>{};
    final violations = <String>[];
    final allowed = <String>[];
    for (final file in sources) {
      final path = file.path.replaceAll(r'\', '/');
      for (final hit in _scanFile(file, used)) {
        (hit.allowed ? allowed : violations).add('$path: ${hit.literal}');
      }
    }
    expect(violations, isEmpty);
    // The count floor and the named literals prove the detector still sees
    // the endpoints the product may keep. An over-broad exclusion cannot
    // hollow the sweep. The native entries prove the same for the native
    // walk: an empty native scan cannot pass.
    expect(allowed.length, greaterThan(80));
    expect(
      allowed,
      containsAll([
        'lib/onevpn/net/failover_domains.dart: 1vpn.org',
        'lib/onevpn/net/failover_domains.dart: 1vpn.co',
        'lib/onevpn/net/failover_domains.dart: onevpn.com',
        'lib/onevpn/net/failover_domains.dart: cloudlogcdn.com',
        'lib/onevpn/net/dns_resolver.dart: '
            'https://dns10.quad9.net/dns-query',
        'lib/onevpn/net/dns_resolver.dart: https://1.1.1.1/dns-query',
        'lib/service/advanced/xray/geodata/system_state.dart: '
            'https://github.com/v2fly/domain-list-community/releases/'
            'latest/download/dlc.dat',
        'lib/service/advanced/xray/geodata/system_state.dart: '
            'https://github.com/v2fly/geoip/releases/latest/download/'
            'geoip.dat',
        'lib/onevpn/shell/links.dart: https://1vpn.org/privacy-policy/',
        'lib/onevpn/net/dns_resolver.dart: 9.9.9.10',
        'lib/onevpn/net/dns_resolver.dart: 2620:fe::10',
        'lib/service/advanced/platform_policy.dart: 198.18.0.1',
        'android/app/src/main/kotlin/net/yuandev/onexray/vpn/'
            'OneVpnService.kt: 198.18.0.1',
        'android/app/src/main/AndroidManifest.xml: '
            'http://schemas.android.com/apk/res/android',
        'android/build.gradle.kts: https://jitpack.io',
        'swift/All/Constants.swift: 127.0.0.1',
        'swift/Tunnel/PacketTunnelProvider.swift: 198.18.0.1',
        'ios/Runner/Info.plist: '
            'http://www.apple.com/DTDs/PropertyList-1.0.dtd',
        'assets/geodata/regions.sources.json: '
            'https://github.com/v2fly/geoip/releases/latest/download/'
            'geoip.dat',
      ]),
    );
    // Every schema identifier must still appear in a scanned file. A stale
    // entry is an open exact-URL hole.
    for (final id in _schemaIdentifierUrls) {
      expect(
        allowed.any((entry) => entry.endsWith(': $id')),
        isTrue,
        reason: 'schema identifier matches no scanned file: $id',
      );
    }
    // Every per-file allowance must still match. A stale entry would admit
    // a new literal unchecked.
    for (final entry in _fileAllowances.entries) {
      expect(
        used[entry.key] ?? const <String>{},
        entry.value,
        reason: '${entry.key} allows literals it no longer contains',
      );
    }
  });

  test('every compiled configuration carries only allowlisted endpoints', () {
    _compiledConfigs().forEach((label, json) {
      final hits = _scan(json);
      expect(
        hits.where((hit) => !hit.allowed).map((h) => '$label: ${h.literal}'),
        isEmpty,
      );
      // The compiled output must still carry the pinned resolvers. Without
      // these checks, an empty scan passes vacuously.
      final literals = hits.map((hit) => hit.literal).toSet();
      expect(literals, contains('https://dns10.quad9.net/dns-query'));
      expect(literals, contains('https://1.1.1.1/dns-query'));
      expect(literals, contains('9.9.9.10'));
    });
  });
}
