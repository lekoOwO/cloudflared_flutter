package com.cloudflare.cloudflared_tunnel

internal fun interface RetryScheduler {
    fun postDelayed(delayMillis: Long, action: () -> Unit)
}

internal class HandlerRetryScheduler(
    private val handler: android.os.Handler,
) : RetryScheduler {
    override fun postDelayed(delayMillis: Long, action: () -> Unit) {
        handler.postDelayed(action, delayMillis)
    }
}

internal class ServiceBindingWaiter(
    private val isReady: () -> Boolean,
    private val scheduler: RetryScheduler,
    private val retryDelayMillis: Long = 100,
    private val timeoutMillis: Long = 5_000,
    private val nowMillis: () -> Long = { System.currentTimeMillis() },
) {
    fun wait(onReady: () -> Unit, onTimeout: () -> Unit) {
        val startedAt = nowMillis()

        fun attempt() {
            if (isReady()) {
                onReady()
                return
            }

            val elapsed = nowMillis() - startedAt
            if (elapsed >= timeoutMillis) {
                onTimeout()
                return
            }

            val remaining = timeoutMillis - elapsed
            scheduler.postDelayed(minOf(retryDelayMillis, remaining)) {
                attempt()
            }
        }

        attempt()
    }
}
