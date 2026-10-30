# flutter_activity

Record ONE activity (a run, a ride) from the sensors, keep its history durably, and turn it into a summary: distance, active time, pace, heart-rate and cadence averages and maxima, and how much of the activity each sensor really covered.

The sensor packages give the LATEST value (`SportBle.snapshots`) or the state of a recording (`TrackingSession.updates`); none of them keeps the history of the heart rate or the cadence. This package is that history. It knows neither GPS nor Bluetooth: `flutter_multisport_adapters` makes sources from them. Pure Dart; depends on nothing but `meta`.

```dart
final recorder = await ActivityRecorder.begin(
  FileTelemetryStore(directory),          // survives the process dying
  'run-2026-01-01',
  activityType: 'running',
);
recorder.attachDistance(GpsProgressSource(trackingSession.updates));          // from flutter_multisport_adapters
recorder.attachTelemetry(BleTelemetrySource(snapshots: ble.snapshots, deviceId: strap.id));
recorder.attachTelemetry(BleTelemetrySource(snapshots: ble.snapshots, deviceId: footpod.id));

// live, any time:
final s = recorder.summary();          // s.distanceMeters, s.averageHeartRate, s.averagePaceSecondsPerKm ...

recorder.pause();  recorder.resume();
final summary = await recorder.finish();
database.save(summary.toJson());       // the app's own database
final chart = recorder.series(TelemetryMetric.heartRate, maxPoints: 200);
```

## What it guarantees

- **Event time.** A sample counts when it was MADE inside a stretch of active time, not when it arrived. A sample made during a pause or before the start is dropped (`droppedSamples`); the same measurement twice is kept once (`duplicateSamples`).
- **Nothing is made up.** A metric no sensor gave is `null` (no strap: `averageHeartRate` is null, not 0).
- **Holes are visible.** `coverage[metric]` says what share of the active time a sensor covered and its longest gap: a strap that dropped for three minutes shows as a gap, it is not averaged away. A chart (`series`) leaves a hole as a hole.
- **Distance is a counter.** The distance is the sum of the INCREASES of the distance counters (a GPS total that already had a value before the recording does not count), a counter that goes back adds nothing, and the pace is active time over that distance.
- **Durable.** Every record is appended to the `TelemetryStore`; after the process died `ActivityRecorder.restore` brings the recording back PAUSED at its last record (the dead time is not active time) and `resume` or `finish` goes on. `isDurable` tells whether everything recorded is on the store.

## Limits

- It cannot record what the sensors did not send. If the Bluetooth link is lost (no auto-reconnect yet, and the connection does not outlive the Flutter engine), the history has a hole, and the coverage says so. It does not sync a history stored inside a device.
- The route is not part of the summary: read it from the GPS recording (`TrackingSession.persistedFixes`).
- One activity per recorder. Not verified with real devices.
