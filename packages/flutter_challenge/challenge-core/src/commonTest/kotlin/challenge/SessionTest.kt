package challenge

import challenge.model.ChallengeDefinition
import challenge.model.ChallengeEvent
import challenge.model.ChallengeState
import challenge.model.CompletionEvidence
import challenge.model.CompletionPolicy
import challenge.model.ProgressMetric
import challenge.model.Refusal
import challenge.model.StageDefinition
import challenge.session.ChallengeSession
import challenge.session.StageCounterAdapter
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

class SessionTest {
    private fun stage(id: String, metric: ProgressMetric, target: Double, policy: CompletionPolicy, vararg sources: String) =
        StageDefinition(id, metric, target, policy, sources.toSet())

    private val def = ChallengeDefinition(
        "hybrid", 1,
        listOf(
            stage("run-1", ProgressMetric.RUN_METERS, 1000.0, CompletionPolicy.AUTO, "gps-primary"),
            stage("sled", ProgressMetric.SLED_METERS, 50.0, CompletionPolicy.MANUAL, "manual"),
            stage("row", ProgressMetric.ROW_METERS, 1000.0, CompletionPolicy.SENSOR_OR_MANUAL, "pm5-rower"),
            stage("run-2", ProgressMetric.RUN_METERS, 1000.0, CompletionPolicy.AUTO, "gps-primary"),
        ),
    )

    /** A GPS that keeps counting the whole time: 10 m per second, 5 m between the samples of a second. */
    private class Gps(val session: ChallengeSession, var total: Double, var t: Long) {
        fun run(seconds: Int) { repeat(seconds) { t += 1000; total += 10.0; session.onCounter("gps-primary", 1, total, t) } }
    }

    @Test fun theStarterScenarioRunSledRowRunWithGpsCountingTheWholeTime() {
        val s = ChallengeSession(def, "s1")
        s.start(0)
        val gps = Gps(s, 10_000.0, 0)
        s.onCounter("gps-primary", 1, 10_000.0, 0) // the GPS already had a total before the challenge
        gps.run(100) // run 1: 1000 m
        assertEquals(ChallengeState.TRANSITION, s.snapshot(gps.t).state)
        assertEquals(1000.0, s.snapshot(gps.t).completed[0].progress, 1e-9)
        s.nextStage(gps.t + 10_000)
        gps.run(60) // GPS keeps running at the sled station: 600 m that count for NOTHING
        assertEquals(0.0, s.snapshot(gps.t).stageProgress, 1e-9, "a run counter cannot advance the sled")
        s.onDelta("manual", "sled-1", 25.0, gps.t + 1000)
        s.onDelta("manual", "sled-2", 25.0, gps.t + 2000)
        s.confirm(CompletionEvidence.MANUAL, gps.t + 3000)
        s.nextStage(gps.t + 20_000)
        // the rower reports its own counter; the footpod's/GPS's counters cannot complete the row stage
        s.onCounter("pm5-rower", 5, 500.0, gps.t + 21_000)
        var rt = gps.t + 21_000
        repeat(125) { rt += 1000; s.onCounter("pm5-rower", 5, 500.0 + (it + 1) * 8.0, rt); gps.total += 10; s.onCounter("gps-primary", 1, gps.total, rt) }
        assertEquals(1000.0, s.snapshot(rt).stageProgress, 1e-9, "the row stage only counts the rower")
        s.confirm(CompletionEvidence.MANUAL, rt + 500)
        // run 2 starts 40 s later: the GPS distance covered meanwhile is NOT credited to it
        s.nextStage(rt + 40_000)
        val gps2 = Gps(s, gps.total + 400.0, rt + 40_000)
        s.onCounter("gps-primary", 1, gps2.total, gps2.t)
        gps2.run(25)
        assertEquals(250.0, s.snapshot(gps2.t).stageProgress, 1e-9, "250 m, not the whole GPS total since run 1")
        gps2.run(75)
        val end = s.snapshot(gps2.t)
        assertEquals(ChallengeState.COMPLETED, end.state)
        assertEquals(4, end.completed.size)
        assertEquals(1000.0, end.completed[0].progress, 1e-9)
        assertEquals(1000.0, end.completed[3].progress, 1e-9)
    }

    @Test fun aNewStageStartsFromTheLastFreshCounterNotFromTheNextSample() {
        val s = ChallengeSession(def, "s1")
        s.start(0)
        s.onCounter("gps-primary", 1, 0.0, 0)
        for (i in 1..100) s.onCounter("gps-primary", 1, i * 10.0, i * 1000L)
        s.nextStage(101_000); s.confirm(CompletionEvidence.MANUAL, 102_000); s.nextStage(103_000)
        s.confirm(CompletionEvidence.MANUAL, 104_000) // row is SENSOR_OR_MANUAL: skipped by hand
        s.nextStage(105_000) // run 2
        s.onCounter("gps-primary", 1, 1000.0 + 1000 + 10.0, 106_000)
        // the GPS counter noted at 100 s is too old (> 5 s) to seed: the first fresh sample is the baseline
        assertEquals(0.0, s.snapshot(106_000).stageProgress, 1e-9)
        s.onCounter("gps-primary", 1, 2020.0, 107_000)
        assertEquals(10.0, s.snapshot(107_000).stageProgress, 1e-9)
    }

    // POLICY (strict, for races): from two totals around the stage boundary there is no way to know how much of the difference was
    // covered after it, so a counter seen BEFORE the activation is never used. The first sample of the stage is only a baseline: the
    // distance before it is not credited (an approximation that never gives a stage metres it cannot prove).
    @Test fun aStageThatStartsRightAfterASampleStillStartsFromItsOwnFirstSample() {
        val s = ChallengeSession(def, "s1")
        s.start(0)
        s.onCounter("gps-primary", 1, 0.0, 0)
        for (i in 1..100) s.onCounter("gps-primary", 1, i * 10.0, i * 1000L)
        s.nextStage(100_500); s.confirm(CompletionEvidence.MANUAL, 100_600); s.nextStage(100_700)
        s.confirm(CompletionEvidence.MANUAL, 100_800); s.nextStage(100_900) // run 2 starts 0.9 s after the last GPS sample
        s.onCounter("gps-primary", 1, 1010.0, 101_000) // the baseline of the stage: the sample at 100 s is NOT used
        assertEquals(0.0, s.snapshot(101_000).stageProgress, 1e-9, "the distance before the first sample of the stage is not credited")
        s.onCounter("gps-primary", 1, 1020.0, 102_000)
        assertEquals(10.0, s.snapshot(102_000).stageProgress, 1e-9)
    }

    @Test fun aSourceThatIsNotAllowedForTheStageNeverAdvancesIt() {
        val s = ChallengeSession(def, "s1")
        s.start(0)
        s.onCounter("pm5-rower", 1, 0.0, 0)
        s.onCounter("pm5-rower", 1, 8.0, 1000)
        assertEquals(0.0, s.snapshot(1000).stageProgress, 0.0)
        val r = s.onDelta("pm5-rower", "x", 5.0, 1100)
        assertEquals(Refusal.SOURCE_NOT_ALLOWED, r.refusal)
    }

    @Test fun aManualDeltaWithTheSameEventIdIsNeverCountedTwice() {
        val s = ChallengeSession(def, "s1")
        s.start(0)
        for (i in 0..100) s.onCounter("gps-primary", 1, i * 10.0, i * 1000L)
        s.nextStage(101_000)
        assertTrue(s.onDelta("manual", "tap-1", 5.0, 102_000).accepted)
        assertEquals(Refusal.DUPLICATE, s.onDelta("manual", "tap-1", 5.0, 103_000).refusal)
        assertEquals(5.0, s.snapshot(103_000).stageProgress, 1e-9)
    }

    // ---- the adapter ----

    @Test fun theAdapterBaselinesRejectsGapsSpikesAndResets() {
        val a = StageCounterAdapter("s", "gps", ProgressMetric.RUN_METERS)
        a.activate(1)
        assertNull(a.onCounter(1, 1000.0, 0), "the first sample is a baseline")
        assertEquals(10.0, a.onCounter(1, 1010.0, 1000)!!.delta, 1e-9)
        assertNull(a.onCounter(1, 1020.0, 1000), "a duplicate time is ignored")
        assertNull(a.onCounter(1, 1030.0, 30_000), "a gap of lost data is not credited")
        assertNull(a.onCounter(1, 5000.0, 31_000), "a jump faster than a runner can go")
        assertNull(a.onCounter(1, 10.0, 32_000), "a counter that went back")
        assertEquals(10.0, a.onCounter(1, 20.0, 33_000)!!.delta, 1e-9)
        assertNull(a.onCounter(2, 5.0, 34_000), "a new connection is a new baseline")
        assertNull(a.onCounter(1, 6.0, 35_000), "an older epoch is ignored")
    }

    @Test fun anEventIdIsTheSameForTheSameMeasurement() {
        val a = StageCounterAdapter("s", "gps", ProgressMetric.RUN_METERS)
        val b = StageCounterAdapter("s", "gps", ProgressMetric.RUN_METERS)
        a.activate(1); b.activate(1)
        a.onCounter(1, 0.0, 0); b.onCounter(1, 0.0, 0)
        assertEquals(a.onCounter(1, 10.0, 1000)!!.eventId, b.onCounter(1, 10.0, 1000)!!.eventId)
    }

    @Test fun theRowerAndTheFootpodAreTwoSourcesWithTheirOwnCounters() {
        val s = ChallengeSession(def, "s1")
        s.start(0)
        for (i in 0..100) s.onCounter("gps-primary", 1, i * 10.0, i * 1000L)
        s.nextStage(101_000); s.confirm(CompletionEvidence.MANUAL, 102_000); s.nextStage(103_000)
        // both report "total distance"; only the rower is allowed to advance the row stage
        s.onCounter("footpod", 1, 1500.0, 103_000)
        s.onCounter("pm5-rower", 4, 850.0, 103_000)
        for (i in 1..10) {
            s.onCounter("footpod", 1, 1500.0 + i * 3, 103_000L + i * 1000)
            s.onCounter("pm5-rower", 4, 850.0 + i * 5, 103_000L + i * 1000)
        }
        assertEquals(50.0, s.snapshot(113_000).stageProgress, 1e-9)
    }

    @Test fun noEventAppearsAfterAnInputThatDidNothing() {
        val s = ChallengeSession(def, "s1")
        assertTrue(s.onCounter("gps-primary", 1, 5.0, 0).events.isEmpty(), "before the start nothing counts")
        s.start(0)
        val r = s.onCounter("gps-primary", 1, 5.0, 1000)
        assertTrue(r.events.none { it is ChallengeEvent.ProgressAdvanced })
    }
}
