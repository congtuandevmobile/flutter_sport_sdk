import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'flutter_sport_ble',
    dartOut: 'lib/src/sport_ble_api.g.dart',
    kotlinOut:
        'android/src/main/kotlin/io/github/congtuandevmobile/flutter_sport_ble/SportBleApi.g.kt',
    kotlinOptions: KotlinOptions(package: 'io.github.congtuandevmobile.flutter_sport_ble'),
    swiftOut: 'ios/Classes/SportBleApi.g.swift',
  ),
)

/// Whether Bluetooth can be used right now.
enum NativeAdapterState {
  unknown,

  /// The device has no Bluetooth LE.
  unsupported,

  /// The app was not allowed to use Bluetooth (permission denied).
  unauthorized,
  poweredOff,
  ready,
}

enum NativeConnection {
  disconnected,
  connecting,
  connected,

  /// The last attempt failed or the link was lost with an error (see `NativeDeviceState.error`).
  failed,
}

/// Order matches `sensor.model.MetricType` of the shared core.
enum NativeMetric {
  heartRate,
  runningSpeed,
  runningCadence,
  runningStrideLength,
  totalDistance,
}

enum NativeKind { instantaneous, cumulative }

/// Order matches `sensor.model.Capability` of the shared core.
enum NativeCapability {
  heartRate,
  runningSpeedCadence,
  cyclingSpeedCadence,
  cyclingPower,
  fitnessMachine,
  battery,
  deviceInformation,
}

class NativeBleDevice {
  NativeBleDevice({
    required this.id,
    required this.rssi,
    required this.capabilities,
    this.name,
  });

  /// Android: the MAC address; iOS: the peripheral UUID. Stable for one phone only.
  String id;
  String? name;
  int rssi;

  /// What the advertisement says (services); the real list is known after connecting.
  List<NativeCapability> capabilities;
}

class NativeDeviceState {
  NativeDeviceState({
    required this.id,
    required this.connection,
    required this.epoch,
    required this.capabilities,
    this.name,
    this.error,
  });

  String id;
  String? name;
  NativeConnection connection;

  /// Grows with every new connection to the device: data of an older one is never mixed with a newer one.
  int epoch;
  List<NativeCapability> capabilities;
  String? error;
}

class NativeResolvedMetric {
  NativeResolvedMetric({
    required this.metric,
    required this.value,
    required this.sourceId,
    required this.kind,
    required this.ageMs,
  });

  NativeMetric metric;
  double value;

  /// The device this value came from.
  String sourceId;
  NativeKind kind;

  /// How old the value is on this phone's clock.
  int ageMs;
}

class NativeSensorSnapshot {
  NativeSensorSnapshot({required this.metrics, required this.devices, required this.updatedAtMs});

  /// One entry per metric that has a healthy source; a metric without one is absent (unknown), never 0.
  List<NativeResolvedMetric> metrics;
  List<NativeDeviceState> devices;
  int updatedAtMs;
}

/// A notification of a characteristic the core does not decode (for instance the Cycling Speed and Cadence Measurement),
/// handed over so that whoever decodes it can use it.
class NativeRawPacket {
  NativeRawPacket({
    required this.deviceId,
    required this.epoch,
    required this.characteristic,
    required this.data,
    required this.receivedAtMs,
  });

  String deviceId;
  int epoch;

  /// 16-bit characteristic number as 4 lowercase hex digits, for example "2a5b".
  String characteristic;
  Uint8List data;
  int receivedAtMs;
}

@HostApi()
abstract class SportBleHostApi {
  NativeAdapterState adapterState();

  /// Scans for devices that advertise a sport service (heart rate, running or cycling speed and cadence). Stops by itself
  /// after [timeoutMs].
  void startScan(int timeoutMs);

  void stopScan();

  /// Connects, discovers the services and subscribes to the measurements. Completes when the link is up and subscribed.
  @async
  void connect(String deviceId);

  void disconnect(String deviceId);

  /// Disconnects and forgets the device (its values and its preference).
  void forget(String deviceId);

  /// The device the user prefers for [metric] (null clears it). Only used while that device has a healthy value.
  void setPreferredSource(NativeMetric metric, String? deviceId);

  NativeSensorSnapshot snapshot();
}

@FlutterApi()
abstract class SportBleFlutterApi {
  void onDeviceFound(NativeBleDevice device);
  void onScanStopped();

  /// About once per second and on every connection change.
  void onSnapshot(NativeSensorSnapshot snapshot);
  void onRawPacket(NativeRawPacket packet);
}
