# flutter_sport_ble

Bluetooth LE sport sensors for Flutter. It connects **several devices at once** (a heart rate strap, a running footpod, a cycling
sensor), decodes what they send in a shared Kotlin core, and publishes **one resolved value per metric**. Nothing in Flutter ever
sees a byte of a packet.

> Beta. Not yet tested with a real device or a real radio: the decoding, the choice of source and the connection bookkeeping are
> covered by tests with a fake radio; the Android and iOS radio code compiles and is reviewed but has never talked to a sensor.

## What it does

```dart
final ble = SportBle();
await ble.startScan();                       // heart rate, running and cycling speed/cadence devices
ble.devices.listen((d) => print(d));          // show them, let the user pick
await ble.connect(deviceId);                  // several at once
ble.snapshots.listen((s) {                    // about once per second and on every connection change
  print('${s.heartRateBpm} bpm, ${s.runningCadencePerMin} /min, ${s.runningSpeedMps} m/s');
});
```

`SensorSnapshot` has ONE value per metric that has a healthy source; a metric without one is `null`, never 0 (a measured 0 is
a value). Each value says which device it came from (`sourceId`), its `kind` and its `age`.

## Rules the core applies

- **Decoding.** Heart Rate Measurement (0x2A37): 8 or 16 bit value, sensor contact (no contact = no value), energy, R-R intervals
  (kept per device: `DeviceState.recentRrMs`). Running Speed and Cadence (0x2A53). Cycling Speed and Cadence (0x2A5B): the crank gives
  `cyclingCadence` (0 when verified still), the wheel gives the `wheelRevolutions` counter and, after `setWheelCircumference`,
  `cyclingSpeed`; the raw packet also comes out of `rawPackets`. Cycling Power (0x2A63): power, plus the crank cadence when the meter
  sends crank data. Fitness Machine data (treadmill, cross trainer, step and stair climber, rower, indoor bike): speed, cadence,
  power, distance, incline, energy, stroke rate and count, step rate, floors, heart rate. Battery level and Device Information
  (manufacturer, model, firmware) are read once per device. A truncated packet is rejected whole.
- **Readiness.** A device goes `connecting`, `discovering`, `subscribing`, then `ready` (at least one workout measurement is
  subscribed) or `notSupported` (the link works but nothing usable could be subscribed: the connect call fails with
  `NOT_SUPPORTED`). `connected` alone never meant "gives metrics", so there is no such state. A characteristic that could not be
  subscribed is reported (`DeviceState.error`, `PARTIAL:`), never skipped silently.
- **Scanning.** `startScan()` filters by the services of the registry. A device may not advertise them: `startScan(allDevices: true)`
  scans every BLE device for a short time, and what a device can do is only known after connecting. Android's `neverForLocation`
  flag can hide some beacons, so not finding a device is not proof that it is unsupported.
- **Per-metric source.** A device is a candidate for a metric while it is `ready`, its value is fresh (5 s) and it has delivered two
  valid values over at least 1 s since its (re)connect or its last gap. Choice: the source the user prefers (`setPreferredSource`),
  else the best ranked by what the device is (a heart rate strap before a machine's heart rate, a power meter's cadence before a
  cadence sensor's before a trainer's), else among equals the one already chosen, else the first connected. A better ranked source
  that becomes healthy takes over once, never back and forth. Values are never averaged or summed.
- **Epochs.** Every connect to a device gets a new `epoch`; data of an older one is dropped, so a reset sensor's counters are never
  compared with the old ones.
- **Cumulative values** (`totalDistance`, a counter of the DEVICE) are published as such. Turning them into a workout distance
  needs deltas per connection, a pause policy and a source choice: that is a separate layer, not done here.

## What the host app does

- **Permissions.** Android 12+: request *Nearby devices* (`BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`); the manifest declares them with
  `neverForLocation`. Android 11 and older: the host declares and requests a location permission (this package does not declare
  one: a plugin that declared it with a `maxSdkVersion` would cap the location permission of any other plugin in the merged
  manifest; `tool/check_merged_manifest.sh` in the repository checks it). iOS: add `NSBluetoothAlwaysUsageDescription` to Info.plist; the prompt appears
  when the app first scans or connects, never at launch. Without permission `adapterState()` says `unauthorized` and nothing throws.
- **Reconnecting.** This version never reconnects by itself, and the links end with the Flutter engine. Keeping a link alive in the
  background (an Android foreground service, iOS state restoration) and after the process dies is not built.

## Not built yet

The Fitness Machine control point (read-only for now), the Physical Activity Monitor, health devices (scale, SpO2, environment),
indoor distance and every workout rule (that is a separate layer), recording of the samples, a native runtime that outlives the
Flutter engine, automatic reconnect, watches and health platforms. Nothing was captured from a real device: see
`doc/COMPATIBILITY.yaml` for the candidates and `fixtures/README.md`.

Package layout and the rules of the repository: see the root `CLAUDE.md`.
