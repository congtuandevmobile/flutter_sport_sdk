# flutter_sport_sdk

Generic Flutter SDKs for sport apps, in one workspace.

| Package | What it does | State |
|---|---|---|
| [`flutter_tracking_gps`](packages/flutter_tracking_gps) | GPS recording with a shared Kotlin distance core | copied from its own repository, unchanged except `resolution: workspace` |
| [`flutter_sport_ble`](packages/flutter_sport_ble) | Bluetooth LE sport sensors: several devices at once, one resolved value per metric | new, beta |
| [`shared/sensor-core`](shared/sensor-core) | Kotlin core of the sensors: GATT numbers, heart rate and running speed/cadence parsers, per-metric resolver | new |

```
flutter pub get                                            # at the root: resolves the workspace
(cd shared/sensor-core && ./gradlew jvmTest)               # core tests
(cd packages/flutter_sport_ble && flutter test)            # Dart tests
(cd packages/flutter_sport_ble/example/android && ./gradlew :flutter_sport_ble:testDebugUnitTest)
packages/flutter_sport_ble/tool/build_core.sh debug        # iOS framework, then the iOS tests in packages/flutter_sport_ble/example/ios
```

See [CLAUDE.md](CLAUDE.md) for the rules of the repository.
