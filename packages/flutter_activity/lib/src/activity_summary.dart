import 'package:meta/meta.dart';

import 'telemetry.dart';

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
    required this.isDurable,
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

  /// True when everything recorded is on the store.
  final bool isDurable;

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
      for (final e in coverage.entries) e.key.name: {'ratio': e.value.ratio, 'longestGapMs': e.value.longestGap.inMilliseconds},
    },
    'sources': {for (final e in sources.entries) e.key.name: e.value.toList()..sort()},
    'droppedSamples': droppedSamples,
    'duplicateSamples': duplicateSamples,
    'isDurable': isDurable,
  };
}

/// One point of a chart.
@immutable
class SeriesPoint {
  const SeriesPoint(this.at, this.value);

  final DateTime at;
  final double value;
}
