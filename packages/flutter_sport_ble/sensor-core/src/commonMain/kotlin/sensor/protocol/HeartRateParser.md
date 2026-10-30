# HeartRateParser.kt

**Path:** `.../sensor/protocol/HeartRateParser.kt` · **Layer:** protocol

Decodes Heart Rate Measurement (0x2A37): flags (bit 0 value is uint16, bits 1-2 sensor contact where 2 = supported but not detected, bit 3 energy kJ, bit 4 R-R intervals in 1/1024 s), the value, the optional fields in that order. A truncated packet is rejected whole. A value of 0, above 300 bpm, or with no skin contact gives no bpm (`HeartRateMeasurement.bpm` null) and no reading. `readings(bytes)` returns the HEART_RATE reading or nothing. R-R intervals are decoded but not published yet.
