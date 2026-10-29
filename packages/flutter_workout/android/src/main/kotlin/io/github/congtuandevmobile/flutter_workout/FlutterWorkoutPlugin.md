# FlutterWorkoutPlugin.kt

**Path:** `android/.../FlutterWorkoutPlugin.kt` · **Layer:** Flutter entry point

Thin: creates a `WorkoutEngine` with a `FileWorkoutJournalStore` (in the app's files directory) and forwards the Pigeon host API to it; a `WorkoutException` becomes a `FlutterError` with its code; snapshots reach Flutter on the main thread.
