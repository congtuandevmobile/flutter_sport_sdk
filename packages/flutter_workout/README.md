# flutter_workout

A workout session for Flutter: **one distance, no double counting, and a journal that survives the process dying.**

> Beta. Not tested on a device with real sensors: the engines are tested with in-memory and temporary-file journals, and the demo
> app runs a tiny workout through the native core.

```dart
final workout = FlutterWorkout();
await workout.start(sessionId: 'run-1', mode: WorkoutMode.indoorRunning);

// what the sensors say (for a flutter_sport_ble snapshot: the value, its age, the device's epoch)
await workout.submitCounter('run-1', DistanceSourceRef.counter(deviceId), meters, epoch: epoch, age: age);
await workout.submitSpeed('run-1', DistanceSourceRef.speed(deviceId), mps, epoch: epoch, age: age);
await workout.submitCounter('run-1', const DistanceSourceRef.gps(), gpsTotalMeters);

workout.snapshots.listen((s) => print('${s.distanceMeters} m in ${s.activeTime} from ${s.distanceSource}'));
await workout.finish('run-1');
```

The package measures nothing: it takes samples and decides what they add up to.

## What the native core guarantees
- **Differences from a baseline, from ONE source at a time.** The first sample of a source, of a new epoch (a reconnect), after a
  pause, after the start and right after a source switch credits nothing. A counter that goes back, or jumps more than the speed
  limit allows, takes a new baseline. Two sources are never added; switching keeps the distance so far and never assigns the new
  source's total.
- **A pause is not credited.** A treadmill that counted 500 m while the workout was paused adds nothing; a speed is not integrated
  across a pause or across a gap of lost data (more than 5 s).
- **Written before shown.** Every change is appended to a journal on disk (synced) before the snapshot that shows it. If a write
  fails the workout goes on but `journalFailed` is true and stays true (`snapshot.isDurable` is false): do not present such a
  workout as saved. A workout whose first line cannot be written is not started.
- **The process dies.** `activeSessionId()` then `restore(id)` brings the workout back PAUSED, with its distance. The time the process
  was dead is not activity and no distance is invented. A cut last line is repaired and a damaged middle keeps the part before it
  (`restoreStatus`). Restoring twice is harmless. A rebooted phone (its monotonic clock restarted) can still resume.
- **A workout is not a Bluetooth connection.** A sensor connected before the start puts no old data in the workout; a lost sensor
  does not stop the clock.

## Limits
- The workout belongs to the plugin instance: when the Flutter engine goes away nothing feeds it any more (and a recording started
  natively would need a process-wide owner, which is not built). The journal is what survives.
- Distance and time only: no pace, no heart rate or cadence series, no stride estimate, no multisport segments, no swimming.
- The limits (10 s stale, 5 s integration gap, 12 m/s running, 30 m/s cycling, 5 m jitter) are starting values, never measured.
- The glue between `flutter_sport_ble`, `flutter_tracking_gps` and a workout is an example (`examples/sensors_demo`,
  `WorkoutFeeder`), not a published package.

Layout and rules of the repository: see the root `CLAUDE.md`.
