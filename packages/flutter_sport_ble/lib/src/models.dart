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

  /// The link is being made.
  connecting,

  /// The link is up and the services are being discovered.
  discovering,

  /// The services are known and the measurements are being subscribed.
  subscribing,

  /// Subscribed to at least one workout measurement: the device can give metrics. The ONLY state that means so.
  ready,

  /// The link works but the device has no workout measurement this package can use, or none could be subscribed.
  notSupported,

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

  /// Pedal revolutions per minute (0 = the cranks are verified still).
  cyclingCadence,

  /// Watts (a power meter, a trainer, a rower). Never negative.
  powerWatts,

  /// Metres per second of a bike (a wheel sensor with a known circumference, or a trainer).
  cyclingSpeed,

  /// Percent, as the machine reports it.
  incline,

  /// Kilocalories since the MACHINE's own start (a counter).
  energyKcal,

  /// Strokes per minute (a rower).
  strokeRate,

  /// Strokes since the MACHINE's own start (a counter).
  strokeCount,

  /// Wheel revolutions of a cycling sensor (a counter).
  wheelRevolutions,

  /// Steps per minute of a machine (cross trainer, stair or step climber).
  stepRate,

  /// Floors since the MACHINE's own start (a counter).
  floors,
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
    this.discoveredServices = const [],
    this.subscribedCharacteristics = const [],
    this.recentRrMs = const [],
    this.name,
    this.error,
    this.manufacturer,
    this.model,
    this.firmware,
    this.batteryPercent,
  });

  final String id;
  final String? name;
  final BleConnectionState connection;

  /// Grows with every new connection to the device.
  final int epoch;
  final List<SensorCapability> capabilities;

  /// 16-bit service numbers found on the device (4 lowercase hex digits), once discovered.
  final List<String> discoveredServices;

  /// 16-bit characteristic numbers that are subscribed.
  final List<String> subscribedCharacteristics;

  /// R-R intervals (ms) of the latest heart rate notification that had some; empty when none.
  final List<int> recentRrMs;

  /// A stable code and a message ("TIMEOUT: ...", "PERMISSION: ...", "NOT_SUPPORTED: ...", "PARTIAL: ...", "GATT_8: ...").
  final String? error;

  /// Read once from Device Information, when the device has it.
  final String? manufacturer;
  final String? model;
  final String? firmware;

  /// The device's own battery level (0 to 100), when it has the Battery service. Per device: never resolved between devices.
  final int? batteryPercent;
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

/// The latest value of one metric of ONE device, before any source is chosen. [epoch] is the connection number of the device and
/// [age] how old the value is: the consumer decides what is fresh. A caller that needs a specific device's counter (a rower's distance
/// next to a footpod's) reads it here, because [SensorSnapshot.values] keeps one source per metric.
@immutable
class DeviceValue {
  const DeviceValue({
    required this.deviceId,
    required this.epoch,
    required this.metric,
    required this.value,
    required this.kind,
    required this.age,
  });

  final String deviceId;
  final int epoch;
  final SportMetric metric;
  final double value;
  final MetricKind kind;
  final Duration age;
}

/// What the connected sensors say now: ONE value per metric that has a healthy source. A metric without one is absent
/// (null here), never 0.
@immutable
class SensorSnapshot {
  const SensorSnapshot({
    required this.values,
    required this.devices,
    required this.updatedAtMs,
    this.deviceValues = const [],
  });

  const SensorSnapshot.empty() : values = const {}, devices = const [], updatedAtMs = 0, deviceValues = const [];

  final Map<SportMetric, SensorValue> values;

  /// What EACH connected device says, nothing chosen (see [DeviceValue]).
  final List<DeviceValue> deviceValues;

  /// The latest [metric] of ONE device, or null when it has none.
  DeviceValue? valueOf(String deviceId, SportMetric metric) {
    for (final v in deviceValues) {
      if (v.deviceId == deviceId && v.metric == metric) return v;
    }
    return null;
  }
  final List<DeviceState> devices;

  /// The phone's monotonic clock (milliseconds) when the snapshot was made.
  final int updatedAtMs;

  SensorValue? operator [](SportMetric metric) => values[metric];

  int? get heartRateBpm => values[SportMetric.heartRate]?.value.round();
  double? get runningSpeedMps => values[SportMetric.runningSpeed]?.value;
  double? get runningCadencePerMin => values[SportMetric.runningCadence]?.value;
  double? get runningStrideLengthM => values[SportMetric.runningStrideLength]?.value;
  double? get deviceTotalDistanceM => values[SportMetric.totalDistance]?.value;
  double? get cyclingCadenceRpm => values[SportMetric.cyclingCadence]?.value;
  double? get powerWatts => values[SportMetric.powerWatts]?.value;
  double? get cyclingSpeedMps => values[SportMetric.cyclingSpeed]?.value;
  double? get inclinePercent => values[SportMetric.incline]?.value;

  /// The devices that can give metrics now ([BleConnectionState.ready]).
  Iterable<DeviceState> get readyDevices => devices.where((d) => d.connection == BleConnectionState.ready);
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

/// Thrown when connecting fails. [code] is stable: TIMEOUT, PERMISSION, BAD_DEVICE, NOT_SUPPORTED, GATT_status, CONNECT_FAILED,
/// DETACHED.
class SportBleException implements Exception {
  const SportBleException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'SportBleException($code): $message';
}
