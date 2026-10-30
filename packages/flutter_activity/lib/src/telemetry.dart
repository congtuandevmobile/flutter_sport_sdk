import 'package:meta/meta.dart';

/// What can be recorded during an activity.
enum TelemetryMetric {
  heartRate(false),
  cadence(false),
  speed(false),
  power(false),

  /// The distance counter of a source (a GPS total, a machine's distance): the activity's distance is the sum of its increases.
  distance(true),

  /// A counter of the device (strokes of a rower or a swimmer): the number is the sum of its increases.
  strokeCount(true);

  const TelemetryMetric(this.isCumulative);

  /// True for a counter that only grows; its statistic is a [MetricStats.total], not an average.
  final bool isCumulative;
}

/// One measurement, with the time it was MADE (not the time it arrived).
@immutable
class TelemetrySample {
  const TelemetrySample({required this.metric, required this.value, required this.at, required this.sourceId});

  final TelemetryMetric metric;
  final double value;
  final DateTime at;

  /// The device or source that made it ("strap-1", "gps").
  final String sourceId;
}

/// What the samples of ONE metric say. Absent (null) where there are no samples: nothing is ever made up.
@immutable
class MetricStats {
  const MetricStats({
    required this.count,
    required this.average,
    required this.min,
    required this.max,
    required this.first,
    required this.last,
    required this.total,
  });

  /// Statistics of [samples] (at least one, of the same [metric]). Sorts [samples] by time.
  factory MetricStats.fromSamples(TelemetryMetric metric, List<TelemetrySample> samples) {
    samples.sort((a, b) => a.at.compareTo(b.at));
    var sum = 0.0;
    var min = samples.first.value;
    var max = samples.first.value;
    for (final s in samples) {
      sum += s.value;
      if (s.value < min) min = s.value;
      if (s.value > max) max = s.value;
    }
    double? total;
    if (metric.isCumulative) {
      total = 0;
      final previous = <String, double>{};
      for (final s in samples) {
        final before = previous[s.sourceId];
        if (before != null && s.value >= before) total = total! + (s.value - before); // a counter that went back (a reset) adds nothing
        previous[s.sourceId] = s.value;
      }
    }
    return MetricStats(
      count: samples.length,
      average: sum / samples.length,
      min: min,
      max: max,
      first: samples.first.value,
      last: samples.last.value,
      total: total,
    );
  }

  final int count;
  final double average;
  final double min;
  final double max;
  final double first;
  final double last;

  /// For a cumulative metric: the sum of the increases between consecutive samples of one source (a counter that goes back is not
  /// subtracted). Null for an instantaneous metric.
  final double? total;

  Map<String, Object?> toJson() => {'count': count, 'average': average, 'min': min, 'max': max, 'first': first, 'last': last, 'total': total};
}
