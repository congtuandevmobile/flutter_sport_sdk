# WorkoutJournalStore.swift

**Path:** `ios/Classes/WorkoutJournalStore.swift` · **Layer:** native storage

Same contract as the Android store: `append` returns only when the lines are on the disk (`FileHandle.synchronize()`) and throws otherwise; `read`, `clear`, `activeSessionId` / `setActive`. `FileWorkoutJournalStore` keeps one text file per workout in `Application Support/flutter_workout`; a file name is made from the id with every character that is not an ASCII letter or digit written as its hex code.
