# workout-core: rules and what is not done

## What it guarantees (tested)
- **No distance from nowhere.** The first sample of a source, of a new connection (epoch), after a pause, after the start and right after a source switch is a baseline: it credits nothing. A counter that goes back, or jumps more than the speed limit and the elapsed time allow, takes a new baseline: no spike, no negative distance.
- **The pause is not credited.** A treadmill that counted 500 m while the workout was paused adds nothing; a speed is not integrated across a pause or across a gap of lost data.
- **One source at a time, never summed.** Switching keeps the distance so far; the new source's own total is never assigned (1000 m on the footpod, then a treadmill reading 2500 m, stays 1000 m and adds the treadmill's NEW differences).
- **Replay is idempotent.** An event whose sequence number was already applied is ignored; a journal with repeated or reordered lines gives the same workout. A cut last line is repaired, damage in the middle keeps the prefix.
- **A restored workout comes back paused.** The time the process was dead is not activity and no distance is invented.

## Done in the plugin (`flutter_workout`)
- Android and iOS engines own a `WorkoutSession`, append every event to a synced file journal BEFORE publishing the snapshot, report a
  failed write (sticky `journalFailed`), refuse to start a workout whose first line cannot be written, and restore a workout PAUSED
  after the process dies (also after a reboot, with a clock shift). Pigeon + Dart API. The demo app runs a tiny workout through the
  native core.

## Not done yet
- Nothing feeds the workout by itself: a host (or a glue, see `examples/sensors_demo/lib/workout_feeder.dart`) must forward what
  `flutter_sport_ble` and `flutter_tracking_gps` say. The workout stops being fed when the Flutter engine goes away.
- Only distance and time: no pace, heart rate or cadence series, no stride estimator, no multisport segments, no swimming.
- The limits (10 s stale, 5 s integration gap, 12 and 30 m/s, 5 m slack) are starting values, never measured.
- The core builds as an XCFramework (`WorkoutCore`) but no Swift code uses it yet.
