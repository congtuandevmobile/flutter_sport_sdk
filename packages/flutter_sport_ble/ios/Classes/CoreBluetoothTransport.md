# CoreBluetoothTransport.swift

**Path:** `ios/Classes/CoreBluetoothTransport.swift` · **Layer:** native radio

The real radio. The `CBCentralManager` is created on first scan or connect, so the Bluetooth permission prompt appears then and never at launch (`adapterState` reads `CBManager.authorization` without creating it). A scan or connect requested before the adapter is powered on waits for `poweredOn`. Per device: discover services, then characteristics, subscribe to the wanted ones, announce once every subscription answered. Adapter off, unauthorized or unsupported ends the links with `BLUETOOTH_OFF:` / `PERMISSION:` / `UNSUPPORTED:`. Not unit-tested (it needs a radio); never run against a real sensor. No reconnect, no state restoration.
