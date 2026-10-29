package workout.distance

import workout.model.DistanceSource
import workout.model.DistanceSourceKind
import workout.model.WorkoutEvent
import workout.model.WorkoutMode

/** Starting values, not measured. */
class DistanceLedgerConfig(
    /** A source with no sample for this long is stale and loses the distance to another one. */
    val staleAfterMs: Long = 10_000,
    /** The fastest speed a source may report (running 12 m/s, cycling 30 m/s): more is a spike, not a movement. */
    val maxSpeedMps: Double = 12.0,
    /** A counter may move this much more than the maximum speed allows (jitter). */
    val spikeSlackMeters: Double = 5.0,
    /** A speed is integrated only over a gap this short: a longer one is lost data, never credited. */
    val maxIntegrationGapMs: Long = 5_000,
) {
    init {
        require(staleAfterMs > 0 && maxIntegrationGapMs > 0) { "durations" }
        require(maxSpeedMps > 0.0 && spikeSlackMeters >= 0.0) { "limits" }
    }

    companion object {
        fun forMode(mode: WorkoutMode): DistanceLedgerConfig = when (mode) {
            WorkoutMode.OUTDOOR_RUNNING, WorkoutMode.INDOOR_RUNNING -> DistanceLedgerConfig()
            WorkoutMode.OUTDOOR_CYCLING, WorkoutMode.INDOOR_CYCLING -> DistanceLedgerConfig(maxSpeedMps = 30.0)
        }
    }
}

/**
 * The one place the distance of a workout is added up. A source gives either a cumulative COUNTER (a GPS total, a footpod, a
 * treadmill) or a SPEED to integrate; the ledger adds only DIFFERENCES, from a baseline, and only from ONE source at a time.
 *
 *  - The first sample of a source, of a new epoch, after a pause, after the workout started, or right after the source was
 *    chosen is a BASELINE: it credits nothing. A counter that goes back, or jumps more than the speed limit and the elapsed time
 *    allow, takes a new baseline too (a reset sensor never makes a spike or a negative distance).
 *  - Only the chosen source credits. Choice: the user's preference while it is fresh, else the chosen source while it stays
 *    fresh (it never alternates), else the best kind for the mode (outdoors GPS, then counter, then speed; indoors counter, then
 *    speed, then GPS), among equals the first seen. A source that returns after being stale does not take the distance back.
 *  - Switching keeps the distance counted so far: the new source starts from a new baseline (its total is never assigned).
 *  - A speed is integrated (trapezoid) only over gaps up to [DistanceLedgerConfig.maxIntegrationGapMs], never across a pause.
 *  - A sample older than the previous one of its source is ignored; a source's epoch must not go back.
 * Every change is returned as events with a sequence number from [nextSeq]; replaying the DistanceAdvanced deltas gives the
 * distance again. One monotonic clock; not thread-safe.
 */
class DistanceLedger(
    private val mode: WorkoutMode,
    private val config: DistanceLedgerConfig,
    private val nextSeq: () -> Long,
) {
    private class Track(val source: DistanceSource, var epoch: Long) {
        var seenAtMs = -1L
        var lastAtMs = -1L
        var lastValue = 0.0
        var baselined = false
        var lastSpeed = -1.0
        var reason = "first sample"
    }

    private val tracks = LinkedHashMap<DistanceSource, Track>()
    private var preferred: DistanceSource? = null
    private var active = false

    var distanceMeters = 0.0
        private set
    var selected: DistanceSource? = null
        private set

    /** The workout is counting (started or resumed): every source starts from a new baseline. */
    fun activate(reason: String) {
        active = true
        forgetBaselines(reason)
    }

    /** The workout is not counting (paused or finished): nothing is credited and every baseline is forgotten. */
    fun deactivate() {
        active = false
        forgetBaselines("resumed")
    }

    /** The user's choice of source (null clears it). It only applies while that source is fresh. */
    fun setPreferred(source: DistanceSource?, nowMs: Long): List<WorkoutEvent> {
        preferred = source
        val out = ArrayList<WorkoutEvent>(1)
        evaluate(nowMs, out)
        return out
    }

    /** Looks at the freshness of the sources without a new sample (a source went quiet). */
    fun tick(nowMs: Long): List<WorkoutEvent> {
        val out = ArrayList<WorkoutEvent>(1)
        evaluate(nowMs, out)
        return out
    }

    fun onCounter(source: DistanceSource, epoch: Long, meters: Double, atMs: Long): List<WorkoutEvent> {
        if (source.kind == DistanceSourceKind.SPEED || !meters.isFinite() || meters < 0.0 || atMs < 0L) return emptyList()
        val track = track(source, epoch, atMs) ?: return emptyList()
        val out = ArrayList<WorkoutEvent>(2)
        evaluate(atMs, out)
        if (!active) { // seen, but nothing counts: the next sample while counting is a baseline
            track.baselined = false
            track.lastAtMs = atMs
            return out
        }
        if (!track.baselined) {
            baseline(track, meters, atMs, out)
            return out
        }
        val elapsedMs = atMs - track.lastAtMs
        val delta = meters - track.lastValue
        track.lastAtMs = atMs
        if (delta < 0.0) {
            track.reason = "the counter went back"
            baseline(track, meters, atMs, out)
        } else if (delta > config.maxSpeedMps * elapsedMs / 1000.0 + config.spikeSlackMeters) {
            track.reason = "a jump the elapsed time cannot explain"
            baseline(track, meters, atMs, out)
        } else {
            track.lastValue = meters
            if (selected == source && delta > 0.0) credit(source, delta, atMs, out)
        }
        return out
    }

    fun onSpeed(source: DistanceSource, epoch: Long, mps: Double, atMs: Long): List<WorkoutEvent> {
        if (source.kind != DistanceSourceKind.SPEED || !mps.isFinite() || mps < 0.0 || atMs < 0L) return emptyList()
        val track = track(source, epoch, atMs) ?: return emptyList()
        val out = ArrayList<WorkoutEvent>(2)
        evaluate(atMs, out)
        if (!active || mps > config.maxSpeedMps) { // nothing counts, or an impossible speed: start over at the next one
            track.lastSpeed = -1.0
            track.lastAtMs = atMs
            return out
        }
        if (track.lastSpeed < 0.0) {
            track.lastSpeed = mps
            track.lastAtMs = atMs
            if (selected == source) out.add(WorkoutEvent.BaselineEstablished(nextSeq(), atMs, source, mps, track.reason))
            return out
        }
        val dt = atMs - track.lastAtMs
        if (selected == source && dt > 0L && dt <= config.maxIntegrationGapMs) {
            val delta = 0.5 * (track.lastSpeed + mps) * dt / 1000.0
            if (delta > 0.0) credit(source, delta, atMs, out)
        }
        track.lastSpeed = mps
        track.lastAtMs = atMs
        return out
    }

    // ── recovery (a journal replay) ─────────────────────────────────────────

    internal fun restoreDistance(delta: Double) {
        if (delta.isFinite() && delta > 0.0) distanceMeters += delta
    }

    internal fun restoreSelected(source: DistanceSource) {
        selected = source
    }

    // ── internals ───────────────────────────────────────────────────────────

    private fun track(source: DistanceSource, epoch: Long, atMs: Long): Track? {
        val t = tracks.getOrPut(source) { Track(source, epoch) }
        if (epoch < t.epoch) return null
        if (epoch > t.epoch) {
            t.epoch = epoch
            t.baselined = false
            t.lastSpeed = -1.0
            t.lastAtMs = -1L
            t.reason = "a new connection"
        }
        if (atMs < t.seenAtMs) return null
        t.seenAtMs = atMs
        return t
    }

    private fun forgetBaselines(reason: String) {
        for (t in tracks.values) {
            t.baselined = false
            t.lastSpeed = -1.0
            t.reason = reason
        }
    }

    private fun baseline(track: Track, meters: Double, atMs: Long, out: MutableList<WorkoutEvent>) {
        track.lastValue = meters
        track.lastAtMs = atMs
        track.baselined = true
        if (selected == track.source) out.add(WorkoutEvent.BaselineEstablished(nextSeq(), atMs, track.source, meters, track.reason))
    }

    private fun credit(source: DistanceSource, delta: Double, atMs: Long, out: MutableList<WorkoutEvent>) {
        distanceMeters += delta
        out.add(WorkoutEvent.DistanceAdvanced(nextSeq(), atMs, source, delta))
    }

    private fun evaluate(nowMs: Long, out: MutableList<WorkoutEvent>) {
        fun fresh(t: Track) = t.seenAtMs >= 0L && nowMs - t.seenAtMs <= config.staleAfterMs
        val candidates = tracks.values.filter { fresh(it) }
        if (candidates.isEmpty()) return
        val wanted = preferred?.let { tracks[it] }?.takeIf { fresh(it) }
        val current = selected?.let { tracks[it] }?.takeIf { fresh(it) }
        val next = wanted ?: current ?: candidates.minByOrNull { rank(it.source.kind) }!!
        if (next.source == selected) return
        val reason = when {
            wanted != null -> "preferred by the user"
            selected == null -> "first source"
            else -> "the previous source went quiet"
        }
        selected = next.source
        next.baselined = false // the distance so far is kept; the new source starts from a new baseline
        next.lastSpeed = -1.0
        next.reason = "source selected"
        out.add(WorkoutEvent.SourceSelected(nextSeq(), nowMs, next.source, reason))
    }

    private fun rank(kind: DistanceSourceKind): Int = if (mode.isIndoor) {
        when (kind) { DistanceSourceKind.COUNTER -> 0; DistanceSourceKind.SPEED -> 1; DistanceSourceKind.GPS -> 2 }
    } else {
        when (kind) { DistanceSourceKind.GPS -> 0; DistanceSourceKind.COUNTER -> 1; DistanceSourceKind.SPEED -> 2 }
    }
}
