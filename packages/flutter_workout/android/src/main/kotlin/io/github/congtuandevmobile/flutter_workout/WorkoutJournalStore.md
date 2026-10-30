# WorkoutJournalStore.kt

**Path:** `android/.../WorkoutJournalStore.kt` · **Layer:** native storage

`WorkoutJournalStore`: `append(sessionId, lines)` returns only when the lines are on the disk and throws when they are not, `read`, `clear`, `activeSessionId` / `setActive` (the workout that was running or paused when it was last seen). `FileWorkoutJournalStore` keeps one text file per workout in the app's files directory (`flutter_workout/`), one line per event, synced (`fd.sync()`) on every append; the active pointer is a small file synced the same way. A file name is made from the id with every character that is not an ASCII letter or digit written as its hex code, so two ids never collide.

**`exists(sessionId)`:** whether a journal file exists, EVEN an empty one. The engines use it for `SESSION_EXISTS` (a session id is used once).

**`JournalDirectoryOwner`:** holds an exclusive lock on `.owner.lock` in the journal directory while the plugin is attached (the OS drops it if the process dies). A second Flutter engine does not get it and its commands fail with `OWNED_BY_ANOTHER_ENGINE`, so two runners never write the same files.
