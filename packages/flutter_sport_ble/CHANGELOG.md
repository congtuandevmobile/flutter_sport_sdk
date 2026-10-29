## 0.0.1-beta

First version. Not tested with a real device.

* `SportBle`: scan, connect several devices at once, `snapshots` (one resolved value per metric, `null` when unknown), `devices`,
  `rawPackets`, `setPreferredSource`, `adapterState`.
* Shared Kotlin core `shared/sensor-core`: Heart Rate and Running Speed and Cadence parsers, GATT number helpers, `MetricResolver`
  (per metric, freshness, recovery hysteresis, epochs, preference) and `SensorHub`.
* Android: `AndroidBleTransport` (one `BluetoothGatt` per device, serialised descriptor writes) and `SportBleEngine`.
  iOS: `CoreBluetoothTransport` (manager created on first use, so the permission prompt is not shown at launch) and `SportBleEngine`.
* Cycling Speed and Cadence packets are forwarded raw (`rawPackets`), not decoded.
* No automatic reconnect, no background keep-alive.
