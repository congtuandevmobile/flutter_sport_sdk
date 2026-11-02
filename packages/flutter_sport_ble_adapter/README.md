# flutter_sport_ble_adapter

Optional adapter from `flutter_sport_ble` to the `ProgressSource` and `TelemetrySource` interfaces of `flutter_activity`. It can also feed `flutter_multisport`, which uses those interfaces. This package has no GPS dependency.

- `BleCounterSource` emits a cumulative counter of one chosen device, with connection epoch and age.
- `BleTelemetrySource` emits heart rate, cadence, speed, power and strokes with the measurement time. Repeated snapshots do not repeat a measurement.
- `ResolvedBleTelemetrySource` emits one BLE resolver-selected device per metric, preserving source ID and connection epoch. Use it for activity and challenge history when several devices can report the same metric.

The adapter never adds counters together or decides challenge progress. The activity/challenge package applies its own source and stage rules.
