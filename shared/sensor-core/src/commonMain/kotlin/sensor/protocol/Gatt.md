# Gatt.kt

**Path:** `.../sensor/protocol/Gatt.kt` · **Layer:** protocol

The 16-bit Bluetooth SIG numbers the package knows (heart rate 180d/2a37, running speed and cadence 1814/2a53, cycling speed and cadence 1816/2a5b, cycling power, fitness machine, battery, device information). `short(uuid)` turns a 128-bit SIG-base UUID, `0x2A37` or `2A37` into `2a37`. `capabilities(services)` maps services to `Capability` (unknown services add nothing). `measurementCharacteristics(service)` lists the measurements to subscribe to.
