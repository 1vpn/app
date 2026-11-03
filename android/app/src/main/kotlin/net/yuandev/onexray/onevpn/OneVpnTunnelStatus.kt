package net.yuandev.onexray.onevpn

import android.content.Context
import com.elvishew.xlog.XLog
import net.yuandev.onexray.pigeon.VpnStatus
import net.yuandev.onexray.vpn.VpnController
import net.yuandev.onexray.vpn.VpnStatusConnection

/**
 * Reads the VPN service status while the tunnel interface is up. A held
 * TUN reads disconnected with the interface up. A running core reads
 * connected.
 */
object OneVpnTunnelStatus {
    /**
     * Whether a failed start holds the TUN: the interface is up while the
     * service reads disconnected. False when the interface is down. Null
     * when the status is unreadable.
     */
    suspend fun held(context: Context): Boolean? {
        if (!VpnController.readVpnRunning(context)) return false
        return read(context)?.let { it == VpnStatus.DISCONNECTED }
    }

    /** The service status, or null when the interface is down or the status is unreadable. */
    suspend fun read(context: Context): VpnStatus? {
        if (!VpnController.readVpnRunning(context)) return null
        val status = VpnStatusConnection(context) {}
        return try {
            status.read()
        } catch (error: Exception) {
            XLog.w("OneVpnTunnelStatus: VPN status unreadable: $error")
            null
        } finally {
            status.close()
        }
    }
}
