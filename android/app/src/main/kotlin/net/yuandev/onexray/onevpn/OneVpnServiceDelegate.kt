package net.yuandev.onexray.onevpn

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.VpnService
import com.elvishew.xlog.XLog
import kotlinx.serialization.json.JsonObject
import net.yuandev.onexray.MainActivity
import net.yuandev.onexray.R
import net.yuandev.onexray.onevpn.handover.OneVpnHandoverService
import net.yuandev.onexray.pigeon.PerAppVPNMode
import net.yuandev.onexray.pigeon.TunJson
import net.yuandev.onexray.vpn.OneVpnService
import java.io.File

/**
 * The fork-owned companion to the VPN service. Each hook in the upstream
 * service file is a single line that calls in here. The behavior lives
 * in this object or in the fork file it calls. The delegate runs in the
 * service's `:native` process and shares no memory with the main
 * process. Files under the run directory and package-scoped broadcasts
 * are the only channels between the two processes.
 */
object OneVpnServiceDelegate {
    // This path must differ from the stop-request token's file. The check
    // that reads the token deletes it. The token's path constant is private
    // to VpnController. This marker stays readable after that check runs.
    private const val userStopMarkerRelativePath = "run/onevpn_user.stop"

    // The start request that only an in-app connect writes.
    private const val startRequestRelativePath = "run/start.json"

    // The tag keeps the notice apart from the service's foreground
    // notification, whose id is the start id.
    private const val updateNoticeTag = "net.yuandev.onexray.onevpn.UPDATE_NOTICE"
    private const val updateNoticeId = 1
    private const val updateNoticeChannelId = "com.one.vpnapp.update"

    /**
     * Marks a start intent as the network trigger's single retry over a
     * held TUN. The name is frozen once shipped.
     */
    const val EXTRA_HELD_RETRY: String = "net.yuandev.onexray.onevpn.HELD_RETRY"

    /**
     * The builder policy pass. The service calls it before `establish()`,
     * after its address and per-app setup, with the TUN config in scope.
     * [selfPackage] is this app's own package name. Marks the VPN network
     * unmetered. The platform defaults a VPN to metered for apps targeting
     * Q+. `false` restores inheritance from the underlying network. minSdk
     * 29 keeps the call unguarded.
     *
     * Outside the allow-list mode, excludes [selfPackage] from the tunnel.
     * The app's own sockets then never enter it. Other apps keep their
     * routing, and the core's protected sockets bypass the tunnel either
     * way. Under lockdown the platform keeps the VPN app's own uid
     * connected. In the allow-list mode only the listed apps enter the
     * tunnel. A failed package lookup is logged and keeps the app inside.
     */
    fun applyBuilderPolicy(
        builder: VpnService.Builder,
        tun: TunJson,
        selfPackage: String,
    ) {
        builder.setMetered(false)
        // The platform rejects a disallow call once an allow call has run.
        if (tun.perAppVPNMode != PerAppVPNMode.ALLOW) {
            try {
                builder.addDisallowedApplication(selfPackage)
            } catch (e: PackageManager.NameNotFoundException) {
                XLog.d("OneVpnServiceDelegate: self exclusion failed")
                XLog.d(e)
            }
        }
    }

    /**
     * The direct DNS patch for one core start or reload. It fills or removes
     * the direct DNS server in each parsed configuration it gets. All of them
     * share one network read, taken when the first carries the server. The
     * read follows the attached monitor, or the best non-VPN network without
     * one. Never throws.
     */
    fun directDnsPatch(context: Context): (JsonObject) -> JsonObject {
        val reading = lazy { OneVpnDirectDns.read(context, OneVpnHandoverService.network()) }
        return { root -> OneVpnDirectDns.patch(root, reading) }
    }

    /**
     * The return value for a start command that the service handled.
     * Consumes the user-stop marker: a handled start supersedes the user's
     * last stop. Returns [Service.START_STICKY]. A process death after a
     * handled start then arms a system restart. The restart arrives as the
     * null intent that [onUnrecognizedStart] handles.
     */
    fun runningResult(context: Context): Int {
        consumeUserStop(context)
        cancelUpdateNotice(context)
        return Service.START_STICKY
    }

    /**
     * Handles a start whose intent carries no recognized action.
     * [pendingStop] consumes the app-side stop-request token and reports
     * whether one stood. The app process writes that token before it
     * broadcasts a stop. A standing token is a stop whose broadcast never
     * reached this process. [start] starts the tunnel unless it is
     * already running.
     *
     * [VpnService.SERVICE_INTERFACE] is the system's always-on start. The
     * system sends it on user unlock, a package update and the Settings
     * toggle. It does not send it after a process death. The delegate must
     * dial the start: under lockdown, a declined start blocks all traffic.
     * The delegate consumes both stop records. [start] runs whether or not
     * either stands. With no start request on disk, the delegate first posts
     * a notice to open 1VPN once to finish the update. The start then fails
     * closed. An in-app connect writes the request, and a handled start
     * clears the notice.
     *
     * A null intent or null action is the sticky redelivery after a
     * process death. A standing token vetoes the restart. The veto also
     * writes the user-stop marker. The marker keeps the veto after
     * [pendingStop] consumes the token. With no token, [start] runs unless
     * the user-stop marker stands. Dialing consumes the marker.
     *
     * Any other action does nothing. Returns [Service.START_STICKY] when
     * dialing and [Service.START_NOT_STICKY] otherwise.
     */
    fun onUnrecognizedStart(
        context: Context,
        intent: Intent?,
        startId: Int,
        pendingStop: () -> Boolean,
        start: () -> Unit,
    ): Int {
        val action = intent?.action
        if (action == VpnService.SERVICE_INTERFACE) {
            XLog.d("OneVpnServiceDelegate: always-on start")
            pendingStop()
            consumeUserStop(context)
            if (!File(context.filesDir, startRequestRelativePath).exists()) {
                postUpdateNotice(context)
            }
            start()
            return Service.START_STICKY
        }
        if (action == null) {
            if (pendingStop()) {
                XLog.d("OneVpnServiceDelegate: restart vetoed by pending stop request")
                markUserStop(context)
                return Service.START_NOT_STICKY
            }
            if (userStopStands(context)) {
                XLog.d("OneVpnServiceDelegate: restart vetoed by user stop")
                return Service.START_NOT_STICKY
            }
            XLog.d("OneVpnServiceDelegate: restoring after process death")
            consumeUserStop(context)
            start()
            return Service.START_STICKY
        }
        return Service.START_NOT_STICKY
    }

    /**
     * Posts the notice that asks the user to open 1VPN once to finish the
     * update. A tap opens the app and dismisses the notice. Catches and logs
     * every failure: the notice must never block the start.
     */
    private fun postUpdateNotice(context: Context) {
        try {
            val manager = context.getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(
                NotificationChannel(
                    updateNoticeChannelId,
                    context.getString(R.string.onevpn_notification_channel_updates),
                    NotificationManager.IMPORTANCE_DEFAULT,
                ),
            )
            val open = PendingIntent.getActivity(
                context,
                0,
                Intent(context, MainActivity::class.java).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                },
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
            val text = context.getString(R.string.onevpn_notification_open_after_update)
            val notice = Notification.Builder(context, updateNoticeChannelId)
                .setContentTitle(context.getString(R.string.quick_settings_tile_label))
                .setContentText(text)
                .setStyle(Notification.BigTextStyle().bigText(text))
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentIntent(open)
                .setAutoCancel(true)
                .build()
            manager.notify(updateNoticeTag, updateNoticeId, notice)
            XLog.d("OneVpnServiceDelegate: no start request, update notice posted")
        } catch (e: Exception) {
            XLog.d("OneVpnServiceDelegate: update notice failed")
            XLog.d(e)
        }
    }

    /** Removes the update notice when it shows. Never throws. */
    private fun cancelUpdateNotice(context: Context) {
        try {
            context.getSystemService(NotificationManager::class.java)
                .cancel(updateNoticeTag, updateNoticeId)
        } catch (e: Exception) {
            XLog.d("OneVpnServiceDelegate: update notice cancel failed")
            XLog.d(e)
        }
    }

    /**
     * The stop-path mark, the first statement of the service's stopTun.
     * Records that the tunnel's last stop was deliberate. The user-stop
     * marker vetoes a later sticky restart. Every stopTun caller carries
     * that meaning, onRevoke included: a system revocation counts as a
     * deliberate stop. The restart veto in onUnrecognizedStart also writes
     * the marker. The marker keeps the veto after onUnrecognizedStart
     * consumes the stop token. Catches and logs marker IO: a failed write
     * must never break a stop.
     */
    fun markUserStop(context: Context) {
        try {
            val marker = markerFile(context)
            marker.parentFile?.mkdirs()
            marker.createNewFile()
        } catch (e: Exception) {
            XLog.d("OneVpnServiceDelegate: markUserStop failed")
            XLog.d(e)
        }
    }

    /**
     * The start guard, the first statement of the service's start branch.
     * [held] is whether a failed start holds the TUN. Answers true to drop
     * [intent]: a retry start that finds no held TUN, because a stop
     * released it first. The retry can then only replace a held TUN.
     * Every other start passes.
     */
    fun dropsStart(intent: Intent, held: Boolean): Boolean {
        if (held || !intent.getBooleanExtra(EXTRA_HELD_RETRY, false)) return false
        XLog.d("OneVpnServiceDelegate: retry start dropped, no held TUN")
        return true
    }

    /**
     * The tunnel-up hook. The service calls it after it broadcasts a
     * started core, while no release has begun since the start. The
     * service's onDestroy also calls [onTunnelDown]: a release can still
     * land just before this call. [reload] is the service's in-place core
     * restart. It blocks and must run off the main thread. Arms the
     * measure cap, [OneVpnMeasureTimeout]. Never throws: it logs a failed
     * attach and leaves nothing registered.
     */
    fun onTunnelUp(
        service: Service,
        reload: (String, String) -> OneVpnService.ReloadOutcome,
    ) {
        OneVpnMeasureTimeout.arm(service)
        try {
            OneVpnHandoverService.attach(service, reload)
        } catch (e: Exception) {
            XLog.d("OneVpnServiceDelegate: onTunnelUp failed")
            XLog.d(e)
        }
    }

    /**
     * The tunnel-down hook. Each release calls it before the core stops.
     * The service's onDestroy also calls it. Does nothing when nothing is
     * attached. A reload that starts before the next tunnel-up hook answers
     * not running. Disarms the measure cap. Never throws: it logs a failed
     * detach.
     */
    fun onTunnelDown() {
        OneVpnMeasureTimeout.disarm()
        try {
            OneVpnHandoverService.detach()
        } catch (e: Exception) {
            XLog.d("OneVpnServiceDelegate: onTunnelDown failed")
            XLog.d(e)
        }
    }

    /** The delegate's own stop marker under the run directory. */
    private fun markerFile(context: Context): File =
        File(context.filesDir, userStopMarkerRelativePath)

    /**
     * True while the user-stop marker stands. It reads the marker and never
     * deletes it.
     */
    private fun userStopStands(context: Context): Boolean =
        try {
            markerFile(context).exists()
        } catch (e: Exception) {
            // An unreadable marker reads as absent. The restart then
            // dials, as it does for a lost marker.
            XLog.d("OneVpnServiceDelegate: user-stop peek failed")
            XLog.d(e)
            false
        }

    /** Deletes the user-stop marker. Logs failed IO and never throws. */
    private fun consumeUserStop(context: Context) {
        try {
            markerFile(context).delete()
        } catch (e: Exception) {
            XLog.d("OneVpnServiceDelegate: user-stop consume failed")
            XLog.d(e)
        }
    }
}
