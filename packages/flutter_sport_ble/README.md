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

- **Decoding.** Heart Rate Measurement (0x2A37): 8 or 16 bit value, sensor contact (no contact = no value), energy, R-R. Running
  Speed and Cadence (0x2A53): speed (1/256 m/s), cadence, optional stride length and total distance. A truncated packet is rejected
  whole. The Cycling Speed and Cadence Measurement (0x2A5B) is **not decoded here**: its bytes come out of `rawPackets` for whoever
  decodes it.
- **Per-metric source.** A device is a candidate for a metric while it is connected, its value is fresh (5 s) and it has delivered two
  valid values over at least 1 s since its (re)connect or its last gap. The source already chosen stays while it is healthy, else
  the one the user prefers (`setPreferredSource`), else the one that connected first. Values are never averaged or summed.
- **Epochs.** Every connect to a device gets a new `epoch`; data of an older one is dropped, so a reset sensor's counters are never
  compared with the old ones.
- **Cumulative values** (`totalDistance`, a counter of the DEVICE) are published as such. Turning them into a workout distance
  needs deltas per connection, a pause policy and a source choice: that is a separate layer, not done here.

## What the host app does

- **Permissions.** Android 12+: request *Nearby devices* (`BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`); the manifest declares them with
  `neverForLocation`. Android 11 and older: location. iOS: add `NSBluetoothAlwaysUsageDescription` to Info.plist; the prompt appears
  when the app first scans or connects, never at launch. Without permission `adapterState()` says `unauthorized` and nothing throws.
- **Reconnecting.** This version never reconnects by itself, and the links end with the Flutter engine. Keeping a link alive in the
  background (an Android foreground service, iOS state restoration) and after the process dies is not built.

## Not built yet

Fitness Machine (treadmills, bikes, rowers), Cycling Power, the Physical Activity Monitor, battery level and device information
values, heart rate R-R intervals in the snapshot, indoor distance, recording of the samples, watches and health platforms.

Package layout and the rules of the repository: see the root `CLAUDE.md`.
