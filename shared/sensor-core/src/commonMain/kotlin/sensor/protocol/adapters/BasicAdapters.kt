package sensor.protocol.adapters

import sensor.model.Capability
import sensor.model.DeviceInfoField
import sensor.model.MeasurementKind
import sensor.model.MetricType
import sensor.model.SensorEvent
import sensor.model.SensorReading
import sensor.protocol.BleProtocolAdapter
import sensor.protocol.CounterRate
import sensor.protocol.Gatt
import sensor.protocol.HeartRateParser
import sensor.protocol.RunningSpeedCadenceParser
import sensor.protocol.SourceState

internal fun measurement(metric: MetricType, value: Double, kind: MeasurementKind = MeasurementKind.INSTANTANEOUS): SensorEvent =
    SensorEvent.Measurement(SensorReading(metric, value, kind))

object HeartRateAdapter : BleProtocolAdapter {
    override val serviceUuid = Gatt.HEART_RATE_SERVICE
    override val capability = Capability.HEART_RATE
    override val notifyCharacteristics = listOf(Gatt.HEART_RATE_MEASUREMENT)

    override fun decode(characteristic: String, bytes: ByteArray, state: SourceState, nowMs: Long): List<SensorEvent> {
        val m = HeartRateParser.parse(bytes) ?: return emptyList()
        val out = ArrayList<SensorEvent>(2)
        m.bpm?.let { out.add(measurement(MetricType.HEART_RATE, it.toDouble())) }
        if (m.rrIntervalsMs.isNotEmpty()) out.add(SensorEvent.RrIntervals(m.rrIntervalsMs))
        return out
    }
}

object RunningSpeedCadenceAdapter : BleProtocolAdapter {
    override val serviceUuid = Gatt.RUNNING_SPEED_CADENCE_SERVICE
    override val capability = Capability.RUNNING_SPEED_CADENCE
    override val notifyCharacteristics = listOf(Gatt.RSC_MEASUREMENT)

    override fun decode(characteristic: String, bytes: ByteArray, state: SourceState, nowMs: Long): List<SensorEvent> =
        RunningSpeedCadenceParser.readings(bytes).map { SensorEvent.Measurement(it) }
}

/**
 * Cycling Speed and Cadence Measurement (0x2A5B): flags (bit 0 wheel data, bit 1 crank data), wheel revolutions (uint32) and last
 * wheel event time (uint16, 1/1024 s), crank revolutions (uint16) and last crank event time (uint16, 1/1024 s). The crank gives
 * CYCLING_CADENCE (0 when verified still), the wheel gives the WHEEL_REVOLUTIONS counter and, when the host knows the wheel
 * circumference, CYCLING_SPEED. The raw packet is also forwarded to the host.
 */
object CyclingSpeedCadenceAdapter : BleProtocolAdapter {
    override val serviceUuid = Gatt.CYCLING_SPEED_CADENCE_SERVICE
    override val capability = Capability.CYCLING_SPEED_CADENCE
    override val notifyCharacteristics = listOf(Gatt.CSC_MEASUREMENT)
    override val forwardRaw = setOf(Gatt.CSC_MEASUREMENT)

    override fun decode(characteristic: String, bytes: ByteArray, state: SourceState, nowMs: Long): List<SensorEvent> {
        if (bytes.isEmpty()) return emptyList()
        val flags = bytes[0].toInt() and 0xFF
        val r = sensor.protocol.ByteReader(bytes, 1)
        var wheelCount = -1L
        var wheelTicks = 0
        var crankCount = -1
        var crankTicks = 0
        if (flags and 0x01 != 0) { wheelCount = r.u32(); wheelTicks = r.u16() }
        if (flags and 0x02 != 0) { crankCount = r.u16(); crankTicks = r.u16() }
        if (!r.ok || flags and 0x03 == 0) return emptyList()
        val out = ArrayList<SensorEvent>(3)
        CycleCounters.crank(state, crankCount.toLong(), crankTicks, nowMs, out)
        CycleCounters.wheel(state, "csc.wheel", wheelCount, wheelTicks, nowMs, CounterRate.Companion::cscWheel, out)
        return out
    }
}

/** What both the CSC and the power meter do with a crank or a wheel counter. */
internal object CycleCounters {
    fun crank(state: SourceState, count: Long, ticks: Int, nowMs: Long, out: MutableList<SensorEvent>) {
        if (count < 0L) return
        val rate = state.getOrPut("crank") { CounterRate.crank() }.onSample(count, ticks, nowMs)
        if (rate >= 0.0) out.add(measurement(MetricType.CYCLING_CADENCE, rate * 60.0))
    }

    fun wheel(
        state: SourceState, key: String, count: Long, ticks: Int, nowMs: Long, make: () -> CounterRate,
        out: MutableList<SensorEvent>,
    ) {
        if (count < 0L) return
        out.add(measurement(MetricType.WHEEL_REVOLUTIONS, count.toDouble(), MeasurementKind.CUMULATIVE))
        val circumference = state.wheelCircumferenceM ?: return
        val rate = state.getOrPut(key, make).onSample(count, ticks, nowMs)
        if (rate >= 0.0) out.add(measurement(MetricType.CYCLING_SPEED, rate * circumference))
    }
}

/**
 * Cycling Power Measurement (0x2A63): flags (uint16), instantaneous power (sint16, W), then by flag: pedal power balance (bit 0,
 * uint8), accumulated torque (bit 2, uint16), wheel revolution data (bit 4: uint32 + uint16 in 1/2048 s), crank revolution data
 * (bit 5: uint16 + uint16 in 1/1024 s). Later fields (extreme forces, angles, energy) are not needed and not read. A negative
 * power is noise and becomes 0. Not every power meter sends crank data: cadence is only given when the packet has it.
 */
object CyclingPowerAdapter : BleProtocolAdapter {
    override val serviceUuid = Gatt.CYCLING_POWER_SERVICE
    override val capability = Capability.CYCLING_POWER
    override val notifyCharacteristics = listOf(Gatt.CYCLING_POWER_MEASUREMENT)

    override fun decode(characteristic: String, bytes: ByteArray, state: SourceState, nowMs: Long): List<SensorEvent> {
        val r = sensor.protocol.ByteReader(bytes)
        val flags = r.u16()
        val power = r.s16()
        if (flags and 0x01 != 0) r.skip(1)
        if (flags and 0x04 != 0) r.skip(2)
        var wheelCount = -1L
        var wheelTicks = 0
        var crankCount = -1
        var crankTicks = 0
        if (flags and 0x10 != 0) { wheelCount = r.u32(); wheelTicks = r.u16() }
        if (flags and 0x20 != 0) { crankCount = r.u16(); crankTicks = r.u16() }
        if (!r.ok) return emptyList()
        val out = ArrayList<SensorEvent>(4)
        out.add(measurement(MetricType.POWER_WATTS, maxOf(0, power).toDouble()))
        CycleCounters.crank(state, crankCount.toLong(), crankTicks, nowMs, out)
        CycleCounters.wheel(state, "cps.wheel", wheelCount, wheelTicks, nowMs, CounterRate.Companion::powerWheel, out)
        return out
    }
}

/** Battery Level (0x2A19): one byte, 0 to 100. Read once and notified when the device supports it. */
object BatteryAdapter : BleProtocolAdapter {
    override val serviceUuid = Gatt.BATTERY_SERVICE
    override val capability = Capability.BATTERY
    override val notifyCharacteristics = listOf(Gatt.BATTERY_LEVEL)
    override val readCharacteristics = listOf(Gatt.BATTERY_LEVEL)

    override fun decode(characteristic: String, bytes: ByteArray, state: SourceState, nowMs: Long): List<SensorEvent> {
        if (bytes.isEmpty()) return emptyList()
        val percent = bytes[0].toInt() and 0xFF
        return if (percent in 0..100) listOf(SensorEvent.Battery(percent)) else emptyList()
    }
}

/** Device Information strings (manufacturer, model, firmware, hardware, software), read once. The serial number is not read. */
object DeviceInformationAdapter : BleProtocolAdapter {
    override val serviceUuid = Gatt.DEVICE_INFORMATION_SERVICE
    override val capability = Capability.DEVICE_INFORMATION
    override val notifyCharacteristics = emptyList<String>()
    override val readCharacteristics = listOf(
        Gatt.MANUFACTURER_NAME, Gatt.MODEL_NUMBER, Gatt.FIRMWARE_REVISION, Gatt.HARDWARE_REVISION, Gatt.SOFTWARE_REVISION,
    )

    override fun decode(characteristic: String, bytes: ByteArray, state: SourceState, nowMs: Long): List<SensorEvent> {
        val field = when (characteristic) {
            Gatt.MANUFACTURER_NAME -> DeviceInfoField.MANUFACTURER
            Gatt.MODEL_NUMBER -> DeviceInfoField.MODEL
            Gatt.FIRMWARE_REVISION -> DeviceInfoField.FIRMWARE
            Gatt.HARDWARE_REVISION -> DeviceInfoField.HARDWARE
            Gatt.SOFTWARE_REVISION -> DeviceInfoField.SOFTWARE
            else -> return emptyList()
        }
        val text = bytes.decodeToString().trim { it == '\u0000' || it.isWhitespace() }
        return if (text.isEmpty() || text.length > 64) emptyList() else listOf(SensorEvent.DeviceInfo(field, text))
    }
}
