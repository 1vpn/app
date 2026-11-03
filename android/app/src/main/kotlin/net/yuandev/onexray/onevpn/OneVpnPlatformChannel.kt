package net.yuandev.onexray.onevpn

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.os.SystemClock
import android.provider.Settings
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import com.elvishew.xlog.XLog
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.net.NetworkInterface
import java.net.SocketException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import net.yuandev.onexray.onevpn.handover.OneVpnHandoverHost
import net.yuandev.onexray.onevpn.handover.OneVpnHandoverHostApi

/**
 * The fork's own platform channel, named [CHANNEL]. The Dart side is
 * `OneVpnPlatformChannel`. Each method answers on the main thread.
 *
 * `openVpnSettings` opens the system VPN settings screen from [activity]
 * and answers true. It answers false when no activity handles the screen.
 * `tunnelHeld` answers whether a failed start holds the TUN: the
 * interface is up while the service status reads disconnected.
 * `activeNetwork` answers `vpn` true when the active network is a VPN.
 * Otherwise it answers the network's `handle`, or null when there is
 * none. It waits up to [STALE_WAIT_MS] for a stale VPN to leave.
 * `moveTaskToBack` moves the task of [activity] to the back of the activity
 * stack and answers whether it moved. The activity and its Flutter engine
 * stay alive. `restoreBillingTask` brings Play's purchase sheet, left behind
 * in a billing task, to the front and answers whether it moved.
 * `finishBillingTasks` finishes every billing task and answers whether one
 * finished. [OneVpnBillingTask] holds both. Any other method answers
 * not-implemented.
 *
 * [setUp] also registers the reload host, [OneVpnHandoverHost], on the
 * same messenger. The host closes when [activity] is destroyed.
 */
object OneVpnPlatformChannel {
    /** The channel name. It is frozen once shipped: the Dart side matches it. */
    const val CHANNEL: String = "onevpn/platform"

    /** How often `activeNetwork` reads again while the VPN is stale. */
    private const val STALE_POLL_MS: Long = 50L

    /** How long `activeNetwork` waits for a stale VPN to leave. */
    private const val STALE_WAIT_MS: Long = 2_000L

    private val scope = MainScope()

    fun setUp(messenger: BinaryMessenger, activity: FragmentActivity) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openVpnSettings" -> result.success(openVpnSettings(activity))
                "tunnelHeld" -> scope.launch { result.success(tunnelHeld(activity)) }
                "activeNetwork" -> scope.launch { result.success(activeNetwork(activity)) }
                "moveTaskToBack" -> result.success(activity.moveTaskToBack(true))
                "restoreBillingTask" -> result.success(OneVpnBillingTask.restore(activity))
                "finishBillingTasks" -> result.success(OneVpnBillingTask.finish(activity))
                else -> result.notImplemented()
            }
        }
        val handover = OneVpnHandoverHost(activity.applicationContext, messenger)
        OneVpnHandoverHostApi.setUp(messenger, handover)
        activity.lifecycle.addObserver(LifecycleEventObserver { _, event ->
            if (event == Lifecycle.Event.ON_DESTROY) {
                handover.close()
            }
        })
    }

    private fun openVpnSettings(activity: Activity): Boolean =
        try {
            activity.startActivity(Intent(Settings.ACTION_VPN_SETTINGS))
            true
        } catch (error: ActivityNotFoundException) {
            XLog.w("OneVpnPlatformChannel: no VPN settings screen: $error")
            false
        }

    /** A status that cannot be read counts as not held. */
    private suspend fun tunnelHeld(context: Context): Boolean =
        OneVpnTunnelStatus.held(context) == true

    /**
     * Answers `vpn` true when the active network is a VPN. Otherwise answers
     * its `handle`, an OS-local id. Answers null when there is no active
     * network or its capabilities are unreadable.
     *
     * The active network is this app's default network, and the app is
     * excluded from its own tunnel. The read never sees that tunnel, up or
     * held, and answers the underlying network instead.
     *
     * A VPN whose interface is missing or down is stale: the system has not
     * yet dropped a stopped tunnel. The read repeats every [STALE_POLL_MS]
     * until the active network is no stale VPN, for up to [STALE_WAIT_MS].
     * A VPN still stale then answers `vpn` true. A live VPN answers at once.
     */
    private suspend fun activeNetwork(context: Context): Map<String, Any>? {
        val connectivity = context.getSystemService(ConnectivityManager::class.java) ?: return null
        val deadline = SystemClock.elapsedRealtime() + STALE_WAIT_MS
        while (true) {
            val network = connectivity.activeNetwork ?: return null
            val capabilities = connectivity.getNetworkCapabilities(network) ?: return null
            if (!capabilities.hasTransport(NetworkCapabilities.TRANSPORT_VPN)) {
                return mapOf("handle" to network.networkHandle)
            }
            if (!stale(connectivity, network) || SystemClock.elapsedRealtime() >= deadline) {
                return mapOf("vpn" to true)
            }
            delay(STALE_POLL_MS)
        }
    }

    /** Whether the VPN [network] has no interface, or one that is gone or down. */
    private suspend fun stale(connectivity: ConnectivityManager, network: Network): Boolean {
        val name = connectivity.getLinkProperties(network)?.interfaceName ?: return true
        return withContext(Dispatchers.IO) {
            try {
                NetworkInterface.getByName(name)?.isUp != true
            } catch (_: SocketException) {
                true
            }
        }
    }
}
