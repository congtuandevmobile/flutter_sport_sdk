# BleTransport.kt

**Path:** `android/.../BleTransport.kt` · **Layer:** native boundary

The radio as the engine sees it: `adapterState`, `startScan(services?)` (null scans every BLE device), `stopScan`, `connect(deviceId, notify, read)` and a `Listener`: `onDeviceFound`, `onScanFinished`, `onGattConnected`, `onServicesDiscovered`, `onReady(subscribed, failed)` (every subscription was tried; both lists may be empty), `onNotification` (notifications AND the one-time reads), `onDisconnected` (error string, null for a disconnect the engine asked for). Knows nothing about what bytes mean or about Flutter, so the engine is tested with a fake. Listener callbacks arrive on ONE thread.
