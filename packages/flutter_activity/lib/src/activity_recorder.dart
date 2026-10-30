import 'dart:async';
import 'dart:convert';

import 'activity_summary.dart';
import 'sources.dart';
import 'telemetry.dart';
import 'telemetry_store.dart';

enum ActivityState { running, paused, finished }

/// Records ONE activity from the sensors, durably, and turns it into an [ActivitySummary].
///
/// It is the history that the sensor packages do not keep: they give the latest value, the recorder keeps every value with the time it was
/// MADE. A sample counts when it was made inside a stretch of active time (a pause splits the activity), whatever the time it arrived at;
/// a sample made during a pause or before the start is dropped and counted. The same measurement twice is kept once.
///
/// Every record is appended to the [TelemetryStore] in order, so a recording that was cut by the process dying can be picked up
/// ([restore]). The recorder does not know GPS or Bluetooth: [attachTelemetry] and [attachDistance] take sources that an adapter makes
/// from them. It does not keep the route; ask the GPS recording for it.
class ActivityRecorder {
  ActivityRecorder._(this._store, this.sessionId, this.activityType, this._clock, this.coverageHold);

  /// Starts recording a NEW activity now. Throws a [StateError] when the store already has lines for [sessionId] (an id is used once).
  static Future<ActivityRecorder> begin(
    TelemetryStore store,
    String sessionId, {
    required String activityType,
    DateTime Function()? clock,
    Duration coverageHold = const Duration(seconds: 10),
  }) async {
    if ((await store.read(sessionId)).isNotEmpty) {
      throw StateError('a recording for "$sessionId" already exists: restore it, or clear it first');
    }
    final recorder = ActivityRecorder._(store, sessionId, activityType, clock ?? DateTime.now, coverageHold);
    final at = recorder._clock();
    recorder._startedAt = at;
    recorder._openInterval(at);
    recorder._write({'k': 'start', 'type': activityType, 't': at.millisecondsSinceEpoch});
    return recorder;
  }

  /// Picks up the recording of [sessionId] from its store, or null when there is none. A recording that was still running when the process
  /// died comes back PAUSED at its last record (the dead time is not active time): call [resume], or [finish].
  static Future<ActivityRecorder?> restore(
    TelemetryStore store,
    String sessionId, {
    DateTime Function()? clock,
    Duration coverageHold = const Duration(seconds: 10),
  }) async {
    final lines = await store.read(sessionId);
    if (lines.isEmpty) return null;
    ActivityRecorder? recorder;
    var lastAt = 0;
    for (final line in lines) {
      final Map<String, Object?> r;
      try {
        r = jsonDecode(line) as Map<String, Object?>;
      } on FormatException {
        continue; // a line cut by a crash
      }
      lastAt = (r['t'] as num?)?.toInt() ?? lastAt;
      if (r['k'] == 'start') {
        recorder = ActivityRecorder._(store, sessionId, (r['type'] as String?) ?? '', clock ?? DateTime.now, coverageHold);
        recorder._startedAt = DateTime.fromMillisecondsSinceEpoch(lastAt);
        recorder._openInterval(recorder._startedAt!);
      } else {
        recorder?._apply(r);
      }
    }
    if (recorder == null) return null;
    if (recorder._open != null) {
      recorder._pause(DateTime.fromMillisecondsSinceEpoch(lastAt));
      recorder._write({'k': 'pause', 't': lastAt, 'why': 'restore'});
    }
    return recorder;
  }

  final TelemetryStore _store;
  final String sessionId;
  final String activityType;
  final DateTime Function() _clock;

  /// A sample covers at most this long after it when the next one is late (see [MetricCoverage]).
  final Duration coverageHold;

  DateTime? _startedAt;
  DateTime? _endedAt;
  _Interval? _open;
  final _intervals = <_Interval>[];
  final _samples = <TelemetryMetric, List<TelemetrySample>>{};
  final _seen = <String>{};
  final _subs = <StreamSubscription<Object?>>[];
  Future<void> _tail = Future<void>.value();
  int _dropped = 0;
  int _duplicates = 0;
  int _writeFailures = 0;

  ActivityState get state => _endedAt != null ? ActivityState.finished : (_open != null ? ActivityState.running : ActivityState.paused);

  bool get isDurable => _writeFailures == 0;

  /// Completes when every record so far is stored.
  Future<void> flush() => _tail;

  // ── sources ───────────────────────────────────────────────────────────────

  /// Records the samples of [source] (heart rate, cadence, speed, ...).
  void attachTelemetry(TelemetrySource source) => _subs.add(source.samples.listen(record));

  /// Records the distance of [source] (a GPS total, a machine's counter) as a counter: the readings are made at "now minus their age".
  void attachDistance(ProgressSource source) => _subs.add(
    source.readings.listen((r) {
      record(TelemetrySample(metric: TelemetryMetric.distance, value: r.value, at: _clock().subtract(r.age), sourceId: source.sourceId));
    }),
  );

  /// Records one sample by hand (an adapter-less source, a test).
  void record(TelemetrySample sample) {
    if (_endedAt != null) return;
    if (!_isActiveAt(sample.at)) {
      _dropped += 1;
      return;
    }
    final key = '${sample.metric.name}|${sample.sourceId}|${sample.at.microsecondsSinceEpoch}';
    if (!_seen.add(key)) {
      _duplicates += 1;
      return;
    }
    (_samples[sample.metric] ??= []).add(sample);
    _write({
      'k': 's', 'm': sample.metric.name, 'v': sample.value, 't': sample.at.millisecondsSinceEpoch, 'us': sample.at.microsecondsSinceEpoch,
      'src': sample.sourceId,
    });
  }

  // ── life cycle ────────────────────────────────────────────────────────────

  void pause([DateTime? at]) {
    if (state != ActivityState.running) return;
    final when = at ?? _clock();
    _pause(when);
    _write({'k': 'pause', 't': when.millisecondsSinceEpoch});
  }

  void resume([DateTime? at]) {
    if (state != ActivityState.paused) return;
    final when = at ?? _clock();
    _openInterval(when);
    _write({'k': 'resume', 't': when.millisecondsSinceEpoch});
  }

  /// Ends the recording and returns the final summary. It stops listening to the sources and waits until everything is stored.
  Future<ActivitySummary> finish([DateTime? at]) async {
    if (_endedAt == null) {
      final when = at ?? _clock();
      _pause(when);
      _endedAt = when;
      _write({'k': 'finish', 't': when.millisecondsSinceEpoch});
    }
    await _cancelSources();
    await flush();
    return summary();
  }

  /// Stops listening to the sources (the recording stays on the store and can be restored).
  Future<void> dispose() async {
    await _cancelSources();
    await flush();
  }

  Future<void> _cancelSources() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
  }

  // ── the result ────────────────────────────────────────────────────────────

  /// The summary so far (final once [finish] was called).
  ActivitySummary summary() {
    final now = _endedAt ?? _clock();
    var active = Duration.zero;
    for (final i in _intervals) {
      active += (i.end ?? now).difference(i.start);
    }
    final total = now.difference(_startedAt!);
    final stats = <TelemetryMetric, MetricStats>{};
    final coverage = <TelemetryMetric, MetricCoverage>{};
    final sources = <TelemetryMetric, Set<String>>{};
    for (final entry in _samples.entries) {
      if (entry.value.isEmpty) continue;
      stats[entry.key] = MetricStats.fromSamples(entry.key, List.of(entry.value));
      coverage[entry.key] = _coverage(entry.value, now, active);
      sources[entry.key] = {for (final s in entry.value) s.sourceId};
    }
    return ActivitySummary(
      sessionId: sessionId,
      activityType: activityType,
      startedAt: _startedAt!,
      endedAt: _endedAt,
      isFinished: _endedAt != null,
      activeDuration: active,
      pausedDuration: total > active ? total - active : Duration.zero,
      stats: stats,
      coverage: coverage,
      sources: sources,
      droppedSamples: _dropped,
      duplicateSamples: _duplicates,
      isDurable: isDurable,
    );
  }

  /// Every sample of [metric], oldest first (for a chart).
  List<TelemetrySample> samplesOf(TelemetryMetric metric) =>
      List.of(_samples[metric] ?? const <TelemetrySample>[])..sort((a, b) => a.at.compareTo(b.at));

  /// [metric] as at most [maxPoints] points: the time is cut into equal buckets and each bucket gives the average of its samples (the last
  /// value of a counter). A bucket without samples gives no point: a hole in the history stays a hole.
  List<SeriesPoint> series(TelemetryMetric metric, {int maxPoints = 200}) {
    final samples = samplesOf(metric);
    if (samples.length <= maxPoints || maxPoints < 2) return [for (final s in samples) SeriesPoint(s.at, s.value)];
    final from = samples.first.at.microsecondsSinceEpoch;
    final span = samples.last.at.microsecondsSinceEpoch - from;
    final width = span / maxPoints;
    final buckets = <int, List<TelemetrySample>>{};
    for (final s in samples) {
      final index = width <= 0 ? 0 : ((s.at.microsecondsSinceEpoch - from) / width).floor().clamp(0, maxPoints - 1);
      (buckets[index] ??= []).add(s);
    }
    return [
      for (final i in (buckets.keys.toList()..sort()))
        SeriesPoint(
          buckets[i]!.last.at,
          metric.isCumulative ? buckets[i]!.last.value : buckets[i]!.fold<double>(0, (a, s) => a + s.value) / buckets[i]!.length,
        ),
    ];
  }

  MetricCoverage _coverage(List<TelemetrySample> samples, DateTime now, Duration active) {
    var covered = Duration.zero;
    var longest = Duration.zero;
    final sorted = List.of(samples)..sort((a, b) => a.at.compareTo(b.at));
    for (final interval in _intervals) {
      final end = interval.end ?? now;
      final inside = [for (final s in sorted) if (!s.at.isBefore(interval.start) && !s.at.isAfter(end)) s.at];
      var cursor = interval.start;
      for (var i = 0; i < inside.length; i++) {
        final gap = inside[i].difference(cursor);
        if (gap > longest) longest = gap;
        cursor = inside[i];
        // a sample covers until the next one, at most `coverageHold`
        final next = i + 1 < inside.length ? inside[i + 1] : end;
        final span = next.difference(inside[i]);
        covered += span < coverageHold ? span : coverageHold;
      }
      final tail = end.difference(cursor);
      if (tail > longest) longest = tail;
    }
    final activeMs = active.inMilliseconds;
    final ratio = activeMs <= 0 ? 0.0 : (covered.inMilliseconds / activeMs).clamp(0.0, 1.0);
    return MetricCoverage(ratio: ratio, longestGap: longest);
  }

  // ── intervals and persistence ─────────────────────────────────────────────

  bool _isActiveAt(DateTime t) {
    final open = _open;
    if (open != null && !t.isBefore(open.start)) return true;
    for (final i in _intervals) {
      final end = i.end;
      if (end != null && !t.isBefore(i.start) && !t.isAfter(end)) return true;
    }
    return false;
  }

  void _openInterval(DateTime at) {
    final interval = _Interval(at);
    _intervals.add(interval);
    _open = interval;
  }

  void _pause(DateTime at) {
    _open?.end = at;
    _open = null;
  }

  void _write(Map<String, Object?> record) {
    final line = jsonEncode(record);
    _tail = _tail.then((_) => _store.append(sessionId, line)).catchError((Object _) {
      _writeFailures += 1;
    });
  }

  /// Replays one stored record (no write).
  void _apply(Map<String, Object?> r) {
    DateTime at() => DateTime.fromMillisecondsSinceEpoch((r['t'] as num).toInt());
    switch (r['k']) {
      case 'pause':
        _pause(at());
      case 'resume':
        _openInterval(at());
      case 'finish':
        _pause(at());
        _endedAt = at();
      case 's':
        final metric = TelemetryMetric.values.firstWhere((m) => m.name == r['m'], orElse: () => TelemetryMetric.heartRate);
        final us = (r['us'] as num?)?.toInt();
        final time = us == null ? at() : DateTime.fromMicrosecondsSinceEpoch(us);
        final source = (r['src'] as String?) ?? '';
        if (_seen.add('${metric.name}|$source|${time.microsecondsSinceEpoch}')) {
          (_samples[metric] ??= []).add(TelemetrySample(metric: metric, value: (r['v'] as num).toDouble(), at: time, sourceId: source));
        }
    }
  }
}

class _Interval {
  _Interval(this.start);
  final DateTime start;
  DateTime? end;
}
