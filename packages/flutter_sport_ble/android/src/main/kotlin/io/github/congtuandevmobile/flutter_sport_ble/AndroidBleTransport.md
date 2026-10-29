# AndroidBleTransport.kt

**Path:** `android/.../AndroidBleTransport.kt` · **Layer:** native radio

The real radio: the BLE scanner (filtered by service, or unfiltered when asked) and one `BluetoothGatt` per device. Every GATT and scan callback is moved to the main looper and checked against the current `BluetoothGatt` object, so a callback of an old link never touches a new one. Descriptor writes are serialised: it subscribes to each wanted characteristic in turn. A characteristic that cannot notify (no descriptor, refused) is put in `failed` and reported, never silently skipped, and does not kill the link. After `onReady` it reads once the wanted characteristics (battery, device information), one after the other. Permission, adapter and GATT problems are error strings (`PERMISSION:`, `BAD_DEVICE:`, `GATT_<status>:`), never thrown. Not unit-tested (it needs a radio); never run against a real sensor. No reconnect.
