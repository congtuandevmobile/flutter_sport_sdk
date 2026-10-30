package challenge.engine

import challenge.model.ChallengeDefinition
import challenge.model.ChallengeEvent
import challenge.model.ChallengeResult
import challenge.model.ChallengeSnapshot
import challenge.model.ChallengeState
import challenge.model.CompletedStage
import challenge.model.CompletionEvidence
import challenge.model.CompletionPolicy
import challenge.model.ProgressMetric
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
        if (atMs < maxOf(stageStartedAt, lastAcceptedAt, lastEventAt)) return ChallengeResult.refused(Refusal.TIME_BACKWARDS)
        val policy = definition.stages[index].policy
        val allowed = when (policy) {
            CompletionPolicy.AUTO -> false
            CompletionPolicy.MANUAL, CompletionPolicy.SENSOR_OR_MANUAL ->
                evidence == CompletionEvidence.MANUAL || evidence == CompletionEvidence.JUDGE
            CompletionPolicy.JUDGE_REQUIRED -> evidence == CompletionEvidence.JUDGE
        }
        // A refused command must not mutate the engine: otherwise a target event can be applied without reaching the journal.
        // AUTO is the exception: a due timer still completes when this command happens to arrive before the next tick.
        if (!allowed && policy != CompletionPolicy.AUTO) return ChallengeResult.refused(Refusal.NOT_ALLOWED)
        val due = settle(atMs)
        if (due.any { it is ChallengeEvent.StageCompleted }) return ChallengeResult(due)
        if (!allowed) return ChallengeResult.refused(Refusal.NOT_ALLOWED)
        return ChallengeResult(due + complete(atMs, evidence))
    }

    /** Starts the next stage explicitly, so the transition time stays in the total. */
    fun nextStage(atMs: Long): ChallengeResult {
        if (state != ChallengeState.TRANSITION) return ChallengeResult.refused(Refusal.WRONG_STATE)
        if (atMs < lastEventAt) return ChallengeResult.refused(Refusal.TIME_BACKWARDS)
        return ChallengeResult(listOf(apply(ChallengeEvent.StageActivated(++seq, atMs, index + 1, activation + 1))))
    }

    /**
     * The clock of a DURATION stage. Call it regularly (the runners do, once a second): when the ACTIVE time of the stage has reached its
     * target, the stage reaches its target AT THE MOMENT the time was reached (not when the tick came), and an AUTO stage completes with
     * TIMER evidence. The completion is an event like any other: it is journaled before it is shown, and a replay gives the same
     * result. Nothing happens in another state: a paused challenge does not run out of time, and neither does one that is not running.
     */
    fun tick(atMs: Long): ChallengeResult {
        val due = settle(atMs)
        if (due.isNotEmpty()) return ChallengeResult(due)
        // a DURATION stage that is running leaves a checkpoint now and then: a crash then loses at most the time since the last one
        if (state == ChallengeState.ACTIVE && stageStatus == StageStatus.ACTIVE &&
            definition.stages[index].metric == ProgressMetric.DURATION && atMs - lastEventAt >= CHECKPOINT_EVERY_MS
        ) {
            return ChallengeResult(listOf(apply(ChallengeEvent.Checkpoint(++seq, atMs))))
        }
        return ChallengeResult.NONE
    }

    /** The events of a DURATION stage whose time is up at [atMs] (empty when it is not up). */
    private fun settle(atMs: Long): List<ChallengeEvent> {
        if (state != ChallengeState.ACTIVE || stageStatus != StageStatus.ACTIVE) return emptyList()
        val stage = definition.stages[index]
        if (stage.metric != ProgressMetric.DURATION) return emptyList()
        val dueAt = stageStartedAt + stagePausedTotal + (stage.target * 1000.0).toLong()
        if (atMs < dueAt) return emptyList()
        val at = maxOf(dueAt, lastEventAt) // an event never goes back in time
        val events = ArrayList<ChallengeEvent>(3)
        events += apply(ChallengeEvent.TargetReached(++seq, at, activation))
        if (stage.policy == CompletionPolicy.AUTO) events += complete(at, CompletionEvidence.TIMER)
        return events
    }

    /** A pause by the user (refused when the definition forbids it). */
    fun pause(atMs: Long): ChallengeResult = pause(atMs, "user")

    internal fun pause(atMs: Long, reason: String): ChallengeResult {
        if (state != ChallengeState.ACTIVE && state != ChallengeState.TRANSITION) return ChallengeResult.refused(Refusal.WRONG_STATE)
        if (reason == "user" && !definition.allowPause) return ChallengeResult.refused(Refusal.PAUSE_NOT_ALLOWED)
        if (atMs < lastEventAt) return ChallengeResult.refused(Refusal.TIME_BACKWARDS)
        // a time that ran out before the pause is settled first: the pause must not stretch the stage
        val due = settle(atMs)
        if (state == ChallengeState.COMPLETED) return ChallengeResult(due) // the time that ran out was the last stage: nothing left to pause
        return ChallengeResult(due + apply(ChallengeEvent.Paused(++seq, atMs, reason)))
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
        // A DURATION stage shows its clock as its progress (seconds, capped at the target); it is display only: the stage completes by tick().
        val shownProgress = if (current?.metric == ProgressMetric.DURATION && stageStatus != StageStatus.COMPLETED && stageStatus != StageStatus.PENDING) {
            minOf(current.target, stageTime / 1000.0)
        } else progress
        return ChallengeSnapshot(
            state, definition.id, definition.version, index, current?.id, activation, stageStatus, shownProgress, current?.target ?: 0.0,
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
                definition.stages[index].let { if (it.metric == ProgressMetric.DURATION) progress = it.target }
            }
            is ChallengeEvent.StageCompleted -> if (e.activation == activation && stageStatus != StageStatus.COMPLETED) {
                stageStatus = StageStatus.COMPLETED
                val durationMs = maxOf(0L, e.atMs - stageStartedAt - stagePausedTotal)
                // the progress of a DURATION stage is the time it ran (seconds, at most the target), also when it is confirmed early
                definition.stages[index].let { if (it.metric == ProgressMetric.DURATION) progress = minOf(it.target, durationMs / 1000.0) }
                results.add(CompletedStage(definition.stages[index].id, durationMs, progress, e.evidence))
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
            is ChallengeEvent.Checkpoint -> Unit // it only moves lastEventAt (above): the stage clock is derived from event times
            is ChallengeEvent.Completed -> {
                state = ChallengeState.COMPLETED
                finishedAt = e.atMs
            }
        }
        return e
    }

    companion object {
        /** How often a running DURATION stage leaves a checkpoint (an unmeasured starting value). */
        const val CHECKPOINT_EVERY_MS = 10_000L

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
