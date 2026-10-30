# RunningSpeedCadenceParser.kt

**Path:** `.../sensor/protocol/RunningSpeedCadenceParser.kt` · **Layer:** protocol

Decodes RSC Measurement (0x2A53): flags (bit 0 stride length, bit 1 total distance, bit 2 running), speed uint16 in 1/256 m/s, cadence uint8 per minute, stride uint16 in 1/100 m, total distance uint32 in 1/10 m. Speed above 15 m/s or a truncated packet is rejected whole. `readings(bytes)` gives RUNNING_SPEED, RUNNING_CADENCE, and when present RUNNING_STRIDE_LENGTH and TOTAL_DISTANCE (CUMULATIVE). Whether the cadence counts steps or strides depends on the device: verify with a real one.
