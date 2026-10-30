import 'dart:async';

import 'package:flutter_activity/flutter_activity.dart';
import 'package:flutter_multisport_adapters/flutter_multisport_adapters.dart';
import 'package:flutter_sport_ble/flutter_sport_ble.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tracking_gps/flutter_tracking_gps.dart';

TrackingSnapshot gps(double total, {String? session = 's', double? speed, DateTime? fixAt}) => TrackingSnapshot(
  state: RecordingState.running, quality: GpsQuality.good, totalMeters: total, gpsMeters: total, gapBridgeMeters: 0, pdrMeters: 0,
  pendingPdrMeters: 0, segmentId: 1, fixCount: 1, sessionId: session, speedMps: speed, lastFixAt: fixAt,
);

SensorSnapshot ble(List<DeviceValue> values) => SensorSnapshot(values: const {}, devices: const [], updatedAtMs: 0, deviceValues: values);

DeviceValue dv(String device, SportMetric metric, double value, {int epoch = 1, Duration age = Duration.zero, MetricKind kind = MetricKind.instantaneous}) =>
    DeviceValue(deviceId: device, epoch: epoch, metric: metric, value: value, kind: kind, age: age);

void main() {
  final now = DateTime(2026, 1, 1, 10);

  test('GPS: the total goes out only when it changed, with the age of the fix and the same epoch', () async {
    final input = StreamController<TrackingSnapshot>();
    final source = GpsProgressSource(input.stream, clock: () => now);
    final seen = <CounterReading>[];
    source.readings.listen(seen.add);
    input.add(gps(10, fixAt: now.subtract(const Duration(milliseconds: 400))));
    input.add(gps(10, fixAt: now)); // the same number again: nothing new
    input.add(gps(12.5, fixAt: now));
    await Future<void>.delayed(Duration.zero);
    expect(seen.map((r) => r.value), [10, 12.5]);
    expect(seen.first.age, const Duration(milliseconds: 400));
    expect(seen.map((r) => r.epoch), [1, 1]);
    expect(source.sourceId, 'gps');
  });

  test('GPS: a new recording is a new epoch (its total starting again is not a jump); a snapshot without a session says nothing', () async {
    final input = StreamController<TrackingSnapshot>();
    final seen = <CounterReading>[];
    GpsProgressSource(input.stream, clock: () => now).readings.listen(seen.add);
    input.add(gps(500, session: 'a'));
    input.add(gps(0, session: null));
    input.add(gps(3, session: 'b'));
    await Future<void>.delayed(Duration.zero);
    expect(seen.map((r) => [r.value, r.epoch]), [[500, 1], [3, 2]]);
  });

  test('GPS: the speed is a sample made at the time of the fix, once per fix, and absent when unknown', () async {
    final input = StreamController<TrackingSnapshot>();
    final seen = <TelemetrySample>[];
    GpsTelemetrySource(input.stream).samples.listen(seen.add);
    input.add(gps(1, speed: 3.2, fixAt: now));
    input.add(gps(2, speed: 3.3, fixAt: now)); // the same fix
    input.add(gps(3, speed: null, fixAt: now.add(const Duration(seconds: 1))));
    input.add(gps(4, speed: 3.4, fixAt: now.add(const Duration(seconds: 2))));
    await Future<void>.delayed(Duration.zero);
    expect(seen.map((s) => s.value), [3.2, 3.4]);
    expect(seen.first.metric, TelemetryMetric.speed);
    expect(seen.first.at, now);
  });

  test('BLE counter: it reads the device the stage was bound to, not the value the resolver chose among devices', () async {
    final input = StreamController<SensorSnapshot>();
    final seen = <CounterReading>[];
    BleCounterSource(snapshots: input.stream, deviceId: 'rower', metric: SportMetric.totalDistance, sourceId: 'pm5').readings.listen(seen.add);
    input.add(ble([
      dv('footpod', SportMetric.totalDistance, 9000, kind: MetricKind.cumulative),
      dv('rower', SportMetric.totalDistance, 120, epoch: 4, age: const Duration(milliseconds: 250), kind: MetricKind.cumulative),
    ]));
    input.add(ble([dv('rower', SportMetric.totalDistance, 120, epoch: 4, kind: MetricKind.cumulative)])); // unchanged
    input.add(ble([dv('rower', SportMetric.totalDistance, 135, epoch: 4, kind: MetricKind.cumulative)]));
    input.add(ble([dv('rower', SportMetric.totalDistance, 2, epoch: 5, kind: MetricKind.cumulative)])); // reconnected, counter restarted
    await Future<void>.delayed(Duration.zero);
    expect(seen.map((r) => [r.value, r.epoch]), [[120, 4], [135, 4], [2, 5]]);
    expect(seen.first.age, const Duration(milliseconds: 250));
  });

  test('BLE counter: an instantaneous metric is not a counter, and a device that is not there gives nothing', () async {
    final input = StreamController<SensorSnapshot>();
    final seen = <CounterReading>[];
    BleCounterSource(snapshots: input.stream, deviceId: 'strap', metric: SportMetric.heartRate, sourceId: 'x').readings.listen(seen.add);
    input.add(ble([dv('strap', SportMetric.heartRate, 150)]));
    input.add(ble(const []));
    await Future<void>.delayed(Duration.zero);
    expect(seen, isEmpty);
  });

  test('BLE telemetry: each sample is made "now minus its age", only for the metrics the device has, and never repeated', () async {
    final input = StreamController<SensorSnapshot>();
    final seen = <TelemetrySample>[];
    BleTelemetrySource(snapshots: input.stream, deviceId: 'strap', clock: () => now).samples.listen(seen.add);
    input.add(ble([
      dv('strap', SportMetric.heartRate, 152, age: const Duration(milliseconds: 600)),
      dv('other', SportMetric.heartRate, 99), // another device
    ]));
    input.add(ble([dv('strap', SportMetric.heartRate, 152, age: const Duration(milliseconds: 600))])); // the same measurement again
    await Future<void>.delayed(Duration.zero);
    expect(seen, hasLength(1));
    expect(seen.single.metric, TelemetryMetric.heartRate);
    expect(seen.single.value, 152);
    expect(seen.single.at, now.subtract(const Duration(milliseconds: 600)));
    expect(seen.single.sourceId, 'strap');
  });
}
