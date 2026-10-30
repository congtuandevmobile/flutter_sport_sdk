# multisport_demo

Create a multisport challenge (a sport and a goal per stage), run it, read the result of every stage.

The sensors are SIMULATED (a GPS that counts 3 m/s, a heart-rate strap), so it runs without hardware. The native side is the real `flutter_challenge` plugin. A real app attaches the sources of `flutter_multisport_adapters` and a `FileTelemetryStore` instead.

```
flutter run          # in this folder, on a device or a simulator
flutter test         # widget tests with a fake native side
```

Try: Running 1 km -> Football 1 minute -> Cycling 2 km, switch the simulated GPS on, and watch the stages complete.
