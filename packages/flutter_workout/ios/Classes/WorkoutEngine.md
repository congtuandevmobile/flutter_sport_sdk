# WorkoutEngine.swift

**Path:** `ios/Classes/WorkoutEngine.swift` · **Layer:** native engine

Same rules as the Android engine, on one serial queue: every event of the shared core (Kotlin/Native `WorkoutCore`) is appended to the journal and synced BEFORE the snapshot that shows it is published; `journalFailed` is sticky; the first line must be writable for the workout to start; `SESSION_OPEN`, `NO_SESSION`, `NOT_RESTORABLE`; samples stamped with their real time; a clock shift after `restore` so a rebooted phone can resume; a restored workout comes back PAUSED and restoring twice is idempotent. The engine maps the core's modes, states and source kinds to the Pigeon enums by ordinal (a test fails on drift). `flush()` waits for the queue (tests).
