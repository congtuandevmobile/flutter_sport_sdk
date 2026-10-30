import 'package:meta/meta.dart';

import 'telemetry.dart';

/// What a restore found in the store of a recording.
enum RecordingRestoreStatus {
  /// Not restored: the recording was made in this run.
  notRestored,

  /// Every line was good.
  intact,

  /// The LAST line was cut (the process died while writing it): it was cut off, nothing else was lost.
  tailRepaired,

  /// A line in the MIDDLE was damaged: only what comes before it is trusted, what came after is gone. The numbers may be too low.
  partial,
}

/// How much of the ACTIVE time a sensor really covered. A strap that dropped for two minutes shows here: the history has a hole, and the
/// summary says so instead of averaging over what it has.
@immutable
class MetricCoverage {
  const MetricCoverage({required this.ratio, required this.longestGap});

  /// 0..1: the part of the active time that had a sample (a sample covers up to `coverageHold` after it, or until the next one).
  final double ratio;

  /// The longest stretch of active time without a sample of this metric.
  final Duration longestGap;
}

/// What a recorded activity says. A number a sensor did not give is null: never 0, never a guess.
@immutable
class ActivitySummary {
  const ActivitySummary({
    required this.sessionId,
    required this.activityType,
    required this.startedAt,
    required this.endedAt,
    required this.isFinished,
    required this.activeDuration,
    required this.pausedDuration,
    required this.stats,
    required this.coverage,
    required this.sources,
    required this.droppedSamples,
    required this.duplicateSamples,
    required this.rejectedFutureSamples,
    required this.distanceSource,
    required this.restoreStatus,
    required this.isDurable,
    required this.hasWriteFailures,
  });

  final String sessionId;

  /// What the app calls the activity ("running", "cycling"). The library never reads it.
  final String activityType;
  final DateTime startedAt;

  /// When it ended (null while it is still being recorded).
  final DateTime? endedAt;
  final bool isFinished;

  /// The time of effort: a pause is not in it.
  final Duration activeDuration;
  final Duration pausedDuration;

  /// Per metric; a metric without samples is not in the map.
  final Map<TelemetryMetric, MetricStats> stats;

  /// Per metric; how much of the active time its sensors covered.
  final Map<TelemetryMetric, MetricCoverage> coverage;

  /// The sources that gave samples, per metric ("strap-1", "gps").
  final Map<TelemetryMetric, Set<String>> sources;

  /// Samples made outside the active time (during a pause, before the start) and so not counted.
  final int droppedSamples;

  /// Samples that repeated one already recorded.
  final int duplicateSamples;

  /// Samples refused because their time was in the future (a clock that is wrong, an adapter that is wrong).
  final int rejectedFutureSamples;

  /// The ONE source whose counter makes the distance (the others are kept in the history but never added: two sources that watch the
  /// same run would count it twice). Null when no distance was recorded.
  final String? distanceSource;

  /// What the restore found (see [RecordingRestoreStatus]); [RecordingRestoreStatus.notRestored] for a recording made in this run.
  final RecordingRestoreStatus restoreStatus;

  /// True when everything recorded is on the store RIGHT NOW: false while a write is still on its way, and after a failed one.
  final bool isDurable;

  /// True when at least one write FAILED (use this for an error banner; [isDurable] is also false for a moment after every sample).
  final bool hasWriteFailures;

  double? get averageHeartRate => stats[TelemetryMetric.heartRate]?.average;
  double? get maxHeartRate => stats[TelemetryMetric.heartRate]?.max;
  double? get minHeartRate => stats[TelemetryMetric.heartRate]?.min;
  double? get averageCadence => stats[TelemetryMetric.cadence]?.average;
  double? get maxCadence => stats[TelemetryMetric.cadence]?.max;
  double? get averagePower => stats[TelemetryMetric.power]?.average;
  double? get strokeCount => stats[TelemetryMetric.strokeCount]?.total;

  /// The distance, in metres: the sum of the increases of the distance counters. Null when no distance source gave anything.
  double? get distanceMeters => stats[TelemetryMetric.distance]?.total;

  /// Distance over ACTIVE time, in metres per second. Null without a distance or without active time.
  double? get averageSpeedMps {
    final d = distanceMeters;
    final seconds = activeDuration.inMilliseconds / 1000.0;
    return d == null || seconds <= 0 ? null : d / seconds;
  }

  /// Active seconds per kilometre (a pace of 6:00/km is 360). Null until at least 10 m were covered.
  double? get averagePaceSecondsPerKm {
    final d = distanceMeters;
    final seconds = activeDuration.inMilliseconds / 1000.0;
    return d == null || d < 10 || seconds <= 0 ? null : seconds / (d / 1000.0);
  }

  /// A plain map for the app's own database (times in milliseconds since the epoch, durations in milliseconds).
  Map<String, Object?> toJson() => {
    'sessionId': sessionId,
    'activityType': activityType,
    'startedAt': startedAt.millisecondsSinceEpoch,
    'endedAt': endedAt?.millisecondsSinceEpoch,
    'isFinished': isFinished,
    'activeMs': activeDuration.inMilliseconds,
    'pausedMs': pausedDuration.inMilliseconds,
    'distanceMeters': distanceMeters,
    'averageSpeedMps': averageSpeedMps,
    'averagePaceSecondsPerKm': averagePaceSecondsPerKm,
    'stats': {for (final e in stats.entries) e.key.name: e.value.toJson()},
    'coverage': {
      for (final e in coverage.entries)
        e.key.name: {
          'ratio': e.value.ratio,
          'longestGapMs': e.value.longestGap.inMilliseconds,
        },
    },
    'sources': {
      for (final e in sources.entries) e.key.name: e.value.toList()..sort(),
    },
    'droppedSamples': droppedSamples,
    'duplicateSamples': duplicateSamples,
    'rejectedFutureSamples': rejectedFutureSamples,
    'distanceSource': distanceSource,
    'restoreStatus': restoreStatus.name,
    'isDurable': isDurable,
    'hasWriteFailures': hasWriteFailures,
  };
}

/// One point of a chart.
@immutable
class SeriesPoint {
  const SeriesPoint(this.at, this.value);

  final DateTime at;
  final double value;
}

/// Builds a bounded chart from samples of one metric. Empty time buckets stay empty, so gaps in sensor coverage remain visible.
/// Cumulative metrics use the last counter value in a bucket; instantaneous metrics use its average.
List<SeriesPoint> telemetrySeries(
  List<TelemetrySample> samples,
  TelemetryMetric metric, {
  int maxPoints = 200,
}) {
  if (maxPoints < 1) {
    throw RangeError.value(maxPoints, 'maxPoints', 'must be at least 1');
  }
  final ordered = List.of(samples)..sort((a, b) => a.at.compareTo(b.at));
  if (ordered.length <= maxPoints) {
    return [for (final s in ordered) SeriesPoint(s.at, s.value)];
  }
  final from = ordered.first.at.microsecondsSinceEpoch;
  final span = ordered.last.at.microsecondsSinceEpoch - from;
  final width = span / maxPoints;
  final buckets = <int, List<TelemetrySample>>{};
  for (final s in ordered) {
    final index = width <= 0
        ? 0
        : ((s.at.microsecondsSinceEpoch - from) / width).floor().clamp(
            0,
            maxPoints - 1,
          );
    (buckets[index] ??= []).add(s);
  }
  return [
    for (final i in (buckets.keys.toList()..sort()))
      SeriesPoint(
        buckets[i]!.last.at,
        metric.isCumulative
            ? buckets[i]!.last.value
            : buckets[i]!.fold<double>(0, (a, s) => a + s.value) /
                  buckets[i]!.length,
      ),
  ];
}
