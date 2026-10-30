# flutter_sport_sdk (monorepo)

A family of generic Flutter SDKs for sport apps. Every package here is independent of any application: no README, doc, code
comment or config may name an app or an app-specific class.

## Layout and direction of dependencies

```
packages/flutter_tracking_gps   GPS recording; owns tracking-core/ (Kotlin Multiplatform, pure); knows nothing about Bluetooth
packages/flutter_sport_ble      Bluetooth LE transport (Android/iOS native); owns sensor-core/ (parsers, per-metric resolver, SensorHub)
packages/flutter_workout        a workout session (native, journal on disk); owns workout-core/ (session, distance ledger, journal)
packages/flutter_challenge      a challenge session (native, own journal); owns challenge-core/ (event-sourced stages, journal, recovery)
packages/flutter_activity       records ONE activity from sources: history of HR/cadence/speed/distance, summary (pure Dart; knows neither GPS nor BLE)
packages/flutter_multisport     sports/goals catalog, coordinator, per-stage results (pure Dart; depends on flutter_challenge and flutter_activity)
packages/flutter_tracking_gps_adapter  optional GPS sources for flutter_activity / flutter_multisport (depends on gps and activity)
packages/flutter_sport_ble_adapter     optional BLE sources for flutter_activity / flutter_multisport (depends on ble and activity)
packages/flutter_multisport_adapters   compatibility export of both optional adapter packages
examples/sensors_demo           one app with the plugins (a link/launch check)
examples/multisport_demo        create and run a multisport challenge with simulated sensors
```

Every package OWNS its core (`<name>-core/` inside the package) so it can be packaged, versioned, tested and released alone. A core
never imports another product's core; products meet only in the app or in an optional adapter package above them.

- Dependencies only point DOWN: a package never imports one above it, and `flutter_tracking_gps` and `flutter_sport_ble` never
  import each other. A future package that needs both (workouts) depends on both.
- Dart: a pub workspace (root `pubspec.yaml`). Every package has `resolution: workspace`; the sibling packages are found by
  name. Run `flutter pub get` at the root.
- Android: a plugin compiles the common Kotlin it needs straight into itself (`java.srcDirs("../sensor-core/src/commonMain/kotlin")`).
  iOS: each plugin vendors its OWN static XCFramework (`tool/build_core.sh`). Two plugins therefore carry two Kotlin/Native
  runtimes; this was linked and launched in `examples/sensors_demo`, but never put two cores in ONE framework or let a Kotlin
  object cross from one framework to the other.
- A workout session is NOT a Bluetooth connection: `workout-core` owns the session; sensors only feed it. A distance is credited only
  as a DIFFERENCE from a baseline and from ONE source at a time; a total of a device is never assigned to the workout. Never fake a
  GPS fix to carry a footpod distance.
- The workout journal rule: every event is appended to disk (synced) BEFORE the snapshot that shows its effect is published; a failed
  write is reported and sticky, never hidden; a workout that cannot write its first line is not started.
- Algorithms live once, in a Kotlin core with a test in `commonTest`; never re-implement one in Swift, Kotlin-Android or Dart.
- Native code collects and forwards; it never decides a value. The decision (decode, validate, choose the source) is in the core.
- Every time a core sees (`nowMs`, `atMs`) comes from ONE monotonic clock of the phone, never from a device or the wall clock.
- Pigeon: edit `pigeons/*.dart`, then `dart run pigeon --input pigeons/<file>.dart` in that package. Never edit `*.g.*`.
- Every Swift and Kotlin file has an English `.md` next to it with the same base name (purpose, API, rules, limits).
- Every threshold is an unmeasured starting value; say so when you change one.
- Do not commit or push without the owner's approval.

## Checks that must stay green
- `tool/check_merged_manifest.sh`: the merged Android manifest of an app with both plugins keeps `ACCESS_FINE_LOCATION` uncapped.
  A permission declared by two plugins is merged by NAME, so a `maxSdkVersion` on one caps the other: a plugin must not declare a
  permission another plugin needs unless it declares it identically.
- Native engines map the core's enums to the Pigeon enums by order/name: each engine test suite has a test that fails on drift.

## Releases
One tag per package: `<package>-v<version>` (for example `flutter_sport_ble-v0.0.1-beta`). `flutter_tracking_gps` still has its own
release workflow from its original repository (`.github/workflows/release.yml` there); it has NOT been moved here.
