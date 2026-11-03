package net.yuandev.onexray.onevpn

import android.content.Intent
import android.os.Bundle

/**
 * The start shortcut's launch extra on the intent that creates the activity.
 * A restored activity and a launch from Recents carry an earlier intent with
 * its extras. [dropReplayedLaunch] removes the launch extra from them, so only
 * a new shortcut launch runs the shortcut.
 */
object OneVpnStartShortcutIntent {
    /**
     * The extra the quick_actions plugin puts on a shortcut's intent. It holds
     * the shortcut's id. The plugin reads it from the activity's intent when
     * it attaches to the activity and when the Dart side initializes it, and
     * either read delivers the launch. Must equal the plugin's
     * `QuickActions.EXTRA_ACTION`.
     */
    const val EXTRA_ACTION: String = "some unique action key"

    /**
     * Removes [EXTRA_ACTION] from [intent] when the activity is restored, with
     * a non-null [savedInstanceState], or when [intent] carries
     * [Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY]. Any other intent keeps it.
     * Must run before `super.onCreate`: the plugin can read the intent from
     * there on.
     */
    fun dropReplayedLaunch(intent: Intent?, savedInstanceState: Bundle?) {
        if (intent == null) return
        if (savedInstanceState != null ||
            (intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY) != 0
        ) {
            intent.removeExtra(EXTRA_ACTION)
        }
    }
}
