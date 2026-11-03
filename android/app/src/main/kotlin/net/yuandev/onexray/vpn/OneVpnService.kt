package net.yuandev.onexray.vpn

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.graphics.drawable.Icon
import android.net.VpnService
import android.os.Build
import android.os.Binder
import android.os.IBinder
import android.os.Parcel
import android.os.ParcelFileDescriptor
import androidx.core.content.ContextCompat
import com.elvishew.xlog.XLog
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.decodeFromJsonElement
import kotlinx.serialization.json.encodeToJsonElement
import kotlinx.serialization.json.jsonObject
import libXray.DialerController
import libXray.LibXray
import net.yuandev.onexray.MainActivity
import net.yuandev.onexray.R
import net.yuandev.onexray.onevpn.OneVpnServiceDelegate
import net.yuandev.onexray.pigeon.JsonTool
import net.yuandev.onexray.pigeon.LibXrayInvokeRequest
import net.yuandev.onexray.pigeon.LibXrayInvokeResponse
import net.yuandev.onexray.pigeon.LibXrayMethod
import net.yuandev.onexray.pigeon.PerAppVPNMode
import net.yuandev.onexray.pigeon.StartVpnRequest
import net.yuandev.onexray.pigeon.TunJson
import net.yuandev.onexray.pigeon.XrayEnv
import net.yuandev.onexray.pigeon.VpnStatus
import java.io.File
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger


class OneVpnService : VpnService() {
    companion object {
        const val ACTION_START: String = "vpn_start"
        const val ACTION_STOP: String = "vpn_stop"
        const val ACTION_STOP_REQUEST: String = "net.yuandev.onexray.VPN_STOP_REQUEST"

        const val IPV4_ADDRESS = "198.18.0.1"
        const val IPV6_ADDRESS = "fc00::1"
        const val ACTION_VPN_STATUS: String = "net.yuandev.onexray.VPN_STATUS"
        const val EXTRA_RUNNING: String = "running"
        const val EXTRA_ERROR: String = "error"
        const val NOTIFICATION_OPEN_REQUEST_CODE = 1
        const val NOTIFICATION_STOP_REQUEST_CODE = 2

        /**
         * The process's one dialer and listener controller.
         *
         * libXray appends every controller registration to a global list that nothing
         * removes. The process registers this controller once. Each service instance rebinds
         * [VPNController.vpn] to itself. A stale controller fails every protect, and Xray-core
         * cancels each dial whose controller fails.
         */
        private val controller = VPNController()

        private var controllerInit = false

        /** Registers [controller] as the dialer and listener controller once per process. */
        @Synchronized
        private fun initController() {
            if (controllerInit) {
                return
            }
            LibXray.registerDialerController(controller)
            LibXray.registerListenerController(controller)
            controllerInit = true
        }
    }

    @Volatile
    private var tunnel: ParcelFileDescriptor? = null

    private val tunMtu = 1500
    @Volatile
    private var running = false
    private val startGeneration = AtomicInteger(0)
    private val released = AtomicBoolean(true)
    // True while a failed start holds the TUN with no core. Its packets drop.
    @Volatile
    private var failedClosed = false

    private fun sendStatusBroadcast(running: Boolean, error: String? = null) {
        val intent = Intent(ACTION_VPN_STATUS).apply {
            setPackage(packageName) // 限定仅本包接收
            putExtra(EXTRA_RUNNING, running)
            putExtra(EXTRA_ERROR, error)
        }
        sendBroadcast(intent)
        VpnController.requestTileRefresh(this)
    }

    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private val stopRequestReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == ACTION_STOP_REQUEST) {
                XLog.d("OneVpnService: received stop request")
                stopTun()
            }
        }
    }
    private var stopRequestReceiverRegistered = false

    private val statusBinder = object : Binder() {
        override fun onTransact(code: Int, data: Parcel, reply: Parcel?, flags: Int): Boolean {
            if (code != VpnStatusConnection.READ_STATUS) return super.onTransact(code, data, reply, flags)
            data.enforceInterface(VpnStatusConnection.DESCRIPTOR)
            val status = when {
                failedClosed && !running -> VpnStatus.DISCONNECTED
                running && !released.get() -> VpnStatus.CONNECTED
                released.get() && tunnel != null -> VpnStatus.DISCONNECTING
                !released.get() -> VpnStatus.CONNECTING
                else -> VpnStatus.DISCONNECTED
            }
            reply?.writeNoException()
            reply?.writeInt(status.ordinal)
            return true
        }
    }

    override fun onBind(intent: Intent?): IBinder? =
        if (intent?.action == VpnStatusConnection.ACTION_BIND) statusBinder else super.onBind(intent)

    override fun onRevoke() {
        stopTun()
    }

    /** Protects core sockets through [vpn], the service instance that runs the tunnel. */
    class VPNController : DialerController {
        @Volatile
        var vpn: OneVpnService? = null
        override fun protectFd(p0: Long): Boolean {
            val socket = p0.toInt()
            return vpn?.protect(socket) == true
        }
    }

    override fun onCreate() {
        super.onCreate()
        initService()
        val filter = IntentFilter(ACTION_STOP_REQUEST)
        ContextCompat.registerReceiver(
            this,
            stopRequestReceiver,
            filter,
            ContextCompat.RECEIVER_NOT_EXPORTED,
        )
        stopRequestReceiverRegistered = true
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        XLog.d("OneVpnService: onStartCommand ${intent?.action}")
        if (intent != null && intent.action == ACTION_STOP) {
            XLog.d("OneVpnService: onStartCommand $ACTION_STOP running=$running")
            stopTun()
            return START_NOT_STICKY
        }
        if (intent != null && intent.action == ACTION_START) {
            if (OneVpnServiceDelegate.dropsStart(intent, failedClosed && tunnel != null)) return START_NOT_STICKY
            XLog.d("OneVpnService: onStartCommand $ACTION_START running=$running")
            if (VpnController.consumeStopRequest(this)) {
                XLog.d("OneVpnService: start cancelled by pending stop request")
                stopTun()
                return START_NOT_STICKY
            }
            if (!running && (tunnel == null || failedClosed)) {
                startTun(startId)
            }
            return OneVpnServiceDelegate.runningResult(this)
        }
        return OneVpnServiceDelegate.onUnrecognizedStart(this, intent, startId, { VpnController.consumeStopRequest(this) }) { if (!running && tunnel == null) startTun(startId) }
    }

    override fun onDestroy() {
        if (stopRequestReceiverRegistered) {
            try {
                unregisterReceiver(stopRequestReceiver)
            } catch (_: IllegalArgumentException) {
            }
            stopRequestReceiverRegistered = false
        }
        releaseTun()
        OneVpnServiceDelegate.onTunnelDown()
        scope.cancel()
        super.onDestroy()
    }

    private fun initService() {
        XLog.init()
    }

    private fun startTun(startId: Int) {
        XLog.d("OneVpnService: startTun $startId")
        // A held TUN stays up until runTun establishes its replacement.
        val held = if (failedClosed) tunnel else null
        if (!released.compareAndSet(true, false) && held == null) {
            XLog.d("OneVpnService: startTun ignored because VPN resources are active")
            return
        }
        failedClosed = false
        val generation = startGeneration.incrementAndGet()
        try {
            showNotification(startId)
            val model = readStartRequest()
            runTun(model, generation, held)
        } catch (e: Exception) {
            failStart("OneVpnService: startTun failed", e, generation)
        }
    }

    private fun readStartRequest(): StartVpnRequest {
        val runPath = File(this.filesDir.path, "run")
        val file = File(runPath.path, "start.json")
        val data = file.readText()
        return try {
            JsonTool.json.decodeFromString<StartVpnRequest>(data)
        } catch (_: IllegalArgumentException) {
            // Decoder errors may contain the input, including node credentials.
            throw IllegalStateException("invalid VPN start request")
        }
    }

    private fun stopTun() {
        OneVpnServiceDelegate.markUserStop(this)
        if (!releaseTun()) {
            stopForeground(STOP_FOREGROUND_REMOVE)
            sendStatusBroadcast(false)
        }
        stopSelf()
    }

    private fun releaseTun(error: String? = null): Boolean {
        if (!released.compareAndSet(false, true)) {
            return false
        }
        OneVpnServiceDelegate.onTunnelDown()
        startGeneration.incrementAndGet()
        XLog.d("OneVpnService: releaseTun")
        stopForeground(STOP_FOREGROUND_REMOVE)
        try {
            stopXray()
        } catch (e: Exception) {
            XLog.d("OneVpnService: releaseTun stopXray exception")
            XLog.d(e)
        }
        try {
            LibXray.resetDNS()
        } catch (e: Exception) {
            XLog.d("OneVpnService: releaseTun resetDNS exception")
            XLog.d(e)
        }
        try {
            tunnel?.close()
        } catch (e: Exception) {
            XLog.d("OneVpnService: releaseTun close tunnel exception")
            XLog.d(e)
        }
        tunnel = null
        // A newer instance may own the controller. Only this instance's binding clears.
        if (controller.vpn === this) controller.vpn = null
        running = false
        failedClosed = false
        sendStatusBroadcast(false, error)
        return true
    }

    private fun failStart(message: String, error: Exception, generation: Int? = null) {
        if (generation != null && generation != startGeneration.get()) {
            XLog.d("$message ignored for stale start generation=$generation")
            XLog.d(error)
            return
        }
        XLog.e(message, error)
        val reason = error.message ?: error.toString()
        // Fails closed: an established TUN stays up with no core until a
        // stop or the next start releases it.
        if (tunnel != null && !released.get()) {
            try {
                stopXray()
            } catch (e: Exception) {
                XLog.d("OneVpnService: failStart stopXray exception")
                XLog.d(e)
            }
            // A stop during stopXray owns the teardown and its broadcast.
            if ((generation != null && generation != startGeneration.get()) || released.get()) return
            running = false
            failedClosed = true
            sendStatusBroadcast(false, reason)
            return
        }
        if (!releaseTun(reason)) sendStatusBroadcast(false, reason)
        stopSelf()
    }

    private fun showNotification(startId: Int) {
        val notification = makeNotification()
        var notificationId = startId
        if (notificationId <= 0) {
            notificationId = 1
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                notificationId,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
            )
        } else {
            startForeground(notificationId, notification)
        }
    }

    private fun makeNotification(): Notification {
        val appName = getString(R.string.quick_settings_tile_label)
        val channelId = "com.one.vpnapp.tunnel"
        val channel = NotificationChannel(
            channelId,
            appName,
            NotificationManager.IMPORTANCE_LOW
        )
        channel.description = appName
        val notificationManager = getSystemService(
            NotificationManager::class.java
        )
        notificationManager.createNotificationChannel(channel)

        val openPendingIntent = PendingIntent.getActivity(
            this,
            NOTIFICATION_OPEN_REQUEST_CODE,
            Intent(this, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            },
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        val stopPendingIntent = PendingIntent.getService(
            this,
            NOTIFICATION_STOP_REQUEST_CODE,
            Intent(this, OneVpnService::class.java).apply {
                action = ACTION_STOP
            },
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        return Notification.Builder(this, channelId)
            .setContentTitle(appName)
            .setContentText(getString(R.string.notification_vpn_connected))
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(openPendingIntent)
            .setTicker(appName)
            .setOngoing(true)
            .addAction(
                Notification.Action.Builder(
                    Icon.createWithResource(this, R.mipmap.ic_launcher),
                    getString(R.string.notification_action_open),
                    openPendingIntent
                ).build()
            )
            .addAction(
                Notification.Action.Builder(
                    Icon.createWithResource(this, R.drawable.pause_light),
                    getString(R.string.notification_action_disconnect),
                    stopPendingIntent
                ).build()
            )
            .build()
    }

    private fun runTun(
        request: StartVpnRequest,
        generation: Int,
        held: ParcelFileDescriptor? = null,
    ) {
        if (generation != startGeneration.get() || tunnel !== held) {
            return
        }
        XLog.d("OneVpnService: runTun tunnel = null")
        val builder = Builder()
        val tun = requireNotNull(request.tun) { "missing TUN config" }
        setPerAppVpn(tun, builder)
        setIPAndDns(tun, builder)
        OneVpnServiceDelegate.applyBuilderPolicy(builder, tun, packageName)

        val establishedTunnel = builder.establish()
            ?: throw IllegalStateException("failed to establish VPN tunnel")
        if (generation != startGeneration.get()) {
            establishedTunnel.close()
            return
        }
        tunnel = establishedTunnel
        // The held TUN closes only after its replacement is up. No clearnet gap opens.
        try {
            held?.close()
        } catch (e: Exception) {
            XLog.d("OneVpnService: runTun close held tunnel exception")
            XLog.d(e)
        }

        XLog.d("OneVpnService: runTun tunnel = ${tunnel?.fd}")

        val coreInvokeText = requireNotNull(request.coreInvokeText) {
            "missing Xray run request"
        }
        controller.vpn = this
        configureDNS(tun)
        runXray(coreInvokeText, establishedTunnel, generation)
    }

    private fun configureDNS(tun: TunJson) {
        val dns = tun.tunDnsIPv4?.trim()
        require(!dns.isNullOrEmpty()) { "missing IPv4 TUN DNS" }
        LibXray.setDNS(controller, "$dns:53")
    }

    private fun setIPAndDns(tun: TunJson, builder: Builder) {
        builder.addAddress(IPV4_ADDRESS, 15)
            .addRoute("0.0.0.0", 0)
            .setMtu(tunMtu)
        tun.tunDnsIPv4?.let {
            builder.addDnsServer(it)
        }

        tun.enableIPv6?.let {
            if (it) {
                builder.addAddress(IPV6_ADDRESS, 64)
                    .addRoute("::", 0)
                tun.tunDnsIPv6?.let { dnsIPv6 ->
                    builder.addDnsServer(dnsIPv6)
                }
            }
        }
    }

    private fun setPerAppVpn(tun: TunJson, builder: Builder) {
        tun.perAppVPNMode?.let {
            when (it) {
                PerAppVPNMode.ALLOW -> addAllowedApplication(tun.allowAppList, builder)
                PerAppVPNMode.DISALLOW -> addDisallowedApplication(tun.disallowAppList, builder)
            }
        }
    }

    private fun addAllowedApplication(appList: List<String>?, builder: Builder) {
        var allowed = 0
        for (appPackage in appList.orEmpty().distinct()) {
            try {
                packageManager.getPackageInfo(appPackage, 0)
                builder.addAllowedApplication(appPackage)
                allowed++
            } catch (_: PackageManager.NameNotFoundException) {
            }
        }
        // No addAllowedApplication calls would otherwise mean every installed app.
        require(allowed > 0) { "Select at least one installed app before connecting" }
    }

    private fun addDisallowedApplication(appList: List<String>?, builder: Builder) {
        appList?.let {
            if (it.isNotEmpty()) {
                for (appPackage in it) {
                    try {
                        packageManager.getPackageInfo(appPackage, 0)
                        builder.addDisallowedApplication(appPackage)
                    } catch (_: PackageManager.NameNotFoundException) {
                    }
                }
            }
        }
    }

    private fun runXray(
        coreInvokeText: String,
        establishedTunnel: ParcelFileDescriptor,
        generation: Int,
    ) {
        scope.launch {
            try {
                initController()
                if (generation != startGeneration.get() || tunnel !== establishedTunnel) {
                    return@launch
                }
                val result = LibXray.invoke(patchRuntimeEnv(coreInvokeText, establishedTunnel.fd, OneVpnServiceDelegate.directDnsPatch(this@OneVpnService)))
                validateRunXrayResult(result)
                if (generation != startGeneration.get() || tunnel !== establishedTunnel) {
                    XLog.d("OneVpnService: stale runXray result ignored")
                    if (tunnel == null) {
                        stopXray()
                    }
                    return@launch
                }
                XLog.d("OneVpnService: Xray started")
                running = true
                sendStatusBroadcast(true)
                if (generation == startGeneration.get() && !released.get()) OneVpnServiceDelegate.onTunnelUp(this@OneVpnService, ::reloadXray)
            } catch (e: Exception) {
                failStart("OneVpnService: runXray failed", e, generation)
            }
        }
    }

    enum class ReloadOutcome { APPLIED, ROLLED_BACK, FAILED, NOT_RUNNING, SUPERSEDED, INVALID }

    /**
     * Restarts the core on the running TUN and blocks the caller. The TUN, its routes and the
     * VPN network stay up. Packets sent during the swap drop inside the tunnel. The swap
     * requires the core to leave the TUN fd open when it stops. A request that cannot be
     * patched answers INVALID before the core stops. A failed [next] restores [fallback]. A
     * failed [fallback] takes the failed-start path.
     */
    private fun reloadXray(next: String, fallback: String): ReloadOutcome {
        val generation = startGeneration.get()
        val live = tunnel
        if (live == null || !running) return ReloadOutcome.NOT_RUNNING
        fun stale(): Boolean {
            if (generation == startGeneration.get() && tunnel === live) return false
            XLog.d("OneVpnService: stale reloadXray result ignored")
            if (tunnel == null || released.get()) stopXray()
            return true
        }
        val requests = try {
            val fd = live.fd
            val directDns = OneVpnServiceDelegate.directDnsPatch(this)
            listOf(patchRuntimeEnv(next, fd, directDns), patchRuntimeEnv(fallback, fd, directDns))
        } catch (e: Exception) {
            XLog.e("OneVpnService: reloadXray request invalid", e)
            return if (stale()) ReloadOutcome.SUPERSEDED else ReloadOutcome.INVALID
        }
        fun start(request: String): Exception? = try {
            stopXray()
            validateRunXrayResult(LibXray.invoke(request))
            null
        } catch (e: Exception) {
            e
        }
        val nextError = start(requests[0])
        if (stale()) return ReloadOutcome.SUPERSEDED
        if (nextError == null) return ReloadOutcome.APPLIED
        XLog.e("OneVpnService: reloadXray failed, restoring the previous core", nextError)
        val fallbackError = start(requests[1])
        if (stale()) return ReloadOutcome.SUPERSEDED
        if (fallbackError == null) return ReloadOutcome.ROLLED_BACK
        failStart("OneVpnService: reloadXray rollback failed", fallbackError, generation)
        return ReloadOutcome.FAILED
    }

    private fun validateRunXrayResult(result: String) {
        val response = JsonTool.json.decodeFromString<LibXrayInvokeResponse>(result)
        if (!response.success) {
            throw IllegalStateException(response.error)
        }
    }

    private fun stopXray() {
        val request = LibXrayInvokeRequest(method = LibXrayMethod.STOP_XRAY)
        LibXray.invoke(JsonTool.json.encodeToString(request))
    }

    private fun patchRuntimeEnv(requestJson: String, fd: Int, directDns: (JsonObject) -> JsonObject): String {
        try {
            val request = JsonTool.json.decodeFromString<LibXrayInvokeRequest>(requestJson)
            val payload = request.payload
                ?: throw IllegalStateException("runXray payload is empty")
            val xrayJson = payload.xrayJson
                ?: throw IllegalStateException("xrayJson is empty")
            if (xrayJson.isEmpty()) {
                throw IllegalStateException("xrayJson is empty")
            }
            val root = directDns(JsonTool.json.parseToJsonElement(xrayJson).jsonObject)
            val currentEnv = root["env"]?.let {
                JsonTool.json.decodeFromJsonElement<XrayEnv>(it)
            } ?: XrayEnv()
            val env = currentEnv.copy(tunFd = fd.toString())
            val updated = buildJsonObject {
                root.forEach { (key, value) ->
                    if (key != "env") {
                        put(key, value)
                    }
                }
                put("env", JsonTool.json.encodeToJsonElement(env))
            }
            val updatedPayload = payload.copy(
                xrayJson = JsonTool.json.encodeToString(updated),
            )
            return JsonTool.json.encodeToString(request.copy(payload = updatedPayload))
        } catch (_: IllegalArgumentException) {
            throw IllegalStateException("invalid Xray run request")
        }
    }
}
