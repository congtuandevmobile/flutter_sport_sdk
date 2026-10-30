/// Adapters between `flutter_tracking_gps` / `flutter_sport_ble` and `flutter_multisport`. They only convert and route: they never decide
/// how much progress a measurement is worth (the challenge does).
library;

export 'src/ble_sources.dart';
export 'src/gps_sources.dart';
