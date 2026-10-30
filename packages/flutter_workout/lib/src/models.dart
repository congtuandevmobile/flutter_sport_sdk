import 'package:meta/meta.dart';

/// The kind of workout. It decides which distance source is preferred (outdoors GPS, indoors a counter).
enum WorkoutMode { outdoorRunning, indoorRunning, outdoorCycling, indoorCycling }

/// The lifecycle of a workout. A workout is NOT a Bluetooth connection: a sensor can stay connected between two workouts.
enum WorkoutState { idle, running, paused, finished }

/// How a distance reaches the workout.
enum DistanceSourceKind {
  /// A GPS engine's cumulative total.
  gps,

  /// A cumulative counter of a device (a footpod, a treadmill).
  counter,

  /// A speed that is integrated over time.
  speed,
}

/// What a restore found in the journal.
enum RestoreStatus {
  /// The snapshot was not produced by a restore.
  notRestored,

  /// Every line was intact.
  intact,

  /// The last line was cut by the process dying and was dropped.
  tailRepaired,

  /// A line in the middle was damaged: only what comes before it was kept.
  partial,
}

/// One place a distance can come from. A device's counter and its speed are two sources.
@immutable
class DistanceSourceRef {
  const DistanceSourceRef(this.id, this.kind);

  const DistanceSourceRef.gps([this.id = 'gps']) : kind = DistanceSourceKind.gps;
  const DistanceSourceRef.counter(this.id) : kind = DistanceSourceKind.counter;
  const DistanceSourceRef.speed(this.id) : kind = DistanceSourceKind.speed;

  final String id;
  final DistanceSourceKind kind;

  @override
  bool operator ==(Object other) => other is DistanceSourceRef && other.id == id && other.kind == kind;

  @override
  int get hashCode => Object.hash(id, kind);

  @override
  String toString() => '${kind.name}:$id';
}

/// What the workout shows now.
@immutable
class WorkoutSnapshot {
  const WorkoutSnapshot({
    required this.state,
    required this.activeTime,
    required this.pausedTime,
    required this.distanceMeters,
    required this.lastSeq,
    required this.journalFailed,
    required this.restoreStatus,
    this.sessionId,
    this.mode,
    this.distanceSource,
    this.lastDistanceSource,
    this.error,
  });

  const WorkoutSnapshot.idle()
    : state = WorkoutState.idle,
      activeTime = Duration.zero,
      pausedTime = Duration.zero,
      distanceMeters = 0,
      lastSeq = 0,
      journalFailed = false,
      restoreStatus = RestoreStatus.notRestored,
      sessionId = null,
      mode = null,
      distanceSource = null,
      lastDistanceSource = null,
      error = null;

  final String? sessionId;
  final WorkoutState state;
  final WorkoutMode? mode;

  /// Time spent running. A pause is NOT in it.
  final Duration activeTime;
  final Duration pausedTime;

  /// The workout distance, from ONE source at a time. 0 while no source is chosen: never a guess.
  final double distanceMeters;

  /// The source that is counting NOW: null when none is chosen yet or the chosen one went quiet (the distance so far is kept).
  final DistanceSourceRef? distanceSource;

  /// The source that credited last, even if it went quiet: a history, not a promise that it is counting.
  final DistanceSourceRef? lastDistanceSource;

  /// Sequence number of the last journal event.
  final int lastSeq;

  /// A journal write FAILED. Sticky: what this snapshot shows is NOT guaranteed to survive the process dying.
  final bool journalFailed;
  final RestoreStatus restoreStatus;
  final String? error;

  /// True when what is shown is on the disk (no journal failure): a workout that is not durable must not be presented as saved.
  bool get isDurable => !journalFailed;
}

/// A failure with a stable code: SESSION_OPEN, NO_SESSION, NOT_RESTORABLE, RESTORE_FAILED, JOURNAL_WRITE_FAILED, BAD_SESSION,
/// DETACHED.
class WorkoutException implements Exception {
  const WorkoutException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'WorkoutException($code): $message';
}
