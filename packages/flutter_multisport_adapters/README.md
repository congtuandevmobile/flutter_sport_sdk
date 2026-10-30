# flutter_multisport_adapters

Adapters that feed `flutter_activity` and `flutter_multisport` (through the source interfaces of `flutter_activity`) from `flutter_tracking_gps` and `flutter_sport_ble`. They only convert and route; they never decide how much progress a measurement is worth (the challenge does). They do not depend on `flutter_multisport` or `flutter_challenge`: a record-only app uses them with `flutter_activity` alone.

| Adapter | Gives | Notes |
|---|---|---|
| `GpsProgressSource(session.updates)` | the GPS total as a counter | only when the total CHANGED, with the age of the fix; a new recording is a new epoch |
| `GpsTelemetrySource(session.updates)` | speed samples | made at the time of the fix, once per fix |
| `BleCounterSource(snapshots:, deviceId:, metric:, sourceId:)` | the counter of ONE device | reads `SensorSnapshot.valueOf(deviceId, metric)`, not the value the resolver chose; epoch and age go along; only a cumulative metric |
| `BleTelemetrySource(snapshots:, deviceId:)` | heart rate, cadence, speed, power, strokes of one device | each sample is "now minus its age"; nothing is invented when the device has no value |

```dart
coordinator.attachProgress(GpsProgressSource(trackingSession.updates));
coordinator.attachProgress(BleCounterSource(
  snapshots: ble.snapshots, deviceId: rower.id, metric: SportMetric.totalDistance, sourceId: 'rower'));
coordinator.attachTelemetry(BleTelemetrySource(snapshots: ble.snapshots, deviceId: strap.id));
```

Not verified with real devices. The Bluetooth profiles and the GPS recording have their own limits (see their packages).
