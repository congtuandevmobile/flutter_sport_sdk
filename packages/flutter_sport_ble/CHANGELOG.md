## Unreleased

* Fix: `PigeonSportBlePlatform()` is one shared instance per engine, so a second `SportBle` no longer silences the first.

## 0.0.1-beta (second pass)

* **Readiness.** New connection states `discovering`, `subscribing`, `ready`, `notSupported` (replace `connected`). A device is `ready`
  only when a workout measurement is really subscribed; a failed subscription is reported, not skipped.
* **Scan.** `startScan(allDevices: true)` scans every BLE device; the default scan takes its services from the protocol registry.
* **Protocols.** Cycling Speed and Cadence (cadence, wheel revolutions, speed with a wheel circumference), Cycling Power, Fitness
  Machine data (treadmill, cross trainer, step and stair climber, rower, indoor bike), Battery, Device Information, heart rate R-R
  intervals. New metrics: `cyclingCadence`, `powerWatts`, `cyclingSpeed`, `incline`, `energyKcal`, `strokeRate`, `strokeCount`,
  `wheelRevolutions`, `stepRate`, `floors`. `DeviceState` has the discovered services, the subscribed characteristics, the battery,
  the device information and the R-R intervals. Written from the specification: no device capture yet.
* **Source policy.** Rank by device kind (strap before machine, power meter before cadence sensor), with the user's choice first.
* **Fix.** The Android manifest no longer declares `ACCESS_FINE_LOCATION` (with a `maxSdkVersion` it capped the GPS plugin's one in the
  merged manifest). Stale callbacks of an older link are dropped on iOS and Android.
* Tests: 65 core, 27 Android, 27 iOS, 6 Dart.

## 0.0.1-beta

First version. Not tested with a real device.

* `SportBle`: scan, connect several devices at once, `snapshots` (one resolved value per metric, `null` when unknown), `devices`,
  `rawPackets`, `setPreferredSource`, `adapterState`.
* Shared Kotlin core `sensor-core` (inside the package): Heart Rate and Running Speed and Cadence parsers, GATT number helpers, `MetricResolver`
  (per metric, freshness, recovery hysteresis, epochs, preference) and `SensorHub`.
* Android: `AndroidBleTransport` (one `BluetoothGatt` per device, serialised descriptor writes) and `SportBleEngine`.
  iOS: `CoreBluetoothTransport` (manager created on first use, so the permission prompt is not shown at launch) and `SportBleEngine`.
* Cycling Speed and Cadence packets are forwarded raw (`rawPackets`), not decoded.
* No automatic reconnect, no background keep-alive.
