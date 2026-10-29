import Flutter
import SensorCore
import XCTest

@testable import flutter_sport_ble

private final class FakeTransport: BleTransport {
    weak var listener: BleTransportListener?
    var state: NativeAdapterState = .ready
    var connects: [String] = []
    var disconnects: [String] = []
    var scans = 0
    var scanStops = 0
    var lastScanServices: [String]? = []
    var lastNotify: [String] = []
    var lastRead: [String] = []
    func adapterState() -> NativeAdapterState { state }
    func startScan(serviceShortIds: [String]?) { scans += 1; lastScanServices = serviceShortIds }
    func stopScan() { scanStops += 1 }
    func connect(deviceId: String, notify: [String], read: [String]) {
        connects.append(deviceId); lastNotify = notify; lastRead = read
    }
    func disconnect(deviceId: String) { disconnects.append(deviceId) }
}

private final class RecordingSink: SportBleSink {
    var devices: [NativeBleDevice] = []
    var snapshots: [NativeSensorSnapshot] = []
    var raw: [NativeRawPacket] = []
    var scanStopped = 0
    func onDeviceFound(_ device: NativeBleDevice) { devices.append(device) }
    func onScanStopped() { scanStopped += 1 }
    func onSnapshot(_ snapshot: NativeSensorSnapshot) { snapshots.append(snapshot) }
    func onRawPacket(_ packet: NativeRawPacket) { raw.append(packet) }
}

final class RunnerTests: XCTestCase {
    private var clock: Int64 = 0
    private let transport = FakeTransport()
    private let sink = RecordingSink()

    private func makeEngine(connectTimeout: TimeInterval = 20, snapshotEvery: TimeInterval = 1) -> SportBleEngine {
        SportBleEngine(
            transport: transport, sink: sink, monotonicMs: { self.clock },
            connectTimeout: connectTimeout, snapshotEvery: snapshotEvery)
    }

    /// A device that connects, discovers `services` and subscribes to `subscribed` (by default the measurement of each service).
    @discardableResult
    private func link(
        _ e: SportBleEngine, _ id: String, _ services: [String], subscribed: [String]? = nil, failed: [String] = []
    ) -> Result<Void, Error>? {
        var result: Result<Void, Error>?
        e.connect(deviceId: id) { result = $0 }
        e.flush()
        e.onGattConnected(id: id)
        e.onServicesDiscovered(id: id, name: "dev-\(id)", serviceShortIds: services)
        let defaults: [String: String] = ["180d": "2a37", "1814": "2a53", "1816": "2a5b", "1818": "2a63", "1826": "2ad2"]
        e.onReady(id: id, subscribed: subscribed ?? services.compactMap { defaults[$0] }, failed: failed)
        e.flush()
        return result
    }

    private func hr(_ e: SportBleEngine, _ id: String, _ bpm: UInt8, at ms: Int64) {
        clock = ms
        e.onNotification(id: id, characteristicShortId: "2a37", bytes: Data([0x00, bpm]))
        e.flush()
    }

    private func metric(_ s: NativeSensorSnapshot, _ m: NativeMetric) -> NativeResolvedMetric? {
        s.metrics.first { $0.metric == m }
    }

    func testScanForwardsDevicesWithTheirCapabilities() {
        let e = makeEngine()
        e.startScan(timeoutMs: 10_000, allDevices: false)
        e.flush()
        e.onDeviceFound(id: "A", name: "Strap", rssi: -60, serviceShortIds: ["180d", "180f"])
        e.flush()
        XCTAssertEqual(sink.devices.first?.id, "A")
        XCTAssertEqual(sink.devices.first?.capabilities, [.heartRate, .battery])
        XCTAssertEqual(transport.scans, 1)
    }

    func testAScanStopsByItselfAfterItsTimeout() {
        let e = makeEngine()
        e.startScan(timeoutMs: 50, allDevices: false)
        let stopped = expectation(description: "scan stopped")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.4) { e.flush(); stopped.fulfill() }
        wait(for: [stopped], timeout: 3)
        XCTAssertEqual(transport.scanStops, 1)
        XCTAssertEqual(sink.scanStopped, 1)
    }

    func testConnectCompletesWhenTheLinkIsUpAndTheStateSaysSo() {
        let e = makeEngine()
        guard case .success? = link(e, "A", ["180d"]) else { return XCTFail("connect did not succeed") }
        XCTAssertEqual(transport.connects, ["A"])
        let state = e.snapshot().devices.first
        XCTAssertEqual(state?.connection, .ready)
        XCTAssertEqual(state?.epoch, 1)
        XCTAssertEqual(state?.capabilities, [.heartRate])
    }

    func testHeartRateFromTheStrapAppearsOnceItIsHealthy() {
        let e = makeEngine()
        link(e, "strap", ["180d"])
        hr(e, "strap", 145, at: 0)
        XCTAssertNil(metric(e.snapshot(), .heartRate))
        hr(e, "strap", 146, at: 1000)
        let m = metric(e.snapshot(), .heartRate)
        XCTAssertEqual(m?.value, 146)
        XCTAssertEqual(m?.sourceId, "strap")
    }

    func testTwoDevicesGiveTwoMetricsAndALostOneDoesNotTakeTheOtherDown() {
        let e = makeEngine()
        link(e, "strap", ["180d"])
        link(e, "foot", ["1814"])
        hr(e, "strap", 145, at: 0)
        hr(e, "strap", 146, at: 1000)
        clock = 0
        e.onNotification(id: "foot", characteristicShortId: "2a53", bytes: Data([0x00, 0xD0, 0x02, 170]))
        clock = 1000
        e.onNotification(id: "foot", characteristicShortId: "2a53", bytes: Data([0x00, 0xD0, 0x02, 171]))
        e.flush()
        var s = e.snapshot()
        XCTAssertEqual(metric(s, .heartRate)?.value, 146)
        XCTAssertEqual(metric(s, .runningCadence)?.value, 171)
        XCTAssertEqual(metric(s, .runningSpeed)?.value ?? 0, 2.8125, accuracy: 1e-9)
        e.onDisconnected(id: "strap", error: "GATT_8: link lost")
        e.flush()
        s = e.snapshot()
        XCTAssertNil(metric(s, .heartRate))
        XCTAssertEqual(metric(s, .runningCadence)?.value, 171)
        let strap = s.devices.first { $0.id == "strap" }
        XCTAssertEqual(strap?.connection, .failed)
        XCTAssertEqual(strap?.error, "GATT_8: link lost")
    }

    func testAReconnectIsANewEpochAndOldDataIsNotMixed() {
        let e = makeEngine()
        link(e, "strap", ["180d"])
        hr(e, "strap", 145, at: 0)
        hr(e, "strap", 146, at: 1000)
        e.onDisconnected(id: "strap", error: nil)
        e.flush()
        link(e, "strap", ["180d"])
        XCTAssertEqual(e.snapshot().devices.first?.epoch, 2)
        XCTAssertNil(metric(e.snapshot(), .heartRate), "the new connection earns its place again")
        hr(e, "strap", 150, at: 2000)
        hr(e, "strap", 151, at: 3000)
        XCTAssertEqual(metric(e.snapshot(), .heartRate)?.value, 151)
    }

    func testNotificationsOfADeviceThatIsNotConnectedAreDropped() {
        let e = makeEngine()
        e.onNotification(id: "ghost", characteristicShortId: "2a37", bytes: Data([0x00, 100]))
        e.connect(deviceId: "A") { _ in }
        e.flush()
        e.onNotification(id: "A", characteristicShortId: "2a37", bytes: Data([0x00, 100])) // still connecting
        e.flush()
        XCTAssertNil(metric(e.snapshot(), .heartRate))
    }

    func testTheCyclingCadencePacketIsForwardedRawWithItsEpoch() {
        let e = makeEngine()
        link(e, "bike", ["1816"])
        clock = 500
        e.onNotification(id: "bike", characteristicShortId: "2a5b", bytes: Data([0x02, 1, 0, 1, 0]))
        e.flush()
        XCTAssertEqual(sink.raw.count, 1)
        XCTAssertEqual(sink.raw.first?.deviceId, "bike")
        XCTAssertEqual(sink.raw.first?.characteristic, "2a5b")
        XCTAssertEqual(sink.raw.first?.epoch, 1)
        XCTAssertEqual(sink.raw.first?.receivedAtMs, 500)
        XCTAssertEqual(sink.raw.first?.data.data.count, 5)
        e.onNotification(id: "bike", characteristicShortId: "2a37", bytes: Data([0x00, 100]))
        e.flush()
        XCTAssertEqual(sink.raw.count, 1, "a characteristic the core decodes is not forwarded")
    }

    func testAFailedConnectFailsTheCallAndKeepsTheReason() {
        let e = makeEngine()
        var done: Result<Void, Error>?
        e.connect(deviceId: "A") { done = $0 }
        e.flush()
        e.onDisconnected(id: "A", error: "PERMISSION: not allowed")
        e.flush()
        guard case .failure(let error)? = done, let failure = error as? SportBleError else { return XCTFail("expected a failure") }
        XCTAssertEqual(failure.code, "PERMISSION")
        let state = e.snapshot().devices.first
        XCTAssertEqual(state?.connection, .failed)
        XCTAssertEqual(state?.error, "PERMISSION: not allowed")
    }

    func testADeviceThatNeverAnswersTimesOut() {
        let e = makeEngine(connectTimeout: 0.05)
        let finished = expectation(description: "connect failed")
        var done: Result<Void, Error>?
        e.connect(deviceId: "A") { done = $0; finished.fulfill() }
        wait(for: [finished], timeout: 3)
        guard case .failure(let error)? = done, let failure = error as? SportBleError else { return XCTFail("expected a failure") }
        XCTAssertEqual(failure.code, "TIMEOUT")
        XCTAssertEqual(e.snapshot().devices.first?.connection, .failed)
        XCTAssertEqual(transport.disconnects, ["A"])
    }

    func testConnectingTwiceIsRefusedWhileConnectingAndAnswersAtOnceWhenUp() {
        let e = makeEngine()
        e.connect(deviceId: "A") { _ in }
        var second: Result<Void, Error>?
        e.connect(deviceId: "A") { second = $0 }
        e.flush()
        guard case .failure? = second else { return XCTFail("expected a failure") }
        e.onGattConnected(id: "A")
        e.onServicesDiscovered(id: "A", name: nil, serviceShortIds: ["180d"])
        e.onReady(id: "A", subscribed: ["2a37"], failed: [])
        e.flush()
        var third: Result<Void, Error>?
        e.connect(deviceId: "A") { third = $0 }
        e.flush()
        guard case .success? = third else { return XCTFail("expected success") }
        XCTAssertEqual(transport.connects, ["A"])
    }

    func testDisconnectAndForgetDropTheDeviceAndItsValues() {
        let e = makeEngine()
        link(e, "strap", ["180d"])
        hr(e, "strap", 145, at: 0)
        hr(e, "strap", 146, at: 1000)
        e.disconnect(deviceId: "strap")
        e.flush()
        XCTAssertEqual(e.snapshot().devices.first?.connection, .disconnected)
        XCTAssertNil(metric(e.snapshot(), .heartRate))
        e.forget(deviceId: "strap")
        e.flush()
        XCTAssertTrue(e.snapshot().devices.isEmpty)
        XCTAssertEqual(transport.disconnects, ["strap", "strap"])
    }

    func testThePreferredSourceWinsWhileItIsHealthy() {
        let e = makeEngine()
        link(e, "strap", ["180d"])
        link(e, "watch", ["180d"])
        for t: Int64 in [0, 1000] { hr(e, "strap", 145, at: t); hr(e, "watch", 141, at: t) }
        XCTAssertEqual(metric(e.snapshot(), .heartRate)?.sourceId, "strap")
        e.setPreferred(metric: .heartRate, deviceId: "watch")
        XCTAssertEqual(metric(e.snapshot(), .heartRate)?.sourceId, "watch")
    }

    func testSilenceMakesAMetricUnknownNotStale() {
        let e = makeEngine()
        link(e, "strap", ["180d"])
        hr(e, "strap", 145, at: 0)
        hr(e, "strap", 146, at: 1000)
        clock = 7000
        XCTAssertNil(metric(e.snapshot(), .heartRate))
    }

    func testTheSnapshotIsPublishedPeriodically() {
        let e = makeEngine(snapshotEvery: 0.05)
        e.start()
        let waited = expectation(description: "ticks")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.4) { waited.fulfill() }
        wait(for: [waited], timeout: 3)
        e.stop()
        e.flush()
        XCTAssertGreaterThanOrEqual(sink.snapshots.count, 3)
    }

    // MARK: - wave 0

    func testScanCanLookAtEveryBleDeviceOrOnlyAtTheServicesOfTheRegistry() {
        let e = makeEngine()
        e.startScan(timeoutMs: 5_000, allDevices: false)
        e.flush()
        XCTAssertEqual(transport.lastScanServices ?? [], ["180d", "1814", "1816", "1818", "1826"])
        e.startScan(timeoutMs: 5_000, allDevices: true)
        e.flush()
        XCTAssertNil(transport.lastScanServices, "nil means every BLE device")
    }

    func testConnectUsesTheRegistryForWhatToSubscribeAndRead() {
        let e = makeEngine()
        e.connect(deviceId: "A") { _ in }
        e.flush()
        for c in ["2a37", "2a53", "2a5b", "2a63", "2ad2"] { XCTAssertTrue(transport.lastNotify.contains(c), c) }
        for c in ["2a19", "2a29"] { XCTAssertTrue(transport.lastRead.contains(c), c) }
    }

    func testTheStatesGoThroughDiscoveringAndSubscribingBeforeReady() {
        let e = makeEngine()
        e.connect(deviceId: "A") { _ in }
        e.flush()
        XCTAssertEqual(e.snapshot().devices.first?.connection, .connecting)
        e.onGattConnected(id: "A"); e.flush()
        XCTAssertEqual(e.snapshot().devices.first?.connection, .discovering)
        e.onServicesDiscovered(id: "A", name: "Strap", serviceShortIds: ["180d"]); e.flush()
        XCTAssertEqual(e.snapshot().devices.first?.connection, .subscribing)
        e.onReady(id: "A", subscribed: ["2a37"], failed: []); e.flush()
        let d = e.snapshot().devices.first
        XCTAssertEqual(d?.connection, .ready)
        XCTAssertEqual(d?.discoveredServices, ["180d"])
        XCTAssertEqual(d?.subscribedCharacteristics, ["2a37"])
    }

    func testAConnectionWithoutAWorkoutMeasurementIsNotReadyAndSaysWhy() {
        let e = makeEngine()
        let r = link(e, "A", ["180f", "180a"], subscribed: ["2a19"])
        guard case .failure(let error)? = r, let failure = error as? SportBleError else { return XCTFail("expected a failure") }
        XCTAssertEqual(failure.code, "NOT_SUPPORTED")
        let d = e.snapshot().devices.first
        XCTAssertEqual(d?.connection, .notSupported)
        XCTAssertEqual(d?.capabilities, [.battery, .deviceInformation])
        XCTAssertEqual(transport.disconnects, ["A"], "the useless link is closed")
    }

    func testASubscriptionThatFailedIsReportedAndNeverSilentlySkipped() {
        let e = makeEngine()
        let none = link(e, "A", ["180d"], subscribed: [], failed: ["2a37"])
        guard case .failure? = none else { return XCTFail("expected a failure") }
        XCTAssertTrue(e.snapshot().devices.first { $0.id == "A" }?.error?.contains("2a37") == true)
        let some = link(e, "B", ["1814", "180d"], subscribed: ["2a53"], failed: ["2a37"])
        guard case .success? = some else { return XCTFail("expected success") }
        let b = e.snapshot().devices.first { $0.id == "B" }
        XCTAssertEqual(b?.connection, .ready)
        XCTAssertEqual(b?.error?.hasPrefix("PARTIAL"), true)
    }

    func testAStaleNotificationDuringANewAttemptIsDropped() {
        let e = makeEngine()
        link(e, "strap", ["180d"])
        hr(e, "strap", 145, at: 0)
        hr(e, "strap", 146, at: 1000)
        e.onDisconnected(id: "strap", error: nil); e.flush()
        e.connect(deviceId: "strap") { _ in }; e.flush()
        e.onNotification(id: "strap", characteristicShortId: "2a37", bytes: Data([0x00, 190])); e.flush()
        e.onGattConnected(id: "strap")
        e.onServicesDiscovered(id: "strap", name: nil, serviceShortIds: ["180d"])
        e.onReady(id: "strap", subscribed: ["2a37"], failed: [])
        e.flush()
        XCTAssertNil(metric(e.snapshot(), .heartRate))
        XCTAssertEqual(e.snapshot().devices.first?.epoch, 2)
    }

    func testADeviceThatIsNotSupportedDoesNotBlockAnother() {
        let e = makeEngine()
        link(e, "battery-only", ["180f"], subscribed: ["2a19"])
        link(e, "strap", ["180d"])
        hr(e, "strap", 145, at: 0)
        hr(e, "strap", 146, at: 1000)
        let s = e.snapshot()
        XCTAssertEqual(metric(s, .heartRate)?.value, 146)
        XCTAssertEqual(s.devices.first { $0.id == "battery-only" }?.connection, .notSupported)
        XCTAssertEqual(s.devices.first { $0.id == "strap" }?.connection, .ready)
    }

    func testBatteryDeviceInformationAndRrIntervalsReachTheSnapshot() {
        let e = makeEngine()
        link(e, "strap", ["180d", "180f", "180a"], subscribed: ["2a37", "2a19"])
        e.onNotification(id: "strap", characteristicShortId: "2a19", bytes: Data([82]))
        e.onNotification(id: "strap", characteristicShortId: "2a29", bytes: Data("Polar".utf8))
        e.onNotification(id: "strap", characteristicShortId: "2a24", bytes: Data("H10".utf8))
        e.onNotification(id: "strap", characteristicShortId: "2a26", bytes: Data("3.0.35".utf8))
        e.onNotification(id: "strap", characteristicShortId: "2a37", bytes: Data([0x16, 70, 0x00, 0x04, 0x00, 0x02]))
        e.flush()
        let d = e.snapshot().devices.first
        XCTAssertEqual(d?.batteryPercent, 82)
        XCTAssertEqual(d?.manufacturer, "Polar")
        XCTAssertEqual(d?.model, "H10")
        XCTAssertEqual(d?.firmware, "3.0.35")
        XCTAssertEqual(d?.recentRrMs, [1000, 500])
    }

    func testTheWheelCircumferenceTurnsWheelRevolutionsIntoSpeed() {
        let e = makeEngine()
        link(e, "wheel", ["1816"])
        e.setWheelCircumference(deviceId: "wheel", metres: 2.1)
        e.flush()
        for (i, count) in [1000, 1002, 1004, 1006].enumerated() {
            clock = Int64(i) * 1000
            let ticks = i * 1024
            e.onNotification(
                id: "wheel", characteristicShortId: "2a5b",
                bytes: Data([0x01, UInt8(count & 0xFF), UInt8(count >> 8), 0, 0, UInt8(ticks & 0xFF), UInt8(ticks >> 8)]))
            e.flush()
        }
        XCTAssertEqual(metric(e.snapshot(), .cyclingSpeed)?.value ?? 0, 4.2, accuracy: 1e-6)
    }

    func testEveryMetricOfTheCoreHasItsPigeonTwinWithTheSameOrder() {
        // the engine maps metrics by ordinal: a drift between the two enums must fail here
        XCTAssertEqual(MetricType.values().size, Int32(NativeMetric.floors.rawValue + 1))
        XCTAssertEqual(Capability.values().size, Int32(NativeCapability.deviceInformation.rawValue + 1))
        XCTAssertEqual(MetricType.cyclingCadence.ordinal, Int32(NativeMetric.cyclingCadence.rawValue))
        XCTAssertEqual(MetricType.floors.ordinal, Int32(NativeMetric.floors.rawValue))
    }

    /// The Pigeon enums mirror the core's by ORDER (the iOS engine maps by ordinal): a drift must fail here.
    func testEveryMetricAndCapabilityKeepsItsMeaningAcrossTheCoreBoundary() {
        let e = makeEngine()
        link(e, "foot", ["180d", "1814", "1816", "1818", "1826", "180f", "180a"])
        XCTAssertEqual(
            e.snapshot().devices.first?.capabilities,
            [.heartRate, .runningSpeedCadence, .cyclingSpeedCadence, .cyclingPower, .fitnessMachine, .battery, .deviceInformation])
        // flags 0x07: stride + total distance + running; speed 2.8125 m/s, cadence 170, stride 0.99 m, total 4000.0 m
        let packet = Data([0x07, 0xD0, 0x02, 170, 0x63, 0x00, 0x40, 0x9C, 0x00, 0x00])
        for t: Int64 in [0, 1000] {
            clock = t
            e.onNotification(id: "foot", characteristicShortId: "2a53", bytes: packet)
            e.flush()
        }
        let s = e.snapshot()
        XCTAssertEqual(metric(s, .runningSpeed)?.value ?? 0, 2.8125, accuracy: 1e-9)
        XCTAssertEqual(metric(s, .runningCadence)?.value, 170)
        XCTAssertEqual(metric(s, .runningStrideLength)?.value ?? 0, 0.99, accuracy: 1e-9)
        XCTAssertEqual(metric(s, .totalDistance)?.value ?? 0, 4000.0, accuracy: 1e-9)
        XCTAssertEqual(metric(s, .totalDistance)?.kind, .cumulative)
        XCTAssertEqual(metric(s, .runningCadence)?.kind, .instantaneous)
    }

    func testTheAdapterStateIsTheTransportsAndBluetoothOffNeverThrows() {
        let e = makeEngine()
        transport.state = .poweredOff
        XCTAssertEqual(e.adapterState(), .poweredOff)
    }
}
