# SportBleEngine.swift

**Path:** `ios/Classes/SportBleEngine.swift` · **Layer:** native engine

Same rules as the Android engine, on one serial queue: the states CONNECTING, DISCOVERING, SUBSCRIBING, READY or NOT_SUPPORTED, an epoch per connection, connect completion or `TIMEOUT` after 20 s, what to scan, subscribe to, read and forward raw from the `ProtocolRegistry`, the shared `SensorHub` (Kotlin/Native `SensorCore`) fed with the receipt time taken BEFORE the hop to the queue, and a snapshot about once per second and on every change. Bytes cross to Kotlin as a `KotlinByteArray`; the engine maps the core's metrics and capabilities to the Pigeon enums by ordinal (a test fails if they drift). `flush()` waits for the queue (tests).
