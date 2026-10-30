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
