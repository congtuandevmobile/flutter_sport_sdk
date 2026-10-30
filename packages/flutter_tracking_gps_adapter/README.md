# flutter_tracking_gps_adapter

Optional adapter from `flutter_tracking_gps` to the `ProgressSource` and `TelemetrySource` interfaces of `flutter_activity`. It can also feed `flutter_multisport`, which uses those interfaces. This package has no BLE dependency.

- `GpsProgressSource(session.updates)` emits the GPS total as a counter with fix age and recording epoch.
- `GpsTelemetrySource(session.updates)` emits one speed sample per fix.

Use `ActivityRecorder.attachDistance(GpsProgressSource(session.updates))` for a GPS activity history. The GPS route remains in `flutter_tracking_gps`.
