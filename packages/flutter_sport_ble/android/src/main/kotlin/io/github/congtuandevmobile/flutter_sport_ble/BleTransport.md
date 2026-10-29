# BleTransport.kt

**Path:** `android/.../BleTransport.kt` · **Layer:** native boundary

The radio as the engine sees it: `adapterState`, `startScan`, `stopScan`, `connect(deviceId, measurements)`, `disconnect`, and a `Listener` (`onDeviceFound`, `onScanFinished`, `onConnected` once the services are discovered and the notifications on, `onNotification`, `onDisconnected` with an error string or null for a disconnect the engine asked for). Knows nothing about what bytes mean or about Flutter, so the engine is tested with a fake. Listener callbacks arrive on ONE thread.
