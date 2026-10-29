# Gatt.kt

**Path:** `.../sensor/protocol/Gatt.kt` · **Layer:** protocol

The 16-bit Bluetooth SIG numbers the package knows (services and characteristics of heart rate, running and cycling speed and cadence, cycling power, fitness machine, battery, device information). `short(uuid)` turns a 128-bit SIG-base UUID, `0x2A37` or `2A37` into `2a37`. `capabilities(services)` maps services to `Capability` (unknown services add nothing). What to scan, subscribe to and read now comes from the `ProtocolRegistry`.
