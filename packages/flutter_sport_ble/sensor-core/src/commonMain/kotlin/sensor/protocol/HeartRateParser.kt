package sensor.protocol

import sensor.model.MeasurementKind
import sensor.model.MetricType
import sensor.model.SensorReading

/** One decoded Heart Rate Measurement (0x2A37). */
class HeartRateMeasurement(
    /** Beats per minute, or null when the packet carries no usable value (0, or the strap has no skin contact). */
    val bpm: Int?,
    /** Energy expended in kJ since the sensor reset, when present. */
    val energyKj: Int?,
    /** R-R intervals in milliseconds (the packet has them in 1/1024 s), when present. */
    val rrIntervalsMs: List<Int>,
    /** True when the sensor says it has no skin contact (the value cannot be trusted). */
    val contactLost: Boolean,
)

/**
 * Heart Rate Measurement: flags (bit 0: value is uint16 instead of uint8; bits 1-2: sensor contact, 2 = supported but not
 * detected, 3 = detected; bit 3: energy expended present, uint16 kJ; bit 4: one or more R-R intervals, uint16 each, 1/1024 s),
 * then the value, then the optional fields in that order. A truncated packet is rejected as a whole.
 */
object HeartRateParser {
    const val MAX_BPM = 300

    fun parse(bytes: ByteArray): HeartRateMeasurement? {
        if (bytes.size < 2) return null
        val flags = bytes[0].toInt() and 0xFF
        val wide = flags and 0x01 != 0
        val contact = (flags shr 1) and 0x03
        var at = 1
        val raw: Int
        if (wide) {
            if (bytes.size < at + 2) return null
            raw = u16(bytes, at); at += 2
        } else {
            raw = bytes[at].toInt() and 0xFF; at += 1
        }
        var energy: Int? = null
        if (flags and 0x08 != 0) {
            if (bytes.size < at + 2) return null
            energy = u16(bytes, at); at += 2
        }
        val rr = ArrayList<Int>()
        if (flags and 0x10 != 0) {
            if (bytes.size < at + 2 || (bytes.size - at) % 2 != 0) return null
            while (at + 2 <= bytes.size) {
                rr.add((u16(bytes, at) * 1000L / 1024L).toInt())
                at += 2
            }
        }
        val contactLost = contact == 2
        val bpm = if (raw in 1..MAX_BPM && !contactLost) raw else null
        return HeartRateMeasurement(bpm, energy, rr, contactLost)
    }

    fun readings(bytes: ByteArray): List<SensorReading> {
        val bpm = parse(bytes)?.bpm ?: return emptyList()
        return listOf(SensorReading(MetricType.HEART_RATE, bpm.toDouble(), MeasurementKind.INSTANTANEOUS))
    }

    private fun u16(b: ByteArray, at: Int): Int = (b[at].toInt() and 0xFF) or ((b[at + 1].toInt() and 0xFF) shl 8)
}
