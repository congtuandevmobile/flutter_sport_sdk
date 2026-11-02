import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_challenge/flutter_challenge.dart';
import 'package:flutter_multisport/flutter_multisport.dart';
import 'package:flutter_sport_ble/flutter_sport_ble.dart';
import 'package:flutter_tracking_gps/flutter_tracking_gps.dart';

import 'real_sport_flow.dart';

/// A reference host flow with real phone GPS and optional BLE devices. The UI
/// deliberately owns permissions, device choice, plan editing and history.
class RealFlowScreen extends StatefulWidget {
  const RealFlowScreen({super.key});

  @override
  State<RealFlowScreen> createState() => _RealFlowScreenState();
}

class _RealFlowScreenState extends State<RealFlowScreen> {
  RealSportFlow? _flow;
  StreamSubscription<SensorSnapshot>? _bleSub;
  StreamSubscription<SportDevice>? _scanSub;
  StreamSubscription<TrackingSnapshot>? _gpsSub;
  StreamSubscription<ChallengeSnapshot>? _challengeSub;
  StreamSubscription<CoordinatorEvent>? _eventSub;
  SensorSnapshot _ble = const SensorSnapshot.empty();
  TrackingSnapshot? _gps;
  ChallengeSnapshot? _challenge;
  final _found = <String, SportDevice>{};
  List<Map<String, String>> _history = [];
  String? _message;
  bool _busy = false;
  final _runMeters = TextEditingController(text: '1000');
  final _swimMeters = TextEditingController(text: '200');
  final _strengthMinutes = TextEditingController(text: '60');
  final _profiles = <SportProfile>[...SportCatalog.standard().profiles];
  final _draftStages = <SportStageConfig>[];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    RealSportFlow? flow;
    try {
      flow = await RealSportFlow.create();
      _bleSub = flow.bleSnapshots.listen((s) {
        if (mounted) setState(() => _ble = s);
      });
      _scanSub = flow.ble.devices.listen((d) {
        if (mounted) setState(() => _found[d.id] = d);
      });
      await flow.restoreActive();
      _bind(flow);
      final history = await flow.history();
      if (mounted) {
        setState(() {
          _flow = flow;
          _history = history;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _flow = flow;
          _message = 'Restore failed: $error';
        });
      }
    }
  }

  void _bind(RealSportFlow flow) {
    _gpsSub?.cancel();
    _challengeSub?.cancel();
    _eventSub?.cancel();
    _gps = flow.tracking?.snapshot;
    _challenge = flow.coordinator?.snapshot;
    _gpsSub = flow.tracking?.updates.listen((s) {
      if (mounted) setState(() => _gps = s);
    });
    _challengeSub = flow.challenge.snapshots.listen((s) {
      if (mounted) setState(() => _challenge = s);
    });
    _eventSub = flow.coordinator?.events.listen((event) {
      if (event is StageCompleted) {
        HapticFeedback.heavyImpact();
        if (mounted) {
          setState(
            () => _message =
                '${event.config.title ?? event.config.effectiveSportId} completed',
          );
        }
      } else if (event is CoordinatorError) {
        if (mounted) {
          setState(() => _message = '${event.code}: ${event.message}');
        }
      }
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
      final flow = _flow;
      if (flow != null) {
        _bind(flow);
        final history = await flow.history();
        if (mounted) setState(() => _history = history);
      }
    } catch (error) {
      if (mounted) setState(() => _message = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  SportPlan _examplePlan() {
    final run = double.parse(_runMeters.text);
    final swim = double.parse(_swimMeters.text);
    final strength = double.parse(_strengthMinutes.text);
    return SportPlan(
      id: 'run-swim-strength',
      profiles: SportCatalog.standard().profiles,
      stages: [
        SportStageConfig(
          id: 'run',
          sport: SportType.running,
          goal: SportGoal.distanceMeters(run),
          title: 'Run ${run.toStringAsFixed(0)} m',
        ),
        SportStageConfig(
          id: 'swim',
          sport: SportType.swimming,
          goal: SportGoal.distanceMeters(swim),
          sources: const ['manual'],
          completion: StageCompletion.manualOnly,
          title: 'Swim ${swim.toStringAsFixed(0)} m',
        ),
        SportStageConfig(
          id: 'strength',
          sport: SportType.strength,
          goal: SportGoal.duration(
            Duration(milliseconds: (strength * 60000).round()),
          ),
          title: 'Strength $strength min',
        ),
      ],
    );
  }

  Future<void> _addSport() async {
    final id = TextEditingController();
    final source = TextEditingController();
    var withDistance = false;
    var metric = ProgressMetric.runMeters;
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('Add sport profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: id,
                  decoration: const InputDecoration(
                    labelText: 'Unique sport ID',
                  ),
                ),
                SwitchListTile(
                  title: const Text('Distance goal (metres)'),
                  value: withDistance,
                  onChanged: (v) => update(() => withDistance = v),
                ),
                if (withDistance)
                  DropdownButtonFormField<ProgressMetric>(
                    initialValue: metric,
                    decoration: const InputDecoration(
                      labelText: 'Native metric',
                    ),
                    items:
                        const [
                              ProgressMetric.runMeters,
                              ProgressMetric.rowMeters,
                              ProgressMetric.skiMeters,
                              ProgressMetric.sledMeters,
                              ProgressMetric.swimMeters,
                              ProgressMetric.cycleMeters,
                            ]
                            .map(
                              (m) => DropdownMenuItem(
                                value: m,
                                child: Text(m.name),
                              ),
                            )
                            .toList(),
                    onChanged: (v) => update(() => metric = v ?? metric),
                  ),
                TextField(
                  controller: source,
                  decoration: const InputDecoration(
                    labelText: 'Default source ID (optional)',
                    hintText: 'gps, manual, or a device source',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    if (save == true) {
      final profile = SportProfile.custom(
        id: id.text.trim(),
        goals: {
          GoalType.duration,
          GoalType.repetitions,
          if (withDistance) GoalType.distance,
        },
        distanceMetric: withDistance ? metric : null,
        defaultSources: source.text.trim().isEmpty
            ? const ['manual']
            : [source.text.trim()],
        telemetry: const [TelemetryMetric.heartRate, TelemetryMetric.cadence],
      );
      SportCatalog([..._profiles, profile]);
      if (mounted) setState(() => _profiles.add(profile));
    }
    id.dispose();
    source.dispose();
  }

  Future<void> _addStage() async {
    var profile = _profiles.first;
    var goalType = profile.goals.first;
    var completion = StageCompletion.automatic;
    var transition = TransitionPolicy.waitForUser;
    final target = TextEditingController(text: '1000');
    final source = TextEditingController();
    final title = TextEditingController();
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('Add challenge stage'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<SportProfile>(
                  initialValue: profile,
                  decoration: const InputDecoration(labelText: 'Sport'),
                  items: [
                    for (final p in _profiles)
                      DropdownMenuItem(value: p, child: Text(p.sportId)),
                  ],
                  onChanged: (v) => update(() {
                    profile = v ?? profile;
                    goalType = profile.goals.first;
                  }),
                ),
                DropdownButtonFormField<GoalType>(
                  key: ValueKey(profile.sportId),
                  initialValue: goalType,
                  decoration: const InputDecoration(labelText: 'Goal'),
                  items: [
                    for (final g in profile.goals)
                      DropdownMenuItem(value: g, child: Text(g.name)),
                  ],
                  onChanged: (v) => update(() => goalType = v ?? goalType),
                ),
                TextField(
                  controller: target,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText:
                        'Target (${switch (goalType) {
                          GoalType.distance => 'metres',
                          GoalType.duration => 'seconds',
                          GoalType.repetitions => 'reps',
                        }})',
                  ),
                ),
                TextField(
                  controller: title,
                  decoration: const InputDecoration(
                    labelText: 'Display title (optional)',
                  ),
                ),
                TextField(
                  controller: source,
                  decoration: const InputDecoration(
                    labelText: 'Override source ID (optional)',
                  ),
                ),
                DropdownButtonFormField<StageCompletion>(
                  initialValue: completion,
                  decoration: const InputDecoration(labelText: 'Completion'),
                  items: [
                    for (final c in StageCompletion.values)
                      DropdownMenuItem(value: c, child: Text(c.name)),
                  ],
                  onChanged: (v) => update(() => completion = v ?? completion),
                ),
                DropdownButtonFormField<TransitionPolicy>(
                  initialValue: transition,
                  decoration: const InputDecoration(
                    labelText: 'After completion',
                  ),
                  items: [
                    for (final t in TransitionPolicy.values)
                      DropdownMenuItem(value: t, child: Text(t.name)),
                  ],
                  onChanged: (v) => update(() => transition = v ?? transition),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    if (save == true) {
      final amount = double.parse(target.text);
      final goal = switch (goalType) {
        GoalType.distance => SportGoal.distanceMeters(amount),
        GoalType.duration => SportGoal.duration(
          Duration(milliseconds: (amount * 1000).round()),
        ),
        GoalType.repetitions => SportGoal.repetitions(amount.toInt()),
      };
      if (goalType == GoalType.repetitions &&
          amount != amount.roundToDouble()) {
        throw const FormatException('repetitions must be a whole number');
      }
      final stage = SportStageConfig(
        id: 'stage-${DateTime.now().microsecondsSinceEpoch}',
        sport: profile.sport,
        sportId: profile.id,
        goal: goal,
        sources: source.text.trim().isEmpty ? null : [source.text.trim()],
        completion: completion,
        transition: transition,
        title: title.text.trim().isEmpty ? null : title.text.trim(),
      );
      SportCatalog(_profiles).stageDefinitionOf(stage);
      if (mounted) setState(() => _draftStages.add(stage));
    }
    target.dispose();
    source.dispose();
    title.dispose();
  }

  Future<void> _startDraft(RealSportFlow flow) => flow.startChallenge(
    SportPlan(
      id: 'custom-${DateTime.now().microsecondsSinceEpoch}',
      profiles: _profiles,
      stages: _draftStages,
    ),
  );

  Future<void> _addManualStageProgress(RealSportFlow flow) async {
    final amount = TextEditingController(text: '1');
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add measured progress'),
        content: TextField(
          controller: amount,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Metres or repetitions'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (save == true) await flow.addManualProgress(double.parse(amount.text));
    amount.dispose();
  }

  Future<void> _showHistory(Map<String, String> item) async {
    final flow = _flow!;
    final id = item['id']!;
    if (item['kind'] == 'activity') {
      final recorder = await flow.activityHistory(id);
      if (recorder == null) return;
      final summary = recorder.summary();
      final hr = recorder.series(TelemetryMetric.heartRate);
      final cadence = recorder.series(TelemetryMetric.cadence);
      final route = await flow.routeHistory(id);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Activity history')),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(id),
                Text(
                  'Distance: ${summary.distanceMeters?.toStringAsFixed(0) ?? '—'} m',
                ),
                Text(
                  'Active: ${summary.activeDuration.inMinutes} min; route fixes: ${route.length}',
                ),
                Text(
                  'Heart rate: avg ${summary.averageHeartRate?.toStringAsFixed(0) ?? '—'}, max ${summary.maxHeartRate?.toStringAsFixed(0) ?? '—'} bpm',
                ),
                SizedBox(
                  height: 140,
                  child: CustomPaint(painter: _SeriesPainter(hr)),
                ),
                Text(
                  'Heart-rate samples: ${hr.length}; cadence samples: ${cadence.length}',
                ),
                Text(
                  'Stored: ${summary.isDurable}; restore: ${summary.restoreStatus.name}',
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      final saved = await flow.challengeHistory(id);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Challenge history')),
            body: ListView(
              children: [
                for (var i = 0; i < saved.results.length; i++)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(saved.results[i].displayName),
                          Text(
                            'Progress ${saved.results[i].progress?.toStringAsFixed(0) ?? '—'} / ${saved.results[i].goal.value.toStringAsFixed(0)}; active ${saved.results[i].activeDuration.inMinutes} min; evidence ${saved.results[i].evidence?.name ?? '—'}',
                          ),
                          Text(
                            'HR avg ${saved.results[i].averageHeartRate?.toStringAsFixed(0) ?? '—'} bpm · ${saved.heartRate[i].length} HR samples · ${saved.cadence[i].length} cadence samples',
                          ),
                          SizedBox(
                            height: 100,
                            child: CustomPaint(
                              painter: _SeriesPainter(saved.heartRate[i]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _bleSub?.cancel();
    _scanSub?.cancel();
    _gpsSub?.cancel();
    _challengeSub?.cancel();
    _eventSub?.cancel();
    unawaited(_flow?.dispose());
    _runMeters.dispose();
    _swimMeters.dispose();
    _strengthMinutes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flow = _flow;
    final challenge = _challenge;
    final activeStage = flow?.coordinator?.currentStage;
    return Scaffold(
      appBar: AppBar(title: const Text('Real sport flow')),
      body: flow == null
          ? Center(
              child: _message == null
                  ? const CircularProgressIndicator()
                  : Text(_message!),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_message != null)
                  Text(
                    _message!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                Text(
                  'GPS ${_gps?.totalMeters.toStringAsFixed(0) ?? '—'} m · HR ${_ble.heartRateBpm ?? '—'} bpm · cadence ${_ble.runningCadencePerMin?.toStringAsFixed(0) ?? '—'}',
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => _run(() => flow.ble.startScan()),
                  child: const Text('Scan BLE devices'),
                ),
                OutlinedButton(
                  onPressed: _busy ? null : () => _run(flow.ble.stopScan),
                  child: const Text('Stop scan'),
                ),
                for (final device in _found.values)
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(device.name ?? device.id),
                          subtitle: Text(device.id),
                        ),
                        Wrap(
                          spacing: 4,
                          children: [
                            TextButton(
                              onPressed: () =>
                                  _run(() => flow.connectDevice(device.id)),
                              child: const Text('Connect'),
                            ),
                            TextButton(
                              onPressed: () => _run(
                                () => flow.preferDevice(
                                  SportMetric.heartRate,
                                  device.id,
                                ),
                              ),
                              child: const Text('Use HR'),
                            ),
                            TextButton(
                              onPressed: () => _run(
                                () => flow.preferDevice(
                                  SportMetric.runningCadence,
                                  device.id,
                                ),
                              ),
                              child: const Text('Use cadence'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  _run(() => flow.disconnectDevice(device.id)),
                              child: const Text('Disconnect'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const Divider(),
                if (flow.sessionId == null) ...[
                  FilledButton(
                    onPressed: _busy ? null : () => _run(flow.startActivity),
                    child: const Text('Record GPS activity (+ optional BLE)'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Example challenge: run → swim manually → strength by time',
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _runMeters,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Run m'),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _swimMeters,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Swim m',
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _strengthMinutes,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Strength min',
                          ),
                        ),
                      ),
                    ],
                  ),
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () => _run(() => flow.startChallenge(_examplePlan())),
                    child: const Text('Start challenge'),
                  ),
                  const Divider(),
                  const Text('Build a custom challenge'),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: _busy ? null : () => _run(_addSport),
                        child: const Text('Add sport'),
                      ),
                      OutlinedButton(
                        onPressed: _busy ? null : () => _run(_addStage),
                        child: const Text('Add stage'),
                      ),
                    ],
                  ),
                  for (var i = 0; i < _draftStages.length; i++)
                    ListTile(
                      title: Text(
                        _draftStages[i].title ??
                            _draftStages[i].effectiveSportId,
                      ),
                      subtitle: Text(
                        '${_draftStages[i].goal.value.toStringAsFixed(0)} ${_draftStages[i].goal.type.name}',
                      ),
                      trailing: IconButton(
                        onPressed: () =>
                            setState(() => _draftStages.removeAt(i)),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                  FilledButton(
                    onPressed: _busy || _draftStages.isEmpty
                        ? null
                        : () => _run(() => _startDraft(flow)),
                    child: const Text('Start custom challenge'),
                  ),
                ] else ...[
                  Text('Session ${flow.sessionId}'),
                  if (challenge != null && flow.kind == 'challenge') ...[
                    Text(
                      'Stage: ${activeStage?.title ?? activeStage?.effectiveSportId ?? 'completed'}',
                    ),
                    Text(
                      'Progress: ${challenge.stageProgress.toStringAsFixed(0)} / ${challenge.stageTarget.toStringAsFixed(0)}',
                    ),
                    if (challenge.state == ChallengeState.transition)
                      FilledButton(
                        onPressed: _busy ? null : () => _run(flow.nextStage),
                        child: const Text('Next stage'),
                      ),
                    if (challenge.state == ChallengeState.active &&
                        activeStage != null &&
                        activeStage.goal.type != GoalType.duration &&
                        flow.plan!.catalog
                            .stageDefinitionOf(activeStage)
                            .allowedSources
                            .contains('manual'))
                      OutlinedButton(
                        onPressed: _busy
                            ? null
                            : () => _run(() => _addManualStageProgress(flow)),
                        child: const Text('Add manual progress'),
                      ),
                    if (challenge.state == ChallengeState.active &&
                        activeStage?.completion != StageCompletion.automatic)
                      OutlinedButton(
                        onPressed: _busy ? null : () => _run(flow.confirmStage),
                        child: const Text('Done with stage'),
                      ),
                    if (challenge.state == ChallengeState.completed)
                      FilledButton(
                        onPressed: _busy
                            ? null
                            : () => _run(() async {
                                await flow.archiveChallenge();
                              }),
                        child: const Text('Save challenge results'),
                      ),
                  ],
                  if (flow.kind == 'activity')
                    FilledButton(
                      onPressed: _busy
                          ? null
                          : () => _run(() async {
                              await flow.finishActivity();
                            }),
                      child: const Text('Finish and save activity'),
                    ),
                  if ((flow.kind == 'activity' &&
                          flow.activity?.state == ActivityState.running) ||
                      (challenge?.state == ChallengeState.active))
                    OutlinedButton(
                      onPressed: _busy ? null : () => _run(flow.pause),
                      child: const Text('Pause'),
                    ),
                  if ((flow.kind == 'activity' &&
                          flow.activity?.state == ActivityState.paused) ||
                      challenge?.state == ChallengeState.paused)
                    OutlinedButton(
                      onPressed: _busy ? null : () => _run(flow.resume),
                      child: const Text('Resume'),
                    ),
                ],
                const Divider(),
                const Text('Saved sessions'),
                for (final item in _history.reversed)
                  ListTile(
                    title: Text(item['kind'] ?? 'session'),
                    subtitle: Text(item['id'] ?? ''),
                    onTap: flow.sessionId != null && item['kind'] == 'challenge'
                        ? null
                        : () => _run(() => _showHistory(item)),
                  ),
              ],
            ),
    );
  }
}

class _SeriesPainter extends CustomPainter {
  const _SeriesPainter(this.points);
  final List<SeriesPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final minTime = points.first.at.microsecondsSinceEpoch;
    final span = points.last.at.microsecondsSinceEpoch - minTime;
    final values = points.map((p) => p.value);
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final valueSpan = maxValue - minValue;
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = span == 0
          ? 0.0
          : (points[i].at.microsecondsSinceEpoch - minTime) / span * size.width;
      final y = valueSpan == 0
          ? size.height / 2
          : size.height -
                (points[i].value - minValue) / valueSpan * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFD32F2F)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _SeriesPainter oldDelegate) =>
      oldDelegate.points != points;
}
