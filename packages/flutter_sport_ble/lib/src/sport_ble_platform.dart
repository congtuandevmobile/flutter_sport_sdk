import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_sport_ble/src/models.dart';
import 'package:flutter_sport_ble/src/sport_ble_api.g.dart';

/// The native side as the Dart API sees it (a fake implements this in tests).
abstract class SportBlePlatform {
  Stream<SportDevice> get devices;
  Stream<void> get scanStopped;
  Stream<SensorSnapshot> get snapshots;
  Stream<RawPacket> get rawPackets;

  Future<BleAdapterState> adapterState();
  Future<void> startScan(Duration timeout);
  Future<void> stopScan();
  Future<void> connect(String deviceId);
  Future<void> disconnect(String deviceId);
  Future<void> forget(String deviceId);
  Future<void> setPreferredSource(SportMetric metric, String? deviceId);
  Future<SensorSnapshot> snapshot();
}

/// Pigeon implementation: the host API for calls, the Flutter API for events.
class PigeonSportBlePlatform implements SportBlePlatform, SportBleFlutterApi {
  PigeonSportBlePlatform({SportBleHostApi? api}) : _api = api ?? SportBleHostApi() {
    SportBleFlutterApi.setUp(this);
  }

  final SportBleHostApi _api;
  final _devices = StreamController<SportDevice>.broadcast();
  final _scanStopped = StreamController<void>.broadcast();
  final _snapshots = StreamController<SensorSnapshot>.broadcast();
  final _raw = StreamController<RawPacket>.broadcast();

  @override
  Stream<SportDevice> get devices => _devices.stream;
  @override
  Stream<void> get scanStopped => _scanStopped.stream;
  @override
  Stream<SensorSnapshot> get snapshots => _snapshots.stream;
  @override
  Stream<RawPacket> get rawPackets => _raw.stream;

  // ── SportBleFlutterApi (events from native) ──

  @override
  void onDeviceFound(NativeBleDevice device) => _devices.add(
    SportDevice(
      id: device.id,
      name: device.name,
      rssi: device.rssi,
      capabilities: _capabilities(device.capabilities),
    ),
  );

  @override
  void onScanStopped() => _scanStopped.add(null);

  @override
  void onSnapshot(NativeSensorSnapshot snapshot) => _snapshots.add(_snapshot(snapshot));

  @override
  void onRawPacket(NativeRawPacket packet) => _raw.add(
    RawPacket(
      deviceId: packet.deviceId,
      epoch: packet.epoch,
      characteristic: packet.characteristic,
      data: packet.data,
      receivedAtMs: packet.receivedAtMs,
    ),
  );

  // ── SportBlePlatform (calls to native) ──

  @override
  Future<BleAdapterState> adapterState() async => switch (await _api.adapterState()) {
    NativeAdapterState.unknown => BleAdapterState.unknown,
    NativeAdapterState.unsupported => BleAdapterState.unsupported,
    NativeAdapterState.unauthorized => BleAdapterState.unauthorized,
    NativeAdapterState.poweredOff => BleAdapterState.poweredOff,
    NativeAdapterState.ready => BleAdapterState.ready,
  };

  @override
  Future<void> startScan(Duration timeout) => _api.startScan(timeout.inMilliseconds);

  @override
  Future<void> stopScan() => _api.stopScan();

  @override
  Future<void> connect(String deviceId) async {
    try {
      await _api.connect(deviceId);
    } on PlatformException catch (e) {
      throw SportBleException(e.code, e.message ?? 'connect failed');
    }
  }

  @override
  Future<void> disconnect(String deviceId) => _api.disconnect(deviceId);

  @override
  Future<void> forget(String deviceId) => _api.forget(deviceId);

  @override
  Future<void> setPreferredSource(SportMetric metric, String? deviceId) =>
      _api.setPreferredSource(NativeMetric.values[metric.index], deviceId);

  @override
  Future<SensorSnapshot> snapshot() async => _snapshot(await _api.snapshot());

  static List<SensorCapability> _capabilities(List<NativeCapability> list) =>
      [for (final c in list) SensorCapability.values[c.index]];

  static SensorSnapshot _snapshot(NativeSensorSnapshot s) => SensorSnapshot(
    values: {
      for (final m in s.metrics)
        SportMetric.values[m.metric.index]: SensorValue(
          metric: SportMetric.values[m.metric.index],
          value: m.value,
          sourceId: m.sourceId,
          kind: m.kind == NativeKind.cumulative ? MetricKind.cumulative : MetricKind.instantaneous,
          age: Duration(milliseconds: m.ageMs),
        ),
    },
    devices: [
      for (final d in s.devices)
        DeviceState(
          id: d.id,
          name: d.name,
          connection: switch (d.connection) {
            NativeConnection.disconnected => BleConnectionState.disconnected,
            NativeConnection.connecting => BleConnectionState.connecting,
            NativeConnection.connected => BleConnectionState.connected,
            NativeConnection.failed => BleConnectionState.failed,
          },
          epoch: d.epoch,
          capabilities: _capabilities(d.capabilities),
          error: d.error,
        ),
    ],
    updatedAtMs: s.updatedAtMs,
  );
}
