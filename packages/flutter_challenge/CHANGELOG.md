## Unreleased
- Fix: a pause or a resume forgets every stage baseline, so what moved while paused is never credited (also for a short pause).
- Fix: only ONE source advances a stage at a time (the current one while fresh, else the first fresh one in the order of `allowedSources`, which is now the priority); two sensors on the same movement are no longer added together.
- Fix: `submitDelta(..., stageActivation:)` and `confirm(..., expectedStageActivation:)` (both optional, null = the current stage): a late tap or confirmation made for an older stage is dropped or refused with `STALE_ACTIVATION`.
- Fix: `restore` of another challenge while one is open is refused with `SESSION_OPEN`.
- Fix: `PigeonChallengePlatform()` is one shared instance per engine, so a second `FlutterChallenge` no longer silences the first.
- Pigeon: `confirm` and `submitDelta` got a nullable activation argument (regenerated). The iOS runner changes are not compiled yet: rebuild `ChallengeCore.xcframework` (`tool/build_core.sh`) and run the iOS tests.

## 0.0.1
- First version: Pigeon API, Android/iOS runners, journal with CRC and repair, Dart API.
