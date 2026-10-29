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

  /// The link is being made.
  connecting,

  /// The link is up and the services are being discovered.
  discovering,

  /// The services are known and the measurements are being subscribed.
  subscribing,

  /// Subscribed to at least one workout measurement: the sensor can give metrics.
  ready,

  /// The link works but the device has no workout measurement this package can use (or none could be subscribed).
  notSupported,

  /// The last attempt failed or the link was lost with an error (see `NativeDeviceState.error`).
  failed,
}

/// Order matches `sensor.model.MetricType` of the shared core (a test of each native engine fails if it drifts).
enum NativeMetric {
  heartRate,
  runningSpeed,
  runningCadence,
  runningStrideLength,
  totalDistance,
  cyclingCadence,
  powerWatts,
  cyclingSpeed,
  incline,
  energyKcal,
  strokeRate,
  strokeCount,
  wheelRevolutions,
  stepRate,
  floors,
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
    required this.discoveredServices,
    required this.subscribedCharacteristics,
    required this.recentRrMs,
    this.name,
    this.error,
    this.manufacturer,
    this.model,
    this.firmware,
    this.batteryPercent,
  });

  String id;
  String? name;
  NativeConnection connection;

  /// Grows with every new connection to the device: data of an older one is never mixed with a newer one.
  int epoch;
  List<NativeCapability> capabilities;

  /// 16-bit service numbers found on the device (4 lowercase hex digits), once discovered.
  List<String> discoveredServices;

  /// 16-bit characteristic numbers that are subscribed.
  List<String> subscribedCharacteristics;

  /// R-R intervals (ms) of the latest heart rate notification that had some; empty when none.
  List<int> recentRrMs;
  String? error;

  /// Read once from Device Information, when the device has it.
  String? manufacturer;
  String? model;
  String? firmware;

  /// The device's own battery level (0 to 100), when it has the Battery service. Per device: never resolved between devices.
  int? batteryPercent;
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

/// A notification the host may want untouched (the Cycling Speed and Cadence Measurement, which `flutter_tracking_gps` can
/// also decode), handed over besides being decoded here.
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

  /// Scans for devices that advertise a sport service known to the core. With [allDevices] it scans EVERY BLE device (a device
  /// may not advertise its services): what it can do is only known after connecting. Stops by itself after [timeoutMs]; never
  /// scan for everything for long, and not in the background.
  void startScan(int timeoutMs, bool allDevices);

  void stopScan();

  /// Connects, discovers the services and subscribes to the measurements. Completes when the link is up and subscribed.
  @async
  void connect(String deviceId);

  void disconnect(String deviceId);

  /// Disconnects and forgets the device (its values and its preference).
  void forget(String deviceId);

  /// The device the user prefers for [metric] (null clears it). Only used while that device has a healthy value.
  void setPreferredSource(NativeMetric metric, String? deviceId);

  /// The wheel circumference in metres (0.5 to 3.0; null clears it) of a cycling wheel sensor: without it the wheel gives
  /// revolutions but no speed. Applies from the next connection of the device too.
  void setWheelCircumference(String deviceId, double? metres);

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
