package io.github.congtuandevmobile.flutter_sport_ble

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.ParcelUuid
import java.util.UUID
import sensor.protocol.Gatt

/**
 * The real radio: Android scanner and one [BluetoothGatt] per device. Every GATT and scan callback is moved to the main
 * looper, so the engine sees ONE thread. Descriptor writes of one device are serialised (Android allows one GATT operation
 * at a time). A permission or adapter problem is reported as an error string, never thrown. Not unit-tested (it needs a radio);
 * the engine above it is.
 */
@SuppressLint("MissingPermission")
class AndroidBleTransport(private val context: Context) : BleTransport {
    override var listener: BleTransport.Listener? = null

    private val main = Handler(Looper.getMainLooper())
    private val adapter: BluetoothAdapter?
        get() = (context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager)?.adapter
    private val links = HashMap<String, Link>()
    private var scanning = false

    private class Link(val gatt: BluetoothGatt, val wanted: List<String>) {
        var pending: ArrayDeque<BluetoothGattCharacteristic> = ArrayDeque()
        var announced = false
        var services: List<String> = emptyList()
    }

    override fun adapterState(): NativeAdapterState {
        if (!context.packageManager.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE)) return NativeAdapterState.UNSUPPORTED
        val a = adapter ?: return NativeAdapterState.UNSUPPORTED
        if (!hasConnectPermission()) return NativeAdapterState.UNAUTHORIZED
        return if (a.isEnabled) NativeAdapterState.READY else NativeAdapterState.POWERED_OFF
    }

    private fun hasConnectPermission(): Boolean {
        if (Build.VERSION.SDK_INT < 31) return true
        return context.checkSelfPermission(android.Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED &&
            context.checkSelfPermission(android.Manifest.permission.BLUETOOTH_SCAN) == PackageManager.PERMISSION_GRANTED
    }

    // ── scan ────────────────────────────────────────────────────────────────

    private val scanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult) {
            val device = result.device ?: return
            val services = result.scanRecord?.serviceUuids?.map { Gatt.short(it.uuid.toString()) } ?: emptyList()
            val name = try { result.scanRecord?.deviceName ?: device.name } catch (_: SecurityException) { null }
            listener?.onDeviceFound(device.address, name, result.rssi, services)
        }

        override fun onScanFailed(errorCode: Int) {
            scanning = false
            listener?.onScanFinished()
        }
    }

    override fun startScan(serviceShortIds: List<String>) {
        main.post {
            if (scanning) return@post
            val scanner = adapter?.bluetoothLeScanner
            if (scanner == null || !hasConnectPermission()) {
                listener?.onScanFinished()
                return@post
            }
            val filters = serviceShortIds.map { ScanFilter.Builder().setServiceUuid(ParcelUuid(uuidOf(it))).build() }
            try {
                scanner.startScan(filters, ScanSettings.Builder().setScanMode(ScanSettings.SCAN_MODE_BALANCED).build(), scanCallback)
                scanning = true
            } catch (e: SecurityException) {
                listener?.onScanFinished()
            }
        }
    }

    override fun stopScan() {
        main.post {
            if (!scanning) return@post
            scanning = false
            try { adapter?.bluetoothLeScanner?.stopScan(scanCallback) } catch (_: SecurityException) {}
        }
    }

    // ── connect ─────────────────────────────────────────────────────────────

    override fun connect(deviceId: String, measurementShortIds: List<String>) {
        main.post {
            val a = adapter
            if (a == null || !hasConnectPermission()) {
                listener?.onDisconnected(deviceId, "PERMISSION: Bluetooth is not allowed or not available")
                return@post
            }
            try {
                links.remove(deviceId)?.gatt?.close()
                val device: BluetoothDevice = a.getRemoteDevice(deviceId)
                val callback = GattCallback(deviceId)
                val gatt = device.connectGatt(context, false, callback, BluetoothDevice.TRANSPORT_LE)
                links[deviceId] = Link(gatt, measurementShortIds)
            } catch (e: IllegalArgumentException) {
                listener?.onDisconnected(deviceId, "BAD_DEVICE: ${e.message}")
            } catch (e: SecurityException) {
                listener?.onDisconnected(deviceId, "PERMISSION: ${e.message}")
            }
        }
    }

    override fun disconnect(deviceId: String) {
        main.post {
            val link = links.remove(deviceId) ?: return@post
            try { link.gatt.disconnect() } catch (_: SecurityException) {}
            try { link.gatt.close() } catch (_: SecurityException) {}
        }
    }

    private inner class GattCallback(private val id: String) : BluetoothGattCallback() {
        override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
            main.post {
                val link = links[id]
                if (link == null || link.gatt !== gatt) {
                    try { gatt.close() } catch (_: Exception) {}
                    return@post
                }
                if (newState == BluetoothProfile.STATE_CONNECTED && status == BluetoothGatt.GATT_SUCCESS) {
                    try { gatt.discoverServices() } catch (e: SecurityException) { end(id, gatt, "PERMISSION: ${e.message}") }
                } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                    end(id, gatt, if (status == BluetoothGatt.GATT_SUCCESS) null else "GATT_$status: the link ended")
                }
            }
        }

        override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
            main.post {
                val link = links[id] ?: return@post
                if (link.gatt !== gatt) return@post
                if (status != BluetoothGatt.GATT_SUCCESS) {
                    end(id, gatt, "GATT_$status: service discovery failed")
                    return@post
                }
                link.services = gatt.services.map { Gatt.short(it.uuid.toString()) }
                for (service in gatt.services) {
                    for (c in service.characteristics) {
                        if (Gatt.short(c.uuid.toString()) in link.wanted) link.pending.addLast(c)
                    }
                }
                enableNext(id, link)
            }
        }

        override fun onDescriptorWrite(gatt: BluetoothGatt, descriptor: BluetoothGattDescriptor, status: Int) {
            main.post {
                val link = links[id] ?: return@post
                if (link.gatt !== gatt) return@post
                if (status != BluetoothGatt.GATT_SUCCESS) {
                    end(id, gatt, "GATT_$status: could not subscribe")
                    return@post
                }
                enableNext(id, link)
            }
        }

        override fun onCharacteristicChanged(gatt: BluetoothGatt, characteristic: BluetoothGattCharacteristic, value: ByteArray) {
            val copy = value.clone()
            main.post { if (links[id]?.gatt === gatt) listener?.onNotification(id, Gatt.short(characteristic.uuid.toString()), copy) }
        }

        @Deprecated("Android 12 and older")
        @Suppress("DEPRECATION")
        override fun onCharacteristicChanged(gatt: BluetoothGatt, characteristic: BluetoothGattCharacteristic) {
            if (Build.VERSION.SDK_INT >= 33) return // the three-argument callback delivers it
            val copy = characteristic.value?.clone() ?: return
            main.post { if (links[id]?.gatt === gatt) listener?.onNotification(id, Gatt.short(characteristic.uuid.toString()), copy) }
        }
    }

    /** Subscribes to the next wanted characteristic, or announces the connection when none is left. */
    private fun enableNext(id: String, link: Link) {
        val next = link.pending.removeFirstOrNull()
        if (next == null) {
            if (!link.announced) {
                link.announced = true
                val name = try { link.gatt.device.name } catch (_: SecurityException) { null }
                listener?.onConnected(id, name, link.services)
            }
            return
        }
        try {
            if (!link.gatt.setCharacteristicNotification(next, true)) {
                enableNext(id, link)
                return
            }
            val cccd = next.getDescriptor(CCCD)
            if (cccd == null) {
                enableNext(id, link)
                return
            }
            val value = if (next.properties and BluetoothGattCharacteristic.PROPERTY_NOTIFY != 0)
                BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
            else
                BluetoothGattDescriptor.ENABLE_INDICATION_VALUE
            val ok = if (Build.VERSION.SDK_INT >= 33) {
                link.gatt.writeDescriptor(cccd, value) == android.bluetooth.BluetoothStatusCodes.SUCCESS
            } else {
                @Suppress("DEPRECATION")
                run {
                    cccd.value = value
                    link.gatt.writeDescriptor(cccd)
                }
            }
            if (!ok) end(id, link.gatt, "GATT: could not start the subscription")
        } catch (e: SecurityException) {
            end(id, link.gatt, "PERMISSION: ${e.message}")
        }
    }

    private fun end(id: String, gatt: BluetoothGatt, error: String?) {
        val link = links[id]
        if (link != null && link.gatt === gatt) links.remove(id)
        try { gatt.close() } catch (_: Exception) {}
        listener?.onDisconnected(id, error)
    }

    private fun uuidOf(short: String): UUID = UUID.fromString("0000$short-0000-1000-8000-00805f9b34fb")

    companion object {
        private val CCCD: UUID = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")
    }
}
