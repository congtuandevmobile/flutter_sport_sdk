# flutter_multisport_adapters

Compatibility bundle for [`flutter_tracking_gps_adapter`](../flutter_tracking_gps_adapter/) and [`flutter_sport_ble_adapter`](../flutter_sport_ble_adapter/). Existing imports continue to work. New apps can install either adapter alone, without pulling in the other sensor plugin. Adapters only convert and route; they never decide how much progress a measurement is worth.

| Adapter | Gives | Notes |
|---|---|---|
| `GpsProgressSource(session.updates)` | the GPS total as a counter | only when the total CHANGED, with the age of the fix; a new recording is a new epoch |
| `GpsTelemetrySource(session.updates)` | speed samples | made at the time of the fix, once per fix |
| `BleCounterSource(snapshots:, deviceId:, metric:, sourceId:)` | the counter of ONE device | reads `SensorSnapshot.valueOf(deviceId, metric)`, not the value the resolver chose; epoch and age go along; only a cumulative metric |
| `BleTelemetrySource(snapshots:, deviceId:)` | heart rate, cadence, speed, power, strokes of one device | a measurement is identified by connection epoch and the monotonic time the plugin received it (`updatedAtMs - age`), so the same measurement in later snapshots is recorded ONCE; a counter after reconnect starts a new baseline; nothing is invented when the device has no value |

```dart
coordinator.attachProgress(GpsProgressSource(trackingSession.updates));
coordinator.attachProgress(BleCounterSource(
  snapshots: ble.snapshots, deviceId: rower.id, metric: SportMetric.totalDistance, sourceId: 'rower'));
coordinator.attachTelemetry(BleTelemetrySource(snapshots: ble.snapshots, deviceId: strap.id));
```

Not verified with real devices. The Bluetooth profiles and the GPS recording have their own limits (see their packages).
