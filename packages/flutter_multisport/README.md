# flutter_multisport

Multisport challenges for Flutter: the user picks a sport and a goal for each stage (a distance or a time), the challenge runs them one after the other, and every stage keeps its own result.

It sits ABOVE `flutter_challenge` (and uses `flutter_activity` for the telemetry types, the stores and the sources): it does not know GPS or Bluetooth. Pure Dart, no native code. To record a plain activity without challenges, use `flutter_activity` alone.

| Piece | What it does |
|---|---|
| `SportCatalog` | Which sports exist, which goals each one can end on, how its distance is counted, which source usually feeds it. The "create challenge" form is made from it, and it turns a `SportStageConfig` into a `flutter_challenge` stage. |
| `ChallengeCoordinator` | Starts the challenge, forwards the readings of the sources, tells the app when a stage starts or completes, moves to the next stage by hand or by itself, restores after the process died. |
| `StageTelemetryRecorder` | Records heart rate, cadence, speed, power and strokes DURING each stage (durably) and builds a `StageResult` per stage. |
| `package:flutter_multisport/testing.dart` | `FakeChallengePlatform`: a fake native side, to test your own screens. |

```dart
final catalog = SportCatalog.standard();

final stages = [
  SportStageConfig(id: 'run',  sport: SportType.running,  goal: SportGoal.distanceKm(1)),
  SportStageConfig(id: 'ball', sport: SportType.football, goal: SportGoal.duration(const Duration(minutes: 10))),
  SportStageConfig(id: 'bike', sport: SportType.cycling,  goal: SportGoal.distanceKm(2), transition: TransitionPolicy.autoNext),
];

final coordinator = ChallengeCoordinator(
  challenge: FlutterChallenge(),
  store: FileTelemetryStore(directory),   // history that survives the process dying
);
coordinator.attachProgress(gpsSource);      // a ProgressSource: a GPS total, a machine's distance
coordinator.attachTelemetry(strapSource);   // a TelemetrySource: heart rate, cadence...
coordinator.events.listen((e) {
  switch (e) {
    case StageCompleted(): vibrate();                 // e.result: duration, evidence, averages
    case AwaitingNextStage(): showNextStageButton();  // coordinator.nextStage() when the user taps
    case ChallengeFinished(): showResults(e.results);
    default: break;
  }
});
await coordinator.start(sessionId: 'session-1', stages: stages);
```

## Sport, goal, source

- **Sport** says what the user does. **Goal** says what ends the stage: a distance (metres), a time (seconds of ACTIVE effort, a pause is not in it) or a number of repetitions. **Source** says where the progress comes from. The same sport can end on a distance or on a time; the same device can serve several sports.
- A time goal is completed by the engine's own clock (see `flutter_challenge`), not by a Flutter `Timer`: it keeps counting in the background and survives the process dying (at most 10 s lost).
- Swimming and rowing have NO default source: a stage of them needs a source named by the app (`sources: ['pool-counter']`), or `StageCompletion.manualOnly`. The library never promises a measurement that no device gives. Bluetooth does not work reliably under water: a swimming source is a device or a system chosen on purpose, not a Bluetooth parser assumed to work.
- On foot (running, walking, football) the distance is counted as `runMeters`; cycling has its own metric with a higher speed limit.

## Results

`coordinator.results` has one `StageResult` per completed stage: the active time and the evidence the challenge decided (`sensor`, `manual`, `judge`, `timer`), the goal's progress, and statistics per metric (average, min, max, count, and the sum of increases for a counter such as strokes). A metric that no sensor gave is `null`: nothing is averaged from zero samples, and nothing is guessed.

- A sample belongs to a stage by the time it was MADE, not the time it arrived: a heart-rate sample that arrives late is still filed under the stage it was made in; a sample made during a pause or between two stages is dropped (`recorder.dropped`).
- `StageCompleted.result` is the result UNTIL THAT MOMENT; read `coordinator.results` (or the `ChallengeFinished` event) for the final numbers.
- The telemetry is its own history (`TelemetryStore`), NOT the journal of the challenge: the journal protects the progress, the store keeps what the sensors said. `isTelemetryDurable` tells whether everything recorded is on the store.
- The times of the stage boundaries are the wall clock of the phone, as the coordinator saw them (within about a second of the engine's clock). A route is not part of a result; read it from your GPS recording.

## Limits

- Not verified with real sensors or on a device: the tests use a fake native side and simulated sources. Every threshold of the packages below is an unmeasured starting value.
- No judge authentication, penalties or official results (see `flutter_challenge`).
- One challenge at a time (the one of `flutter_challenge`).
- A stage whose time is up while the app is dead is not completed: after a restore the challenge is paused and the dead time is not counted.
