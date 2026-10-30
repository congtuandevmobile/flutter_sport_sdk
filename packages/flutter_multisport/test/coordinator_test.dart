import 'dart:async';
import 'dart:io';

import 'package:flutter_challenge/flutter_challenge.dart';
import 'package:flutter_multisport/flutter_multisport.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_multisport/testing.dart';

class _Counter implements ProgressSource {
  _Counter(this.sourceId);
  @override
  final String sourceId;
  final controller = StreamController<CounterReading>.broadcast();
  @override
  Stream<CounterReading> get readings => controller.stream;
}

class _Telemetry implements TelemetrySource {
  final controller = StreamController<TelemetrySample>.broadcast();
  @override
  Stream<TelemetrySample> get samples => controller.stream;
}

void main() {
  late FakeChallengePlatform platform;
  late MemoryTelemetryStore store;
  late DateTime now;
  late ChallengeCoordinator coordinator;
  late List<CoordinatorEvent> events;

  final t0 = DateTime(2026, 1, 1, 10);
  final stages = [
    SportStageConfig(id: 'run', sport: SportType.running, goal: SportGoal.distanceKm(1)),
    SportStageConfig(id: 'ball', sport: SportType.football, goal: SportGoal.duration(const Duration(minutes: 10))),
    SportStageConfig(id: 'bike', sport: SportType.cycling, goal: SportGoal.distanceKm(2)),
  ];

  ChallengeCoordinator make({List<SportStageConfig>? s, TelemetryStore? st, Duration autoNextDelay = Duration.zero}) {
    final c = ChallengeCoordinator(
      challenge: FlutterChallenge(platform: platform),
      store: st ?? store,
      clock: () => now,
      autoNextDelay: autoNextDelay,
    );
    c.events.listen(events.add);
    return c;
  }

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  setUp(() {
    platform = FakeChallengePlatform();
    store = MemoryTelemetryStore();
    now = t0;
    events = [];
    coordinator = make();
  });

  test('start builds the challenge from the stages and announces the first one', () async {
    await coordinator.start(sessionId: 's1', stages: stages);
    await settle();
    expect(platform.definition.stages.map((s) => s.metric), [ProgressMetric.runMeters, ProgressMetric.duration, ProgressMetric.cycleMeters]);
    expect(events.single, isA<StageStarted>().having((e) => e.index, 'index', 0));
    expect(coordinator.currentStage?.id, 'run');
  });

  test('a source is forwarded with its epoch and age; every source goes to the challenge, which decides what counts', () async {
    final gps = _Counter('gps');
    final rower = _Counter('rower');
    coordinator.attachProgress(gps);
    coordinator.attachProgress(rower);
    await coordinator.start(sessionId: 's1', stages: stages);
    gps.controller.add(const CounterReading(value: 120.5, epoch: 2, age: Duration(milliseconds: 300)));
    rower.controller.add(const CounterReading(value: 40));
    await settle();
    expect(platform.counters, ['gps:2:120.5:300', 'rower:1:40.0:0']);
  });

  test('a stage completes: the app is told, the result has the evidence and the telemetry of THAT stage, then it waits for the user', () async {
    final strap = _Telemetry();
    coordinator.attachTelemetry(strap);
    await coordinator.start(sessionId: 's1', stages: stages);
    for (final (sec, hr) in [(10, 140.0), (20, 150.0), (30, 160.0)]) {
      strap.controller.add(TelemetrySample(metric: TelemetryMetric.heartRate, value: hr, at: t0.add(Duration(seconds: sec)), sourceId: 'strap'));
    }
    await settle(); // the samples have arrived
    now = t0.add(const Duration(minutes: 5));
    platform.completeStage(duration: const Duration(minutes: 5));
    await settle();

    final done = events.whereType<StageCompleted>().single;
    expect(done.index, 0);
    expect(done.completed.evidence, CompletionEvidence.sensor);
    expect(done.result.averageHeartRate, 150);
    expect(done.result.maxHeartRate, 160);
    expect(done.result.averageCadence, isNull, reason: 'no cadence sensor: nothing is made up');
    expect(done.result.distanceMeters, 1000);
    expect(done.result.activeDuration, const Duration(minutes: 5));
    expect(events.last, isA<AwaitingNextStage>().having((e) => e.nextIndex, 'next', 1));
  });

  test('the user moves on: the next stage starts at the moment of the request and its telemetry is its own', () async {
    final strap = _Telemetry();
    coordinator.attachTelemetry(strap);
    await coordinator.start(sessionId: 's1', stages: stages);
    now = t0.add(const Duration(minutes: 5));
    platform.completeStage();
    await settle();
    now = t0.add(const Duration(minutes: 6)); // a minute of transition
    await coordinator.nextStage();
    strap.controller.add(TelemetrySample(metric: TelemetryMetric.heartRate, value: 120, at: t0.add(const Duration(minutes: 7)), sourceId: 'strap'));
    // made between the two stages: belongs to none
    strap.controller.add(TelemetrySample(metric: TelemetryMetric.heartRate, value: 99, at: t0.add(const Duration(minutes: 5, seconds: 30)), sourceId: 'strap'));
    now = t0.add(const Duration(minutes: 16));
    platform.completeStage(duration: const Duration(minutes: 10));
    await settle();

    final second = events.whereType<StageCompleted>().last.result;
    expect(second.index, 1);
    expect(second.startedAt, t0.add(const Duration(minutes: 6)));
    expect(second.stats[TelemetryMetric.heartRate]!.count, 1);
    expect(second.averageHeartRate, 120);
  });

  test('a sample that arrives AFTER its stage ended is still filed under the stage it was made in (event time, not arrival time)', () async {
    final strap = _Telemetry();
    coordinator.attachTelemetry(strap);
    await coordinator.start(sessionId: 's1', stages: stages);
    now = t0.add(const Duration(minutes: 5));
    platform.completeStage();
    await settle();
    now = t0.add(const Duration(minutes: 6));
    await coordinator.nextStage();
    // arrives in stage 2, but was made at minute 4 (in stage 1)
    strap.controller.add(TelemetrySample(metric: TelemetryMetric.heartRate, value: 171, at: t0.add(const Duration(minutes: 4)), sourceId: 'strap'));
    await settle();
    expect(coordinator.results.single.maxHeartRate, 171);
    expect(coordinator.currentResult?.stats, isEmpty);
  });

  test('samples made while paused are dropped; a pause is not in the stage', () async {
    final strap = _Telemetry();
    coordinator.attachTelemetry(strap);
    await coordinator.start(sessionId: 's1', stages: stages);
    now = t0.add(const Duration(minutes: 1));
    await coordinator.pause();
    strap.controller.add(TelemetrySample(metric: TelemetryMetric.heartRate, value: 90, at: t0.add(const Duration(minutes: 2)), sourceId: 'strap'));
    now = t0.add(const Duration(minutes: 3));
    await coordinator.resume();
    strap.controller.add(TelemetrySample(metric: TelemetryMetric.heartRate, value: 130, at: t0.add(const Duration(minutes: 4)), sourceId: 'strap'));
    await settle();
    final r = coordinator.currentResult!;
    expect(r.stats[TelemetryMetric.heartRate]!.count, 1);
    expect(r.averageHeartRate, 130);
    expect(r.pausedDuration, const Duration(minutes: 2));
  });

  test('a stage with autoNext starts the next one by itself; a stage with waitForUser does not', () async {
    coordinator = make(autoNextDelay: const Duration(milliseconds: 10));
    final auto = [
      SportStageConfig(id: 'run', sport: SportType.running, goal: SportGoal.distanceKm(1), transition: TransitionPolicy.autoNext),
      SportStageConfig(id: 'ball', sport: SportType.football, goal: SportGoal.duration(const Duration(minutes: 10))),
      SportStageConfig(id: 'bike', sport: SportType.cycling, goal: SportGoal.distanceKm(2)),
    ];
    await coordinator.start(sessionId: 's1', stages: auto);
    platform.completeStage();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(coordinator.snapshot!.stageIndex, 1, reason: 'the next stage began by itself');
    expect(events.whereType<AwaitingNextStage>(), isEmpty);
    platform.completeStage();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(coordinator.snapshot!.stageIndex, 1, reason: 'stage 2 is waitForUser: it waits');
    expect(events.whereType<AwaitingNextStage>().single.nextIndex, 2);
  });

  test('the whole Running -> Football -> Cycling challenge ends with one result per stage, told once', () async {
    await coordinator.start(sessionId: 's1', stages: stages);
    for (var i = 0; i < 3; i++) {
      now = now.add(const Duration(minutes: 5));
      platform.completeStage();
      await settle();
      platform.republish(); // a repeated snapshot must not repeat an event
      await settle();
      if (i < 2) await coordinator.nextStage();
    }
    await settle();
    expect(events.whereType<StageStarted>().map((e) => e.index), [0, 1, 2]);
    expect(events.whereType<StageCompleted>().map((e) => e.index), [0, 1, 2]);
    final finished = events.whereType<ChallengeFinished>().single;
    expect(finished.results.map((r) => r.stageId), ['run', 'ball', 'bike']);
    expect(coordinator.currentStage, isNull);
  });

  test('the same snapshot published again and again repeats no event', () async {
    await coordinator.start(sessionId: 's1', stages: stages);
    platform.completeStage();
    await settle();
    final count = events.length;
    for (var i = 0; i < 5; i++) {
      platform.republish();
    }
    await settle();
    expect(events.length, count);
  });

  test('a repetition count carries the stage the user saw; a confirmation too, so a late one is refused', () async {
    final reps = [SportStageConfig(id: 'sq', sport: SportType.strength, goal: const SportGoal.repetitions(20)), stages[1]];
    await coordinator.start(sessionId: 's1', stages: reps);
    await coordinator.addRepetitions(5);
    expect(platform.deltas.single, 'manual:5.0:1');
    await coordinator.confirm();
    expect(platform.confirms.single, 'manual:1');
    now = now.add(const Duration(minutes: 1));
    await coordinator.nextStage();
    // a confirmation for the stage the user saw before, delivered now
    expect(
      () => FlutterChallenge(platform: platform).confirm('s1', CompletionEvidence.manual, expectedStageActivation: 1),
      throwsA(isA<ChallengeException>().having((e) => e.code, 'code', 'STALE_ACTIVATION')),
    );
  });

  test('a reading the challenge refuses becomes one error event, not a flood', () async {
    final gps = _Counter('gps');
    coordinator.attachProgress(gps);
    await coordinator.start(sessionId: 's1', stages: stages);
    platform.counterError = ChallengeException('WRONG_STATE', 'no');
    for (var i = 0; i < 5; i++) {
      gps.controller.add(CounterReading(value: i * 1.0));
    }
    await settle();
    expect(events.whereType<CoordinatorError>().single.code, 'READING_REFUSED');
  });

  test('a challenge that cannot start leaves nothing behind and the same id can be tried again', () async {
    final bad = [SportStageConfig(id: 'swim', sport: SportType.swimming, goal: const SportGoal.distanceMeters(200))];
    await expectLater(coordinator.start(sessionId: 's1', stages: bad), throwsA(isA<SportConfigException>()));
    expect(store.lines, isEmpty);
    await coordinator.start(sessionId: 's1', stages: stages);
  });

  test('after the process died the challenge and the telemetry come back, paused, without the dead time', () async {
    final dir = Directory.systemTemp.createTempSync('multisport_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final files = FileTelemetryStore(dir);
    coordinator = make(st: files);
    final strap = _Telemetry();
    coordinator.attachTelemetry(strap);
    await coordinator.start(sessionId: 's1', stages: stages);
    strap.controller.add(TelemetrySample(metric: TelemetryMetric.heartRate, value: 150, at: t0.add(const Duration(minutes: 1)), sourceId: 'strap'));
    await settle();
    now = t0.add(const Duration(minutes: 2)); // the last thing recorded; then the process dies
    strap.controller.add(TelemetrySample(metric: TelemetryMetric.heartRate, value: 160, at: now, sourceId: 'strap'));
    await settle();
    final before = platform.current;
    await coordinator.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    // a new process: new coordinator, the same store; the native side restores the challenge PAUSED
    platform.restoreSnapshot = ChallengeSnapshot(
      sessionId: 's1', state: ChallengeState.paused, definitionId: 'multisport', definitionVersion: 1, stageIndex: 0, stageId: 'run',
      stageActivation: before.stageActivation, stageStatus: StageStatus.active, stageProgress: 0, stageTarget: 1000,
      totalElapsed: Duration.zero, stageElapsed: Duration.zero, completed: const [], lastSeq: 5, recoveries: 1, journalFailed: false,
      restoreStatus: RestoreStatus.intact,
    );
    now = t0.add(const Duration(minutes: 30)); // 28 minutes dead
    coordinator = make(st: files);
    coordinator.attachTelemetry(strap);
    await coordinator.restore(sessionId: 's1', stages: stages);
    expect(coordinator.currentResult!.stats[TelemetryMetric.heartRate]!.count, 2);
    await coordinator.resume();
    now = t0.add(const Duration(minutes: 31));
    strap.controller.add(TelemetrySample(metric: TelemetryMetric.heartRate, value: 170, at: now, sourceId: 'strap'));
    // made during the dead time: dropped
    strap.controller.add(TelemetrySample(metric: TelemetryMetric.heartRate, value: 60, at: t0.add(const Duration(minutes: 10)), sourceId: 'strap'));
    await settle();
    final r = coordinator.currentResult!;
    expect(r.stats[TelemetryMetric.heartRate]!.count, 3);
    expect(r.maxHeartRate, 170);
    expect(r.pausedDuration, const Duration(minutes: 28), reason: 'the dead time is a pause, not a stage time');
  });

  test('a cumulative metric is the sum of its increases: a counter that restarts adds nothing', () async {
    final strap = _Telemetry();
    coordinator.attachTelemetry(strap);
    await coordinator.start(sessionId: 's1', stages: [SportStageConfig(id: 'sw', sport: SportType.swimming, goal: const SportGoal.distanceMeters(200), completion: StageCompletion.manualOnly)]);
    for (final (min, v) in [(1, 10.0), (2, 40.0), (3, 5.0), (4, 25.0)]) {
      strap.controller.add(TelemetrySample(metric: TelemetryMetric.strokeCount, value: v, at: t0.add(Duration(minutes: min)), sourceId: 'swim-band'));
    }
    await settle();
    expect(coordinator.currentResult!.strokeCount, 30 + 20, reason: '10->40 (+30), 40->5 is a reset (0), 5->25 (+20)');
  });
}
