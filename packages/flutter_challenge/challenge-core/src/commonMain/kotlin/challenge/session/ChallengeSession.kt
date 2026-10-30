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

/** A restored session and the events the recovery itself adds (to append to the journal). */
class RestoredSession(val session: ChallengeSession, val recoveryEvents: List<ChallengeEvent>, val ignoredEvents: Int)

/**
 * A [ChallengeEngine] and the feeding of it: it turns the cumulative counters that GPS and machines report into stage-local deltas.
 *
 *  - Counters are noted ALWAYS (whatever the stage), so when a stage starts its baseline is the last fresh value of each allowed
 *    source, and the distance covered between the end of one stage and the start of the next is never credited to the new one.
 *  - A counter advances a stage only if its source is allowed for it; a run counter cannot advance a row stage.
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

    private class Latest(val epoch: Long, val value: Double, val atMs: Long)

    val currentState: ChallengeState get() = engine.currentState

    fun start(atMs: Long): ChallengeResult = after(engine.start(atMs), atMs)

    /** A cumulative counter of [sourceId] (a GPS total, a machine's distance). */
    fun onCounter(sourceId: String, epoch: Long, counter: Double, atMs: Long): ChallengeResult {
        if (sourceId.isBlank() || !counter.isFinite() || counter < 0.0 || atMs < 0L) return ChallengeResult.refused(Refusal.BAD_DELTA)
        val noted = latest[sourceId]
        if (noted == null || epoch > noted.epoch || (epoch == noted.epoch && atMs >= noted.atMs)) latest[sourceId] = Latest(epoch, counter, atMs)
        if (engine.currentState != ChallengeState.ACTIVE) return ChallengeResult.NONE
        val stage = currentStage() ?: return ChallengeResult.NONE
        if (sourceId !in stage.allowedSources) return ChallengeResult.NONE
        val adapter = adapters.getOrPut(sourceId) {
            StageCounterAdapter(sessionId, sourceId, stage.metric, maxGapMs = maxGapMs).also { it.activate(engine.stageActivation()) }
        }
        val sample = adapter.onCounter(epoch, counter, atMs) ?: return ChallengeResult.NONE
        return after(engine.accept(sample), atMs)
    }

    /** A delta of the current stage's metric from a source that counts for itself (reps, a station): [eventId] must be stable. */
    fun onDelta(sourceId: String, eventId: String, delta: Double, atMs: Long): ChallengeResult {
        val stage = currentStage() ?: return ChallengeResult.refused(Refusal.WRONG_STATE)
        return after(engine.accept(ProgressSample(eventId, sessionId, engine.stageActivation(), sourceId, stage.metric, delta, atMs)), atMs)
    }

    fun confirm(evidence: CompletionEvidence, atMs: Long): ChallengeResult = after(engine.confirm(evidence, atMs), atMs)
    fun nextStage(atMs: Long): ChallengeResult = after(engine.nextStage(atMs), atMs)
    fun pause(atMs: Long): ChallengeResult = after(engine.pause(atMs), atMs)
    fun resume(atMs: Long): ChallengeResult = after(engine.resume(atMs), atMs)
    fun snapshot(atMs: Long): ChallengeSnapshot = engine.snapshot(atMs)

    private fun currentStage() = definition.stages.getOrNull(engine.currentStageIndex())

    /** After every input: a new stage starts from the last fresh counter of each of its allowed sources (not from the next sample). */
    private fun after(result: ChallengeResult, atMs: Long): ChallengeResult {
        val activated = result.events.lastOrNull { it is ChallengeEvent.StageActivated } as? ChallengeEvent.StageActivated
        if (activated != null) seedStage(activated.index, activated.activation, activated.atMs)
        return result
    }

    private fun seedStage(index: Int, activation: Long, atMs: Long) {
        adapters.clear()
        val stage = definition.stages[index]
        for (source in stage.allowedSources) {
            val noted = latest[source] ?: continue
            if (atMs - noted.atMs > maxGapMs) continue
            val adapter = StageCounterAdapter(sessionId, source, stage.metric, maxGapMs = maxGapMs)
            adapter.activate(activation)
            adapter.onCounter(noted.epoch, noted.value, noted.atMs) // the baseline: credits nothing
            adapters[source] = adapter
        }
    }

    companion object {
        private const val DEFAULT_MAX_GAP_MS = 5_000L

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
