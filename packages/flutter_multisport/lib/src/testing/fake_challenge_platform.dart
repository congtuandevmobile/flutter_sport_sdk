import 'dart:async';

import 'package:flutter_challenge/flutter_challenge.dart';

/// A stand-in for the native side of `flutter_challenge`, for the tests of an app (give it to `FlutterChallenge(platform: ...)`): it keeps a
/// snapshot, records what it is told, and lets a test decide when a stage completes. It does NOT re-implement the rules of the challenge
/// (the real ones live in the native core and are tested there), so it proves how YOUR code reacts, not whether progress is right.
class FakeChallengePlatform implements ChallengePlatform {
  final _stream = StreamController<ChallengeSnapshot>.broadcast();
  late ChallengeDefinition definition;
  String? sessionId;
  ChallengeSnapshot current = const ChallengeSnapshot.idle();
  int _activation = 0;
  ChallengeState _resumeState = ChallengeState.active;

  final counters = <String>[];
  final deltas = <String>[];
  final confirms = <String>[];
  Object? counterError;
  ChallengeSnapshot? restoreSnapshot;
  Future<ChallengeSnapshot>? nextSnapshot;

  @override
  Stream<ChallengeSnapshot> get snapshots => _stream.stream;

  ChallengeSnapshot _make(
    ChallengeState state,
    int index, {
    List<CompletedStage>? completed,
  }) => ChallengeSnapshot(
    sessionId: sessionId,
    state: state,
    definitionId: definition.id,
    definitionVersion: definition.version,
    stageIndex: index,
    stageId: index >= 0 && index < definition.stages.length
        ? definition.stages[index].id
        : null,
    stageActivation: _activation,
    stageStatus: StageStatus.active,
    stageProgress: 0,
    stageTarget: index >= 0 && index < definition.stages.length
        ? definition.stages[index].target
        : 0,
    totalElapsed: Duration.zero,
    stageElapsed: Duration.zero,
    completed: completed ?? current.completed,
    lastSeq: current.lastSeq + 1,
    recoveries: 0,
    journalFailed: false,
    restoreStatus: RestoreStatus.notRestored,
  );

  ChallengeSnapshot _publish(ChallengeSnapshot s) {
    current = s;
    _stream.add(s);
    return s;
  }

  @override
  Future<ChallengeSnapshot> start(String id, ChallengeDefinition d) async {
    definition = d;
    sessionId = id;
    _activation = 1;
    return _publish(_make(ChallengeState.active, 0, completed: const []));
  }

  /// The test says: the stage that runs completed with [evidence] after [duration].
  ChallengeSnapshot completeStage({
    CompletionEvidence evidence = CompletionEvidence.sensor,
    Duration duration = const Duration(minutes: 5),
  }) {
    final index = current.stageIndex;
    final stage = definition.stages[index];
    final done = [
      ...current.completed,
      CompletedStage(
        stageId: stage.id,
        duration: duration,
        progress: stage.target,
        evidence: evidence,
      ),
    ];
    final last = index == definition.stages.length - 1;
    return _publish(
      _make(
        last ? ChallengeState.completed : ChallengeState.transition,
        index,
        completed: done,
      ),
    );
  }

  /// The test says that the active stage reached its target but still awaits confirmation.
  void reachTarget() {
    final s = current;
    _publish(
      ChallengeSnapshot(
        sessionId: s.sessionId,
        state: s.state,
        definitionId: s.definitionId,
        definitionVersion: s.definitionVersion,
        stageIndex: s.stageIndex,
        stageId: s.stageId,
        stageActivation: s.stageActivation,
        stageStatus: StageStatus.targetReached,
        stageProgress: s.stageTarget,
        stageTarget: s.stageTarget,
        totalElapsed: s.totalElapsed,
        stageElapsed: s.stageElapsed,
        completed: s.completed,
        lastSeq: s.lastSeq + 1,
        recoveries: s.recoveries,
        journalFailed: s.journalFailed,
        restoreStatus: s.restoreStatus,
      ),
    );
  }

  /// The native side publishes about once a second even when nothing changed.
  void republish() => _stream.add(current);

  @override
  Future<ChallengeSnapshot> nextStage(String id) async {
    _activation += 1;
    return _publish(_make(ChallengeState.active, current.stageIndex + 1));
  }

  @override
  Future<ChallengeSnapshot> confirm(
    String id,
    CompletionEvidence evidence,
    int? expectedStageActivation,
  ) async {
    confirms.add('${evidence.name}:$expectedStageActivation');
    if (expectedStageActivation != null &&
        expectedStageActivation != _activation) {
      throw ChallengeException(
        'STALE_ACTIVATION',
        'the challenge refused: STALE_ACTIVATION',
      );
    }
    return completeStage(evidence: evidence);
  }

  @override
  Future<ChallengeSnapshot> pause(String id) async {
    _resumeState = current.state;
    return _publish(_make(ChallengeState.paused, current.stageIndex));
  }

  @override
  Future<ChallengeSnapshot> resume(String id) async =>
      _publish(_make(_resumeState, current.stageIndex));

  @override
  Future<void> submitCounter(
    String id,
    String sourceId,
    int epoch,
    double meters,
    Duration age,
  ) async {
    final error = counterError;
    if (error != null) throw error;
    counters.add('$sourceId:$epoch:$meters:${age.inMilliseconds}');
  }

  @override
  Future<void> submitDelta(
    String id,
    String sourceId,
    String eventId,
    double delta,
    Duration age,
    int? stageActivation,
  ) async {
    deltas.add('$sourceId:$delta:$stageActivation');
  }

  @override
  Future<ChallengeSnapshot> snapshot() async {
    final pending = nextSnapshot;
    nextSnapshot = null;
    return pending == null ? current : await pending;
  }

  @override
  Future<ChallengeSnapshot> restore(String id) async {
    sessionId = id;
    current = restoreSnapshot!;
    _activation = current.stageActivation;
    return current;
  }

  @override
  Future<String?> activeSessionId() async => sessionId;

  @override
  Future<void> clearSession(String id) async {}
}
