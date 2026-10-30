package sensor.protocol

import sensor.model.Capability
import sensor.model.SensorEvent

/** The decoders of one connection of one device (counters, rates): a new connection gets a new state. */
class SourceState {
    private val values = HashMap<String, Any>()

    @Suppress("UNCHECKED_CAST")
    fun <T : Any> getOrPut(key: String, make: () -> T): T = values.getOrPut(key, make) as T

    /** Wheel circumference in metres, when the host knows it (a wheel sensor gives revolutions, not speed). */
    var wheelCircumferenceM: Double? = null
}

/**
 * One GATT service the core understands: what to subscribe to, what to read once, and how to decode. Pure Kotlin: a parser never
 * calls a Bluetooth API, so it is tested with packets. A packet that is truncated or impossible gives no events.
 */
interface BleProtocolAdapter {
    /** 16-bit service number, 4 lowercase hex digits. */
    val serviceUuid: String

    /** What this service tells about the device that has it. */
    val capability: Capability

    /** Characteristics to subscribe to (notify or indicate), when the device has them. */
    val notifyCharacteristics: List<String>

    /** Characteristics to read once after connecting (their value is decoded like a notification). */
    val readCharacteristics: List<String> get() = emptyList()

    /** Characteristics whose bytes are also handed to the host untouched. */
    val forwardRaw: Set<String> get() = emptySet()

    fun decode(characteristic: String, bytes: ByteArray, state: SourceState, nowMs: Long): List<SensorEvent>
}
