import 'package:flutter/material.dart';
import 'package:flutter_sport_ble/flutter_sport_ble.dart';
import 'package:flutter_tracking_gps/flutter_tracking_gps.dart';

/// Both native cores (tracking and sensors) live in one app: a launch check, and the first wiring of the two packages.
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
      status = 'bluetooth: ${adapter.name}, devices: ${snapshot.devices.length}, gps permission: ${gps.name}';
    } catch (e) {
      status = 'unavailable: $e';
    }
    if (!mounted) return;
    setState(() => _status = status);
  }

  @override
  Widget build(BuildContext context) =>
      MaterialApp(home: Scaffold(body: Center(child: Text(_status, key: const Key('status')))));
}
