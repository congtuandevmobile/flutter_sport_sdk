import 'package:flutter_sport_ble/flutter_sport_ble.dart';
import 'package:flutter_workout/flutter_workout.dart';

/// The glue between the sensors, the GPS and a workout. It owns no rule: it only says WHICH source a number is and WHEN it was
/// measured, and the workout core decides (one source at a time, differences only, never across a pause or a reconnect).
///
///  - a device's cumulative distance (`totalDistance`) is a COUNTER source, with the device's current `epoch` (a reconnect is a new
///    baseline) and the value's `age` (the sample keeps its real time even if the snapshot repeats it);
///  - a device's speed (running or cycling) is a SPEED source of the same device: a different source from its counter;
///  - a GPS total is the `gps` counter source.
class WorkoutFeeder {
  WorkoutFeeder({required this.workout, required this.sessionId});

  final FlutterWorkout workout;
  final String sessionId;

  /// Feed with every `SportBle.snapshots` event.
  Future<void> onSensors(SensorSnapshot snapshot) async {
    final epochs = {for (final d in snapshot.devices) d.id: d.epoch};
    final distance = snapshot[SportMetric.totalDistance];
    if (distance != null) {
      await workout.submitCounter(
        sessionId,
        DistanceSourceRef.counter(distance.sourceId),
        distance.value,
        epoch: epochs[distance.sourceId] ?? 1,
        age: distance.age,
      );
    }
    for (final metric in const [SportMetric.runningSpeed, SportMetric.cyclingSpeed]) {
      final speed = snapshot[metric];
      if (speed == null) continue;
      await workout.submitSpeed(
        sessionId,
        DistanceSourceRef.speed(speed.sourceId),
        speed.value,
        epoch: epochs[speed.sourceId] ?? 1,
        age: speed.age,
      );
    }
  }

  /// Feed with the total distance of the GPS recording (`TrackingSnapshot.totalMeters`).
  Future<void> onGpsTotal(double meters) =>
      workout.submitCounter(sessionId, const DistanceSourceRef.gps(), meters);
}
