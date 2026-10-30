package challenge.session

import challenge.model.ProgressMetric
import challenge.model.ProgressSample

/**
 * Turns the cumulative counter of ONE source (GPS total, a machine's distance, a rep counter) into STAGE-LOCAL positive deltas for ONE
 * stage activation. The first sample after [activate] (or after a new connection epoch) is only a baseline; a counter that goes back,
 * a gap longer than [maxGapMs], or a jump faster than the metric's maximum rate is not credited. It never touches the recording the
 * counter comes from. The event id is `source/epoch/time`: the same measurement gets the same id after a restart.
 */
class StageCounterAdapter(
    private val sessionId: String,
    private val sourceId: String,
    private val metric: ProgressMetric,
    private val maxRatePerSecond: Double = metric.maxRatePerSecond,
    private val maxGapMs: Long = 5_000,
) {
    init {
        require(maxRatePerSecond > 0.0 && maxGapMs > 0L) { "limits" }
    }

    private var activation = -1L
    private var epoch = -1L
    private var lastCounter = 0.0
    private var lastAtMs = -1L

    fun activate(stageActivation: Long) {
        activation = stageActivation
        epoch = -1L
        lastAtMs = -1L
    }

    fun onCounter(connectionEpoch: Long, counter: Double, atMs: Long): ProgressSample? {
        if (activation < 0L || !counter.isFinite() || counter < 0.0 || atMs < 0L) return null
        if (epoch >= 0L && connectionEpoch < epoch) return null
        if (epoch != connectionEpoch) {
            epoch = connectionEpoch
            lastCounter = counter
            lastAtMs = atMs
            return null
        }
        if (atMs <= lastAtMs) return null // a duplicate or an out-of-order sample
        val dt = atMs - lastAtMs
        val delta = counter - lastCounter
        lastCounter = counter
        lastAtMs = atMs
        if (dt > maxGapMs || delta <= 0.0 || delta > maxRatePerSecond * dt / 1000.0) return null
        return ProgressSample("$sourceId/$epoch/$atMs", sessionId, activation, sourceId, metric, delta, atMs)
    }
}
