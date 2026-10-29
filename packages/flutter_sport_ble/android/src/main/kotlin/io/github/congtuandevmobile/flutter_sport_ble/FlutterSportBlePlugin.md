# FlutterSportBlePlugin.kt

**Path:** `android/.../FlutterSportBlePlugin.kt` · **Layer:** Flutter entry point

Thin: creates the `SportBleEngine` with an `AndroidBleTransport` and forwards the Pigeon host API to it; the engine's events go to Flutter on the main thread. Connect failures become a `FlutterError` whose code is the stable prefix of the message. The links end when the plugin detaches from the engine.
