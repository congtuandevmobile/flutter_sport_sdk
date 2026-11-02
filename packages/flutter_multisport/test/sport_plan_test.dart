import 'package:flutter_challenge/flutter_challenge.dart';
import 'package:flutter_multisport/flutter_multisport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'versioned plan restores built-in and custom sport rules and stages',
    () {
      final plan = SportPlan(
        id: 'run-swim-lift',
        profiles: [
          ...SportCatalog.standard().profiles,
          const SportProfile.custom(
            id: 'paddleboard',
            goals: {GoalType.distance, GoalType.duration},
            distanceMetric: ProgressMetric.rowMeters,
            defaultSources: ['external-paddle'],
          ),
        ],
        stages: [
          SportStageConfig(
            id: 'run',
            sport: SportType.running,
            goal: SportGoal.distanceMeters(1000),
          ),
          SportStageConfig(
            id: 'swim',
            sport: SportType.swimming,
            goal: SportGoal.distanceMeters(200),
            completion: StageCompletion.manualOnly,
            title: 'Pool 200 m',
          ),
          SportStageConfig.custom(
            id: 'paddle',
            sportId: 'paddleboard',
            goal: SportGoal.distanceMeters(500),
            title: 'Lake paddle',
          ),
          SportStageConfig(
            id: 'lift',
            sport: SportType.strength,
            goal: SportGoal.duration(Duration(hours: 1)),
          ),
        ],
      );
      final restored = SportPlan.decode(plan.encode());
      expect(restored.stages.map((s) => s.effectiveSportId), [
        'running',
        'swimming',
        'paddleboard',
        'strength',
      ]);
      expect(restored.stages[1].completion, StageCompletion.manualOnly);
      expect(restored.stages[2].title, 'Lake paddle');
      expect(
        restored.catalog.stageDefinitionOf(restored.stages[2]).metric,
        ProgressMetric.rowMeters,
      );
      expect(restored.stages[3].goal.value, 3600);
    },
  );

  test('unknown schema and corrupt profile are refused', () {
    expect(() => SportPlan.decode('{"schema":2}'), throwsFormatException);
    final plan = SportPlan(
      id: 'x',
      profiles: SportCatalog.standard().profiles,
      stages: const [
        SportStageConfig(
          id: 'a',
          sport: SportType.running,
          goal: SportGoal.distanceMeters(1),
        ),
      ],
    );
    expect(
      () => SportPlan.decode(
        plan.encode().replaceFirst('"runMeters"', '"unknownMetric"'),
      ),
      throwsFormatException,
    );
  });
}
