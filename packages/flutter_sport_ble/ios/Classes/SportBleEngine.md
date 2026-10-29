# SportBleEngine.swift

**Path:** `ios/Classes/SportBleEngine.swift` · **Layer:** native engine

Same rules as the Android engine, on one serial queue: epoch per connection, connect completion or `TIMEOUT` after 20 s, raw forwarding of the CSC measurement, the shared `SensorHub` (Kotlin/Native `SensorCore`) fed with the receipt time taken BEFORE the hop to the queue, a snapshot about once per second and on every connection change. Bytes cross to Kotlin as a `KotlinByteArray`. `flush()` waits for the queue (tests). `SportBleSink` is what the plugin implements.
