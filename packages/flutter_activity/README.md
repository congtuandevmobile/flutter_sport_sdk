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
- **Distance is a counter, from ONE source.** The distance is the sum of the INCREASES of the counter of ONE source: the one named in `begin(distanceSource: ...)`, else the first that gave a counter. A second source (a footpod next to a GPS) stays in the history but is never added, so the run is not counted twice; `summary.distanceSource` says which one counted. A counter is only measured inside one stretch of active time and one connection (its `epoch`): what it did while paused, and a counter that restarted after a reconnect (even at a bigger value), add nothing. There is no automatic switch when the chosen source goes silent: the distance then stops growing (use `flutter_workout` to fuse sources).
- **Durable.** Every record is appended to the `TelemetryStore`, and `begin` completes only when the first record is stored (`ActivityStoreException` otherwise). `isDurable` is true only when everything recorded is on the store RIGHT NOW (it is false for a moment after every sample, and after a failed write): use `hasWriteFailures` for an error banner. After the process died `ActivityRecorder.restore` brings the recording back PAUSED at its last record (the dead time is not active time) and `resume` or `finish` goes on.
- **Checked on restore.** A cut LAST line is cut off (`RecordingRestoreStatus.tailRepaired`); a damaged line in the MIDDLE stops the replay there (`partial`: what came after is gone, the numbers may be too low). Either way the store is rewritten (the damaged original is kept) so that what is recorded next is not hidden behind the damage. Session ids map to file names without collisions.
- **No samples from the future.** A sample made more than `futureTolerance` (2 s) ahead of the phone's clock is refused (`rejectedFutureSamples`).

## Limits

- It cannot record what the sensors did not send. If the Bluetooth link is lost (no auto-reconnect yet, and the connection does not outlive the Flutter engine), the history has a hole, and the coverage says so. It does not sync a history stored inside a device.
- The route is not part of the summary: read it from the GPS recording (`TrackingSession.persistedFixes`).
- The times are the WALL clock of the phone: a change of the system clock during a recording distorts the active time (the native cores use a monotonic clock).
- One activity per recorder. Not verified with real devices.
