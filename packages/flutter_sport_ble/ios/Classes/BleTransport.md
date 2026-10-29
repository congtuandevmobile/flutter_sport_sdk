# BleTransport.swift

**Path:** `ios/Classes/BleTransport.swift` · **Layer:** native boundary

The radio as the engine sees it (same contract as the Android `BleTransport`): `adapterState`, `startScan`, `stopScan`, `connect`, `disconnect`, and a listener (`onDeviceFound`, `onScanFinished`, `onConnected`, `onNotification`, `onDisconnected`). Callbacks may come from any thread; the engine hops to its own queue.
