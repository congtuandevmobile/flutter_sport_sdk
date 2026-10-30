import 'dart:async';
import 'dart:convert';

import 'activity_summary.dart';
import 'sources.dart';
import 'telemetry.dart';
import 'telemetry_store.dart';

enum ActivityState { running, paused, finished }

/// The store refused the first record: the recording did not start.
class ActivityStoreException implements Exception {
  ActivityStoreException(this.message);
  final String message;

  @override
  String toString() => 'ActivityStoreException($message)';
}

/// Records ONE activity from the sensors, durably, and turns it into an [ActivitySummary].
///
/// It is the history that the sensor packages do not keep: they give the latest value, the recorder keeps every value with the time it was
/// MADE. A sample counts when it was made inside a stretch of active time (a pause splits the activity), whatever the time it arrived at;
/// a sample made during a pause, before the start or in the future is dropped and counted. The same measurement twice is kept once.
///
/// The distance is made by ONE source (the one named in [begin], else the first that gives a counter): the others stay in the history but
/// are never added, so a GPS and a footpod on the same run do not count it twice. A counter is only ever measured within one stretch of
/// active time and one connection (its epoch): what it did while paused, and a restart of the counter, add nothing.
///
/// Every record is appended to the [TelemetryStore] in order, so a recording that was cut by the process dying can be picked up
/// ([restore]). The recorder does not know GPS or Bluetooth: [attachTelemetry] and [attachDistance] take sources that an adapter makes
/// from them. It does not keep the route; ask the GPS recording for it. The times are the wall clock of the phone: a change of the system
/// clock during a recording distorts the active time (the native cores use a monotonic clock).
class ActivityRecorder {
  ActivityRecorder._(
    this._store,
    this.sessionId,
    this.activityType,
    this._clock,
    this.coverageHold,
    this.futureTolerance,
    this._preferredDistance,
  );

  /// Starts recording a NEW activity now. Completes only when the first record is on the store: it throws a [StateError] when the store
  /// already has lines for [sessionId] (an id is used once), and an [ActivityStoreException] when the store cannot write.
  ///
  /// [distanceSource] names the source that makes the distance; without it the first source that gives a distance counter does.
  static Future<ActivityRecorder> begin(
    TelemetryStore store,
    String sessionId, {
    required String activityType,
    String? distanceSource,
    DateTime Function()? clock,
    Duration coverageHold = const Duration(seconds: 10),
    Duration futureTolerance = const Duration(seconds: 2),
  }) async {
    if ((await store.read(sessionId)).isNotEmpty) {
      throw StateError(
        'a recording for "$sessionId" already exists: restore it, or clear it first',
      );
    }
    final recorder = ActivityRecorder._(
      store,
      sessionId,
      activityType,
      clock ?? DateTime.now,
      coverageHold,
      futureTolerance,
      distanceSource,
    );
    final at = recorder._clock();
    recorder._startedAt = at;
    recorder._openInterval(at);
    recorder._write({
      'k': 'start',
      'type': activityType,
      'dist': distanceSource,
      't': at.millisecondsSinceEpoch,
    });
    await recorder.flush();
    if (recorder._writeFailures > 0) {
      throw ActivityStoreException(
        'the first record of "$sessionId" could not be stored',
      );
    }
    return recorder;
  }

  /// Picks up the recording of [sessionId] from its store, or null when there is none. A recording that was still running when the process
  /// died comes back PAUSED at its last record (the dead time is not active time): call [resume], or [finish].
  ///
  /// The lines are checked: a cut LAST line is cut off ([RecordingRestoreStatus.tailRepaired]); a damaged line in the MIDDLE stops the replay there
  /// ([RecordingRestoreStatus.partial]: what comes after cannot be trusted, and is gone). In both cases the store is rewritten (the damaged
  /// original is kept) so that what is recorded next is not hidden behind the damage.
  static Future<ActivityRecorder?> restore(
    TelemetryStore store,
    String sessionId, {
    DateTime Function()? clock,
    Duration coverageHold = const Duration(seconds: 10),
    Duration futureTolerance = const Duration(seconds: 2),
  }) async {
    final lines = await store.read(sessionId);
    if (lines.isEmpty) return null;
    ActivityRecorder? recorder;
    int? lastAt;
    var status = RecordingRestoreStatus.intact;
    final good = <String>[];
    for (var i = 0; i < lines.length; i++) {
      final Map<String, Object?>? r = _parse(lines[i]);
      final startsTheRecording = r != null && r['k'] == 'start';
      if (r == null || (recorder == null && !startsTheRecording)) {
        if (recorder == null) {
          return null; // no usable first line: nothing to restore
        }
        status = i == lines.length - 1
            ? RecordingRestoreStatus.tailRepaired
            : RecordingRestoreStatus.partial;
        break;
      }
      // Samples may arrive after a pause/resume while carrying an older measurement time.
      // The recovery boundary must never move behind a lifecycle event already replayed.
      final recordAt = (r['t'] as num).toInt();
      if (lastAt == null || recordAt > lastAt) lastAt = recordAt;
      if (startsTheRecording) {
        if (recorder != null) {
          status = i == lines.length - 1
              ? RecordingRestoreStatus.tailRepaired
              : RecordingRestoreStatus.partial;
          break;
        }
        recorder = ActivityRecorder._(
          store,
          sessionId,
          (r['type'] as String?) ?? '',
          clock ?? DateTime.now,
          coverageHold,
          futureTolerance,
          r['dist'] as String?,
        );
        recorder._startedAt = DateTime.fromMillisecondsSinceEpoch(recordAt);
        recorder._openInterval(recorder._startedAt!);
      } else {
        recorder!._apply(r);
      }
      good.add(lines[i]);
    }
    if (recorder == null) return null;
    recorder._restoreStatus = status;
    if (status != RecordingRestoreStatus.intact) {
      try {
        await store.replace(sessionId, good);
      } catch (_) {
        recorder._writeFailures += 1;
      }
    }
    if (recorder._open != null) {
      recorder._pause(DateTime.fromMillisecondsSinceEpoch(lastAt!));
      recorder._write({'k': 'pause', 't': lastAt, 'why': 'restore'});
    }
    return recorder;
  }

  static Map<String, Object?>? _parse(String line) {
    try {
      final decoded = jsonDecode(line);
      if (decoded is! Map<String, Object?>) return null;
      final time = decoded['t'];
      if (time is! num || !time.isFinite) return null;
      DateTime.fromMillisecondsSinceEpoch(time.toInt());
      switch (decoded['k']) {
        case 'start':
          if (decoded['type'] is! String ||
              (decoded['dist'] != null && decoded['dist'] is! String)) {
            return null;
          }
        case 'pause':
        case 'resume':
        case 'finish':
          break;
        case 's':
          if (decoded['m'] is! String ||
              !TelemetryMetric.values.any((m) => m.name == decoded['m'])) {
            return null;
          }
          final value = decoded['v'];
          if (value is! num || !value.isFinite) return null;
          if (decoded['src'] != null && decoded['src'] is! String) return null;
          final micros = decoded['us'];
          if (micros != null) {
            if (micros is! num || !micros.isFinite) return null;
            DateTime.fromMicrosecondsSinceEpoch(micros.toInt());
          }
          final epoch = decoded['e'];
          if (epoch != null && (epoch is! num || !epoch.isFinite)) return null;
        default:
          return null;
      }
      return decoded;
    } on FormatException catch (_) {
      return null;
    } on ArgumentError catch (_) {
      return null;
    }
  }

  final TelemetryStore _store;
  final String sessionId;
  final String activityType;
  final DateTime Function() _clock;
  final String? _preferredDistance;

  /// A sample covers at most this long after it when the next one is late (see [MetricCoverage]).
  final Duration coverageHold;

  /// How far ahead of the phone's clock a sample may be made before it is refused.
  final Duration futureTolerance;

  DateTime? _startedAt;
  DateTime? _endedAt;
  _Interval? _open;
  final _intervals = <_Interval>[];
  final _samples = <TelemetryMetric, List<TelemetrySample>>{};
  final _seen = <String>{};
  final _subs = <StreamSubscription<Object?>>[];
  String? _firstDistanceSource;
  RecordingRestoreStatus _restoreStatus = RecordingRestoreStatus.notRestored;
  Future<void> _tail = Future<void>.value();
  int _dropped = 0;
  int _duplicates = 0;
  int _future = 0;
  int _pending = 0;
  int _writeFailures = 0;

  ActivityState get state => _endedAt != null
      ? ActivityState.finished
      : (_open != null ? ActivityState.running : ActivityState.paused);

  /// True when everything recorded is on the store RIGHT NOW (no write on its way, none failed).
  bool get isDurable => _pending == 0 && _writeFailures == 0;

  /// True when at least one write failed.
  bool get hasWriteFailures => _writeFailures > 0;

  /// The source whose counter makes the distance (null until one gave a counter and none was named).
  String? get distanceSource => _preferredDistance ?? _firstDistanceSource;

  /// Completes when every record so far is stored.
  Future<void> flush() => _tail;

  // ── sources ───────────────────────────────────────────────────────────────

  /// Records the samples of [source] (heart rate, cadence, speed, ...).
  void attachTelemetry(TelemetrySource source) =>
      _subs.add(source.samples.listen(record));

  /// Records the distance of [source] (a GPS total, a machine's counter) as a counter, made at "now minus its age", with its epoch.
  void attachDistance(ProgressSource source) => _subs.add(
    source.readings.listen((r) {
      record(
        TelemetrySample(
          metric: TelemetryMetric.distance,
          value: r.value,
          at: _clock().subtract(r.age),
          sourceId: source.sourceId,
          epoch: r.epoch,
        ),
      );
    }),
  );

  /// Records one sample by hand (a source without an adapter, a test).
  void record(TelemetrySample sample) {
    if (_endedAt != null) return;
    if (sample.at.isAfter(_clock().add(futureTolerance))) {
      _future += 1;
      return;
    }
    if (!_isActiveAt(sample.at)) {
      _dropped += 1;
      return;
    }
    final key =
        '${sample.metric.name}|${sample.sourceId}|${sample.at.microsecondsSinceEpoch}';
    if (!_seen.add(key)) {
      _duplicates += 1;
      return;
    }
    _add(sample);
    _write({
      'k': 's',
      'm': sample.metric.name,
      'v': sample.value,
      't': sample.at.millisecondsSinceEpoch,
      'us': sample.at.microsecondsSinceEpoch,
      'src': sample.sourceId,
      'e': sample.epoch,
    });
  }

  void _add(TelemetrySample s) {
    (_samples[s.metric] ??= []).add(s);
    if (s.metric == TelemetryMetric.distance) {
      _firstDistanceSource ??= s.sourceId;
    }
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
      var samples = entry.value;
      // ONE source makes the distance: the others stay in the history (and in `sources`) but are never added
      if (entry.key == TelemetryMetric.distance) {
        final primary = distanceSource;
        samples = [
          for (final s in samples)
            if (s.sourceId == primary) s,
        ];
      }
      if (samples.isNotEmpty) {
        stats[entry.key] = MetricStats.fromSamples(
          entry.key,
          List.of(samples),
          segmentOf: _segmentOf,
        );
        coverage[entry.key] = _coverage(samples, now, active);
      }
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
      rejectedFutureSamples: _future,
      distanceSource: _samples[TelemetryMetric.distance]?.isNotEmpty ?? false
          ? distanceSource
          : null,
      restoreStatus: _restoreStatus,
      isDurable: isDurable,
      hasWriteFailures: hasWriteFailures,
    );
  }

  /// Every sample of [metric], oldest first (for a chart).
  List<TelemetrySample> samplesOf(TelemetryMetric metric) =>
      List.of(_samples[metric] ?? const <TelemetrySample>[])
        ..sort((a, b) => a.at.compareTo(b.at));

  /// [metric] as at most [maxPoints] points: the time is cut into equal buckets and each bucket gives the average of its samples (the last
  /// value of a counter). A bucket without samples gives no point: a hole in the history stays a hole.
  List<SeriesPoint> series(TelemetryMetric metric, {int maxPoints = 200}) =>
      telemetrySeries(samplesOf(metric), metric, maxPoints: maxPoints);

  /// The stretch of active time (the index of its interval) that [s] was made in; -1 when none (cannot happen for a recorded sample).
  int _segmentOf(TelemetrySample s) {
    for (var i = 0; i < _intervals.length; i++) {
      final end = _intervals[i].end;
      if (!s.at.isBefore(_intervals[i].start) &&
          (end == null || !s.at.isAfter(end))) {
        return i;
      }
    }
    return -1;
  }

  MetricCoverage _coverage(
    List<TelemetrySample> samples,
    DateTime now,
    Duration active,
  ) {
    var covered = Duration.zero;
    var longest = Duration.zero;
    final sorted = List.of(samples)..sort((a, b) => a.at.compareTo(b.at));
    for (final interval in _intervals) {
      final end = interval.end ?? now;
      final inside = [
        for (final s in sorted)
          if (!s.at.isBefore(interval.start) && !s.at.isAfter(end)) s.at,
      ];
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
    final ratio = activeMs <= 0
        ? 0.0
        : (covered.inMilliseconds / activeMs).clamp(0.0, 1.0);
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
    _pending += 1;
    _tail = _tail.then((_) async {
      try {
        await _store.append(sessionId, line);
      } catch (_) {
        _writeFailures += 1;
      } finally {
        _pending -= 1;
      }
    });
  }

  /// Replays one stored record (no write).
  void _apply(Map<String, Object?> r) {
    DateTime at() =>
        DateTime.fromMillisecondsSinceEpoch((r['t'] as num).toInt());
    switch (r['k']) {
      case 'pause':
        _pause(at());
      case 'resume':
        _openInterval(at());
      case 'finish':
        _pause(at());
        _endedAt = at();
      case 's':
        final metric = TelemetryMetric.values.firstWhere(
          (m) => m.name == r['m'],
          orElse: () => TelemetryMetric.heartRate,
        );
        final us = (r['us'] as num?)?.toInt();
        final time = us == null
            ? at()
            : DateTime.fromMicrosecondsSinceEpoch(us);
        final source = (r['src'] as String?) ?? '';
        if (_seen.add(
          '${metric.name}|$source|${time.microsecondsSinceEpoch}',
        )) {
          _add(
            TelemetrySample(
              metric: metric,
              value: (r['v'] as num).toDouble(),
              at: time,
              sourceId: source,
              epoch: (r['e'] as num?)?.toInt() ?? 1,
            ),
          );
        }
    }
  }
}

class _Interval {
  _Interval(this.start);
  final DateTime start;
  DateTime? end;
}
