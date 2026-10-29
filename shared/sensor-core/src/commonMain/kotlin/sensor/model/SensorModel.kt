package sensor.model

/** What a reading measures. Units are fixed (see each entry): an adapter converts BEFORE it makes a reading. */
enum class MetricType {
    /** Beats per minute. */
    HEART_RATE,

    /** Metres per second. */
    RUNNING_SPEED,

    /** Steps (or strides, as the device reports them) per minute. */
    RUNNING_CADENCE,

    /** Metres per step/stride, as the device defines it. */
    RUNNING_STRIDE_LENGTH,

    /** Cumulative metres of the device since ITS own start: a counter, never a workout distance by itself. */
    TOTAL_DISTANCE,
}

enum class MeasurementKind {
    /** The value right now. */
    INSTANTANEOUS,

    /** A running total of the device: only differences between two values of ONE connection mean something. */
    CUMULATIVE,
}

/** One number from one source. `receivedAtMs` is the receiving phone's monotonic clock, never the device's clock. */
class SensorReading(
    val metric: MetricType,
    val value: Double,
    val kind: MeasurementKind,
)

/** What a device can do, decided from the GATT services it really exposes (never from its name). */
enum class Capability {
    HEART_RATE,
    RUNNING_SPEED_CADENCE,
    CYCLING_SPEED_CADENCE,
    CYCLING_POWER,
    FITNESS_MACHINE,
    BATTERY,
    DEVICE_INFORMATION,
}
