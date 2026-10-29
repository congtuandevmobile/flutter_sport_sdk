package sensor

import sensor.model.Capability
import sensor.model.MeasurementKind
import sensor.model.MetricType
import sensor.model.SensorReading
import sensor.resolver.MetricResolver
import sensor.resolver.SensorHub
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class HubTest {
    private fun b(vararg v: Int) = ByteArray(v.size) { v[it].toByte() }
    private fun u16(v: Int) = intArrayOf(v and 0xFF, (v shr 8) and 0xFF)
    private fun hr(v: Double) = SensorReading(MetricType.HEART_RATE, v, MeasurementKind.INSTANTANEOUS)

    private fun SensorHub.metric(m: MetricType, now: Long) = resolve(now).firstOrNull { it.metric == m }

    @Test fun theSameEpochComingBackMustEarnItsPlaceAgain() {
        val r = MetricResolver()
        r.onConnection("strap", 1, true)
        r.onReading("strap", 1, hr(145.0), 0)
        r.onReading("strap", 1, hr(146.0), 1000)
        assertEquals(146.0, r.resolve(1000).single().value, 0.0)
        r.onConnection("strap", 1, false)
        r.onConnection("strap", 1, true) // an adapter that forgot to bump the epoch
        assertTrue(r.resolve(1100).isEmpty(), "nothing of the old link survives")
        r.onReading("strap", 1, hr(150.0), 1200)
        assertTrue(r.resolve(1200).isEmpty(), "one value is not enough")
    }

    @Test fun aHeartRateSensorBeatsAMachineThatConnectedFirst() {
        val h = SensorHub()
        h.onConnection("treadmill", 1, true)
        h.setCapabilities("treadmill", listOf(Capability.FITNESS_MACHINE))
        h.onConnection("strap", 1, true)
        h.setCapabilities("strap", listOf(Capability.HEART_RATE))
        // the treadmill reports heart rate through its machine data (flags: heart rate bit 8)
        for (t in listOf(0L, 1000L)) {
            h.onPacket("treadmill", 1, "2acd", b(0x00, 0x01, *u16(1000), 140), t)
            h.onPacket("strap", 1, "2a37", b(0x00, 143), t)
        }
        val v = h.metric(MetricType.HEART_RATE, 1000)!!
        assertEquals("strap", v.sourceId)
        assertEquals(143.0, v.value, 0.0)
    }

    @Test fun aBetterRankedSourceTakesOverOnceAndDoesNotAlternate() {
        val h = SensorHub()
        h.onConnection("treadmill", 1, true)
        h.setCapabilities("treadmill", listOf(Capability.FITNESS_MACHINE))
        for (t in listOf(0L, 1000L)) h.onPacket("treadmill", 1, "2acd", b(0x00, 0x01, *u16(1000), 140), t)
        assertEquals("treadmill", h.metric(MetricType.HEART_RATE, 1000)!!.sourceId)
        h.onConnection("strap", 1, true)
        h.setCapabilities("strap", listOf(Capability.HEART_RATE))
        var switches = 0
        var last = "treadmill"
        var t = 1000L
        while (t < 20_000) {
            t += 1000
            h.onPacket("strap", 1, "2a37", b(0x00, 143), t)
            h.onPacket("treadmill", 1, "2acd", b(0x00, 0x01, *u16(1000), 140), t)
            val s = h.metric(MetricType.HEART_RATE, t)!!.sourceId
            if (s != last) { switches++; last = s }
        }
        assertEquals(1, switches)
        assertEquals("strap", last)
    }

    @Test fun thePowerMetersCadenceBeatsTheCadenceSensor() {
        val h = SensorHub()
        h.onConnection("csc", 1, true); h.setCapabilities("csc", listOf(Capability.CYCLING_SPEED_CADENCE))
        h.onConnection("power", 1, true); h.setCapabilities("power", listOf(Capability.CYCLING_POWER))
        var count = 100
        var ticks = 1000
        for (i in 0..4) {
            val t = i * 750L
            h.onPacket("csc", 1, "2a5b", b(0x02, *u16(count), *u16(ticks)), t)
            h.onPacket("power", 1, "2a63", b(0x20, 0x00, *u16(200), *u16(count), *u16(ticks)), t)
            count += 1; ticks += 768
        }
        val cadence = h.metric(MetricType.CYCLING_CADENCE, 3000)!!
        assertEquals("power", cadence.sourceId)
        assertEquals(80.0, cadence.value, 0.001)
    }

    @Test fun aZeroFromTheCadenceSensorIsKeptNotReplacedByAnotherSource() {
        val h = SensorHub()
        h.onConnection("csc", 1, true); h.setCapabilities("csc", listOf(Capability.CYCLING_SPEED_CADENCE))
        h.onPacket("csc", 1, "2a5b", b(0x02, *u16(100), *u16(1000)), 0)
        h.onPacket("csc", 1, "2a5b", b(0x02, *u16(101), *u16(1768)), 750)
        var t = 750L
        while (t < 6_000) { t += 1000; h.onPacket("csc", 1, "2a5b", b(0x02, *u16(101), *u16(1768)), t) }
        val v = h.metric(MetricType.CYCLING_CADENCE, t)!!
        assertEquals(0.0, v.value, 0.0)
    }

    @Test fun deviceDetailsKeepRrBatteryAndInformation() {
        val h = SensorHub()
        h.onConnection("strap", 1, true)
        h.onPacket("strap", 1, "2a37", b(0x16, 70, 0x00, 0x04, 0x00, 0x02), 0)
        h.onPacket("strap", 1, "2a19", b(82), 0)
        h.onPacket("strap", 1, "2a29", "Polar".encodeToByteArray(), 0)
        h.onPacket("strap", 1, "2a24", "H10".encodeToByteArray(), 0)
        h.onPacket("strap", 1, "2a26", "3.0.35".encodeToByteArray(), 0)
        val d = h.details("strap")
        assertEquals(listOf(1000, 500), d.recentRrMs)
        assertEquals(82, d.batteryPercent)
        assertEquals("Polar", d.manufacturer)
        assertEquals("H10", d.model)
        assertEquals("3.0.35", d.firmware)
        assertNull(h.details("ghost").batteryPercent)
    }

    @Test fun aNewConnectionStartsWithEmptyDecodersAndNoOldBattery() {
        val h = SensorHub()
        h.onConnection("bike", 1, true)
        h.onPacket("bike", 1, "2a5b", b(0x02, *u16(65000), *u16(45000)), 0)
        h.onPacket("bike", 1, "2a19", b(50), 0)
        h.onConnection("bike", 2, true)
        assertNull(h.details("bike").batteryPercent)
        // the counters of connection 2 are not compared with those of connection 1
        assertEquals(0, h.onPacket("bike", 2, "2a5b", b(0x02, *u16(5), *u16(1200)), 750))
        assertEquals(0, h.onPacket("bike", 1, "2a19", b(40), 800), "an older epoch is dropped")
    }

    @Test fun wheelSpeedNeedsAnExplicitCircumference() {
        val h = SensorHub()
        h.onConnection("wheel", 1, true)
        h.setWheelCircumference("wheel", 2.1)
        h.setWheelCircumference("wheel", 9.0) // out of range: cleared
        fun w(count: Int, ticks: Int) = b(0x01, count and 0xFF, 0, 0, 0, *u16(ticks))
        for ((i, c) in listOf(1000, 1002, 1004).withIndex()) h.onPacket("wheel", 1, "2a5b", w(c, i * 1024), i * 1000L)
        assertNull(h.metric(MetricType.CYCLING_SPEED, 2000))
        assertNotNull(h.metric(MetricType.WHEEL_REVOLUTIONS, 2000))
        h.setWheelCircumference("wheel", 2.1)
        for ((i, c) in listOf(1004, 1006, 1008).withIndex()) h.onPacket("wheel", 1, "2a5b", w(c, (i + 3) * 1024), (i + 3) * 1000L)
        assertEquals(4.2, h.metric(MetricType.CYCLING_SPEED, 5000)!!.value, 1e-6)
    }

    @Test fun anIndoorMachineGivesTheMetricsOfItsType() {
        val h = SensorHub()
        h.onConnection("rower", 1, true)
        h.setCapabilities("rower", listOf(Capability.FITNESS_MACHINE))
        for (t in listOf(0L, 1000L)) h.onPacket("rower", 1, "2ad1", b(0x24, 0x00, 56, *u16(120), 0xF4, 0x01, 0x00, *u16(180)), t)
        val all = h.resolve(1000).associateBy { it.metric }
        assertEquals(28.0, all.getValue(MetricType.STROKE_RATE).value, 0.0)
        assertEquals(180.0, all.getValue(MetricType.POWER_WATTS).value, 0.0)
        assertEquals(MeasurementKind.CUMULATIVE, all.getValue(MetricType.STROKE_COUNT).kind)
    }
}
