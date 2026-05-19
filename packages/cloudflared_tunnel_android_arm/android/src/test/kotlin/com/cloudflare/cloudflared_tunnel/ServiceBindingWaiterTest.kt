package com.cloudflare.cloudflared_tunnel

import kotlin.test.Test
import kotlin.test.assertEquals

internal class ServiceBindingWaiterTest {
    @Test
    fun waitsForServiceBindingInsteadOfFailingImmediately() {
        val scheduler = FakeRetryScheduler()
        var ready = false
        var readyCalls = 0
        var timeoutCalls = 0

        val waiter = ServiceBindingWaiter(
            isReady = { ready },
            scheduler = scheduler,
            retryDelayMillis = 100,
            timeoutMillis = 5_000,
            nowMillis = { scheduler.nowMillis },
        )

        waiter.wait(
            onReady = { readyCalls++ },
            onTimeout = { timeoutCalls++ },
        )

        assertEquals(0, readyCalls)
        assertEquals(0, timeoutCalls)
        assertEquals(1, scheduler.pendingCount)

        ready = true
        scheduler.runNext()

        assertEquals(1, readyCalls)
        assertEquals(0, timeoutCalls)
        assertEquals(listOf(100L), scheduler.delays)
    }

    @Test
    fun timesOutOnlyAfterConfiguredWaitWindow() {
        val scheduler = FakeRetryScheduler()
        var readyCalls = 0
        var timeoutCalls = 0

        val waiter = ServiceBindingWaiter(
            isReady = { false },
            scheduler = scheduler,
            retryDelayMillis = 100,
            timeoutMillis = 500,
            nowMillis = { scheduler.nowMillis },
        )

        waiter.wait(
            onReady = { readyCalls++ },
            onTimeout = { timeoutCalls++ },
        )

        assertEquals(0, readyCalls)
        assertEquals(0, timeoutCalls)

        while (scheduler.pendingCount > 0) {
            scheduler.runNext()
        }

        assertEquals(0, readyCalls)
        assertEquals(1, timeoutCalls)
        assertEquals(500, scheduler.nowMillis)
        assertEquals(List(5) { 100L }, scheduler.delays)
    }

    private class FakeRetryScheduler : RetryScheduler {
        private val pending = ArrayDeque<() -> Unit>()
        val delays = mutableListOf<Long>()
        var nowMillis = 0L
            private set

        val pendingCount: Int
            get() = pending.size

        override fun postDelayed(delayMillis: Long, action: () -> Unit) {
            delays += delayMillis
            pending += {
                nowMillis += delayMillis
                action()
            }
        }

        fun runNext() {
            pending.removeFirst().invoke()
        }
    }
}
