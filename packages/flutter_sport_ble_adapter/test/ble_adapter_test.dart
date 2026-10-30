import 'dart:async';

import 'package:flutter_activity/flutter_activity.dart';
import 'package:flutter_sport_ble/flutter_sport_ble.dart';
import 'package:flutter_sport_ble_adapter/flutter_sport_ble_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
