import 'package:flutter_activity/flutter_activity.dart';
import 'package:flutter_challenge/flutter_challenge.dart';

import 'sport.dart';

/// What the catalog knows about one sport: the goals it can end on, how its distance is counted, where its progress usually comes from and
/// what is worth recording during it.
class SportProfile {
  const SportProfile({
    required this.sport,
    required this.goals,
    this.distanceMetric,
    this.defaultSources = const [],
    this.telemetry = const [],
  });

  final SportType sport;

  /// The goal types a user may pick for this sport (the form of the "create challenge" screen is made from this).
  final Set<GoalType> goals;

  /// How the distance of this sport is counted by the challenge (null: this sport has no distance goal).
  final ProgressMetric? distanceMetric;

  /// The sources that advance a stage of this sport when the config names none, in order. Empty: the app must name one (or complete the
  /// stage by hand), because no standard source exists.
  final List<String> defaultSources;

  /// What is worth recording during a stage of this sport.
  final List<TelemetryMetric> telemetry;
}

/// A config that cannot become a stage, and why.
class SportConfigException implements Exception {
  SportConfigException(this.problems);

  final List<String> problems;

  @override
  String toString() => 'SportConfigException(${problems.join('; ')})';
}

/// The sports a challenge can be made of, and the one place that turns a user's choice (a sport and a goal) into a `flutter_challenge`
/// stage. The core of the challenge knows goals and measurements, not sports: this catalog is the only place that knows which metric
/// counts a sport.
class SportCatalog {
  SportCatalog(Iterable<SportProfile> profiles) : _profiles = {for (final p in profiles) p.sport: p};

  /// Running, walking, cycling, swimming, rowing, football, strength and a custom sport.
  ///
  /// On foot (running, walking, football) the distance is counted as `runMeters`. Swimming and rowing have no default source: a stage
  /// of them needs a source named by the app, or manual completion. Strength and a custom sport count repetitions by hand (`manual`).
  factory SportCatalog.standard() => SportCatalog(const [
    SportProfile(
      sport: SportType.running,
      goals: {GoalType.distance, GoalType.duration},
      distanceMetric: ProgressMetric.runMeters,
      defaultSources: ['gps'],
      telemetry: [TelemetryMetric.heartRate, TelemetryMetric.cadence, TelemetryMetric.speed],
    ),
    SportProfile(
      sport: SportType.walking,
      goals: {GoalType.distance, GoalType.duration},
      distanceMetric: ProgressMetric.runMeters,
      defaultSources: ['gps'],
      telemetry: [TelemetryMetric.heartRate, TelemetryMetric.cadence, TelemetryMetric.speed],
    ),
    SportProfile(
      sport: SportType.cycling,
      goals: {GoalType.distance, GoalType.duration},
      distanceMetric: ProgressMetric.cycleMeters,
      defaultSources: ['gps'],
      telemetry: [TelemetryMetric.heartRate, TelemetryMetric.cadence, TelemetryMetric.power, TelemetryMetric.speed],
    ),
    SportProfile(
      sport: SportType.swimming,
      goals: {GoalType.distance, GoalType.duration},
      distanceMetric: ProgressMetric.swimMeters,
      telemetry: [TelemetryMetric.heartRate, TelemetryMetric.strokeCount],
    ),
    SportProfile(
      sport: SportType.rowing,
      goals: {GoalType.distance, GoalType.duration},
      distanceMetric: ProgressMetric.rowMeters,
      telemetry: [TelemetryMetric.heartRate, TelemetryMetric.cadence, TelemetryMetric.power, TelemetryMetric.strokeCount],
    ),
    SportProfile(
      sport: SportType.football,
      goals: {GoalType.duration, GoalType.distance},
      distanceMetric: ProgressMetric.runMeters,
      defaultSources: ['gps'],
      telemetry: [TelemetryMetric.heartRate, TelemetryMetric.speed],
    ),
    SportProfile(
      sport: SportType.strength,
      goals: {GoalType.duration, GoalType.repetitions},
      defaultSources: ['manual'], // repetitions are counted by hand (`ChallengeCoordinator.addRepetitions`) unless the app names a counter
      telemetry: [TelemetryMetric.heartRate],
    ),
    SportProfile(sport: SportType.custom, goals: {GoalType.duration, GoalType.repetitions}, defaultSources: ['manual']),
  ]);

  final Map<SportType, SportProfile> _profiles;

  /// The sports a user can pick, in the order of [SportType].
  List<SportType> get sports => [for (final s in SportType.values) if (_profiles.containsKey(s)) s];

  SportProfile? profileOf(SportType sport) => _profiles[sport];

  /// The goal types the user may pick for [sport] (empty for an unknown sport).
  List<GoalType> goalsOf(SportType sport) => [for (final g in GoalType.values) if (_profiles[sport]?.goals.contains(g) ?? false) g];

  /// What is wrong with [config] (empty when it can become a stage).
  List<String> validate(SportStageConfig config) {
    final problems = <String>[];
    if (config.id.trim().isEmpty) problems.add('the stage id is empty');
    final profile = _profiles[config.sport];
    if (profile == null) return [...problems, '${config.sport.name} is not in the catalog'];
    final goal = config.goal;
    if (!profile.goals.contains(goal.type)) problems.add('${config.sport.name} has no ${goal.type.name} goal');
    if (!goal.value.isFinite || goal.value <= 0) problems.add('the goal must be more than 0');
    if (goal.type == GoalType.repetitions && goal.value != goal.value.roundToDouble()) problems.add('repetitions must be a whole number');
    if (goal.type != GoalType.duration && config.completion != StageCompletion.manualOnly && _sourcesOf(config, profile).isEmpty) {
      problems.add('${config.sport.name} has no default source: name one in `sources`, or complete the stage by hand (manualOnly)');
    }
    if ((config.sources ?? const []).any((s) => s.trim().isEmpty)) problems.add('a source id is empty');
    return problems;
  }

  List<String> _sourcesOf(SportStageConfig config, SportProfile profile) => config.sources ?? profile.defaultSources;

  /// The `flutter_challenge` stage of [config]. Throws [SportConfigException] when it cannot be one.
  StageDefinition stageDefinitionOf(SportStageConfig config) {
    final problems = validate(config);
    if (problems.isNotEmpty) throw SportConfigException(problems);
    final profile = _profiles[config.sport]!;
    switch (config.goal.type) {
      case GoalType.duration:
        return StageDefinition(
          id: config.id,
          metric: ProgressMetric.duration,
          target: config.goal.value,
          // a time reaches its target by itself; `confirmed` and `manualOnly` both wait for the user once it is reached
          policy: config.completion == StageCompletion.automatic ? CompletionPolicy.auto : CompletionPolicy.manual,
          allowedSources: const {},
        );
      case GoalType.distance:
      case GoalType.repetitions:
        final sources = _sourcesOf(config, profile);
        return StageDefinition(
          id: config.id,
          metric: config.goal.type == GoalType.distance ? profile.distanceMetric! : ProgressMetric.reps,
          target: config.goal.value,
          policy: switch (config.completion) {
            StageCompletion.automatic => CompletionPolicy.auto,
            StageCompletion.confirmed => CompletionPolicy.sensorOrManual,
            StageCompletion.manualOnly => CompletionPolicy.manual,
          },
          // by hand with no source: the stage still needs a name for the one that counts ("manual")
          allowedSources: sources.isEmpty ? const {'manual'} : sources.toSet(),
        );
    }
  }

  /// The whole challenge. Throws [SportConfigException] (with every problem of every stage) when a stage is wrong or an id repeats.
  ChallengeDefinition definitionOf({
    required String id,
    required List<SportStageConfig> stages,
    int version = 1,
    bool allowPause = true,
  }) {
    final problems = <String>[];
    if (stages.isEmpty) problems.add('a challenge needs at least one stage');
    final seen = <String>{};
    for (var i = 0; i < stages.length; i++) {
      for (final p in validate(stages[i])) {
        problems.add('stage ${i + 1}: $p');
      }
      if (!seen.add(stages[i].id)) problems.add('stage ${i + 1}: the id "${stages[i].id}" is used twice');
    }
    if (problems.isNotEmpty) throw SportConfigException(problems);
    return ChallengeDefinition(
      id: id,
      version: version,
      allowPause: allowPause,
      stages: [for (final s in stages) stageDefinitionOf(s)],
    );
  }
}
