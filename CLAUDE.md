# flutter_sport_sdk (monorepo)

A family of generic Flutter SDKs for sport apps. Every package here is independent of any application: no README, doc, code
comment or config may name an app or an app-specific class.

## Layout and direction of dependencies

```
shared/sensor-core            Kotlin Multiplatform, pure: models, GATT numbers, parsers, per-metric resolver, SensorHub
packages/flutter_tracking_gps GPS recording (own KMP core in its tracking-core/); knows nothing about Bluetooth
packages/flutter_sport_ble    Bluetooth LE transport (Android/iOS native) on top of shared/sensor-core
examples/sensors_demo         one app with both plugins (a link/launch check)
```

- Dependencies only point DOWN: a package never imports one above it, and `flutter_tracking_gps` and `flutter_sport_ble` never
  import each other. A future package that needs both (workouts) depends on both.
- Dart: a pub workspace (root `pubspec.yaml`). Every package has `resolution: workspace`; the sibling packages are found by
  name. Run `flutter pub get` at the root.
- Android: a plugin compiles the common Kotlin it needs straight into itself (`java.srcDirs("../../../shared/sensor-core/...")`).
  iOS: each plugin vendors its OWN static XCFramework (`tool/build_core.sh`). Two plugins therefore carry two Kotlin/Native
  runtimes; this was linked and launched in `examples/sensors_demo`, but never put two cores in ONE framework or let a Kotlin
  object cross from one framework to the other.
- Algorithms live once, in a Kotlin core with a test in `commonTest`; never re-implement one in Swift, Kotlin-Android or Dart.
- Native code collects and forwards; it never decides a value. The decision (decode, validate, choose the source) is in the core.
- Every time a core sees (`nowMs`, `atMs`) comes from ONE monotonic clock of the phone, never from a device or the wall clock.
- Pigeon: edit `pigeons/*.dart`, then `dart run pigeon --input pigeons/<file>.dart` in that package. Never edit `*.g.*`.
- Every Swift and Kotlin file has an English `.md` next to it with the same base name (purpose, API, rules, limits).
- Every threshold is an unmeasured starting value; say so when you change one.
- Do not commit or push without the owner's approval.

## Releases
One tag per package: `<package>-v<version>` (for example `flutter_sport_ble-v0.0.1-beta`). `flutter_tracking_gps` still has its own
release workflow from its original repository (`.github/workflows/release.yml` there); it has NOT been moved here.
