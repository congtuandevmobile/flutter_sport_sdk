package challenge

import challenge.model.ChallengeDefinition
import challenge.model.ChallengeState
import challenge.model.CompletionEvidence
import challenge.model.CompletionPolicy
import challenge.model.ProgressMetric
import challenge.model.Refusal
import challenge.model.StageDefinition
import challenge.session.ChallengeSession
import kotlin.test.Test
import kotlin.test.assertEquals

/** Regression tests for the review findings: pause baselines, one active source, stale manual callbacks and confirmations. */
class RegressionTest {
    private fun stage(id: String, metric: ProgressMetric, target: Double, policy: CompletionPolicy, vararg sources: String) =
        StageDefinition(id, metric, target, policy, sources.toCollection(LinkedHashSet()))

    private val run = ChallengeDefinition(
        "run", 1, listOf(stage("run", ProgressMetric.RUN_METERS, 1000.0, CompletionPolicy.AUTO, "gps")),
    )

    @Test fun movementWhilePausedIsNeverCreditedEvenAfterAShortPause() {
        val s = ChallengeSession(run, "p")
        s.start(0)
        s.onCounter("gps", 1, 100.0, 0)
        s.onCounter("gps", 1, 110.0, 2000)
        s.pause(3000)
        s.onCounter("gps", 1, 120.0, 4000) // moved 10 m while paused
        s.resume(5000)
        s.onCounter("gps", 1, 125.0, 6000) // the first sample after the resume is a new baseline
        assertEquals(10.0, s.snapshot(6000).stageProgress, 1e-9, "only the 10 m before the pause")
        s.onCounter("gps", 1, 130.0, 7000)
        assertEquals(15.0, s.snapshot(7000).stageProgress, 1e-9, "counting again from the new baseline")
    }

    @Test fun aPauseThatChangesNothingKeepsTheBaselines() {
        val s = ChallengeSession(run, "p2")
        s.start(0)
        s.onCounter("gps", 1, 100.0, 0)
        s.onCounter("gps", 1, 110.0, 1000)
        assertEquals(Refusal.WRONG_STATE, s.resume(1500).refusal) // not paused: nothing happens
        s.onCounter("gps", 1, 120.0, 2000)
        assertEquals(20.0, s.snapshot(2000).stageProgress, 1e-9)
    }

    private val two = ChallengeDefinition(
        "two", 1, listOf(stage("run", ProgressMetric.RUN_METERS, 1000.0, CompletionPolicy.AUTO, "gps", "footpod")),
    )

    @Test fun twoSensorsOnTheSameMovementAreNeverAddedTogether() {
        val s = ChallengeSession(two, "x")
        s.start(0)
        s.onCounter("gps", 1, 100.0, 0)
        s.onCounter("footpod", 1, 500.0, 0)
        for (i in 1..10) {
            s.onCounter("gps", 1, 100.0 + i * 10, i * 1000L)
            s.onCounter("footpod", 1, 500.0 + i * 10, i * 1000L + 100)
        }
        assertEquals(100.0, s.snapshot(10_100).stageProgress, 1e-9, "100 m of movement is 100 m, not 200")
    }

    @Test fun whenTheActiveSourceGoesSilentTheNextOneTakesOverFromItsOwnBaseline() {
        val s = ChallengeSession(two, "y")
        s.start(0)
        s.onCounter("gps", 1, 100.0, 0)
        s.onCounter("footpod", 1, 500.0, 0)
        for (i in 1..5) {
            s.onCounter("gps", 1, 100.0 + i * 10, i * 1000L)
            s.onCounter("footpod", 1, 500.0 + i * 10, i * 1000L)
        }
        assertEquals(50.0, s.snapshot(5000).stageProgress, 1e-9)
        // the GPS goes silent; the footpod keeps counting
        for (i in 6..20) s.onCounter("footpod", 1, 500.0 + i * 10, i * 1000L)
        // the footpod credits again once the GPS is stale (> 5 s): the seconds before that are not credited by anybody
        val progress = s.snapshot(20_000).stageProgress
        assertEquals(true, progress > 50.0 && progress <= 150.0, "progress=$progress")
        // and the footpod's own total (about 700) was never assigned to the stage
        assertEquals(true, progress < 200.0)
    }

    private val three = ChallengeDefinition(
        "three", 1, listOf(stage("run", ProgressMetric.RUN_METERS, 1000.0, CompletionPolicy.AUTO, "gps", "footpod", "treadmill")),
    )

    @Test fun whenTheActiveSourceGoesStaleTheFirstFreshSourceOfTheListTakesOverAndItsFirstDeltaCreditsNothing() {
        val s = ChallengeSession(three, "z")
        s.start(0)
        s.onCounter("treadmill", 1, 0.0, 0) // the first to report: baseline, then the active source
        s.onCounter("treadmill", 1, 10.0, 1000)
        s.onCounter("gps", 1, 100.0, 1000) // tracked, never credited while the treadmill is fresh
        s.onCounter("footpod", 1, 500.0, 1000)
        assertEquals(10.0, s.snapshot(1000).stageProgress, 1e-9)
        s.onCounter("gps", 1, 120.0, 6000)
        s.onCounter("footpod", 1, 520.0, 6000)
        s.onCounter("gps", 1, 130.0, 6500) // the treadmill is stale (5.5 s): the GPS has the priority over the footpod and takes over
        assertEquals(10.0, s.snapshot(6500).stageProgress, 1e-9, "the first delta of the new source is not credited")
        s.onCounter("footpod", 1, 530.0, 7000) // the GPS is active and fresh: the footpod is discarded
        s.onCounter("gps", 1, 140.0, 7500)
        assertEquals(20.0, s.snapshot(7500).stageProgress, 1e-9)
        s.onCounter("footpod", 1, 540.0, 8000)
        assertEquals(20.0, s.snapshot(8000).stageProgress, 1e-9)
    }

    private val sleds = ChallengeDefinition(
        "wb", 1,
        listOf(
            stage("wb-1", ProgressMetric.REPS, 10.0, CompletionPolicy.MANUAL, "tap"),
            stage("wb-2", ProgressMetric.REPS, 10.0, CompletionPolicy.MANUAL, "tap"),
        ),
    )

    @Test fun aManualTapMadeInAnOldStageNeverAdvancesTheNextOne() {
        val s = ChallengeSession(sleds, "w")
        s.start(0)
        val activation = s.snapshot(0).stageActivation
        s.onDelta("tap", "t1", 10.0, 1000, activation)
        s.confirm(CompletionEvidence.MANUAL, 2000)
        s.nextStage(3000)
        assertEquals(ChallengeState.ACTIVE, s.snapshot(3000).state)
        val late = s.onDelta("tap", "t2", 1.0, 3100, activation) // the callback of stage 1 arrives in stage 2
        assertEquals(Refusal.STALE_ACTIVATION, late.refusal)
        assertEquals(0.0, s.snapshot(3100).stageProgress, 1e-9)
        // the same event id for the CURRENT stage is a different, valid measurement
        s.onDelta("tap", "t1", 1.0, 3200, s.snapshot(3200).stageActivation)
        assertEquals(1.0, s.snapshot(3200).stageProgress, 1e-9)
    }

    @Test fun aLateConfirmationForAnOldStageCompletesNothing() {
        val s = ChallengeSession(sleds, "c")
        s.start(0)
        val activation = s.snapshot(0).stageActivation
        s.onDelta("tap", "t1", 10.0, 1000, activation)
        s.confirm(CompletionEvidence.MANUAL, 2000, activation)
        s.nextStage(3000)
        val late = s.confirm(CompletionEvidence.MANUAL, 3100, activation)
        assertEquals(Refusal.STALE_ACTIVATION, late.refusal)
        assertEquals(1, s.snapshot(3100).completed.size, "stage 2 is still running")
    }

    @Test fun aCallWithoutAnActivationStillMeansTheCurrentStage() {
        val s = ChallengeSession(sleds, "d")
        s.start(0)
        assertEquals(null, s.onDelta("tap", "t1", 3.0, 100).refusal)
        assertEquals(3.0, s.snapshot(100).stageProgress, 1e-9)
    }
}
