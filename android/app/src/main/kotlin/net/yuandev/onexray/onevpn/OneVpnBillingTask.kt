package net.yuandev.onexray.onevpn

import android.app.Activity
import android.app.ActivityManager
import com.elvishew.xlog.XLog

/**
 * The app's billing tasks: tasks whose base activity is the billing
 * library's proxy activity. Play's purchase sheet runs in such a task,
 * apart from the task of the single-instance main activity. Home therefore
 * leaves the sheet behind, and a launcher start brings back only the main
 * task.
 *
 * [restore] brings a running billing task with a sheet on top to the front.
 * [finish] finishes and removes every billing task. A running proxy activity
 * that finishes reports a cancel to the billing library. A billing task with
 * no running activity is a Recents entry that would restart the proxy with a
 * spent purchase intent. Both skip the task of the calling activity, and both
 * answer false when the task list cannot be read.
 *
 * The debug log names classes, the running flag and the activity count only.
 * It never names the base intent or its extras.
 */
object OneVpnBillingTask {
    /**
     * The billing library's proxy activity. It is matched by class name, so
     * the app needs no compile dependency on the billing library.
     */
    private const val PROXY = "com.android.billingclient.api.ProxyBillingActivity"

    /**
     * Moves a running billing task whose top activity is not the proxy to the
     * front, and answers whether one moved.
     *
     * A task that is not running stays where it is: a move would restart its
     * base intent against the live purchase.
     */
    fun restore(activity: Activity): Boolean = guarded(false) {
        val sheet = billingTasks(activity, "restore").firstOrNull { (_, info) ->
            info.isRunning && info.topActivity?.className != PROXY
        }
        sheet?.first?.moveToFront()
        sheet != null
    }

    /**
     * Finishes and removes every billing task, running or not, and answers
     * whether one finished.
     */
    fun finish(activity: Activity): Boolean = guarded(false) {
        var finished = false
        for ((task, _) in billingTasks(activity, "finish")) {
            // A task that left since the listing throws.
            val done = guarded(false) {
                task.finishAndRemoveTask()
                true
            }
            finished = done || finished
        }
        finished
    }

    /** The billing tasks other than the task of [activity], each with its info. */
    private fun billingTasks(
        activity: Activity,
        action: String,
    ): List<Pair<ActivityManager.AppTask, ActivityManager.RecentTaskInfo>> {
        val manager = activity.getSystemService(ActivityManager::class.java) ?: return emptyList()
        return manager.appTasks.mapNotNull { task ->
            // A task that left since the listing has no info.
            val info = guarded(null) { task.taskInfo } ?: return@mapNotNull null
            if (info.taskId == activity.taskId || info.baseIntent.component?.className != PROXY) {
                return@mapNotNull null
            }
            XLog.d(
                "OneVpnBillingTask: $action base=${info.baseActivity?.className} " +
                    "top=${info.topActivity?.className} running=${info.isRunning} " +
                    "activities=${info.numActivities}",
            )
            task to info
        }
    }

    /** Runs [block], or answers [fallback] when the system refuses the call. */
    private inline fun <T> guarded(fallback: T, block: () -> T): T =
        try {
            block()
        } catch (_: IllegalArgumentException) {
            fallback
        } catch (_: SecurityException) {
            fallback
        }
}
