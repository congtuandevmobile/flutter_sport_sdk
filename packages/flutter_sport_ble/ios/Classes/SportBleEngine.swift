import Darwin
import Flutter
import Foundation
import SensorCore

/// What the engine tells the Flutter side (the plugin turns it into Pigeon calls on the main thread).
protocol SportBleSink: AnyObject {
    func onDeviceFound(_ device: NativeBleDevice)
    func onScanStopped()
    func onSnapshot(_ snapshot: NativeSensorSnapshot)
    func onRawPacket(_ packet: NativeRawPacket)
}

func sportBleMonotonicNowMs() -> Int64 { Int64(clock_gettime_nsec_np(CLOCK_MONOTONIC) / 1_000_000) }

/// Owns the devices and the shared `SensorHub`. Every connection event and every notification goes into the hub (it decodes,
/// validates and chooses the source per metric); the engine only keeps the connection state of each device, gives every new
/// connection a new epoch (so data of an older one is dropped), forwards the characteristics the core does not decode, and
/// publishes a snapshot about once per second and on every connection change. It never reconnects by itself and never touches
/// GPS. All state lives on `queue`.
final class SportBleEngine: BleTransportListener {
    private final class Device {
        var epoch: Int64 = 0
        var name: String?
        var connection: NativeConnection = .disconnected
        var capabilities: [NativeCapability] = []
        var error: String?
        var pending: ((Result<Void, Error>) -> Void)?
        var timeout: DispatchWorkItem?
    }

    static let scanServices = ["180d", "1814", "1816"]
    /// Subscribed to after connecting: every measurement the core decodes, plus the CSC one that is forwarded.
    static let measurements = ["2a37", "2a53", "2a5b"]
    /// Characteristics the core does not decode: their bytes go to the host.
    static let rawForwarded: Set<String> = ["2a5b"]

    let queue: DispatchQueue
    private let transport: BleTransport
    private let monotonicMs: () -> Int64
    private weak var sink: SportBleSink?
    private let hub = SensorHub.Companion.shared.standard()
    private let connectTimeout: TimeInterval
    private let snapshotEvery: TimeInterval
    private var devices: [String: Device] = [:]
    private var order: [String] = []
    private var ticker: DispatchSourceTimer?
    private var scanTimeout: DispatchWorkItem?

    init(
        transport: BleTransport, sink: SportBleSink, queue: DispatchQueue = DispatchQueue(label: "flutter_sport_ble.engine"),
        monotonicMs: @escaping () -> Int64 = sportBleMonotonicNowMs,
        connectTimeout: TimeInterval = 20, snapshotEvery: TimeInterval = 1
    ) {
        self.transport = transport
        self.sink = sink
        self.queue = queue
        self.monotonicMs = monotonicMs
        self.connectTimeout = connectTimeout
        self.snapshotEvery = snapshotEvery
        transport.listener = self
    }

    // MARK: - Lifecycle

    func start() {
        queue.async { [weak self] in
            guard let self = self, self.ticker == nil else { return }
            let timer = DispatchSource.makeTimerSource(queue: self.queue)
            timer.schedule(deadline: .now() + self.snapshotEvery, repeating: self.snapshotEvery)
            timer.setEventHandler { [weak self] in self?.publish() }
            timer.resume()
            self.ticker = timer
        }
    }

    func stop() {
        queue.sync {
            ticker?.cancel()
            ticker = nil
            scanTimeout?.cancel()
            scanTimeout = nil
        }
        transport.stopScan()
        for id in queue.sync(execute: { order }) { transport.disconnect(deviceId: id) }
    }

    func adapterState() -> NativeAdapterState { transport.adapterState() }

    /// Waits until everything queued so far ran (tests, snapshot reads).
    func flush() { queue.sync {} }

    // MARK: - Calls from the host

    func startScan(timeoutMs: Int64) {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.scanTimeout?.cancel()
            let work = DispatchWorkItem { [weak self] in
                self?.transport.stopScan()
                self?.sink?.onScanStopped()
            }
            self.scanTimeout = work
            self.queue.asyncAfter(deadline: .now() + .milliseconds(Int(timeoutMs)), execute: work)
        }
        transport.startScan(serviceShortIds: Self.scanServices)
    }

    func stopScan() {
        queue.async { [weak self] in
            self?.scanTimeout?.cancel()
            self?.scanTimeout = nil
        }
        transport.stopScan()
        queue.async { [weak self] in self?.sink?.onScanStopped() }
    }

    /// Connects; `done` runs once: when the link is up and subscribed, or when it failed.
    func connect(deviceId id: String, done: @escaping (Result<Void, Error>) -> Void) {
        queue.async { [weak self] in
            guard let self = self else { return }
            let device = self.device(id)
            if device.connection == .connected { done(.success(())); return }
            if device.connection == .connecting {
                done(.failure(SportBleError(code: "CONNECT_FAILED", message: "already connecting")))
                return
            }
            device.epoch += 1
            device.connection = .connecting
            device.error = nil
            device.pending = done
            let timeout = DispatchWorkItem { [weak self] in
                self?.failPending(id, error: "TIMEOUT: the device did not answer in time", disconnect: true)
            }
            device.timeout = timeout
            self.queue.asyncAfter(deadline: .now() + self.connectTimeout, execute: timeout)
            _ = self.hub.onConnection(sourceId: id, epoch: device.epoch, connected: false)
            self.publish()
            self.transport.connect(deviceId: id, measurementShortIds: Self.measurements)
        }
    }

    func disconnect(deviceId id: String) {
        queue.async { [weak self] in
            guard let self = self, let device = self.devices[id] else { return }
            device.timeout?.cancel()
            device.pending?(.failure(SportBleError(code: "CONNECT_FAILED", message: "cancelled")))
            device.pending = nil
            device.connection = .disconnected
            _ = self.hub.onConnection(sourceId: id, epoch: device.epoch, connected: false)
            self.transport.disconnect(deviceId: id)
            self.publish()
        }
    }

    func forget(deviceId id: String) {
        disconnect(deviceId: id)
        queue.async { [weak self] in
            guard let self = self else { return }
            self.devices[id] = nil
            self.order.removeAll { $0 == id }
            self.hub.forget(sourceId: id)
            self.publish()
        }
    }

    func setPreferred(metric: NativeMetric, deviceId: String?) {
        queue.async { [weak self] in
            self?.hub.setPreferred(metric: Self.metricType(metric), sourceId: deviceId)
        }
    }

    func snapshot() -> NativeSensorSnapshot { queue.sync { makeSnapshot() } }

    // MARK: - BleTransportListener

    func onDeviceFound(id: String, name: String?, rssi: Int, serviceShortIds: [String]) {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.sink?.onDeviceFound(NativeBleDevice(
                id: id, name: name, rssi: Int64(rssi), capabilities: self.capabilities(serviceShortIds)))
        }
    }

    func onScanFinished() {
        queue.async { [weak self] in
            self?.scanTimeout?.cancel()
            self?.scanTimeout = nil
            self?.sink?.onScanStopped()
        }
    }

    func onConnected(id: String, name: String?, serviceShortIds: [String]) {
        queue.async { [weak self] in
            guard let self = self, let device = self.devices[id], device.connection == .connecting else { return }
            device.connection = .connected
            device.name = name ?? device.name
            device.capabilities = self.capabilities(serviceShortIds)
            device.timeout?.cancel()
            let done = device.pending
            device.pending = nil
            _ = self.hub.onConnection(sourceId: id, epoch: device.epoch, connected: true)
            self.publish()
            done?(.success(()))
        }
    }

    func onNotification(id: String, characteristicShortId: String, bytes: Data) {
        // The receipt time is taken NOW, before the hop: a notification that waits in the queue keeps its time.
        let now = monotonicMs()
        queue.async { [weak self] in
            guard let self = self, let device = self.devices[id], device.connection == .connected else { return }
            let kotlinBytes = Self.kotlinBytes(bytes)
            _ = self.hub.onPacket(
                sourceId: id, epoch: device.epoch, characteristic: characteristicShortId, bytes: kotlinBytes, nowMs: now)
            if Self.rawForwarded.contains(characteristicShortId) {
                self.sink?.onRawPacket(NativeRawPacket(
                    deviceId: id, epoch: device.epoch, characteristic: characteristicShortId,
                    data: FlutterStandardTypedData(bytes: bytes), receivedAtMs: now))
            }
        }
    }

    func onDisconnected(id: String, error: String?) {
        queue.async { [weak self] in
            guard let self = self, let device = self.devices[id], device.connection != .disconnected else { return }
            device.timeout?.cancel()
            let done = device.pending
            device.pending = nil
            device.connection = error != nil ? .failed : .disconnected
            device.error = error
            _ = self.hub.onConnection(sourceId: id, epoch: device.epoch, connected: false)
            self.publish()
            done?(.failure(SportBleError(code: Self.code(of: error), message: error ?? "disconnected")))
        }
    }

    // MARK: - Internals (queue)

    private func device(_ id: String) -> Device {
        if let d = devices[id] { return d }
        let d = Device()
        devices[id] = d
        order.append(id)
        return d
    }

    private func failPending(_ id: String, error: String, disconnect: Bool) {
        guard let device = devices[id], device.connection == .connecting else { return }
        let done = device.pending
        device.pending = nil
        device.connection = .failed
        device.error = error
        _ = hub.onConnection(sourceId: id, epoch: device.epoch, connected: false)
        if disconnect { transport.disconnect(deviceId: id) }
        publish()
        done?(.failure(SportBleError(code: Self.code(of: error), message: error)))
    }

    private func publish() { sink?.onSnapshot(makeSnapshot()) }

    private func makeSnapshot() -> NativeSensorSnapshot {
        let now = monotonicMs()
        let metrics: [NativeResolvedMetric] = hub.resolve(nowMs: now).map { r in
            NativeResolvedMetric(
                metric: NativeMetric(rawValue: Int(r.metric.ordinal)) ?? .heartRate, value: r.value, sourceId: r.sourceId,
                kind: r.kind == .cumulative ? .cumulative : .instantaneous, ageMs: r.ageMs)
        }
        let states: [NativeDeviceState] = order.compactMap { id in
            guard let d = devices[id] else { return nil }
            return NativeDeviceState(
                id: id, name: d.name, connection: d.connection, epoch: d.epoch, capabilities: d.capabilities, error: d.error)
        }
        return NativeSensorSnapshot(metrics: metrics, devices: states, updatedAtMs: now)
    }

    private func capabilities(_ serviceShortIds: [String]) -> [NativeCapability] {
        Gatt.shared.capabilities(serviceUuids: serviceShortIds).compactMap { NativeCapability(rawValue: Int($0.ordinal)) }
    }

    private static func metricType(_ metric: NativeMetric) -> MetricType {
        switch metric {
        case .heartRate: return .heartRate
        case .runningSpeed: return .runningSpeed
        case .runningCadence: return .runningCadence
        case .runningStrideLength: return .runningStrideLength
        case .totalDistance: return .totalDistance
        }
    }

    private static func kotlinBytes(_ data: Data) -> KotlinByteArray {
        let array = KotlinByteArray(size: Int32(data.count))
        for (i, b) in data.enumerated() { array.set(index: Int32(i), value: Int8(bitPattern: b)) }
        return array
    }

    /// "TIMEOUT: ..." to "TIMEOUT"; anything without a stable prefix is CONNECT_FAILED.
    private static func code(of error: String?) -> String {
        guard let text = error, let colon = text.firstIndex(of: ":") else { return "CONNECT_FAILED" }
        let prefix = String(text[text.startIndex..<colon])
        let ok = (1...24).contains(prefix.count) && prefix.allSatisfy { $0.isUppercase || $0 == "_" || $0.isNumber }
        return ok ? prefix : "CONNECT_FAILED"
    }
}

/// A connect failure with a stable code (the plugin turns it into a `FlutterError`).
struct SportBleError: Error {
    let code: String
    let message: String
}
