import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workout/flutter_workout.dart';
import 'package:flutter_workout/src/workout_api.g.dart';
import 'package:flutter_workout/src/workout_platform.dart';

class FakeHost extends WorkoutHostApi {
  final calls = <String>[];
  Object? error;

  NativeWorkoutSnapshot _snap({NativeWorkoutState state = NativeWorkoutState.running}) => NativeWorkoutSnapshot(
    sessionId: 'w1',
    state: state,
    mode: NativeWorkoutMode.indoorRunning,
    activeMs: 40000,
    pausedMs: 5000,
    distanceMeters: 123.5,
    distanceSource: NativeSourceRef(id: 'footpod', kind: NativeSourceKind.counter),
    lastSeq: 9,
    journalFailed: false,
    restoreStatus: NativeRestoreStatus.tailRepaired,
    updatedAtMs: 1,
  );

  Future<T> _go<T>(String call, T Function() result) async {
    calls.add(call);
    if (error != null) throw error!;
    return result();
  }

  @override
  Future<NativeWorkoutSnapshot> start(String sessionId, NativeWorkoutMode mode) => _go('start:$sessionId:${mode.name}', _snap);
  @override
  Future<NativeWorkoutSnapshot> pause(String sessionId) => _go('pause', () => _snap(state: NativeWorkoutState.paused));
  @override
  Future<NativeWorkoutSnapshot> resume(String sessionId) => _go('resume', _snap);
  @override
  Future<NativeWorkoutSnapshot> finish(String sessionId) => _go('finish', () => _snap(state: NativeWorkoutState.finished));
  @override
  Future<void> submitCounter(String sessionId, NativeSourceRef source, int epoch, double meters, int ageMs) =>
      _go('counter:${source.id}:${source.kind.name}:$epoch:$meters:$ageMs', () {});
  @override
  Future<void> submitSpeed(String sessionId, NativeSourceRef source, int epoch, double mps, int ageMs) =>
      _go('speed:${source.id}:$epoch:$mps:$ageMs', () {});
  @override
  Future<void> setPreferredSource(String sessionId, NativeSourceRef? source) =>
      _go('prefer:${source?.id}:${source?.kind.name}', () {});
  @override
  Future<NativeWorkoutSnapshot> snapshot() => _go('snapshot', _snap);
  @override
  Future<NativeWorkoutSnapshot> restore(String sessionId) => _go('restore:$sessionId', () => _snap(state: NativeWorkoutState.paused));
  @override
  Future<String?> activeSessionId() => _go('active', () => 'w1');
  @override
  Future<void> clearSession(String sessionId) => _go('clear:$sessionId', () {});
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeHost host;
  late PigeonWorkoutPlatform platform;
  late FlutterWorkout workout;

  setUp(() {
    host = FakeHost();
    platform = PigeonWorkoutPlatform(api: host);
    workout = FlutterWorkout(platform: platform);
  });

  test('commands reach native with their arguments, ages in milliseconds', () async {
    await workout.start(sessionId: 'w1', mode: WorkoutMode.indoorRunning);
    await workout.submitCounter('w1', const DistanceSourceRef.counter('footpod'), 1204.5, epoch: 2, age: const Duration(milliseconds: 800));
    await workout.submitSpeed('w1', const DistanceSourceRef.speed('foot-speed'), 2.8);
    await workout.setPreferredSource('w1', const DistanceSourceRef.counter('treadmill'));
    await workout.setPreferredSource('w1', null);
    await workout.pause('w1');
    await workout.resume('w1');
    await workout.finish('w1');
    await workout.restore('w1');
    await workout.clearSession('w1');
    expect(host.calls, [
      'start:w1:indoorRunning',
      'counter:footpod:counter:2:1204.5:800',
      'speed:foot-speed:1:2.8:0',
      'prefer:treadmill:counter',
      'prefer:null:null',
      'pause', 'resume', 'finish', 'restore:w1', 'clear:w1',
    ]);
    expect(await workout.activeSessionId(), 'w1');
  });

  test('a snapshot keeps the times, the distance, its source and the restore status', () async {
    final s = await workout.restore('w1');
    expect(s.state, WorkoutState.paused);
    expect(s.mode, WorkoutMode.indoorRunning);
    expect(s.activeTime, const Duration(seconds: 40));
    expect(s.pausedTime, const Duration(seconds: 5));
    expect(s.distanceMeters, 123.5);
    expect(s.distanceSource, const DistanceSourceRef.counter('footpod'));
    expect(s.lastSeq, 9);
    expect(s.restoreStatus, RestoreStatus.tailRepaired);
    expect(s.isDurable, isTrue);
  });

  test('a native error becomes a WorkoutException with its code', () async {
    host.error = PlatformException(code: 'SESSION_OPEN', message: 'workout w1 is still open');
    await expectLater(
      workout.start(sessionId: 'w2', mode: WorkoutMode.outdoorRunning),
      throwsA(isA<WorkoutException>().having((e) => e.code, 'code', 'SESSION_OPEN')),
    );
  });

  test('snapshots from native become a stream', () async {
    final seen = <WorkoutSnapshot>[];
    workout.snapshots.listen(seen.add);
    platform.onSnapshot(host._snap());
    await Future<void>.delayed(Duration.zero);
    expect(seen.single.distanceMeters, 123.5);
  });

  test('a failed journal write is visible and means not durable', () {
    final s = WorkoutSnapshot(
      state: WorkoutState.running,
      activeTime: Duration.zero,
      pausedTime: Duration.zero,
      distanceMeters: 1,
      lastSeq: 1,
      journalFailed: true,
      restoreStatus: RestoreStatus.notRestored,
      error: 'JOURNAL_WRITE_FAILED: disk full',
    );
    expect(s.isDurable, isFalse);
  });

  test('every native enum has its Dart twin in the same order', () {
    expect(WorkoutMode.values.map((m) => m.name), NativeWorkoutMode.values.map((m) => m.name));
    expect(WorkoutState.values.map((m) => m.name), NativeWorkoutState.values.map((m) => m.name));
    expect(DistanceSourceKind.values.map((m) => m.name), NativeSourceKind.values.map((m) => m.name));
    expect(RestoreStatus.values.map((m) => m.name), NativeRestoreStatus.values.map((m) => m.name));
  });

  test('source refs compare by id and kind', () {
    expect(const DistanceSourceRef.counter('a'), const DistanceSourceRef.counter('a'));
    expect(const DistanceSourceRef.counter('a') == const DistanceSourceRef.speed('a'), isFalse);
    expect(const DistanceSourceRef.gps().id, 'gps');
  });

  test('the idle snapshot has nothing', () {
    const s = WorkoutSnapshot.idle();
    expect(s.distanceMeters, 0);
    expect(s.distanceSource, isNull);
  });
}
