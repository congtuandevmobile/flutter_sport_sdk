package io.github.congtuandevmobile.flutter_sport_ble

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import sensor.model.MeasurementKind
import sensor.model.MetricType
import sensor.protocol.Gatt
import sensor.resolver.SensorHub

/** What the engine tells the Flutter side (the plugin turns it into Pigeon calls on the main thread). */
interface SportBleSink {
    fun onDeviceFound(device: NativeBleDevice)
    fun onScanStopped()
    fun onSnapshot(snapshot: NativeSensorSnapshot)
    fun onRawPacket(packet: NativeRawPacket)
}

/**
 * Owns the devices and the shared [SensorHub]. Every connection event and every notification goes into the hub (it decodes,
 * validates and chooses the source per metric); the engine only keeps the connection state of each device, gives every new
 * connection a new epoch (so data of an older one is dropped), forwards the characteristics the core does not decode, and
 * publishes a snapshot about once per second and on every connection change. It never reconnects by itself and never touches
 * GPS: connecting again is the host's call. All state is guarded by [lock].
 */
class SportBleEngine(
    private val transport: BleTransport,
    private val scope: CoroutineScope,
    private val monotonicMs: () -> Long,
    private val sink: SportBleSink,
    private val hub: SensorHub = SensorHub(),
    private val connectTimeoutMs: Long = 20_000,
    private val snapshotEveryMs: Long = 1_000,
) : BleTransport.Listener {
    private class Device(var epoch: Long = 0) {
        var name: String? = null
        var connection = NativeConnection.DISCONNECTED
        var capabilities: List<NativeCapability> = emptyList()
        var error: String? = null
        var pending: ((Result<Unit>) -> Unit)? = null
        var timeout: Job? = null
    }

    private val lock = Any()
    private val devices = LinkedHashMap<String, Device>()
    private var ticker: Job? = null
    private var scanTimeout: Job? = null

    init {
        transport.listener = this
    }

    fun start() {
        synchronized(lock) {
            if (ticker != null) return
            ticker = scope.launch {
                while (true) {
                    delay(snapshotEveryMs)
                    publish()
                }
            }
        }
    }

    fun stop() {
        val ids: List<String>
        synchronized(lock) {
            ticker?.cancel()
            ticker = null
            scanTimeout?.cancel()
            scanTimeout = null
            ids = devices.keys.toList()
        }
        transport.stopScan()
        for (id in ids) transport.disconnect(id)
    }

    fun adapterState(): NativeAdapterState = transport.adapterState()

    fun startScan(timeoutMs: Long) {
        synchronized(lock) {
            scanTimeout?.cancel()
            scanTimeout = scope.launch {
                delay(timeoutMs)
                transport.stopScan()
                sink.onScanStopped()
            }
        }
        transport.startScan(SCAN_SERVICES)
    }

    fun stopScan() {
        synchronized(lock) {
            scanTimeout?.cancel()
            scanTimeout = null
        }
        transport.stopScan()
        sink.onScanStopped()
    }

    /** Connects; [done] runs once: when the link is up and subscribed, or when it failed. */
    fun connect(id: String, done: (Result<Unit>) -> Unit) {
        val epoch: Long
        synchronized(lock) {
            val device = devices.getOrPut(id) { Device() }
            if (device.connection == NativeConnection.CONNECTED) {
                done(Result.success(Unit))
                return
            }
            if (device.connection == NativeConnection.CONNECTING) {
                done(Result.failure(IllegalStateException("already connecting")))
                return
            }
            device.epoch += 1
            epoch = device.epoch
            device.connection = NativeConnection.CONNECTING
            device.error = null
            device.pending = done
            device.timeout = scope.launch {
                delay(connectTimeoutMs)
                failPending(id, "TIMEOUT: the device did not answer in time", disconnect = true)
            }
            hub.onConnection(id, epoch, false)
        }
        publish()
        transport.connect(id, MEASUREMENTS)
    }

    fun disconnect(id: String) {
        synchronized(lock) {
            val device = devices[id] ?: return
            device.timeout?.cancel()
            device.pending?.let { it(Result.failure(IllegalStateException("cancelled"))) }
            device.pending = null
            device.connection = NativeConnection.DISCONNECTED
            hub.onConnection(id, device.epoch, false)
        }
        transport.disconnect(id)
        publish()
    }

    fun forget(id: String) {
        disconnect(id)
        synchronized(lock) {
            devices.remove(id)
            hub.forget(id)
        }
        publish()
    }

    fun setPreferred(metric: NativeMetric, id: String?) {
        synchronized(lock) { hub.setPreferred(MetricType.valueOf(metric.name), id) }
    }

    fun snapshot(): NativeSensorSnapshot {
        val now = monotonicMs()
        synchronized(lock) {
            val metrics = hub.resolve(now).map {
                NativeResolvedMetric(
                    metric = NativeMetric.valueOf(it.metric.name),
                    value = it.value,
                    sourceId = it.sourceId,
                    kind = if (it.kind == MeasurementKind.CUMULATIVE) NativeKind.CUMULATIVE else NativeKind.INSTANTANEOUS,
                    ageMs = it.ageMs,
                )
            }
            val states = devices.map { (id, d) ->
                NativeDeviceState(id = id, name = d.name, connection = d.connection, epoch = d.epoch, capabilities = d.capabilities, error = d.error)
            }
            return NativeSensorSnapshot(metrics = metrics, devices = states, updatedAtMs = now)
        }
    }

    // ── BleTransport.Listener ───────────────────────────────────────────────

    override fun onDeviceFound(id: String, name: String?, rssi: Int, serviceShortIds: List<String>) {
        sink.onDeviceFound(NativeBleDevice(id = id, name = name, rssi = rssi.toLong(), capabilities = capabilitiesOf(serviceShortIds)))
    }

    override fun onScanFinished() {
        synchronized(lock) {
            scanTimeout?.cancel()
            scanTimeout = null
        }
        sink.onScanStopped()
    }

    override fun onConnected(id: String, name: String?, serviceShortIds: List<String>) {
        var done: ((Result<Unit>) -> Unit)? = null
        synchronized(lock) {
            val device = devices[id] ?: return
            if (device.connection != NativeConnection.CONNECTING) return
            device.connection = NativeConnection.CONNECTED
            device.name = name ?: device.name
            device.capabilities = capabilitiesOf(serviceShortIds)
            device.timeout?.cancel()
            done = device.pending
            device.pending = null
            hub.onConnection(id, device.epoch, true)
        }
        publish()
        done?.invoke(Result.success(Unit))
    }

    override fun onNotification(id: String, characteristicShortId: String, bytes: ByteArray) {
        val packet: NativeRawPacket?
        synchronized(lock) {
            val device = devices[id] ?: return
            if (device.connection != NativeConnection.CONNECTED) return
            val now = monotonicMs()
            hub.onPacket(id, device.epoch, characteristicShortId, bytes, now)
            packet = if (characteristicShortId in RAW_FORWARDED) {
                NativeRawPacket(deviceId = id, epoch = device.epoch, characteristic = characteristicShortId, data = bytes, receivedAtMs = now)
            } else {
                null
            }
        }
        if (packet != null) sink.onRawPacket(packet)
    }

    override fun onDisconnected(id: String, error: String?) {
        var done: ((Result<Unit>) -> Unit)? = null
        synchronized(lock) {
            val device = devices[id] ?: return
            if (device.connection == NativeConnection.DISCONNECTED) return
            device.timeout?.cancel()
            done = device.pending
            device.pending = null
            device.connection = if (error != null) NativeConnection.FAILED else NativeConnection.DISCONNECTED
            device.error = error
            hub.onConnection(id, device.epoch, false)
        }
        publish()
        done?.invoke(Result.failure(IllegalStateException(error ?: "disconnected")))
    }

    // ── internals ───────────────────────────────────────────────────────────

    private fun failPending(id: String, error: String, disconnect: Boolean) {
        var done: ((Result<Unit>) -> Unit)? = null
        synchronized(lock) {
            val device = devices[id] ?: return
            if (device.connection != NativeConnection.CONNECTING) return
            done = device.pending
            device.pending = null
            device.connection = NativeConnection.FAILED
            device.error = error
            hub.onConnection(id, device.epoch, false)
        }
        if (disconnect) transport.disconnect(id)
        publish()
        done?.invoke(Result.failure(IllegalStateException(error)))
    }

    private fun publish() = sink.onSnapshot(snapshot())

    private fun capabilitiesOf(serviceShortIds: List<String>): List<NativeCapability> =
        Gatt.capabilities(serviceShortIds).map { NativeCapability.valueOf(it.name) }

    companion object {
        /** Scanned for: heart rate, running speed and cadence, cycling speed and cadence. */
        val SCAN_SERVICES = listOf(
            Gatt.HEART_RATE_SERVICE,
            Gatt.RUNNING_SPEED_CADENCE_SERVICE,
            Gatt.CYCLING_SPEED_CADENCE_SERVICE,
        )

        /** Subscribed to after connecting (every measurement the core decodes, plus the CSC one that is forwarded). */
        val MEASUREMENTS = listOf(Gatt.HEART_RATE_MEASUREMENT, Gatt.RSC_MEASUREMENT, Gatt.CSC_MEASUREMENT)

        /** Characteristics the core does not decode: their bytes go to the host. */
        val RAW_FORWARDED = setOf(Gatt.CSC_MEASUREMENT)
    }
}
