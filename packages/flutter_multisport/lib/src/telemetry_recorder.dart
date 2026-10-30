import 'dart:async';
import 'dart:convert';

import 'package:flutter_challenge/flutter_challenge.dart' show CompletedStage;

import 'package:flutter_activity/flutter_activity.dart';

import 'sport.dart';
import 'telemetry.dart';

/// Records what the sensors say DURING each stage and turns it into a [StageResult].
///
/// A sample belongs to a stage by the time it was MADE, not by the time it arrived: the recorder keeps the intervals in which each stage ran
/// (a pause splits one), and a sample is filed under the interval that contains its time, even when it arrives after the stage ended. A
/// sample made outside every interval (during a pause, between two stages, before the start) is dropped and counted in [dropped].
///
/// Every record is appended to the [TelemetryStore] in order, so a result can be rebuilt after the process died ([restore]). This is NOT
/// the journal of the challenge: that one protects the progress, this one keeps the history of the sensors. The times are the wall clock
/// of the phone; the stage boundaries are the moments the coordinator saw (within about a second of the engine's own clock).
class StageTelemetryRecorder {
  StageTelemetryRecorder._(this._store, this.sessionId, this._clock);

  /// Starts recording a NEW session. Throws a [StateError] when the store already has lines for [sessionId] (a session id is used once).
  static Future<StageTelemetryRecorder> begin(TelemetryStore store, String sessionId, {DateTime Function()? clock}) async {
    if ((await store.read(sessionId)).isNotEmpty) {
      throw StateError('telemetry for "$sessionId" already exists: restore it, or clear it first');
    }
    return StageTelemetryRecorder._(store, sessionId, clock ?? DateTime.now);
  }

  /// Rebuilds the recorder of [sessionId] from its store. The stage that was running when the process died is closed at its LAST record
  /// (the dead time is not a stage time) and the recorder is paused: call [markResumed] when the challenge resumes.
  static Future<StageTelemetryRecorder> restore(TelemetryStore store, String sessionId, {DateTime Function()? clock}) async {
    final recorder = StageTelemetryRecorder._(store, sessionId, clock ?? DateTime.now);
    var lastAt = 0;
    for (final line in await store.read(sessionId)) {
      final Map<String, Object?> r;
      try {
        r = jsonDecode(line) as Map<String, Object?>;
      } on FormatException {
        continue; // a line cut by a crash
      }
      lastAt = (r['t'] as num?)?.toInt() ?? lastAt;
      recorder._apply(r);
    }
    if (recorder._open != null) {
      final at = DateTime.fromMillisecondsSinceEpoch(lastAt);
      recorder._pause(at);
      recorder._write({'k': 'pause', 't': lastAt, 'why': 'restore'});
    }
    recorder._paused = true;
    return recorder;
  }

  final TelemetryStore _store;
  final String sessionId;
  final DateTime Function() _clock;

  final Map<int, _Stage> _stages = {};
  final Map<int, List<_Interval>> _intervals = {};
  final Map<int, List<TelemetrySample>> _samples = {};
  _Interval? _open;
  int _current = -1;
  bool _stageRunning = false;
  bool _paused = false;

  Future<void> _tail = Future<void>.value();

  /// How many samples were dropped because they were made outside every stage interval.
  int dropped = 0;

  /// How many records could not be stored. 0 means everything recorded is on the store.
  int writeFailures = 0;

  bool get isDurable => writeFailures == 0;

  /// Completes when every record so far is stored.
  Future<void> flush() => _tail;

  /// The stage that is running or was last running (-1 before the first).
  int get currentStage => _current;

  bool get isPaused => _paused;

  // ── what the coordinator tells ────────────────────────────────────────────

  void markStageStarted(int index, SportStageConfig config, DateTime at) {
    if (index <= _current) return; // seen already
    _closeOpen(at);
    _current = index;
    _stageRunning = true;
    _stages[index] = _Stage(config.id, config.sport, config.goal, at);
    if (!_paused) _openInterval(index, at);
    _write({
      'k': 'start', 'i': index, 'id': config.id, 'sport': config.sport.name, 'gt': config.goal.type.name, 'gv': config.goal.value,
      't': at.millisecondsSinceEpoch,
    });
  }

  void markStageEnded(int index, DateTime at) {
    final stage = _stages[index];
    if (stage == null || stage.endedAt != null) return;
    if (index == _current) {
      _closeOpen(at);
      _stageRunning = false;
    }
    stage.endedAt = at;
    _write({'k': 'end', 'i': index, 't': at.millisecondsSinceEpoch});
  }

  void markPaused(DateTime at) {
    if (_paused) return;
    _pause(at);
    _write({'k': 'pause', 't': at.millisecondsSinceEpoch});
  }

  void markResumed(DateTime at) {
    if (!_paused) return;
    _paused = false;
    if (_stageRunning && _open == null) _openInterval(_current, at);
    _write({'k': 'resume', 't': at.millisecondsSinceEpoch});
  }

  /// Files [sample] under the stage whose interval contains its time (dropped when none does).
  void record(TelemetrySample sample) {
    final t = sample.at;
    final stage = _stageAt(t);
    if (stage == null) {
      dropped += 1;
      return;
    }
    (_samples[stage] ??= []).add(sample);
    _write({
      'k': 's', 'i': stage, 'm': sample.metric.name, 'v': sample.value, 't': t.millisecondsSinceEpoch, 'src': sample.sourceId,
    });
  }

  // ── the result ────────────────────────────────────────────────────────────

  /// The result of stage [index]. [completed] (from the challenge's snapshot) gives the duration and the evidence the challenge decided;
  /// without it the stage is still running (or was never completed) and those are absent.
  StageResult resultFor(int index, {CompletedStage? completed}) {
    final stage = _stages[index];
    if (stage == null) throw ArgumentError('stage $index was never started');
    final byMetric = <TelemetryMetric, List<TelemetrySample>>{};
    for (final s in _samples[index] ?? const <TelemetrySample>[]) {
      (byMetric[s.metric] ??= []).add(s);
    }
    final now = _clock();
    var active = Duration.zero;
    for (final i in _intervals[index] ?? const <_Interval>[]) {
      active += (i.end ?? now).difference(i.start);
    }
    final end = stage.endedAt ?? now;
    final total = end.difference(stage.startedAt);
    return StageResult(
      index: index,
      stageId: stage.id,
      sport: stage.sport,
      goal: stage.goal,
      startedAt: stage.startedAt,
      endedAt: stage.endedAt,
      activeDuration: completed?.duration ?? active,
      evidence: completed?.evidence,
      progress: completed?.progress,
      stats: {for (final e in byMetric.entries) e.key: MetricStats.fromSamples(e.key, e.value)},
      sources: {for (final list in byMetric.values) for (final s in list) s.sourceId},
      pausedDuration: total > active ? total - active : Duration.zero,
    );
  }

  // ── intervals ─────────────────────────────────────────────────────────────

  int? _stageAt(DateTime t) {
    final open = _open;
    if (open != null && !t.isBefore(open.start)) return open.stage;
    for (final entry in _intervals.entries) {
      for (final i in entry.value) {
        final end = i.end;
        if (end != null && !t.isBefore(i.start) && !t.isAfter(end)) return entry.key;
      }
    }
    return null;
  }

  void _openInterval(int stage, DateTime at) {
    final interval = _Interval(stage, at);
    (_intervals[stage] ??= []).add(interval);
    _open = interval;
  }

  void _closeOpen(DateTime at) {
    _open?.end = at;
    _open = null;
  }

  void _pause(DateTime at) {
    _closeOpen(at);
    _paused = true;
  }

  // ── persistence ───────────────────────────────────────────────────────────

  void _write(Map<String, Object?> record) {
    final line = jsonEncode(record);
    _tail = _tail.then((_) => _store.append(sessionId, line)).catchError((Object _) {
      writeFailures += 1;
    });
  }

  /// Replays one stored record (no write).
  void _apply(Map<String, Object?> r) {
    DateTime at() => DateTime.fromMillisecondsSinceEpoch((r['t'] as num).toInt());
    switch (r['k']) {
      case 'start':
        final index = (r['i'] as num).toInt();
        final sport = SportType.values.firstWhere((s) => s.name == r['sport'], orElse: () => SportType.custom);
        final type = GoalType.values.firstWhere((g) => g.name == r['gt'], orElse: () => GoalType.duration);
        final goal = switch (type) {
          GoalType.distance => SportGoal.distanceMeters((r['gv'] as num).toDouble()),
          GoalType.duration => SportGoal.duration(Duration(milliseconds: ((r['gv'] as num).toDouble() * 1000).round())),
          GoalType.repetitions => SportGoal.repetitions((r['gv'] as num).round()),
        };
        _closeOpen(at());
        _current = index;
        _stageRunning = true;
        _paused = false;
        _stages[index] = _Stage(r['id'] as String, sport, goal, at());
        _openInterval(index, at());
      case 'end':
        final index = (r['i'] as num).toInt();
        final stage = _stages[index];
        if (stage == null) return;
        if (index == _current) {
          _closeOpen(at());
          _stageRunning = false;
        }
        stage.endedAt = at();
      case 'pause':
        _pause(at());
      case 'resume':
        _paused = false;
        if (_stageRunning && _open == null) _openInterval(_current, at());
      case 's':
        final metric = TelemetryMetric.values.firstWhere((m) => m.name == r['m'], orElse: () => TelemetryMetric.heartRate);
        (_samples[(r['i'] as num).toInt()] ??= []).add(TelemetrySample(metric: metric, value: (r['v'] as num).toDouble(), at: at(), sourceId: (r['src'] as String?) ?? ''));
    }
  }
}

class _Stage {
  _Stage(this.id, this.sport, this.goal, this.startedAt);
  final String id;
  final SportType sport;
  final SportGoal goal;
  final DateTime startedAt;
  DateTime? endedAt;
}

class _Interval {
  _Interval(this.stage, this.start);
  final int stage;
  final DateTime start;
  DateTime? end;
}
