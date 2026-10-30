package sensor.resolver

import sensor.model.Capability
import sensor.model.MeasurementKind
import sensor.model.MetricType
import sensor.model.SensorReading

/** The chosen value of one metric. [ageMs] is how old it is on the receiving phone's monotonic clock. */
class ResolvedMetric(
    val metric: MetricType,
    val value: Double,
    val sourceId: String,
    val kind: MeasurementKind,
    val ageMs: Long,
)

/**
 * The latest value of one metric of ONE device, before any source is chosen: [sourceId] and [epoch] say whose it is and of which
 * connection, [ageMs] how old it is (the consumer decides what is fresh). A caller that needs a specific device's counter (a rower's
 * distance next to a footpod's) reads it here instead of from the resolved value.
 */
class DeviceMetricValue(
    val sourceId: String,
    val epoch: Long,
    val metric: MetricType,
    val value: Double,
    val kind: MeasurementKind,
    val ageMs: Long,
)

/** Starting values, not measured. */
class MetricResolverConfig(
    /** A source with no value of a metric for this long is stale for that metric. */
    val staleAfterMs: Long = 5_000,
    /** After a (re)connect or a stale spell a source needs this many valid values... */
    val recoveryMinSamples: Int = 2,
    /** ...spread over at least this long, before it is a candidate again. */
    val recoveryMinMs: Long = 1_000,
) {
    init {
        require(staleAfterMs > 0 && recoveryMinMs >= 0) { "durations" }
        require(recoveryMinSamples >= 1) { "samples" }
    }

    companion object {
        fun standard(): MetricResolverConfig = MetricResolverConfig()
    }
}

/**
 * Chooses ONE source for each metric, at the level of the metric (not of the workout): a session can take its heart rate
 * from a chest strap and its cadence from a footpod at the same time. Values are never averaged or summed.
 *
 *  - A source is a candidate for a metric while it is connected, its value is fresh ([MetricResolverConfig.staleAfterMs]) and
 *    it has recovered (see the config). A value of 0 is a measurement like any other.
 *  - Choice: the source the user prefers ([setPreferred]) when it is a candidate, else the candidate of the best RANK for the
 *    metric ([SourcePolicy]: a heart rate strap before a machine's heart rate, a power meter's cadence before a cadence sensor's),
 *    else, among equals, the one already chosen (so two equally good sources do not alternate), else the one that connected first.
 *    A better ranked source that becomes healthy takes over once; it never alternates, because a rank does not change.
 *  - A source is `(sourceId, epoch)`: the epoch grows with every new connection to the device. A reading or a connection event
 *    of an older epoch is dropped, and a newer epoch forgets everything the source had (counters of a reset sensor are never
 *    compared with the old ones).
 * All times come from one monotonic clock. Not thread-safe (the native engine calls it under its own lock/queue).
 */
class MetricResolver(private val config: MetricResolverConfig = MetricResolverConfig()) {
    private class Source(var epoch: Long, var connected: Boolean, val order: Long) {
        var capabilities: Set<Capability> = emptySet()
    }

    private class Entry(var value: Double, var kind: MeasurementKind, var atMs: Long) {
        var samples = 1
        var sinceMs = atMs
    }

    private val sources = HashMap<String, Source>()
    private val entries = HashMap<MetricType, HashMap<String, Entry>>()
    private val chosen = HashMap<MetricType, String>()
    private val preferred = HashMap<MetricType, String>()
    private var nextOrder = 0L

    /** The host connected to (or lost) a device. Returns false when the event is of an epoch older than the current one. */
    fun onConnection(sourceId: String, epoch: Long, connected: Boolean): Boolean {
        val source = sources[sourceId]
        if (source == null) {
            sources[sourceId] = Source(epoch, connected, nextOrder++)
            return true
        }
        if (epoch < source.epoch) return false
        if (epoch > source.epoch) {
            dropEntries(sourceId)
            source.epoch = epoch
        } else if (connected && !source.connected) {
            // The same epoch coming back is still a new link: it must earn its place again, never reuse what it had.
            dropEntries(sourceId)
        }
        source.connected = connected
        return true
    }

    /** What the device can do (decided from the services it really exposes); it decides its rank for each metric. */
    fun setCapabilities(sourceId: String, capabilities: Set<Capability>) {
        sources[sourceId]?.capabilities = capabilities
    }

    /** Takes a reading of a connected source of the current epoch; false when it was dropped. */
    fun onReading(sourceId: String, epoch: Long, reading: SensorReading, atMs: Long): Boolean {
        val source = sources[sourceId] ?: return false
        if (epoch != source.epoch || !source.connected) return false
        if (!reading.value.isFinite() || atMs < 0L) return false
        val byMetric = entries.getOrPut(reading.metric) { HashMap() }
        val entry = byMetric[sourceId]
        if (entry == null) {
            byMetric[sourceId] = Entry(reading.value, reading.kind, atMs)
            return true
        }
        if (atMs < entry.atMs) return false
        if (atMs - entry.atMs > config.staleAfterMs) { // a stale spell passed: it must earn its place again
            entry.samples = 0
            entry.sinceMs = atMs
        }
        entry.value = reading.value
        entry.kind = reading.kind
        entry.atMs = atMs
        entry.samples += 1
        return true
    }

    /** The user's choice for [metric] (null clears it). It only applies while that source is a candidate. */
    fun setPreferred(metric: MetricType, sourceId: String?) {
        if (sourceId == null) preferred.remove(metric) else preferred[metric] = sourceId
    }

    /** Forgets a device altogether (the user removed it). */
    fun forget(sourceId: String) {
        sources.remove(sourceId)
        dropEntries(sourceId)
        preferred.entries.removeAll { it.value == sourceId }
    }

    /** The chosen value of every metric that has a candidate, at [nowMs]. */
    fun resolve(nowMs: Long): List<ResolvedMetric> {
        val out = ArrayList<ResolvedMetric>()
        for (metric in MetricType.values()) {
            val byMetric = entries[metric] ?: continue
            val candidates = ArrayList<String>()
            for ((id, entry) in byMetric) if (isCandidate(id, entry, nowMs)) candidates.add(id)
            if (candidates.isEmpty()) {
                chosen.remove(metric)
                continue
            }
            val id = pick(metric, candidates)
            val entry = byMetric.getValue(id)
            out.add(ResolvedMetric(metric, entry.value, id, entry.kind, nowMs - entry.atMs))
        }
        return out
    }

    /** The latest value of every metric of every CONNECTED device (any age: [DeviceMetricValue.ageMs] tells), nothing is chosen. */
    fun deviceValues(nowMs: Long): List<DeviceMetricValue> {
        val out = ArrayList<DeviceMetricValue>()
        for (metric in MetricType.values()) {
            val byMetric = entries[metric] ?: continue
            for ((id, entry) in byMetric) {
                val source = sources[id] ?: continue
                if (!source.connected || nowMs < entry.atMs) continue
                out.add(DeviceMetricValue(id, source.epoch, metric, entry.value, entry.kind, nowMs - entry.atMs))
            }
        }
        return out
    }

    fun reset() {
        sources.clear()
        entries.clear()
        chosen.clear()
        preferred.clear()
        nextOrder = 0L
    }

    private fun pick(metric: MetricType, candidates: List<String>): String {
        preferred[metric]?.let { if (it in candidates) { chosen[metric] = it; return it } }
        val bestRank = candidates.minOf { rank(metric, it) }
        val best = candidates.filter { rank(metric, it) == bestRank }
        chosen[metric]?.let { if (it in best) return it }
        var first = best[0]
        for (id in best) if (order(id) < order(first)) first = id
        chosen[metric] = first
        return first
    }

    private fun rank(metric: MetricType, id: String): Int = SourcePolicy.rank(metric, sources[id]?.capabilities ?: emptySet())

    private fun order(id: String): Long = sources[id]?.order ?: Long.MAX_VALUE

    private fun isCandidate(id: String, entry: Entry, nowMs: Long): Boolean {
        val source = sources[id] ?: return false
        if (!source.connected || nowMs < entry.atMs) return false
        if (nowMs - entry.atMs > config.staleAfterMs) {
            entry.samples = 0 // stale: it must earn its place again
            return false
        }
        return entry.samples >= config.recoveryMinSamples && entry.atMs - entry.sinceMs >= config.recoveryMinMs
    }

    private fun dropEntries(sourceId: String) {
        for (byMetric in entries.values) byMetric.remove(sourceId)
    }
}
