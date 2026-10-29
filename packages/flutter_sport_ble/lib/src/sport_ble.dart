import 'dart:async';

import 'package:flutter_sport_ble/src/models.dart';
import 'package:flutter_sport_ble/src/sport_ble_platform.dart';

/// Bluetooth LE sport sensors: scan, connect several devices at once, and read ONE resolved value per metric.
///
/// The package decodes the standard sport profiles in a shared Kotlin core (Heart Rate 0x180D, Running Speed and Cadence
/// 0x1814; the Cycling Speed and Cadence measurement is handed over raw), validates every value, drops what is stale,
/// gives each connection an epoch and chooses one source per metric. The Flutter side only shows [snapshots].
///
/// The HOST app asks for the Bluetooth permission (Android 12+: Nearby devices; iOS: the usage description in Info.plist) and
/// decides when to reconnect: this version never reconnects by itself and does not keep a link alive when the Flutter engine
/// goes away.
class SportBle {
  SportBle({SportBlePlatform? platform}) : _platform = platform ?? PigeonSportBlePlatform();

  final SportBlePlatform _platform;

  /// Devices found by a scan (one event per advertisement, so the same device repeats with a new [SportDevice.rssi]).
  Stream<SportDevice> get devices => _platform.devices;

  /// A scan ended (its timeout, [stopScan], or a failure).
  Stream<void> get scanStopped => _platform.scanStopped;

  /// The resolved metrics and the devices, about once per second and on every connection change.
  Stream<SensorSnapshot> get snapshots => _platform.snapshots;

  /// Notifications the core does not decode (the Cycling Speed and Cadence Measurement, "2a5b"), for whoever decodes them.
  Stream<RawPacket> get rawPackets => _platform.rawPackets;

  Future<BleAdapterState> adapterState() => _platform.adapterState();

  /// Scans for devices that advertise heart rate, running or cycling speed and cadence. Stops by itself after [timeout].
  Future<void> startScan({Duration timeout = const Duration(seconds: 10)}) => _platform.startScan(timeout);

  Future<void> stopScan() => _platform.stopScan();

  /// Connects (several devices can be connected at once), discovers the services and subscribes to the measurements.
  /// Completes when the link is up. Throws [SportBleException] when it fails.
  Future<void> connect(String deviceId) => _platform.connect(deviceId);

  Future<void> disconnect(String deviceId) => _platform.disconnect(deviceId);

  /// Disconnects and forgets the device: its values and its preference.
  Future<void> forget(String deviceId) => _platform.forget(deviceId);

  /// The device the user prefers for [metric] (null clears it). It only applies while that device has a healthy value.
  Future<void> setPreferredSource(SportMetric metric, String? deviceId) =>
      _platform.setPreferredSource(metric, deviceId);

  Future<SensorSnapshot> snapshot() => _platform.snapshot();
}
