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
    const val FITNESS_MACHINE_SERVICE = "1826"
    const val BATTERY_SERVICE = "180f"
    const val DEVICE_INFORMATION_SERVICE = "180a"

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

    /** The characteristics the core can decode (the native layer subscribes to these). */
    fun measurementCharacteristics(serviceUuid: String): List<String> = when (short(serviceUuid)) {
        HEART_RATE_SERVICE -> listOf(HEART_RATE_MEASUREMENT)
        RUNNING_SPEED_CADENCE_SERVICE -> listOf(RSC_MEASUREMENT)
        CYCLING_SPEED_CADENCE_SERVICE -> listOf(CSC_MEASUREMENT) // forwarded raw: not decoded here
        else -> emptyList()
    }
}
