import 'dart:async';
import 'dart:io';

import 'package:flutter_activity/flutter_activity.dart';
import 'package:flutter_test/flutter_test.dart';

class _Strap implements TelemetrySource {
  final controller = StreamController<TelemetrySample>.broadcast();
  @override
  Stream<TelemetrySample> get samples => controller.stream;
}

class _Gps implements ProgressSource {
  final controller = StreamController<CounterReading>.broadcast();
  @override
  String get sourceId => 'gps';
  @override
  Stream<CounterReading> get readings => controller.stream;
}

void main() {
  final t0 = DateTime(2026, 1, 1, 10);
  late MemoryTelemetryStore store;
  late DateTime now;
  late ActivityRecorder recorder;

  DateTime at(int seconds) => t0.add(Duration(seconds: seconds));
  // the phone's clock is never behind a measurement it just received: put() moves the clock to the time of the sample
  void putTo(ActivityRecorder r, TelemetrySample sample) {
    if (sample.at.isAfter(now)) now = sample.at;
    r.record(sample);
  }

  TelemetrySample hr(int seconds, double bpm, {String source = 'strap'}) =>
      TelemetrySample(
        metric: TelemetryMetric.heartRate,
        value: bpm,
        at: at(seconds),
        sourceId: source,
      );
  TelemetrySample cadence(int seconds, double spm) => TelemetrySample(
    metric: TelemetryMetric.cadence,
    value: spm,
    at: at(seconds),
    sourceId: 'footpod',
  );
  TelemetrySample dist(int seconds, double total) => TelemetrySample(
    metric: TelemetryMetric.distance,
    value: total,
    at: at(seconds),
    sourceId: 'gps',
  );

  setUp(() async {
    store = MemoryTelemetryStore();
    now = t0;
    recorder = await ActivityRecorder.begin(
      store,
      's1',
      activityType: 'running',
      clock: () => now,
    );
  });

  test(
    'a run with a heart-rate strap, a footpod and GPS: average, max, distance and pace come out of the history',
    () async {
      for (var s = 0; s <= 60; s += 10) {
        putTo(recorder, hr(s, 120 + s.toDouble()));
        putTo(recorder, cadence(s, 170 + s / 10));
        putTo(
          recorder,
          dist(s, 1000 + s * 3.0),
        ); // the GPS total keeps counting from a total it already had
      }
      now = at(60);
      final summary = await recorder.finish();

      expect(summary.isFinished, isTrue);
      expect(summary.activeDuration, const Duration(seconds: 60));
      expect(summary.averageHeartRate, 150);
      expect(summary.maxHeartRate, 180);
      expect(summary.minHeartRate, 120);
      expect(summary.averageCadence, 173);
      expect(summary.maxCadence, 176);
      expect(
        summary.distanceMeters,
        180,
        reason:
            'the increases of the GPS total, not the total of a recording that started earlier',
      );
      expect(summary.averageSpeedMps, 3);
      expect(summary.averagePaceSecondsPerKm, closeTo(333.3, 0.1));
      expect(summary.sources[TelemetryMetric.heartRate], {'strap'});
      expect(summary.sources[TelemetryMetric.cadence], {'footpod'});
    },
  );

  test(
    'what no sensor gave is null: a run with no strap has no heart rate, not 0',
    () async {
      putTo(recorder, dist(0, 0));
      putTo(recorder, dist(30, 100));
      now = at(30);
      final summary = await recorder.finish();
      expect(summary.averageHeartRate, isNull);
      expect(summary.maxHeartRate, isNull);
      expect(summary.averageCadence, isNull);
      expect(summary.stats.containsKey(TelemetryMetric.heartRate), isFalse);
      expect(summary.distanceMeters, 100);
    },
  );

  test(
    'a pause is not active time and what was measured during it is dropped, not averaged',
    () async {
      putTo(recorder, hr(10, 140));
      now = at(60);
      recorder.pause();
      putTo(recorder, hr(90, 80)); // made during the pause
      now = at(120);
      recorder.resume();
      putTo(recorder, hr(150, 160));
      now = at(180);
      final summary = await recorder.finish();
      expect(summary.activeDuration, const Duration(seconds: 120));
      expect(summary.pausedDuration, const Duration(seconds: 60));
      expect(summary.averageHeartRate, 150);
      expect(summary.droppedSamples, 1);
    },
  );

  test(
    'a sample that arrives late is still filed by the time it was made; the same measurement twice is kept once',
    () async {
      now = at(100);
      putTo(recorder, hr(40, 130)); // arrived at 100 s, made at 40 s
      putTo(recorder, hr(40, 130));
      final summary = recorder.summary();
      expect(summary.stats[TelemetryMetric.heartRate]!.count, 1);
      expect(summary.duplicateSamples, 1);
    },
  );

  test(
    'the summary says how much of the activity each sensor really covered: a strap that dropped leaves a hole',
    () async {
      for (final s in [0, 5, 10, 15, 20]) {
        putTo(
          recorder,
          hr(s, 140),
        ); // covered 0..30 (the last sample holds 10 s)
      }
      // the strap drops for 3 minutes
      for (final s in [200, 205, 210]) {
        putTo(recorder, hr(s, 150));
      }
      now = at(240);
      final summary = await recorder.finish();
      final c = summary.coverage[TelemetryMetric.heartRate]!;
      expect(c.longestGap, const Duration(seconds: 180)); // 20 s -> 200 s
      expect(c.ratio, lessThan(0.4));
      expect(c.ratio, greaterThan(0.2));
      expect(summary.coverage.containsKey(TelemetryMetric.cadence), isFalse);
    },
  );

  test(
    'the sources are attached: a strap and a GPS counter record themselves, a counter by "now minus its age"',
    () async {
      final strap = _Strap();
      final gps = _Gps();
      recorder.attachTelemetry(strap);
      recorder.attachDistance(gps);
      now = at(10);
      strap.controller.add(hr(10, 150));
      gps.controller.add(
        const CounterReading(value: 500, age: Duration(seconds: 2)),
      );
      await Future<void>.delayed(
        Duration.zero,
      ); // delivered while the clock says 10 s
      now = at(20);
      gps.controller.add(
        const CounterReading(value: 560, age: Duration(seconds: 2)),
      );
      await Future<void>.delayed(Duration.zero);
      now = at(20);
      final summary = await recorder.finish();
      expect(summary.averageHeartRate, 150);
      expect(summary.distanceMeters, 60);
      // after finish the sources are no longer listened to
      strap.controller.add(hr(21, 99));
      await Future<void>.delayed(Duration.zero);
      expect(recorder.summary().stats[TelemetryMetric.heartRate]!.count, 1);
    },
  );

  test(
    'a recording survives the process dying: it comes back paused at its last record, without the dead time',
    () async {
      final dir = Directory.systemTemp.createTempSync('activity_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final files = FileTelemetryStore(dir);
      final first = await ActivityRecorder.begin(
        files,
        's2',
        activityType: 'cycling',
        clock: () => now,
      );
      putTo(first, hr(10, 140));
      putTo(first, dist(10, 0));
      putTo(first, hr(60, 160));
      putTo(first, dist(60, 300));
      await first.flush(); // ... and the process dies at 60 s

      now = at(1800); // half an hour later
      final back = (await ActivityRecorder.restore(
        files,
        's2',
        clock: () => now,
      ))!;
      expect(back.activityType, 'cycling');
      expect(back.state, ActivityState.paused);
      putTo(back, hr(900, 70)); // made while the app was dead: dropped
      back.resume();
      putTo(back, hr(1810, 170));
      now = at(1840);
      final summary = await back.finish();
      expect(
        summary.activeDuration,
        const Duration(seconds: 60 + 40),
        reason: '60 s before the crash, 40 s after the resume',
      );
      expect(summary.maxHeartRate, 170);
      expect(summary.stats[TelemetryMetric.heartRate]!.count, 3);
      expect(summary.droppedSamples, 1);

      // a finished recording restores as finished, with the same numbers
      final done = (await ActivityRecorder.restore(
        files,
        's2',
        clock: () => now,
      ))!;
      expect(done.state, ActivityState.finished);
      expect(done.summary().averageHeartRate, summary.averageHeartRate);
      expect(done.summary().distanceMeters, 300);
    },
  );

  test(
    'a recording that never existed restores as null, and an id is used once',
    () async {
      expect(await ActivityRecorder.restore(store, 'nope'), isNull);
      await expectLater(
        ActivityRecorder.begin(store, 's1', activityType: 'running'),
        throwsStateError,
      );
    },
  );

  test(
    'a chart gets at most the points asked for; a hole stays a hole',
    () async {
      for (var s = 0; s < 1000; s += 1) {
        putTo(recorder, hr(s, 100 + (s % 50).toDouble()));
      }
      now = at(1000);
      expect(
        recorder.series(TelemetryMetric.heartRate, maxPoints: 50).length,
        lessThanOrEqualTo(50),
      );
      expect(
        recorder.series(TelemetryMetric.heartRate, maxPoints: 5000).length,
        1000,
      );
      expect(
        recorder.series(TelemetryMetric.heartRate, maxPoints: 1).length,
        1,
      );
      expect(
        () => recorder.series(TelemetryMetric.heartRate, maxPoints: 0),
        throwsRangeError,
      );
      expect(recorder.series(TelemetryMetric.cadence), isEmpty);
    },
  );

  test('the summary becomes a plain map for the app\'s database', () async {
    putTo(recorder, hr(5, 140));
    final json = recorder.summary().toJson();
    expect(json['activityType'], 'running');
    expect((json['stats']! as Map)['heartRate'], isNotNull);
    expect(json['distanceMeters'], isNull);
    expect(json['restoreStatus'], 'notRestored');
  });

  // ── the invariants of the data ───────────────────────────────────────────

  test(
    'distanceMustNotBridgePause: what a counter did while paused is never added',
    () async {
      putTo(recorder, dist(0, 0));
      putTo(recorder, dist(10, 1000)); // 1000 m before the pause
      now = at(10);
      recorder.pause();
      putTo(recorder, dist(15, 1200)); // made while paused: dropped
      now = at(20);
      recorder.resume();
      putTo(
        recorder,
        dist(21, 1300),
      ); // the footpod counted 300 m while paused: only a baseline
      putTo(recorder, dist(30, 1400));
      now = at(30);
      final summary = await recorder.finish();
      expect(
        summary.distanceMeters,
        1100,
        reason:
            '1000 before the pause + 100 after the resume; never the 300 m in between',
      );
    },
  );

  test(
    'twoDistanceSourcesMustNotDoubleCount: a GPS and a footpod on the same run count it once',
    () async {
      for (final s in [0, 10, 20]) {
        putTo(recorder, dist(s, 1000 + s * 5.0)); // GPS
        putTo(
          recorder,
          TelemetrySample(
            metric: TelemetryMetric.distance,
            value: 50 + s * 5.0,
            at: at(s),
            sourceId: 'footpod',
          ),
        );
      }
      now = at(20);
      final summary = await recorder.finish();
      expect(summary.distanceMeters, 100, reason: '100 m run, not 200');
      expect(
        summary.distanceSource,
        'gps',
        reason: 'the first source that gave a counter',
      );
      expect(
        summary.sources[TelemetryMetric.distance],
        {'gps', 'footpod'},
        reason: 'the other one stays in the history',
      );
    },
  );

  test(
    'the distance source can be named, and then it does not matter which one came first',
    () async {
      final named = await ActivityRecorder.begin(
        store,
        'named',
        activityType: 'running',
        distanceSource: 'footpod',
        clock: () => now,
      );
      putTo(named, dist(0, 0));
      putTo(named, dist(10, 500)); // GPS first, but the footpod was named
      putTo(
        named,
        TelemetrySample(
          metric: TelemetryMetric.distance,
          value: 0,
          at: at(0),
          sourceId: 'footpod',
        ),
      );
      putTo(
        named,
        TelemetrySample(
          metric: TelemetryMetric.distance,
          value: 90,
          at: at(10),
          sourceId: 'footpod',
        ),
      );
      now = at(10);
      final summary = await named.finish();
      expect(summary.distanceMeters, 90);
      expect(summary.distanceSource, 'footpod');
      // the choice survives a restart
      expect(
        (await ActivityRecorder.restore(
          store,
          'named',
          clock: () => now,
        ))!.summary().distanceSource,
        'footpod',
      );
    },
  );

  test(
    'reconnectedCounterStartsNewBaseline: a counter that restarted with a bigger value is not a jump',
    () async {
      TelemetrySample c(int s, double v, int epoch) => TelemetrySample(
        metric: TelemetryMetric.distance,
        value: v,
        at: at(s),
        sourceId: 'rower',
        epoch: epoch,
      );
      putTo(recorder, c(0, 0, 1));
      putTo(recorder, c(10, 500, 1));
      putTo(
        recorder,
        c(20, 800, 2),
      ); // reconnected: the machine's counter restarted at a value above the last one
      putTo(recorder, c(30, 850, 2));
      now = at(30);
      expect(
        (await recorder.finish()).distanceMeters,
        550,
        reason: '500 + 50, not 500 + 300 + 50',
      );
    },
  );

  test(
    'futureSampleMustBeRejected: a measurement from the future is not recorded',
    () async {
      now = at(10);
      recorder.record(hr(60, 190)); // 50 s ahead of the phone
      recorder.record(hr(11, 150)); // within the tolerance
      final summary = recorder.summary();
      expect(summary.rejectedFutureSamples, 1);
      expect(summary.maxHeartRate, 150);
    },
  );

  test(
    'pendingAppendMustNotBeDurable: the summary does not claim a write that is still on its way',
    () async {
      final slow = _SlowStore();
      final r = await ActivityRecorder.begin(
        slow,
        'slow',
        activityType: 'running',
        clock: () => now,
      );
      expect(r.isDurable, isTrue);
      slow.hold = Completer<void>();
      putTo(r, hr(1, 140));
      expect(r.isDurable, isFalse, reason: 'the append has not finished');
      expect(r.summary().isDurable, isFalse);
      expect(r.hasWriteFailures, isFalse);
      slow.hold!.complete();
      await r.flush();
      expect(r.isDurable, isTrue);
    },
  );

  test(
    'a store that cannot write the first record means the recording did not start; a later failure is reported',
    () async {
      await expectLater(
        ActivityRecorder.begin(_FailingStore(0), 'x', activityType: 'running'),
        throwsA(isA<ActivityStoreException>()),
      );
      final late = _FailingStore(
        1,
      ); // the start is written, the next record is not
      final r = await ActivityRecorder.begin(
        late,
        'y',
        activityType: 'running',
        clock: () => now,
      );
      putTo(r, hr(1, 100));
      await r.flush();
      expect(r.isDurable, isFalse);
      expect(r.hasWriteFailures, isTrue);
      expect(r.summary().hasWriteFailures, isTrue);
    },
  );

  test(
    'corruptedMiddleJournalMustBeReported: only what comes before the damage is trusted, and the store is repaired',
    () async {
      final mem = MemoryTelemetryStore();
      final r = await ActivityRecorder.begin(
        mem,
        'c',
        activityType: 'running',
        clock: () => now,
      );
      putTo(r, hr(5, 140));
      putTo(r, hr(10, 150));
      putTo(r, hr(15, 160));
      await r.flush();
      mem.lines['c']![2] = '{"k":"s","m":"heartRate"'; // the middle is damaged
      final back = (await ActivityRecorder.restore(
        mem,
        'c',
        clock: () => now,
      ))!;
      final summary = back.summary();
      expect(summary.restoreStatus, RecordingRestoreStatus.partial);
      expect(
        summary.stats[TelemetryMetric.heartRate]!.count,
        1,
        reason: 'only the sample before the damage',
      );
      expect(
        mem.damaged['c'],
        isNotEmpty,
        reason: 'the damaged original was kept',
      );
      // what is recorded next is visible to the next restore (not hidden behind the damage)
      back.resume();
      putTo(back, hr(70, 170));
      await back.flush();
      final again = (await ActivityRecorder.restore(
        mem,
        'c',
        clock: () => now,
      ))!;
      expect(again.summary().restoreStatus, RecordingRestoreStatus.intact);
      expect(again.summary().stats[TelemetryMetric.heartRate]!.count, 2);
    },
  );

  test(
    'restore does not move the active interval behind a resume when a sample arrived late',
    () async {
      now = at(10);
      recorder.pause();
      now = at(20);
      recorder.resume();
      now = at(25);
      recorder.record(
        hr(5, 140),
      ); // measured in the first interval, delivered after resume
      await recorder.flush();

      final back = (await ActivityRecorder.restore(
        store,
        's1',
        clock: () => now,
      ))!;
      expect(back.summary().activeDuration, const Duration(seconds: 10));
      expect(back.summary().averageHeartRate, 140);
    },
  );

  test(
    'valid JSON with a wrong field type is treated as journal damage',
    () async {
      putTo(recorder, hr(5, 140));
      putTo(recorder, hr(10, 150));
      putTo(recorder, hr(15, 160));
      await recorder.flush();
      store.lines['s1']![2] =
          '{"k":"s","m":"heartRate","t":1000,"v":"broken","src":"strap"}';

      final back = (await ActivityRecorder.restore(
        store,
        's1',
        clock: () => now,
      ))!;
      expect(back.summary().restoreStatus, RecordingRestoreStatus.partial);
      expect(back.summary().stats[TelemetryMetric.heartRate]!.count, 1);
      expect(store.damaged['s1'], isNotEmpty);
    },
  );

  test(
    'a LAST line cut by a crash is cut off and reported as tailRepaired',
    () async {
      final mem = MemoryTelemetryStore();
      final r = await ActivityRecorder.begin(
        mem,
        't',
        activityType: 'running',
        clock: () => now,
      );
      putTo(r, hr(5, 140));
      await r.flush();
      mem.lines['t']!.add(
        '{"k":"s","m":"heartRa',
      ); // the process died while writing
      final back = (await ActivityRecorder.restore(
        mem,
        't',
        clock: () => now,
      ))!;
      expect(back.summary().restoreStatus, RecordingRestoreStatus.tailRepaired);
      expect(back.summary().stats[TelemetryMetric.heartRate]!.count, 1);
    },
  );

  test('two different session ids never share a file', () async {
    final dir = Directory.systemTemp.createTempSync('names_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final files = FileTelemetryStore(dir);
    await files.append('a/b', 'one');
    await files.append('a_2Fb', 'two');
    await files.append('a%2Fb', 'three');
    expect(await files.read('a/b'), ['one']);
    expect(await files.read('a_2Fb'), ['two']);
    expect(await files.read('a%2Fb'), ['three']);
  });
}

class _SlowStore extends MemoryTelemetryStore {
  Completer<void>? hold;
  @override
  Future<void> append(String sessionId, String line) async {
    await hold?.future;
    await super.append(sessionId, line);
  }
}

/// Writes [okWrites] lines, then fails.
class _FailingStore extends MemoryTelemetryStore {
  _FailingStore(this.okWrites);
  int okWrites;
  @override
  Future<void> append(String sessionId, String line) async {
    if (okWrites-- <= 0) throw const FileSystemException('disk full');
    await super.append(sessionId, line);
  }
}
