package challenge

import challenge.engine.ChallengeEngine
import challenge.model.ChallengeDefinition
import challenge.model.ChallengeEvent
import challenge.model.ChallengeState
import challenge.model.CompletionEvidence
import challenge.model.CompletionPolicy
import challenge.model.ProgressMetric
import challenge.model.ProgressSample
import challenge.model.Refusal
import challenge.model.StageDefinition
import challenge.model.StageStatus
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

class EngineTest {
    private fun stage(id: String, metric: ProgressMetric, target: Double, policy: CompletionPolicy, vararg sources: String) =
        StageDefinition(id, metric, target, policy, sources.toSet())

    private val def = ChallengeDefinition(
        "hybrid", 1,
        listOf(
            stage("run-1", ProgressMetric.RUN_METERS, 1000.0, CompletionPolicy.AUTO, "gps-primary"),
            stage("sled", ProgressMetric.SLED_METERS, 50.0, CompletionPolicy.MANUAL, "manual"),
            stage("row", ProgressMetric.ROW_METERS, 1000.0, CompletionPolicy.SENSOR_OR_MANUAL, "pm5-rower"),
            stage("judged", ProgressMetric.REPS, 10.0, CompletionPolicy.JUDGE_REQUIRED, "manual"),
        ),
    )

    private fun engine(d: ChallengeDefinition = def): ChallengeEngine = ChallengeEngine(d, "s1").also { assertTrue(it.start(0).accepted) }

    private fun sample(e: ChallengeEngine, id: String, source: String, metric: ProgressMetric, delta: Double, at: Long, session: String = "s1", activation: Long = e.stageActivation()) =
        ProgressSample(id, session, activation, source, metric, delta, at)

    @Test fun theDefinitionRulesAreEnforced() {
        assertFailsWith<IllegalArgumentException> { StageDefinition("", ProgressMetric.REPS, 1.0, CompletionPolicy.AUTO, setOf("a")) }
        assertFailsWith<IllegalArgumentException> { StageDefinition("a", ProgressMetric.REPS, 0.0, CompletionPolicy.AUTO, setOf("a")) }
        assertFailsWith<IllegalArgumentException> { StageDefinition("a", ProgressMetric.REPS, 1.0, CompletionPolicy.AUTO, emptySet()) }
        assertFailsWith<IllegalArgumentException> { ChallengeDefinition("x", 1, emptyList()) }
        assertFailsWith<IllegalArgumentException> {
            ChallengeDefinition("x", 1, listOf(stage("a", ProgressMetric.REPS, 1.0, CompletionPolicy.AUTO, "m"), stage("a", ProgressMetric.REPS, 1.0, CompletionPolicy.AUTO, "m")))
        }
    }

    @Test fun startCreatesTheChallengeStartsItAndActivatesTheFirstStage() {
        val r = ChallengeEngine(def, "s1").start(1000)
        assertEquals(listOf(1L, 2L, 3L), r.events.map { it.seq })
        assertTrue(r.events[0] is ChallengeEvent.Created)
        assertTrue(r.events[2] is ChallengeEvent.StageActivated)
    }

    @Test fun anAutoStageCompletesWhenTheTargetIsReachedAndTheRestOfAProgressIsCapped() {
        val e = engine()
        assertTrue(e.accept(sample(e, "a", "gps-primary", ProgressMetric.RUN_METERS, 600.0, 10)).accepted)
        val done = e.accept(sample(e, "b", "gps-primary", ProgressMetric.RUN_METERS, 700.0, 20))
        val advanced = done.events.filterIsInstance<ChallengeEvent.ProgressAdvanced>().single()
        assertEquals(400.0, advanced.delta, 1e-9, "only what is needed to reach the target is credited")
        assertTrue(done.events.any { it is ChallengeEvent.TargetReached })
        assertTrue(done.events.any { it is ChallengeEvent.StageCompleted })
        val snap = e.snapshot(30)
        assertEquals(ChallengeState.TRANSITION, snap.state)
        assertEquals(1000.0, snap.completed.single().progress, 1e-9)
    }

    @Test fun aWrongInputIsRefusedWithItsReason() {
        val e = engine()
        assertEquals(Refusal.WRONG_SESSION, e.accept(sample(e, "a", "gps-primary", ProgressMetric.RUN_METERS, 5.0, 1, session = "other")).refusal)
        assertEquals(Refusal.STALE_ACTIVATION, e.accept(sample(e, "a", "gps-primary", ProgressMetric.RUN_METERS, 5.0, 1, activation = 99)).refusal)
        assertEquals(Refusal.WRONG_METRIC, e.accept(sample(e, "a", "gps-primary", ProgressMetric.ROW_METERS, 5.0, 1)).refusal)
        assertEquals(Refusal.SOURCE_NOT_ALLOWED, e.accept(sample(e, "a", "pm5-rower", ProgressMetric.RUN_METERS, 5.0, 1)).refusal)
        assertEquals(Refusal.BAD_EVENT_ID, e.accept(sample(e, " ", "gps-primary", ProgressMetric.RUN_METERS, 5.0, 1)).refusal)
        assertEquals(Refusal.BAD_DELTA, e.accept(sample(e, "a", "gps-primary", ProgressMetric.RUN_METERS, -5.0, 1)).refusal)
        assertEquals(Refusal.BAD_DELTA, e.accept(sample(e, "a", "gps-primary", ProgressMetric.RUN_METERS, Double.NaN, 1)).refusal)
        assertTrue(e.accept(sample(e, "a", "gps-primary", ProgressMetric.RUN_METERS, 5.0, 10)).accepted)
        assertEquals(Refusal.DUPLICATE, e.accept(sample(e, "a", "gps-primary", ProgressMetric.RUN_METERS, 5.0, 11)).refusal)
        assertEquals(Refusal.TIME_BACKWARDS, e.accept(sample(e, "b", "gps-primary", ProgressMetric.RUN_METERS, 5.0, 5)).refusal)
        assertEquals(5.0, e.snapshot(20).stageProgress, 1e-9)
    }

    @Test fun aManualStageNeedsAConfirmationAndANewStageNeedsAnExplicitNext() {
        val e = engine()
        e.accept(sample(e, "a", "gps-primary", ProgressMetric.RUN_METERS, 1000.0, 10))
        assertEquals(Refusal.WRONG_STATE, e.confirm(CompletionEvidence.MANUAL, 20).refusal, "a transition has no stage to confirm")
        assertTrue(e.nextStage(100).accepted)
        // the stale activation of the finished run cannot advance the sled
        assertEquals(Refusal.STALE_ACTIVATION, e.accept(sample(e, "late", "gps-primary", ProgressMetric.RUN_METERS, 30.0, 110, activation = 1)).refusal)
        assertEquals(Refusal.NOT_ALLOWED, e.confirm(CompletionEvidence.SENSOR, 120).refusal)
        val c = e.confirm(CompletionEvidence.MANUAL, 130)
        assertTrue(c.events.any { it is ChallengeEvent.StageCompleted })
        assertEquals(ChallengeState.TRANSITION, e.currentState)
    }

    @Test fun aSensorOrManualStageTakesEitherAndAJudgedStageOnlyTheJudge() {
        val e = engine()
        e.accept(sample(e, "a", "gps-primary", ProgressMetric.RUN_METERS, 1000.0, 10)); e.nextStage(20)
        e.confirm(CompletionEvidence.MANUAL, 30); e.nextStage(40)
        // row: reaches the target by sensor, but SENSOR_OR_MANUAL waits for a confirmation
        e.accept(sample(e, "r", "pm5-rower", ProgressMetric.ROW_METERS, 1000.0, 50))
        assertEquals(StageStatus.TARGET_REACHED, e.snapshot(60).stageStatus)
        assertEquals(Refusal.TARGET_REACHED, e.accept(sample(e, "r2", "pm5-rower", ProgressMetric.ROW_METERS, 5.0, 55)).refusal)
        e.confirm(CompletionEvidence.MANUAL, 60); e.nextStage(70)
        assertEquals(Refusal.NOT_ALLOWED, e.confirm(CompletionEvidence.MANUAL, 80).refusal)
        val judged = e.confirm(CompletionEvidence.JUDGE, 90)
        assertTrue(judged.events.any { it is ChallengeEvent.Completed })
        assertEquals(ChallengeState.COMPLETED, e.currentState)
        assertEquals(CompletionEvidence.JUDGE, e.snapshot(100).completed.last().evidence)
        assertEquals(4, e.snapshot(100).completed.size)
        assertEquals(Refusal.WRONG_STATE, e.nextStage(200).refusal, "a completed challenge never runs a stage again")
    }

    @Test fun theTotalTimeKeepsTheTransitionsTheStageTimeFreezesAndAPauseIsInNeither() {
        val e = engine()
        e.accept(sample(e, "a", "gps-primary", ProgressMetric.RUN_METERS, 1000.0, 100_000)) // run done at 100 s
        assertEquals(100_000L, e.snapshot(500_000).completed.single().durationMs)
        assertEquals(500_000L, e.snapshot(500_000).totalElapsedMs, "the transition is in the total")
        e.nextStage(130_000) // 30 s of transition
        e.pause(140_000)
        val paused = e.snapshot(900_000)
        assertEquals(140_000L, paused.totalElapsedMs, "the clock stops while paused")
        e.resume(200_000) // 60 s paused
        val s = e.snapshot(230_000)
        assertEquals(170_000L, s.totalElapsedMs)
        assertEquals(40_000L, s.stageElapsedMs, "10 s before the pause + 30 s after it")
    }

    @Test fun aPauseCanBeForbiddenByTheDefinition() {
        val d = ChallengeDefinition("race", 1, listOf(stage("a", ProgressMetric.REPS, 5.0, CompletionPolicy.AUTO, "m")), allowPause = false)
        val e = engine(d)
        assertEquals(Refusal.PAUSE_NOT_ALLOWED, e.pause(10).refusal)
        assertEquals(ChallengeState.ACTIVE, e.currentState)
    }

    @Test fun inputsAfterTheEndOrBeforeTheStartAreRefused() {
        val e = ChallengeEngine(def, "s1")
        assertEquals(Refusal.WRONG_STATE, e.confirm(CompletionEvidence.MANUAL, 0).refusal)
        assertEquals(Refusal.WRONG_STATE, e.nextStage(0).refusal)
        assertEquals(Refusal.WRONG_STATE, e.pause(0).refusal)
        assertEquals(Refusal.TIME_BACKWARDS, e.start(-1).refusal)
        e.start(0)
        assertEquals(Refusal.WRONG_STATE, e.start(1).refusal)
        assertNotNull(e.snapshot(5))
    }
}
