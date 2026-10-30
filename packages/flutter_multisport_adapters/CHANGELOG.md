## 0.0.1-beta

The package remains a compatibility bundle; GPS and BLE sources are available separately from `flutter_tracking_gps_adapter` and `flutter_sport_ble_adapter` so either sensor can be installed alone.

BLE telemetry now carries the connection epoch into stored samples, so cumulative values after reconnect start from a new baseline.

BLE telemetry: a measurement has a stable identity (monotonic receive time) and one wall-clock anchor, so a repeated snapshot never duplicates a sample.

First version: GPS progress and speed, one Bluetooth device as a counter or as telemetry. Not tested with real devices.
