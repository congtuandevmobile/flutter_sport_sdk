## Unreleased
- New: a stage can have a TIME goal. `ProgressMetric.duration` (target in SECONDS, no `allowedSources`): the engine completes the stage by its own clock (a pause is not in it), with the new `CompletionEvidence.timer`; the runners tick once a second, the completion is journaled before it is shown, and it is stamped at the moment the time was reached, not when the tick came. A MANUAL / JUDGE stage reaches its target and waits for the confirmation; `progress` of a timed stage is the seconds it ran. A running timed stage leaves a checkpoint event (`K`) every 10 s (unmeasured), so a crash loses at most that much of its time.
- Both new enum values are appended (Pigeon + Dart + Kotlin + Swift); an old journal without them is read as before.
- Fix: `start` is refused with `RECOVERY_REQUIRED` while the previous challenge finished in memory but its journal failed (the active pointer is its only way to recovery); `clearSession` discards it on purpose and frees the runner.
- Fix: an EMPTY journal file still takes its id (`SESSION_EXISTS`, new `JournalStore.exists`); a start that cannot write its first line leaves the id free.
- One engine owns the journal directory (exclusive lock): a second Flutter engine at the same time fails its commands with `OWNED_BY_ANOTHER_ENGINE` instead of writing the same files.
- Fix: a session id is used once. `start` with an id whose journal exists is refused with `SESSION_EXISTS` (nothing is appended behind the old journal); `clearSession` frees the id.
- Fix: a completed challenge releases the active pointer (`activeSessionId()` is null), but only after the completion is on the disk.
- Fix: a sample is timed when it ARRIVED at the plugin (minus its age), not when the executor gets to it, on Android and iOS.
- Fix (race integrity): event time decides, not arrival time. A measurement made before the stage started or before the last resume is dropped BEFORE it can touch a baseline (`TIME_BACKWARDS`), for counters and for manual deltas: late callbacks can no longer credit what moved while paused.
- Behaviour change (strict stage boundary): a new stage, and every resume, starts WITHOUT a baseline; the first measurement after it is only a baseline. A counter seen before the activation is never used, so a stage is never credited with distance it cannot prove. The price: the distance before a source's first sample of a stage is not credited.
- A source that takes over a stage (the active one went stale) credits nothing with its first delta.
- Fix: a pause or a resume forgets every stage baseline, so what moved while paused is never credited (also for a short pause).
- Fix: only ONE source advances a stage at a time (the current one while fresh, else the first fresh one in the order of `allowedSources`, which is now the priority); two sensors on the same movement are no longer added together.
- Fix: `submitDelta(..., stageActivation:)` and `confirm(..., expectedStageActivation:)` (both optional, null = the current stage): a late tap or confirmation made for an older stage is dropped or refused with `STALE_ACTIVATION`.
- Fix: `restore` of another challenge while one is open is refused with `SESSION_OPEN`.
- Fix: `PigeonChallengePlatform()` is one shared instance per engine, so a second `FlutterChallenge` no longer silences the first.
- Pigeon: `confirm` and `submitDelta` got a nullable activation argument (regenerated). The iOS runner changes are not compiled yet: rebuild `ChallengeCore.xcframework` (`tool/build_core.sh`) and run the iOS tests.

## 0.0.1
- First version: Pigeon API, Android/iOS runners, journal with CRC and repair, Dart API.
