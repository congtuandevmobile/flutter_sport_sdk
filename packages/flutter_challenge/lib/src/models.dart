import 'package:meta/meta.dart';

/// What a stage measures. A domain metric, never a generic "distance": a rower's metres cannot complete a run stage.
enum ProgressMetric { runMeters, rowMeters, skiMeters, sledMeters, swimMeters, reps }

/// How a stage is completed.
enum CompletionPolicy {
  /// By the sensor, as soon as the target is reached.
  auto,

  /// Only by an explicit confirmation.
  manual,

  /// By the sensor reaching the target and a confirmation, or by a confirmation when the sensor cannot.
  sensorOrManual,

  /// Only with judge evidence. The host or a backend MUST authenticate the judge: this package only records the evidence.
  judgeRequired,
}

enum ChallengeState { idle, active, transition, paused, completed }

enum StageStatus { pending, active, targetReached, completed }

enum CompletionEvidence { sensor, manual, judge }

/// What a restore found in the journal.
enum RestoreStatus { notRestored, intact, tailRepaired, partial }

@immutable
class StageDefinition {
  const StageDefinition({
    required this.id,
    required this.metric,
    required this.target,
    required this.policy,
    required this.allowedSources,
  });

  final String id;
  final ProgressMetric metric;
  final double target;
  final CompletionPolicy policy;

  /// Only these sources may advance the stage ("gps-primary", "pm5-rower", "manual").
  final Set<String> allowedSources;
}

@immutable
class ChallengeDefinition {
  const ChallengeDefinition({required this.id, required this.version, required this.stages, this.allowPause = true});

  final String id;
  final int version;
  final List<StageDefinition> stages;

  /// False for a format where the clock must not stop. (A recovery after the process died still pauses: see `recoveries`.)
  final bool allowPause;
}

@immutable
class CompletedStage {
  const CompletedStage({required this.stageId, required this.duration, required this.progress, required this.evidence});

  final String stageId;
  final Duration duration;
  final double progress;
  final CompletionEvidence evidence;
}

/// What the challenge shows now.
@immutable
class ChallengeSnapshot {
  const ChallengeSnapshot({
    required this.state,
    required this.definitionVersion,
    required this.stageIndex,
    required this.stageActivation,
    required this.stageStatus,
    required this.stageProgress,
    required this.stageTarget,
    required this.totalElapsed,
    required this.stageElapsed,
    required this.completed,
    required this.lastSeq,
    required this.recoveries,
    required this.journalFailed,
    required this.restoreStatus,
    this.sessionId,
    this.definitionId,
    this.stageId,
    this.error,
  });

  const ChallengeSnapshot.idle()
    : state = ChallengeState.idle,
      definitionVersion = 0,
      stageIndex = -1,
      stageActivation = 0,
      stageStatus = StageStatus.pending,
      stageProgress = 0,
      stageTarget = 0,
      totalElapsed = Duration.zero,
      stageElapsed = Duration.zero,
      completed = const [],
      lastSeq = 0,
      recoveries = 0,
      journalFailed = false,
      restoreStatus = RestoreStatus.notRestored,
      sessionId = null,
      definitionId = null,
      stageId = null,
      error = null;

  final String? sessionId;
  final ChallengeState state;
  final String? definitionId;
  final int definitionVersion;
  final int stageIndex;
  final String? stageId;

  /// Grows with every stage: a sample made for an older stage can never advance a newer one.
  final int stageActivation;
  final StageStatus stageStatus;

  /// What the current stage counted: only what belongs to the stage, never a GPS total, never another source's counter.
  final double stageProgress;
  final double stageTarget;

  /// The whole challenge, transitions included; a pause is not in it.
  final Duration totalElapsed;

  /// The current stage; frozen once it completes.
  final Duration stageElapsed;
  final List<CompletedStage> completed;
  final int lastSeq;

  /// How many times the challenge was recovered after the process died. A result with a recovery is NOT time-verified.
  final int recoveries;

  /// A journal write FAILED. Sticky: what this snapshot shows is NOT guaranteed to survive the process dying.
  final bool journalFailed;
  final RestoreStatus restoreStatus;
  final String? error;

  /// True when what is shown is on the disk (no journal failure): a challenge that is not durable must not be presented as saved.
  bool get isDurable => !journalFailed;

  bool get isFinished => state == ChallengeState.completed;
}

/// A failure with a stable code. Commands refused by the rules: WRONG_STATE, NOT_ALLOWED, PAUSE_NOT_ALLOWED, TIME_BACKWARDS, ... .
/// Others: SESSION_OPEN, NO_SESSION, BAD_DEFINITION, BAD_SESSION, NOT_RESTORABLE, RESTORE_FAILED, JOURNAL_WRITE_FAILED, DETACHED.
class ChallengeException implements Exception {
  const ChallengeException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'ChallengeException($code): $message';
}
