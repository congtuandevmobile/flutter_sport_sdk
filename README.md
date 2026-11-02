# flutter_sport_sdk

Generic Flutter SDKs for sport apps, in one workspace.

Start with [the source summary](doc/SOURCE_SUMMARY.md) for the package map, composition examples, current limits and next steps. [SDK rules](doc/SDK_RULES.md) and [AGENTS.md](AGENTS.md) capture the boundaries to preserve when extending the repository.

| Package | What it does | State |
|---|---|---|
| [`flutter_tracking_gps`](packages/flutter_tracking_gps) | GPS recording with a shared Kotlin distance core | copied from its own repository, unchanged except `resolution: workspace` |
| [`packages/flutter_workout/workout-core`](packages/flutter_workout/workout-core) | Kotlin core of a workout: session state machine, distance ledger (no double counting across pause, reconnect, source switch), durable journal with CRC and idempotent replay | used by `flutter_workout` |
| [`flutter_workout`](packages/flutter_workout) | A workout session on top of `workout-core`: one distance, a journal on disk that is written before it is shown, restore after the process dies | new, beta, not fed by the sensor plugins by itself |
| [`packages/flutter_challenge/challenge-core`](packages/flutter_challenge/challenge-core) | Kotlin core of a multi-stage challenge: event-sourced engine, stage counters, journal with CRC and recovery | new |
| [`flutter_challenge`](packages/flutter_challenge) | A challenge session (Android/iOS native, journal on disk) on top of `challenge-core`; works without Bluetooth | new, beta, used by `multisport_demo` |
| [`flutter_activity`](packages/flutter_activity) | Record one activity from the sensors (heart rate, cadence, speed, distance with the time each was measured), keep the history durably, summarise it (averages, pace, how much each sensor covered). Pure Dart | new, beta, not tested with real devices |
| [`flutter_multisport`](packages/flutter_multisport) | Multisport challenges above `flutter_challenge`: runtime sport profiles and a saved `SportPlan`, stage coordination, telemetry and results. Pure Dart | new, beta, not tested with real sensors |
| [`flutter_tracking_gps_adapter`](packages/flutter_tracking_gps_adapter) | Optional GPS source for `flutter_activity` or `flutter_multisport`; no BLE dependency | new, beta |
| [`flutter_sport_ble_adapter`](packages/flutter_sport_ble_adapter) | Optional per-device counter and resolver-selected BLE telemetry for `flutter_activity` or `flutter_multisport`; no GPS dependency | new, beta |
| [`flutter_multisport_adapters`](packages/flutter_multisport_adapters) | Compatibility bundle exporting both optional adapters | new, beta |
| [`flutter_sport_ble`](packages/flutter_sport_ble) | Bluetooth LE sport sensors: several devices at once, one resolved value per metric | new, beta |
| [`packages/flutter_sport_ble/sensor-core`](packages/flutter_sport_ble/sensor-core) | Kotlin core of the sensors: protocol registry and adapters (heart rate, running and cycling speed/cadence, cycling power, fitness machines, battery, device information), per-metric resolver with a source policy | new |

```
flutter pub get                                            # at the root: resolves the workspace
(cd packages/flutter_sport_ble/sensor-core && ./gradlew jvmTest)               # core tests
(cd packages/flutter_workout/workout-core && ./gradlew jvmTest)              # workout core tests
(cd packages/flutter_sport_ble && flutter test)            # Dart tests
(cd packages/flutter_workout && flutter test)
(cd packages/flutter_challenge/challenge-core && ./gradlew jvmTest)          # challenge core tests
(cd packages/flutter_challenge && flutter test)
(cd packages/flutter_sport_ble/example/android && ./gradlew :flutter_sport_ble:testDebugUnitTest)
packages/flutter_sport_ble/tool/build_core.sh debug        # iOS framework, then the iOS tests in packages/flutter_sport_ble/example/ios
packages/flutter_workout/tool/build_core.sh debug          # same for the workout plugin
```

See [CLAUDE.md](CLAUDE.md) for the rules of the repository.

The [sensors demo](examples/sensors_demo) has a reference host flow for GPS activity, optional BLE telemetry, a run → manual swim → strength challenge, and saved history. It is an integration example; physical GPS/BLE behavior still needs device testing.

Continuous integration lives in `.github/workflows/` (sensor core, Flutter packages, Android and iOS native tests, the two-plugin
integration check). They were written here and have not run on GitHub yet.

Where things stand: [doc/COMPATIBILITY.yaml](doc/COMPATIBILITY.yaml) (candidate devices, nothing verified) and
[fixtures/README.md](fixtures/README.md).

## Independence rule and release check
Every package owns its core and must build alone. `tool/release_check.sh <package> [android|ios|both]` builds the release XCFramework, packages the SDK
(respecting its `.pubignore`, which ships `ios/Frameworks`), extracts it into an empty directory, creates a fresh Flutter app that depends on that
package only, and builds it. Run it before every release; the `release-check` workflow does the same per package.
