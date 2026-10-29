package sensor.resolver

import sensor.model.Capability
import sensor.model.DeviceDetails
import sensor.model.DeviceInfoField
import sensor.model.MetricType
import sensor.model.SensorEvent
import sensor.protocol.Gatt
import sensor.protocol.ProtocolRegistry
import sensor.protocol.SourceState

/**
 * What a native BLE layer holds: it forwards every connection event and every notification or read (the characteristic and its
 * bytes) and asks for the resolved metrics and the details of each device. Decoding (through [ProtocolRegistry]), validation,
 * epochs, freshness and the choice of source are all here, so Android and iOS behave the same and the Flutter side never sees a
 * byte.
 *
 * Per connection of a device the decoders start empty (the counters of a new connection are never compared with the old
 * ones). A characteristic the registry does not know is ignored. Not thread-safe.
 */
class SensorHub(config: MetricResolverConfig = MetricResolverConfig()) {
    private class Source(var epoch: Long) {
        var connected = false
        var state = SourceState()
        var wheelCircumferenceM: Double? = null
        val info = HashMap<DeviceInfoField, String>()
        var battery: Int? = null
        var rr: List<Int> = emptyList()
    }

    private val resolver = MetricResolver(config)
    private val sources = HashMap<String, Source>()

    fun onConnection(sourceId: String, epoch: Long, connected: Boolean): Boolean {
        if (!resolver.onConnection(sourceId, epoch, connected)) return false
        val source = sources.getOrPut(sourceId) { Source(epoch) }
        if (epoch > source.epoch || (connected && !source.connected)) {
            source.epoch = epoch
            source.state = SourceState().also { it.wheelCircumferenceM = source.wheelCircumferenceM }
            source.battery = null
            source.rr = emptyList()
        }
        source.connected = connected
        return true
    }

    /** What the device exposes (from its services); it decides its rank for each metric. */
    fun setCapabilities(sourceId: String, capabilities: List<Capability>) =
        resolver.setCapabilities(sourceId, capabilities.toSet())

    /** The wheel circumference in metres of a cycling wheel sensor (null clears it): without it a wheel gives only revolutions. */
    fun setWheelCircumference(sourceId: String, metres: Double?) {
        val source = sources[sourceId] ?: return
        val valid = metres?.takeIf { it.isFinite() && it in 0.5..3.0 }
        source.wheelCircumferenceM = valid
        source.state.wheelCircumferenceM = valid
    }

    /** One notification or read. Returns how many events were taken (0 for an unknown, malformed or stale-epoch packet). */
    fun onPacket(sourceId: String, epoch: Long, characteristic: String, bytes: ByteArray, nowMs: Long): Int {
        val source = sources[sourceId] ?: return 0
        if (epoch != source.epoch || !source.connected) return 0
        val adapter = ProtocolRegistry.adapterFor(characteristic) ?: return 0
        var taken = 0
        for (event in adapter.decode(Gatt.short(characteristic), bytes, source.state, nowMs)) {
            when (event) {
                is SensorEvent.Measurement -> if (resolver.onReading(sourceId, epoch, event.reading, nowMs)) taken += 1
                is SensorEvent.RrIntervals -> { source.rr = event.intervalsMs; taken += 1 }
                is SensorEvent.DeviceInfo -> { source.info[event.field] = event.value; taken += 1 }
                is SensorEvent.Battery -> { source.battery = event.percent; taken += 1 }
            }
        }
        return taken
    }

    fun details(sourceId: String): DeviceDetails {
        val s = sources[sourceId] ?: return DeviceDetails(null, null, null, null, emptyList())
        return DeviceDetails(
            s.info[DeviceInfoField.MANUFACTURER], s.info[DeviceInfoField.MODEL], s.info[DeviceInfoField.FIRMWARE],
            s.battery, s.rr,
        )
    }

    fun setPreferred(metric: MetricType, sourceId: String?) = resolver.setPreferred(metric, sourceId)

    fun forget(sourceId: String) {
        sources.remove(sourceId)
        resolver.forget(sourceId)
    }

    fun resolve(nowMs: Long): List<ResolvedMetric> = resolver.resolve(nowMs)

    fun reset() {
        sources.clear()
        resolver.reset()
    }

    companion object {
        /** A hub with the starting values (Swift cannot use Kotlin default arguments). */
        fun standard(): SensorHub = SensorHub()
    }
}
