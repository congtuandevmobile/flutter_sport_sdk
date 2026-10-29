# SensorHub.kt

**Path:** `.../sensor/resolver/SensorHub.kt` · **Layer:** resolver

What a native BLE layer holds: `onConnection`, `setCapabilities`, `setWheelCircumference`, `onPacket(sourceId, epoch, characteristic, bytes, nowMs)` (decoded through the `ProtocolRegistry`; returns how many events were taken), `details(sourceId)` (manufacturer, model, firmware, battery, recent R-R intervals), `setPreferred`, `forget`, `resolve(nowMs)`, `reset`. Per connection of a device the decoders start empty and the battery and R-R are cleared. `SensorHub.standard()` is for Swift. Not thread-safe.
