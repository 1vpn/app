package net.yuandev.onexray.onevpn.handover

import android.content.Context
import android.content.Intent

/**
 * The reload broadcasts between the main process and `:native`. Each one is
 * scoped to this package. The receivers for [ACTION_REQUEST] and
 * [ACTION_EVENT] register as not exported. The action names are frozen once
 * shipped.
 */
object OneVpnHandoverBroadcast {
    /** Main process to `:native`: reload from the staged request. */
    const val ACTION_REQUEST: String = "net.yuandev.onexray.onevpn.RELOAD_REQUEST"

    /** `:native` to the main process: one reload phase change. */
    const val ACTION_EVENT: String = "net.yuandev.onexray.onevpn.RELOAD_EVENT"

    const val EXTRA_REQUEST_ID: String = "requestId"

    /**
     * The `SystemClock.elapsedRealtime` value after which the request
     * answers superseded before it claims the staged request. Both
     * processes read the same clock.
     */
    const val EXTRA_DEADLINE: String = "deadline"

    private const val EXTRA_TRIGGER = "trigger"
    private const val EXTRA_PHASE = "phase"
    private const val EXTRA_RESULT = "result"

    fun sendRequest(context: Context, requestId: String, deadline: Long) {
        context.sendBroadcast(
            scoped(context, ACTION_REQUEST)
                .putExtra(EXTRA_REQUEST_ID, requestId)
                .putExtra(EXTRA_DEADLINE, deadline)
        )
    }

    fun sendEvent(context: Context, event: ReloadEvent) {
        context.sendBroadcast(
            scoped(context, ACTION_EVENT)
                .putExtra(EXTRA_REQUEST_ID, event.requestId)
                .putExtra(EXTRA_TRIGGER, event.trigger.name)
                .putExtra(EXTRA_PHASE, event.phase.name)
                .putExtra(EXTRA_RESULT, event.result?.name)
        )
    }

    /** The event [intent] carries, or null for a malformed one. */
    fun readEvent(intent: Intent): ReloadEvent? {
        if (intent.action != ACTION_EVENT) return null
        val trigger = ReloadTrigger.entries.firstOrNull {
            it.name == intent.getStringExtra(EXTRA_TRIGGER)
        } ?: return null
        val phase = ReloadPhase.entries.firstOrNull {
            it.name == intent.getStringExtra(EXTRA_PHASE)
        } ?: return null
        val result = intent.getStringExtra(EXTRA_RESULT)?.let { name ->
            ReloadResult.entries.firstOrNull { it.name == name } ?: return null
        }
        return ReloadEvent(intent.getStringExtra(EXTRA_REQUEST_ID), trigger, phase, result)
    }

    // Foreground delivery keeps the broadcast queue inside the RELOAD_WAIT_MS bound.
    private fun scoped(context: Context, action: String): Intent =
        Intent(action)
            .setPackage(context.packageName)
            .addFlags(Intent.FLAG_RECEIVER_FOREGROUND)
}
