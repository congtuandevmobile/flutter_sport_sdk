import 'dart:async';

import 'package:flutter_activity/flutter_activity.dart';
import 'package:flutter_challenge/flutter_challenge.dart';
import 'package:flutter_multisport/flutter_multisport.dart' as multisport;
import 'package:flutter_multisport/testing.dart';
import 'package:flutter_sport_ble/flutter_sport_ble.dart';
import 'package:flutter_sport_ble_adapter/flutter_sport_ble_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tracking_gps/flutter_tracking_gps.dart';
import 'package:flutter_tracking_gps_adapter/flutter_tracking_gps_adapter.dart';

void main() {
  test(
    'one GPS and selected BLE stream feed activity history and stage history',
    () async {
      var now = DateTime(2026, 1, 1, 10);
      final gps = StreamController<TrackingSnapshot>.broadcast();
      final ble = StreamController<SensorSnapshot>.broadcast();
      final progress = GpsProgressSource(gps.stream, clock: () => now);
      final selectedBle = ResolvedBleTelemetrySource(
        snapshots: ble.stream,
        clock: () => now,
      );
      final store = MemoryTelemetryStore();
      final activity = await ActivityRecorder.begin(
        store,
        'activity',
        activityType: 'running',
        distanceSource: 'gps',
        clock: () => now,
      );
      activity.attachDistance(progress);
      activity.attachTelemetry(selectedBle);

      final native = FakeChallengePlatform();
      final coordinator = multisport.ChallengeCoordinator(
        challenge: FlutterChallenge(platform: native),
        store: store,
        clock: () => now,
      );
      coordinator.attachProgress(progress);
      coordinator.attachTelemetry(selectedBle);
      await coordinator.start(
        sessionId: 'challenge',
        stages: const [
          multisport.SportStageConfig(
            id: 'run',
            sport: multisport.SportType.running,
            goal: multisport.SportGoal.distanceMeters(20),
          ),
          multisport.SportStageConfig(
            id: 'swim',
            sport: multisport.SportType.swimming,
            goal: multisport.SportGoal.distanceMeters(200),
            completion: multisport.StageCompletion.manualOnly,
          ),
          multisport.SportStageConfig(
            id: 'strength',
            sport: multisport.SportType.strength,
            goal: multisport.SportGoal.repetitions(10),
          ),
        ],
      );

      TrackingSnapshot fix(double metres) => TrackingSnapshot(
        sessionId: 'phone-gps',
        state: RecordingState.running,
        quality: GpsQuality.good,
        totalMeters: metres,
        gpsMeters: metres,
        gapBridgeMeters: 0,
        pdrMeters: 0,
        pendingPdrMeters: 0,
        segmentId: 0,
        fixCount: metres.round(),
        lastFixAt: now,
      );
      gps.add(fix(0));
      now = now.add(const Duration(seconds: 1));
      gps.add(fix(20));
      ble.add(
        SensorSnapshot(
          values: const {
            SportMetric.heartRate: SensorValue(
              metric: SportMetric.heartRate,
              value: 130,
              sourceId: 'strap-b',
              kind: MetricKind.instantaneous,
              age: Duration.zero,
            ),
          },
          devices: const [
            DeviceState(
              id: 'strap-b',
              connection: BleConnectionState.ready,
              epoch: 1,
              capabilities: [SensorCapability.heartRate],
            ),
          ],
          updatedAtMs: 1000,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      await activity.flush();
      await coordinator.flushTelemetry();
      expect(activity.summary().distanceMeters, 20);
      expect(activity.summary().averageHeartRate, 130);
      expect(coordinator.currentResult?.averageHeartRate, 130);
      expect(native.counters, isNotEmpty);

      native.completeStage();
      await Future<void>.delayed(Duration.zero);
      await coordinator.nextStage();
      await coordinator.addProgress(200, eventId: 'pool-lengths');
      expect(native.deltas.single, startsWith('manual:200.0:'));
      native.completeStage(evidence: CompletionEvidence.manual);
      await Future<void>.delayed(Duration.zero);
      await coordinator.nextStage();
      native.completeStage(evidence: CompletionEvidence.manual);
      await Future<void>.delayed(Duration.zero);
      expect(coordinator.results.length, 3);
      expect(
        coordinator.stageSamples(0, TelemetryMetric.heartRate).single.value,
        130,
      );
      expect(coordinator.stageSamples(1, TelemetryMetric.heartRate), isEmpty);

      await activity.finish();
      await coordinator.dispose();
      await gps.close();
      await ble.close();
    },
  );
}
