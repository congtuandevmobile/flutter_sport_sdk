import 'package:flutter_activity/flutter_activity.dart';
import 'package:flutter_tracking_gps/flutter_tracking_gps.dart';

/// The distance the GPS recording counted, as a progress source. Hand it `TrackingSession.updates`.
///
/// It sends the TOTAL of the recording (the challenge makes the stage's own distance out of it), only when the total CHANGED (a snapshot
/// that repeats the same number says nothing new), and with the age of the fix that produced it, so the challenge knows WHEN it was
/// measured. A new recording (another session id) is a new epoch: its total starting again is not a jump.
class GpsProgressSource implements ProgressSource {
  GpsProgressSource(Stream<TrackingSnapshot> snapshots, {this.sourceId = 'gps', DateTime Function()? clock}) : _clock = clock ?? DateTime.now {
    _readings = snapshots.where(_changed).map(_reading).asBroadcastStream();
  }

  @override
  final String sourceId;

  final DateTime Function() _clock;
  late final Stream<CounterReading> _readings;
  double? _lastTotal;
  String? _lastSession;
  var _epoch = 1;

  @override
  Stream<CounterReading> get readings => _readings;

  bool _changed(TrackingSnapshot s) {
    if (s.sessionId == null) return false;
    if (s.sessionId != _lastSession) {
      if (_lastSession != null) _epoch += 1;
      _lastSession = s.sessionId;
      _lastTotal = null;
    }
    return s.totalMeters != _lastTotal;
  }

  CounterReading _reading(TrackingSnapshot s) {
    _lastTotal = s.totalMeters;
    final fixAt = s.lastFixAt;
    final age = fixAt == null ? Duration.zero : _clock().difference(fixAt);
    return CounterReading(value: s.totalMeters, epoch: _epoch, age: age.isNegative ? Duration.zero : age);
  }
}

/// The speed of the GPS (Doppler, not smoothed) as telemetry, made at the time of the fix. A snapshot without a trustworthy speed gives
/// no sample, and a fix is sampled once.
class GpsTelemetrySource implements TelemetrySource {
  GpsTelemetrySource(Stream<TrackingSnapshot> snapshots, {this.sourceId = 'gps'}) {
    _samples = snapshots.where(_fresh).map(_sample).asBroadcastStream();
  }

  final String sourceId;
  late final Stream<TelemetrySample> _samples;
  DateTime? _lastFix;

  @override
  Stream<TelemetrySample> get samples => _samples;

  bool _fresh(TrackingSnapshot s) {
    final at = s.lastFixAt;
    if (at == null || s.speedMps == null || at == _lastFix) return false;
    return true;
  }

  TelemetrySample _sample(TrackingSnapshot s) {
    _lastFix = s.lastFixAt;
    return TelemetrySample(metric: TelemetryMetric.speed, value: s.speedMps!, at: s.lastFixAt!, sourceId: sourceId);
  }
}
