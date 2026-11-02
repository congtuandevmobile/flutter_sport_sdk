import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tracking_gps/src/platform/pigeon_tracking_platform.dart';
import 'package:flutter_tracking_gps/src/platform/tracking_api.g.dart';

void main() {
  NativeFix nativeFix({double? altitude}) => NativeFix(
    sessionId: 'session',
    segmentId: 0,
    seq: 1,
    timeMs: 1_700_000_000_000,
    elapsedMs: 1234,
    latitude: 10,
    longitude: 106,
    horizontalAccuracy: 5,
    speed: -1,
    speedAccuracy: -1,
    course: -1,
    altitude: altitude,
    verticalAccuracy: altitude == null ? -1 : 3,
    provider: 'gps',
    isMock: false,
  );

  test('missing native altitude stays null in the domain fix', () async {
    final platform = PigeonTrackingPlatform(
      fixSource: () => Stream.value(nativeFix()),
    );

    final fix = await platform.fixes.first;

    expect(fix.altitude, isNull);
  });

  test('zero and negative measured altitudes are preserved', () async {
    for (final altitude in <double>[0, -430]) {
      final platform = PigeonTrackingPlatform(
        fixSource: () => Stream.value(nativeFix(altitude: altitude)),
      );

      final fix = await platform.fixes.first;

      expect(fix.altitude, altitude);
    }
  });
}
