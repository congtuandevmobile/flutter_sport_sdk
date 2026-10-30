## Unreleased
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
