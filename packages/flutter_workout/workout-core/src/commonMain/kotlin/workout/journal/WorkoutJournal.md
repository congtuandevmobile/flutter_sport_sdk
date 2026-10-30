# WorkoutJournal.kt

**Path:** `.../workout/journal/WorkoutJournal.kt` · **Layer:** journal

The text form of the workout events, independent of the GPS journal (no coordinate): one line per event, `W1|seq|type|atMs|fields...|crc` with a CRC-32 of everything before it; `|`, `%` and line breaks in text are percent-escaped. `encode`, `decode` (null for a damaged, cut, forged, other-version or non-positive-distance line), `read(lines)` (every intact line in order; the first damaged one ends the reading: `TAIL_REPAIRED` when it is the last line, `PARTIAL` when it is in the middle, then only the prefix is trusted), `recover(lines)` (a `RestoredSession`; null without a Started line). The caller owns the storage (append the lines durably BEFORE it shows the number).
