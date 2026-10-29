# SensorHub.kt

**Path:** `.../sensor/resolver/SensorHub.kt` · **Layer:** resolver

What a native BLE layer holds: `onConnection`, `onPacket(sourceId, epoch, characteristic, bytes, nowMs)` (decodes heart rate and RSC; anything else, such as the CSC measurement, is ignored and returns 0), `setPreferred`, `forget`, `resolve(nowMs)`, `reset`. `SensorHub.standard()` is for Swift. Not thread-safe: the engine calls it under its own lock or queue.
