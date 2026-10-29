# SensorModel.kt

**Path:** `.../sensor/model/SensorModel.kt` · **Layer:** model

`MetricType` (what a reading measures, fixed units: heart rate bpm, running speed m/s, running cadence per minute, stride length m, total distance m), `MeasurementKind` (INSTANTANEOUS, or CUMULATIVE for a device counter), `SensorReading(metric, value, kind)` and `Capability` (what a device exposes, decided from its GATT services). The order of `MetricType` and `Capability` is mirrored by the Pigeon enums of `flutter_sport_ble`; a test of that package must fail if one drifts.
