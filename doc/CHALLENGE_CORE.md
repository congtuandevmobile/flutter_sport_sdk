# challenge-core: rules and what is not done

A challenge is an ordered list of stages (for example Run, Sled, Run). Each stage measures ONE metric (distance, reps, time) from the sources it allows.

## What it guarantees (tested)
- **Event sourced.** State is the fold of an ordered list of events with sequence numbers; replay ignores a sequence already applied, so a journal with repeated lines gives the same challenge.
- **No progress from nowhere.** A stage starts from a baseline (the last fresh counter of its source when it was activated); a counter that goes back or jumps takes a new baseline. A stage never uses a total of another stage or of a resolved sensor snapshot.
- **Manual input is idempotent.** A manual delta carries a stable event id; the same id twice counts once.
- **Time.** Total time includes transitions, a stage's time is frozen when it completes, a pause is excluded.
- **Recovery.** A journal is written and synced BEFORE the snapshot that shows its effect is published; a failed write is sticky (`journalFailed`); a first line that cannot be written means the challenge is not started. After a crash the challenge is restored PAUSED (even when pausing is not allowed), a Paused("recovery") event is appended and `recoveries` goes up. A damaged journal is repaired on a temp file and atomically renamed; the original is kept as `.damaged-<ms>`.

## Done in the plugin (`flutter_challenge`)
Android and iOS runners own a `ChallengeSession` on a single serial thread (no disk I/O on the main thread), with Pigeon commands and a snapshot event stream. Dart API: `FlutterChallenge`.

## Not done yet
- No judge authentication: JUDGE_REQUIRED only records that a judge confirmed; who the judge is is the host's problem.
- No penalties, rounds or teams.
- No native background owner: when the Flutter engine goes away nothing feeds the challenge.
- The challenge journal is separate; it is not merged with the GPS or workout journals.
- Time is not verified after a recovery (a monotonic clock may restart after a reboot).
- Not wired into `examples/sensors_demo` yet: no feeder from GPS / BLE `deviceValues` / manual taps. Hardware untested, CI not run on GitHub.
