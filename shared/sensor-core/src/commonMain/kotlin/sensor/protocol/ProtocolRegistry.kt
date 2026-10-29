package sensor.protocol

import sensor.model.Capability
import sensor.protocol.adapters.BatteryAdapter
import sensor.protocol.adapters.CyclingPowerAdapter
import sensor.protocol.adapters.CyclingSpeedCadenceAdapter
import sensor.protocol.adapters.DeviceInformationAdapter
import sensor.protocol.adapters.FitnessMachineAdapter
import sensor.protocol.adapters.HeartRateAdapter
import sensor.protocol.adapters.RunningSpeedCadenceAdapter

/**
 * Every protocol the core understands. A native layer asks this registry WHAT to scan for, subscribe to and read (it never keeps
 * its own list), and the hub asks it HOW to decode. Adding a protocol is one adapter here.
 */
object ProtocolRegistry {
    val adapters: List<BleProtocolAdapter> = listOf(
        HeartRateAdapter,
        RunningSpeedCadenceAdapter,
        CyclingSpeedCadenceAdapter,
        CyclingPowerAdapter,
        FitnessMachineAdapter,
        BatteryAdapter,
        DeviceInformationAdapter,
    )

    private val byCharacteristic: Map<String, BleProtocolAdapter> = buildMap {
        for (a in adapters) for (c in a.notifyCharacteristics + a.readCharacteristics) put(c, a)
    }

    /** Services worth scanning for: the ones that carry workout data (battery and device information are not advertised for it). */
    fun scanServices(): List<String> =
        adapters.filter { it.capability != Capability.BATTERY && it.capability != Capability.DEVICE_INFORMATION }.map { it.serviceUuid }

    /** Characteristics to subscribe to after connecting (the transport keeps the ones the device really has). */
    fun notifyCharacteristics(): List<String> = adapters.flatMap { it.notifyCharacteristics }.distinct()

    /** Characteristics to read once after connecting. */
    fun readCharacteristics(): List<String> = adapters.flatMap { it.readCharacteristics }.distinct()

    /** Characteristics whose bytes are also handed to the host untouched. */
    fun rawForwarded(): Set<String> = adapters.flatMap { it.forwardRaw }.toSet()

    fun adapterFor(characteristic: String): BleProtocolAdapter? = byCharacteristic[Gatt.short(characteristic)]

    /** True when a characteristic can be turned into data or handed over. */
    fun isUseful(characteristic: String): Boolean = Gatt.short(characteristic) in byCharacteristic

    /**
     * True when a characteristic carries WORKOUT data (not just battery or device information): a device where none of these could
     * be subscribed is connected but not usable for a workout.
     */
    fun isWorkoutCharacteristic(characteristic: String): Boolean {
        val adapter = byCharacteristic[Gatt.short(characteristic)] ?: return false
        return adapter.capability != Capability.BATTERY && adapter.capability != Capability.DEVICE_INFORMATION &&
            Gatt.short(characteristic) in adapter.notifyCharacteristics
    }
}
