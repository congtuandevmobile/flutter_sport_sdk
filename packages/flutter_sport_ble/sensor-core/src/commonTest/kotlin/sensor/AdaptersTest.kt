package sensor

import sensor.model.Capability
import sensor.model.DeviceInfoField
import sensor.model.MeasurementKind
import sensor.model.MetricType
import sensor.model.SensorEvent
import sensor.protocol.BleProtocolAdapter
import sensor.protocol.CounterRate
import sensor.protocol.ProtocolRegistry
import sensor.protocol.SourceState
import sensor.protocol.adapters.BatteryAdapter
import sensor.protocol.adapters.CyclingPowerAdapter
import sensor.protocol.adapters.CyclingSpeedCadenceAdapter
import sensor.protocol.adapters.DeviceInformationAdapter
import sensor.protocol.adapters.FitnessMachineAdapter
import sensor.protocol.adapters.HeartRateAdapter
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/** Golden packets written from the Bluetooth SIG field layouts (not captured from a device). */
class AdaptersTest {
    private fun b(vararg v: Int) = ByteArray(v.size) { v[it].toByte() }
    private fun u16(v: Int) = intArrayOf(v and 0xFF, (v shr 8) and 0xFF)

    private fun BleProtocolAdapter.run(ch: String, bytes: ByteArray, state: SourceState = SourceState(), now: Long = 0): Map<MetricType, Double> =
        decode(ch, bytes, state, now).filterIsInstance<SensorEvent.Measurement>().associate { it.reading.metric to it.reading.value }

    private fun BleProtocolAdapter.kinds(ch: String, bytes: ByteArray): Map<MetricType, MeasurementKind> =
        decode(ch, bytes, SourceState(), 0).filterIsInstance<SensorEvent.Measurement>().associate { it.reading.metric to it.reading.kind }

    // ---- heart rate: the R-R intervals are exposed ----

    @Test fun heartRateAdapterExposesRrIntervals() {
        val events = HeartRateAdapter.decode("2a37", b(0x16, 70, 0x00, 0x04, 0x00, 0x02), SourceState(), 0)
        assertEquals(2, events.size)
        val rr = events.filterIsInstance<SensorEvent.RrIntervals>().single()
        assertEquals(listOf(1000, 500), rr.intervalsMs)
        assertEquals(70.0, events.filterIsInstance<SensorEvent.Measurement>().single().reading.value, 0.0)
    }

    @Test fun rrIntervalsStillComeWhenTheValueIsNotUsable() {
        // contact not detected (flags bit 2 only) + rr present: no bpm, the intervals are still reported
        val events = HeartRateAdapter.decode("2a37", b(0x14, 70, 0x00, 0x04), SourceState(), 0)
        assertEquals(1, events.size)
        assertTrue(events.single() is SensorEvent.RrIntervals)
    }

    // ---- cycling speed and cadence ----

    private fun csc(flags: Int, vararg rest: Int) = b(flags, *rest)

    @Test fun cscCrankGivesCadenceAndZero() {
        val state = SourceState()
        val first = CyclingSpeedCadenceAdapter.run("2a5b", csc(0x02, *u16(100), *u16(1000)), state, 0)
        assertTrue(first.isEmpty(), "a baseline gives no value")
        val second = CyclingSpeedCadenceAdapter.run("2a5b", csc(0x02, *u16(101), *u16(1768)), state, 750)
        assertEquals(80.0, second.getValue(MetricType.CYCLING_CADENCE), 0.001)
        var t = 750L
        var last: Map<MetricType, Double> = emptyMap()
        while (t < 4_000) { t += 1000; last = CyclingSpeedCadenceAdapter.run("2a5b", csc(0x02, *u16(101), *u16(1768)), state, t) }
        assertEquals(0.0, last.getValue(MetricType.CYCLING_CADENCE), 0.0)
    }

    @Test fun cscWheelGivesTheCounterAndSpeedOnlyWithACircumference() {
        val state = SourceState()
        fun wheel(count: Long, ticks: Int) = csc(0x01, (count and 0xFF).toInt(), ((count shr 8) and 0xFF).toInt(), ((count shr 16) and 0xFF).toInt(), ((count shr 24) and 0xFF).toInt(), *u16(ticks))
        val a = CyclingSpeedCadenceAdapter.run("2a5b", wheel(1000, 0), state, 0)
        assertEquals(1000.0, a.getValue(MetricType.WHEEL_REVOLUTIONS), 0.0)
        assertTrue(MetricType.CYCLING_SPEED !in a)
        state.wheelCircumferenceM = 2.1
        CyclingSpeedCadenceAdapter.run("2a5b", wheel(1000, 0), state, 100) // baseline for the speed
        val c = CyclingSpeedCadenceAdapter.run("2a5b", wheel(1002, 1024), state, 1100)
        // 2 revolutions in 1 s at 2.1 m = 4.2 m/s
        assertEquals(4.2, c.getValue(MetricType.CYCLING_SPEED), 1e-6)
        assertEquals(MeasurementKind.CUMULATIVE, CyclingSpeedCadenceAdapter.kinds("2a5b", wheel(5, 0)).getValue(MetricType.WHEEL_REVOLUTIONS))
    }

    @Test fun cscWheelCounterRollsOverAt32Bits() {
        val state = SourceState().also { it.wheelCircumferenceM = 2.0 }
        fun wheel(count: Long, ticks: Int) = csc(0x01, (count and 0xFF).toInt(), ((count shr 8) and 0xFF).toInt(), ((count shr 16) and 0xFF).toInt(), ((count shr 24) and 0xFF).toInt(), *u16(ticks))
        CyclingSpeedCadenceAdapter.run("2a5b", wheel(0xFFFFFFFFL, 0), state, 0)
        val r = CyclingSpeedCadenceAdapter.run("2a5b", wheel(1, 1024), state, 1000)
        assertEquals(4.0, r.getValue(MetricType.CYCLING_SPEED), 1e-6) // 2 revolutions in 1 s
    }

    @Test fun cscMalformedPackets() {
        assertTrue(CyclingSpeedCadenceAdapter.decode("2a5b", b(), SourceState(), 0).isEmpty())
        assertTrue(CyclingSpeedCadenceAdapter.decode("2a5b", b(0x00), SourceState(), 0).isEmpty())
        assertTrue(CyclingSpeedCadenceAdapter.decode("2a5b", b(0x03, 1, 2, 3), SourceState(), 0).isEmpty())
        assertTrue(CyclingSpeedCadenceAdapter.decode("2a5b", b(0x02, 1), SourceState(), 0).isEmpty())
    }

    // ---- cycling power ----

    @Test fun powerOnlyPacketHasNoCadence() {
        val r = CyclingPowerAdapter.run("2a63", b(0x00, 0x00, *u16(230)))
        assertEquals(setOf(MetricType.POWER_WATTS), r.keys)
        assertEquals(230.0, r.getValue(MetricType.POWER_WATTS), 0.0)
    }

    @Test fun powerWithBalanceTorqueAndCrankReadsTheCrankAtTheRightOffset() {
        // flags: balance (bit 0) + accumulated torque (bit 2) + crank data (bit 5) = 0x0025
        val state = SourceState()
        fun p(count: Int, ticks: Int, w: Int) = b(0x25, 0x00, *u16(w), 100, *u16(500), *u16(count), *u16(ticks))
        assertEquals(setOf(MetricType.POWER_WATTS), CyclingPowerAdapter.run("2a63", p(100, 1000, 250), state, 0).keys)
        val r = CyclingPowerAdapter.run("2a63", p(101, 1768, 260), state, 750)
        assertEquals(260.0, r.getValue(MetricType.POWER_WATTS), 0.0)
        assertEquals(80.0, r.getValue(MetricType.CYCLING_CADENCE), 0.001)
    }

    @Test fun powerWheelUsesTheTwoThousandFortyEightTick() {
        val state = SourceState().also { it.wheelCircumferenceM = 2.0 }
        fun p(count: Int, ticks: Int) = b(0x10, 0x00, *u16(200), count and 0xFF, 0, 0, 0, *u16(ticks))
        CyclingPowerAdapter.run("2a63", p(10, 0), state, 0)
        val r = CyclingPowerAdapter.run("2a63", p(12, 2048), state, 1000)
        assertEquals(4.0, r.getValue(MetricType.CYCLING_SPEED), 1e-6) // 2 revolutions in 1 s of 1/2048 ticks
    }

    @Test fun aNegativePowerIsNoiseAndBecomesZero() {
        assertEquals(0.0, CyclingPowerAdapter.run("2a63", b(0x00, 0x00, *u16(0xFFF6))).getValue(MetricType.POWER_WATTS), 0.0)
    }

    @Test fun powerTruncatedIsRejected() {
        assertTrue(CyclingPowerAdapter.decode("2a63", b(0x00, 0x00), SourceState(), 0).isEmpty())
        assertTrue(CyclingPowerAdapter.decode("2a63", b(0x20, 0x00, *u16(100), 1, 0), SourceState(), 0).isEmpty())
    }

    // ---- fitness machine ----

    @Test fun treadmillSpeedDistanceInclineEnergyAndHeartRate() {
        // flags: distance (bit 2) + inclination (bit 3) + energy (bit 7) + heart rate (bit 8) = 0x018C; speed present (bit 0 = 0)
        val bytes = b(0x8C, 0x01, *u16(1000), 0xE8, 0x03, 0x00, *u16(25), *u16(0), *u16(120), *u16(700), 12, 150)
        val r = FitnessMachineAdapter.run("2acd", bytes)
        assertEquals(10.0 / 3.6, r.getValue(MetricType.RUNNING_SPEED), 1e-9) // 10.00 km/h
        assertEquals(1000.0, r.getValue(MetricType.TOTAL_DISTANCE), 0.0)
        assertEquals(2.5, r.getValue(MetricType.INCLINE), 1e-9)
        assertEquals(120.0, r.getValue(MetricType.ENERGY_KCAL), 0.0)
        assertEquals(150.0, r.getValue(MetricType.HEART_RATE), 0.0)
        assertEquals(MeasurementKind.CUMULATIVE, FitnessMachineAdapter.kinds("2acd", bytes).getValue(MetricType.TOTAL_DISTANCE))
    }

    @Test fun treadmillMoreDataBitMeansTheSpeedIsAbsent() {
        val r = FitnessMachineAdapter.run("2acd", b(0x01, 0x00))
        assertTrue(r.isEmpty())
    }

    @Test fun treadmillEnergyNotAvailableIsNotAValue() {
        val r = FitnessMachineAdapter.run("2acd", b(0x80, 0x00, *u16(500), *u16(0xFFFF), *u16(0xFFFF), 0xFF))
        assertTrue(MetricType.ENERGY_KCAL !in r)
    }

    @Test fun indoorBikeSpeedCadencePowerAndHeartRate() {
        // flags: cadence (bit 2) + distance (bit 4) + power (bit 6) + heart rate (bit 9) = 0x0254
        val bytes = b(0x54, 0x02, *u16(3000), *u16(170), 0xD0, 0x07, 0x00, *u16(250), 140)
        val r = FitnessMachineAdapter.run("2ad2", bytes)
        assertEquals(30.0 / 3.6, r.getValue(MetricType.CYCLING_SPEED), 1e-9)
        assertEquals(85.0, r.getValue(MetricType.CYCLING_CADENCE), 0.0) // 170 x 0.5
        assertEquals(2000.0, r.getValue(MetricType.TOTAL_DISTANCE), 0.0)
        assertEquals(250.0, r.getValue(MetricType.POWER_WATTS), 0.0)
        assertEquals(140.0, r.getValue(MetricType.HEART_RATE), 0.0)
    }

    @Test fun rowerStrokeRateStrokeCountPowerAndDistance() {
        // flags: distance (bit 2) + power (bit 5) = 0x0024; stroke rate 0.5/min, stroke count
        val r = FitnessMachineAdapter.run("2ad1", b(0x24, 0x00, 56, *u16(120), 0xF4, 0x01, 0x00, *u16(180)))
        assertEquals(28.0, r.getValue(MetricType.STROKE_RATE), 0.0)
        assertEquals(120.0, r.getValue(MetricType.STROKE_COUNT), 0.0)
        assertEquals(500.0, r.getValue(MetricType.TOTAL_DISTANCE), 0.0)
        assertEquals(180.0, r.getValue(MetricType.POWER_WATTS), 0.0)
    }

    @Test fun crossTrainerStepRateAndPower() {
        // 3-byte flags: speed absent flag 0 => present; step count (bit 3) + power (bit 8)
        val r = FitnessMachineAdapter.run("2ace", b(0x08, 0x01, 0x00, *u16(900), *u16(60), *u16(58), *u16(200)))
        assertEquals(60.0, r.getValue(MetricType.STEP_RATE), 0.0)
        assertEquals(200.0, r.getValue(MetricType.POWER_WATTS), 0.0)
    }

    @Test fun stairAndStepClimbersGiveFloorsAndStepRate() {
        val stair = FitnessMachineAdapter.run("2ad0", b(0x02, 0x00, *u16(12), *u16(70)))
        assertEquals(12.0, stair.getValue(MetricType.FLOORS), 0.0)
        assertEquals(70.0, stair.getValue(MetricType.STEP_RATE), 0.0)
        val step = FitnessMachineAdapter.run("2acf", b(0x02, 0x00, *u16(8), *u16(100), *u16(65)))
        assertEquals(8.0, step.getValue(MetricType.FLOORS), 0.0)
        assertEquals(65.0, step.getValue(MetricType.STEP_RATE), 0.0)
    }

    @Test fun fitnessMachineTruncatedOrUnknownIsRejected() {
        assertTrue(FitnessMachineAdapter.decode("2acd", b(0x04, 0x00, *u16(100)), SourceState(), 0).isEmpty()) // distance cut
        assertTrue(FitnessMachineAdapter.decode("2ad2", b(), SourceState(), 0).isEmpty())
        assertTrue(FitnessMachineAdapter.decode("2adf", b(0, 0, 0, 0), SourceState(), 0).isEmpty())
        assertTrue(FitnessMachineAdapter.decode("2acd", b(0x00, 0x00, 0xFF, 0xFF), SourceState(), 0).isEmpty()) // 655 km/h
    }

    // ---- battery and device information ----

    @Test fun batteryLevel() {
        val e = BatteryAdapter.decode("2a19", b(82), SourceState(), 0).single() as SensorEvent.Battery
        assertEquals(82, e.percent)
        assertTrue(BatteryAdapter.decode("2a19", b(101), SourceState(), 0).isEmpty())
        assertTrue(BatteryAdapter.decode("2a19", b(), SourceState(), 0).isEmpty())
    }

    @Test fun deviceInformationStrings() {
        val e = DeviceInformationAdapter.decode("2a29", "Polar Electro Oy\u0000".encodeToByteArray(), SourceState(), 0).single() as SensorEvent.DeviceInfo
        assertEquals(DeviceInfoField.MANUFACTURER, e.field)
        assertEquals("Polar Electro Oy", e.value)
        assertEquals(DeviceInfoField.FIRMWARE, (DeviceInformationAdapter.decode("2a26", "1.0.5".encodeToByteArray(), SourceState(), 0).single() as SensorEvent.DeviceInfo).field)
        assertTrue(DeviceInformationAdapter.decode("2a29", b(), SourceState(), 0).isEmpty())
        assertTrue(DeviceInformationAdapter.decode("2a25", "serial".encodeToByteArray(), SourceState(), 0).isEmpty(), "the serial number is not read")
    }

    // ---- the registry ----

    @Test fun theRegistryDrivesScanSubscribeReadAndForward() {
        assertEquals(listOf("180d", "1814", "1816", "1818", "1826"), ProtocolRegistry.scanServices())
        assertTrue("2a19" in ProtocolRegistry.readCharacteristics())
        assertTrue("2a29" in ProtocolRegistry.readCharacteristics())
        assertTrue("2a5b" in ProtocolRegistry.notifyCharacteristics())
        assertEquals(setOf("2a5b"), ProtocolRegistry.rawForwarded())
        assertEquals(Capability.CYCLING_POWER, ProtocolRegistry.adapterFor("00002A63-0000-1000-8000-00805F9B34FB")!!.capability)
        assertTrue(ProtocolRegistry.adapterFor("2a99") == null)
        assertTrue(ProtocolRegistry.isUseful("2ad1"))
    }

    // ---- counter rate ----

    @Test fun counterRateRejectsAJumpThatTimeCannotExplain() {
        val c = CounterRate.crank()
        c.onSample(100, 1000, 0)
        c.onSample(101, 1768, 750)
        assertEquals(CounterRate.UNKNOWN, c.onSample(3, 2536, 1500)) // a reset sensor
        assertEquals(CounterRate.UNKNOWN, c.rate(1500).let { if (it < 0) CounterRate.UNKNOWN else it })
    }

    @Test fun counterRateNeverInventsARateAfterALongCoast() {
        val c = CounterRate.crank()
        c.onSample(100, 1000, 0)
        c.onSample(101, 1768, 750)
        var t = 750L
        while (t < 66_750) { t += 1000; c.onSample(101, 1768, t) }
        assertEquals(CounterRate.UNKNOWN, c.onSample(102, (1768 + 67584) and 0xFFFF, t + 500))
    }

    @Test fun counterRateSilenceIsUnknownNotZero() {
        val c = CounterRate.crank()
        c.onSample(100, 1000, 0)
        c.onSample(101, 1768, 750)
        assertTrue(c.rate(2000) > 0)
        assertEquals(CounterRate.UNKNOWN, c.rate(7000))
    }
}
