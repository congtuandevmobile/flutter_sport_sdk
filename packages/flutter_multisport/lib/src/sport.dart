import 'package:meta/meta.dart';

/// The sports a challenge stage can be about. A sport is NOT a device and NOT a goal: the same sport can end on a distance or on a
/// time, and the same device can serve several sports.
enum SportType {
  running,
  walking,
  cycling,
  swimming,
  rowing,
  football,
  strength,
  custom,
}

/// What ends a stage.
enum GoalType {
  /// A distance, in metres.
  distance,

  /// A time of active effort (a pause is not in it), in seconds.
  duration,

  /// A number of repetitions.
  repetitions,
}

/// Who decides that a stage is done.
enum StageCompletion {
  /// The stage completes by itself when its goal is reached (the sensor reached the distance, the clock reached the time).
  automatic,

  /// The goal is reached by itself, but the stage waits for the user to confirm it.
  confirmed,

  /// Only the user ends the stage (the goal is shown, but nothing completes it by itself).
  manualOnly,
}

/// What happens after a stage completed.
enum TransitionPolicy {
  /// The next stage starts when the user asks for it ([ChallengeCoordinator.nextStage]).
  waitForUser,

  /// The next stage starts by itself, after the coordinator's `autoNextDelay`.
  autoNext,
}

/// The goal of a stage: a [type] and a [value] in the unit of that type (metres, seconds or repetitions).
@immutable
class SportGoal {
  const SportGoal._(this.type, this.value);

  const SportGoal.distanceMeters(double meters)
    : this._(GoalType.distance, meters);

  factory SportGoal.distanceKm(double kilometers) =>
      SportGoal.distanceMeters(kilometers * 1000);

  SportGoal.duration(Duration time)
    : this._(GoalType.duration, time.inMilliseconds / 1000.0);

  const SportGoal.repetitions(int count)
    : this._(GoalType.repetitions, count * 1.0);

  final GoalType type;

  /// Metres, seconds or repetitions, by [type].
  final double value;

  @override
  bool operator ==(Object other) =>
      other is SportGoal && other.type == type && other.value == value;

  @override
  int get hashCode => Object.hash(type, value);

  @override
  String toString() => 'SportGoal($type, $value)';
}

/// One stage the user asked for: a sport, its goal, and how it is measured and completed.
@immutable
class SportStageConfig {
  const SportStageConfig({
    required this.id,
    required this.sport,
    this.sportId,
    required this.goal,
    this.sources,
    this.completion = StageCompletion.automatic,
    this.transition = TransitionPolicy.waitForUser,
    this.title,
  });

  /// A host-defined sport registered in [SportCatalog].
  const SportStageConfig.custom({
    required this.id,
    required this.sportId,
    required this.goal,
    this.sources,
    this.completion = StageCompletion.automatic,
    this.transition = TransitionPolicy.waitForUser,
    this.title,
  }) : assert(sportId != null && sportId != ''),
       sport = SportType.custom;

  /// Unique inside the challenge.
  final String id;
  final SportType sport;

  /// Null for a built-in sport; otherwise the registered profile ID.
  final String? sportId;
  String get effectiveSportId => sportId ?? sport.name;
  final SportGoal goal;

  /// The ids of the sources that may advance this stage, in order (see the sticky rule of `flutter_challenge`). Null: the catalog's
  /// default for the sport. A stage whose goal is a time needs none.
  final List<String>? sources;

  final StageCompletion completion;

  /// What happens when THIS stage completes.
  final TransitionPolicy transition;

  /// A name for the screen (the library never reads it).
  final String? title;
}
