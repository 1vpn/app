package net.yuandev.onexray.onevpn.handover

import android.content.Context
import android.net.ConnectivityManager
import android.net.LinkProperties
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import com.elvishew.xlog.XLog
import net.yuandev.onexray.onevpn.OneVpnDirectDns

/**
 * Follows the network the core dials on: the best network with internet
 * access that is not a VPN. [start] requests it and [close] releases it.
 *
 * The first network the request finds is the starting point, unless a
 * [previous] monitor hands over its own. A different network after it is
 * a change. So is a new resolver choice on the same network: see
 * [OneVpnDirectDns.choose]. Changes less than [DEBOUNCE_MS] apart coalesce.
 * The change callback runs once, [DEBOUNCE_MS] after the last of them. A
 * burst that ends on the network it started from is no change, unless its
 * resolver choice differs from the one the running core uses. Before any
 * patch applies a choice, such a burst is no change. A loss alone is no
 * change. Nothing runs after [close].
 *
 * The debounce counts uptime: while the device sleeps it waits.
 */
internal class OneVpnNetworkMonitor(context: Context, previous: OneVpnNetworkMonitor? = null) {
    /**
     * One coalesced change, from the network before the burst to the network
     * after it. [at] is the `SystemClock.elapsedRealtime` of the last event,
     * a resolver event included. [from] equals [to] for a resolver change on
     * one network.
     */
    class Change(val from: Network, val to: Network, val at: Long)

    companion object {
        /** The quiet time after the last network event before a change runs. */
        const val DEBOUNCE_MS: Long = 1_000L
    }

    private val connectivity = context.getSystemService(ConnectivityManager::class.java)
    private val handler = Handler(Looper.getMainLooper())

    private var onChange: ((Change) -> Unit)? = null
    private var current: Network? = null
    /** The resolver choice of [current], or null before its link properties arrive. */
    private var resolver: OneVpnDirectDns.Choice? = null
    private var burstFrom: Network? = null
    private var lastEventAt = 0L
    private var closed = false

    private val pending = Runnable { deliver() }

    init {
        // A closed previous monitor hands over its network and its pending change.
        if (previous != null) {
            synchronized(previous) {
                current = previous.current
                resolver = previous.resolver
                burstFrom = previous.burstFrom
                lastEventAt = previous.lastEventAt
            }
        }
    }

    private val callback = object : ConnectivityManager.NetworkCallback() {
        override fun onAvailable(network: Network) = available(network)

        override fun onLinkPropertiesChanged(network: Network, linkProperties: LinkProperties) =
            linked(network, linkProperties)

        override fun onLost(network: Network) {
            XLog.d("OneVpnNetworkMonitor: lost $network")
        }
    }

    /**
     * Requests the network and runs [onChange] on the main thread for each
     * change. A request that fails is logged and leaves the monitor inert.
     * A handed-over pending change runs [DEBOUNCE_MS] after the start.
     */
    fun start(onChange: (Change) -> Unit) {
        val handedOver = synchronized(this) {
            this.onChange = onChange
            burstFrom != null
        }
        if (handedOver) handler.postDelayed(pending, DEBOUNCE_MS)
        val request = NetworkRequest.Builder()
            .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .addCapability(NetworkCapabilities.NET_CAPABILITY_NOT_RESTRICTED)
            .addCapability(NetworkCapabilities.NET_CAPABILITY_NOT_VPN)
            .build()
        try {
            connectivity.requestNetwork(request, callback, handler)
        } catch (e: RuntimeException) {
            XLog.e("OneVpnNetworkMonitor: request failed (${e.javaClass.simpleName})")
        }
    }

    /** The network the monitor follows, or null before the first. */
    fun network(): Network? = synchronized(this) { current }

    /** Releases the request. A pending change never runs here. */
    fun close() {
        synchronized(this) {
            if (closed) return
            closed = true
        }
        handler.removeCallbacks(pending)
        try {
            connectivity.unregisterNetworkCallback(callback)
        } catch (_: IllegalArgumentException) {
        }
    }

    private fun available(network: Network) {
        XLog.d("OneVpnNetworkMonitor: available $network")
        synchronized(this) {
            if (closed) return
            val previous = current
            current = network
            if (previous == null || previous == network) return
            if (burstFrom == null) burstFrom = previous
            lastEventAt = SystemClock.elapsedRealtime()
        }
        handler.removeCallbacks(pending)
        handler.postDelayed(pending, DEBOUNCE_MS)
    }

    /**
     * A link event on the current network whose resolver choice moved
     * starts or extends a burst on that network. Any other link event does
     * nothing.
     */
    private fun linked(network: Network, link: LinkProperties) {
        val choice = OneVpnDirectDns.choose(link)
        synchronized(this) {
            if (closed || network != current || choice == resolver) return
            resolver = choice
            if (burstFrom == null) burstFrom = network
            lastEventAt = SystemClock.elapsedRealtime()
        }
        handler.removeCallbacks(pending)
        handler.postDelayed(pending, DEBOUNCE_MS)
    }

    private fun deliver() {
        val (change, run) = synchronized(this) {
            // A closed monitor keeps its pending change for the monitor it hands over to.
            if (closed) return
            val from = burstFrom ?: return
            val to = current ?: return
            burstFrom = null
            if (from == to && (resolver == null || OneVpnDirectDns.applied.let { it == null || it == resolver })) return
            Change(from, to, lastEventAt) to (onChange ?: return)
        }
        run(change)
    }
}
