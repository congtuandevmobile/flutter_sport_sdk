import 'dart:async';

import 'package:flutter_activity/flutter_activity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tracking_gps/flutter_tracking_gps.dart';
import 'package:flutter_tracking_gps_adapter/flutter_tracking_gps_adapter.dart';

TrackingSnapshot snapshot(double meters, String sessionId) => TrackingSnapshot(
  state: RecordingState.running,
  quality: GpsQuality.good,
  totalMeters: meters,
  gpsMeters: meters,
  gapBridgeMeters: 0,
  pdrMeters: 0,
  pendingPdrMeters: 0,
  segmentId: 1,
  fixCount: 1,
  sessionId: sessionId,
);

void main() {
  test(
    'GPS-only adapter sends changed totals and new recording epochs',
    () async {
      final input = StreamController<TrackingSnapshot>();
      final values = <CounterReading>[];
      GpsProgressSource(input.stream).readings.listen(values.add);
      input.add(snapshot(0, 'first'));
      input.add(snapshot(10, 'first'));
      input.add(snapshot(10, 'first'));
      input.add(snapshot(2, 'second'));
      await Future<void>.delayed(Duration.zero);
      expect(values.map((v) => [v.value, v.epoch]), [
        [0, 1],
        [10, 1],
        [2, 2],
      ]);
      await input.close();
    },
  );
}
