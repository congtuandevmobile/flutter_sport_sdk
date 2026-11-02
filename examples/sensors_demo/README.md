# sensors_demo

Reference host app that links GPS, BLE, workout and challenge. On the first screen, open **Real sport flow** to try:

- GPS-only activity recording, with optional multiple BLE devices for live heart rate and cadence.
- A run → manually measured swim → strength-duration challenge, with a next-stage button and haptic stage-completion signal.
- Local activity and per-stage history after completion or restart, including heart-rate charts, cadence sample counts and saved GPS route fixes.

`lib/real_sport_flow.dart` is app-owned glue: it handles permission requests, session IDs, file location, device/source attachment, restore, and history. `lib/real_flow_screen.dart` is a small reference UI with both a quick three-stage preset and a form to add custom sport profiles and stages. The form builds a `SportPlan` from those choices. The SDK packages do not depend on this app.

Swimming distance in this example is entered by hand. A supported external counter can be attached through `attachDeviceCounter`, or the host can implement `ProgressSource`/`TelemetrySource` for another device. Unknown BLE packet formats cannot be decoded without a parser for the device's protocol.

Run `flutter test`, then `flutter run` on Android or iOS. Simulator and unit tests do not establish GPS accuracy or BLE hardware compatibility.
