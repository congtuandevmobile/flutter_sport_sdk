package challenge

import challenge.model.ChallengeDefinition
import challenge.model.CompletionEvidence
import challenge.model.CompletionPolicy
import challenge.model.ProgressMetric
import challenge.model.Refusal
import challenge.model.StageDefinition
import challenge.session.ChallengeSession
import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * Additional RED tests against 47e98d2. Place in:
 * packages/flutter_challenge/challenge-core/src/commonTest/kotlin/challenge/RaceIntegrityRegressionTest.kt
 *
 * Desired contract: event time (not arrival time) determines stage/pause ownership.
 * These intentionally expose gaps not covered by RegressionTest.kt at the reviewed HEAD.
 */
class RaceIntegrityRegressionTest {
    private fun stage(id: String, metric: ProgressMetric, target: Double, policy: CompletionPolicy, vararg sources: String) =
        StageDefinition(id, metric, target, policy, sources.toCollection(LinkedHashSet()))

    @Test
    fun manualMeasurementCreatedDuringPauseMustNotAdvanceAfterResume() {
        val definition = ChallengeDefinition(
            "late-manual", 1,
            listOf(stage("wall-balls", ProgressMetric.REPS, 10.0, CompletionPolicy.MANUAL, "manual")),
        )
        val session = ChallengeSession(definition, "s")
        session.start(0)
        val activation = session.snapshot(0).stageActivation
        session.pause(2_000)
        session.resume(5_000)

        // Callback arrived after resume, but the action occurred while paused.
        val result = session.onDelta("manual", "paused-tap", 3.0, 3_000, activation)
        assertEquals(Refusal.TIME_BACKWARDS, result.refusal)
        assertEquals(0.0, session.snapshot(5_000).stageProgress, 0.0)
    }

    @Test
    fun bufferedGpsSamplesFromPauseMustNotCreateProgressAfterResume() {
        val definition = ChallengeDefinition(
            "late-gps", 1,
            listOf(stage("run", ProgressMetric.RUN_METERS, 1_000.0, CompletionPolicy.AUTO, "gps")),
        )
        val session = ChallengeSession(definition, "s")
        session.start(0)
        session.onCounter("gps", 1, 100.0, 0)
        session.pause(2_000)
        session.onCounter("gps", 1, 120.0, 3_000)
        session.resume(5_000)

        // Both GPS samples were measured during the pause, but are delivered AFTER resume.
        session.onCounter("gps", 1, 125.0, 3_500)
        session.onCounter("gps", 1, 130.0, 4_500)
        assertEquals(0.0, session.snapshot(5_100).stageProgress, 0.0)

        // After resume: first fresh post-resume sample is a baseline.
        session.onCounter("gps", 1, 140.0, 5_500)
        session.onCounter("gps", 1, 145.0, 6_500)
        assertEquals(5.0, session.snapshot(6_500).stageProgress, 1e-9)
    }

    @Test
    fun stageTwoMustNotCreditDistanceSpanningThePreviousStage() {
        val definition = ChallengeDefinition(
            "stage-boundary", 1,
            listOf(
                stage("first", ProgressMetric.REPS, 1.0, CompletionPolicy.MANUAL, "manual"),
                stage("row", ProgressMetric.ROW_METERS, 1_000.0, CompletionPolicy.AUTO, "rower"),
            ),
        )
        val session = ChallengeSession(definition, "s")
        session.start(0)
        session.onCounter("rower", 1, 100.0, 1_000) // rower was already measuring BEFORE stage 2
        session.onDelta("manual", "finish-first", 1.0, 2_000)
        session.confirm(CompletionEvidence.MANUAL, 2_500)
        session.nextStage(3_000)

        session.onCounter("rower", 1, 120.0, 4_000)
        // 100->120 spanned 1000..4000. Only 3000..4000 belongs to this stage;
        // no 3000 counter is available, so safest result is 0 on first post-activation sample.
        assertEquals(0.0, session.snapshot(4_000).stageProgress, 0.0)
        session.onCounter("rower", 1, 125.0, 5_000)
        assertEquals(5.0, session.snapshot(5_000).stageProgress, 1e-9)
    }

    @Test
    fun sensorMeasurementDatedBeforeStageStartMustNotBecomeBaseline() {
        val definition = ChallengeDefinition(
            "delayed-stage-boundary", 1,
            listOf(
                stage("first", ProgressMetric.REPS, 1.0, CompletionPolicy.MANUAL, "manual"),
                stage("row", ProgressMetric.ROW_METERS, 1_000.0, CompletionPolicy.AUTO, "rower"),
            ),
        )
        val session = ChallengeSession(definition, "s")
        session.start(0)
        session.onDelta("manual", "finish-first", 1.0, 1_000)
        session.confirm(CompletionEvidence.MANUAL, 2_000)
        session.nextStage(3_000)

        session.onCounter("rower", 1, 100.0, 2_500) // delivered late, captured before stage start
        session.onCounter("rower", 1, 110.0, 4_000) // first legitimate stage-2 reading
        assertEquals(0.0, session.snapshot(4_000).stageProgress, 0.0)
        session.onCounter("rower", 1, 115.0, 5_000)
        assertEquals(5.0, session.snapshot(5_000).stageProgress, 1e-9)
    }
}
