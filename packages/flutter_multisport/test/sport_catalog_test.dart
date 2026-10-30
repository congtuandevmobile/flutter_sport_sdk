import 'package:flutter_challenge/flutter_challenge.dart';
import 'package:flutter_multisport/flutter_multisport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final catalog = SportCatalog.standard();

  test('the form of "create challenge" comes from the catalog: each sport offers its own goals', () {
    expect(catalog.sports, containsAll([SportType.running, SportType.swimming, SportType.football, SportType.strength]));
    expect(catalog.goalsOf(SportType.running), [GoalType.distance, GoalType.duration]);
    expect(catalog.goalsOf(SportType.strength), [GoalType.duration, GoalType.repetitions]);
    expect(catalog.goalsOf(SportType.football), [GoalType.distance, GoalType.duration]);
  });

  test('Running 1 km -> Football 10 min -> Cycling 2 km becomes three stages with the right metric, target and source', () {
    final definition = catalog.definitionOf(
      id: 'tri',
      stages: [
        SportStageConfig(id: 'run', sport: SportType.running, goal: SportGoal.distanceKm(1)),
        SportStageConfig(id: 'ball', sport: SportType.football, goal: SportGoal.duration(const Duration(minutes: 10))),
        SportStageConfig(id: 'bike', sport: SportType.cycling, goal: SportGoal.distanceKm(2)),
      ],
    );
    final [run, ball, bike] = definition.stages;
    expect([run.metric, run.target, run.policy, run.allowedSources], [ProgressMetric.runMeters, 1000.0, CompletionPolicy.auto, {'gps'}]);
    expect([ball.metric, ball.target, ball.policy, ball.allowedSources], [ProgressMetric.duration, 600.0, CompletionPolicy.auto, <String>{}]);
    expect([bike.metric, bike.target, bike.policy, bike.allowedSources], [ProgressMetric.cycleMeters, 2000.0, CompletionPolicy.auto, {'gps'}]);
  });

  test('a sport without a standard source needs one named, or manual completion', () {
    final swim = SportStageConfig(id: 'swim', sport: SportType.swimming, goal: const SportGoal.distanceMeters(200));
    expect(catalog.validate(swim).single, contains('no default source'));

    final named = SportStageConfig(id: 'swim', sport: SportType.swimming, goal: const SportGoal.distanceMeters(200), sources: const ['pool-counter']);
    expect(catalog.stageDefinitionOf(named).allowedSources, {'pool-counter'});
    expect(catalog.stageDefinitionOf(named).metric, ProgressMetric.swimMeters);

    final byHand = SportStageConfig(
      id: 'swim', sport: SportType.swimming, goal: const SportGoal.distanceMeters(200), completion: StageCompletion.manualOnly,
    );
    final def = catalog.stageDefinitionOf(byHand);
    expect([def.policy, def.allowedSources], [CompletionPolicy.manual, {'manual'}]);
  });

  test('completion modes become the policies of the challenge', () {
    CompletionPolicy policyOf(SportGoal goal, StageCompletion c, SportType sport) =>
        catalog.stageDefinitionOf(SportStageConfig(id: 'x', sport: sport, goal: goal, completion: c)).policy;
    expect(policyOf(SportGoal.distanceKm(1), StageCompletion.confirmed, SportType.running), CompletionPolicy.sensorOrManual);
    expect(policyOf(SportGoal.distanceKm(1), StageCompletion.manualOnly, SportType.running), CompletionPolicy.manual);
    expect(policyOf(SportGoal.duration(const Duration(hours: 1)), StageCompletion.confirmed, SportType.strength), CompletionPolicy.manual);
    expect(policyOf(const SportGoal.repetitions(50), StageCompletion.automatic, SportType.strength), CompletionPolicy.auto);
  });

  test('a goal a sport does not have, a goal of 0 and half a repetition are refused, with every problem named', () {
    expect(catalog.validate(SportStageConfig(id: 'a', sport: SportType.running, goal: const SportGoal.repetitions(10))), isNotEmpty);
    expect(catalog.validate(SportStageConfig(id: 'a', sport: SportType.running, goal: const SportGoal.distanceMeters(0))), isNotEmpty);
    expect(catalog.validate(SportStageConfig(id: 'a', sport: SportType.strength, goal: const SportGoal.repetitions(1))), isEmpty);
    expect(
      () => catalog.definitionOf(id: 'x', stages: [
        SportStageConfig(id: 'a', sport: SportType.running, goal: SportGoal.distanceKm(1)),
        SportStageConfig(id: 'a', sport: SportType.swimming, goal: SportGoal.distanceKm(1)),
      ]),
      throwsA(isA<SportConfigException>().having((e) => e.problems.length, 'problems', 2)),
    );
    expect(() => catalog.definitionOf(id: 'x', stages: const []), throwsA(isA<SportConfigException>()));
  });

  test('the goals have units: km and a Duration become metres and seconds', () {
    expect(SportGoal.distanceKm(1.5).value, 1500);
    expect(SportGoal.duration(const Duration(hours: 1)).value, 3600);
    expect(const SportGoal.repetitions(20).type, GoalType.repetitions);
  });
}
