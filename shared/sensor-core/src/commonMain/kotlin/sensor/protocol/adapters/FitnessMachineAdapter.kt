package sensor.protocol.adapters

import sensor.model.Capability
import sensor.model.MeasurementKind
import sensor.model.MetricType
import sensor.model.SensorEvent
import sensor.protocol.BleProtocolAdapter
import sensor.protocol.ByteReader
import sensor.protocol.Gatt
import sensor.protocol.SourceState

/**
 * Fitness Machine Service (0x1826), READ-ONLY telemetry: the data characteristics of treadmill (0x2ACD), cross trainer (0x2ACE),
 * step climber (0x2ACF), stair climber (0x2AD0), rower (0x2AD1) and indoor bike (0x2AD2). The control point is never touched.
 *
 * Every data characteristic starts with flags and then lists its fields in a fixed order, each present or not by a flag. The
 * parser reads every field the flags announce, so a later field is never misaligned, and rejects the whole packet if it is
 * truncated. In the "more data" flag (bit 0) a value of 0 means the first field is PRESENT. The field layouts are written from
 * the Bluetooth SIG specification and golden packets, NOT yet captured from a device: the size of the Resistance Level field
 * (taken as 2 bytes) and the step and stair climber layouts in particular need a real machine to confirm.
 */
object FitnessMachineAdapter : BleProtocolAdapter {
    override val serviceUuid = Gatt.FITNESS_MACHINE_SERVICE
    override val capability = Capability.FITNESS_MACHINE
    override val notifyCharacteristics = listOf(
        Gatt.TREADMILL_DATA, Gatt.CROSS_TRAINER_DATA, Gatt.STEP_CLIMBER_DATA, Gatt.STAIR_CLIMBER_DATA,
        Gatt.ROWER_DATA, Gatt.INDOOR_BIKE_DATA,
    )

    private const val MAX_RUN_SPEED = 15.0
    private const val MAX_BIKE_SPEED = 30.0
    private const val MAX_POWER = 3000
    private const val ENERGY_NOT_AVAILABLE = 0xFFFF

    override fun decode(characteristic: String, bytes: ByteArray, state: SourceState, nowMs: Long): List<SensorEvent> {
        val r = ByteReader(bytes)
        val out = ArrayList<SensorEvent>(6)
        when (characteristic) {
            Gatt.TREADMILL_DATA -> treadmill(r, out)
            Gatt.INDOOR_BIKE_DATA -> indoorBike(r, out)
            Gatt.ROWER_DATA -> rower(r, out)
            Gatt.CROSS_TRAINER_DATA -> crossTrainer(r, out)
            Gatt.STEP_CLIMBER_DATA -> stepClimber(r, out)
            Gatt.STAIR_CLIMBER_DATA -> stairClimber(r, out)
            else -> return emptyList()
        }
        return if (r.ok) out else emptyList()
    }

    private fun kmh(raw: Int): Double = raw * 0.01 / 3.6

    private fun distance(r: ByteReader, out: MutableList<SensorEvent>) {
        val metres = r.u24()
        if (r.ok) out.add(measurement(MetricType.TOTAL_DISTANCE, metres.toDouble(), MeasurementKind.CUMULATIVE))
    }

    private fun energy(r: ByteReader, out: MutableList<SensorEvent>) {
        val total = r.u16()
        r.skip(3) // energy per hour (uint16), per minute (uint8)
        if (r.ok && total != ENERGY_NOT_AVAILABLE) out.add(measurement(MetricType.ENERGY_KCAL, total.toDouble(), MeasurementKind.CUMULATIVE))
    }

    private fun heartRate(r: ByteReader, out: MutableList<SensorEvent>) {
        val bpm = r.u8()
        if (r.ok && bpm in 1..300) out.add(measurement(MetricType.HEART_RATE, bpm.toDouble()))
    }

    private fun power(r: ByteReader, out: MutableList<SensorEvent>) {
        val w = r.s16()
        if (r.ok && w <= MAX_POWER) out.add(measurement(MetricType.POWER_WATTS, maxOf(0, w).toDouble()))
    }

    private fun treadmill(r: ByteReader, out: MutableList<SensorEvent>) {
        val f = r.u16()
        if (f and 0x0001 == 0) {
            val v = kmh(r.u16())
            if (r.ok && v <= MAX_RUN_SPEED) out.add(measurement(MetricType.RUNNING_SPEED, v))
        }
        if (f and 0x0002 != 0) r.skip(2)
        if (f and 0x0004 != 0) distance(r, out)
        if (f and 0x0008 != 0) {
            val incline = r.s16() / 10.0
            r.skip(2) // ramp angle
            if (r.ok) out.add(measurement(MetricType.INCLINE, incline))
        }
        if (f and 0x0010 != 0) r.skip(4)
        if (f and 0x0020 != 0) r.skip(1)
        if (f and 0x0040 != 0) r.skip(1)
        if (f and 0x0080 != 0) energy(r, out)
        if (f and 0x0100 != 0) heartRate(r, out)
        if (f and 0x0200 != 0) r.skip(1)
        if (f and 0x0400 != 0) r.skip(2)
        if (f and 0x0800 != 0) r.skip(2)
        if (f and 0x1000 != 0) r.skip(4)
    }

    private fun indoorBike(r: ByteReader, out: MutableList<SensorEvent>) {
        val f = r.u16()
        if (f and 0x0001 == 0) {
            val v = kmh(r.u16())
            if (r.ok && v <= MAX_BIKE_SPEED) out.add(measurement(MetricType.CYCLING_SPEED, v))
        }
        if (f and 0x0002 != 0) r.skip(2)
        if (f and 0x0004 != 0) {
            val rpm = r.u16() * 0.5
            if (r.ok && rpm <= 250.0) out.add(measurement(MetricType.CYCLING_CADENCE, rpm))
        }
        if (f and 0x0008 != 0) r.skip(2)
        if (f and 0x0010 != 0) distance(r, out)
        if (f and 0x0020 != 0) r.skip(2) // resistance level
        if (f and 0x0040 != 0) power(r, out)
        if (f and 0x0080 != 0) r.skip(2)
        if (f and 0x0100 != 0) energy(r, out)
        if (f and 0x0200 != 0) heartRate(r, out)
        if (f and 0x0400 != 0) r.skip(1)
        if (f and 0x0800 != 0) r.skip(2)
        if (f and 0x1000 != 0) r.skip(2)
    }

    private fun rower(r: ByteReader, out: MutableList<SensorEvent>) {
        val f = r.u16()
        if (f and 0x0001 == 0) {
            val rate = r.u8() * 0.5
            val count = r.u16()
            if (r.ok) {
                out.add(measurement(MetricType.STROKE_RATE, rate))
                out.add(measurement(MetricType.STROKE_COUNT, count.toDouble(), MeasurementKind.CUMULATIVE))
            }
        }
        if (f and 0x0002 != 0) r.skip(1)
        if (f and 0x0004 != 0) distance(r, out)
        if (f and 0x0008 != 0) r.skip(2)
        if (f and 0x0010 != 0) r.skip(2)
        if (f and 0x0020 != 0) power(r, out)
        if (f and 0x0040 != 0) r.skip(2)
        if (f and 0x0080 != 0) r.skip(2)
        if (f and 0x0100 != 0) energy(r, out)
        if (f and 0x0200 != 0) heartRate(r, out)
        if (f and 0x0400 != 0) r.skip(1)
        if (f and 0x0800 != 0) r.skip(2)
        if (f and 0x1000 != 0) r.skip(2)
    }

    private fun crossTrainer(r: ByteReader, out: MutableList<SensorEvent>) {
        val f = r.u24()
        if (f and 0x000001 == 0) r.skip(2) // instantaneous speed: not a metric of this machine
        if (f and 0x000002 != 0) r.skip(2)
        if (f and 0x000004 != 0) distance(r, out)
        if (f and 0x000008 != 0) {
            val perMin = r.u16()
            r.skip(2)
            if (r.ok) out.add(measurement(MetricType.STEP_RATE, perMin.toDouble()))
        }
        if (f and 0x000010 != 0) r.skip(2)
        if (f and 0x000020 != 0) r.skip(4)
        if (f and 0x000040 != 0) {
            val incline = r.s16() / 10.0
            r.skip(2)
            if (r.ok) out.add(measurement(MetricType.INCLINE, incline))
        }
        if (f and 0x000080 != 0) r.skip(2)
        if (f and 0x000100 != 0) power(r, out)
        if (f and 0x000200 != 0) r.skip(2)
        if (f and 0x000400 != 0) energy(r, out)
        if (f and 0x000800 != 0) heartRate(r, out)
        if (f and 0x001000 != 0) r.skip(1)
        if (f and 0x002000 != 0) r.skip(2)
        if (f and 0x004000 != 0) r.skip(2)
    }

    private fun stepClimber(r: ByteReader, out: MutableList<SensorEvent>) {
        val f = r.u16()
        if (f and 0x0001 == 0) {
            val floors = r.u16()
            r.skip(2) // step count
            if (r.ok) out.add(measurement(MetricType.FLOORS, floors.toDouble(), MeasurementKind.CUMULATIVE))
        }
        if (f and 0x0002 != 0) {
            val perMin = r.u16()
            if (r.ok) out.add(measurement(MetricType.STEP_RATE, perMin.toDouble()))
        }
        if (f and 0x0004 != 0) r.skip(2)
        if (f and 0x0008 != 0) r.skip(2)
        if (f and 0x0010 != 0) energy(r, out)
        if (f and 0x0020 != 0) heartRate(r, out)
        if (f and 0x0040 != 0) r.skip(1)
        if (f and 0x0080 != 0) r.skip(2)
        if (f and 0x0100 != 0) r.skip(2)
    }

    private fun stairClimber(r: ByteReader, out: MutableList<SensorEvent>) {
        val f = r.u16()
        if (f and 0x0001 == 0) {
            val floors = r.u16()
            if (r.ok) out.add(measurement(MetricType.FLOORS, floors.toDouble(), MeasurementKind.CUMULATIVE))
        }
        if (f and 0x0002 != 0) {
            val perMin = r.u16()
            if (r.ok) out.add(measurement(MetricType.STEP_RATE, perMin.toDouble()))
        }
        if (f and 0x0004 != 0) r.skip(2)
        if (f and 0x0008 != 0) r.skip(2)
        if (f and 0x0010 != 0) r.skip(2)
        if (f and 0x0020 != 0) energy(r, out)
        if (f and 0x0040 != 0) heartRate(r, out)
        if (f and 0x0080 != 0) r.skip(1)
        if (f and 0x0100 != 0) r.skip(2)
        if (f and 0x0200 != 0) r.skip(2)
    }
}
