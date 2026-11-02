import 'package:flutter/material.dart';
import 'package:flutter_sport_ble/flutter_sport_ble.dart';
import 'package:flutter_tracking_gps/flutter_tracking_gps.dart';
import 'package:flutter_workout/flutter_workout.dart';

import 'real_flow_screen.dart';

/// Four native cores (tracking, sensors, workout and challenge) link in one
/// app. The first screen checks the first three; RealFlowScreen exercises the
/// activity and challenge integrations.
void main() {
  runApp(const SensorsDemo());
}

class SensorsDemo extends StatefulWidget {
  const SensorsDemo({super.key});

  @override
  State<SensorsDemo> createState() => _SensorsDemoState();
}

class _SensorsDemoState extends State<SensorsDemo> {
  final SportBle _ble = SportBle();
  final FlutterTrackingGps _gps = FlutterTrackingGps();
  final FlutterWorkout _workout = FlutterWorkout();
  String _status = 'starting';

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    String status;
    try {
      final adapter = await _ble.adapterState();
      final snapshot = await _ble.snapshot();
      final gps = await _gps.permissionStatus();
      // A tiny workout through the native core (a launch check of the Kotlin/Native runtime, journal included).
      const id = 'launch-check';
      await _workout.start(sessionId: id, mode: WorkoutMode.indoorRunning);
      const src = DistanceSourceRef.counter('check');
      await _workout.submitCounter(id, src, 0);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await _workout.finish(id);
      final workout = await _workout.snapshot();
      await _workout.clearSession(id);
      status =
          'bluetooth: ${adapter.name}, devices: ${snapshot.devices.length}, gps permission: ${gps.name}, workout: ${workout.state.name}';
    } catch (e) {
      status = 'unavailable: $e';
    }
    if (!mounted) return;
    setState(() => _status = status);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_status, key: const Key('status')),
            Builder(
              builder: (context) => FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const RealFlowScreen(),
                  ),
                ),
                child: const Text('Open real sport flow'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
