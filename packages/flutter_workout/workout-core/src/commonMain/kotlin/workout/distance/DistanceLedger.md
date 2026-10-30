# DistanceLedger.kt

**Path:** `.../workout/distance/DistanceLedger.kt` · **Layer:** distance

The one place a workout distance is added up. A source gives a cumulative COUNTER (a GPS total, a footpod, a treadmill) or a SPEED to integrate; the ledger adds only DIFFERENCES from a baseline and only from ONE source at a time.

- **Baseline** (credits nothing): the first sample of a source, of a new epoch, after a pause, after the workout started or resumed, right after the source was chosen; a counter that goes back; a counter that jumps more than `maxSpeedMps x elapsed + spikeSlackMeters`.
- **Choice:** the user's preference while fresh, else the chosen source while it stays fresh (`staleAfterMs` 10 s; it never alternates), else the best kind for the mode (outdoors GPS, counter, speed; indoors counter, speed, GPS), among equals the first seen. A source that returns after being stale does not take the distance back. Switching keeps the distance counted so far; the new source starts from a new baseline, its total is never assigned.
- **Speed** is integrated (trapezoid) only over gaps up to `maxIntegrationGapMs` (5 s), never across a pause; a speed above the limit is dropped and the next one starts over.
- A sample older than the previous one of its source, or of an older epoch, is ignored; a counter sample at the SAME instant as the previous one credits nothing (elapsed 0 would let the spike slack credit metres).
- Every change is returned as events with a sequence number.

Limits are starting values (running 12 m/s, cycling 30 m/s). `activate` / `deactivate` are called by the session on start/resume and pause/finish. One monotonic clock; not thread-safe.
