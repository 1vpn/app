// Pins the native fill of the direct DNS server. Each core start and each
// reload takes one delegate patch. That patch fills every parsed
// configuration of the start or reload from one network read. It finds the
// server by the compiler's direct tag. The read follows the monitor's
// network, or the ranked non-VPN networks when no monitor is attached. The
// patch writes the first IPv4 resolver, else the first unzoned IPv6
// resolver that is not link-local.
// Private DNS in use or in strict mode, an unreadable network, or no
// usable resolver removes the server. The patch never throws, and no log
// line carries a resolver address or a network.

import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/service/connect/routing/dns.dart';

import 'support/kotlin_source.dart';

const _kotlinRoot = 'android/app/src/main/kotlin/net/yuandev/onexray';
const _onevpnDir = '$_kotlinRoot/onevpn';
const _directDnsPath = '$_onevpnDir/OneVpnDirectDns.kt';
const _delegatePath = '$_onevpnDir/OneVpnServiceDelegate.kt';
const _servicePath = '$_kotlinRoot/vpn/OneVpnService.kt';

// Whole-body pins, normalized by normalizedKotlinMethod.

const _pinnedPatch =
    r'fun patch(root: JsonObject, reading: Lazy<Choice>): JsonObject { val '
    r'dns = root["dns"] as? JsonObject ?: return root val servers = '
    r'dns["servers"] as? JsonArray ?: return root if '
    r'(servers.none(::isDirect)) return root val choice = reading.value '
    r'applied = choice XLog.d("OneVpnDirectDns: direct server '
    r'${if (choice.address == null) "removed" else "filled"}") val address = '
    r'choice.address val patched = servers.mapNotNull { server -> when { '
    r'!isDirect(server) -> server address == null -> null else -> '
    r'JsonObject(server.jsonObject + ("address" to JsonPrimitive(address))) } } '
    r'return JsonObject(root + ("dns" to JsonObject(dns + ("servers" to '
    r'JsonArray(patched))))) }';

/// A read failure gives no address, so the patch removes the server.
const _pinnedRead =
    r'fun read(context: Context, network: Network?): Choice = try { val '
    r'connectivity = context.getSystemService(ConnectivityManager::class.java) '
    r'choose((network ?: underlying(connectivity))?.let { '
    r'connectivity.getLinkProperties(it) }) } catch (e: Exception) { '
    r'XLog.w("OneVpnDirectDns: network unreadable (${e.javaClass.simpleName})") '
    r'Choice(null) }';

const _pinnedChoose =
    r'fun choose(link: LinkProperties?): Choice { if (link == null || '
    r'link.isPrivateDnsActive || link.privateDnsServerName != null) { return '
    r'Choice(null) } val servers = link.dnsServers val address = '
    r'servers.firstOrNull { it is Inet4Address } ?: servers.firstOrNull { it is '
    r'Inet6Address && it.scopeId == 0 && it.scopedInterface == null && '
    r'!it.isLinkLocalAddress } return Choice(address?.hostAddress) }';

const _pinnedCarried =
    r'fun carried(request: StartVpnRequest?): Boolean = try { val xrayJson = '
    r'request?.coreInvokeText?.let { '
    r'JsonTool.json.decodeFromString<LibXrayInvokeRequest>(it).payload?.xrayJson '
    r'} val dns = xrayJson?.let { '
    r'JsonTool.json.parseToJsonElement(it).jsonObject["dns"] } ((dns as? '
    r'JsonObject)?.get("servers") as? JsonArray)?.any(::isDirect) == true } '
    r'catch (_: Exception) { false }';

const _pinnedRank =
    r'private fun rank(capabilities: NetworkCapabilities): Int { val transport '
    r'= listOf( NetworkCapabilities.TRANSPORT_ETHERNET, '
    r'NetworkCapabilities.TRANSPORT_WIFI, '
    r'NetworkCapabilities.TRANSPORT_CELLULAR, '
    r').indexOfFirst(capabilities::hasTransport).let { if (it < 0) 3 else it } '
    r'val validated = '
    r'capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED) '
    r'return if (validated) transport else transport + 4 }';

// Expression bodies, matched in the whitespace-collapsed source.

const _pinnedUnderlying =
    '@Suppress("DEPRECATION") private fun underlying(connectivity: '
    'ConnectivityManager): Network? = connectivity.allNetworks .mapNotNull { '
    'network -> connectivity.getNetworkCapabilities(network)?.let { network to '
    'it } } .filter { (_, capabilities) -> '
    'capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) && '
    'capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_RESTRICTED) '
    '&& capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_VPN) } '
    '.minByOrNull { (_, capabilities) -> rank(capabilities) } ?.first';

const _pinnedIsDirect =
    'private fun isDirect(server: JsonElement): Boolean = (server as? '
    'JsonObject)?.get("tag") == JsonPrimitive(DIRECT_TAG)';

const _pinnedHook =
    'fun directDnsPatch(context: Context): (JsonObject) -> JsonObject { val '
    'reading = lazy { OneVpnDirectDns.read(context, '
    'OneVpnHandoverService.network()) } return { root -> '
    'OneVpnDirectDns.patch(root, reading) } }';

/// The service's runtime patch, upstream's function with the patch passed in.
const _pinnedPatchRuntimeEnv =
    r'private fun patchRuntimeEnv(requestJson: String, fd: Int, directDns: '
    r'(JsonObject) -> JsonObject): String { try { '
    r'val request = '
    r'JsonTool.json.decodeFromString<LibXrayInvokeRequest>(requestJson) val '
    r'payload = request.payload ?: throw IllegalStateException("runXray payload '
    r'is empty") val xrayJson = payload.xrayJson ?: throw '
    r'IllegalStateException("xrayJson is empty") if (xrayJson.isEmpty()) { '
    r'throw IllegalStateException("xrayJson is empty") } val root = '
    r'directDns(JsonTool.json.parseToJsonElement(xrayJson).jsonObject) val '
    r'currentEnv = '
    r'root["env"]?.let { JsonTool.json.decodeFromJsonElement<XrayEnv>(it) } ?: '
    r'XrayEnv() val env = currentEnv.copy(tunFd = fd.toString()) val updated = '
    r'buildJsonObject { root.forEach { (key, value) -> if (key != "env") { '
    r'put(key, value) } } put("env", JsonTool.json.encodeToJsonElement(env)) } '
    r'val updatedPayload = payload.copy( xrayJson = '
    r'JsonTool.json.encodeToString(updated), ) return '
    r'JsonTool.json.encodeToString(request.copy(payload = updatedPayload)) } '
    r'catch (_: IllegalArgumentException) { throw '
    r'IllegalStateException("invalid Xray run request") } }';

String _collapsed(String path) =>
    kotlinSource(path).replaceAll(RegExp(r'\s+'), ' ');

void main() {
  group('the service hook', () {
    test('every core request passes the patch once, on the parsed '
        'configuration', () {
      final body = normalizedKotlinMethod(
        _servicePath,
        'private fun patchRuntimeEnv(',
      );
      // Anti-vacuity guard. The extraction reached the env rewrite.
      expect(body, contains('put("env", '));
      expect(body, _pinnedPatchRuntimeEnv);
      expect(kotlinCensus(_kotlinRoot, 'directDnsPatch('), [
        'OneVpnServiceDelegate.kt: '
            'fun directDnsPatch(context: Context): (JsonObject) -> JsonObject {',
        'OneVpnService.kt: val result = '
            'LibXray.invoke(patchRuntimeEnv(coreInvokeText, '
            'establishedTunnel.fd, '
            'OneVpnServiceDelegate.directDnsPatch(this@OneVpnService)))',
        'OneVpnService.kt: '
            'val directDns = OneVpnServiceDelegate.directDnsPatch(this)',
      ]);
      // The first start, each reload request, and its fallback all pass
      // through patchRuntimeEnv.
      expect(kotlinLines(_servicePath, 'patchRuntimeEnv('), [
        'val result = LibXray.invoke(patchRuntimeEnv(coreInvokeText, '
            'establishedTunnel.fd, '
            'OneVpnServiceDelegate.directDnsPatch(this@OneVpnService)))',
        'listOf(patchRuntimeEnv(next, fd, directDns), '
            'patchRuntimeEnv(fallback, fd, directDns))',
        'private fun patchRuntimeEnv(requestJson: String, fd: Int, '
            'directDns: (JsonObject) -> JsonObject): String {',
      ]);
    });

    test('a reload reads the choice once for both of its requests', () {
      final reload = normalizedKotlinMethod(
        _servicePath,
        'private fun reloadXray(',
      );
      // Anti-vacuity guard. The extraction reached the rollback.
      expect(reload, contains('return ReloadOutcome.ROLLED_BACK'));
      expect(
        reload,
        contains(
          'val requests = try { val fd = live.fd val directDns = '
          'OneVpnServiceDelegate.directDnsPatch(this) '
          'listOf(patchRuntimeEnv(next, fd, directDns), '
          'patchRuntimeEnv(fallback, fd, directDns)) }',
        ),
      );
      expect('directDnsPatch('.allMatches(reload), hasLength(1));
      // One patch holds one lazy read, so both requests carry one choice.
      expect(kotlinLines(_delegatePath, 'lazy'), [
        'val reading = lazy { '
            'OneVpnDirectDns.read(context, OneVpnHandoverService.network()) }',
      ]);
      expect(kotlinLines(_directDnsPath, '.value'), [
        'val choice = reading.value',
      ]);
    });

    test('the delegate reads the monitor network, else none', () {
      expect(
        normalizedKotlinMethod(_delegatePath, 'fun directDnsPatch('),
        _pinnedHook,
      );
      expect(kotlinCensus(_kotlinRoot, 'OneVpnDirectDns.patch('), [
        'OneVpnServiceDelegate.kt: '
            'return { root -> OneVpnDirectDns.patch(root, reading) }',
      ]);
      expect(kotlinCensus(_kotlinRoot, 'OneVpnDirectDns.read('), [
        'OneVpnServiceDelegate.kt: val reading = lazy { '
            'OneVpnDirectDns.read(context, OneVpnHandoverService.network()) }',
      ]);
    });
  });

  group('the patch', () {
    test('finds the server by the compiler direct tag', () {
      expect(kotlinLines(_directDnsPath, 'const val DIRECT_TAG'), [
        'private const val DIRECT_TAG = "${RoutingDns.directTag}"',
      ]);
      expect(_collapsed(_directDnsPath), contains(_pinnedIsDirect));
    });

    test('fills or removes the server and never throws', () {
      final patch = normalizedKotlinMethod(_directDnsPath, 'fun patch(');
      // Anti-vacuity guard. The extraction reached the rebuilt root.
      expect(patch, contains('return JsonObject(root + ("dns" to'));
      expect(patch, _pinnedPatch);
      expect(_collapsed(_directDnsPath), contains(_pinnedRead));
      expect(kotlinCensus(_onevpnDir, RegExp(r'\bapplied = ')), [
        'OneVpnDirectDns.kt: applied = choice',
      ]);
      // The patch writes off the main looper. The monitor reads on it.
      expect(
        _collapsed(_directDnsPath),
        contains('@Volatile var applied: Choice? = null private set'),
      );
    });

    test('chooses IPv4 first, then an unzoned IPv6 that is not '
        'link-local, and nothing under Private DNS', () {
      expect(
        normalizedKotlinMethod(_directDnsPath, 'fun choose('),
        _pinnedChoose,
      );
    });

    test('with no monitor, reads the first-ranked non-VPN network', () {
      expect(_collapsed(_directDnsPath), contains(_pinnedUnderlying));
      expect(
        normalizedKotlinMethod(_directDnsPath, 'private fun rank('),
        _pinnedRank,
      );
      expect(kotlinCensus(_kotlinRoot, 'allNetworks'), [
        'OneVpnDirectDns.kt: connectivity.allNetworks',
      ]);
    });

    test('answers whether a request carries the server', () {
      expect(
        normalizedKotlinMethod(_directDnsPath, 'fun carried('),
        _pinnedCarried,
      );
    });

    test('logs no resolver address and no network', () {
      expect(kotlinLines(_directDnsPath, 'XLog.'), [
        r'XLog.d("OneVpnDirectDns: direct server ${if (choice.address == '
            r'null) "removed" else "filled"}")',
        r'XLog.w("OneVpnDirectDns: network unreadable '
            r'(${e.javaClass.simpleName})")',
      ]);
      // A choice prints no address, so a stray interpolation stays safe.
      expect(
        _collapsed(_directDnsPath),
        contains(
          'data class Choice(val address: String?) { '
          'override fun toString(): String = "Choice" }',
        ),
      );
    });
  });
}
