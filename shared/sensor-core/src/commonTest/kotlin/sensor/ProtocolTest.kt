package sensor

import sensor.model.Capability
import sensor.model.MeasurementKind
import sensor.model.MetricType
import sensor.protocol.Gatt
import sensor.protocol.HeartRateParser
import sensor.protocol.RunningSpeedCadenceParser
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class ProtocolTest {
    private fun b(vararg v: Int) = ByteArray(v.size) { v[it].toByte() }

    // ---- heart rate ----

    @Test fun heartRateEightBit() {
        val m = assertNotNull(HeartRateParser.parse(b(0x00, 0x91)))
        assertEquals(145, m.bpm)
        assertNull(m.energyKj)
        assertTrue(m.rrIntervalsMs.isEmpty())
    }

    @Test fun heartRateSixteenBit() {
        assertEquals(300, assertNotNull(HeartRateParser.parse(b(0x01, 0x2C, 0x01))).bpm)
        assertEquals(172, assertNotNull(HeartRateParser.parse(b(0x01, 0xAC, 0x00))).bpm)
    }

    @Test fun heartRateWithContactEnergyAndRrIntervals() {
        // flags: contact detected (bits 1-2 = 3), energy present, rr present; hr 60; energy 0x0102; rr 1024 and 512 (1000 ms, 500 ms)
        val m = assertNotNull(HeartRateParser.parse(b(0x1E, 60, 0x02, 0x01, 0x00, 0x04, 0x00, 0x02)))
        assertEquals(60, m.bpm)
        assertEquals(0x0102, m.energyKj)
        assertEquals(listOf(1000, 500), m.rrIntervalsMs)
    }

    @Test fun noSkinContactMeansNoValue() {
        val m = assertNotNull(HeartRateParser.parse(b(0x04, 80))) // contact supported (bit 2 only = value 2) but not detected
        assertTrue(m.contactLost)
        assertNull(m.bpm)
        assertTrue(HeartRateParser.readings(b(0x04, 80)).isEmpty())
    }

    @Test fun zeroAndImpossibleHeartRatesAreNotReadings() {
        assertTrue(HeartRateParser.readings(b(0x00, 0)).isEmpty())
        assertTrue(HeartRateParser.readings(b(0x01, 0x2D, 0x01)).isEmpty()) // 301
    }

    @Test fun truncatedHeartRatePacketsAreRejected() {
        assertNull(HeartRateParser.parse(b()))
        assertNull(HeartRateParser.parse(b(0x00)))
        assertNull(HeartRateParser.parse(b(0x01, 0x91)))
        assertNull(HeartRateParser.parse(b(0x08, 70, 0x01)))
        assertNull(HeartRateParser.parse(b(0x10, 70, 0x01))) // an R-R interval cut in half
    }

    @Test fun heartRateReadingIsInstantaneous() {
        val r = HeartRateParser.readings(b(0x00, 0x91)).single()
        assertEquals(MetricType.HEART_RATE, r.metric)
        assertEquals(145.0, r.value, 0.0)
        assertEquals(MeasurementKind.INSTANTANEOUS, r.kind)
    }

    // ---- running speed and cadence ----

    @Test fun rscSpeedAndCadenceOnly() {
        // speed 0x02D0 = 720 / 256 = 2.8125 m/s, cadence 170
        val m = assertNotNull(RunningSpeedCadenceParser.parse(b(0x04, 0xD0, 0x02, 170)))
        assertEquals(2.8125, m.speedMps, 1e-9)
        assertEquals(170, m.cadencePerMin)
        assertTrue(m.isRunning)
        assertNull(m.strideLengthM)
        assertNull(m.totalDistanceM)
    }

    @Test fun rscWithStrideAndTotalDistance() {
        // stride 0x0063 = 99 -> 0.99 m; total 0x00009C40 = 40000 -> 4000.0 m
        val bytes = b(0x07, 0xD0, 0x02, 170, 0x63, 0x00, 0x40, 0x9C, 0x00, 0x00)
        val readings = RunningSpeedCadenceParser.readings(bytes)
        assertEquals(4, readings.size)
        val byMetric = readings.associateBy { it.metric }
        assertEquals(0.99, byMetric.getValue(MetricType.RUNNING_STRIDE_LENGTH).value, 1e-9)
        val distance = byMetric.getValue(MetricType.TOTAL_DISTANCE)
        assertEquals(4000.0, distance.value, 1e-9)
        assertEquals(MeasurementKind.CUMULATIVE, distance.kind)
    }

    @Test fun rscDistanceWithoutStride() {
        val m = assertNotNull(RunningSpeedCadenceParser.parse(b(0x02, 0x00, 0x01, 100, 0x0A, 0x00, 0x00, 0x00)))
        assertEquals(1.0, m.totalDistanceM!!, 1e-9)
        assertNull(m.strideLengthM)
    }

    @Test fun rscRejectsTruncatedAndImpossibleSpeed() {
        assertNull(RunningSpeedCadenceParser.parse(b(0x00, 0x00, 0x01)))
        assertNull(RunningSpeedCadenceParser.parse(b(0x01, 0x00, 0x01, 100, 0x63)))
        assertNull(RunningSpeedCadenceParser.parse(b(0x02, 0x00, 0x01, 100, 0x0A, 0x00)))
        assertNull(RunningSpeedCadenceParser.parse(b(0x00, 0x00, 0x10, 100))) // 4096 / 256 = 16 m/s
    }

    @Test fun rscStandingStillIsAValidZero() {
        val readings = RunningSpeedCadenceParser.readings(b(0x00, 0x00, 0x00, 0))
        assertEquals(listOf(0.0, 0.0), readings.map { it.value })
    }

    // ---- GATT numbers ----

    @Test fun uuidsAreShortened() {
        assertEquals("180d", Gatt.short("0000180D-0000-1000-8000-00805F9B34FB"))
        assertEquals("2a37", Gatt.short("0x2A37"))
        assertEquals("180d", Gatt.short("180D"))
        assertEquals("6e400001-b5a3-f393-e0a9-e50e24dcca9e", Gatt.short("6E400001-B5A3-F393-E0A9-E50E24DCCA9E"))
    }

    @Test fun capabilitiesComeFromTheServices() {
        val caps = Gatt.capabilities(listOf("0000180D-0000-1000-8000-00805F9B34FB", "1814", "1814", "dead"))
        assertEquals(listOf(Capability.HEART_RATE, Capability.RUNNING_SPEED_CADENCE), caps)
        assertEquals(listOf("2a37"), Gatt.measurementCharacteristics("180d"))
        assertTrue(Gatt.measurementCharacteristics("180f").isEmpty())
    }
}
