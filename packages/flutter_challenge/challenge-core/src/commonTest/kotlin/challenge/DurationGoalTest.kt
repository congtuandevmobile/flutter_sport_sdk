package challenge

import challenge.journal.ChallengeJournal
import challenge.model.ChallengeDefinition
import challenge.model.ChallengeEvent
import challenge.model.ChallengeState
import challenge.model.CompletionEvidence
import challenge.model.CompletionPolicy
import challenge.model.ProgressMetric
import challenge.model.Refusal
import challenge.model.StageDefinition
import challenge.model.StageStatus
import challenge.session.ChallengeSession
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

/** A stage whose goal is TIME: the engine completes it by its own clock, a pause is not in it, and the result survives a replay. */
class DurationGoalTest {
    private fun timed(id: String, seconds: Double, policy: CompletionPolicy = CompletionPolicy.AUTO) =
        StageDefinition(id, ProgressMetric.DURATION, seconds, policy, emptySet())

    private fun single(seconds: Double, policy: CompletionPolicy = CompletionPolicy.AUTO) =
        ChallengeDefinition("t", 1, listOf(timed("football", seconds, policy)))

    @Test fun aTimedStageCompletesWhenItsActiveTimeIsReachedAndTheEvidenceIsTheTimer() {
        val s = ChallengeSession(single(10.0), "s")
        s.start(0)
        assertTrue(s.tick(9_999).events.isEmpty(), "not yet")
        assertEquals(4.0, s.snapshot(4_000).stageProgress, 1e-9, "the clock is the progress, in seconds")
        // the tick comes late (12.3 s): the stage still completed AT 10 s
        val result = s.tick(12_300)
        val completed = result.events.filterIsInstance<ChallengeEvent.StageCompleted>().single()
        assertEquals(CompletionEvidence.TIMER, completed.evidence)
        assertEquals(10_000L, completed.atMs)
        val snap = s.snapshot(12_300)
        assertEquals(ChallengeState.COMPLETED, snap.state)
        assertEquals(10_000L, snap.completed.single().durationMs)
        assertEquals(10.0, snap.completed.single().progress, 1e-9)
        assertEquals(10_000L, snap.totalElapsedMs, "the total stops where the last stage ended")
    }

    @Test fun aPauseIsNotInTheTime() {
        val s = ChallengeSession(single(10.0), "s")
        s.start(0)
        s.pause(4_000)
        assertTrue(s.tick(30_000).events.isEmpty(), "a paused challenge does not run out of time")
        s.resume(20_000) // 16 s paused: 4 s done, 6 s to go
        assertTrue(s.tick(25_999).events.isEmpty())
        val completed = s.tick(26_500).events.filterIsInstance<ChallengeEvent.StageCompleted>().single()
        assertEquals(26_000L, completed.atMs)
        assertEquals(10_000L, s.snapshot(26_500).completed.single().durationMs)
    }

    @Test fun aPauseThatComesAfterTheTimeRanOutSettlesTheStageFirst() {
        val def = ChallengeDefinition("t", 1, listOf(timed("a", 10.0), timed("b", 10.0)))
        val s = ChallengeSession(def, "s")
        s.start(0)
        // nobody ticked; the user pauses at 15 s: stage a was over at 10 s and the pause must not stretch it
        val r = s.pause(15_000)
        assertEquals(null, r.refusal)
        val completed = r.events.filterIsInstance<ChallengeEvent.StageCompleted>().single()
        assertEquals(10_000L, completed.atMs)
        assertTrue(r.events.last() is ChallengeEvent.Paused)
        assertEquals(10_000L, s.snapshot(15_000).completed.single().durationMs)
        assertEquals(ChallengeState.PAUSED, s.snapshot(15_000).state)
    }

    @Test fun aManualTimedStageWaitsForTheConfirmationAndRecordsTheTimeItRan() {
        val s = ChallengeSession(single(10.0, CompletionPolicy.MANUAL), "s")
        s.start(0)
        s.tick(12_000)
        val reached = s.snapshot(12_000)
        assertEquals(StageStatus.TARGET_REACHED, reached.stageStatus)
        assertEquals(10.0, reached.stageProgress, 1e-9)
        s.confirm(CompletionEvidence.MANUAL, 13_000)
        assertEquals(ChallengeState.COMPLETED, s.snapshot(13_000).state)
        assertEquals(10.0, s.snapshot(13_000).completed.single().progress, 1e-9)
    }

    @Test fun aTimedStageConfirmedEarlyRecordsTheTimeItReallyRan() {
        val s = ChallengeSession(single(60.0, CompletionPolicy.MANUAL), "s")
        s.start(0)
        s.confirm(CompletionEvidence.MANUAL, 7_500)
        assertEquals(7.5, s.snapshot(7_500).completed.single().progress, 1e-9)
        assertEquals(7_500L, s.snapshot(7_500).completed.single().durationMs)
    }

    @Test fun aTimedStageTakesNoMeasurementsAndNeedsNoSources() {
        val s = ChallengeSession(single(10.0), "s")
        s.start(0)
        s.onCounter("gps", 1, 100.0, 1_000)
        s.onCounter("gps", 1, 150.0, 2_000)
        assertEquals(Refusal.SOURCE_NOT_ALLOWED, s.onDelta("gps", "e1", 5.0, 3_000).refusal)
        assertEquals(3.0, s.snapshot(3_000).stageProgress, 1e-9, "only the clock moves it")
    }

    @Test fun aStageOfADistanceStillNeedsItsSources() {
        val ok = runCatching { StageDefinition("run", ProgressMetric.RUN_METERS, 1000.0, CompletionPolicy.AUTO, emptySet()) }
        assertTrue(ok.isFailure)
    }

    @Test fun aRaceMixesDistanceAndTimeStages() {
        val def = ChallengeDefinition(
            "mix", 1,
            listOf(
                StageDefinition("run", ProgressMetric.RUN_METERS, 100.0, CompletionPolicy.AUTO, setOf("gps")),
                timed("football", 600.0),
            ),
        )
        val s = ChallengeSession(def, "s")
        s.start(0)
        s.onCounter("gps", 1, 0.0, 0)
        for (i in 1..10) s.onCounter("gps", 1, i * 10.0, i * 1_000L)
        assertEquals(ChallengeState.TRANSITION, s.snapshot(10_000).state)
        s.nextStage(15_000)
        assertEquals(0.0, s.snapshot(15_000).stageProgress, 1e-9)
        s.tick(15_000 + 599_999)
        assertEquals(ChallengeState.ACTIVE, s.snapshot(615_000).state)
        s.tick(15_000 + 600_000)
        assertEquals(ChallengeState.COMPLETED, s.snapshot(615_000).state)
        assertEquals(2, s.snapshot(615_000).completed.size)
    }

    @Test fun theJournalCarriesATimedStageAndAReplayGivesTheSameChallenge() {
        val def = ChallengeDefinition("t", 1, listOf(timed("a", 10.0), timed("b", 60.0)))
        val s = ChallengeSession(def, "s")
        val lines = ArrayList<String>()
        fun log(r: challenge.model.ChallengeResult) { r.events.forEach { lines += ChallengeJournal.encode(it) } }
        log(s.start(0))
        log(s.tick(10_000)) // a completes
        log(s.nextStage(12_000))
        for (t in 13..35) log(s.tick(t * 1_000L)) // checkpoints at 22 s and 32 s
        // the process dies at ~35 s; the journal is all that is left
        val recovered = assertNotNull(ChallengeJournal.recover(lines))
        val r = recovered.restored.session
        assertEquals(ChallengeState.PAUSED, r.snapshot(35_000).state)
        assertEquals(1, r.snapshot(35_000).completed.size)
        assertEquals(10_000L, r.snapshot(35_000).completed[0].durationMs)
        assertEquals(CompletionEvidence.TIMER, r.snapshot(35_000).completed[0].evidence)
        assertEquals(20.0, r.snapshot(35_000).stageProgress, 1e-9, "stage b had run 20 s at the last checkpoint (32 s): at most 10 s are lost")
        // after the resume the clock goes on from there: the dead time is not in it
        r.resume(100_000)
        assertTrue(r.tick(139_999).events.none { it is ChallengeEvent.StageCompleted }, "only a checkpoint, not the end")
        r.tick(140_000)
        assertEquals(ChallengeState.COMPLETED, r.snapshot(140_000).state)
    }

    @Test fun aCheckpointIsOnlyLeftByARunningTimedStageAndNeverMovesTheClock() {
        val s = ChallengeSession(single(3600.0), "s")
        s.start(0)
        assertTrue(s.tick(9_999).events.isEmpty())
        val cp = s.tick(10_000).events.single()
        assertTrue(cp is ChallengeEvent.Checkpoint)
        assertTrue(s.tick(15_000).events.isEmpty(), "the next one is 10 s later")
        assertEquals(15.0, s.snapshot(15_000).stageProgress, 1e-9)
        s.pause(16_000)
        assertTrue(s.tick(60_000).events.isEmpty(), "no checkpoint while paused")
        // a distance stage leaves none
        val run = ChallengeSession(
            ChallengeDefinition("r", 1, listOf(StageDefinition("run", ProgressMetric.RUN_METERS, 100.0, CompletionPolicy.AUTO, setOf("gps")))), "r",
        )
        run.start(0)
        assertTrue(run.tick(60_000).events.isEmpty())
    }
}
