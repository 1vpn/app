package net.yuandev.onexray.onevpn

import android.content.Context
import android.net.ConnectivityManager
import android.net.LinkProperties
import android.net.Network
import android.net.NetworkCapabilities
import com.elvishew.xlog.XLog
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.jsonObject
import net.yuandev.onexray.pigeon.JsonTool
import net.yuandev.onexray.pigeon.LibXrayInvokeRequest
import net.yuandev.onexray.pigeon.StartVpnRequest
import java.net.Inet4Address
import java.net.Inet6Address

/**
 * The direct DNS server of a compiled configuration, filled from the resolver
 * of the network the core dials on. The compiler emits the server on Android
 * only, tagged [DIRECT_TAG], with a loopback placeholder address. Runs in the
 * `:native` process. Resolver addresses stay in memory: nothing here logs or
 * stores one.
 */
internal object OneVpnDirectDns {
    /** The direct server's tag. Must match the compiler's direct tag. */
    private const val DIRECT_TAG = "app-dns-direct"

    /**
     * The resolver a patch writes into the direct server. A null [address]
     * removes the server. [toString] omits the address.
     */
    data class Choice(val address: String?) {
        override fun toString(): String = "Choice"
    }

    /** The choice of the latest patch that found a direct server, or null before one. */
    @Volatile
    var applied: Choice? = null
        private set

    /**
     * [root] with each direct server filled from [reading]. A choice with no
     * address removes the server. A configuration without the server returns
     * unchanged and leaves [reading] unread. Never throws.
     */
    fun patch(root: JsonObject, reading: Lazy<Choice>): JsonObject {
        val dns = root["dns"] as? JsonObject ?: return root
        val servers = dns["servers"] as? JsonArray ?: return root
        if (servers.none(::isDirect)) return root
        val choice = reading.value
        applied = choice
        XLog.d("OneVpnDirectDns: direct server ${if (choice.address == null) "removed" else "filled"}")
        val address = choice.address
        val patched = servers.mapNotNull { server ->
            when {
                !isDirect(server) -> server
                address == null -> null
                else -> JsonObject(server.jsonObject + ("address" to JsonPrimitive(address)))
            }
        }
        return JsonObject(root + ("dns" to JsonObject(dns + ("servers" to JsonArray(patched)))))
    }

    /**
     * The choice of [network], or of [underlying] when [network] is null. Any
     * failure to read the network gives no address. Never throws.
     */
    fun read(context: Context, network: Network?): Choice = try {
        val connectivity = context.getSystemService(ConnectivityManager::class.java)
        choose((network ?: underlying(connectivity))?.let { connectivity.getLinkProperties(it) })
    } catch (e: Exception) {
        XLog.w("OneVpnDirectDns: network unreadable (${e.javaClass.simpleName})")
        Choice(null)
    }

    /**
     * The resolver [link] offers: its first IPv4 server, else its first IPv6
     * server that is unzoned and not link-local. Private DNS in use or in
     * strict mode, a null [link], or no such server gives no address.
     */
    fun choose(link: LinkProperties?): Choice {
        if (link == null || link.isPrivateDnsActive || link.privateDnsServerName != null) {
            return Choice(null)
        }
        val servers = link.dnsServers
        val address = servers.firstOrNull { it is Inet4Address }
            ?: servers.firstOrNull {
                it is Inet6Address && it.scopeId == 0 && it.scopedInterface == null &&
                    !it.isLinkLocalAddress
            }
        return Choice(address?.hostAddress)
    }

    /**
     * True when [request] starts a configuration that carries the direct
     * server. An unreadable request answers false.
     */
    fun carried(request: StartVpnRequest?): Boolean = try {
        val xrayJson = request?.coreInvokeText?.let {
            JsonTool.json.decodeFromString<LibXrayInvokeRequest>(it).payload?.xrayJson
        }
        val dns = xrayJson?.let { JsonTool.json.parseToJsonElement(it).jsonObject["dns"] }
        ((dns as? JsonObject)?.get("servers") as? JsonArray)?.any(::isDirect) == true
    } catch (_: Exception) {
        false
    }

    /**
     * The first non-VPN network with internet access: validated before
     * unvalidated, then Ethernet, Wi-Fi, cellular, and any other transport.
     * A start with no monitor reads this.
     */
    @Suppress("DEPRECATION")
    private fun underlying(connectivity: ConnectivityManager): Network? =
        connectivity.allNetworks
            .mapNotNull { network -> connectivity.getNetworkCapabilities(network)?.let { network to it } }
            .filter { (_, capabilities) ->
                capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) &&
                    capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_RESTRICTED) &&
                    capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_VPN)
            }
            .minByOrNull { (_, capabilities) -> rank(capabilities) }
            ?.first

    /** Lower ranks first. Validation outranks transport. */
    private fun rank(capabilities: NetworkCapabilities): Int {
        val transport = listOf(
            NetworkCapabilities.TRANSPORT_ETHERNET,
            NetworkCapabilities.TRANSPORT_WIFI,
            NetworkCapabilities.TRANSPORT_CELLULAR,
        ).indexOfFirst(capabilities::hasTransport).let { if (it < 0) 3 else it }
        val validated = capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)
        return if (validated) transport else transport + 4
    }

    private fun isDirect(server: JsonElement): Boolean =
        (server as? JsonObject)?.get("tag") == JsonPrimitive(DIRECT_TAG)
}
