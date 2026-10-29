# AndroidBleTransport.kt

**Path:** `android/.../AndroidBleTransport.kt` · **Layer:** native radio

The real radio: the BLE scanner (filtered by service) and one `BluetoothGatt` per device. Every GATT and scan callback is moved to the main looper. Descriptor writes of a device are serialised: it subscribes to each wanted characteristic in turn, then announces the connection. Permission, adapter and GATT problems are reported as error strings (`PERMISSION:`, `BAD_DEVICE:`, `GATT_<status>:`), never thrown. Not unit-tested (it needs a radio); never run against a real sensor. No reconnect.
