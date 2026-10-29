package io.github.congtuandevmobile.flutter_sport_ble

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

private class FakeTransport : BleTransport {
    override var listener: BleTransport.Listener? = null
    var state = NativeAdapterState.READY
    val connects = mutableListOf<String>()
    val disconnects = mutableListOf<String>()
    var scans = 0
    var scanStops = 0
    override fun adapterState() = state
    override fun startScan(serviceShortIds: List<String>) { scans += 1 }
    override fun stopScan() { scanStops += 1 }
    override fun connect(deviceId: String, measurementShortIds: List<String>) { connects += deviceId }
    override fun disconnect(deviceId: String) { disconnects += deviceId }
}

private class RecordingSink : SportBleSink {
    val devices = mutableListOf<NativeBleDevice>()
    val snapshots = mutableListOf<NativeSensorSnapshot>()
    val raw = mutableListOf<NativeRawPacket>()
    var scanStopped = 0
    override fun onDeviceFound(device: NativeBleDevice) { devices += device }
    override fun onScanStopped() { scanStopped += 1 }
    override fun onSnapshot(snapshot: NativeSensorSnapshot) { snapshots += snapshot }
    override fun onRawPacket(packet: NativeRawPacket) { raw += packet }
}

@OptIn(ExperimentalCoroutinesApi::class)
class SportBleEngineTest {
    private var clock = 0L
    private val transport = FakeTransport()
    private val sink = RecordingSink()

    private fun TestScope.engine() = SportBleEngine(
        transport = transport, scope = CoroutineScope(testScheduler.let { kotlinx.coroutines.test.StandardTestDispatcher(it) }),
        monotonicMs = { clock }, sink = sink,
    )

    private fun b(vararg v: Int) = ByteArray(v.size) { v[it].toByte() }

    private fun SportBleEngine.link(id: String, services: List<String>): Result<Unit>? {
        var result: Result<Unit>? = null
        connect(id) { result = it }
        onConnected(id, "dev-$id", services)
        return result
    }

    private fun SportBleEngine.hr(id: String, bpm: Int, at: Long) {
        clock = at
        onNotification(id, "2a37", b(0x00, bpm))
    }

    private fun NativeSensorSnapshot.metric(m: NativeMetric) = metrics.firstOrNull { it.metric == m }

    @Test
    fun scanForwardsDevicesWithTheirCapabilities() = runTest {
        val e = engine()
        e.startScan(10_000)
        transport.listener!!.onDeviceFound("A", "Strap", -60, listOf("180d", "180f"))
        val d = sink.devices.single()
        assertEquals("A", d.id)
        assertEquals(listOf(NativeCapability.HEART_RATE, NativeCapability.BATTERY), d.capabilities)
        assertEquals(1, transport.scans)
    }

    @Test
    fun aScanStopsByItselfAfterItsTimeout() = runTest {
        val e = engine()
        e.startScan(5_000)
        advanceTimeBy(5_001)
        assertEquals(1, transport.scanStops)
        assertEquals(1, sink.scanStopped)
    }

    @Test
    fun connectCompletesWhenTheLinkIsUpAndTheStateSaysSo() = runTest {
        val e = engine()
        assertTrue(e.link("A", listOf("180d"))!!.isSuccess)
        assertEquals(listOf("A"), transport.connects)
        val state = e.snapshot().devices.single()
        assertEquals(NativeConnection.CONNECTED, state.connection)
        assertEquals(1L, state.epoch)
        assertEquals(listOf(NativeCapability.HEART_RATE), state.capabilities)
    }

    @Test
    fun heartRateFromTheStrapAppearsOnceItIsHealthy() = runTest {
        val e = engine()
        e.link("strap", listOf("180d"))
        e.hr("strap", 145, 0)
        assertNull(e.snapshot().metric(NativeMetric.HEART_RATE))
        e.hr("strap", 146, 1000)
        val m = assertNotNull(e.snapshot().metric(NativeMetric.HEART_RATE))
        assertEquals(146.0, m.value, 0.0)
        assertEquals("strap", m.sourceId)
    }

    @Test
    fun twoDevicesGiveTwoMetricsAndALostOneDoesNotTakeTheOtherDown() = runTest {
        val e = engine()
        e.link("strap", listOf("180d"))
        e.link("foot", listOf("1814"))
        e.hr("strap", 145, 0)
        e.hr("strap", 146, 1000)
        clock = 0
        e.onNotification("foot", "2a53", b(0x00, 0xD0, 0x02, 170))
        clock = 1000
        e.onNotification("foot", "2a53", b(0x00, 0xD0, 0x02, 171))
        var s = e.snapshot()
        assertEquals(146.0, s.metric(NativeMetric.HEART_RATE)!!.value, 0.0)
        assertEquals(171.0, s.metric(NativeMetric.RUNNING_CADENCE)!!.value, 0.0)
        transport.listener!!.onDisconnected("strap", "GATT_8: link lost")
        s = e.snapshot()
        assertNull(s.metric(NativeMetric.HEART_RATE))
        assertEquals(171.0, s.metric(NativeMetric.RUNNING_CADENCE)!!.value, 0.0)
        assertEquals(NativeConnection.FAILED, s.devices.first { it.id == "strap" }.connection)
        assertEquals("GATT_8: link lost", s.devices.first { it.id == "strap" }.error)
    }

    @Test
    fun aReconnectIsANewEpochAndOldDataIsNotMixed() = runTest {
        val e = engine()
        e.link("strap", listOf("180d"))
        e.hr("strap", 145, 0)
        e.hr("strap", 146, 1000)
        transport.listener!!.onDisconnected("strap", null)
        e.link("strap", listOf("180d"))
        assertEquals(2L, e.snapshot().devices.single().epoch)
        assertNull(e.snapshot().metric(NativeMetric.HEART_RATE), "the new connection earns its place again")
        e.hr("strap", 150, 2000)
        e.hr("strap", 151, 3000)
        assertEquals(151.0, e.snapshot().metric(NativeMetric.HEART_RATE)!!.value, 0.0)
    }

    @Test
    fun notificationsOfADeviceThatIsNotConnectedAreDropped() = runTest {
        val e = engine()
        e.onNotification("ghost", "2a37", b(0x00, 100))
        var done: Result<Unit>? = null
        e.connect("A") { done = it }
        e.onNotification("A", "2a37", b(0x00, 100)) // still connecting
        assertNull(done)
        assertNull(e.snapshot().metric(NativeMetric.HEART_RATE))
    }

    @Test
    fun theCyclingCadencePacketIsForwardedRawWithItsEpoch() = runTest {
        val e = engine()
        e.link("bike", listOf("1816"))
        clock = 500
        e.onNotification("bike", "2a5b", b(0x02, 1, 0, 1, 0))
        val p = sink.raw.single()
        assertEquals("bike", p.deviceId)
        assertEquals("2a5b", p.characteristic)
        assertEquals(1L, p.epoch)
        assertEquals(500L, p.receivedAtMs)
        assertEquals(5, p.data.size)
        // a characteristic the core decodes is NOT forwarded
        e.onNotification("bike", "2a37", b(0x00, 100))
        assertEquals(1, sink.raw.size)
    }

    @Test
    fun aFailedConnectFailsTheCallAndKeepsTheReason() = runTest {
        val e = engine()
        var done: Result<Unit>? = null
        e.connect("A") { done = it }
        transport.listener!!.onDisconnected("A", "PERMISSION: not allowed")
        assertTrue(done!!.isFailure)
        val state = e.snapshot().devices.single()
        assertEquals(NativeConnection.FAILED, state.connection)
        assertEquals("PERMISSION: not allowed", state.error)
    }

    @Test
    fun aDeviceThatNeverAnswersTimesOut() = runTest {
        val e = engine()
        var done: Result<Unit>? = null
        e.connect("A") { done = it }
        advanceTimeBy(20_001)
        assertTrue(done!!.isFailure)
        assertEquals(NativeConnection.FAILED, e.snapshot().devices.single().connection)
        assertEquals(listOf("A"), transport.disconnects)
    }

    @Test
    fun connectingTwiceIsRefusedWhileConnectingAndAnswersAtOnceWhenUp() = runTest {
        val e = engine()
        e.connect("A") {}
        var second: Result<Unit>? = null
        e.connect("A") { second = it }
        assertTrue(second!!.isFailure)
        e.onConnected("A", null, listOf("180d"))
        var third: Result<Unit>? = null
        e.connect("A") { third = it }
        assertTrue(third!!.isSuccess)
        assertEquals(listOf("A"), transport.connects)
    }

    @Test
    fun disconnectAndForgetDropTheDeviceAndItsValues() = runTest {
        val e = engine()
        e.link("strap", listOf("180d"))
        e.hr("strap", 145, 0)
        e.hr("strap", 146, 1000)
        e.disconnect("strap")
        assertEquals(NativeConnection.DISCONNECTED, e.snapshot().devices.single().connection)
        assertNull(e.snapshot().metric(NativeMetric.HEART_RATE))
        e.forget("strap")
        assertTrue(e.snapshot().devices.isEmpty())
        assertEquals(listOf("strap", "strap"), transport.disconnects)
    }

    @Test
    fun thePreferredSourceWinsWhileItIsHealthy() = runTest {
        val e = engine()
        e.link("strap", listOf("180d"))
        e.link("watch", listOf("180d"))
        for (t in listOf(0L, 1000L)) { e.hr("strap", 145, t); e.hr("watch", 141, t) }
        assertEquals("strap", e.snapshot().metric(NativeMetric.HEART_RATE)!!.sourceId)
        e.setPreferred(NativeMetric.HEART_RATE, "watch")
        assertEquals("watch", e.snapshot().metric(NativeMetric.HEART_RATE)!!.sourceId)
    }

    @Test
    fun silenceMakesAMetricUnknownNotStale() = runTest {
        val e = engine()
        e.link("strap", listOf("180d"))
        e.hr("strap", 145, 0)
        e.hr("strap", 146, 1000)
        clock = 7000
        assertNull(e.snapshot().metric(NativeMetric.HEART_RATE))
    }

    @Test
    fun theSnapshotIsPublishedAboutOncePerSecond() = runTest {
        val e = engine()
        e.start()
        advanceTimeBy(3_500)
        assertEquals(3, sink.snapshots.size)
        e.stop()
    }

    @Test
    fun everyMetricAndCapabilityKeepsItsMeaningAcrossTheCoreBoundary() = runTest {
        val e = engine()
        e.link("foot", listOf("180d", "1814", "1816", "1818", "1826", "180f", "180a"))
        assertEquals(
            listOf(
                NativeCapability.HEART_RATE, NativeCapability.RUNNING_SPEED_CADENCE, NativeCapability.CYCLING_SPEED_CADENCE,
                NativeCapability.CYCLING_POWER, NativeCapability.FITNESS_MACHINE, NativeCapability.BATTERY,
                NativeCapability.DEVICE_INFORMATION,
            ),
            e.snapshot().devices.single().capabilities,
        )
        val packet = b(0x07, 0xD0, 0x02, 170, 0x63, 0x00, 0x40, 0x9C, 0x00, 0x00)
        for (t in listOf(0L, 1000L)) { clock = t; e.onNotification("foot", "2a53", packet) }
        val s = e.snapshot()
        assertEquals(2.8125, s.metric(NativeMetric.RUNNING_SPEED)!!.value, 1e-9)
        assertEquals(170.0, s.metric(NativeMetric.RUNNING_CADENCE)!!.value, 0.0)
        assertEquals(0.99, s.metric(NativeMetric.RUNNING_STRIDE_LENGTH)!!.value, 1e-9)
        assertEquals(4000.0, s.metric(NativeMetric.TOTAL_DISTANCE)!!.value, 1e-9)
        assertEquals(NativeKind.CUMULATIVE, s.metric(NativeMetric.TOTAL_DISTANCE)!!.kind)
        assertEquals(NativeKind.INSTANTANEOUS, s.metric(NativeMetric.RUNNING_CADENCE)!!.kind)
    }

    @Test
    fun theAdapterStateIsTheTransportsAndBluetoothOffNeverThrows() = runTest {
        val e = engine()
        transport.state = NativeAdapterState.POWERED_OFF
        assertEquals(NativeAdapterState.POWERED_OFF, e.adapterState())
    }
}
