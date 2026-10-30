package challenge.engine

import challenge.model.ChallengeDefinition
import challenge.model.ChallengeEvent
import challenge.model.ChallengeResult
import challenge.model.ChallengeSnapshot
import challenge.model.ChallengeState
import challenge.model.CompletedStage
import challenge.model.CompletionEvidence
import challenge.model.CompletionPolicy
import challenge.model.ProgressSample
import challenge.model.Refusal
import challenge.model.StageStatus

/**
 * The challenge as a state machine of events. Every input returns a [ChallengeResult]: the events it caused (to be journaled BEFORE
 * the result is shown) or the reason it did nothing (never an exception for a bad input). Replaying the events gives the same
 * challenge ([restore]).
 *
 * Rules: one stage is active at a time; a sample counts only for the stage activation it was made for, from an allowed source and
 * with the stage's own metric, once (by event id); a stage that completes stays completed and never runs again; the total time
 * includes the transitions, the stage time freezes at completion, a pause is in neither. Not thread-safe: call it through one
 * serialized executor. All times come from one monotonic clock.
 */
class ChallengeEngine(val definition: ChallengeDefinition, val sessionId: String) {
    private var seq = 0L
    private var state = ChallengeState.IDLE
    private var resumeState = ChallengeState.ACTIVE
    private var index = -1
    private var activation = 0L
    private var stageStatus = StageStatus.PENDING
    private var progress = 0.0
    private var startedAt = -1L
    private var stageStartedAt = -1L
    private var pausedAt = -1L
    private var pausedTotal = 0L
    private var stagePausedTotal = 0L
    private var lastAcceptedAt = -1L
    private var lastEventAt = -1L
    private var finishedAt = -1L
    private var recoveries = 0
    private val seenEventIds = HashSet<String>()
    private val results = ArrayList<CompletedStage>()

    val currentState: ChallengeState get() = state

    /** The stage activation a sample must carry to count now. */
    fun stageActivation(): Long = activation

    /**
     * Whether a measurement taken at [atMs] may be looked at now: the challenge is ACTIVE and the measurement is not older than the
     * stage start, the last resume or the last accepted event. The session asks BEFORE it lets a counter touch a baseline: a stale
     * measurement that the engine would refuse must not become the baseline of the next one.
     */
    fun canIngestMeasurementAt(atMs: Long): Boolean =
        state == ChallengeState.ACTIVE && stageStatus != StageStatus.COMPLETED && atMs >= stageStartedAt && atMs >= lastEventAt

    /** The stage that is active now, or null before the start and after the end. */
    fun currentStageIndex(): Int = index

    fun start(atMs: Long): ChallengeResult {
        if (atMs < 0L) return ChallengeResult.refused(Refusal.TIME_BACKWARDS)
        if (state != ChallengeState.IDLE) return ChallengeResult.refused(Refusal.WRONG_STATE)
        val events = ArrayList<ChallengeEvent>(3)
        events += apply(ChallengeEvent.Created(++seq, atMs, sessionId, definition))
        events += apply(ChallengeEvent.Started(++seq, atMs))
        events += apply(ChallengeEvent.StageActivated(++seq, atMs, 0, activation + 1))
        return ChallengeResult(events)
    }

    fun accept(sample: ProgressSample): ChallengeResult {
        if (state != ChallengeState.ACTIVE || stageStatus == StageStatus.COMPLETED) return ChallengeResult.refused(Refusal.WRONG_STATE)
        if (sample.sessionId != sessionId) return ChallengeResult.refused(Refusal.WRONG_SESSION)
        if (sample.stageActivation != activation) return ChallengeResult.refused(Refusal.STALE_ACTIVATION)
        val stage = definition.stages[index]
        if (sample.metric != stage.metric) return ChallengeResult.refused(Refusal.WRONG_METRIC)
        if (sample.sourceId !in stage.allowedSources) return ChallengeResult.refused(Refusal.SOURCE_NOT_ALLOWED)
        if (sample.eventId.isBlank()) return ChallengeResult.refused(Refusal.BAD_EVENT_ID)
        if (sample.eventId in seenEventIds) return ChallengeResult.refused(Refusal.DUPLICATE)
        if (!sample.delta.isFinite() || sample.delta <= 0.0) return ChallengeResult.refused(Refusal.BAD_DELTA)
        // Event time decides, not arrival time: a measurement made before the stage started, before the last resume or before the last
        // accepted progress belongs to an interval that is over (a pause, the previous stage) and is never credited.
        if (sample.atMs < stageStartedAt || sample.atMs < lastAcceptedAt || sample.atMs < lastEventAt) {
            return ChallengeResult.refused(Refusal.TIME_BACKWARDS)
        }
        if (stageStatus == StageStatus.TARGET_REACHED) return ChallengeResult.refused(Refusal.TARGET_REACHED)
        val applied = minOf(sample.delta, stage.target - progress)
        if (applied <= 0.0) return ChallengeResult.refused(Refusal.TARGET_REACHED)
        val events = ArrayList<ChallengeEvent>(3)
        events += apply(ChallengeEvent.ProgressAdvanced(++seq, sample.atMs, activation, sample.eventId, sample.sourceId, applied))
        if (progress >= stage.target) {
            events += apply(ChallengeEvent.TargetReached(++seq, sample.atMs, activation))
            if (stage.policy == CompletionPolicy.AUTO) events += complete(sample.atMs, CompletionEvidence.SENSOR)
        }
        return ChallengeResult(events)
    }

    /**
     * Confirms the active stage. A MANUAL or SENSOR_OR_MANUAL stage takes MANUAL or JUDGE evidence; a JUDGE_REQUIRED one only JUDGE;
     * an AUTO one none. The judge is NOT authenticated here: the host or a backend must do that.
     */
    fun confirm(evidence: CompletionEvidence, atMs: Long): ChallengeResult {
        if (state != ChallengeState.ACTIVE || stageStatus == StageStatus.COMPLETED) return ChallengeResult.refused(Refusal.WRONG_STATE)
        if (atMs < maxOf(stageStartedAt, lastAcceptedAt)) return ChallengeResult.refused(Refusal.TIME_BACKWARDS)
        val allowed = when (definition.stages[index].policy) {
            CompletionPolicy.AUTO -> false
            CompletionPolicy.MANUAL, CompletionPolicy.SENSOR_OR_MANUAL ->
                evidence == CompletionEvidence.MANUAL || evidence == CompletionEvidence.JUDGE
            CompletionPolicy.JUDGE_REQUIRED -> evidence == CompletionEvidence.JUDGE
        }
        if (!allowed) return ChallengeResult.refused(Refusal.NOT_ALLOWED)
        return ChallengeResult(complete(atMs, evidence))
    }

    /** Starts the next stage explicitly, so the transition time stays in the total. */
    fun nextStage(atMs: Long): ChallengeResult {
        if (state != ChallengeState.TRANSITION) return ChallengeResult.refused(Refusal.WRONG_STATE)
        if (atMs < lastEventAt) return ChallengeResult.refused(Refusal.TIME_BACKWARDS)
        return ChallengeResult(listOf(apply(ChallengeEvent.StageActivated(++seq, atMs, index + 1, activation + 1))))
    }

    /** A pause by the user (refused when the definition forbids it). */
    fun pause(atMs: Long): ChallengeResult = pause(atMs, "user")

    internal fun pause(atMs: Long, reason: String): ChallengeResult {
        if (state != ChallengeState.ACTIVE && state != ChallengeState.TRANSITION) return ChallengeResult.refused(Refusal.WRONG_STATE)
        if (reason == "user" && !definition.allowPause) return ChallengeResult.refused(Refusal.PAUSE_NOT_ALLOWED)
        if (atMs < lastEventAt) return ChallengeResult.refused(Refusal.TIME_BACKWARDS)
        return ChallengeResult(listOf(apply(ChallengeEvent.Paused(++seq, atMs, reason))))
    }

    fun resume(atMs: Long): ChallengeResult {
        if (state != ChallengeState.PAUSED) return ChallengeResult.refused(Refusal.WRONG_STATE)
        if (atMs < pausedAt) return ChallengeResult.refused(Refusal.TIME_BACKWARDS)
        return ChallengeResult(listOf(apply(ChallengeEvent.Resumed(++seq, atMs))))
    }

    fun snapshot(atMs: Long): ChallengeSnapshot {
        val measuredNow = when (state) {
            ChallengeState.PAUSED -> pausedAt
            ChallengeState.COMPLETED -> finishedAt
            else -> maxOf(atMs, lastEventAt)
        }
        val total = if (startedAt >= 0L) maxOf(0L, measuredNow - startedAt - pausedTotal) else 0L
        val stageTime = when {
            stageStatus == StageStatus.COMPLETED -> results.last().durationMs
            stageStartedAt >= 0L -> maxOf(0L, measuredNow - stageStartedAt - stagePausedTotal)
            else -> 0L
        }
        val current = definition.stages.getOrNull(index)
        return ChallengeSnapshot(
            state, definition.id, definition.version, index, current?.id, activation, stageStatus, progress, current?.target ?: 0.0,
            total, stageTime, results.toList(), seq, recoveries,
        )
    }

    // ── applying events (live and replay share this one code path) ─────────────

    private fun complete(atMs: Long, evidence: CompletionEvidence): List<ChallengeEvent> {
        val out = ArrayList<ChallengeEvent>(2)
        out += apply(ChallengeEvent.StageCompleted(++seq, atMs, activation, evidence))
        if (index == definition.stages.lastIndex) out += apply(ChallengeEvent.Completed(++seq, atMs))
        return out
    }

    private fun apply(e: ChallengeEvent): ChallengeEvent {
        lastEventAt = maxOf(lastEventAt, e.atMs)
        when (e) {
            is ChallengeEvent.Created -> Unit
            is ChallengeEvent.Started -> {
                startedAt = e.atMs
                state = ChallengeState.ACTIVE
            }
            is ChallengeEvent.StageActivated -> {
                index = e.index
                activation = e.activation
                stageStatus = StageStatus.ACTIVE
                stageStartedAt = e.atMs
                stagePausedTotal = 0L
                lastAcceptedAt = -1L
                progress = 0.0
                seenEventIds.clear()
                state = ChallengeState.ACTIVE
            }
            is ChallengeEvent.ProgressAdvanced -> if (e.activation == activation) {
                progress += e.delta
                seenEventIds.add(e.eventId)
                lastAcceptedAt = e.atMs
            }
            is ChallengeEvent.TargetReached -> if (e.activation == activation && stageStatus == StageStatus.ACTIVE) {
                stageStatus = StageStatus.TARGET_REACHED
            }
            is ChallengeEvent.StageCompleted -> if (e.activation == activation && stageStatus != StageStatus.COMPLETED) {
                stageStatus = StageStatus.COMPLETED
                results.add(CompletedStage(definition.stages[index].id, maxOf(0L, e.atMs - stageStartedAt - stagePausedTotal), progress, e.evidence))
                state = ChallengeState.TRANSITION
            }
            is ChallengeEvent.Paused -> {
                resumeState = state
                pausedAt = e.atMs
                state = ChallengeState.PAUSED
                if (e.reason == "recovery") recoveries += 1
            }
            is ChallengeEvent.Resumed -> {
                val gap = maxOf(0L, e.atMs - pausedAt)
                pausedTotal += gap
                if (resumeState == ChallengeState.ACTIVE) stagePausedTotal += gap
                pausedAt = -1L
                state = resumeState
            }
            is ChallengeEvent.Completed -> {
                state = ChallengeState.COMPLETED
                finishedAt = e.atMs
            }
        }
        return e
    }

    companion object {
        /**
         * Rebuilds a challenge from its journal events, in any order and with duplicates (an event whose sequence number was already
         * applied is ignored). The definition comes from the Created event. A challenge that was ACTIVE or in a TRANSITION when the
         * process died comes back PAUSED at its last event, even when the definition forbids pausing: the time since is not counted
         * and the snapshot's `recoveries` says so, so a result with a recovery can be treated as not time-verified. The recovery adds a
         * Paused event for the journal. Null when there is no Created event.
         */
        fun restore(events: List<ChallengeEvent>): RestoredEngine? {
            val ordered = events.sortedBy { it.seq }
            val created = ordered.firstOrNull { it is ChallengeEvent.Created } as? ChallengeEvent.Created ?: return null
            val engine = ChallengeEngine(created.definition, created.sessionId)
            var last = 0L
            var ignored = 0
            for (e in ordered) {
                if (e.seq <= last) { ignored += 1; continue }
                engine.apply(e)
                last = e.seq
            }
            engine.seq = last
            val recovery = ArrayList<ChallengeEvent>(1)
            if (engine.state == ChallengeState.ACTIVE || engine.state == ChallengeState.TRANSITION) {
                recovery += engine.apply(ChallengeEvent.Paused(++engine.seq, engine.lastEventAt, "recovery"))
            }
            return RestoredEngine(engine, recovery, ignored)
        }
    }
}

/** A restored challenge and the events the recovery itself adds (to append to the journal). */
class RestoredEngine(val engine: ChallengeEngine, val recoveryEvents: List<ChallengeEvent>, val ignoredEvents: Int)
