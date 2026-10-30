import 'package:flutter/material.dart';
import 'package:flutter_challenge/flutter_challenge.dart';
import 'package:flutter_multisport/flutter_multisport.dart';

import 'run_screen.dart';
import 'simulated_sources.dart';

void main() => runApp(const MultisportDemoApp());

/// Create a multisport challenge, run it, read the result of each stage. The sensors are simulated (a GPS that counts 3 m/s, a heart-rate
/// strap); a real app attaches `flutter_multisport_adapters` sources instead and a `FileTelemetryStore`.
class MultisportDemoApp extends StatelessWidget {
  const MultisportDemoApp({super.key, this.challenge, this.store});

  /// Give a `FlutterChallenge(platform: FakeChallengePlatform())` in a test.
  final FlutterChallenge? challenge;
  final TelemetryStore? store;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Multisport',
    theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
    home: CreateChallengeScreen(challenge: challenge ?? FlutterChallenge(), store: store ?? MemoryTelemetryStore()),
  );
}

class CreateChallengeScreen extends StatefulWidget {
  const CreateChallengeScreen({super.key, required this.challenge, required this.store});

  final FlutterChallenge challenge;
  final TelemetryStore store;

  @override
  State<CreateChallengeScreen> createState() => _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends State<CreateChallengeScreen> {
  final _catalog = SportCatalog.standard();
  final _stages = <SportStageConfig>[];
  String? _error;

  Future<void> _add() async {
    final config = await showDialog<SportStageConfig>(
      context: context,
      builder: (_) => AddStageDialog(catalog: _catalog, id: 'stage-${_stages.length + 1}'),
    );
    if (config != null) setState(() => _stages.add(config));
  }

  Future<void> _start() async {
    final coordinator = ChallengeCoordinator(challenge: widget.challenge, store: widget.store, catalog: _catalog);
    final gps = SimulatedGps();
    final strap = SimulatedHeartRate();
    coordinator.attachProgress(gps);
    coordinator.attachTelemetry(strap);
    try {
      await coordinator.start(sessionId: 'demo-${DateTime.now().millisecondsSinceEpoch}', stages: List.of(_stages));
    } on SportConfigException catch (e) {
      setState(() => _error = e.problems.join('\n'));
      return;
    } on ChallengeException catch (e) {
      setState(() => _error = '${e.code}: ${e.message}');
      return;
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RunScreen(coordinator: coordinator, challenge: widget.challenge, gps: gps, strap: strap),
      ),
    );
    gps.stop();
    strap.stop();
    await coordinator.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create challenge')),
    body: Column(
      children: [
        Expanded(
          child: _stages.isEmpty
              ? const Center(child: Text('Add the sports of your challenge, in order.'))
              : ReorderableListView(
                  onReorder: (from, to) => setState(() {
                    if (to > from) to -= 1;
                    _stages.insert(to, _stages.removeAt(from));
                  }),
                  children: [
                    for (var i = 0; i < _stages.length; i++)
                      ListTile(
                        key: ValueKey(_stages[i].id),
                        leading: CircleAvatar(child: Text('${i + 1}')),
                        title: Text(describeStage(_stages[i])),
                        subtitle: Text(_stages[i].transition == TransitionPolicy.autoNext ? 'then starts the next by itself' : 'then waits for you'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Remove',
                          onPressed: () => setState(() => _stages.removeAt(i)),
                        ),
                      ),
                  ],
                ),
        ),
        if (_error != null) Padding(padding: const EdgeInsets.all(12), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              OutlinedButton.icon(onPressed: _add, icon: const Icon(Icons.add), label: const Text('Add stage')),
              const Spacer(),
              FilledButton(onPressed: _stages.isEmpty ? null : _start, child: const Text('Start challenge')),
            ],
          ),
        ),
      ],
    ),
  );
}

/// "Running 1.5 km", "Football 60 min", "Strength 20 reps".
String describeStage(SportStageConfig c) {
  final name = c.sport.name[0].toUpperCase() + c.sport.name.substring(1);
  final g = c.goal;
  return switch (g.type) {
    GoalType.distance => g.value >= 1000 ? '$name ${(g.value / 1000).toStringAsFixed(g.value % 1000 == 0 ? 0 : 1)} km' : '$name ${g.value.toStringAsFixed(0)} m',
    GoalType.duration => '$name ${(g.value / 60).toStringAsFixed(g.value % 60 == 0 ? 0 : 1)} min',
    GoalType.repetitions => '$name ${g.value.toStringAsFixed(0)} reps',
  };
}

/// The form of one stage, made from the catalog: the sports it knows, the goals the chosen sport has, and the number of the goal.
class AddStageDialog extends StatefulWidget {
  const AddStageDialog({super.key, required this.catalog, required this.id});

  final SportCatalog catalog;
  final String id;

  @override
  State<AddStageDialog> createState() => _AddStageDialogState();
}

class _AddStageDialogState extends State<AddStageDialog> {
  SportType _sport = SportType.running;
  GoalType _goal = GoalType.distance;
  final _value = TextEditingController(text: '1');
  bool _autoNext = false;
  bool _byHand = false;

  void _pick(SportType sport) {
    setState(() {
      _sport = sport;
      final goals = widget.catalog.goalsOf(sport);
      if (!goals.contains(_goal)) _goal = goals.first;
    });
  }

  String get _unit => switch (_goal) {
    GoalType.distance => 'km',
    GoalType.duration => 'minutes',
    GoalType.repetitions => 'reps',
  };

  SportStageConfig? _build() {
    final n = double.tryParse(_value.text.replaceAll(',', '.'));
    if (n == null) return null;
    final goal = switch (_goal) {
      GoalType.distance => SportGoal.distanceKm(n),
      GoalType.duration => SportGoal.duration(Duration(milliseconds: (n * 60000).round())),
      GoalType.repetitions => SportGoal.repetitions(n.round()),
    };
    return SportStageConfig(
      id: widget.id,
      sport: _sport,
      goal: goal,
      // a sport without a standard source (swimming, rowing) is completed by hand unless the app names a source
      completion: _byHand ? StageCompletion.manualOnly : StageCompletion.automatic,
      transition: _autoNext ? TransitionPolicy.autoNext : TransitionPolicy.waitForUser,
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = _build();
    final problems = config == null ? ['enter a number'] : widget.catalog.validate(config);
    return AlertDialog(
      title: const Text('Add stage'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<SportType>(
              value: _sport,
              isExpanded: true,
              items: [for (final s in widget.catalog.sports) DropdownMenuItem(value: s, child: Text(s.name))],
              onChanged: (s) => _pick(s!),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final g in widget.catalog.goalsOf(_sport))
                  ChoiceChip(label: Text(g.name), selected: _goal == g, onSelected: (_) => setState(() => _goal = g)),
              ],
            ),
            TextField(
              controller: _value,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'Target', suffixText: _unit),
              onChanged: (_) => setState(() {}),
            ),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Start the next stage by itself'), value: _autoNext, onChanged: (v) => setState(() => _autoNext = v)),
            if (_goal != GoalType.duration)
              SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('I end it by hand'), value: _byHand, onChanged: (v) => setState(() => _byHand = v)),
            for (final p in problems) Text(p, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: problems.isEmpty ? () => Navigator.pop(context, config) : null, child: const Text('Add')),
      ],
    );
  }
}
