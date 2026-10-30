# flutter_challenge

Multi-stage challenges (for example Run → Sled → Run) on top of its own `challenge-core/`. Android and iOS own the session, journal every event to disk before publishing the snapshot, and restore a crashed challenge paused.

```dart
final challenge = FlutterChallenge();
await challenge.start(sessionId: 'c1', definition: definition);
challenge.snapshots.listen(print);
await challenge.submitDelta('c1', 'manual', 'tap-1', 1);
```

Feed it from any source (GPS total, BLE per-device values, manual taps); it does not need Bluetooth. See `doc/CHALLENGE_CORE.md` for what is guaranteed and what is not done.

iOS: build the XCFramework first with `tool/build_core.sh debug`.

## Session lifecycle contract

- **A session id is used once.** `start` with an id whose journal exists (even an empty file) fails with `SESSION_EXISTS`; call `clearSession` first.
- **One session at a time.** `start` or `restore` of another session while one is open fails with `SESSION_OPEN`.
- **A failed journal is never silently replaced.** If the previous challenge finished in memory but its journal could not be written, `start` fails with `RECOVERY_REQUIRED`: recover it (`activeSessionId` still points to it) or discard it on purpose with `clearSession`.
- **One Flutter engine owns the journal.** A second engine alive at the same time gets `OWNED_BY_ANOTHER_ENGINE` on every command (nothing is written). Hot reload is fine; a second engine (for example a headless background isolate) is not supported.

## Which source advances a stage

`allowedSources` says which sources MAY advance a stage; it is not a priority list that is re-evaluated on every sample. Only ONE source advances a stage at a time, and the rule is sticky:

1. After a stage starts (and after every resume) there is no active source. The first allowed source with a valid measurement becomes active.
2. The active source stays active while it is fresh (a measurement in the last 5 s), even when a source that comes first in `allowedSources` appears later.
3. When the active source goes stale, the first FRESH source in the order of `allowedSources` takes over; its first delta credits nothing (it may reach back to a moment the previous source already counted).
4. Sources that are not active keep their own baseline but never credit the stage.

A manual delta (`submitDelta`) is not subject to this rule; it is deduplicated by its event id and, when given, its `stageActivation`.

## Time goals (a stage that ends when a time has passed)

```dart
StageDefinition(
  id: 'football',
  metric: ProgressMetric.duration,
  target: 3600,                       // SECONDS of active time
  policy: CompletionPolicy.auto,      // the clock completes it (evidence: CompletionEvidence.timer)
  allowedSources: {},                 // nothing feeds a timed stage
)
```

- The time is the ACTIVE time of the stage: a pause (and the time a dead process was away) is not in it. The snapshot's `stageProgress` is the seconds run (capped at the target).
- The engine decides, not a Flutter `Timer`: the native runner ticks once a second, so the stage completes while the app is in the background, and the completion is on the disk before it is shown.
- `manual` / `sensorOrManual` / `judgeRequired`: the stage reaches its target when the time is up and waits for `confirm`. A confirmation before that ends the stage early; its `progress` is the time it really ran.
- A distance stage (`runMeters`, ...) and a timed stage can be mixed in one challenge.
- A timed stage ignores `submitCounter` / `submitDelta` (`SOURCE_NOT_ALLOWED`).

