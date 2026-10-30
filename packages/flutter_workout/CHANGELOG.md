## Unreleased

* Fix: a session id is used once. `start` with an id whose journal exists is refused with `SESSION_EXISTS`; `clearSession` frees the id.
* Fix: a sample is timed when it ARRIVED at the plugin (minus its age), not when the executor gets to it, on Android and iOS.

* Fix (late samples): while RUNNING, a sample measured before the current run started (before the start or the last resume) is dropped by `WorkoutSession`, so a callback that arrives after the resume can neither become a baseline nor credit or integrate what moved while paused (counters and speeds).

* Fix: a counter sample at the SAME instant as the previous one credits nothing (elapsed time 0 let the spike slack credit up to 5 m).
* Fix: `restore` of another workout while one is running or paused is refused with `SESSION_OPEN`.
* Fix: `PigeonWorkoutPlatform()` is one shared instance per engine, so a second `FlutterWorkout` no longer silences the first.
* The iOS change is not compiled yet: rebuild `WorkoutCore.xcframework` and run the iOS tests.

## 0.0.1-beta

First version. Not tested with real sensors.

* `FlutterWorkout`: `start`, `pause`, `resume`, `finish`, `submitCounter`, `submitSpeed`, `setPreferredSource`, `snapshot`, `restore`,
  `activeSessionId`, `clearSession`, `snapshots`.
* Native engines on top of the shared Kotlin core `workout-core` (inside the package): the journal is written and synced before a snapshot shows
  its effect; `journalFailed` is sticky; a workout whose first line cannot be written is not started; restore brings the workout back
  paused (also after a reboot that restarted the monotonic clock); restoring twice is idempotent.
* Tests: 41 core, 19 Android, 18 iOS, 8 Dart.
