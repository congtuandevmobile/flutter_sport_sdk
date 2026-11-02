## 0.0.1-beta

Add runtime sport IDs and profiles, versioned `SportPlan` serialization, and custom sport labels in per-stage results and restored telemetry.

Stage telemetry restore now keeps a nondecreasing recovery boundary and repairs malformed records. `ChallengeCoordinator.stageSamples()` and `stageSeries()` expose per-stage replay data, with `telemetryRestoreStatus` and `flushTelemetry()` for persistence checks.

`confirmed` stages now reject an early confirmation; automatic next-stage transitions wait through a pause. Add `addProgress()` for manually measured metres or repetitions, while keeping `addRepetitions()`.

Review fixes: a repeated measurement is recorded once per stage; a counter is not bridged across a pause inside a stage; `isTelemetryDurable` is strict (pending writes) and `hasTelemetryWriteFailures` reports failures; `detachSources()` (sources live as long as the coordinator, not as long as a session).


First version. Not tested with real sensors or on a device.

* `SportCatalog`: sports, their goals (distance, time, repetitions), the metric and default source of each, validation, and the conversion of a `SportStageConfig` into a `flutter_challenge` stage.
* `ChallengeCoordinator`: start, restore, forwarding of sources, events (stage started / completed / awaiting the next / finished / error), manual or automatic transition, repetitions by hand, confirmation tied to the stage the user saw.
* `StageTelemetryRecorder`, `TelemetryStore` (memory, file): per-stage telemetry by event time, durable, restorable (the dead time is not stage time), `StageResult`.
* `package:flutter_multisport/testing.dart`: `FakeChallengePlatform`.
