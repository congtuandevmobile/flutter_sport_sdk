package sensor.protocol

import sensor.model.Capability

/**
 * The 16-bit Bluetooth SIG numbers this package knows, written as 4 lowercase hex digits ("180d"). A native layer converts a
 * full 128-bit UUID of the SIG base (0000xxxx-0000-1000-8000-00805f9b34fb) with [short] before it calls the core.
 */
object Gatt {
    const val HEART_RATE_SERVICE = "180d"
    const val HEART_RATE_MEASUREMENT = "2a37"
    const val RUNNING_SPEED_CADENCE_SERVICE = "1814"
    const val RSC_MEASUREMENT = "2a53"
    const val CYCLING_SPEED_CADENCE_SERVICE = "1816"
    const val CSC_MEASUREMENT = "2a5b"
    const val CYCLING_POWER_SERVICE = "1818"
    const val CYCLING_POWER_MEASUREMENT = "2a63"
    const val FITNESS_MACHINE_SERVICE = "1826"
    const val BATTERY_SERVICE = "180f"
    const val DEVICE_INFORMATION_SERVICE = "180a"
    const val BATTERY_LEVEL = "2a19"
    const val MANUFACTURER_NAME = "2a29"
    const val MODEL_NUMBER = "2a24"
    const val FIRMWARE_REVISION = "2a26"
    const val HARDWARE_REVISION = "2a27"
    const val SOFTWARE_REVISION = "2a28"

    // Fitness Machine Service (0x1826) data characteristics
    const val TREADMILL_DATA = "2acd"
    const val CROSS_TRAINER_DATA = "2ace"
    const val STEP_CLIMBER_DATA = "2acf"
    const val STAIR_CLIMBER_DATA = "2ad0"
    const val ROWER_DATA = "2ad1"
    const val INDOOR_BIKE_DATA = "2ad2"

    private const val SIG_BASE_SUFFIX = "-0000-1000-8000-00805f9b34fb"

    /** "0000180D-0000-1000-8000-00805F9B34FB" or "180D" or "0x180d" to "180d"; any other UUID is returned lowercase. */
    fun short(uuid: String): String {
        val u = uuid.trim().lowercase().removePrefix("0x")
        if (u.length == 4) return u
        if (u.length == 36 && u.startsWith("0000") && u.endsWith(SIG_BASE_SUFFIX)) return u.substring(4, 8)
        return u
    }

    /** The capabilities of a device from the services it exposes. Unknown services add nothing. */
    fun capabilities(serviceUuids: List<String>): List<Capability> {
        val out = LinkedHashSet<Capability>()
        for (raw in serviceUuids) {
            when (short(raw)) {
                HEART_RATE_SERVICE -> out.add(Capability.HEART_RATE)
                RUNNING_SPEED_CADENCE_SERVICE -> out.add(Capability.RUNNING_SPEED_CADENCE)
                CYCLING_SPEED_CADENCE_SERVICE -> out.add(Capability.CYCLING_SPEED_CADENCE)
                CYCLING_POWER_SERVICE -> out.add(Capability.CYCLING_POWER)
                FITNESS_MACHINE_SERVICE -> out.add(Capability.FITNESS_MACHINE)
                BATTERY_SERVICE -> out.add(Capability.BATTERY)
                DEVICE_INFORMATION_SERVICE -> out.add(Capability.DEVICE_INFORMATION)
            }
        }
        return out.toList()
    }
}
