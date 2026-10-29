# BasicAdapters.kt

**Path:** `.../sensor/protocol/adapters/BasicAdapters.kt` · **Layer:** protocol adapters

`HeartRateAdapter` (bpm and R-R intervals; the intervals come even when the value is unusable), `RunningSpeedCadenceAdapter`, `CyclingSpeedCadenceAdapter` (CSC 0x2A5B: crank gives CYCLING_CADENCE, 0 when verified still; wheel gives the WHEEL_REVOLUTIONS counter and, with a circumference, CYCLING_SPEED; the raw packet is also forwarded), `CyclingPowerAdapter` (CPS 0x2A63: power, plus crank and wheel data in the order the flags announce; a negative power is noise and becomes 0; later fields are not read), `BatteryAdapter` (0x2A19, read and notified), `DeviceInformationAdapter` (manufacturer, model, firmware, hardware, software read once; the serial number is not read). `CycleCounters` is what CSC and CPS share for a crank or a wheel counter.
