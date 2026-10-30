import 'package:flutter_multisport/flutter_multisport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime(2026, 1, 1, 10);
  const stage = SportStageConfig(
    id: 'run',
    sport: SportType.running,
    goal: SportGoal.distanceMeters(1000),
  );

  test(
    'late telemetry does not move a restored stage behind its resume',
    () async {
      final store = MemoryTelemetryStore();
      var now = start;
      final recorder = await StageTelemetryRecorder.begin(
        store,
        'late',
        clock: () => now,
      );
      recorder.markStageStarted(0, stage, start);
      recorder.markPaused(start.add(const Duration(seconds: 10)));
      recorder.markResumed(start.add(const Duration(seconds: 20)));
      now = start.add(const Duration(seconds: 25));
      recorder.record(
        TelemetrySample(
          metric: TelemetryMetric.heartRate,
          value: 140,
          at: start.add(const Duration(seconds: 5)),
          sourceId: 'strap',
        ),
      );
      await recorder.flush();

      final back = await StageTelemetryRecorder.restore(
        store,
        'late',
        clock: () => now,
      );
      expect(back.resultFor(0).activeDuration, const Duration(seconds: 10));
      expect(back.samplesOf(0, TelemetryMetric.heartRate).single.value, 140);
      expect(back.series(0, TelemetryMetric.heartRate).single.value, 140);
      expect(back.restoreStatus, RecordingRestoreStatus.intact);
    },
  );

  test(
    'invalid middle record is reported and repaired before more telemetry is appended',
    () async {
      final store = MemoryTelemetryStore();
      var now = start;
      final recorder = await StageTelemetryRecorder.begin(
        store,
        'damaged',
        clock: () => now,
      );
      recorder.markStageStarted(0, stage, start);
      for (final second in [5, 10, 15]) {
        now = start.add(Duration(seconds: second));
        recorder.record(
          TelemetrySample(
            metric: TelemetryMetric.heartRate,
            value: 100 + second.toDouble(),
            at: now,
            sourceId: 'strap',
          ),
        );
      }
      await recorder.flush();
      store.lines['damaged']![2] =
          '{"k":"s","i":0,"m":"heartRate","v":"broken","t":1000}';

      final back = await StageTelemetryRecorder.restore(
        store,
        'damaged',
        clock: () => now,
      );
      expect(back.restoreStatus, RecordingRestoreStatus.partial);
      expect(back.samplesOf(0, TelemetryMetric.heartRate).length, 1);
      expect(store.damaged['damaged'], isNotEmpty);
    },
  );
}
