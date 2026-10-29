import Foundation

/// The radio, as the engine sees it: scan, connect, and a stream of what the connected devices say. It knows nothing about what
/// the bytes mean (the shared core decodes them) and nothing about Flutter, so the engine can be tested with a fake.
protocol BleTransport: AnyObject {
    var listener: BleTransportListener? { get set }

    func adapterState() -> NativeAdapterState

    /// Starts a scan for devices that advertise one of `serviceShortIds` (4 lowercase hex digits).
    func startScan(serviceShortIds: [String])
    func stopScan()

    /// Connects, discovers the services, subscribes to `measurementShortIds`, then reports `onConnected`.
    func connect(deviceId: String, measurementShortIds: [String])
    func disconnect(deviceId: String)
}

/// Every callback may come from any thread: the engine hops to its own queue.
protocol BleTransportListener: AnyObject {
    func onDeviceFound(id: String, name: String?, rssi: Int, serviceShortIds: [String])
    func onScanFinished()

    /// The link is up, the services were discovered and the notifications are on.
    func onConnected(id: String, name: String?, serviceShortIds: [String])

    /// A notification of a subscribed characteristic (`characteristicShortId` is 4 lowercase hex digits).
    func onNotification(id: String, characteristicShortId: String, bytes: Data)

    /// The link ended or could not be made; `error` is nil for a disconnect the engine asked for.
    func onDisconnected(id: String, error: String?)
}
