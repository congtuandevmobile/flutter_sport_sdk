package sensor.protocol

/**
 * The rate of a (count, event time) pair that a cycling sensor sends: revolutions of a crank or a wheel. The count wraps at 16
 * or 32 bits and the event time at 16 bits (1/[ticksPerSecond] s), so a value is computed between two consecutive EVENTS.
 *
 * Answers: a rate in events per second, [ZERO] when the rotation is verified stopped, or [UNKNOWN].
 *  - Stopped needs valid notifications that keep arriving with an unchanged counter for longer than an event can take
 *    ([zeroAfterMs], or twice the last event interval when that is longer). The lack of notifications is NOT zero: the answer
 *    is [UNKNOWN] once [staleMs] passes (see [rate]).
 *  - The 16-bit event clock wraps every 65536/[ticksPerSecond] s: when the previous event is [eventClockSpanMs] or more in the
 *    past the two samples are not comparable, so a new baseline is taken and no value is given.
 *  - A counter jump the elapsed time cannot explain at [maxRate] (a sensor reset) takes a new baseline too, and so does a clock
 *    that goes back or a silence of [silenceResetMs].
 *  - A rate below [minRate] (the first event after a long coast averages over the coast) or above [maxRate] is not a value.
 * Call [reset] for every new connection. All `nowMs` come from one monotonic clock. Not thread-safe.
 */
class CounterRate(
    private val ticksPerSecond: Double,
    private val countMask: Long,
    private val minRate: Double,
    private val maxRate: Double,
    private val staleMs: Long = 5_000,
    private val zeroAfterMs: Long = 3_000,
    private val silenceResetMs: Long = 15_000,
) {
    init {
        require(ticksPerSecond > 0.0 && minRate > 0.0 && maxRate > minRate) { "ranges" }
        require(staleMs > 0 && zeroAfterMs > 0 && silenceResetMs > 0) { "durations" }
    }

    /** The 16-bit event clock wraps after 65536 ticks; 94% of that is the longest gap that can still be told apart. */
    private val eventClockSpanMs: Long = (65_536_000.0 / ticksPerSecond * 15.0 / 16.0).toLong()

    private var lastCount = -1L
    private var lastTicks = -1
    private var lastRxMs = -1L
    private var lastEventRxMs = -1L
    private var lastIntervalMs = 0L
    private var value = UNKNOWN

    fun reset() {
        lastCount = -1L
        lastTicks = -1
        lastRxMs = -1L
        lastEventRxMs = -1L
        lastIntervalMs = 0L
        value = UNKNOWN
    }

    fun onSample(count: Long, eventTicks: Int, nowMs: Long): Double {
        if (count < 0L || count > countMask || eventTicks !in 0..MAX_U16 || nowMs < 0L) return UNKNOWN
        if (lastRxMs >= 0L && nowMs < lastRxMs) {
            reset()
            return UNKNOWN
        }
        if (lastRxMs >= 0L && nowMs - lastRxMs >= silenceResetMs) reset()
        val previousCount = lastCount
        val previousTicks = lastTicks
        lastRxMs = nowMs
        lastCount = count
        lastTicks = eventTicks
        if (previousCount < 0L) {
            lastEventRxMs = nowMs
            value = UNKNOWN
            return UNKNOWN
        }

        val deltaEvents = (count - previousCount) and countMask
        val sinceEventMs = nowMs - lastEventRxMs
        if (deltaEvents == 0L) {
            val stoppedAfter = maxOf(zeroAfterMs, 2 * lastIntervalMs)
            if (sinceEventMs >= stoppedAfter) value = ZERO
            return value
        }

        lastEventRxMs = nowMs
        val deltaTicks = ((eventTicks - previousTicks) and MAX_U16).toLong()
        if (sinceEventMs >= eventClockSpanMs || deltaEvents > maxEventsIn(sinceEventMs)) {
            value = UNKNOWN
            lastIntervalMs = 0L
            return UNKNOWN
        }
        if (deltaTicks == 0L) {
            value = UNKNOWN
            return UNKNOWN
        }
        val rate = deltaEvents * ticksPerSecond / deltaTicks
        if (!rate.isFinite() || rate < minRate || rate > maxRate) {
            value = UNKNOWN
            lastIntervalMs = 0L
            return UNKNOWN
        }
        lastIntervalMs = (deltaTicks * 1000.0 / ticksPerSecond / deltaEvents).toLong()
        value = rate
        return rate
    }

    /** The last answer while notifications keep arriving, [UNKNOWN] once none came for [staleMs] (never [ZERO]). */
    fun rate(nowMs: Long): Double {
        if (lastRxMs < 0L || nowMs < lastRxMs || nowMs - lastRxMs > staleMs) return UNKNOWN
        return value
    }

    private fun maxEventsIn(elapsedMs: Long): Long = (maxRate * (elapsedMs + SLACK_MS) / 1000.0).toLong() + 1L

    companion object {
        const val UNKNOWN = -1.0
        const val ZERO = 0.0
        private const val MAX_U16 = 0xFFFF
        private const val SLACK_MS = 1_500L

        /** A crank: 16-bit count, 1/1024 s ticks, 15 to 220 rpm. */
        fun crank(): CounterRate = CounterRate(1024.0, 0xFFFFL, 15.0 / 60.0, 220.0 / 60.0)

        /** A wheel of a CSC sensor: 32-bit count, 1/1024 s ticks. */
        fun cscWheel(): CounterRate = CounterRate(1024.0, 0xFFFFFFFFL, 0.1, 30.0)

        /** A wheel of a power meter: 32-bit count, 1/2048 s ticks. */
        fun powerWheel(): CounterRate = CounterRate(2048.0, 0xFFFFFFFFL, 0.1, 30.0)
    }
}
