import CoreBluetooth
import Foundation
import SensorCore

/// The real radio: one `CBCentralManager` (created on first use, so that the Bluetooth permission prompt appears when the app
/// scans or connects, never at launch) and one `CBPeripheral` per device. Every delegate callback runs on `queue`. A permission
/// or adapter problem is reported as an error string, never thrown. Not unit-tested (it needs a radio); the engine above it is.
final class CoreBluetoothTransport: NSObject, BleTransport, CBCentralManagerDelegate, CBPeripheralDelegate {
    weak var listener: BleTransportListener?

    private final class Link {
        let peripheral: CBPeripheral
        let wanted: Set<String>
        var awaiting = 0
        var discoveringServices = 0
        var announced = false
        init(peripheral: CBPeripheral, wanted: Set<String>) {
            self.peripheral = peripheral
            self.wanted = wanted
        }
    }

    private let queue = DispatchQueue(label: "flutter_sport_ble.radio")
    private var central: CBCentralManager?
    private var known: [String: CBPeripheral] = [:]
    private var links: [String: Link] = [:]
    private var pendingScan: [CBUUID]?
    private var pendingConnects: [(String, [String])] = []
    private var scanning = false

    // MARK: - BleTransport

    func adapterState() -> NativeAdapterState {
        if let central = central {
            switch central.state {
            case .unsupported: return .unsupported
            case .unauthorized: return .unauthorized
            case .poweredOff: return .poweredOff
            case .poweredOn: return .ready
            default: return .unknown
            }
        }
        // Asking must not show the permission prompt: read the authorization without creating the manager.
        switch CBManager.authorization {
        case .denied, .restricted: return .unauthorized
        default: return .unknown
        }
    }

    func startScan(serviceShortIds: [String]) {
        queue.async { [weak self] in
            guard let self = self else { return }
            let services = serviceShortIds.map { CBUUID(string: $0) }
            let central = self.ensureCentral()
            guard central.state == .poweredOn else {
                self.pendingScan = services
                return
            }
            self.beginScan(central, services)
        }
    }

    func stopScan() {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.pendingScan = nil
            if self.scanning { self.central?.stopScan() }
            self.scanning = false
        }
    }

    func connect(deviceId: String, measurementShortIds: [String]) {
        queue.async { [weak self] in
            guard let self = self else { return }
            let central = self.ensureCentral()
            guard central.state == .poweredOn else {
                self.pendingConnects.append((deviceId, measurementShortIds))
                return
            }
            self.openLink(central, deviceId, measurementShortIds)
        }
    }

    func disconnect(deviceId: String) {
        queue.async { [weak self] in
            guard let self = self, let link = self.links.removeValue(forKey: deviceId) else { return }
            self.central?.cancelPeripheralConnection(link.peripheral)
        }
    }

    // MARK: - Internals (queue)

    private func ensureCentral() -> CBCentralManager {
        if let central = central { return central }
        let created = CBCentralManager(delegate: self, queue: queue)
        central = created
        return created
    }

    private func beginScan(_ central: CBCentralManager, _ services: [CBUUID]) {
        scanning = true
        central.scanForPeripherals(withServices: services, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }

    private func openLink(_ central: CBCentralManager, _ id: String, _ measurements: [String]) {
        guard let uuid = UUID(uuidString: id) else {
            listener?.onDisconnected(id: id, error: "BAD_DEVICE: not a device id")
            return
        }
        let peripheral = known[id] ?? central.retrievePeripherals(withIdentifiers: [uuid]).first
        guard let peripheral = peripheral else {
            listener?.onDisconnected(id: id, error: "BAD_DEVICE: the device is not known to this phone, scan first")
            return
        }
        known[id] = peripheral
        peripheral.delegate = self
        links[id] = Link(peripheral: peripheral, wanted: Set(measurements))
        central.connect(peripheral, options: nil)
    }

    private func end(_ id: String, error: String?) {
        if let link = links.removeValue(forKey: id) { central?.cancelPeripheralConnection(link.peripheral) }
        listener?.onDisconnected(id: id, error: error)
    }

    private func announceIfDone(_ id: String, _ link: Link) {
        guard !link.announced, link.discoveringServices == 0, link.awaiting == 0 else { return }
        link.announced = true
        let services = (link.peripheral.services ?? []).map { Gatt.shared.short(uuid: $0.uuid.uuidString) }
        listener?.onConnected(id: id, name: link.peripheral.name, serviceShortIds: services)
    }

    // MARK: - CBCentralManagerDelegate

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            if let services = pendingScan {
                pendingScan = nil
                beginScan(central, services)
            }
            let connects = pendingConnects
            pendingConnects = []
            for (id, measurements) in connects { openLink(central, id, measurements) }
            return
        }
        scanning = false
        let message: String
        switch central.state {
        case .unauthorized: message = "PERMISSION: Bluetooth is not allowed for this app"
        case .unsupported: message = "UNSUPPORTED: this device has no Bluetooth LE"
        default: message = "BLUETOOTH_OFF: Bluetooth is off"
        }
        for (id, _) in pendingConnects { listener?.onDisconnected(id: id, error: message) }
        pendingConnects = []
        for id in Array(links.keys) { end(id, error: message) }
        if pendingScan != nil {
            pendingScan = nil
            listener?.onScanFinished()
        }
    }

    func centralManager(
        _ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber
    ) {
        let id = peripheral.identifier.uuidString
        known[id] = peripheral
        let advertised = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? [])
            .map { Gatt.shared.short(uuid: $0.uuidString) }
        let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? peripheral.name
        listener?.onDeviceFound(id: id, name: name, rssi: RSSI.intValue, serviceShortIds: advertised)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        end(peripheral.identifier.uuidString, error: "GATT: \(error?.localizedDescription ?? "could not connect")")
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        let id = peripheral.identifier.uuidString
        guard links.removeValue(forKey: id) != nil else { return } // a disconnect the engine asked for was already reported
        listener?.onDisconnected(id: id, error: error.map { "GATT: \($0.localizedDescription)" })
    }

    // MARK: - CBPeripheralDelegate

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        let id = peripheral.identifier.uuidString
        guard let link = links[id] else { return }
        if let error = error { end(id, error: "GATT: \(error.localizedDescription)"); return }
        for service in peripheral.services ?? [] {
            link.discoveringServices += 1
            peripheral.discoverCharacteristics(nil, for: service)
        }
        if link.discoveringServices == 0 { announceIfDone(id, link) }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        let id = peripheral.identifier.uuidString
        guard let link = links[id] else { return }
        link.discoveringServices -= 1
        if let error = error { end(id, error: "GATT: \(error.localizedDescription)"); return }
        for c in service.characteristics ?? [] where link.wanted.contains(Gatt.shared.short(uuid: c.uuid.uuidString)) {
            link.awaiting += 1
            peripheral.setNotifyValue(true, for: c)
        }
        announceIfDone(id, link)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        let id = peripheral.identifier.uuidString
        guard let link = links[id] else { return }
        link.awaiting -= 1
        if let error = error { end(id, error: "GATT: \(error.localizedDescription)"); return }
        announceIfDone(id, link)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil, let value = characteristic.value else { return }
        let id = peripheral.identifier.uuidString
        guard links[id] != nil else { return }
        listener?.onNotification(id: id, characteristicShortId: Gatt.shared.short(uuid: characteristic.uuid.uuidString), bytes: value)
    }
}
