package sensor

import sensor.model.MeasurementKind
import sensor.model.MetricType
import sensor.model.SensorReading
import sensor.resolver.MetricResolver
import sensor.resolver.MetricResolverConfig
import sensor.resolver.SensorHub
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class ResolverTest {
    private fun hr(v: Double) = SensorReading(MetricType.HEART_RATE, v, MeasurementKind.INSTANTANEOUS)
    private fun cad(v: Double) = SensorReading(MetricType.RUNNING_CADENCE, v, MeasurementKind.INSTANTANEOUS)

    private fun MetricResolver.healthy(id: String, epoch: Long, r: SensorReading, from: Long = 0) {
        onConnection(id, epoch, true)
        onReading(id, epoch, r, from)
        onReading(id, epoch, r, from + 1000)
    }

    private fun MetricResolver.value(metric: MetricType, now: Long) = resolve(now).firstOrNull { it.metric == metric }

    @Test fun aSourceNeedsTwoValuesOverASecondBeforeItIsUsed() {
        val r = MetricResolver()
        r.onConnection("strap", 1, true)
        r.onReading("strap", 1, hr(145.0), 0)
        assertNull(r.value(MetricType.HEART_RATE, 0))
        r.onReading("strap", 1, hr(146.0), 400)
        assertNull(r.value(MetricType.HEART_RATE, 400))
        r.onReading("strap", 1, hr(147.0), 1000)
        val v = r.value(MetricType.HEART_RATE, 1000)!!
        assertEquals(147.0, v.value, 0.0)
        assertEquals("strap", v.sourceId)
        assertEquals(0L, v.ageMs)
    }

    @Test fun eachMetricHasItsOwnSource() {
        val r = MetricResolver()
        r.healthy("strap", 1, hr(145.0))
        r.healthy("footpod", 1, cad(170.0))
        val all = r.resolve(1000)
        assertEquals("strap", all.first { it.metric == MetricType.HEART_RATE }.sourceId)
        assertEquals("footpod", all.first { it.metric == MetricType.RUNNING_CADENCE }.sourceId)
    }

    @Test fun twoSourcesOfOneMetricAreNeverMixedAndTheFirstConnectedWins() {
        val r = MetricResolver()
        r.healthy("strap", 1, hr(145.0))
        r.healthy("watch", 1, hr(141.0))
        val v = r.value(MetricType.HEART_RATE, 1000)!!
        assertEquals("strap", v.sourceId)
        assertEquals(145.0, v.value, 0.0)
    }

    @Test fun theChosenSourceIsKeptWhileItIsHealthy() {
        val r = MetricResolver()
        r.healthy("watch", 1, hr(141.0))
        r.value(MetricType.HEART_RATE, 1000)
        r.healthy("strap", 1, hr(145.0), 1000)
        // a better-ranked source joining later does not take over a healthy one
        assertEquals("watch", r.value(MetricType.HEART_RATE, 2000)!!.sourceId)
    }

    @Test fun theUserPreferenceWinsWhileThatSourceIsACandidate() {
        val r = MetricResolver()
        r.healthy("strap", 1, hr(145.0))
        r.healthy("watch", 1, hr(141.0))
        r.setPreferred(MetricType.HEART_RATE, "watch")
        assertEquals("watch", r.value(MetricType.HEART_RATE, 1000)!!.sourceId)
        r.onConnection("watch", 1, false)
        assertEquals("strap", r.value(MetricType.HEART_RATE, 1000)!!.sourceId)
        r.setPreferred(MetricType.HEART_RATE, null)
    }

    @Test fun aLostSourceFallsBackAtOnceAndMustEarnItsPlaceAgain() {
        val r = MetricResolver()
        r.healthy("strap", 1, hr(145.0))
        r.healthy("watch", 1, hr(141.0))
        r.value(MetricType.HEART_RATE, 1000)
        r.onConnection("strap", 1, false)
        assertEquals("watch", r.value(MetricType.HEART_RATE, 1100)!!.sourceId)
        r.onConnection("strap", 2, true) // reconnected: a new epoch
        r.onReading("strap", 2, hr(150.0), 2000)
        r.onReading("watch", 1, hr(142.0), 2000)
        assertEquals("watch", r.value(MetricType.HEART_RATE, 2000)!!.sourceId)
    }

    @Test fun silenceMakesAMetricUnknownNeverAStaleValue() {
        val r = MetricResolver()
        r.healthy("strap", 1, hr(145.0))
        assertEquals(145.0, r.value(MetricType.HEART_RATE, 5500)!!.value, 0.0)
        assertNull(r.value(MetricType.HEART_RATE, 6100))
        assertNull(r.value(MetricType.HEART_RATE, 60_000))
    }

    @Test fun aStaleSourceFallsBackToAnotherFreshOne() {
        val r = MetricResolver()
        r.healthy("strap", 1, hr(145.0))
        r.healthy("watch", 1, hr(141.0))
        r.onReading("watch", 1, hr(142.0), 6000)
        r.onReading("watch", 1, hr(143.0), 7000)
        val v = r.value(MetricType.HEART_RATE, 7000)!!
        assertEquals("watch", v.sourceId)
        assertEquals(143.0, v.value, 0.0)
    }

    @Test fun aSpellWithoutDataMakesASourceEarnItsPlaceAgain() {
        val r = MetricResolver()
        r.healthy("strap", 1, hr(145.0))
        r.onReading("strap", 1, hr(150.0), 9000) // after a gap: one value is not enough
        assertNull(r.value(MetricType.HEART_RATE, 9000))
        r.onReading("strap", 1, hr(151.0), 10_000)
        assertEquals(151.0, r.value(MetricType.HEART_RATE, 10_000)!!.value, 0.0)
    }

    @Test fun zeroIsAValueAndWinsOverAFallback() {
        val r = MetricResolver()
        r.healthy("footpod", 1, cad(0.0))
        r.healthy("phone", 1, cad(168.0))
        val v = r.value(MetricType.RUNNING_CADENCE, 1000)!!
        assertEquals("footpod", v.sourceId)
        assertEquals(0.0, v.value, 0.0)
    }

    @Test fun anOlderEpochIsDroppedAndANewerOneForgetsTheOldValues() {
        val r = MetricResolver()
        r.healthy("strap", 2, hr(145.0))
        assertFalse(r.onConnection("strap", 1, false))
        assertFalse(r.onReading("strap", 1, hr(100.0), 1500))
        assertEquals(145.0, r.value(MetricType.HEART_RATE, 1500)!!.value, 0.0)
        r.onConnection("strap", 3, true)
        assertNull(r.value(MetricType.HEART_RATE, 1600))
    }

    @Test fun readingsOfADisconnectedOrUnknownSourceAreDropped() {
        val r = MetricResolver()
        assertFalse(r.onReading("ghost", 1, hr(100.0), 0))
        r.onConnection("strap", 1, false)
        assertFalse(r.onReading("strap", 1, hr(100.0), 0))
        r.onConnection("strap", 1, true)
        assertFalse(r.onReading("strap", 1, hr(Double.NaN), 0))
    }

    @Test fun forgettingADeviceRemovesItAndItsPreference() {
        val r = MetricResolver()
        r.healthy("strap", 1, hr(145.0))
        r.setPreferred(MetricType.HEART_RATE, "strap")
        r.forget("strap")
        assertNull(r.value(MetricType.HEART_RATE, 1000))
    }

    @Test fun refusesAnImpossibleConfiguration() {
        assertFailsWith<IllegalArgumentException> { MetricResolverConfig(recoveryMinSamples = 0) }
        assertFailsWith<IllegalArgumentException> { MetricResolverConfig(staleAfterMs = 0) }
    }

    // ---- the hub, from raw packets ----

    private fun b(vararg v: Int) = ByteArray(v.size) { v[it].toByte() }

    @Test fun hubDecodesAndResolvesRawPackets() {
        val h = SensorHub()
        h.onConnection("strap", 1, true)
        h.onConnection("footpod", 1, true)
        assertEquals(1, h.onPacket("strap", 1, "00002a37-0000-1000-8000-00805f9b34fb", b(0x00, 145), 0))
        assertEquals(1, h.onPacket("strap", 1, "2A37", b(0x00, 146), 1000))
        assertEquals(2, h.onPacket("footpod", 1, "2a53", b(0x00, 0xD0, 0x02, 170), 0))
        assertEquals(2, h.onPacket("footpod", 1, "2a53", b(0x00, 0xD0, 0x02, 171), 1000))
        val all = h.resolve(1000).associateBy { it.metric }
        assertEquals(146.0, all.getValue(MetricType.HEART_RATE).value, 0.0)
        assertEquals(171.0, all.getValue(MetricType.RUNNING_CADENCE).value, 0.0)
        assertEquals(2.8125, all.getValue(MetricType.RUNNING_SPEED).value, 1e-9)
    }

    @Test fun hubIgnoresWhatItDoesNotDecodeAndWhatIsMalformed() {
        val h = SensorHub()
        h.onConnection("bike", 1, true)
        assertEquals(0, h.onPacket("bike", 1, "2a5b", b(0x02, 1, 0, 1, 0), 0)) // CSC is forwarded elsewhere
        assertEquals(0, h.onPacket("bike", 1, "2a37", b(0x01, 0x91), 0)) // truncated
        assertEquals(0, h.onPacket("bike", 1, "2a37", b(0x00, 0), 0)) // no value
        assertEquals(0, h.onPacket("bike", 9, "2a37", b(0x00, 100), 0)) // another epoch
        assertTrue(h.resolve(0).isEmpty())
    }

    @Test fun hubResetForgetsEverything() {
        val h = SensorHub()
        h.onConnection("strap", 1, true)
        h.onPacket("strap", 1, "2a37", b(0x00, 145), 0)
        h.onPacket("strap", 1, "2a37", b(0x00, 146), 1000)
        h.reset()
        assertTrue(h.resolve(1000).isEmpty())
    }
}
