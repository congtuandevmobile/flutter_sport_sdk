package sensor

import sensor.model.Capability
import sensor.model.MetricType
import sensor.resolver.SensorHub
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class DeviceValuesTest {
    private fun b(vararg v: Int) = ByteArray(v.size) { v[it].toByte() }
    private fun u16(v: Int) = intArrayOf(v and 0xFF, (v shr 8) and 0xFF)

    @Test fun everyDeviceKeepsItsOwnTotalDistanceWhileOnlyOneIsResolved() {
        val h = SensorHub()
        h.onConnection("foot", 1, true); h.setCapabilities("foot", listOf(Capability.RUNNING_SPEED_CADENCE))
        h.onConnection("rower", 4, true); h.setCapabilities("rower", listOf(Capability.FITNESS_MACHINE))
        for (t in listOf(0L, 1000L)) {
            // RSC with total distance 1500.0 m (0x3A98 x 0.1 -> 15000 = 0x3A98 -> 1500.0)
            h.onPacket("foot", 1, "2a53", b(0x02, 0x00, 0x01, 100, 0x98, 0x3A, 0x00, 0x00), t)
            // rower data: distance 850 m (bit 2) at flags 0x0004, stroke fields present
            h.onPacket("rower", 4, "2ad1", b(0x04, 0x00, 56, *u16(120), 0x52, 0x03, 0x00), t)
        }
        val resolved = h.resolve(1000).filter { it.metric == MetricType.TOTAL_DISTANCE }
        assertEquals(1, resolved.size, "the resolver chooses one source")
        val all = h.deviceValues(1000).filter { it.metric == MetricType.TOTAL_DISTANCE }.associateBy { it.sourceId }
        assertEquals(setOf("foot", "rower"), all.keys, "but each device's own counter is still there")
        assertEquals(1500.0, all.getValue("foot").value, 1e-9)
        assertEquals(850.0, all.getValue("rower").value, 1e-9)
        assertEquals(1L, all.getValue("foot").epoch)
        assertEquals(4L, all.getValue("rower").epoch)
        assertEquals(0L, all.getValue("foot").ageMs)
    }

    @Test fun aDisconnectedDeviceHasNoValuesAndAgeIsReported() {
        val h = SensorHub()
        h.onConnection("strap", 1, true)
        h.onPacket("strap", 1, "2a37", b(0x00, 145), 0)
        assertEquals(3000L, h.deviceValues(3000).single().ageMs, "a value that is not fresh is still listed with its age")
        h.onConnection("strap", 1, false)
        assertTrue(h.deviceValues(3000).isEmpty())
    }
}
