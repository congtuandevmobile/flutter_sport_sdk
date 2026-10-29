# BleProtocolAdapter.kt

**Path:** `.../sensor/protocol/BleProtocolAdapter.kt` · **Layer:** protocol

One GATT service the core understands: `serviceUuid`, `capability`, `notifyCharacteristics` (subscribe), `readCharacteristics` (read once), `forwardRaw` (bytes also handed to the host) and `decode(characteristic, bytes, state, nowMs): List<SensorEvent>`. Pure Kotlin: a parser never calls a Bluetooth API. `SourceState` holds the decoders of ONE connection of one device (counters, rates) plus the wheel circumference; a new connection gets a new state. A truncated or impossible packet gives no events.
