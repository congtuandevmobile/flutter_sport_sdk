import Flutter
import Foundation

/// Flutter entry point. Thin on purpose: it forwards to the `SportBleEngine` and turns the engine's events into Pigeon calls on
/// the main thread. The Bluetooth permission prompt appears when the app first scans or connects (the host declares
/// `NSBluetoothAlwaysUsageDescription`); without it the adapter state says `unauthorized` and nothing throws.
public final class FlutterSportBlePlugin: NSObject, FlutterPlugin, SportBleHostApi, SportBleSink {
    private var engine: SportBleEngine?
    private var flutterApi: SportBleFlutterApi?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = FlutterSportBlePlugin()
        instance.flutterApi = SportBleFlutterApi(binaryMessenger: registrar.messenger())
        let engine = SportBleEngine(transport: CoreBluetoothTransport(), sink: instance)
        instance.engine = engine
        engine.start()
        SportBleHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
        registrar.publish(instance)
    }

    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        SportBleHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: nil)
        // The links belong to this engine instance: they end with it (a background-capable owner is a later phase).
        engine?.stop()
        engine = nil
        flutterApi = nil
    }

    // MARK: - SportBleHostApi

    func adapterState() throws -> NativeAdapterState { engine?.adapterState() ?? .unknown }
    func startScan(timeoutMs: Int64, allDevices: Bool) throws { engine?.startScan(timeoutMs: timeoutMs, allDevices: allDevices) }
    func stopScan() throws { engine?.stopScan() }

    func connect(deviceId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let engine = engine else {
            completion(.failure(PigeonError(code: "DETACHED", message: "the plugin is detached", details: nil)))
            return
        }
        engine.connect(deviceId: deviceId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success: completion(.success(()))
                case .failure(let error):
                    let e = error as? SportBleError
                    completion(.failure(PigeonError(
                        code: e?.code ?? "CONNECT_FAILED", message: e?.message ?? error.localizedDescription, details: nil)))
                }
            }
        }
    }

    func disconnect(deviceId: String) throws { engine?.disconnect(deviceId: deviceId) }
    func forget(deviceId: String) throws { engine?.forget(deviceId: deviceId) }
    func setPreferredSource(metric: NativeMetric, deviceId: String?) throws {
        engine?.setPreferred(metric: metric, deviceId: deviceId)
    }
    func setWheelCircumference(deviceId: String, metres: Double?) throws {
        engine?.setWheelCircumference(deviceId: deviceId, metres: metres)
    }
    func snapshot() throws -> NativeSensorSnapshot {
        engine?.snapshot() ?? NativeSensorSnapshot(metrics: [], devices: [], updatedAtMs: 0)
    }

    // MARK: - SportBleSink (called from the engine queue; Flutter wants the main thread)

    func onDeviceFound(_ device: NativeBleDevice) {
        DispatchQueue.main.async { [weak self] in self?.flutterApi?.onDeviceFound(device: device) { _ in } }
    }

    func onScanStopped() {
        DispatchQueue.main.async { [weak self] in self?.flutterApi?.onScanStopped { _ in } }
    }

    func onSnapshot(_ snapshot: NativeSensorSnapshot) {
        DispatchQueue.main.async { [weak self] in self?.flutterApi?.onSnapshot(snapshot: snapshot) { _ in } }
    }

    func onRawPacket(_ packet: NativeRawPacket) {
        DispatchQueue.main.async { [weak self] in self?.flutterApi?.onRawPacket(packet: packet) { _ in } }
    }
}
