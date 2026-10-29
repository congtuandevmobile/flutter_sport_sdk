import 'dart:typed_data';

import 'package:meta/meta.dart';

/// Whether Bluetooth can be used right now.
enum BleAdapterState {
  unknown,

  /// The phone has no Bluetooth LE.
  unsupported,

  /// The app was not allowed to use Bluetooth: the HOST app asks for the permission.
  unauthorized,
  poweredOff,
  ready,
}

enum BleConnectionState {
  disconnected,
  connecting,
  connected,

  /// The attempt failed or the link was lost with an error (see [DeviceState.error]).
  failed,
}

/// What a value measures; the unit is fixed.
enum SportMetric {
  /// Beats per minute.
  heartRate,

  /// Metres per second.
  runningSpeed,

  /// Per minute, as the device reports it (steps or strides: check with the real device).
  runningCadence,

  /// Metres per step or stride, as the device defines it.
  runningStrideLength,

  /// Metres since the DEVICE's own start: a counter, never a workout distance by itself.
  totalDistance,
}

enum MetricKind {
  instantaneous,

  /// A running total of the device: only the difference of two values of one connection means something.
  cumulative,
}

/// What a device can do, from the services it really exposes (never from its name).
enum SensorCapability {
  heartRate,
  runningSpeedCadence,
  cyclingSpeedCadence,
  cyclingPower,
  fitnessMachine,
  battery,
  deviceInformation,
}

@immutable
class SportDevice {
  const SportDevice({required this.id, required this.rssi, required this.capabilities, this.name});

  /// Android: the MAC address; iOS: the peripheral UUID. Stable on one phone only.
  final String id;
  final String? name;
  final int rssi;

  /// What the advertisement says; the real list is known after connecting.
  final List<SensorCapability> capabilities;

  @override
  String toString() => 'SportDevice($id, $name, $rssi dBm, ${capabilities.map((c) => c.name).join('/')})';
}

@immutable
class DeviceState {
  const DeviceState({
    required this.id,
    required this.connection,
    required this.epoch,
    required this.capabilities,
    this.name,
    this.error,
  });

  final String id;
  final String? name;
  final BleConnectionState connection;

  /// Grows with every new connection to the device.
  final int epoch;
  final List<SensorCapability> capabilities;

  /// A stable code and a message ("TIMEOUT: ...", "PERMISSION: ...", "GATT_8: ...").
  final String? error;
}

/// The chosen value of one metric and where it came from.
@immutable
class SensorValue {
  const SensorValue({
    required this.metric,
    required this.value,
    required this.sourceId,
    required this.kind,
    required this.age,
  });

  final SportMetric metric;
  final double value;

  /// The device the value came from (a metric is never averaged over devices).
  final String sourceId;
  final MetricKind kind;

  /// How old the value is on this phone's clock.
  final Duration age;
}

/// What the connected sensors say now: ONE value per metric that has a healthy source. A metric without one is absent
/// (null here), never 0.
@immutable
class SensorSnapshot {
  const SensorSnapshot({required this.values, required this.devices, required this.updatedAtMs});

  const SensorSnapshot.empty() : values = const {}, devices = const [], updatedAtMs = 0;

  final Map<SportMetric, SensorValue> values;
  final List<DeviceState> devices;

  /// The phone's monotonic clock (milliseconds) when the snapshot was made.
  final int updatedAtMs;

  SensorValue? operator [](SportMetric metric) => values[metric];

  int? get heartRateBpm => values[SportMetric.heartRate]?.value.round();
  double? get runningSpeedMps => values[SportMetric.runningSpeed]?.value;
  double? get runningCadencePerMin => values[SportMetric.runningCadence]?.value;
  double? get runningStrideLengthM => values[SportMetric.runningStrideLength]?.value;
  double? get deviceTotalDistanceM => values[SportMetric.totalDistance]?.value;

  Iterable<DeviceState> get connectedDevices => devices.where((d) => d.connection == BleConnectionState.connected);
}

/// A notification of a characteristic the core does not decode (for instance the Cycling Speed and Cadence Measurement,
/// "2a5b"), handed over so that whoever decodes it can use it. [epoch] is the connection number of [deviceId].
@immutable
class RawPacket {
  const RawPacket({
    required this.deviceId,
    required this.epoch,
    required this.characteristic,
    required this.data,
    required this.receivedAtMs,
  });

  final String deviceId;
  final int epoch;

  /// 16-bit characteristic number as 4 lowercase hex digits.
  final String characteristic;
  final Uint8List data;
  final int receivedAtMs;
}

/// Thrown when connecting fails. [code] is stable: TIMEOUT, PERMISSION, BAD_DEVICE, GATT_status, CONNECT_FAILED, DETACHED.
class SportBleException implements Exception {
  const SportBleException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'SportBleException($code): $message';
}
