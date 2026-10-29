# SportBleEngine.kt

**Path:** `android/.../SportBleEngine.kt` · **Layer:** native engine

Owns the devices and the shared `SensorHub` under one lock. `connect` gives every connection a new epoch, tells the hub, waits for `onConnected` (or fails after 20 s with `TIMEOUT`, or on `onDisconnected` with the transport's error); a second connect while connecting is refused, one while connected succeeds at once. `onNotification` takes the receipt time on arrival, feeds the hub, and forwards the characteristics the core does not decode (the CSC measurement) to the sink as raw packets. A snapshot (resolved metrics, device states) is published about once per second and on every connection change. It never reconnects and never touches GPS. `SportBleSink` is what the plugin implements to reach Flutter.
