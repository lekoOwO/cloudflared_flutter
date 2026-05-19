package com.cloudflare.cloudflared_tunnel

import mobile.Mobile
import mobile.TunnelCallback as GoTunnelCallback
import java.lang.reflect.InvocationTargetException

internal object MobileTunnelBinding {
    fun startTunnelWithOptions(
        token: String,
        originUrl: String,
        quickTunnelUrl: String,
        haConnections: Long,
        enablePostQuantum: Boolean,
        callback: GoTunnelCallback,
    ) {
        try {
            val method = Mobile::class.java.getMethod(
                "startTunnelWithOptions",
                String::class.java,
                String::class.java,
                String::class.java,
                java.lang.Long.TYPE,
                java.lang.Boolean.TYPE,
                GoTunnelCallback::class.java,
            )
            method.invoke(
                null,
                token,
                originUrl,
                quickTunnelUrl,
                haConnections,
                enablePostQuantum,
                callback,
            )
        } catch (e: NoSuchMethodException) {
            throw IllegalStateException(
                "Native cloudflared binding does not expose startTunnelWithOptions; rebuild the mobile AAR",
                e,
            )
        } catch (e: InvocationTargetException) {
            throw (e.targetException ?: e)
        }
    }
}
