package io.github.congtuandevmobile.flutter_sport_ble

/**
 * The radio, as the engine sees it: scan, connect, and a stream of what the connected devices say. It knows nothing about what
 * the bytes mean (the shared core decodes them) and nothing about Flutter, so the engine can be tested with a fake.
 * Every method may be called from any thread; every [Listener] callback is delivered on ONE thread.
 */
interface BleTransport {
    var listener: Listener?

    fun adapterState(): NativeAdapterState

    /** Starts a scan for devices that advertise one of [serviceShortIds] (4 lowercase hex digits); null scans EVERY BLE device. */
    fun startScan(serviceShortIds: List<String>?)
    fun stopScan()

    /**
     * Connects, discovers the services, subscribes to the characteristics of [notify] that the device has and, after announcing
     * [Listener.onReady], reads once the ones of [read] that it has (their value comes through [Listener.onNotification]).
     */
    fun connect(deviceId: String, notify: List<String>, read: List<String>)
    fun disconnect(deviceId: String)

    interface Listener {
        fun onDeviceFound(id: String, name: String?, rssi: Int, serviceShortIds: List<String>)
        fun onScanFinished()

        /** The link is up; the services are being discovered. */
        fun onGattConnected(id: String)

        /** The services are known; the subscriptions start. */
        fun onServicesDiscovered(id: String, name: String?, serviceShortIds: List<String>)

        /**
         * Every subscription was tried. [subscribed] are the characteristics that now notify, [failed] the ones the device has
         * but that could not be subscribed (no descriptor, refused). Both may be empty: that is "connected, not usable".
         */
        fun onReady(id: String, subscribed: List<String>, failed: List<String>)

        /** A notification (or a read) of a characteristic ([characteristicShortId] is 4 lowercase hex digits). */
        fun onNotification(id: String, characteristicShortId: String, bytes: ByteArray)

        /** The link ended or could not be made; [error] is null for a disconnect the engine asked for. */
        fun onDisconnected(id: String, error: String?)
    }
}
