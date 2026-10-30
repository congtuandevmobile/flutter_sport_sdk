package challenge.model

/** What a stage measures. A domain metric, never a generic "distance": a rower's metres cannot complete a run stage. */
enum class ProgressMetric(val maxRatePerSecond: Double) {
    RUN_METERS(12.0),
    ROW_METERS(8.0),
    SKI_METERS(8.0),
    SLED_METERS(5.0),
    SWIM_METERS(3.0),
    REPS(5.0),

    /**
     * Not a measurement: the ACTIVE time of the stage (a pause is not in it). `target` is in seconds and the engine itself completes the
     * stage when the time is reached (see [challenge.engine.ChallengeEngine.tick]); no source feeds it, so `allowedSources` may be empty.
     * APPEND ONLY: the order is the order of the Pigeon enum.
     */
    DURATION(1.0),
}

/** How a stage is completed. */
enum class CompletionPolicy {
    /** By the sensor, as soon as the target is reached. */
    AUTO,

    /** Only by an explicit confirmation. */
    MANUAL,

    /** By the sensor reaching the target, or by a confirmation when the sensor cannot. */
    SENSOR_OR_MANUAL,

    /** Only with judge evidence: the host or a backend MUST authenticate the judge, this core only records the evidence. */
    JUDGE_REQUIRED,
}

enum class ChallengeState { IDLE, ACTIVE, TRANSITION, PAUSED, COMPLETED }
enum class StageStatus { PENDING, ACTIVE, TARGET_REACHED, COMPLETED }
enum class CompletionEvidence { SENSOR, MANUAL, JUDGE, /** The stage clock reached a DURATION target (APPEND ONLY). */ TIMER }

class StageDefinition(
    val id: String,
    val metric: ProgressMetric,
    val target: Double,
    val policy: CompletionPolicy,
    /** Explicit bindings: only these sources may advance the stage ("gps-primary", "pm5-rower", "manual"). */
    val allowedSources: Set<String>,
) {
    init {
        require(id.isNotBlank()) { "stage id" }
        require(target.isFinite() && target > 0.0) { "stage target" }
        require(allowedSources.none { it.isBlank() } && (allowedSources.isNotEmpty() || metric == ProgressMetric.DURATION)) { "stage sources" }
    }
}

class ChallengeDefinition(
    val id: String,
    val version: Int,
    val stages: List<StageDefinition>,
    /** False for a format where the clock must not stop. (A recovery after the process died still pauses: see the session.) */
    val allowPause: Boolean = true,
) {
    init {
        require(id.isNotBlank() && version > 0 && stages.isNotEmpty()) { "challenge" }
        require(stages.map { it.id }.distinct().size == stages.size) { "duplicate stage ids" }
    }
}

/** An already normalized and validated DELTA of a stage, NOT a device's cumulative counter. */
class ProgressSample(
    /** Unique per measurement and stable across restarts: a repeated id is never credited twice. */
    val eventId: String,
    val sessionId: String,
    /** The stage activation the sample was made for: a callback of an older stage can never advance a newer one. */
    val stageActivation: Long,
    val sourceId: String,
    val metric: ProgressMetric,
    val delta: Double,
    val atMs: Long,
)

class CompletedStage(val stageId: String, val durationMs: Long, val progress: Double, val evidence: CompletionEvidence)

/** Why an input did nothing (a diagnosis, not an exception). */
enum class Refusal {
    WRONG_STATE,
    NOT_ALLOWED,
    PAUSE_NOT_ALLOWED,
    TIME_BACKWARDS,
    WRONG_SESSION,
    STALE_ACTIVATION,
    WRONG_METRIC,
    SOURCE_NOT_ALLOWED,
    BAD_EVENT_ID,
    DUPLICATE,
    BAD_DELTA,
    TARGET_REACHED,
}

/** What an input caused: the events to journal, or the reason nothing happened. */
class ChallengeResult(val events: List<ChallengeEvent>, val refusal: Refusal? = null) {
    val accepted: Boolean get() = refusal == null

    companion object {
        val NONE = ChallengeResult(emptyList())
        fun refused(reason: Refusal) = ChallengeResult(emptyList(), reason)
    }
}

/**
 * Everything that changes a challenge is an event with a sequence number: the journal stores these and replaying them gives the same
 * challenge. `atMs` is the phone's monotonic clock.
 */
sealed class ChallengeEvent {
    abstract val seq: Long
    abstract val atMs: Long

    class Created(override val seq: Long, override val atMs: Long, val sessionId: String, val definition: ChallengeDefinition) : ChallengeEvent()
    class Started(override val seq: Long, override val atMs: Long) : ChallengeEvent()
    class StageActivated(override val seq: Long, override val atMs: Long, val index: Int, val activation: Long) : ChallengeEvent()
    class ProgressAdvanced(
        override val seq: Long, override val atMs: Long, val activation: Long, val eventId: String, val sourceId: String, val delta: Double,
    ) : ChallengeEvent()
    class TargetReached(override val seq: Long, override val atMs: Long, val activation: Long) : ChallengeEvent()
    class StageCompleted(override val seq: Long, override val atMs: Long, val activation: Long, val evidence: CompletionEvidence) : ChallengeEvent()
    class Paused(override val seq: Long, override val atMs: Long, val reason: String) : ChallengeEvent()
    class Resumed(override val seq: Long, override val atMs: Long) : ChallengeEvent()
    class Completed(override val seq: Long, override val atMs: Long) : ChallengeEvent()

    /**
     * "The challenge was alive at [atMs]": written now and then while a DURATION stage runs, so that after the process dies the stage is
     * restored with the time it had already run (up to the last checkpoint) instead of the time of its last progress event.
     */
    class Checkpoint(override val seq: Long, override val atMs: Long) : ChallengeEvent()
}

class ChallengeSnapshot(
    val state: ChallengeState,
    val definitionId: String,
    val definitionVersion: Int,
    val stageIndex: Int,
    val stageId: String?,
    val stageActivation: Long,
    val stageStatus: StageStatus,
    val stageProgress: Double,
    val stageTarget: Double,
    /** The whole challenge, transitions included; a pause is not in it. */
    val totalElapsedMs: Long,
    /** The current stage; frozen once it completes. */
    val stageElapsedMs: Long,
    val completed: List<CompletedStage>,
    val lastSeq: Long,
    /** How many times the challenge was recovered after the process died: a result with a recovery is not time-verified. */
    val recoveries: Int,
)
