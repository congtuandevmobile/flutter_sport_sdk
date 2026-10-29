# flutter_sport_sdk

Generic Flutter SDKs for sport apps, in one workspace.

| Package | What it does | State |
|---|---|---|
| [`flutter_tracking_gps`](packages/flutter_tracking_gps) | GPS recording with a shared Kotlin distance core | copied from its own repository, unchanged except `resolution: workspace` |
| [`shared/workout-core`](shared/workout-core) | Kotlin core of a workout: session state machine, distance ledger (no double counting across pause, reconnect, source switch), durable journal with CRC and idempotent replay | new, not wired to a plugin yet |
| [`flutter_workout`](packages/flutter_workout) | A workout session on top of `workout-core`: one distance, a journal on disk that is written before it is shown, restore after the process dies | new, beta, not fed by the sensor plugins by itself |
| [`flutter_sport_ble`](packages/flutter_sport_ble) | Bluetooth LE sport sensors: several devices at once, one resolved value per metric | new, beta |
| [`shared/sensor-core`](shared/sensor-core) | Kotlin core of the sensors: protocol registry and adapters (heart rate, running and cycling speed/cadence, cycling power, fitness machines, battery, device information), per-metric resolver with a source policy | new |

```
flutter pub get                                            # at the root: resolves the workspace
(cd shared/sensor-core && ./gradlew jvmTest)               # core tests
(cd shared/workout-core && ./gradlew jvmTest)              # workout core tests
(cd packages/flutter_sport_ble && flutter test)            # Dart tests
(cd packages/flutter_workout && flutter test)
(cd packages/flutter_sport_ble/example/android && ./gradlew :flutter_sport_ble:testDebugUnitTest)
packages/flutter_sport_ble/tool/build_core.sh debug        # iOS framework, then the iOS tests in packages/flutter_sport_ble/example/ios
packages/flutter_workout/tool/build_core.sh debug          # same for the workout plugin
```

See [CLAUDE.md](CLAUDE.md) for the rules of the repository.

Continuous integration lives in `.github/workflows/` (sensor core, Flutter packages, Android and iOS native tests, the two-plugin
integration check). They were written here and have not run on GitHub yet.

Where things stand: [doc/COMPATIBILITY.yaml](doc/COMPATIBILITY.yaml) (candidate devices, nothing verified) and
[fixtures/README.md](fixtures/README.md).
