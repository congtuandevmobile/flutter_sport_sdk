import 'dart:async';

import 'package:flutter_activity/flutter_activity.dart';
import 'package:flutter_sport_ble/flutter_sport_ble.dart';
import 'package:flutter_sport_ble_adapter/flutter_sport_ble_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'resolved telemetry keeps only the selected device and a repeated snapshot once',
    () async {
      final input = StreamController<SensorSnapshot>();
      final samples = <TelemetrySample>[];
      ResolvedBleTelemetrySource(
        snapshots: input.stream,
        clock: () => DateTime.fromMillisecondsSinceEpoch(100000),
      ).samples.listen(samples.add);

      SensorSnapshot snapshot(
        String selected,
        int updatedAtMs,
        int epoch, {
        int ageMs = 100,
      }) => SensorSnapshot(
        values: {
          SportMetric.heartRate: SensorValue(
            metric: SportMetric.heartRate,
            value: selected == 'strap-a' ? 120 : 130,
            sourceId: selected,
            kind: MetricKind.instantaneous,
            age: Duration(milliseconds: ageMs),
          ),
        },
        devices: [
          DeviceState(
            id: selected,
            connection: BleConnectionState.ready,
            epoch: epoch,
            capabilities: const [SensorCapability.heartRate],
          ),
        ],
        updatedAtMs: updatedAtMs,
        deviceValues: const [
          DeviceValue(
            deviceId: 'strap-a',
            epoch: 1,
            metric: SportMetric.heartRate,
            value: 120,
            kind: MetricKind.instantaneous,
            age: Duration(milliseconds: 100),
          ),
          DeviceValue(
            deviceId: 'strap-b',
            epoch: 1,
            metric: SportMetric.heartRate,
            value: 130,
            kind: MetricKind.instantaneous,
            age: Duration(milliseconds: 100),
          ),
        ],
      );

      input.add(snapshot('strap-a', 1000, 1));
      input.add(snapshot('strap-a', 2000, 1, ageMs: 1100)); // same measurement
      input.add(snapshot('strap-b', 3000, 1));
      input.add(snapshot('strap-b', 3000, 1));
      input.add(snapshot('strap-b', 4000, 2));
      await Future<void>.delayed(Duration.zero);
      expect(samples.map((s) => [s.sourceId, s.value, s.epoch]), [
        ['strap-a', 120.0, 1],
        ['strap-b', 130.0, 1],
        ['strap-b', 130.0, 2],
      ]);
      await input.close();
    },
  );

  test(
    'BLE-only adapter reads one device and treats reconnect as a new epoch',
    () async {
      final input = StreamController<SensorSnapshot>();
      final values = <CounterReading>[];
      BleCounterSource(
        snapshots: input.stream,
        deviceId: 'rower',
        metric: SportMetric.totalDistance,
        sourceId: 'rower',
      ).readings.listen(values.add);

      SensorSnapshot snapshot(int epoch, double value) => SensorSnapshot(
        values: const {},
        devices: const [],
        updatedAtMs: 1000,
        deviceValues: [
          DeviceValue(
            deviceId: 'rower',
            epoch: epoch,
            metric: SportMetric.totalDistance,
            value: value,
            kind: MetricKind.cumulative,
            age: Duration.zero,
          ),
        ],
      );

      input.add(snapshot(1, 100));
      input.add(snapshot(1, 110));
      input.add(snapshot(2, 2));
      await Future<void>.delayed(Duration.zero);
      expect(values.map((v) => [v.value, v.epoch]), [
        [100, 1],
        [110, 1],
        [2, 2],
      ]);
      await input.close();
    },
  );
}
