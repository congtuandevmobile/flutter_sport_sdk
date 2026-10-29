import 'package:flutter_sport_ble/flutter_sport_ble.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workout/flutter_workout.dart';
import 'package:sensors_demo/workout_feeder.dart';

class RecordingPlatform implements WorkoutPlatform {
  final calls = <String>[];
  @override
  Stream<WorkoutSnapshot> get snapshots => const Stream.empty();
  @override
  Future<void> submitCounter(String sessionId, DistanceSourceRef source, int epoch, double meters, Duration age) async =>
      calls.add('counter:$source:$epoch:$meters:${age.inMilliseconds}');
  @override
  Future<void> submitSpeed(String sessionId, DistanceSourceRef source, int epoch, double mps, Duration age) async =>
      calls.add('speed:$source:$epoch:$mps:${age.inMilliseconds}');
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(invocation.memberName.toString());
}

SensorValue value(SportMetric m, double v, String source, int ageMs) => SensorValue(
  metric: m,
  value: v,
  sourceId: source,
  kind: m == SportMetric.totalDistance ? MetricKind.cumulative : MetricKind.instantaneous,
  age: Duration(milliseconds: ageMs),
);

void main() {
  late RecordingPlatform platform;
  late WorkoutFeeder feeder;

  setUp(() {
    platform = RecordingPlatform();
    feeder = WorkoutFeeder(workout: FlutterWorkout(platform: platform), sessionId: 'w1');
  });

  test('a footpod gives a counter and a speed, as two sources, with the epoch and the age of the value', () async {
    await feeder.onSensors(SensorSnapshot(
      values: {
        SportMetric.totalDistance: value(SportMetric.totalDistance, 1204.5, 'foot', 700),
        SportMetric.runningSpeed: value(SportMetric.runningSpeed, 2.8, 'foot', 700),
        SportMetric.heartRate: value(SportMetric.heartRate, 145, 'strap', 100),
      },
      devices: const [
        DeviceState(id: 'foot', connection: BleConnectionState.ready, epoch: 3, capabilities: []),
        DeviceState(id: 'strap', connection: BleConnectionState.ready, epoch: 1, capabilities: []),
      ],
      updatedAtMs: 1,
    ));
    expect(platform.calls, ['counter:counter:foot:3:1204.5:700', 'speed:speed:foot:3:2.8:700']);
  });

  test('a snapshot without distance or speed feeds nothing (heart rate is not a distance)', () async {
    await feeder.onSensors(SensorSnapshot(
      values: {SportMetric.heartRate: value(SportMetric.heartRate, 145, 'strap', 0)},
      devices: const [],
      updatedAtMs: 1,
    ));
    expect(platform.calls, isEmpty);
  });

  test('a bike speed is a speed source and the GPS total is the gps counter', () async {
    await feeder.onSensors(SensorSnapshot(
      values: {SportMetric.cyclingSpeed: value(SportMetric.cyclingSpeed, 8.0, 'wheel', 0)},
      devices: const [],
      updatedAtMs: 1,
    ));
    await feeder.onGpsTotal(512.0);
    expect(platform.calls, ['speed:speed:wheel:1:8.0:0', 'counter:gps:gps:1:512.0:0']);
  });
}
