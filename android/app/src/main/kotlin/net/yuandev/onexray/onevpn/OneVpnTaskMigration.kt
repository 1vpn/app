package net.yuandev.onexray.onevpn

import android.app.Activity
import android.app.ActivityManager

/**
 * Finishes the tasks of the app other than the main activity's. The tasks
 * it finds are the ones builds up to 3.0.0 made: a main task without a task
 * affinity, and ad and billing tasks. Remove this file when the installs
 * that ran those builds have updated.
 *
 * [OneVpnPlatformChannel.setUp] runs [run] once per creation of the main
 * activity. It keeps no state, and with no other task it finds nothing. It
 * runs before the app's logger is initialised and logs nothing.
 */
object OneVpnTaskMigration {
    /**
     * Finishes and removes every task of the app other than the task of
     * [activity], and answers how many finished. Answers zero when the task
     * list cannot be read. Never throws on a refused system call.
     */
    fun run(activity: Activity): Int = guarded(0) {
        val manager = activity.getSystemService(ActivityManager::class.java)
            ?: return@guarded 0
        var finished = 0
        for (task in manager.appTasks) {
            // A task that left since the listing has no info.
            val info = guarded(null) { task.taskInfo } ?: continue
            if (info.taskId == activity.taskId) continue
            // A task that left since the listing throws.
            val done = guarded(false) {
                task.finishAndRemoveTask()
                true
            }
            if (done) finished++
        }
        finished
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
