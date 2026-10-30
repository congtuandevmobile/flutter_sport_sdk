package challenge.session

import challenge.engine.ChallengeEngine
import challenge.model.ChallengeDefinition
import challenge.model.ChallengeEvent
import challenge.model.ChallengeResult
import challenge.model.ChallengeSnapshot
import challenge.model.ChallengeState
import challenge.model.CompletionEvidence
import challenge.model.ProgressSample
import challenge.model.Refusal
import challenge.model.StageDefinition

/** A restored session and the events the recovery itself adds (to append to the journal). */
class RestoredSession(val session: ChallengeSession, val recoveryEvents: List<ChallengeEvent>, val ignoredEvents: Int)

/**
 * A [ChallengeEngine] and the feeding of it: it turns the cumulative counters that GPS and machines report into stage-local deltas.
 *
 *  - Event time decides which interval a measurement belongs to. Only an ACTIVE stage looks at counters, and a measurement made before
 *    the stage started or before the last resume is dropped (it never becomes a baseline). Every stage, and every resume, starts
 *    without a baseline: the first measurement after it is a baseline, so neither what moved while paused nor the distance of the
 *    previous stage is ever credited.
 *  - A counter advances a stage only if its source is allowed for it, and only ONE allowed source at a time (see [selectActive]).
 *  - A manual delta (reps, a station) carries its own event id from the host, so it is idempotent across restarts.
 *  - The baselines are not durable: after a restore the first sample of each source is a new baseline (a gap is never credited).
 * Not thread-safe: call it through one serialized executor.
 */
class ChallengeSession private constructor(
    val definition: ChallengeDefinition,
    val sessionId: String,
    private val maxGapMs: Long,
    private val engine: ChallengeEngine,
) {
    constructor(definition: ChallengeDefinition, sessionId: String) :
        this(definition, sessionId, DEFAULT_MAX_GAP_MS, ChallengeEngine(definition, sessionId))

    private val adapters = HashMap<String, StageCounterAdapter>()
    private val latest = HashMap<String, Latest>()
    private var activeSource: String? = null

    private class Latest(val epoch: Long, val value: Double, val atMs: Long)

    val currentState: ChallengeState get() = engine.currentState

    fun start(atMs: Long): ChallengeResult = after(engine.start(atMs), atMs)

    /** A cumulative counter of [sourceId] (a GPS total, a machine's distance). */
    fun onCounter(sourceId: String, epoch: Long, counter: Double, atMs: Long): ChallengeResult {
        if (sourceId.isBlank() || !counter.isFinite() || counter < 0.0 || atMs < 0L) return ChallengeResult.refused(Refusal.BAD_DELTA)
        if (engine.currentState != ChallengeState.ACTIVE) return ChallengeResult.NONE // nothing is looked at outside a running stage
        // The fence comes BEFORE any baseline is touched: a measurement made before the stage started or before the last resume (a late
        // callback) is dropped here, so it can neither become a baseline nor be the first half of a delta.
        if (!engine.canIngestMeasurementAt(atMs)) return ChallengeResult.refused(Refusal.TIME_BACKWARDS)
        val stage = currentStage() ?: return ChallengeResult.NONE
        if (sourceId !in stage.allowedSources) return ChallengeResult.NONE
        val noted = latest[sourceId]
        if (noted == null || epoch > noted.epoch || (epoch == noted.epoch && atMs >= noted.atMs)) latest[sourceId] = Latest(epoch, counter, atMs)
        val adapter = adapters.getOrPut(sourceId) {
            StageCounterAdapter(sessionId, sourceId, stage.metric, maxGapMs = maxGapMs).also { it.activate(engine.stageActivation()) }
        }
        // Every allowed source keeps its own baseline, but only the ACTIVE source credits the stage: two sensors that watch the same
        // movement are never added together.
        val previousSource = activeSource
        val sample = adapter.onCounter(epoch, counter, atMs)
        if (selectActive(stage, atMs) != sourceId) return ChallengeResult.NONE
        // The source that takes over credits nothing with its first delta: that delta may reach back to a moment the previous source
        // already credited. Its next samples count.
        if (previousSource != null && previousSource != sourceId) return ChallengeResult.NONE
        return after(engine.accept(sample ?: return ChallengeResult.NONE), atMs)
    }

    /**
     * The source that may advance the stage now: the current one while it is fresh (no flipping back and forth), else the first
     * FRESH source in the order of `allowedSources` (that order is the priority). A source that takes over continues from its own
     * baseline: its total is never assigned to the stage.
     */
    private fun selectActive(stage: StageDefinition, nowMs: Long): String? {
        val current = activeSource
        if (current != null && isFresh(current, nowMs)) return current
        activeSource = stage.allowedSources.firstOrNull { isFresh(it, nowMs) }
        return activeSource
    }

    private fun isFresh(source: String, nowMs: Long): Boolean {
        val noted = latest[source] ?: return false
        return noted.atMs <= nowMs && nowMs - noted.atMs <= maxGapMs
    }

    /** A delta of the current stage's metric from a source that counts for itself (reps, a station): [eventId] must be stable. */
    fun onDelta(sourceId: String, eventId: String, delta: Double, atMs: Long): ChallengeResult = onDelta(sourceId, eventId, delta, atMs, CURRENT_ACTIVATION)

    /**
     * Like [onDelta], for the stage activation the host SAW when it made the measurement: a callback that arrives after the stage
     * changed is refused (`STALE_ACTIVATION`) instead of advancing the next stage. [CURRENT_ACTIVATION] means the current one.
     */
    fun onDelta(sourceId: String, eventId: String, delta: Double, atMs: Long, stageActivation: Long): ChallengeResult {
        val stage = currentStage() ?: return ChallengeResult.refused(Refusal.WRONG_STATE)
        val activation = if (stageActivation == CURRENT_ACTIVATION) engine.stageActivation() else stageActivation
        return after(engine.accept(ProgressSample(eventId, sessionId, activation, sourceId, stage.metric, delta, atMs)), atMs)
    }

    fun confirm(evidence: CompletionEvidence, atMs: Long): ChallengeResult = confirm(evidence, atMs, CURRENT_ACTIVATION)

    /** Like [confirm], refused with `STALE_ACTIVATION` when [expectedActivation] is not the active stage's ([CURRENT_ACTIVATION]: no check). */
    fun confirm(evidence: CompletionEvidence, atMs: Long, expectedActivation: Long): ChallengeResult {
        if (expectedActivation != CURRENT_ACTIVATION && expectedActivation != engine.stageActivation()) {
            return ChallengeResult.refused(Refusal.STALE_ACTIVATION)
        }
        return after(engine.confirm(evidence, atMs), atMs)
    }

    fun nextStage(atMs: Long): ChallengeResult = after(engine.nextStage(atMs), atMs)

    /** A pause or a resume forgets every baseline: what moved while paused is never credited, however short the pause was. */
    fun pause(atMs: Long): ChallengeResult = after(engine.pause(atMs), atMs).also { forgetBaselines(it) }
    fun resume(atMs: Long): ChallengeResult = after(engine.resume(atMs), atMs).also { forgetBaselines(it) }
    fun snapshot(atMs: Long): ChallengeSnapshot = engine.snapshot(atMs)

    private fun forgetBaselines(result: ChallengeResult) {
        if (result.events.isEmpty()) return
        forgetEverything()
    }

    private fun forgetEverything() {
        adapters.clear()
        latest.clear()
        activeSource = null
    }

    private fun currentStage() = definition.stages.getOrNull(engine.currentStageIndex())

    /**
     * After every input: a new stage starts with NO baseline. The first measurement taken at or after the activation only becomes the
     * baseline, the next ones count. A counter seen before the activation is never used: from two totals around the boundary there is
     * no way to know how much of the difference was covered after it. (The price: the distance before a source's first sample of the
     * stage is not credited.)
     */
    private fun after(result: ChallengeResult, atMs: Long): ChallengeResult {
        if (result.events.any { it is ChallengeEvent.StageActivated }) forgetEverything()
        return result
    }

    companion object {
        private const val DEFAULT_MAX_GAP_MS = 5_000L

        /** "The stage that is active now": the value to pass when the host does not say which activation a measurement was made for. */
        const val CURRENT_ACTIVATION = -1L

        /** A session for [definition] (Swift cannot use Kotlin default arguments). */
        fun create(definition: ChallengeDefinition, sessionId: String): ChallengeSession = ChallengeSession(definition, sessionId)

        /** Rebuilds a session from its journal events (see [ChallengeEngine.restore]). Null without a Created event. */
        fun restore(events: List<ChallengeEvent>): RestoredSession? {
            val restored = ChallengeEngine.restore(events) ?: return null
            val engine = restored.engine
            return RestoredSession(ChallengeSession(engine.definition, engine.sessionId, DEFAULT_MAX_GAP_MS, engine), restored.recoveryEvents, restored.ignoredEvents)
        }
    }
}
