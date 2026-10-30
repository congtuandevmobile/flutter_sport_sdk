import 'package:flutter_activity/flutter_activity.dart';
import 'package:flutter_sport_ble/flutter_sport_ble.dart';

/// The counter of ONE Bluetooth device (a rower's distance, a footpod's total) as a progress source. Hand it `SportBle.snapshots`.
///
/// It reads what THAT device says (`SensorSnapshot.valueOf`), not the value the resolver chose among devices: a stage must count the
/// device it was bound to, whatever else is connected. Only a cumulative metric is a counter; the connection epoch and the age of the
/// value go along, and a value that did not change since the last reading is not sent again.
class BleCounterSource implements ProgressSource {
  BleCounterSource({
    required Stream<SensorSnapshot> snapshots,
    required this.deviceId,
    required this.metric,
    required this.sourceId,
  }) {
    _readings = snapshots.where(_changed).map(_reading).asBroadcastStream();
  }

  /// The id of the device, as `SportDevice.id`.
  final String deviceId;

  /// The counter to read (`SportMetric.totalDistance`, `SportMetric.strokeCount`, ...). A metric that is not cumulative gives nothing.
  final SportMetric metric;

  @override
  final String sourceId;

  late final Stream<CounterReading> _readings;
  int? _lastEpoch;
  double? _lastValue;

  @override
  Stream<CounterReading> get readings => _readings;

  bool _changed(SensorSnapshot s) {
    final v = s.valueOf(deviceId, metric);
    if (v == null || v.kind != MetricKind.cumulative) return false;
    return v.epoch != _lastEpoch || v.value != _lastValue;
  }

  CounterReading _reading(SensorSnapshot s) {
    final v = s.valueOf(deviceId, metric)!;
    _lastEpoch = v.epoch;
    _lastValue = v.value;
    return CounterReading(value: v.value, epoch: v.epoch, age: v.age);
  }
}

/// What one Bluetooth device measures (heart rate, cadence, speed, power, strokes) as telemetry, each sample with the time it was made.
///
/// A measurement is identified by the MONOTONIC time at which the plugin received it (`snapshot.updatedAtMs - age`): the same measurement
/// has the same number in every snapshot that still carries it, whatever the jitter of the phone's wall clock between two reads, so it is
/// recorded once. The wall-clock time of the sample is that moment placed on the wall clock with ONE anchor taken from the first snapshot
/// (re-taken only when the wall clock jumped by more than 2 s), so a repeated measurement also gets the same timestamp.
class BleTelemetrySource implements TelemetrySource {
  BleTelemetrySource({
    required Stream<SensorSnapshot> snapshots,
    required this.deviceId,
    Map<SportMetric, TelemetryMetric>? mapping,
    DateTime Function()? clock,
  }) : mapping = mapping ?? defaultMapping,
       _clock = clock ?? DateTime.now {
    _samples = snapshots.expand(_samplesOf).asBroadcastStream();
  }

  /// The metrics a device usually gives that a stage can record.
  static const defaultMapping = <SportMetric, TelemetryMetric>{
    SportMetric.heartRate: TelemetryMetric.heartRate,
    SportMetric.runningCadence: TelemetryMetric.cadence,
    SportMetric.cyclingCadence: TelemetryMetric.cadence,
    SportMetric.runningSpeed: TelemetryMetric.speed,
    SportMetric.cyclingSpeed: TelemetryMetric.speed,
    SportMetric.powerWatts: TelemetryMetric.power,
    SportMetric.strokeCount: TelemetryMetric.strokeCount,
  };

  final String deviceId;
  final Map<SportMetric, TelemetryMetric> mapping;
  final DateTime Function() _clock;
  late final Stream<TelemetrySample> _samples;
  final _lastReceived = <SportMetric, (int, int)>{};

  /// The wall-clock time of the monotonic time 0 of the plugin.
  DateTime? _anchor;

  @override
  Stream<TelemetrySample> get samples => _samples;

  Iterable<TelemetrySample> _samplesOf(SensorSnapshot s) sync* {
    final candidate = _clock().subtract(Duration(milliseconds: s.updatedAtMs));
    final anchor = _anchor;
    if (anchor == null ||
        candidate.difference(anchor).abs() > const Duration(seconds: 2)) {
      _anchor = candidate;
    }
    for (final entry in mapping.entries) {
      final v = s.valueOf(deviceId, entry.key);
      if (v == null) continue; // the device has no value: nothing is invented
      final received =
          s.updatedAtMs -
          v
              .age
              .inMilliseconds; // the same number in every snapshot that carries this measurement
      if (_lastReceived[entry.key] == (v.epoch, received)) continue;
      _lastReceived[entry.key] = (v.epoch, received);
      yield TelemetrySample(
        metric: entry.value,
        value: v.value,
        at: _anchor!.add(Duration(milliseconds: received)),
        sourceId: deviceId,
        epoch: v.epoch,
      );
    }
  }
}
