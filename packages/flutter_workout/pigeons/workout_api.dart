import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'flutter_workout',
    dartOut: 'lib/src/workout_api.g.dart',
    kotlinOut:
        'android/src/main/kotlin/io/github/congtuandevmobile/flutter_workout/WorkoutApi.g.kt',
    kotlinOptions: KotlinOptions(package: 'io.github.congtuandevmobile.flutter_workout'),
    swiftOut: 'ios/Classes/WorkoutApi.g.swift',
  ),
)

/// Order matches `workout.model.WorkoutMode` of the shared core (a test of each engine fails if it drifts).
enum NativeWorkoutMode { outdoorRunning, indoorRunning, outdoorCycling, indoorCycling }

/// Order matches `workout.model.WorkoutState`.
enum NativeWorkoutState { idle, running, paused, finished }

/// Order matches `workout.model.DistanceSourceKind`.
enum NativeSourceKind {
  /// A GPS engine's cumulative total.
  gps,

  /// A cumulative counter of a device (a footpod, a treadmill).
  counter,

  /// A speed that is integrated over time.
  speed,
}

/// What a restore found in the journal.
enum NativeRestoreStatus {
  /// The snapshot was not produced by a restore.
  notRestored,

  /// Every line was intact.
  intact,

  /// The last line was cut by the process dying and was dropped.
  tailRepaired,

  /// A line in the middle was damaged: only what comes before it was kept.
  partial,
}

class NativeSourceRef {
  NativeSourceRef({required this.id, required this.kind});

  /// A stable id of the source (a device id, "gps"). A device's counter and its speed are two sources.
  String id;
  NativeSourceKind kind;
}

class NativeWorkoutSnapshot {
  NativeWorkoutSnapshot({
    required this.state,
    required this.activeMs,
    required this.pausedMs,
    required this.distanceMeters,
    required this.lastSeq,
    required this.journalFailed,
    required this.restoreStatus,
    required this.updatedAtMs,
    this.sessionId,
    this.mode,
    this.distanceSource,
    this.error,
  });

  String? sessionId;
  NativeWorkoutState state;
  NativeWorkoutMode? mode;

  /// Time spent running (a pause is NOT in it), on the phone's monotonic clock.
  int activeMs;
  int pausedMs;

  /// The workout distance. 0 while no source is chosen: never a guess.
  double distanceMeters;

  /// Where the distance comes from now.
  NativeSourceRef? distanceSource;

  /// Sequence number of the last journal event.
  int lastSeq;

  /// A journal write FAILED. Sticky: what this snapshot shows is NOT guaranteed to survive the process dying.
  bool journalFailed;
  NativeRestoreStatus restoreStatus;
  int updatedAtMs;
  String? error;
}

@HostApi()
abstract class WorkoutHostApi {
  /// Starts a workout. Fails with SESSION_OPEN when another one is running or paused.
  NativeWorkoutSnapshot start(String sessionId, NativeWorkoutMode mode);

  NativeWorkoutSnapshot pause(String sessionId);
  NativeWorkoutSnapshot resume(String sessionId);

  /// Ends the workout. The journal stays until [clearSession].
  NativeWorkoutSnapshot finish(String sessionId);

  /// A cumulative distance (a GPS total, a footpod, a treadmill). [ageMs] is how old the value already is, so the sample is
  /// stamped with its real time, not with the time of this call. [epoch] grows with every new connection of the source.
  /// Dropped when it is not for the open session.
  void submitCounter(String sessionId, NativeSourceRef source, int epoch, double meters, int ageMs);

  /// A speed in metres per second, integrated over time while the workout runs.
  void submitSpeed(String sessionId, NativeSourceRef source, int epoch, double mps, int ageMs);

  /// The user's choice of distance source (null clears it). Only used while that source is fresh.
  void setPreferredSource(String sessionId, NativeSourceRef? source);

  NativeWorkoutSnapshot snapshot();

  /// Rebuilds the session of [sessionId] from its journal after the process died. It comes back PAUSED (a session that was
  /// running); the time the process was dead is not activity and no distance is invented. If the engine already runs this
  /// session, nothing is replayed.
  NativeWorkoutSnapshot restore(String sessionId);

  /// The id of the workout that was running or paused when it was last seen, or null.
  String? activeSessionId();

  /// Deletes the journal of [sessionId].
  void clearSession(String sessionId);
}

@FlutterApi()
abstract class WorkoutFlutterApi {
  /// About once per second and on every change.
  void onSnapshot(NativeWorkoutSnapshot snapshot);
}
