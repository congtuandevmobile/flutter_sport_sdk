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
    var lastScanServices: List<String>? = emptyList()
    var lastNotify: List<String> = emptyList()
    var lastRead: List<String> = emptyList()
    override fun adapterState() = state
    override fun startScan(serviceShortIds: List<String>?) { scans += 1; lastScanServices = serviceShortIds }
    override fun stopScan() { scanStops += 1 }
    override fun connect(deviceId: String, notify: List<String>, read: List<String>) {
        connects += deviceId; lastNotify = notify; lastRead = read
    }
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

    /** A device that connects, discovers [services] and subscribes to the characteristics of [subscribed]. */
    private fun SportBleEngine.link(id: String, services: List<String>, subscribed: List<String>? = null, failed: List<String> = emptyList()): Result<Unit>? {
        var result: Result<Unit>? = null
        connect(id) { result = it }
        onGattConnected(id)
        onServicesDiscovered(id, "dev-$id", services)
        val subs = subscribed ?: services.flatMap {
            when (it) { "180d" -> listOf("2a37"); "1814" -> listOf("2a53"); "1816" -> listOf("2a5b"); "1818" -> listOf("2a63"); "1826" -> listOf("2ad2"); else -> emptyList() }
        }
        onReady(id, subs, failed)
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
        e.startScan(10_000, false)
        transport.listener!!.onDeviceFound("A", "Strap", -60, listOf("180d", "180f"))
        val d = sink.devices.single()
        assertEquals("A", d.id)
        assertEquals(listOf(NativeCapability.HEART_RATE, NativeCapability.BATTERY), d.capabilities)
        assertEquals(1, transport.scans)
    }

    @Test
    fun aScanStopsByItselfAfterItsTimeout() = runTest {
        val e = engine()
        e.startScan(5_000, false)
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
        assertEquals(NativeConnection.READY, state.connection)
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
        e.onGattConnected("A"); e.onServicesDiscovered("A", null, listOf("180d")); e.onReady("A", listOf("2a37"), emptyList())
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

    // ── wave 0: scan, readiness, stale callbacks, one bad device ────────────

    @Test
    fun scanCanLookAtEveryBleDeviceOrOnlyAtTheServicesOfTheRegistry() = runTest {
        val e = engine()
        e.startScan(5_000, false)
        assertEquals(listOf("180d", "1814", "1816", "1818", "1826"), transport.lastScanServices)
        e.startScan(5_000, true)
        assertNull(transport.lastScanServices, "null means every BLE device")
    }

    @Test
    fun connectUsesTheRegistryForWhatToSubscribeAndRead() = runTest {
        val e = engine()
        e.connect("A") {}
        assertTrue(transport.lastNotify.containsAll(listOf("2a37", "2a53", "2a5b", "2a63", "2ad2")))
        assertTrue(transport.lastRead.containsAll(listOf("2a19", "2a29")))
    }

    @Test
    fun theStatesGoThroughDiscoveringAndSubscribingBeforeReady() = runTest {
        val e = engine()
        e.connect("A") {}
        assertEquals(NativeConnection.CONNECTING, e.snapshot().devices.single().connection)
        e.onGattConnected("A")
        assertEquals(NativeConnection.DISCOVERING, e.snapshot().devices.single().connection)
        e.onServicesDiscovered("A", "Strap", listOf("180d"))
        assertEquals(NativeConnection.SUBSCRIBING, e.snapshot().devices.single().connection)
        e.onReady("A", listOf("2a37"), emptyList())
        val d = e.snapshot().devices.single()
        assertEquals(NativeConnection.READY, d.connection)
        assertEquals(listOf("180d"), d.discoveredServices)
        assertEquals(listOf("2a37"), d.subscribedCharacteristics)
    }

    @Test
    fun aConnectionWithoutAWorkoutMeasurementIsNotReadyAndSaysWhy() = runTest {
        val e = engine()
        val r = e.link("A", listOf("180f", "180a"), subscribed = listOf("2a19"))
        assertTrue(r!!.isFailure)
        val d = e.snapshot().devices.single()
        assertEquals(NativeConnection.NOT_SUPPORTED, d.connection)
        assertTrue(d.error!!.startsWith("NOT_SUPPORTED"))
        assertEquals(listOf("A"), transport.disconnects, "the useless link is closed")
        assertEquals(listOf(NativeCapability.BATTERY, NativeCapability.DEVICE_INFORMATION), d.capabilities)
    }

    @Test
    fun aSubscriptionThatFailedIsReportedAndNeverSilentlySkipped() = runTest {
        val e = engine()
        // the strap has the heart rate characteristic but it could not be subscribed: nothing usable
        val none = e.link("A", listOf("180d"), subscribed = emptyList(), failed = listOf("2a37"))
        assertTrue(none!!.isFailure)
        assertTrue(e.snapshot().devices.single().error!!.contains("2a37"))
        // one of two failed: READY, with the failure said
        val some = e.link("B", listOf("1814", "180d"), subscribed = listOf("2a53"), failed = listOf("2a37"))
        assertTrue(some!!.isSuccess)
        val b = e.snapshot().devices.first { it.id == "B" }
        assertEquals(NativeConnection.READY, b.connection)
        assertTrue(b.error!!.startsWith("PARTIAL"))
    }

    @Test
    fun aStaleNotificationDuringANewAttemptIsDropped() = runTest {
        val e = engine()
        e.link("strap", listOf("180d"))
        e.hr("strap", 145, 0)
        e.hr("strap", 146, 1000)
        transport.listener!!.onDisconnected("strap", null)
        e.connect("strap") {} // the second attempt has started
        e.onNotification("strap", "2a37", b(0x00, 190)) // a late packet of the first link
        e.onGattConnected("strap")
        e.onServicesDiscovered("strap", null, listOf("180d"))
        e.onReady("strap", listOf("2a37"), emptyList())
        assertNull(e.snapshot().metric(NativeMetric.HEART_RATE))
        assertEquals(2L, e.snapshot().devices.single().epoch)
    }

    @Test
    fun aDeviceThatIsNotSupportedDoesNotBlockAnother() = runTest {
        val e = engine()
        e.link("battery-only", listOf("180f"), subscribed = listOf("2a19"))
        e.link("strap", listOf("180d"))
        e.hr("strap", 145, 0)
        e.hr("strap", 146, 1000)
        val s = e.snapshot()
        assertEquals(146.0, s.metric(NativeMetric.HEART_RATE)!!.value, 0.0)
        assertEquals(NativeConnection.NOT_SUPPORTED, s.devices.first { it.id == "battery-only" }.connection)
        assertEquals(NativeConnection.READY, s.devices.first { it.id == "strap" }.connection)
    }

    @Test
    fun batteryDeviceInformationAndRrIntervalsReachTheSnapshot() = runTest {
        val e = engine()
        e.link("strap", listOf("180d", "180f", "180a"), subscribed = listOf("2a37", "2a19"))
        e.onNotification("strap", "2a19", b(82))
        e.onNotification("strap", "2a29", "Polar".encodeToByteArray())
        e.onNotification("strap", "2a24", "H10".encodeToByteArray())
        e.onNotification("strap", "2a26", "3.0.35".encodeToByteArray())
        e.onNotification("strap", "2a37", b(0x16, 70, 0x00, 0x04, 0x00, 0x02))
        val d = e.snapshot().devices.single()
        assertEquals(82L, d.batteryPercent)
        assertEquals("Polar", d.manufacturer)
        assertEquals("H10", d.model)
        assertEquals("3.0.35", d.firmware)
        assertEquals(listOf(1000L, 500L), d.recentRrMs)
    }

    @Test
    fun theSnapshotKeepsEachDevicesOwnCounterEvenThoughOnlyOneIsResolved() = runTest {
        val e = engine()
        e.link("foot", listOf("1814"))
        e.link("rower", listOf("1826"), subscribed = listOf("2ad1"))
        for (t in listOf(0L, 1000L)) {
            clock = t
            e.onNotification("foot", "2a53", b(0x02, 0x00, 0x01, 100, 0x98, 0x3A, 0x00, 0x00)) // total distance 1500.0 m
            e.onNotification("rower", "2ad1", b(0x04, 0x00, 56, 120, 0, 0x52, 0x03, 0x00)) // 850 m
        }
        val s = e.snapshot()
        assertEquals(1, s.metrics.count { it.metric == NativeMetric.TOTAL_DISTANCE })
        val byDevice = s.deviceValues.filter { it.metric == NativeMetric.TOTAL_DISTANCE }.associateBy { it.deviceId }
        assertEquals(1500.0, byDevice.getValue("foot").value, 1e-9)
        assertEquals(850.0, byDevice.getValue("rower").value, 1e-9)
        assertEquals(1L, byDevice.getValue("foot").epoch)
    }

    @Test
    fun theWheelCircumferenceTurnsWheelRevolutionsIntoSpeed() = runTest {
        val e = engine()
        e.link("wheel", listOf("1816"))
        e.setWheelCircumference("wheel", 2.1)
        fun w(count: Int, ticks: Int) = b(0x01, count and 0xFF, 0, 0, 0, ticks and 0xFF, (ticks shr 8) and 0xFF)
        for ((i, c) in listOf(1000, 1002, 1004, 1006).withIndex()) { clock = i * 1000L; e.onNotification("wheel", "2a5b", w(c, i * 1024)) }
        assertEquals(4.2, e.snapshot().metric(NativeMetric.CYCLING_SPEED)!!.value, 1e-6)
    }

    @Test
    fun everyMetricOfTheCoreHasItsPigeonTwinWithTheSameOrder() = runTest {
        val core = sensor.model.MetricType.values().map { it.name }
        assertEquals(core, NativeMetric.values().map { it.name })
        assertEquals(sensor.model.Capability.values().map { it.name }, NativeCapability.values().map { it.name })
    }

    @Test
    fun theAdapterStateIsTheTransportsAndBluetoothOffNeverThrows() = runTest {
        val e = engine()
        transport.state = NativeAdapterState.POWERED_OFF
        assertEquals(NativeAdapterState.POWERED_OFF, e.adapterState())
    }
}
