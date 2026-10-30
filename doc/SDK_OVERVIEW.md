# flutter_sport_sdk: what it is and how the pieces fit

A family of **independent** Flutter packages for sport apps. An app installs only the ones it needs. Nothing here names or depends on any
application.

State today: every package is `0.0.1-beta`; tested with unit tests, fake radios and fake native sides. **Nothing is verified on real
sensors or real devices** (see `QUALITY_GATES.md`, `COMPATIBILITY.yaml`).

## The packages

| Package | One-line job | Native? | Depends on |
|---|---|---|---|
| `flutter_tracking_gps` | Record with the phone: GPS fixes + steps -> one distance (Kalman gate, weak-GPS gap handling, pending step estimate, journal, foreground service). Core: `tracking-core` (Kotlin) | Android + iOS | nothing |
| `flutter_sport_ble` | Connect SEVERAL BLE sensors at once (HR strap, footpod, cycling cadence/power, treadmill/rower/bike via FTMS). Core `sensor-core` decodes packets and picks ONE value per metric | Android + iOS | nothing |
| `flutter_workout` | A workout session: state machine, one distance from counters/speeds, no double counting, journal on disk. Core `workout-core` | Android + iOS | nothing |
| `flutter_challenge` | A multi-stage challenge engine (event-sourced stages, per-stage baseline, time goals, journal, recovery). Core `challenge-core` | Android + iOS | nothing |
| `flutter_activity` | History of ONE activity: HR/cadence/speed/power/distance with event time, durable store, summary (avg/max/pace/coverage/gaps), chart series | none (pure Dart) | nothing |
| `flutter_multisport` | Sport catalog (sport + goal per stage), `ChallengeCoordinator`, per-stage telemetry and `StageResult` | none (pure Dart) | `flutter_challenge`, `flutter_activity` |
| `flutter_tracking_gps_adapter` | GPS as `ProgressSource` / `TelemetrySource` | none | `gps`, `activity` |
| `flutter_sport_ble_adapter` | Per-device BLE as `ProgressSource` / `TelemetrySource` | none | `ble`, `activity` |
| `flutter_multisport_adapters` | Compatibility exports for both adapters | none | both adapters |

```
   flutter_tracking_gps             flutter_sport_ble
            |                              |
   flutter_tracking_gps_adapter     flutter_sport_ble_adapter
            \                             /
             flutter_activity <---- flutter_multisport ----> flutter_challenge
             (history, summary)      (catalog, coordinator)   (stage engine)
                                    flutter_workout (one distance from several sources; standalone)
```

Rule: dependencies only point down; sensor packages never import each other; a core never imports another product's core.

## Data flow (the one idea to remember)

```
sensors -> source interfaces -> (activity recorder | challenge coordinator) -> summary / StageResult -> the app stores it
```

- **Sensors** (`gps`, `ble`) only produce latest values / a distance total. They keep no history.
- **Sources** (`ProgressSource` = a counter that advances a goal; `TelemetrySource` = timed samples such as heart rate) are the
  seam. Anything can implement them: a GPS session, one BLE device, a manual tap, a swimming pool counter.
- **`flutter_activity`** keeps history and makes the summary. **`flutter_challenge`** decides stage progress. Neither measures.
- The app owns long-term storage (`summary.toJson()`, `StageResult`) and the UI.

## Scenarios

### 1. Record with the phone only
Install `flutter_tracking_gps`. `createSession` -> `start/pause/resume/finish` -> `updates` stream for UI -> `persistedFixes()` for the route.
No BLE, no activity package needed.

### 2. Record with the phone + BLE devices, review heart rate afterwards
Install `flutter_tracking_gps`, `flutter_sport_ble`, `flutter_activity`, `flutter_tracking_gps_adapter`, `flutter_sport_ble_adapter`.

```dart
final recorder = await ActivityRecorder.begin(FileTelemetryStore(dir), id, activityType: 'running');
recorder.attachDistance(GpsProgressSource(gpsSession.updates));
recorder.attachTelemetry(BleTelemetrySource(snapshots: ble.snapshots, deviceId: strap.id));   // heart rate
recorder.attachTelemetry(BleTelemetrySource(snapshots: ble.snapshots, deviceId: footpod.id)); // cadence/speed
// live: ble.snapshots (bpm, cadence), recorder.summary()
final summary = await recorder.finish();               // app saves summary.toJson()
final chart = recorder.series(TelemetryMetric.heartRate, maxPoints: 200); // review later
```

Live display comes from `SportBle.snapshots`; the post-activity review comes from `ActivityRecorder` (history, avg/max, gaps).

### 3. Multi-sport challenge (run 1 km -> swim 200 m -> strength 1 h)
Install `flutter_multisport` (+ either optional adapter and sensor plugin as needed).

```dart
final stages = [
  SportStageConfig(id: 'run',  sport: SportType.running,  goal: SportGoal.distanceKm(1)),
  SportStageConfig(id: 'swim', sport: SportType.swimming, goal: SportGoal.distanceMeters(200), sources: ['pool-counter']),
  SportStageConfig(id: 'lift', sport: SportType.strength, goal: SportGoal.duration(const Duration(hours: 1)),
                   transition: TransitionPolicy.autoNext),
];
coordinator.attachProgress(...); coordinator.attachTelemetry(...);
coordinator.events.listen(...);  // StageStarted / StageCompleted / AwaitingNextStage / ChallengeFinished
await coordinator.start(sessionId: 's1', stages: stages);
```

- The user adds/orders stages in the app UI (use `SportCatalog.goalsOf(sport)` to build the form); the catalog validates and turns
  them into a `ChallengeDefinition`.
- Next stage: `TransitionPolicy.waitForUser` -> app shows a button and calls `coordinator.nextStage()`; `autoNext` -> starts by itself
  after `autoNextDelay`. `StageCompleted` / `AwaitingNextStage` events are the "stage done" signal (vibrate, sound, banner).
- After finishing: `coordinator.results` / `ChallengeFinished.results` = one `StageResult` per stage (time, evidence, avg/min/max HR,
  cadence, etc.). The app saves them and shows the challenge detail later.
- For a per-stage chart, read `coordinator.stageSamples(index, metric)` or `stageSeries(index, metric)`; the latter works after restore too.
- Survives the process dying: the challenge restores PAUSED; telemetry store is separate from the challenge journal.

### 4. Indoor machines / one distance from several sources
`flutter_workout` fuses counters and speeds (footpod, treadmill, GPS) into ONE distance without double counting; it is standalone
and not yet fed automatically (see `examples/sensors_demo/lib/workout_feeder.dart`).

## What is not built (honest list)

- No real-device or real-sensor verification; every threshold is an unmeasured starting value.
- No BLE auto-reconnect, no background BLE (links end with the Flutter engine), no Fitness Machine control point.
- No swimming source (Bluetooth does not work under water): a stage needs a named source (pool counter, watch) or manual completion.
- Challenge: no judge authentication, penalties, rounds, teams; a stage whose time is up while the app is dead is not completed.
- `flutter_activity` uses the wall clock (the native cores use a monotonic clock); one activity per recorder; no route in the summary.
- `flutter_workout` is not wired to the sensor plugins; distance and time only.
- Four plugins together in one app (`Run -> Sled -> Row -> Run`) and four Kotlin/Native frameworks in one iOS app: NOT RUN.
- CI workflows were written but have not run on GitHub.

## Gaps against a Hyrox-style product (for planning)

| Need | Status |
|---|---|
| Fixed stage list with run legs and station efforts, per-stage results | Covered by catalog + coordinator (stations with no sensor use `manual`/reps/time) |
| Station types (sled, burpee, wall ball...) | Only `strength` / `custom` today; add profiles to `SportCatalog` |
| Reps from a sensor | Not available; reps are manual (`addRepetitions`) |
| Roxzone / transition time as its own result | Transition time is part of total time; not exposed as a per-transition result |
| Official/judged results, penalties | Not built |
| Wearable/watch as a source | Not built; implement `ProgressSource` / `TelemetrySource` |
