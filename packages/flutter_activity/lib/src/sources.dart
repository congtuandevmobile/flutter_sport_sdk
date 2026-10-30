import 'telemetry.dart';

/// A cumulative counter of a source (a GPS total, a machine's distance), with the facts needed to trust it.
class CounterReading {
  const CounterReading({required this.value, this.epoch = 1, this.age = Duration.zero});

  /// The total so far, in the unit of the source (metres, repetitions).
  final double value;

  /// Grows with every new connection of the source (a counter that restarted is not a jump).
  final int epoch;

  /// How old the value already is when it is handed over.
  final Duration age;
}

/// Something that counts progress: a GPS total, the distance of a machine. The libraries do not know GPS or Bluetooth: an adapter makes
/// one of these from them.
abstract interface class ProgressSource {
  /// The id of the source ("gps", "rower-1").
  String get sourceId;

  Stream<CounterReading> get readings;
}

/// Something that gives samples to record (a heart-rate strap, the speed of a GPS).
abstract interface class TelemetrySource {
  Stream<TelemetrySample> get samples;
}
