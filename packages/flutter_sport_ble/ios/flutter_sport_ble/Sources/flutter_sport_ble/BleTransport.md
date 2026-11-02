# BleTransport.swift

**Path:** `ios/flutter_sport_ble/Sources/flutter_sport_ble/BleTransport.swift` · **Layer:** native boundary

Same contract as the Android `BleTransport`: `adapterState`, `startScan(serviceShortIds:)` (nil scans every BLE device), `stopScan`, `connect(deviceId:notify:read:)` and a listener with `onDeviceFound`, `onScanFinished`, `onGattConnected`, `onServicesDiscovered`, `onReady(subscribed:failed:)`, `onNotification` (notifications and one-time reads) and `onDisconnected`. Callbacks may come from any thread; the engine hops to its own queue.
