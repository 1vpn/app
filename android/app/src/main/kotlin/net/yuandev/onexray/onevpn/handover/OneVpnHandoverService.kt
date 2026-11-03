package net.yuandev.onexray.onevpn.handover

import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Network
import android.os.SystemClock
import androidx.core.content.ContextCompat
import com.elvishew.xlog.XLog
import kotlinx.coroutines.runBlocking
import net.yuandev.onexray.onevpn.OneVpnDirectDns
import net.yuandev.onexray.onevpn.OneVpnMeasureTimeout
import net.yuandev.onexray.onevpn.OneVpnServiceDelegate
import net.yuandev.onexray.onevpn.OneVpnTunnelStatus
import net.yuandev.onexray.pigeon.JsonTool
import net.yuandev.onexray.pigeon.StartVpnRequest
import net.yuandev.onexray.vpn.OneVpnService.ReloadOutcome
import net.yuandev.onexray.vpn.VpnController
import java.io.File
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicInteger

/**
 * The `:native` side of the in-place reload. Its receivers and its network
 * monitor exist only while a tunnel is up. [attach] registers them and
 * [detach] removes them. Every reload runs on one thread in arrival order
 * and broadcasts a started and a finished event.
 *
 * A settings reload past its deadline answers superseded and leaves the
 * staged request in place. Otherwise it claims the staged request and
 * starts it on the running TUN. It promotes the request over `start.json`
 * only when the reload applied. A promote arms or disarms the measure cap,
 * [OneVpnMeasureTimeout]. Every outcome removes the claim.
 *
 * A network reload runs once per change of the monitored network. It
 * restarts the core from `start.json` onto itself and touches no staged or
 * claimed request. A change older than the latest reload that restarted
 * the core runs no reload. That core already dials on the new network. A
 * network reload that answers failed arms the single automatic retry. The
 * next change with a readable status consumes the retry. If the TUN is
 * still held, that change starts the service over it once. A resolver
 * change on one network runs a reload only when `start.json` carries the
 * direct DNS server.
 */
object OneVpnHandoverService {
    /** The staged request. The policy writes it before each reload. */
    private const val STAGED_RELATIVE_PATH = "run/onevpn_start.next.json"

    /** The running request. Must match the service's start snapshot. */
    private const val START_RELATIVE_PATH = "run/start.json"

    /** The staged request while a reload holds it. */
    private const val CLAIMED_RELATIVE_PATH = "run/onevpn_start.claimed.json"

    /** Starts every network reload id. */
    private const val NETWORK_PREFIX = "network-"

    private val executor = Executors.newSingleThreadExecutor()

    private val networkSequence = AtomicInteger()

    /**
     * When the latest reload that restarted the core began, in
     * `SystemClock.elapsedRealtime`. Set once that reload answers.
     */
    @Volatile
    private var coreStartedAt = 0L

    /** The outcomes of a reload that stopped the core and started one. */
    private val coreStarts = setOf(
        ReloadOutcome.APPLIED,
        ReloadOutcome.ROLLED_BACK,
        ReloadOutcome.FAILED,
        ReloadOutcome.SUPERSEDED,
    )

    private class Attachment(
        val service: Service,
        val reload: (String, String) -> ReloadOutcome,
        val receivers: List<BroadcastReceiver>,
        val monitor: OneVpnNetworkMonitor,
    ) {
        /** Set by a network reload that failed twice. The next readable change consumes it. */
        @Volatile
        var retry = false
    }

    @Volatile
    private var attached: Attachment? = null

    /** The staged request the policy writes. */
    private fun stagedFile(context: Context): File = File(context.filesDir, STAGED_RELATIVE_PATH)

    /** The running request. */
    private fun startFile(context: Context): File = File(context.filesDir, START_RELATIVE_PATH)

    /** The network the attached monitor follows, or null with none attached. */
    fun network(): Network? = attached?.monitor?.network()

    /**
     * Registers the reload receivers and starts the network monitor on
     * [service]. A registration that throws unregisters the ones before it
     * and rethrows. A monitor that cannot request its network stays inert.
     * A re-attach with no detach between carries the previous monitor's
     * network and pending change into the new one.
     */
    fun attach(service: Service, reload: (String, String) -> ReloadOutcome) {
        synchronized(this) {
            val previous = attached?.monitor
            detachLocked()
            val context = service.applicationContext
            val receivers = mutableListOf<BroadcastReceiver>()
            try {
                val request = receiver { intent ->
                    val requestId = intent.getStringExtra(OneVpnHandoverBroadcast.EXTRA_REQUEST_ID)
                    val deadline = intent.getLongExtra(OneVpnHandoverBroadcast.EXTRA_DEADLINE, 0L)
                    if (!requestId.isNullOrBlank()) {
                        executor.execute {
                            settingsReload(context, requestId, deadline)
                        }
                    }
                }
                ContextCompat.registerReceiver(
                    service,
                    request,
                    IntentFilter(OneVpnHandoverBroadcast.ACTION_REQUEST),
                    ContextCompat.RECEIVER_NOT_EXPORTED,
                )
                receivers += request
            } catch (e: Exception) {
                unregister(service, receivers)
                throw e
            }
            val monitor = OneVpnNetworkMonitor(context, previous)
            attached = Attachment(service, stamped(reload), receivers, monitor)
            monitor.start { change -> executor.execute { networkReload(context, monitor, change) } }
        }
    }

    fun detach() {
        synchronized(this) { detachLocked() }
    }

    private fun detachLocked() {
        val current = attached ?: return
        attached = null
        current.monitor.close()
        unregister(current.service, current.receivers)
    }

    /** [reload], recording when each call that restarted the core began. */
    private fun stamped(reload: (String, String) -> ReloadOutcome): (String, String) -> ReloadOutcome =
        { next, fallback ->
            val begin = SystemClock.elapsedRealtime()
            reload(next, fallback).also { if (it in coreStarts) coreStartedAt = begin }
        }

    private fun unregister(service: Service, receivers: List<BroadcastReceiver>) {
        for (receiver in receivers) {
            try {
                service.unregisterReceiver(receiver)
            } catch (_: IllegalArgumentException) {
            }
        }
    }

    private fun receiver(onReceive: (Intent) -> Unit): BroadcastReceiver =
        object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                intent?.let(onReceive)
            }
        }

    private fun settingsReload(context: Context, requestId: String, deadline: Long) {
        val begin = SystemClock.elapsedRealtime()
        OneVpnHandoverBroadcast.sendEvent(
            context,
            ReloadEvent(requestId, ReloadTrigger.SETTINGS, ReloadPhase.STARTED),
        )
        val result = settingsResult(context, deadline)
        OneVpnHandoverBroadcast.sendEvent(
            context,
            ReloadEvent(requestId, ReloadTrigger.SETTINGS, ReloadPhase.FINISHED, result),
        )
        XLog.i(
            "OneVpnHandover: reload trigger=settings requestId=$requestId " +
                "result=$result durationMs=${SystemClock.elapsedRealtime() - begin}"
        )
    }

    private fun settingsResult(context: Context, deadline: Long): ReloadResult {
        // Must run before the claim: a late request leaves the staged request to the next one.
        if (SystemClock.elapsedRealtime() > deadline) return ReloadResult.SUPERSEDED
        val claimed = File(context.filesDir, CLAIMED_RELATIVE_PATH)
        val claim = stagedFile(context).renameTo(claimed)
        try {
            val reload = attached?.reload ?: return ReloadResult.NOT_RUNNING
            if (!claim) return ReloadResult.INVALID_REQUEST
            val start = startFile(context)
            val next = readRequest(claimed) ?: return ReloadResult.INVALID_REQUEST
            val current = readRequest(start) ?: return ReloadResult.INVALID_REQUEST
            val nextCore = next.coreInvokeText
            val fallbackCore = current.coreInvokeText
            // The reload never changes the TUN, so start.json keeps describing it.
            if (nextCore == null || fallbackCore == null || next.tun != current.tun) {
                return ReloadResult.INVALID_REQUEST
            }
            val outcome = reload(nextCore, fallbackCore)
            if (outcome != ReloadOutcome.APPLIED) return resultOf(outcome)
            if (claimed.renameTo(start)) {
                // A promoted measure config arms the cap. A promoted pinned config disarms it.
                OneVpnMeasureTimeout.arm(context)
                return resultOf(outcome)
            }
            XLog.e("OneVpnHandover: promote failed, restoring the previous core")
            val restored = resultOf(reload(fallbackCore, fallbackCore))
            return if (restored == ReloadResult.APPLIED) ReloadResult.ROLLED_BACK else restored
        } finally {
            claimed.delete()
        }
    }

    private fun networkReload(
        context: Context,
        monitor: OneVpnNetworkMonitor,
        change: OneVpnNetworkMonitor.Change,
    ) {
        // A stop or a start since the change detached the monitor: the user command wins.
        val attachment = attached?.takeIf { it.monitor === monitor } ?: return
        val netIds = "${change.from}->${change.to}"
        if (attachment.retry) {
            // An unreadable status keeps the retry armed for the next change.
            val held = runBlocking { OneVpnTunnelStatus.held(context) }
            if (held != null) attachment.retry = false
            if (held == true) return retryStart(context, attachment, netIds)
        }
        if (coreStartedAt > change.at) {
            XLog.i("OneVpnHandover: network change coalesced netIds=$netIds")
            return
        }
        if (change.from == change.to && !OneVpnDirectDns.carried(readRequest(startFile(context)))) {
            XLog.i("OneVpnHandover: resolver change ignored")
            return
        }
        val requestId = "$NETWORK_PREFIX${System.currentTimeMillis()}-${networkSequence.incrementAndGet()}"
        val begin = SystemClock.elapsedRealtime()
        OneVpnHandoverBroadcast.sendEvent(
            context,
            ReloadEvent(requestId, ReloadTrigger.NETWORK, ReloadPhase.STARTED),
        )
        val result = networkResult(context, attachment.reload)
        OneVpnHandoverBroadcast.sendEvent(
            context,
            ReloadEvent(requestId, ReloadTrigger.NETWORK, ReloadPhase.FINISHED, result),
        )
        if (result == ReloadResult.FAILED) attachment.retry = true
        XLog.i(
            "OneVpnHandover: reload trigger=network requestId=$requestId netIds=$netIds " +
                "result=$result durationMs=${SystemClock.elapsedRealtime() - begin}"
        )
    }

    /** Restarts the core from `start.json` onto itself. Reads no staged or claimed request. */
    private fun networkResult(context: Context, reload: (String, String) -> ReloadOutcome): ReloadResult {
        val core = readRequest(startFile(context))?.coreInvokeText ?: return ReloadResult.INVALID_REQUEST
        return resultOf(reload(core, core))
    }

    /**
     * The single automatic retry. Starts the service as a connect does, which
     * keeps the held TUN up until its replacement is established. Sends
     * nothing once a stop has detached [attachment]. The service drops the
     * start when a stop released the TUN before it arrived.
     */
    private fun retryStart(context: Context, attachment: Attachment, netIds: String) {
        synchronized(this) {
            if (attached !== attachment) return
            try {
                context.startService(
                    VpnController.buildStartIntent(context)
                        .putExtra(OneVpnServiceDelegate.EXTRA_HELD_RETRY, true)
                )
            } catch (e: RuntimeException) {
                XLog.e("OneVpnHandover: retry failed (${e.javaClass.simpleName})")
                return
            }
        }
        XLog.i("OneVpnHandover: retry trigger=network netIds=$netIds")
    }

    /** The contract result for [outcome]. */
    private fun resultOf(outcome: ReloadOutcome): ReloadResult = when (outcome) {
        ReloadOutcome.APPLIED -> ReloadResult.APPLIED
        ReloadOutcome.ROLLED_BACK -> ReloadResult.ROLLED_BACK
        ReloadOutcome.FAILED -> ReloadResult.FAILED
        ReloadOutcome.NOT_RUNNING -> ReloadResult.NOT_RUNNING
        ReloadOutcome.SUPERSEDED -> ReloadResult.SUPERSEDED
        ReloadOutcome.INVALID -> ReloadResult.INVALID_REQUEST
    }

    /** The decoded request in [file], or null. Logs only the file name. */
    private fun readRequest(file: File): StartVpnRequest? =
        try {
            JsonTool.json.decodeFromString<StartVpnRequest>(file.readText())
        } catch (_: Exception) {
            XLog.w("OneVpnHandover: unreadable request ${file.name}")
            null
        }
}
