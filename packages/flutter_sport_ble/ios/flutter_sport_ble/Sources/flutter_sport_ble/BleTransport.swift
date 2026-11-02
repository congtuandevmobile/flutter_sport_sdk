import Foundation

/// The radio, as the engine sees it: scan, connect, and a stream of what the connected devices say. It knows nothing about what
/// the bytes mean (the shared core decodes them) and nothing about Flutter, so the engine can be tested with a fake.
protocol BleTransport: AnyObject {
    var listener: BleTransportListener? { get set }

    func adapterState() -> NativeAdapterState

    /// Starts a scan for devices that advertise one of `serviceShortIds` (4 lowercase hex digits); nil scans EVERY BLE device.
    func startScan(serviceShortIds: [String]?)
    func stopScan()

    /// Connects, discovers the services, subscribes to the characteristics of `notify` that the device has and, after `onReady`,
    /// reads once the ones of `read` that it has (their value comes through `onNotification`).
    func connect(deviceId: String, notify: [String], read: [String])
    func disconnect(deviceId: String)
}

/// Every callback may come from any thread: the engine hops to its own queue.
protocol BleTransportListener: AnyObject {
    func onDeviceFound(id: String, name: String?, rssi: Int, serviceShortIds: [String])
    func onScanFinished()

    /// The link is up; the services are being discovered.
    func onGattConnected(id: String)

    /// The services are known; the subscriptions start.
    func onServicesDiscovered(id: String, name: String?, serviceShortIds: [String])

    /// Every subscription was tried: `subscribed` notify now, `failed` are characteristics the device has but that could not be
    /// subscribed. Both may be empty: that is "connected, not usable".
    func onReady(id: String, subscribed: [String], failed: [String])

    /// A notification (or a read) of a characteristic (`characteristicShortId` is 4 lowercase hex digits).
    func onNotification(id: String, characteristicShortId: String, bytes: Data)

    /// The link ended or could not be made; `error` is nil for a disconnect the engine asked for.
    func onDisconnected(id: String, error: String?)
}
