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
  TelemetrySample hr(int seconds, double bpm, {String source = 'strap'}) =>
      TelemetrySample(metric: TelemetryMetric.heartRate, value: bpm, at: at(seconds), sourceId: source);
  TelemetrySample cadence(int seconds, double spm) =>
      TelemetrySample(metric: TelemetryMetric.cadence, value: spm, at: at(seconds), sourceId: 'footpod');
  TelemetrySample dist(int seconds, double total) =>
      TelemetrySample(metric: TelemetryMetric.distance, value: total, at: at(seconds), sourceId: 'gps');

  setUp(() async {
    store = MemoryTelemetryStore();
    now = t0;
    recorder = await ActivityRecorder.begin(store, 's1', activityType: 'running', clock: () => now);
  });

  test('a run with a heart-rate strap, a footpod and GPS: average, max, distance and pace come out of the history', () async {
    for (var s = 0; s <= 60; s += 10) {
      recorder.record(hr(s, 120 + s.toDouble()));
      recorder.record(cadence(s, 170 + s / 10));
      recorder.record(dist(s, 1000 + s * 3.0)); // the GPS total keeps counting from a total it already had
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
    expect(summary.distanceMeters, 180, reason: 'the increases of the GPS total, not the total of a recording that started earlier');
    expect(summary.averageSpeedMps, 3);
    expect(summary.averagePaceSecondsPerKm, closeTo(333.3, 0.1));
    expect(summary.sources[TelemetryMetric.heartRate], {'strap'});
    expect(summary.sources[TelemetryMetric.cadence], {'footpod'});
  });

  test('what no sensor gave is null: a run with no strap has no heart rate, not 0', () async {
    recorder.record(dist(0, 0));
    recorder.record(dist(30, 100));
    now = at(30);
    final summary = await recorder.finish();
    expect(summary.averageHeartRate, isNull);
    expect(summary.maxHeartRate, isNull);
    expect(summary.averageCadence, isNull);
    expect(summary.stats.containsKey(TelemetryMetric.heartRate), isFalse);
    expect(summary.distanceMeters, 100);
  });

  test('a pause is not active time and what was measured during it is dropped, not averaged', () async {
    recorder.record(hr(10, 140));
    now = at(60);
    recorder.pause();
    recorder.record(hr(90, 80)); // made during the pause
    now = at(120);
    recorder.resume();
    recorder.record(hr(150, 160));
    now = at(180);
    final summary = await recorder.finish();
    expect(summary.activeDuration, const Duration(seconds: 120));
    expect(summary.pausedDuration, const Duration(seconds: 60));
    expect(summary.averageHeartRate, 150);
    expect(summary.droppedSamples, 1);
  });

  test('a sample that arrives late is still filed by the time it was made; the same measurement twice is kept once', () async {
    now = at(100);
    recorder.record(hr(40, 130)); // arrived at 100 s, made at 40 s
    recorder.record(hr(40, 130));
    final summary = recorder.summary();
    expect(summary.stats[TelemetryMetric.heartRate]!.count, 1);
    expect(summary.duplicateSamples, 1);
  });

  test('the summary says how much of the activity each sensor really covered: a strap that dropped leaves a hole', () async {
    for (final s in [0, 5, 10, 15, 20]) {
      recorder.record(hr(s, 140)); // covered 0..30 (the last sample holds 10 s)
    }
    // the strap drops for 3 minutes
    for (final s in [200, 205, 210]) {
      recorder.record(hr(s, 150));
    }
    now = at(240);
    final summary = await recorder.finish();
    final c = summary.coverage[TelemetryMetric.heartRate]!;
    expect(c.longestGap, const Duration(seconds: 180)); // 20 s -> 200 s
    expect(c.ratio, lessThan(0.4));
    expect(c.ratio, greaterThan(0.2));
    expect(summary.coverage.containsKey(TelemetryMetric.cadence), isFalse);
  });

  test('the sources are attached: a strap and a GPS counter record themselves, a counter by "now minus its age"', () async {
    final strap = _Strap();
    final gps = _Gps();
    recorder.attachTelemetry(strap);
    recorder.attachDistance(gps);
    now = at(10);
    strap.controller.add(hr(10, 150));
    gps.controller.add(const CounterReading(value: 500, age: Duration(seconds: 2)));
    await Future<void>.delayed(Duration.zero); // delivered while the clock says 10 s
    now = at(20);
    gps.controller.add(const CounterReading(value: 560, age: Duration(seconds: 2)));
    await Future<void>.delayed(Duration.zero);
    now = at(20);
    final summary = await recorder.finish();
    expect(summary.averageHeartRate, 150);
    expect(summary.distanceMeters, 60);
    // after finish the sources are no longer listened to
    strap.controller.add(hr(21, 99));
    await Future<void>.delayed(Duration.zero);
    expect(recorder.summary().stats[TelemetryMetric.heartRate]!.count, 1);
  });

  test('a recording survives the process dying: it comes back paused at its last record, without the dead time', () async {
    final dir = Directory.systemTemp.createTempSync('activity_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final files = FileTelemetryStore(dir);
    final first = await ActivityRecorder.begin(files, 's2', activityType: 'cycling', clock: () => now);
    first.record(hr(10, 140));
    first.record(dist(10, 0));
    first.record(hr(60, 160));
    first.record(dist(60, 300));
    await first.flush(); // ... and the process dies at 60 s

    now = at(1800); // half an hour later
    final back = (await ActivityRecorder.restore(files, 's2', clock: () => now))!;
    expect(back.activityType, 'cycling');
    expect(back.state, ActivityState.paused);
    back.record(hr(900, 70)); // made while the app was dead: dropped
    back.resume();
    back.record(hr(1810, 170));
    now = at(1840);
    final summary = await back.finish();
    expect(summary.activeDuration, const Duration(seconds: 60 + 40), reason: '60 s before the crash, 40 s after the resume');
    expect(summary.maxHeartRate, 170);
    expect(summary.stats[TelemetryMetric.heartRate]!.count, 3);
    expect(summary.droppedSamples, 1);

    // a finished recording restores as finished, with the same numbers
    final done = (await ActivityRecorder.restore(files, 's2', clock: () => now))!;
    expect(done.state, ActivityState.finished);
    expect(done.summary().averageHeartRate, summary.averageHeartRate);
    expect(done.summary().distanceMeters, 300);
  });

  test('a recording that never existed restores as null, and an id is used once', () async {
    expect(await ActivityRecorder.restore(store, 'nope'), isNull);
    await expectLater(ActivityRecorder.begin(store, 's1', activityType: 'running'), throwsStateError);
  });

  test('a chart gets at most the points asked for; a hole stays a hole', () async {
    for (var s = 0; s < 1000; s += 1) {
      recorder.record(hr(s, 100 + (s % 50).toDouble()));
    }
    now = at(1000);
    expect(recorder.series(TelemetryMetric.heartRate, maxPoints: 50).length, lessThanOrEqualTo(50));
    expect(recorder.series(TelemetryMetric.heartRate, maxPoints: 5000).length, 1000);
    expect(recorder.series(TelemetryMetric.cadence), isEmpty);
  });

  test('the summary becomes a plain map for the app\'s database, and a store that fails is reported', () async {
    recorder.record(hr(5, 140));
    final json = recorder.summary().toJson();
    expect(json['activityType'], 'running');
    expect((json['stats']! as Map)['heartRate'], isNotNull);
    expect(json['distanceMeters'], isNull);

    final broken = _BrokenStore();
    final bad = await ActivityRecorder.begin(broken, 'x', activityType: 'running', clock: () => now);
    bad.record(hr(1, 100));
    await bad.flush();
    expect(bad.isDurable, isFalse);
    expect(bad.summary().isDurable, isFalse);
  });
}

class _BrokenStore implements TelemetryStore {
  @override
  Future<void> append(String sessionId, String line) async => throw const FileSystemException('disk full');
  @override
  Future<List<String>> read(String sessionId) async => const [];
  @override
  Future<void> clear(String sessionId) async {}
}
