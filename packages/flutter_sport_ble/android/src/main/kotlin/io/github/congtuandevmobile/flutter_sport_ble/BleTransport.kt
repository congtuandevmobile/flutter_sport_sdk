package io.github.congtuandevmobile.flutter_sport_ble

/**
 * The radio, as the engine sees it: scan, connect, and a stream of what the connected devices say. It knows nothing about
 * what the bytes mean (the shared core decodes them) and nothing about Flutter, so the engine can be tested with a fake.
 * Every method may be called from any thread; every [Listener] callback is delivered on ONE thread.
 */
interface BleTransport {
    var listener: Listener?

    fun adapterState(): NativeAdapterState

    /** Starts a scan for devices that advertise one of [serviceShortIds] (4 lowercase hex digits). */
    fun startScan(serviceShortIds: List<String>)
    fun stopScan()

    /** Connects, discovers the services, subscribes to the measurements in [measurementShortIds] and then reports [Listener.onConnected]. */
    fun connect(deviceId: String, measurementShortIds: List<String>)
    fun disconnect(deviceId: String)

    interface Listener {
        fun onDeviceFound(id: String, name: String?, rssi: Int, serviceShortIds: List<String>)
        fun onScanFinished()

        /** The link is up, the services were discovered and the notifications are on. */
        fun onConnected(id: String, name: String?, serviceShortIds: List<String>)

        /** A notification of a subscribed characteristic ([characteristicShortId] is 4 lowercase hex digits). */
        fun onNotification(id: String, characteristicShortId: String, bytes: ByteArray)

        /** The link ended or could not be made; [error] is null for a disconnect the engine asked for. */
        fun onDisconnected(id: String, error: String?)
    }
}
