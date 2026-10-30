## 0.0.1-beta

First version. Not tested with real sensors or on a device.

* `SportCatalog`: sports, their goals (distance, time, repetitions), the metric and default source of each, validation, and the conversion of a `SportStageConfig` into a `flutter_challenge` stage.
* `ChallengeCoordinator`: start, restore, forwarding of sources, events (stage started / completed / awaiting the next / finished / error), manual or automatic transition, repetitions by hand, confirmation tied to the stage the user saw.
* `StageTelemetryRecorder`, `TelemetryStore` (memory, file): per-stage telemetry by event time, durable, restorable (the dead time is not stage time), `StageResult`.
* `package:flutter_multisport/testing.dart`: `FakeChallengePlatform`.
