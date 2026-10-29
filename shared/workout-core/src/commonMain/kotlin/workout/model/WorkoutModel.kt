package workout.model

/** The kind of workout. It decides which distance source is preferred. */
enum class WorkoutMode(val isIndoor: Boolean) {
    OUTDOOR_RUNNING(false),
    INDOOR_RUNNING(true),
    OUTDOOR_CYCLING(false),
    INDOOR_CYCLING(true),
}

/** The lifecycle of a session. A session is NOT a Bluetooth connection: a sensor can stay connected between two workouts. */
enum class WorkoutState { IDLE, RUNNING, PAUSED, FINISHED }

/** How a distance reaches the ledger. */
enum class DistanceSourceKind {
    /** A GPS engine: a cumulative distance of its own. */
    GPS,

    /** A cumulative distance counter of a device (a footpod, a treadmill, a bike computer). */
    COUNTER,

    /** An instantaneous speed that is integrated over time. */
    SPEED,
}

/** One place a distance can come from. Two sources of the SAME device (its counter and its speed) are two sources. */
data class DistanceSource(val id: String, val kind: DistanceSourceKind) {
    override fun toString(): String = "${kind.name}:$id"
}

/**
 * Everything that changes a workout is an event with a sequence number: the journal stores these, and replaying them gives the
 * same session again. `seq` grows by one per event of a session; `atMs` is the phone's monotonic clock.
 */
sealed class WorkoutEvent {
    abstract val seq: Long
    abstract val atMs: Long

    class Started(override val seq: Long, override val atMs: Long, val mode: WorkoutMode) : WorkoutEvent()
    class Paused(override val seq: Long, override val atMs: Long) : WorkoutEvent()
    class Resumed(override val seq: Long, override val atMs: Long) : WorkoutEvent()
    class Finished(override val seq: Long, override val atMs: Long) : WorkoutEvent()

    /** The distance now comes from [source]. The distance already counted is kept; the new source starts from a new baseline. */
    class SourceSelected(override val seq: Long, override val atMs: Long, val source: DistanceSource, val reason: String) : WorkoutEvent()

    /** A source's counter was read as the new zero point: no distance is credited for it. */
    class BaselineEstablished(override val seq: Long, override val atMs: Long, val source: DistanceSource, val value: Double, val reason: String) : WorkoutEvent()

    /** [deltaMeters] (positive) were added to the workout distance, from [source]. */
    class DistanceAdvanced(override val seq: Long, override val atMs: Long, val source: DistanceSource, val deltaMeters: Double) : WorkoutEvent()
}

/** What the workout shows now. Times are milliseconds of the phone's monotonic clock; a pause is NOT in [activeMs]. */
class WorkoutSnapshot(
    val state: WorkoutState,
    val mode: WorkoutMode?,
    val activeMs: Long,
    val pausedMs: Long,
    val distanceMeters: Double,
    /** Where the distance comes from now, or null when no source is chosen yet (the distance is then 0, not guessed). */
    val distanceSource: DistanceSource?,
    val lastSeq: Long,
)
