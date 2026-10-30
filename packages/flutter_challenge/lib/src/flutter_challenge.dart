import 'dart:async';

import 'package:flutter_challenge/src/challenge_platform.dart';
import 'package:flutter_challenge/src/models.dart';

/// A multi-stage challenge: ordered stages, each with its own goal, its own allowed sources and its own completion rule. The native
/// core counts only what BELONGS to the stage and writes every change to a journal BEFORE it shows it.
///
/// Nothing here measures anything and nothing here needs Bluetooth: a host (or a small glue) hands over what its sources say:
///  - [submitCounter]: the cumulative counter of a source (a GPS total, a machine's distance). The core turns it into stage-local
///    deltas: the first value of a stage is a baseline, so what was covered between two stages is never credited to the new one, and a
///    run counter can never advance a row stage;
///  - [submitDelta]: a count that a source makes for itself (reps, a station), with a stable event id.
/// The GPS keeps recording the whole time and is never touched.
///
/// Limits: the challenge belongs to the plugin instance, so it stops being fed when the Flutter engine goes away; after the process
/// dies [restore] brings it back PAUSED. No judge authentication, penalties, rounds or teams.
class FlutterChallenge {
  FlutterChallenge({ChallengePlatform? platform}) : _platform = platform ?? PigeonChallengePlatform();

  final ChallengePlatform _platform;

  /// The challenge, about once per second and on every change.
  Stream<ChallengeSnapshot> get snapshots => _platform.snapshots;

  /// Starts a challenge and its first stage. Throws [ChallengeException] `SESSION_OPEN` while another is open, `BAD_DEFINITION` when the
  /// definition breaks its rules, and `JOURNAL_WRITE_FAILED` (nothing is started) when the first journal line cannot be written.
  Future<ChallengeSnapshot> start({required String sessionId, required ChallengeDefinition definition}) =>
      _platform.start(sessionId, definition);

  /// Confirms the active stage. A command the rules refuse throws with the reason as the code (`NOT_ALLOWED`, `WRONG_STATE`, ...).
  ///
  /// Pass [expectedStageActivation] (`snapshot.stageActivation` of the stage you are confirming) so that a confirmation that arrives
  /// late, after the stage changed, fails with `STALE_ACTIVATION` instead of completing the next stage.
  Future<ChallengeSnapshot> confirm(String sessionId, CompletionEvidence evidence, {int? expectedStageActivation}) =>
      _platform.confirm(sessionId, evidence, expectedStageActivation);

  /// Starts the next stage after one completed (the transition time stays in the total).
  Future<ChallengeSnapshot> nextStage(String sessionId) => _platform.nextStage(sessionId);

  Future<ChallengeSnapshot> pause(String sessionId) => _platform.pause(sessionId);
  Future<ChallengeSnapshot> resume(String sessionId) => _platform.resume(sessionId);

  /// A cumulative counter in metres (or repetitions) of [sourceId]. [age] is how old the value already is; [epoch] must grow with every
  /// new connection of the source. Dropped when the source is not allowed for the current stage.
  Future<void> submitCounter(
    String sessionId,
    String sourceId,
    double value, {
    int epoch = 1,
    Duration age = Duration.zero,
  }) => _platform.submitCounter(sessionId, sourceId, epoch, value, age);

  /// A delta of the current stage's metric from a source that counts for itself. [eventId] must be stable: the same id is never counted
  /// twice, even across a restart.
  ///
  /// Pass [stageActivation] (`snapshot.stageActivation` when the measurement was made): a tap whose callback arrives after the stage
  /// changed is then dropped instead of advancing the next stage. Without it, the delta counts for whatever stage is current.
  Future<void> submitDelta(
    String sessionId,
    String sourceId,
    String eventId,
    double delta, {
    Duration age = Duration.zero,
    int? stageActivation,
  }) => _platform.submitDelta(sessionId, sourceId, eventId, delta, age, stageActivation);

  Future<ChallengeSnapshot> snapshot() => _platform.snapshot();

  /// Rebuilds [sessionId] from its journal after the process died. It comes back PAUSED (even when the definition forbids pausing:
  /// `recoveries` says so). A cut last line is repaired and a damaged middle keeps the part before it (`restoreStatus`).
  Future<ChallengeSnapshot> restore(String sessionId) => _platform.restore(sessionId);

  /// The id of the challenge that was running or paused when it was last seen, or null: ask it on launch, then [restore] it.
  Future<String?> activeSessionId() => _platform.activeSessionId();

  /// Deletes the journal of [sessionId] (throws `SESSION_OPEN` for a challenge that is still open).
  Future<void> clearSession(String sessionId) => _platform.clearSession(sessionId);
}
