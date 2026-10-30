## 0.0.1-beta

Restore now keeps a nondecreasing recovery boundary when a late sensor sample follows pause/resume, and treats valid JSON with malformed field types as journal damage. Chart downsampling honors `maxPoints: 1` and rejects nonpositive limits.

Review fixes before the first release (tests: `activity_recorder_test.dart`):

* Distance never bridges a pause: a counter is measured inside one stretch of active time only.
* ONE distance source counts (named, or the first); the others stay in the history. `TelemetrySample.epoch`: a restarted counter starts a new baseline.
* `isDurable` is false while a write is on its way (`hasWriteFailures` for failures); `begin` waits for the first record (`ActivityStoreException`).
* Samples from the future are refused. Restore checks the lines (`RecordingRestoreStatus`: intact, tailRepaired, partial) and repairs the store (`TelemetryStore.replace`). File names of session ids cannot collide.


First version: `ActivityRecorder`, `ActivitySummary` (with coverage and series), the telemetry types, `TelemetryStore` (memory, file) and the source interfaces shared with `flutter_multisport`. Not tested with real devices.
