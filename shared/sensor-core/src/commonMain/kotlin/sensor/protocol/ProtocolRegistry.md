# ProtocolRegistry.kt

**Path:** `.../sensor/protocol/ProtocolRegistry.kt` · **Layer:** protocol

Every protocol the core understands (heart rate, running speed and cadence, cycling speed and cadence, cycling power, fitness machine, battery, device information). A native layer asks it WHAT to scan for (`scanServices()`: the workout services), subscribe to (`notifyCharacteristics()`), read once (`readCharacteristics()`) and forward raw (`rawForwarded()`), and the hub asks HOW to decode (`adapterFor`). `isWorkoutCharacteristic` tells a workout measurement from battery or device information: a device where none could be subscribed is connected but NOT_SUPPORTED. Adding a protocol is one adapter in the list.
