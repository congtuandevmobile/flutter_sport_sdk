# MetricResolver.kt

**Path:** `.../sensor/resolver/MetricResolver.kt` · **Layer:** resolver

Chooses ONE source per metric (not per workout), never averaging or summing. A source is a candidate while connected, fresh (`staleAfterMs`, 5 s) and recovered (`recoveryMinSamples` 2 over `recoveryMinMs` 1 s since a (re)connect or a stale spell). Choice: the user's preference while it is a candidate, else the source already chosen while it stays one (no alternating between two healthy sources), else the one seen first. A source is `(sourceId, epoch)`: an event of an older epoch is dropped and a newer epoch forgets the source's values. `onConnection`, `onReading`, `setPreferred`, `forget`, `resolve(nowMs)`, `reset`. A value of 0 is a measurement. One monotonic clock; not thread-safe.
