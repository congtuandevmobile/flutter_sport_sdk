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
