import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'flutter_challenge',
    dartOut: 'lib/src/challenge_api.g.dart',
    kotlinOut:
        'android/src/main/kotlin/io/github/congtuandevmobile/flutter_challenge/ChallengeApi.g.kt',
    kotlinOptions: KotlinOptions(package: 'io.github.congtuandevmobile.flutter_challenge'),
    swiftOut: 'ios/Classes/ChallengeApi.g.swift',
  ),
)

/// Order matches `challenge.model.ProgressMetric` of the shared core (a test of each engine fails if it drifts).
/// APPEND ONLY. `duration`: the stage's goal is TIME (target in seconds, the engine completes it by its own clock; no sources).
enum NativeProgressMetric { runMeters, rowMeters, skiMeters, sledMeters, swimMeters, reps, duration, cycleMeters }

/// Order matches `challenge.model.CompletionPolicy`.
enum NativeCompletionPolicy { auto, manual, sensorOrManual, judgeRequired }

/// Order matches `challenge.model.ChallengeState`.
enum NativeChallengeState { idle, active, transition, paused, completed }

/// Order matches `challenge.model.StageStatus`.
enum NativeStageStatus { pending, active, targetReached, completed }

/// Order matches `challenge.model.CompletionEvidence`.
/// APPEND ONLY. `timer`: the stage clock reached a duration target.
enum NativeCompletionEvidence { sensor, manual, judge, timer }

/// What a restore found in the journal.
enum NativeRestoreStatus { notRestored, intact, tailRepaired, partial }

class NativeStageDefinition {
  NativeStageDefinition({
    required this.id,
    required this.metric,
    required this.target,
    required this.policy,
    required this.allowedSources,
  });

  String id;
  NativeProgressMetric metric;
  double target;
  NativeCompletionPolicy policy;

  /// Only these sources may advance the stage ("gps-primary", "pm5-rower", "manual").
  List<String> allowedSources;
}

class NativeChallengeDefinition {
  NativeChallengeDefinition({required this.id, required this.version, required this.allowPause, required this.stages});

  String id;
  int version;
  bool allowPause;
  List<NativeStageDefinition> stages;
}

class NativeCompletedStage {
  NativeCompletedStage({required this.stageId, required this.durationMs, required this.progress, required this.evidence});

  String stageId;
  int durationMs;
  double progress;
  NativeCompletionEvidence evidence;
}

class NativeChallengeSnapshot {
  NativeChallengeSnapshot({
    required this.state,
    required this.definitionVersion,
    required this.stageIndex,
    required this.stageActivation,
    required this.stageStatus,
    required this.stageProgress,
    required this.stageTarget,
    required this.totalElapsedMs,
    required this.stageElapsedMs,
    required this.completed,
    required this.lastSeq,
    required this.recoveries,
    required this.journalFailed,
    required this.restoreStatus,
    required this.updatedAtMs,
    this.sessionId,
    this.definitionId,
    this.stageId,
    this.error,
  });

  String? sessionId;
  NativeChallengeState state;
  String? definitionId;
  int definitionVersion;
  int stageIndex;
  String? stageId;

  /// Grows with every stage: a sample made for an older stage can never advance a newer one.
  int stageActivation;
  NativeStageStatus stageStatus;

  /// What the current stage counted. Only what belongs to the stage: never a GPS total, never another source.
  double stageProgress;
  double stageTarget;

  /// The whole challenge, transitions included; a pause is not in it.
  int totalElapsedMs;

  /// The current stage; frozen once it completes.
  int stageElapsedMs;
  List<NativeCompletedStage> completed;
  int lastSeq;

  /// How many times the challenge was recovered after the process died. A result with a recovery is NOT time-verified.
  int recoveries;

  /// A journal write FAILED. Sticky: what this snapshot shows is NOT guaranteed to survive the process dying.
  bool journalFailed;
  NativeRestoreStatus restoreStatus;
  int updatedAtMs;
  String? error;
}

@HostApi()
abstract class ChallengeHostApi {
  /// Starts a challenge. Fails with SESSION_OPEN when another one is running, with BAD_DEFINITION when the definition breaks its
  /// rules, and with JOURNAL_WRITE_FAILED (nothing is started) when the first journal line cannot be written. Every command below
  /// runs on the engine's own serial thread (the journal is written and synced there, never on the main thread) and answers after
  /// the write. A command the rules refuse fails with the reason as its code (WRONG_STATE, NOT_ALLOWED, PAUSE_NOT_ALLOWED, ...).
  @async
  NativeChallengeSnapshot start(String sessionId, NativeChallengeDefinition definition);

  /// Confirms the active stage (a manual stage, a sensor-or-manual stage the sensor could not complete, a judged stage).
  /// [expectedStageActivation] is the activation the caller saw when it decided to confirm: a confirmation that arrives after the
  /// stage changed fails with STALE_ACTIVATION instead of completing the next stage. Null: no check.
  @async
  NativeChallengeSnapshot confirm(String sessionId, NativeCompletionEvidence evidence, int? expectedStageActivation);

  /// Starts the next stage explicitly, after a stage completed (the transition time stays in the total).
  @async
  NativeChallengeSnapshot nextStage(String sessionId);

  @async
  NativeChallengeSnapshot pause(String sessionId);
  @async
  NativeChallengeSnapshot resume(String sessionId);

  /// A cumulative counter of [sourceId] (a GPS total, a machine's distance). [ageMs] is how old the value already is. [epoch] grows
  /// with every new connection of the source. The stage's baseline is the last fresh value of each of its sources, so what was covered
  /// between two stages is never credited to the new one. Dropped when it is not for the open session.
  void submitCounter(String sessionId, String sourceId, int epoch, double meters, int ageMs);

  /// A delta of the current stage's metric from a source that counts for itself (reps, a station). [eventId] must be stable: the same
  /// id is never counted twice, even across a restart. [stageActivation] is the activation of the stage the measurement was made for
  /// (from a snapshot): a callback that arrives after the stage changed is dropped instead of advancing the next stage. Null: the
  /// current stage.
  void submitDelta(String sessionId, String sourceId, String eventId, double delta, int ageMs, int? stageActivation);

  @async
  NativeChallengeSnapshot snapshot();

  /// Rebuilds [sessionId] from its journal after the process died. It comes back PAUSED (even when the definition forbids pausing:
  /// `recoveries` says so). A damaged journal is repaired ON DISK first (the damaged original is kept next to it).
  @async
  NativeChallengeSnapshot restore(String sessionId);

  /// The id of the challenge that was running or paused when it was last seen, or null.
  @async
  String? activeSessionId();

  /// Deletes the journal of [sessionId].
  @async
  void clearSession(String sessionId);
}

@FlutterApi()
abstract class ChallengeFlutterApi {
  /// About once per second and on every change.
  void onSnapshot(NativeChallengeSnapshot snapshot);
}
