import 'package:flutter/services.dart';
import 'package:flutter_challenge/flutter_challenge.dart';
import 'package:flutter_challenge/src/challenge_api.g.dart';
import 'package:flutter_challenge/src/challenge_platform.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeHost extends ChallengeHostApi {
  final calls = <String>[];
  Object? error;
  NativeChallengeDefinition? lastDefinition;

  NativeChallengeSnapshot _snap({NativeChallengeState state = NativeChallengeState.active}) => NativeChallengeSnapshot(
    sessionId: 's1',
    state: state,
    definitionId: 'hybrid',
    definitionVersion: 2,
    stageIndex: 1,
    stageId: 'sled',
    stageActivation: 2,
    stageStatus: NativeStageStatus.targetReached,
    stageProgress: 50,
    stageTarget: 50,
    totalElapsedMs: 120000,
    stageElapsedMs: 30000,
    completed: [
      NativeCompletedStage(stageId: 'run-1', durationMs: 90000, progress: 1000, evidence: NativeCompletionEvidence.sensor),
    ],
    lastSeq: 17,
    recoveries: 1,
    journalFailed: false,
    restoreStatus: NativeRestoreStatus.partial,
    updatedAtMs: 1,
  );

  Future<T> _go<T>(String call, T Function() result) async {
    calls.add(call);
    if (error != null) throw error!;
    return result();
  }

  @override
  Future<NativeChallengeSnapshot> start(String sessionId, NativeChallengeDefinition definition) {
    lastDefinition = definition;
    return _go('start:$sessionId', _snap);
  }

  @override
  Future<NativeChallengeSnapshot> confirm(String sessionId, NativeCompletionEvidence evidence) => _go('confirm:${evidence.name}', _snap);
  @override
  Future<NativeChallengeSnapshot> nextStage(String sessionId) => _go('next', _snap);
  @override
  Future<NativeChallengeSnapshot> pause(String sessionId) => _go('pause', () => _snap(state: NativeChallengeState.paused));
  @override
  Future<NativeChallengeSnapshot> resume(String sessionId) => _go('resume', _snap);
  @override
  Future<void> submitCounter(String sessionId, String sourceId, int epoch, double meters, int ageMs) =>
      _go('counter:$sourceId:$epoch:$meters:$ageMs', () {});
  @override
  Future<void> submitDelta(String sessionId, String sourceId, String eventId, double delta, int ageMs) =>
      _go('delta:$sourceId:$eventId:$delta:$ageMs', () {});
  @override
  Future<NativeChallengeSnapshot> snapshot() => _go('snapshot', _snap);
  @override
  Future<NativeChallengeSnapshot> restore(String sessionId) => _go('restore', () => _snap(state: NativeChallengeState.paused));
  @override
  Future<String?> activeSessionId() => _go('active', () => 's1');
  @override
  Future<void> clearSession(String sessionId) => _go('clear', () {});
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeHost host;
  late PigeonChallengePlatform platform;
  late FlutterChallenge challenge;

  const definition = ChallengeDefinition(
    id: 'hybrid',
    version: 2,
    allowPause: false,
    stages: [
      StageDefinition(
        id: 'run-1',
        metric: ProgressMetric.runMeters,
        target: 1000,
        policy: CompletionPolicy.auto,
        allowedSources: {'gps-primary'},
      ),
      StageDefinition(
        id: 'sled',
        metric: ProgressMetric.sledMeters,
        target: 50,
        policy: CompletionPolicy.manual,
        allowedSources: {'manual'},
      ),
    ],
  );

  setUp(() {
    host = FakeHost();
    platform = PigeonChallengePlatform(api: host);
    challenge = FlutterChallenge(platform: platform);
  });

  test('the definition reaches native with its stages, metrics, policies and sources', () async {
    await challenge.start(sessionId: 's1', definition: definition);
    final d = host.lastDefinition!;
    expect(d.id, 'hybrid');
    expect(d.version, 2);
    expect(d.allowPause, isFalse);
    expect(d.stages.map((s) => s.id), ['run-1', 'sled']);
    expect(d.stages[0].metric, NativeProgressMetric.runMeters);
    expect(d.stages[0].policy, NativeCompletionPolicy.auto);
    expect(d.stages[1].metric, NativeProgressMetric.sledMeters);
    expect(d.stages[1].policy, NativeCompletionPolicy.manual);
    expect(d.stages[1].allowedSources, ['manual']);
  });

  test('commands and samples reach native with their arguments, ages in milliseconds', () async {
    await challenge.confirm('s1', CompletionEvidence.judge);
    await challenge.nextStage('s1');
    await challenge.pause('s1');
    await challenge.resume('s1');
    await challenge.submitCounter('s1', 'gps-primary', 1204.5, epoch: 3, age: const Duration(milliseconds: 800));
    await challenge.submitDelta('s1', 'manual', 'tap-1', 5, age: const Duration(milliseconds: 20));
    await challenge.restore('s1');
    await challenge.clearSession('s1');
    expect(host.calls, [
      'confirm:judge', 'next', 'pause', 'resume',
      'counter:gps-primary:3:1204.5:800',
      'delta:manual:tap-1:5.0:20',
      'restore', 'clear',
    ]);
    expect(await challenge.activeSessionId(), 's1');
  });

  test('a snapshot keeps the stage, its progress, the completed stages and the recovery facts', () async {
    final s = await challenge.restore('s1');
    expect(s.state, ChallengeState.paused);
    expect(s.stageId, 'sled');
    expect(s.stageStatus, StageStatus.targetReached);
    expect(s.stageProgress, 50);
    expect(s.totalElapsed, const Duration(minutes: 2));
    expect(s.stageElapsed, const Duration(seconds: 30));
    expect(s.completed.single.stageId, 'run-1');
    expect(s.completed.single.duration, const Duration(seconds: 90));
    expect(s.completed.single.evidence, CompletionEvidence.sensor);
    expect(s.recoveries, 1);
    expect(s.restoreStatus, RestoreStatus.partial);
    expect(s.isDurable, isTrue);
    expect(s.isFinished, isFalse);
  });

  test('a refused command throws a ChallengeException with the reason as its code', () async {
    host.error = PlatformException(code: 'NOT_ALLOWED', message: 'the challenge refused: NOT_ALLOWED');
    await expectLater(
      challenge.confirm('s1', CompletionEvidence.manual),
      throwsA(isA<ChallengeException>().having((e) => e.code, 'code', 'NOT_ALLOWED')),
    );
  });

  test('snapshots from native become a stream', () async {
    final seen = <ChallengeSnapshot>[];
    challenge.snapshots.listen(seen.add);
    platform.onSnapshot(host._snap());
    await Future<void>.delayed(Duration.zero);
    expect(seen.single.lastSeq, 17);
  });

  test('every native enum has its Dart twin in the same order', () {
    expect(ProgressMetric.values.map((m) => m.name), NativeProgressMetric.values.map((m) => m.name));
    expect(CompletionPolicy.values.map((m) => m.name), NativeCompletionPolicy.values.map((m) => m.name));
    expect(ChallengeState.values.map((m) => m.name), NativeChallengeState.values.map((m) => m.name));
    expect(StageStatus.values.map((m) => m.name), NativeStageStatus.values.map((m) => m.name));
    expect(CompletionEvidence.values.map((m) => m.name), NativeCompletionEvidence.values.map((m) => m.name));
    expect(RestoreStatus.values.map((m) => m.name), NativeRestoreStatus.values.map((m) => m.name));
  });

  test('the idle snapshot has nothing', () {
    const s = ChallengeSnapshot.idle();
    expect(s.stageProgress, 0);
    expect(s.completed, isEmpty);
    expect(s.stageId, isNull);
  });
}
