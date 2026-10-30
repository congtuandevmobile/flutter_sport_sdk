# Quality gates

What each SDK promises, what is proven, and what is not yet. A new requirement outside the scope below is a scope extension, not a regression of a version that met its gates. Status values: **PASS** (a test ran and passed, named), **NOT RUN** (no evidence yet), **N/A**.

Evidence in this file is only what was observed; update it when a run changes, never ahead of it.

## flutter_workout and flutter_challenge (the engines)

Scope: one workout / one multi-stage challenge per engine, distance and stage progress from host-fed counters, journal on disk, restore after the process dies. Not in scope: judge authentication, penalties, official results, background ownership that outlives the Flutter engine.

| Invariant | Evidence |
|---|---|
| A paused interval never credits distance or progress (late callbacks included) | Kotlin core: `RaceIntegrityRegressionTest`, `WorkoutLateSampleRegressionTest`, `RegressionTest` |
| A stage never credits distance of a previous stage; the first sample of a stage is only a baseline | Kotlin core: `SessionTest`, `RaceIntegrityRegressionTest` |
| Only one source advances a stage at a time | Kotlin core: `RegressionTest` |
| A callback made for an old stage is refused (when the host passes the activation) | Kotlin core + Android runner tests |
| A sample is timed when it arrived at the plugin, not when the queue handled it | Android runner/engine tests (`aSampleIsTimedWhenItArrived...`) |
| A number is never shown before it is on the disk; a write failure is visible and sticky | Android runner/engine tests |
| A session id is used once (even an empty journal); a failed first line leaves the id free | Android tests |
| The active pointer is released only when the completion is on the disk; a failed journal is never replaced silently (`RECOVERY_REQUIRED`) | Android tests |
| One Flutter engine owns the journal directory (`OWNED_BY_ANOTHER_ENGINE`) | Android unit test of `JournalDirectoryOwner` (not run with two real engines) |
| A timed stage completes by the engine's own clock, a pause is not in it, a crash loses at most the time since the last checkpoint | Kotlin core: `DurationGoalTest`; Android runner tests (`aTimedStage...`) |
| Android and iOS behave the same | iOS XCTests mirror the Android ones; see the status table |

Accepted limits (documented in the READMEs): `stageActivation` is optional (no competitive mode yet); `allowedSources` order is only a tie-break when the active source goes stale; the timestamp of a sample still depends on the `ageMs` the host gives.

## flutter_activity

Scope: record one activity from sources and summarise it. Not in scope: measuring, the route, syncing a history stored inside a device, keeping Bluetooth alive.

| Invariant | Evidence |
|---|---|
| Average, max, distance and pace come from the history; a metric nobody gave is null | `activity_recorder_test.dart` |
| A pause is not active time; a sample made during it is dropped; a late sample is filed by the time it was made; the same measurement twice counts once | `activity_recorder_test.dart` |
| A hole in a sensor's history is reported (coverage, longest gap), not averaged away | `activity_recorder_test.dart` |
| The recording survives a restart (file store), without the dead time, and a finished one restores as finished | `activity_recorder_test.dart` |
| A store that fails is reported (`isDurable`) | `activity_recorder_test.dart` |

Not proven: with real GPS and Bluetooth sources over a real run, across the Flutter engine being destroyed.

## flutter_multisport, flutter_multisport_adapters, multisport_demo

Scope: turn a user's choice (a sport and a goal per stage) into a challenge, run it, and keep the result of each stage. Not in scope: measuring anything, deciding progress, a swimming source, judge authentication.

| Invariant | Evidence |
|---|---|
| A config that cannot become a stage is refused with every problem named; a sport with no standard source needs a source or manual completion | `sport_catalog_test.dart` |
| Running 1 km -> Football 10 min -> Cycling 2 km becomes the right metrics, targets and sources | `sport_catalog_test.dart` |
| A stage that completes is announced once; the next stage waits for the user or starts by itself, as configured; a repeated snapshot repeats nothing | `coordinator_test.dart` (against a FAKE native side) |
| A sample belongs to the stage it was MADE in (late arrival included); a pause and the dead time are not stage time; a missing sensor is `null`, not 0 | `coordinator_test.dart` |
| The telemetry is on the store and survives a restart | `coordinator_test.dart` (file store, simulated crash) |
| Adapters send what a device says (not the resolved value), with epoch and age, and never repeat a measurement | `adapters_test.dart` |
| The demo creates, runs and shows the results | `demo_test.dart` (widget tests, fake native side) |

Not proven: anything with a real native side end to end across the four SDKs, real sensors, a swimming source, restore after the process died on a device.

## flutter_tracking_gps, flutter_sport_ble

No change in this round. Their quality gates are real-device evidence (distance accuracy on measured routes, weak GPS, process death, battery; BLE profiles on the candidate devices in `COMPATIBILITY.yaml`). Status: **NOT RUN**.

## Cross-SDK

| Gate | Status |
|---|---|
| Four plugins in one app (Run -> Sled -> Row -> Run) built and run | NOT RUN (`sensors_demo` has no `flutter_challenge`) |
| Four Kotlin/Native frameworks link in one iOS app | NOT RUN |
| `release_check.sh <package> both` on the real publish artifact | NOT RUN |
| Hardware compatibility matrix | NOT RUN (`verified: false`) |

## Status log

Fill the date, the command and the result of each run here.

| Date | What ran | Result |
|---|---|---|
| 2026-10-30 | `jvmTest` of challenge-core and workout-core; Android unit tests of both plugins | PASS |
| 2026-10-30 | iOS XCTest (iPhone 16 Pro simulator, XCFramework rebuilt locally) of flutter_challenge and flutter_workout, before the duration goal | PASS (`** TEST SUCCEEDED **` both) |
| 2026-10-30 | Duration goal + `cycleMeters`: `jvmTest` (51), Android unit tests (33), `flutter test`/`analyze` of flutter_challenge | PASS |
| 2026-10-30 | iOS XCTest of flutter_challenge after the duration goal and `cycleMeters` (XCFramework rebuilt locally, iPhone 16 Pro simulator) | PASS (`** TEST SUCCEEDED **`) |
| 2026-10-30 | `flutter test` + `flutter analyze` of flutter_multisport (20), flutter_multisport_adapters (6), multisport_demo (3) | PASS (fake native side only) |
| 2026-10-30 | `flutter build apk --debug` and `flutter build ios --simulator --no-codesign --debug` of multisport_demo | PASS (built, not launched) |

| 2026-10-30 | `flutter test` + `flutter analyze` of flutter_activity (10); multisport (20), adapters (6) and the demo (3) re-run after moving the shared types into flutter_activity | PASS (simulated sources, fake native side) |
