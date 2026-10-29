# WorkoutJournalStore.kt

**Path:** `android/.../WorkoutJournalStore.kt` · **Layer:** native storage

`WorkoutJournalStore`: `append(sessionId, lines)` returns only when the lines are on the disk and throws when they are not, `read`, `clear`, `activeSessionId` / `setActive` (the workout that was running or paused when it was last seen). `FileWorkoutJournalStore` keeps one text file per workout in the app's files directory (`flutter_workout/`), one line per event, synced (`fd.sync()`) on every append; the active pointer is a small file synced the same way. A file name is made from the id with every character that is not an ASCII letter or digit written as its hex code, so two ids never collide.
