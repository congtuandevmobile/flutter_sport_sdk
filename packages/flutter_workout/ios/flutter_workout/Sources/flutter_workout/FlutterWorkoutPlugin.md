# FlutterWorkoutPlugin.swift

**Path:** `ios/flutter_workout/Sources/flutter_workout/FlutterWorkoutPlugin.swift` · **Layer:** Flutter entry point

Thin: creates a `WorkoutEngine` with a `FileWorkoutJournalStore` and forwards the Pigeon host API to it; a `WorkoutError` becomes a `PigeonError` with its code; snapshots reach Flutter on the main thread.
