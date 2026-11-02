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
| A store that fails is reported (`hasWriteFailures`); a pending write is not called durable; a recording whose first record cannot be stored does not start | `activity_recorder_test.dart` |
| Distance never bridges a pause; ONE source makes it (two sources are not added); a restarted counter is a new baseline | `activity_recorder_test.dart` (`distanceMustNotBridgePause`, `twoDistanceSourcesMustNotDoubleCount`, `reconnectedCounterStartsNewBaseline`) |
| A sample from the future is refused; a damaged journal is reported and repaired; session ids never share a file | `activity_recorder_test.dart` |

Not proven: with real GPS and Bluetooth sources over a real run, across the Flutter engine being destroyed.

## flutter_multisport, flutter_multisport_adapters, multisport_demo

Scope: turn a user's choice (a sport and a goal per stage) into a challenge, run it, and keep the result of each stage. Not in scope: measuring anything, deciding progress, a swimming source, judge authentication.

| Invariant | Evidence |
|---|---|
| A config that cannot become a stage is refused with every problem named; a sport with no standard source needs a source or manual completion | `sport_catalog_test.dart` |
| Multiple host-defined sports can have distinct IDs/goals/sources and their plan survives JSON restore | `sport_catalog_test.dart`, `sport_plan_test.dart` |
| Running 1 km -> Football 10 min -> Cycling 2 km becomes the right metrics, targets and sources | `sport_catalog_test.dart` |
| A stage that completes is announced once; the next stage waits for the user or starts by itself, as configured; a repeated snapshot repeats nothing | `coordinator_test.dart` (against a FAKE native side) |
| A sample belongs to the stage it was MADE in (late arrival included); a pause and the dead time are not stage time; a missing sensor is `null`, not 0 | `coordinator_test.dart` |
| The telemetry is on the store and survives a restart | `coordinator_test.dart` (file store, simulated crash) |
| Per-stage result retains a custom sport ID/title after telemetry restore | `telemetry_recorder_test.dart` |
| Adapters send what a device says (not the resolved value), with epoch and age, and never repeat a measurement | `adapters_test.dart` |
| A repeated BLE snapshot never duplicates a sample (jittering wall clock) | `adapters_test.dart` (`repeatedBleSnapshotMustNotDuplicateSample`) |
| The sources of a previous session do not feed a new one after `detachSources()`; a repeated measurement is recorded once per stage; a counter is not bridged across a pause inside a stage | `coordinator_test.dart` |
| The demo creates, runs and shows the results (stages can be moved with buttons: no deprecated drag-list callback) | `demo_test.dart` (widget tests, fake native side) |

The `sensors_demo` wiring test connects simulated GPS and selected BLE to activity and challenge history. Not proven: real sensors or a swimming counter, restore after process death on a device, or full UI use on a device.

## flutter_tracking_gps, flutter_sport_ble

No change in this round. Their quality gates are real-device evidence (distance accuracy on measured routes, weak GPS, process death, battery; BLE profiles on the candidate devices in `COMPATIBILITY.yaml`). Status: **NOT RUN**.

## Cross-SDK

| Gate | Status |
|---|---|
| Four plugins in one app: GPS/BLE/workout/challenge Android debug build | PASS (`sensors_demo` `assembleDebug`); device run NOT RUN |
| Four Kotlin/Native frameworks link in one iOS app | PASS (`sensors_demo` iOS simulator build); device run NOT RUN |
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
| 2026-10-30 | Review fixes for flutter_activity (20 tests), flutter_multisport (23), adapters (8) and the demo (4): `flutter test` + `flutter analyze` | PASS locally (Flutter 3.41.7); the CI Flutter is newer: check its run |
| 2026-10-30 | Confirmed-stage guard, pause-safe auto-next, manual distance input and BLE reconnect epoch: `flutter test` of all seven packages and both demos; `dart analyze` of the changed packages and demo; challenge-core `jvmTest` | PASS locally; the new Dart tests use a fake challenge platform and simulated BLE snapshots |
| 2026-10-30 | Review fixes: `flutter test` and `flutter analyze` in all nine Flutter packages and both demos; activity 22 tests, multisport 30, GPS adapter 1, BLE adapter 1, compatibility adapters 9 | PASS; all analyzers report no issues. Tests use fake/simulated sources, not physical GPS/BLE devices. |
| 2026-10-30 | Four Kotlin cores: `jvmTest` in tracking, sensor, workout and challenge; challenge re-run after final time-order guard; debug ChallengeCore XCFramework rebuilt | PASS. Used cached Gradle 8.13, JDK 17 and a local plugin-resolution init script because the 8.14 wrapper download did not complete. |
| 2026-10-30 | Android `testDebugUnitTest` for flutter_tracking_gps (72), flutter_sport_ble (28), flutter_workout (31) and flutter_challenge (33); challenge re-run after final core change | PASS using the corresponding example Android Gradle projects and cached Gradle 8.13. |
| 2026-10-30 | Fresh GPS-only and BLE-only temporary apps: `flutter pub get`, dependency graph inspection and adapter smoke `flutter test` | PASS; GPS-only graph has no BLE package, BLE-only graph has no GPS package. Native app builds are a separate gate. |
| 2026-10-30 | `flutter build ios --simulator --debug --no-codesign` for flutter_challenge/example; `xcodebuild test` on iPhone 16 Pro simulator with freshly rebuilt ChallengeCore XCFramework | PASS; 30 XCTest. Flutter iOS engine artifacts had to be downloaded first; initial XCTest attempt could not link `Flutter` before they were installed. |
| 2026-10-30 | `flutter build ios --simulator --debug --no-codesign` and `xcodebuild test` for flutter_sport_ble/example (28 XCTest) and flutter_workout/example (29 XCTest) on iPhone 16 Pro simulator | PASS. Their native cores were unchanged in this review and their existing XCFrameworks were used. |
| 2026-10-30 | `assembleDebug` of examples/multisport_demo Android, including native flutter_challenge and Dart app | PASS; APK produced. Used cached Gradle 8.13 after the 8.14 wrapper download stalled. |
| 2026-10-30 | `flutter build ios --simulator --debug --no-codesign` and `xcodebuild test` for flutter_tracking_gps/example on iPhone 16 Pro simulator | PASS; 60 XCTest. The iOS CI workflow now includes this previously omitted suite. |
| 2026-10-30 | `flutter build ios --simulator --debug --no-codesign` for examples/multisport_demo | PASS; simulator app built with flutter_challenge. Build does not establish real-device behavior. |
| 2026-10-30 | examples/sensors_demo: Android `:app:processDebugMainManifest assembleDebug`, merged-manifest assertions (fine location without maxSdkVersion; BLE scan/connect present), and `flutter build ios --simulator --debug --no-codesign` | PASS; GPS, BLE and workout link in the iOS simulator app. Used cached Gradle 8.13 for Android. |
| 2026-10-31 | `flutter test --reporter compact` and `flutter analyze` in all nine Flutter packages and both demos (196 tests); sensors_demo tests rerun after final host-flow cleanup | PASS; new wiring test uses simulated GPS/BLE and fake challenge platform. All analyzers report no issues. |
| 2026-10-31 | `flutter build ios --simulator --no-codesign --debug` for sensors_demo with GPS, BLE, workout and challenge; Android `assembleDebug` with cached Gradle 8.13 and JDK 17 | PASS; app built for simulator and Android debug APK, not launched on hardware. |
