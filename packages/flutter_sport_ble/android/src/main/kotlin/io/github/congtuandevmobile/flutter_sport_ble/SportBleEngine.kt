package io.github.congtuandevmobile.flutter_sport_ble

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import sensor.model.MeasurementKind
import sensor.model.MetricType
import sensor.protocol.Gatt
import sensor.protocol.ProtocolRegistry
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
 * connection a new epoch (so data of an older one is dropped), forwards the characteristics the registry marks as raw, and
 * publishes a snapshot about once per second and on every connection change. It never reconnects by itself and never touches GPS.
 *
 * A device goes CONNECTING, DISCOVERING, SUBSCRIBING, then READY (at least one workout measurement is subscribed) or NOT_SUPPORTED
 * (the link works but no workout measurement could be subscribed). READY is the only state that means "can give metrics".
 * All state is guarded by [lock].
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
        var services: List<String> = emptyList()
        var subscribed: List<String> = emptyList()
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

    /** [allDevices] scans every BLE device; otherwise only the services of the registry. Both stop after [timeoutMs]. */
    fun startScan(timeoutMs: Long, allDevices: Boolean) {
        synchronized(lock) {
            scanTimeout?.cancel()
            scanTimeout = scope.launch {
                delay(timeoutMs)
                transport.stopScan()
                sink.onScanStopped()
            }
        }
        transport.startScan(if (allDevices) null else ProtocolRegistry.scanServices())
    }

    fun stopScan() {
        synchronized(lock) {
            scanTimeout?.cancel()
            scanTimeout = null
        }
        transport.stopScan()
        sink.onScanStopped()
    }

    /** Connects; [done] runs once: when the device is READY, or when it failed or is NOT_SUPPORTED. */
    fun connect(id: String, done: (Result<Unit>) -> Unit) {
        val epoch: Long
        synchronized(lock) {
            val device = devices.getOrPut(id) { Device() }
            when (device.connection) {
                NativeConnection.READY -> { done(Result.success(Unit)); return }
                NativeConnection.CONNECTING, NativeConnection.DISCOVERING, NativeConnection.SUBSCRIBING -> {
                    done(Result.failure(IllegalStateException("CONNECT_FAILED: already connecting")))
                    return
                }
                else -> Unit
            }
            device.epoch += 1
            epoch = device.epoch
            device.connection = NativeConnection.CONNECTING
            device.error = null
            device.services = emptyList()
            device.subscribed = emptyList()
            device.pending = done
            device.timeout = scope.launch {
                delay(connectTimeoutMs)
                failPending(id, "TIMEOUT: the device did not answer in time", disconnect = true)
            }
            hub.onConnection(id, epoch, false)
        }
        publish()
        transport.connect(id, ProtocolRegistry.notifyCharacteristics(), ProtocolRegistry.readCharacteristics())
    }

    fun disconnect(id: String) {
        synchronized(lock) {
            val device = devices[id] ?: return
            device.timeout?.cancel()
            device.pending?.let { it(Result.failure(IllegalStateException("CONNECT_FAILED: cancelled"))) }
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

    fun setWheelCircumference(id: String, metres: Double?) {
        synchronized(lock) { hub.setWheelCircumference(id, metres) }
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
                val details = hub.details(id)
                NativeDeviceState(
                    id = id, name = d.name, connection = d.connection, epoch = d.epoch, capabilities = d.capabilities,
                    discoveredServices = d.services, subscribedCharacteristics = d.subscribed,
                    recentRrMs = details.recentRrMs.map { it.toLong() }, error = d.error,
                    manufacturer = details.manufacturer, model = details.model, firmware = details.firmware,
                    batteryPercent = details.batteryPercent?.toLong(),
                )
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

    override fun onGattConnected(id: String) {
        synchronized(lock) {
            val device = devices[id] ?: return
            if (device.connection != NativeConnection.CONNECTING) return
            device.connection = NativeConnection.DISCOVERING
        }
        publish()
    }

    override fun onServicesDiscovered(id: String, name: String?, serviceShortIds: List<String>) {
        synchronized(lock) {
            val device = devices[id] ?: return
            if (device.connection != NativeConnection.CONNECTING && device.connection != NativeConnection.DISCOVERING) return
            device.connection = NativeConnection.SUBSCRIBING
            device.name = name ?: device.name
            device.services = serviceShortIds
            device.capabilities = capabilitiesOf(serviceShortIds)
            hub.setCapabilities(id, Gatt.capabilities(serviceShortIds))
            // Notifications can start the moment a subscription is on: the hub must already know the link.
            hub.onConnection(id, device.epoch, true)
        }
        publish()
    }

    override fun onReady(id: String, subscribed: List<String>, failed: List<String>) {
        var done: ((Result<Unit>) -> Unit)? = null
        var result: Result<Unit> = Result.success(Unit)
        var unsupported = false
        synchronized(lock) {
            val device = devices[id] ?: return
            if (device.connection != NativeConnection.SUBSCRIBING) return
            device.timeout?.cancel()
            done = device.pending
            device.pending = null
            device.subscribed = subscribed
            if (subscribed.any { ProtocolRegistry.isWorkoutCharacteristic(it) }) {
                device.connection = NativeConnection.READY
                if (failed.isNotEmpty()) device.error = "PARTIAL: could not subscribe to ${failed.joinToString(", ")}"
            } else {
                unsupported = true
                device.connection = NativeConnection.NOT_SUPPORTED
                device.error = if (failed.isEmpty()) {
                    "NOT_SUPPORTED: the device has no workout measurement this package can use"
                } else {
                    "NOT_SUPPORTED: could not subscribe to ${failed.joinToString(", ")}"
                }
                result = Result.failure(IllegalStateException(device.error!!))
                hub.onConnection(id, device.epoch, false)
            }
        }
        if (unsupported) transport.disconnect(id)
        publish()
        done?.invoke(result)
    }

    override fun onNotification(id: String, characteristicShortId: String, bytes: ByteArray) {
        val packet: NativeRawPacket?
        synchronized(lock) {
            val device = devices[id] ?: return
            if (device.connection != NativeConnection.READY && device.connection != NativeConnection.SUBSCRIBING) return
            val now = monotonicMs()
            hub.onPacket(id, device.epoch, characteristicShortId, bytes, now)
            packet = if (characteristicShortId in ProtocolRegistry.rawForwarded()) {
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
            if (device.connection == NativeConnection.NOT_SUPPORTED && error == null) return // we closed it ourselves
            device.timeout?.cancel()
            done = device.pending
            device.pending = null
            if (device.connection != NativeConnection.NOT_SUPPORTED) {
                device.connection = if (error != null) NativeConnection.FAILED else NativeConnection.DISCONNECTED
                device.error = error
            }
            hub.onConnection(id, device.epoch, false)
        }
        publish()
        done?.invoke(Result.failure(IllegalStateException(error ?: "CONNECT_FAILED: disconnected")))
    }

    // ── internals ───────────────────────────────────────────────────────────

    private fun failPending(id: String, error: String, disconnect: Boolean) {
        var done: ((Result<Unit>) -> Unit)? = null
        synchronized(lock) {
            val device = devices[id] ?: return
            val c = device.connection
            if (c != NativeConnection.CONNECTING && c != NativeConnection.DISCOVERING && c != NativeConnection.SUBSCRIBING) return
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
}
