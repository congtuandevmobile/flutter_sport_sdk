
import 'package:flutter_sport_ble/flutter_sport_ble.dart';
import 'package:flutter_sport_ble/src/sport_ble_api.g.dart';
import 'package:flutter_sport_ble/src/sport_ble_platform.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeHost extends SportBleHostApi {
  final calls = <String>[];
  Object? connectError;

  @override
  Future<NativeAdapterState> adapterState() async => NativeAdapterState.poweredOff;
  @override
  Future<void> startScan(int timeoutMs, bool allDevices) async => calls.add('scan:$timeoutMs:$allDevices');
  @override
  Future<void> stopScan() async => calls.add('stopScan');
  @override
  Future<void> connect(String deviceId) async {
    calls.add('connect:$deviceId');
    if (connectError != null) throw connectError!;
  }

  @override
  Future<void> disconnect(String deviceId) async => calls.add('disconnect:$deviceId');
  @override
  Future<void> forget(String deviceId) async => calls.add('forget:$deviceId');
  @override
  Future<void> setPreferredSource(NativeMetric metric, String? deviceId) async =>
      calls.add('prefer:${metric.name}:$deviceId');
  @override
  Future<void> setWheelCircumference(String deviceId, double? metres) async => calls.add('wheel:$deviceId:$metres');
  @override
  Future<NativeSensorSnapshot> snapshot() async => _native();
}

NativeSensorSnapshot _native() => NativeSensorSnapshot(
  updatedAtMs: 1234,
  deviceValues: [
    NativeDeviceMetric(deviceId: 'foot', epoch: 1, metric: NativeMetric.totalDistance, value: 4000.5, kind: NativeKind.cumulative, ageMs: 900),
    NativeDeviceMetric(deviceId: 'rower', epoch: 4, metric: NativeMetric.totalDistance, value: 850, kind: NativeKind.cumulative, ageMs: 100),
  ],
  metrics: [
    NativeResolvedMetric(metric: NativeMetric.heartRate, value: 145, sourceId: 'strap', kind: NativeKind.instantaneous, ageMs: 200),
    NativeResolvedMetric(metric: NativeMetric.runningCadence, value: 0, sourceId: 'foot', kind: NativeKind.instantaneous, ageMs: 900),
    NativeResolvedMetric(metric: NativeMetric.totalDistance, value: 4000.5, sourceId: 'foot', kind: NativeKind.cumulative, ageMs: 900),
  ],
  devices: [
    NativeDeviceState(
      id: 'strap',
      connection: NativeConnection.ready,
      epoch: 2,
      capabilities: [NativeCapability.heartRate, NativeCapability.battery],
      discoveredServices: ['180d', '180f'],
      subscribedCharacteristics: ['2a37'],
      recentRrMs: [1000, 500],
      manufacturer: 'Polar',
      model: 'H10',
      firmware: '3.0.35',
      batteryPercent: 82,
    ),
    NativeDeviceState(
      id: 'foot',
      connection: NativeConnection.failed,
      epoch: 1,
      capabilities: [NativeCapability.runningSpeedCadence, NativeCapability.battery],
      discoveredServices: [],
      subscribedCharacteristics: [],
      recentRrMs: [],
      error: 'GATT_8: lost',
      name: 'Footpod',
    ),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeHost host;
  late PigeonSportBlePlatform platform;
  late SportBle ble;

  setUp(() {
    host = FakeHost();
    platform = PigeonSportBlePlatform(api: host);
    ble = SportBle(platform: platform);
  });

  test('calls reach native with their arguments', () async {
    await ble.startScan(timeout: const Duration(seconds: 5));
    await ble.startScan(timeout: const Duration(seconds: 2), allDevices: true);
    await ble.stopScan();
    await ble.connect('A');
    await ble.disconnect('A');
    await ble.forget('A');
    await ble.setPreferredSource(SportMetric.runningCadence, 'foot');
    await ble.setPreferredSource(SportMetric.heartRate, null);
    await ble.setWheelCircumference('wheel', 2.1);
    expect(host.calls, [
      'scan:5000:false', 'scan:2000:true', 'stopScan', 'connect:A', 'disconnect:A', 'forget:A', 'prefer:runningCadence:foot', 'prefer:heartRate:null', 'wheel:wheel:2.1',
    ]);
    expect(await ble.adapterState(), BleAdapterState.poweredOff);
  });

  test('a snapshot keeps one value per metric, 0 is a value and a missing metric is null', () async {
    final s = await ble.snapshot();
    expect(s.heartRateBpm, 145);
    expect(s.runningCadencePerMin, 0);
    expect(s.runningSpeedMps, isNull);
    expect(s.deviceTotalDistanceM, 4000.5);
    expect(s[SportMetric.totalDistance]!.kind, MetricKind.cumulative);
    expect(s[SportMetric.heartRate]!.sourceId, 'strap');
    expect(s[SportMetric.heartRate]!.age, const Duration(milliseconds: 200));
    expect(s.updatedAtMs, 1234);
    // the resolved value keeps ONE source, the per-device values keep each device's own counter
    expect(s.valueOf('foot', SportMetric.totalDistance)!.value, 4000.5);
    expect(s.valueOf('rower', SportMetric.totalDistance)!.value, 850);
    expect(s.valueOf('rower', SportMetric.totalDistance)!.epoch, 4);
    expect(s.valueOf('rower', SportMetric.totalDistance)!.age, const Duration(milliseconds: 100));
    expect(s.valueOf('rower', SportMetric.heartRate), isNull);
    expect(s.readyDevices.map((d) => d.id), ['strap']);
    final strap = s.devices.firstWhere((d) => d.id == 'strap');
    expect(strap.batteryPercent, 82);
    expect(strap.manufacturer, 'Polar');
    expect(strap.model, 'H10');
    expect(strap.firmware, '3.0.35');
    expect(strap.recentRrMs, [1000, 500]);
    expect(strap.discoveredServices, ['180d', '180f']);
    expect(strap.subscribedCharacteristics, ['2a37']);
    final foot = s.devices.firstWhere((d) => d.id == 'foot');
    expect(foot.connection, BleConnectionState.failed);
    expect(foot.error, 'GATT_8: lost');
    expect(foot.name, 'Footpod');
    expect(foot.capabilities, [SensorCapability.runningSpeedCadence, SensorCapability.battery]);
  });

  test('events from native become streams', () async {
    final devices = <SportDevice>[];
    final snaps = <SensorSnapshot>[];
    final raws = <RawPacket>[];
    var stops = 0;
    ble.devices.listen(devices.add);
    ble.snapshots.listen(snaps.add);
    ble.rawPackets.listen(raws.add);
    ble.scanStopped.listen((_) => stops++);

    platform.onDeviceFound(NativeBleDevice(id: 'A', name: 'Strap', rssi: -60, capabilities: [NativeCapability.heartRate]));
    platform.onSnapshot(_native());
    platform.onRawPacket(NativeRawPacket(deviceId: 'bike', epoch: 3, characteristic: '2a5b', data: Uint8List.fromList([2, 1, 0, 1, 0]), receivedAtMs: 77));
    platform.onScanStopped();
    await Future<void>.delayed(Duration.zero);

    expect(devices.single.name, 'Strap');
    expect(devices.single.capabilities, [SensorCapability.heartRate]);
    expect(snaps.single.heartRateBpm, 145);
    expect(raws.single.epoch, 3);
    expect(raws.single.data, [2, 1, 0, 1, 0]);
    expect(stops, 1);
  });

  test('a failed connect throws a SportBleException with the native code', () async {
    host.connectError = PlatformExceptionLike('TIMEOUT', 'the device did not answer in time');
    await expectLater(
      ble.connect('A'),
      throwsA(isA<SportBleException>().having((e) => e.code, 'code', 'TIMEOUT')),
    );
  });

  test('every native metric and capability has its Dart twin in the same order', () {
    expect(SportMetric.values.map((m) => m.name), NativeMetric.values.map((m) => m.name));
    expect(SensorCapability.values.map((m) => m.name), NativeCapability.values.map((m) => m.name));
    expect(BleConnectionState.values.map((m) => m.name), NativeConnection.values.map((m) => m.name));
  });

  test('the empty snapshot has nothing', () {
    const s = SensorSnapshot.empty();
    expect(s.heartRateBpm, isNull);
    expect(s.devices, isEmpty);
  });
}

/// A `PlatformException` (what Pigeon throws for a native FlutterError).
class PlatformExceptionLike extends PlatformException {
  PlatformExceptionLike(String code, String message) : super(code: code, message: message);
}
