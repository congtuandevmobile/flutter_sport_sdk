import 'package:flutter_challenge/flutter_challenge.dart' show CompletionEvidence;
import 'package:meta/meta.dart';

import 'package:flutter_activity/flutter_activity.dart';

import 'sport.dart';

/// The result of one stage: what the challenge decided (duration, evidence) and what the sensors recorded during it.
@immutable
class StageResult {
  const StageResult({
    required this.index,
    required this.stageId,
    required this.sport,
    required this.goal,
    required this.startedAt,
    required this.endedAt,
    required this.activeDuration,
    required this.evidence,
    required this.progress,
    required this.stats,
    required this.sources,
    required this.pausedDuration,
  });

  final int index;
  final String stageId;
  final SportType sport;
  final SportGoal goal;
  final DateTime? startedAt;
  final DateTime? endedAt;

  /// The active time the challenge measured (a pause is not in it).
  final Duration activeDuration;

  /// Why the stage counted as completed (null while it has not).
  final CompletionEvidence? evidence;

  /// The goal's own progress at the end: metres, seconds or repetitions, by [goal]. Null while the stage is not completed.
  final double? progress;

  /// Per metric; a metric without samples is not in the map.
  final Map<TelemetryMetric, MetricStats> stats;

  /// The sources that gave samples.
  final Set<String> sources;

  /// The time paused inside the stage (wall clock).
  final Duration pausedDuration;

  double? get averageHeartRate => stats[TelemetryMetric.heartRate]?.average;
  double? get maxHeartRate => stats[TelemetryMetric.heartRate]?.max;
  double? get averageCadence => stats[TelemetryMetric.cadence]?.average;
  double? get averageSpeed => stats[TelemetryMetric.speed]?.average;
  double? get averagePower => stats[TelemetryMetric.power]?.average;
  double? get strokeCount => stats[TelemetryMetric.strokeCount]?.total;

  /// For a distance goal: the metres covered. Null for another goal.
  double? get distanceMeters => goal.type == GoalType.distance ? progress : null;
}
