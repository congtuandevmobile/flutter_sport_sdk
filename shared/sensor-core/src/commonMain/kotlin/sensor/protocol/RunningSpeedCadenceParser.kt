package sensor.protocol

import sensor.model.MeasurementKind
import sensor.model.MetricType
import sensor.model.SensorReading

/** One decoded RSC Measurement (0x2A53). */
class RunningSpeedCadenceMeasurement(
    /** Metres per second. */
    val speedMps: Double,
    /** Per minute, as the device reports it (steps or strides: devices differ, check with the real device). */
    val cadencePerMin: Int,
    /** Metres, when the device sends it. */
    val strideLengthM: Double?,
    /** Metres since the device's own start, when the device sends it. */
    val totalDistanceM: Double?,
    val isRunning: Boolean,
)

/**
 * RSC Measurement: flags (bit 0: stride length present; bit 1: total distance present; bit 2: running (1) or walking (0)),
 * then speed (uint16, 1/256 m/s), cadence (uint8, 1/min), then stride length (uint16, 1/100 m) and total distance
 * (uint32, 1/10 m) when flagged. Speed and cadence are mandatory; a truncated packet is rejected as a whole.
 */
object RunningSpeedCadenceParser {
    const val MAX_SPEED_MPS = 15.0

    fun parse(bytes: ByteArray): RunningSpeedCadenceMeasurement? {
        if (bytes.size < 4) return null
        val flags = bytes[0].toInt() and 0xFF
        var at = 1
        val speed = u16(bytes, at) / 256.0; at += 2
        val cadence = bytes[at].toInt() and 0xFF; at += 1
        var stride: Double? = null
        if (flags and 0x01 != 0) {
            if (bytes.size < at + 2) return null
            stride = u16(bytes, at) / 100.0; at += 2
        }
        var distance: Double? = null
        if (flags and 0x02 != 0) {
            if (bytes.size < at + 4) return null
            distance = u32(bytes, at) / 10.0; at += 4
        }
        if (speed > MAX_SPEED_MPS) return null
        return RunningSpeedCadenceMeasurement(speed, cadence, stride?.takeIf { it > 0.0 }, distance, flags and 0x04 != 0)
    }

    fun readings(bytes: ByteArray): List<SensorReading> {
        val m = parse(bytes) ?: return emptyList()
        val out = ArrayList<SensorReading>(4)
        out.add(SensorReading(MetricType.RUNNING_SPEED, m.speedMps, MeasurementKind.INSTANTANEOUS))
        out.add(SensorReading(MetricType.RUNNING_CADENCE, m.cadencePerMin.toDouble(), MeasurementKind.INSTANTANEOUS))
        m.strideLengthM?.let { out.add(SensorReading(MetricType.RUNNING_STRIDE_LENGTH, it, MeasurementKind.INSTANTANEOUS)) }
        m.totalDistanceM?.let { out.add(SensorReading(MetricType.TOTAL_DISTANCE, it, MeasurementKind.CUMULATIVE)) }
        return out
    }

    private fun u16(b: ByteArray, at: Int): Int = (b[at].toInt() and 0xFF) or ((b[at + 1].toInt() and 0xFF) shl 8)
    private fun u32(b: ByteArray, at: Int): Long =
        (b[at].toLong() and 0xFF) or ((b[at + 1].toLong() and 0xFF) shl 8) or
            ((b[at + 2].toLong() and 0xFF) shl 16) or ((b[at + 3].toLong() and 0xFF) shl 24)
}
