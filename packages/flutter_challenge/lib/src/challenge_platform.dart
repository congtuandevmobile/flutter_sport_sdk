import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_challenge/src/challenge_api.g.dart';
import 'package:flutter_challenge/src/models.dart';

/// The native side as the Dart API sees it (a fake implements this in tests).
abstract class ChallengePlatform {
  Stream<ChallengeSnapshot> get snapshots;

  Future<ChallengeSnapshot> start(String sessionId, ChallengeDefinition definition);
  Future<ChallengeSnapshot> confirm(String sessionId, CompletionEvidence evidence);
  Future<ChallengeSnapshot> nextStage(String sessionId);
  Future<ChallengeSnapshot> pause(String sessionId);
  Future<ChallengeSnapshot> resume(String sessionId);
  Future<void> submitCounter(String sessionId, String sourceId, int epoch, double meters, Duration age);
  Future<void> submitDelta(String sessionId, String sourceId, String eventId, double delta, Duration age);
  Future<ChallengeSnapshot> snapshot();
  Future<ChallengeSnapshot> restore(String sessionId);
  Future<String?> activeSessionId();
  Future<void> clearSession(String sessionId);
}

/// Pigeon implementation: the host API for calls, the Flutter API for events.
class PigeonChallengePlatform implements ChallengePlatform, ChallengeFlutterApi {
  PigeonChallengePlatform({ChallengeHostApi? api}) : _api = api ?? ChallengeHostApi() {
    ChallengeFlutterApi.setUp(this);
  }

  final ChallengeHostApi _api;
  final _snapshots = StreamController<ChallengeSnapshot>.broadcast();

  @override
  Stream<ChallengeSnapshot> get snapshots => _snapshots.stream;

  @override
  void onSnapshot(NativeChallengeSnapshot snapshot) => _snapshots.add(_snapshot(snapshot));

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on PlatformException catch (e) {
      throw ChallengeException(e.code, e.message ?? 'challenge call failed');
    }
  }

  @override
  Future<ChallengeSnapshot> start(String sessionId, ChallengeDefinition d) => _guard(
    () async => _snapshot(
      await _api.start(
        sessionId,
        NativeChallengeDefinition(
          id: d.id,
          version: d.version,
          allowPause: d.allowPause,
          stages: [
            for (final s in d.stages)
              NativeStageDefinition(
                id: s.id,
                metric: NativeProgressMetric.values[s.metric.index],
                target: s.target,
                policy: NativeCompletionPolicy.values[s.policy.index],
                allowedSources: s.allowedSources.toList(),
              ),
          ],
        ),
      ),
    ),
  );

  @override
  Future<ChallengeSnapshot> confirm(String sessionId, CompletionEvidence evidence) =>
      _guard(() async => _snapshot(await _api.confirm(sessionId, NativeCompletionEvidence.values[evidence.index])));

  @override
  Future<ChallengeSnapshot> nextStage(String sessionId) => _guard(() async => _snapshot(await _api.nextStage(sessionId)));

  @override
  Future<ChallengeSnapshot> pause(String sessionId) => _guard(() async => _snapshot(await _api.pause(sessionId)));

  @override
  Future<ChallengeSnapshot> resume(String sessionId) => _guard(() async => _snapshot(await _api.resume(sessionId)));

  @override
  Future<void> submitCounter(String sessionId, String sourceId, int epoch, double meters, Duration age) =>
      _guard(() => _api.submitCounter(sessionId, sourceId, epoch, meters, age.inMilliseconds));

  @override
  Future<void> submitDelta(String sessionId, String sourceId, String eventId, double delta, Duration age) =>
      _guard(() => _api.submitDelta(sessionId, sourceId, eventId, delta, age.inMilliseconds));

  @override
  Future<ChallengeSnapshot> snapshot() => _guard(() async => _snapshot(await _api.snapshot()));

  @override
  Future<ChallengeSnapshot> restore(String sessionId) => _guard(() async => _snapshot(await _api.restore(sessionId)));

  @override
  Future<String?> activeSessionId() => _guard(() => _api.activeSessionId());

  @override
  Future<void> clearSession(String sessionId) => _guard(() => _api.clearSession(sessionId));

  static ChallengeSnapshot _snapshot(NativeChallengeSnapshot s) => ChallengeSnapshot(
    sessionId: s.sessionId,
    state: ChallengeState.values[s.state.index],
    definitionId: s.definitionId,
    definitionVersion: s.definitionVersion,
    stageIndex: s.stageIndex,
    stageId: s.stageId,
    stageActivation: s.stageActivation,
    stageStatus: StageStatus.values[s.stageStatus.index],
    stageProgress: s.stageProgress,
    stageTarget: s.stageTarget,
    totalElapsed: Duration(milliseconds: s.totalElapsedMs),
    stageElapsed: Duration(milliseconds: s.stageElapsedMs),
    completed: [
      for (final c in s.completed)
        CompletedStage(
          stageId: c.stageId,
          duration: Duration(milliseconds: c.durationMs),
          progress: c.progress,
          evidence: CompletionEvidence.values[c.evidence.index],
        ),
    ],
    lastSeq: s.lastSeq,
    recoveries: s.recoveries,
    journalFailed: s.journalFailed,
    restoreStatus: RestoreStatus.values[s.restoreStatus.index],
    error: s.error,
  );
}
