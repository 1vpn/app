package net.yuandev.onexray.onevpn.handover

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.SystemClock
import androidx.core.content.ContextCompat
import com.elvishew.xlog.XLog
import io.flutter.plugin.common.BinaryMessenger
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeout
import net.yuandev.onexray.onevpn.OneVpnTunnelStatus
import net.yuandev.onexray.pigeon.VpnStatus

/**
 * The main-process side of [OneVpnHandoverHostApi], one per Flutter engine.
 * It runs on the main thread.
 *
 * [reload] sends the request broadcast to `:native` with a deadline of
 * [RELOAD_WAIT_MS]. It answers the result of its finished event. Every event
 * from `:native` reaches Dart before the reload it belongs to answers. The
 * caller validates the staged request with testXray before it calls
 * [reload]. The caller gives each reload a request id that no other reload
 * uses.
 */
class OneVpnHandoverHost(
    private val context: Context,
    private val messenger: BinaryMessenger,
) : OneVpnHandoverHostApi {
    companion object {
        /**
         * Bounds the main-process wait for a reload's finished event. The Dart
         * bound sits above it, so the native answer arrives first.
         */
        const val RELOAD_WAIT_MS: Long = 15_000L
    }

    private val flutterApi = OneVpnHandoverFlutterApi(messenger)
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private val pending = mutableMapOf<String, CompletableDeferred<ReloadResult>>()
    private var closed = false

    private val events = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val event = intent?.let(OneVpnHandoverBroadcast::readEvent) ?: return
            flutterApi.reloadEvent(event) {}
            val result = event.result ?: return
            if (event.phase == ReloadPhase.FINISHED) {
                event.requestId?.let(pending::get)?.complete(result)
            }
        }
    }

    init {
        ContextCompat.registerReceiver(
            context,
            events,
            IntentFilter(OneVpnHandoverBroadcast.ACTION_EVENT),
            ContextCompat.RECEIVER_NOT_EXPORTED,
        )
    }

    /**
     * True while a running core can be reloaded: the tunnel interface is up
     * and the service reads connected. False in the held state.
     */
    override fun reloadSupported(callback: (Result<Boolean>) -> Unit) {
        scope.launch { callback(Result.success(reloadable())) }
    }

    override fun reload(request: ReloadRequest, callback: (Result<ReloadResult>) -> Unit) {
        scope.launch { callback(Result.success(awaitReload(request.requestId))) }
    }

    /** Answers every reload in flight with timeout, then stops handling calls. */
    fun close() {
        closed = true
        OneVpnHandoverHostApi.setUp(messenger, null)
        try {
            context.unregisterReceiver(events)
        } catch (_: IllegalArgumentException) {
        }
        for (finished in pending.values.toList()) finished.complete(ReloadResult.TIMEOUT)
    }

    private suspend fun reloadable(): Boolean =
        OneVpnTunnelStatus.read(context) == VpnStatus.CONNECTED

    private suspend fun awaitReload(requestId: String): ReloadResult {
        if (closed) return ReloadResult.TIMEOUT
        if (requestId.isBlank() || requestId in pending) return ReloadResult.INVALID_REQUEST
        val finished = CompletableDeferred<ReloadResult>()
        pending[requestId] = finished
        try {
            if (!reloadable()) return ReloadResult.NOT_RUNNING
            if (finished.isCompleted) return finished.await()
            try {
                val deadline = SystemClock.elapsedRealtime() + RELOAD_WAIT_MS
                OneVpnHandoverBroadcast.sendRequest(context, requestId, deadline)
            } catch (error: RuntimeException) {
                XLog.e("OneVpnHandoverHost: reload request failed", error)
                return ReloadResult.TIMEOUT
            }
            return withTimeout(RELOAD_WAIT_MS) { finished.await() }
        } catch (_: TimeoutCancellationException) {
            XLog.w("OneVpnHandoverHost: reload $requestId outlived its bound")
            return ReloadResult.TIMEOUT
        } finally {
            pending.remove(requestId)
        }
    }
}
