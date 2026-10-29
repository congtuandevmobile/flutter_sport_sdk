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
        let notify: Set<String>
        let read: Set<String>
        var awaiting = 0
        var discoveringServices = 0
        var announced = false
        var subscribed: [String] = []
        var failed: [String] = []
        var toRead: [CBCharacteristic] = []
        var reading: CBCharacteristic?
        init(peripheral: CBPeripheral, notify: Set<String>, read: Set<String>) {
            self.peripheral = peripheral
            self.notify = notify
            self.read = read
        }
    }

    private let queue = DispatchQueue(label: "flutter_sport_ble.radio")
    private var central: CBCentralManager?
    private var known: [String: CBPeripheral] = [:]
    private var links: [String: Link] = [:]
    private var pendingScan: [CBUUID]??
    private var pendingConnects: [(String, [String], [String])] = []
    private var scanning = false
    /// Links we asked CoreBluetooth to cancel and whose `didDisconnect` has not come yet: a new connect to the same device waits
    /// for it, so a callback of the OLD link can never be taken for the new one.
    private var cancelling: Set<String> = []
    private var deferredConnects: [String: ([String], [String])] = [:]

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

    func startScan(serviceShortIds: [String]?) {
        queue.async { [weak self] in
            guard let self = self else { return }
            let services = serviceShortIds?.map { CBUUID(string: $0) } // nil: every BLE device
            let central = self.ensureCentral()
            guard central.state == .poweredOn else {
                self.pendingScan = .some(services)
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

    func connect(deviceId: String, notify: [String], read: [String]) {
        queue.async { [weak self] in
            guard let self = self else { return }
            let central = self.ensureCentral()
            guard central.state == .poweredOn else {
                self.pendingConnects.append((deviceId, notify, read))
                return
            }
            if self.cancelling.contains(deviceId) {
                self.deferredConnects[deviceId] = (notify, read)
                return
            }
            self.openLink(central, deviceId, notify, read)
        }
    }

    func disconnect(deviceId: String) {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.deferredConnects[deviceId] = nil
            guard let link = self.links.removeValue(forKey: deviceId) else { return }
            self.cancelling.insert(deviceId)
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

    private func beginScan(_ central: CBCentralManager, _ services: [CBUUID]?) {
        scanning = true
        central.scanForPeripherals(withServices: services, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }

    private func openLink(_ central: CBCentralManager, _ id: String, _ notify: [String], _ read: [String]) {
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
        links[id] = Link(peripheral: peripheral, notify: Set(notify), read: Set(read))
        central.connect(peripheral, options: nil)
    }

    private func end(_ id: String, error: String?) {
        if let link = links.removeValue(forKey: id) {
            cancelling.insert(id)
            central?.cancelPeripheralConnection(link.peripheral)
        }
        listener?.onDisconnected(id: id, error: error)
    }

    /// The link we cancelled is really gone: a connect that waited for it can start now.
    private func cancelled(_ id: String) {
        cancelling.remove(id)
        if let (notify, read) = deferredConnects.removeValue(forKey: id), let central = central {
            openLink(central, id, notify, read)
        }
    }

    private func announceIfDone(_ id: String, _ link: Link) {
        guard !link.announced, link.discoveringServices == 0, link.awaiting == 0 else { return }
        link.announced = true
        listener?.onReady(id: id, subscribed: link.subscribed, failed: link.failed)
        readNext(link)
    }

    /// Reads once the characteristics worth reading (battery, device information), one after the other.
    private func readNext(_ link: Link) {
        guard link.reading == nil, !link.toRead.isEmpty else { return }
        let next = link.toRead.removeFirst()
        link.reading = next
        link.peripheral.readValue(for: next)
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
            for (id, notify, read) in connects { openLink(central, id, notify, read) }
            return
        }
        scanning = false
        let message: String
        switch central.state {
        case .unauthorized: message = "PERMISSION: Bluetooth is not allowed for this app"
        case .unsupported: message = "UNSUPPORTED: this device has no Bluetooth LE"
        default: message = "BLUETOOTH_OFF: Bluetooth is off"
        }
        for (id, _, _) in pendingConnects { listener?.onDisconnected(id: id, error: message) }
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
        let id = peripheral.identifier.uuidString
        guard links[id]?.peripheral === peripheral else { return }
        listener?.onGattConnected(id: id)
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        let id = peripheral.identifier.uuidString
        if cancelling.contains(id) { cancelled(id); return }
        guard links[id]?.peripheral === peripheral else { return }
        end(id, error: "GATT: \(error?.localizedDescription ?? "could not connect")")
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        let id = peripheral.identifier.uuidString
        // A disconnect we asked for (or the end of a link we already reported) belongs to the OLD link: it is never taken for
        // the new attempt that may already exist.
        if cancelling.contains(id) { cancelled(id); return }
        guard links[id]?.peripheral === peripheral, links.removeValue(forKey: id) != nil else { return }
        listener?.onDisconnected(id: id, error: error.map { "GATT: \($0.localizedDescription)" })
    }

    // MARK: - CBPeripheralDelegate

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        let id = peripheral.identifier.uuidString
        guard let link = links[id] else { return }
        if let error = error { end(id, error: "GATT: \(error.localizedDescription)"); return }
        let services = (peripheral.services ?? []).map { Gatt.shared.short(uuid: $0.uuid.uuidString) }
        listener?.onServicesDiscovered(id: id, name: peripheral.name, serviceShortIds: services)
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
        for c in service.characteristics ?? [] {
            let short = Gatt.shared.short(uuid: c.uuid.uuidString)
            if link.read.contains(short) { link.toRead.append(c) }
            guard link.notify.contains(short) else { continue }
            if c.properties.contains(.notify) || c.properties.contains(.indicate) {
                link.awaiting += 1
                peripheral.setNotifyValue(true, for: c)
            } else {
                link.failed.append(short) // it cannot notify: reported, never silently skipped
            }
        }
        announceIfDone(id, link)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        let id = peripheral.identifier.uuidString
        guard let link = links[id] else { return }
        link.awaiting -= 1
        let short = Gatt.shared.short(uuid: characteristic.uuid.uuidString)
        // A refused subscription is ONE characteristic that does not work, reported, not a dead link.
        if error == nil && characteristic.isNotifying { link.subscribed.append(short) } else { link.failed.append(short) }
        announceIfDone(id, link)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let id = peripheral.identifier.uuidString
        guard let link = links[id], link.peripheral === peripheral else { return }
        let short = Gatt.shared.short(uuid: characteristic.uuid.uuidString)
        if error == nil, let value = characteristic.value, !value.isEmpty {
            listener?.onNotification(id: id, characteristicShortId: short, bytes: value)
        }
        if link.reading === characteristic { // the answer of the read in flight: ask for the next one
            link.reading = nil
            readNext(link)
        }
    }
}
