# SensorModel.kt

**Path:** `.../sensor/model/SensorModel.kt` · **Layer:** model

`MetricType` (what a reading measures, fixed units; ONLY APPEND, the Pigeon enum of `flutter_sport_ble` mirrors the order and a test of each engine fails on drift), `MeasurementKind` (INSTANTANEOUS, or CUMULATIVE for a device counter), `SensorReading`, `Capability`, `DeviceInfoField`, and `SensorEvent`: `Measurement` (a number the resolver can choose), `RrIntervals`, `DeviceInfo` and `Battery` (structured data kept per device, never resolved between devices). `DeviceDetails` is what the hub knows about a device besides its metrics.
