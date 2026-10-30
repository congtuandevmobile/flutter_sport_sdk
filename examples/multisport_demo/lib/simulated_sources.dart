import 'dart:async';
import 'dart:math';

import 'package:flutter_multisport/flutter_multisport.dart';

/// A GPS that counts a total, like the real one: it keeps counting across stages and the challenge makes each stage's distance out of it.
class SimulatedGps implements ProgressSource {
  @override
  final String sourceId = 'gps';

  final _controller = StreamController<CounterReading>.broadcast();
  Timer? _timer;
  double _total = 5000; // a recording that already had a total before the challenge

  bool get running => _timer != null;

  @override
  Stream<CounterReading> get readings => _controller.stream;

  void start({double metersPerSecond = 3}) {
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      _total += metersPerSecond;
      _controller.add(CounterReading(value: _total));
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}

/// A heart-rate strap that gives a sample every second.
class SimulatedHeartRate implements TelemetrySource {
  final _controller = StreamController<TelemetrySample>.broadcast();
  final _random = Random();
  Timer? _timer;

  bool get running => _timer != null;

  @override
  Stream<TelemetrySample> get samples => _controller.stream;

  void start() {
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      _controller.add(
        TelemetrySample(metric: TelemetryMetric.heartRate, value: 135 + _random.nextInt(30).toDouble(), at: DateTime.now(), sourceId: 'strap'),
      );
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
