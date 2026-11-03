package net.yuandev.onexray.onevpn

import android.content.Context
import com.elvishew.xlog.XLog
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.jsonObject
import net.yuandev.onexray.pigeon.JsonTool
import net.yuandev.onexray.pigeon.LibXrayInvokeRequest
import net.yuandev.onexray.pigeon.StartVpnRequest
import net.yuandev.onexray.vpn.VpnController
import java.io.File
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledFuture
import java.util.concurrent.TimeUnit

/**
 * The native cap on a measure core. The app's Dart side measures, picks and
 * pins. While it measures, `start.json` carries the measure config and the
 * TUN blocks every flow.
 *
 * [arm] starts the cap when `start.json` carries a measure config and
 * cancels any earlier cap. [TIMEOUT_MS] after the arm, the cap reads
 * `start.json` again. A measure config still in place stops the tunnel
 * through [VpnController.stopVpn], as a user disconnect does. The core stops,
 * the TUN closes and the notification goes. The user-stop marker then vetoes
 * a sticky restart. [disarm] cancels the cap. A pinned config never trips it.
 *
 * The cap covers a measure the Dart side no longer drives. The app process
 * died, a sticky or always-on restart ran the measure config with no app, or
 * the Dart run ended held.
 */
object OneVpnMeasureTimeout {
    /**
     * How long a measure core runs before the cap stops the tunnel. When no
     * server answers, the Dart all-dead cap plus the hold cap, about 65 s,
     * ends the measure first. A pin that a late answer starts can still be
     * running at 90 s. The cap then stops it as a plain disconnect, and the
     * user retries.
     */
    const val TIMEOUT_MS: Long = 90_000L

    /**
     * The tag of the only routing rule in a measure config. Must equal the
     * Dart side's `oneVpnMeasureBlockRuleTag`.
     */
    const val MEASURE_BLOCK_RULE_TAG: String = "app-measure-block"

    /** The config key that carries the measure core's probes. */
    private const val OBSERVATORY_KEY = "burstObservatory"

    /** The running request. Must match the service's start snapshot. */
    private const val START_RELATIVE_PATH = "run/start.json"

    private val executor = Executors.newSingleThreadScheduledExecutor()

    private var pending: ScheduledFuture<*>? = null

    /** Counts arms and disarms. A check from an older arm stops nothing. */
    private var generation = 0

    /**
     * Cancels any cap, then starts one when `start.json` under [context]
     * carries a measure config. Logs and never throws.
     */
    fun arm(context: Context) {
        val app = context.applicationContext
        synchronized(this) {
            cancelLocked()
            if (!measuring(app)) return
            val armed = generation
            try {
                pending = executor.schedule({ expire(app, armed) }, TIMEOUT_MS, TimeUnit.MILLISECONDS)
            } catch (e: Exception) {
                XLog.d("OneVpnMeasureTimeout: arm failed")
                XLog.d(e)
            }
        }
    }

    /** Cancels the cap. Does nothing when none is armed. Never throws. */
    fun disarm() {
        synchronized(this) { cancelLocked() }
    }

    private fun cancelLocked() {
        generation++
        pending?.cancel(false)
        pending = null
    }

    /**
     * Stops the tunnel when the arm [armed] still stands, the tunnel
     * interface is up and `start.json` still carries a measure config. The
     * checks and the stop request run under one lock, so an arm or a disarm
     * in between leaves the newer measure running.
     */
    private fun expire(context: Context, armed: Int) {
        synchronized(this) {
            if (armed != generation) return
            pending = null
            // A cap armed just before a release outlives it. With the interface down it stops nothing.
            if (!VpnController.readVpnRunning(context) || !measuring(context)) return
            XLog.i("OneVpnMeasureTimeout: measure core outlived ${TIMEOUT_MS}ms, stopping")
            if (!VpnController.stopVpn(context)) {
                XLog.e("OneVpnMeasureTimeout: stop request failed (${VpnController.lastError})")
            }
        }
    }

    /** Whether `start.json` under [context] carries a measure config. An unreadable file reads false. */
    private fun measuring(context: Context): Boolean =
        try {
            val start = JsonTool.json.decodeFromString<StartVpnRequest>(
                File(context.filesDir, START_RELATIVE_PATH).readText(),
            )
            val invoke = JsonTool.json.decodeFromString<LibXrayInvokeRequest>(
                requireNotNull(start.coreInvokeText),
            )
            val xrayJson = requireNotNull(invoke.payload?.xrayJson)
            isMeasureConfig(JsonTool.json.parseToJsonElement(xrayJson).jsonObject)
        } catch (_: Exception) {
            // Decoder errors may contain the input, including node credentials.
            XLog.w("OneVpnMeasureTimeout: start request unreadable")
            false
        }

    /**
     * Whether [config] is a measure config: it carries `burstObservatory`
     * and its routing holds exactly one rule, tagged
     * [MEASURE_BLOCK_RULE_TAG]. A pinned config ends in the catch-all rule
     * and reads false.
     */
    fun isMeasureConfig(config: JsonObject): Boolean {
        if (!config.containsKey(OBSERVATORY_KEY)) return false
        val rules = (config["routing"] as? JsonObject)?.get("rules") as? JsonArray ?: return false
        val rule = rules.singleOrNull() as? JsonObject ?: return false
        val tag = rule["ruleTag"] as? JsonPrimitive ?: return false
        return tag.isString && tag.content == MEASURE_BLOCK_RULE_TAG
    }
}
