import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_challenge/flutter_challenge.dart';
import 'package:flutter_multisport/flutter_multisport.dart';

import 'main.dart' show describeStage;
import 'simulated_sources.dart';

class RunScreen extends StatefulWidget {
  const RunScreen({super.key, required this.coordinator, required this.challenge, required this.gps, required this.strap});

  final ChallengeCoordinator coordinator;
  final FlutterChallenge challenge;
  final SimulatedGps gps;
  final SimulatedHeartRate strap;

  @override
  State<RunScreen> createState() => _RunScreenState();
}

class _RunScreenState extends State<RunScreen> {
  StreamSubscription<CoordinatorEvent>? _events;
  String? _message;

  @override
  void initState() {
    super.initState();
    _events = widget.coordinator.events.listen((e) {
      if (e is StageCompleted) {
        HapticFeedback.heavyImpact(); // an app would also play a sound or show a notification here
        setState(() => _message = '${describeStage(e.config)} completed');
      } else if (e is CoordinatorError) {
        setState(() => _message = '${e.code}: ${e.message}');
      }
    });
  }

  @override
  void dispose() {
    _events?.cancel();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } on ChallengeException catch (e) {
      setState(() => _message = '${e.code}: ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.coordinator;
    return StreamBuilder<ChallengeSnapshot>(
      stream: widget.challenge.snapshots,
      initialData: c.snapshot,
      builder: (context, shot) {
        final s = shot.data;
        final stage = c.currentStage;
        final index = s?.stageIndex ?? 0;
        return Scaffold(
          appBar: AppBar(title: Text(stage == null ? 'Challenge' : 'Stage ${index + 1} of ${c.stages.length}')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (stage != null && s != null) ...[
                Text(describeStage(stage), style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: s.stageTarget <= 0 ? 0 : (s.stageProgress / s.stageTarget).clamp(0, 1).toDouble()),
                const SizedBox(height: 8),
                Text(_progressText(stage, s)),
                Text('Stage time ${_clock(s.stageElapsed)}   ·   total ${_clock(s.totalElapsed)}'),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    if (s.state == ChallengeState.active) FilledButton(onPressed: () => _run(c.pause), child: const Text('Pause')),
                    if (s.state == ChallengeState.paused) FilledButton(onPressed: () => _run(c.resume), child: const Text('Resume')),
                    if (s.state == ChallengeState.active) OutlinedButton(onPressed: () => _run(c.confirm), child: const Text('Done')),
                    if (s.state == ChallengeState.active && stage.goal.type == GoalType.repetitions)
                      OutlinedButton(onPressed: () => _run(() => c.addRepetitions(1)), child: const Text('+1 rep')),
                  ],
                ),
              ],
              if (s != null && s.state == ChallengeState.transition) ...[
                const SizedBox(height: 12),
                Text('Done! Next: ${describeStage(c.stages[index + 1])}'),
                if (c.stages[index].transition == TransitionPolicy.waitForUser)
                  FilledButton(onPressed: () => _run(c.nextStage), child: const Text('Next stage'))
                else
                  const Text('Starting by itself...'),
              ],
              if (s != null && s.state == ChallengeState.completed) ...[
                Text('Challenge completed', style: Theme.of(context).textTheme.headlineSmall),
                FilledButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ResultsScreen(results: c.results))),
                  child: const Text('See the results'),
                ),
              ],
              if (_message != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_message!)),
              const Divider(height: 32),
              Text('Simulated sensors', style: Theme.of(context).textTheme.titleSmall),
              SwitchListTile(
                title: const Text('GPS, 3 m/s'),
                value: widget.gps.running,
                onChanged: (on) => setState(() => on ? widget.gps.start() : widget.gps.stop()),
              ),
              SwitchListTile(
                title: const Text('Heart-rate strap'),
                value: widget.strap.running,
                onChanged: (on) => setState(() => on ? widget.strap.start() : widget.strap.stop()),
              ),
            ],
          ),
        );
      },
    );
  }

  String _progressText(SportStageConfig stage, ChallengeSnapshot s) => switch (stage.goal.type) {
    GoalType.distance => '${s.stageProgress.toStringAsFixed(0)} / ${s.stageTarget.toStringAsFixed(0)} m',
    GoalType.duration => '${_clock(Duration(seconds: s.stageProgress.round()))} / ${_clock(Duration(seconds: s.stageTarget.round()))}',
    GoalType.repetitions => '${s.stageProgress.toStringAsFixed(0)} / ${s.stageTarget.toStringAsFixed(0)} reps',
  };

  String _clock(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes)}:${two(d.inSeconds % 60)}';
  }
}

/// One card per stage: what the challenge decided and what the sensors recorded. A number a sensor did not give is "—", never a guess.
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key, required this.results});

  final List<StageResult> results;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Results')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [for (final r in results) _StageCard(result: r)],
    ),
  );
}

class _StageCard extends StatelessWidget {
  const _StageCard({required this.result});

  final StageResult result;

  String _n(double? v, {int digits = 0, String unit = ''}) => v == null ? '—' : '${v.toStringAsFixed(digits)}$unit';

  @override
  Widget build(BuildContext context) {
    final r = result;
    final minutes = r.activeDuration.inSeconds / 60;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${r.index + 1}. ${r.sport.name}', style: Theme.of(context).textTheme.titleMedium),
            Text('Time ${minutes.toStringAsFixed(1)} min   ·   ended by ${r.evidence?.name ?? '—'}'),
            if (r.distanceMeters != null) Text('Distance ${_n(r.distanceMeters, unit: ' m')}'),
            Text('Heart rate  avg ${_n(r.averageHeartRate)}   max ${_n(r.maxHeartRate)}'),
            Text('Cadence avg ${_n(r.averageCadence)}   ·   strokes ${_n(r.strokeCount)}'),
          ],
        ),
      ),
    );
  }
}
