import 'dart:async';

import 'package:flutter_workout/src/models.dart';
import 'package:flutter_workout/src/workout_platform.dart';

/// A workout session: one distance from counters and speeds, and a journal that survives the process dying.
///
/// Nothing here measures anything. A host (or a small glue between `flutter_sport_ble` and `flutter_tracking_gps`) hands over what
/// its sensors say with [submitCounter] and [submitSpeed]; the native core adds ONLY differences, from ONE source at a time, never
/// across a pause, a reconnect or a source switch, and writes every change to a journal BEFORE it shows the number.
///
/// Limits: the workout belongs to the plugin instance, so it stops being fed when the Flutter engine goes away (a process-wide
/// owner is not built); after the process dies [restore] brings it back PAUSED.
class FlutterWorkout {
  FlutterWorkout({WorkoutPlatform? platform}) : _platform = platform ?? PigeonWorkoutPlatform();

  final WorkoutPlatform _platform;

  /// The workout, about once per second and on every change.
  Stream<WorkoutSnapshot> get snapshots => _platform.snapshots;

  /// Starts a workout. Throws [WorkoutException] `SESSION_OPEN` when another one is running or paused, and
  /// `JOURNAL_WRITE_FAILED` (nothing is started) when the first journal line cannot be written.
  Future<WorkoutSnapshot> start({required String sessionId, required WorkoutMode mode}) =>
      _platform.start(sessionId, mode);

  Future<WorkoutSnapshot> pause(String sessionId) => _platform.pause(sessionId);
  Future<WorkoutSnapshot> resume(String sessionId) => _platform.resume(sessionId);

  /// Ends the workout. The journal stays until [clearSession].
  Future<WorkoutSnapshot> finish(String sessionId) => _platform.finish(sessionId);

  /// A cumulative distance in metres (a GPS total, a footpod, a treadmill). [age] is how old the value already is (for a snapshot of
  /// `flutter_sport_ble`, its `age`), so the sample is stamped with its real time. [epoch] must grow with every new connection of the
  /// source (for a device, `DeviceState.epoch`): a new epoch starts from a new baseline and credits nothing for the gap.
  Future<void> submitCounter(
    String sessionId,
    DistanceSourceRef source,
    double meters, {
    int epoch = 1,
    Duration age = Duration.zero,
  }) => _platform.submitCounter(sessionId, source, epoch, meters, age);

  /// A speed in metres per second, integrated over time while the workout runs (never across a gap of more than 5 s or a pause).
  Future<void> submitSpeed(
    String sessionId,
    DistanceSourceRef source,
    double metersPerSecond, {
    int epoch = 1,
    Duration age = Duration.zero,
  }) => _platform.submitSpeed(sessionId, source, epoch, metersPerSecond, age);

  /// The user's choice of distance source (null clears it). It only applies while that source is fresh.
  Future<void> setPreferredSource(String sessionId, DistanceSourceRef? source) =>
      _platform.setPreferredSource(sessionId, source);

  Future<WorkoutSnapshot> snapshot() => _platform.snapshot();

  /// Rebuilds [sessionId] from its journal after the process died. It comes back PAUSED: the time the process was dead is not
  /// activity and no distance is invented. [WorkoutSnapshot.restoreStatus] says whether the journal was intact, repaired or partial.
  Future<WorkoutSnapshot> restore(String sessionId) => _platform.restore(sessionId);

  /// The id of the workout that was running or paused when it was last seen, or null: ask it on launch, then [restore] it.
  Future<String?> activeSessionId() => _platform.activeSessionId();

  /// Deletes the journal of [sessionId] (throws `SESSION_OPEN` for a workout that is still open).
  Future<void> clearSession(String sessionId) => _platform.clearSession(sessionId);
}
