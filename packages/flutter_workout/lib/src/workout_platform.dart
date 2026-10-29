import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_workout/src/models.dart';
import 'package:flutter_workout/src/workout_api.g.dart';

/// The native side as the Dart API sees it (a fake implements this in tests).
abstract class WorkoutPlatform {
  Stream<WorkoutSnapshot> get snapshots;

  Future<WorkoutSnapshot> start(String sessionId, WorkoutMode mode);
  Future<WorkoutSnapshot> pause(String sessionId);
  Future<WorkoutSnapshot> resume(String sessionId);
  Future<WorkoutSnapshot> finish(String sessionId);
  Future<void> submitCounter(String sessionId, DistanceSourceRef source, int epoch, double meters, Duration age);
  Future<void> submitSpeed(String sessionId, DistanceSourceRef source, int epoch, double mps, Duration age);
  Future<void> setPreferredSource(String sessionId, DistanceSourceRef? source);
  Future<WorkoutSnapshot> snapshot();
  Future<WorkoutSnapshot> restore(String sessionId);
  Future<String?> activeSessionId();
  Future<void> clearSession(String sessionId);
}

/// Pigeon implementation: the host API for calls, the Flutter API for events.
class PigeonWorkoutPlatform implements WorkoutPlatform, WorkoutFlutterApi {
  PigeonWorkoutPlatform({WorkoutHostApi? api}) : _api = api ?? WorkoutHostApi() {
    WorkoutFlutterApi.setUp(this);
  }

  final WorkoutHostApi _api;
  final _snapshots = StreamController<WorkoutSnapshot>.broadcast();

  @override
  Stream<WorkoutSnapshot> get snapshots => _snapshots.stream;

  @override
  void onSnapshot(NativeWorkoutSnapshot snapshot) => _snapshots.add(_snapshot(snapshot));

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on PlatformException catch (e) {
      throw WorkoutException(e.code, e.message ?? 'workout call failed');
    }
  }

  @override
  Future<WorkoutSnapshot> start(String sessionId, WorkoutMode mode) =>
      _guard(() async => _snapshot(await _api.start(sessionId, NativeWorkoutMode.values[mode.index])));

  @override
  Future<WorkoutSnapshot> pause(String sessionId) => _guard(() async => _snapshot(await _api.pause(sessionId)));

  @override
  Future<WorkoutSnapshot> resume(String sessionId) => _guard(() async => _snapshot(await _api.resume(sessionId)));

  @override
  Future<WorkoutSnapshot> finish(String sessionId) => _guard(() async => _snapshot(await _api.finish(sessionId)));

  @override
  Future<void> submitCounter(String sessionId, DistanceSourceRef source, int epoch, double meters, Duration age) =>
      _guard(() => _api.submitCounter(sessionId, _ref(source), epoch, meters, age.inMilliseconds));

  @override
  Future<void> submitSpeed(String sessionId, DistanceSourceRef source, int epoch, double mps, Duration age) =>
      _guard(() => _api.submitSpeed(sessionId, _ref(source), epoch, mps, age.inMilliseconds));

  @override
  Future<void> setPreferredSource(String sessionId, DistanceSourceRef? source) =>
      _guard(() => _api.setPreferredSource(sessionId, source == null ? null : _ref(source)));

  @override
  Future<WorkoutSnapshot> snapshot() => _guard(() async => _snapshot(await _api.snapshot()));

  @override
  Future<WorkoutSnapshot> restore(String sessionId) => _guard(() async => _snapshot(await _api.restore(sessionId)));

  @override
  Future<String?> activeSessionId() => _guard(() => _api.activeSessionId());

  @override
  Future<void> clearSession(String sessionId) => _guard(() => _api.clearSession(sessionId));

  static NativeSourceRef _ref(DistanceSourceRef s) =>
      NativeSourceRef(id: s.id, kind: NativeSourceKind.values[s.kind.index]);

  static WorkoutSnapshot _snapshot(NativeWorkoutSnapshot s) => WorkoutSnapshot(
    sessionId: s.sessionId,
    state: WorkoutState.values[s.state.index],
    mode: s.mode == null ? null : WorkoutMode.values[s.mode!.index],
    activeTime: Duration(milliseconds: s.activeMs),
    pausedTime: Duration(milliseconds: s.pausedMs),
    distanceMeters: s.distanceMeters,
    distanceSource: s.distanceSource == null
        ? null
        : DistanceSourceRef(s.distanceSource!.id, DistanceSourceKind.values[s.distanceSource!.kind.index]),
    lastSeq: s.lastSeq,
    journalFailed: s.journalFailed,
    restoreStatus: RestoreStatus.values[s.restoreStatus.index],
    error: s.error,
  );
}
