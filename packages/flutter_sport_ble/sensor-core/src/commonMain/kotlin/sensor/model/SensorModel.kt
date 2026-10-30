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

    // The order above is mirrored by the Pigeon enum of flutter_sport_ble: ONLY APPEND below.

    /** Pedal revolutions per minute: 0 means the cranks are verified still. */
    CYCLING_CADENCE,

    /** Watts (a bike power meter, a trainer, a rower). Never negative. */
    POWER_WATTS,

    /** Metres per second of a bike: a wheel sensor with a known wheel circumference, or a trainer. */
    CYCLING_SPEED,

    /** Percent, as the machine reports it. */
    INCLINE,

    /** Cumulative kilocalories of the machine since ITS own start. */
    ENERGY_KCAL,

    /** Strokes per minute (a rower). */
    STROKE_RATE,

    /** Cumulative strokes of the machine since ITS own start. */
    STROKE_COUNT,

    /** Cumulative wheel revolutions of a cycling sensor (a counter; speed needs the wheel circumference). */
    WHEEL_REVOLUTIONS,

    /** Steps per minute of a machine (cross trainer, stair or step climber). */
    STEP_RATE,

    /** Cumulative floors of a stair or step climber since ITS own start. */
    FLOORS,
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

/** What a device told about itself (read once, never measured). */
enum class DeviceInfoField { MANUFACTURER, MODEL, FIRMWARE, HARDWARE, SOFTWARE }

/**
 * What a notification (or a read) of a characteristic turned into. A reading is a number the resolver can choose; the other
 * events are structured data that is not one number and is kept per device.
 */
sealed interface SensorEvent {
    class Measurement(val reading: SensorReading) : SensorEvent

    /** R-R intervals in milliseconds, in the order the sensor sent them. */
    class RrIntervals(val intervalsMs: List<Int>) : SensorEvent

    class DeviceInfo(val field: DeviceInfoField, val value: String) : SensorEvent

    /** The device's own battery level, 0 to 100. Per device: it is never resolved between devices. */
    class Battery(val percent: Int) : SensorEvent
}

/** What the hub knows about one device besides its metrics. */
class DeviceDetails(
    val manufacturer: String?,
    val model: String?,
    val firmware: String?,
    val batteryPercent: Int?,
    /** The R-R intervals of the latest heart rate notification that had some (empty when none yet). */
    val recentRrMs: List<Int>,
)
