import 'dart:convert';

import 'package:flutter_activity/flutter_activity.dart';
import 'package:flutter_challenge/flutter_challenge.dart';

import 'sport.dart';
import 'sport_catalog.dart';

/// A versioned challenge plan that the host can save in its own database or
/// file. It includes registered sport profiles so a custom sport can be
/// restored with the same metric and source rules after an app restart.
class SportPlan {
  const SportPlan({
    required this.id,
    required this.stages,
    required this.profiles,
    this.version = 1,
    this.allowPause = true,
  });

  final String id;
  final int version;
  final bool allowPause;
  final List<SportProfile> profiles;
  final List<SportStageConfig> stages;

  SportCatalog get catalog => SportCatalog(profiles);

  /// Validate the entire plan before it is saved or started.
  void validate() {
    if (id.trim().isEmpty || version < 1) {
      throw const FormatException('challenge ID and version must be valid');
    }
    catalog.definitionOf(
      id: id,
      version: version,
      allowPause: allowPause,
      stages: stages,
    );
  }

  String encode() {
    validate();
    return jsonEncode({
      'schema': 1,
      'id': id,
      'version': version,
      'allowPause': allowPause,
      'profiles': [
        for (final p in profiles)
          {
            'id': p.sportId,
            'sport': p.sport.name,
            'goals': [for (final g in p.goals) g.name],
            'distanceMetric': p.distanceMetric?.name,
            'defaultSources': p.defaultSources,
            'telemetry': [for (final m in p.telemetry) m.name],
          },
      ],
      'stages': [
        for (final s in stages)
          {
            'id': s.id,
            'sport': s.sport.name,
            'sportId': s.effectiveSportId,
            'goalType': s.goal.type.name,
            'goalValue': s.goal.value,
            'sources': s.sources,
            'completion': s.completion.name,
            'transition': s.transition.name,
            'title': s.title,
          },
      ],
    });
  }

  static SportPlan decode(String encoded) {
    try {
      final root = jsonDecode(encoded);
      if (root is! Map<String, dynamic> || root['schema'] != 1) {
        throw const FormatException('unsupported sport plan schema');
      }
      final profiles = <SportProfile>[];
      for (final raw in root['profiles'] as List<dynamic>) {
        final p = raw as Map<String, dynamic>;
        profiles.add(
          SportProfile(
            sport: _enum(SportType.values, p['sport']),
            id: p['id'] as String,
            goals: {
              for (final g in p['goals'] as List<dynamic>)
                _enum(GoalType.values, g),
            },
            distanceMetric: p['distanceMetric'] == null
                ? null
                : _enum(ProgressMetric.values, p['distanceMetric']),
            defaultSources: (p['defaultSources'] as List<dynamic>)
                .cast<String>(),
            telemetry: [
              for (final m in p['telemetry'] as List<dynamic>)
                _enum(TelemetryMetric.values, m),
            ],
          ),
        );
      }
      final stages = <SportStageConfig>[];
      for (final raw in root['stages'] as List<dynamic>) {
        final s = raw as Map<String, dynamic>;
        final type = _enum(GoalType.values, s['goalType']);
        final value = s['goalValue'] as num;
        if (type == GoalType.repetitions && value != value.roundToDouble()) {
          throw const FormatException('repetition goal must be a whole number');
        }
        final goal = switch (type) {
          GoalType.distance => SportGoal.distanceMeters(value.toDouble()),
          GoalType.duration => SportGoal.duration(
            Duration(microseconds: (value * 1000000).round()),
          ),
          GoalType.repetitions => SportGoal.repetitions(value.toInt()),
        };
        stages.add(
          SportStageConfig(
            id: s['id'] as String,
            sport: _enum(SportType.values, s['sport']),
            sportId: s['sportId'] as String,
            goal: goal,
            sources: (s['sources'] as List<dynamic>?)?.cast<String>(),
            completion: _enum(StageCompletion.values, s['completion']),
            transition: _enum(TransitionPolicy.values, s['transition']),
            title: s['title'] as String?,
          ),
        );
      }
      final plan = SportPlan(
        id: root['id'] as String,
        version: root['version'] as int,
        allowPause: root['allowPause'] as bool,
        profiles: profiles,
        stages: stages,
      );
      plan.validate();
      return plan;
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException('invalid sport plan: $error');
    }
  }

  static T _enum<T extends Enum>(List<T> values, Object? name) {
    if (name is! String) throw const FormatException('missing enum value');
    for (final value in values) {
      if (value.name == name) return value;
    }
    throw FormatException('unknown enum value: $name');
  }
}
