# FlutterSportBlePlugin.swift

**Path:** `ios/Classes/FlutterSportBlePlugin.swift` · **Layer:** Flutter entry point

Thin: creates the `SportBleEngine` with a `CoreBluetoothTransport`, implements the Pigeon host API by forwarding to it, and delivers the engine's events to Flutter on the main thread. The host declares `NSBluetoothAlwaysUsageDescription`. The links end when the plugin detaches.
