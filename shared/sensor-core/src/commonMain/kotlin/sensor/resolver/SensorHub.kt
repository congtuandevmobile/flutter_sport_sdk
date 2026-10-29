package sensor.resolver

import sensor.model.MetricType
import sensor.protocol.Gatt
import sensor.protocol.HeartRateParser
import sensor.protocol.RunningSpeedCadenceParser

/**
 * What a native BLE layer holds: it forwards every connection event and every notification (the characteristic and its bytes)
 * and asks for the resolved metrics. Decoding, validation, epochs, freshness and the choice of source are all here, so
 * Android and iOS behave the same and the Flutter side never sees a byte.
 *
 * A characteristic the hub does not decode (the Cycling Speed and Cadence Measurement, for instance) is ignored here: the
 * native layer forwards its bytes to whoever decodes it. Not thread-safe.
 */
class SensorHub(config: MetricResolverConfig = MetricResolverConfig()) {
    private val resolver = MetricResolver(config)

    fun onConnection(sourceId: String, epoch: Long, connected: Boolean): Boolean =
        resolver.onConnection(sourceId, epoch, connected)

    /** One notification. Returns how many readings were taken (0 for an unknown, malformed or stale-epoch packet). */
    fun onPacket(sourceId: String, epoch: Long, characteristic: String, bytes: ByteArray, nowMs: Long): Int {
        val readings = when (Gatt.short(characteristic)) {
            Gatt.HEART_RATE_MEASUREMENT -> HeartRateParser.readings(bytes)
            Gatt.RSC_MEASUREMENT -> RunningSpeedCadenceParser.readings(bytes)
            else -> return 0
        }
        var taken = 0
        for (reading in readings) if (resolver.onReading(sourceId, epoch, reading, nowMs)) taken += 1
        return taken
    }

    fun setPreferred(metric: MetricType, sourceId: String?) = resolver.setPreferred(metric, sourceId)

    fun forget(sourceId: String) = resolver.forget(sourceId)

    fun resolve(nowMs: Long): List<ResolvedMetric> = resolver.resolve(nowMs)

    fun reset() = resolver.reset()

    companion object {
        /** A hub with the starting values (Swift cannot use Kotlin default arguments). */
        fun standard(): SensorHub = SensorHub()
    }
}
