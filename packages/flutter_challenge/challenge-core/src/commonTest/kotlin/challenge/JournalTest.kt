package challenge

import challenge.journal.ChallengeJournal
import challenge.journal.JournalStatus
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
import kotlin.test.assertNull
import kotlin.test.assertTrue

class JournalTest {
    private val def = ChallengeDefinition(
        "id|with,odd%chars", 3,
        listOf(
            StageDefinition("run", ProgressMetric.RUN_METERS, 1000.0, CompletionPolicy.AUTO, setOf("gps-primary", "gps,backup")),
            StageDefinition("sled", ProgressMetric.SLED_METERS, 50.0, CompletionPolicy.MANUAL, setOf("manual")),
            StageDefinition("row", ProgressMetric.ROW_METERS, 1000.0, CompletionPolicy.SENSOR_OR_MANUAL, setOf("pm5-rower")),
        ),
        allowPause = false,
    )

    /** A challenge half done, as the lines its journal holds: run done, sled done, row at 400 m. */
    private fun workout(): Pair<ChallengeSession, List<String>> {
        val s = ChallengeSession(def, "sess|1")
        val events = ArrayList<ChallengeEvent>()
        events += s.start(0).events
        events += s.onCounter("gps-primary", 1, 5000.0, 0).events
        for (i in 1..100) events += s.onCounter("gps-primary", 1, 5000.0 + i * 10, i * 1000L).events
        events += s.nextStage(101_000).events
        events += s.onDelta("manual", "tap|1", 50.0, 102_000).events
        events += s.confirm(CompletionEvidence.MANUAL, 103_000).events
        events += s.nextStage(104_000).events
        events += s.onCounter("pm5-rower", 2, 100.0, 104_000).events
        for (i in 1..50) events += s.onCounter("pm5-rower", 2, 100.0 + i * 8, 104_000L + i * 1000).events
        return s to events.map { ChallengeJournal.encode(it) }
    }

    @Test fun everyEventSurvivesTheTextFormAndTheDefinitionIsInTheJournal() {
        val (_, lines) = workout()
        val read = ChallengeJournal.read(lines)
        assertEquals(JournalStatus.INTACT, read.status)
        assertEquals(lines, read.events.map { ChallengeJournal.encode(it) })
        val created = read.events.first() as ChallengeEvent.Created
        assertEquals("id|with,odd%chars", created.definition.id)
        assertEquals(3, created.definition.version)
        assertEquals(false, created.definition.allowPause)
        assertEquals(setOf("gps-primary", "gps,backup"), created.definition.stages[0].allowedSources)
        assertEquals("sess|1", created.sessionId)
    }

    @Test fun aDamagedForgedOrCutLineIsRecognised() {
        val line = ChallengeJournal.encode(ChallengeEvent.Paused(3, 1000, "user"))
        assertNotNull(ChallengeJournal.decode(line))
        assertNull(ChallengeJournal.decode(line.dropLast(3)))
        assertNull(ChallengeJournal.decode(line.replace("1000", "1001")))
        assertNull(ChallengeJournal.decode(""))
        assertNull(ChallengeJournal.decode("garbage"))
        assertNull(ChallengeJournal.decode(line.replace("C1", "C9")))
    }

    @Test fun theChallengeComesBackPausedWithEverythingItDidAndNothingRunsAgain() {
        val (live, lines) = workout()
        val r = assertNotNull(ChallengeJournal.recover(lines))
        val s = r.restored.session
        val snap = s.snapshot(160_000)
        assertEquals(ChallengeState.PAUSED, snap.state, "it was running when the process died")
        assertEquals(2, snap.completed.size, "the stages that completed stay completed")
        assertEquals("row", snap.stageId)
        assertEquals(live.snapshot(160_000).stageProgress, snap.stageProgress, 1e-9)
        assertEquals(1, snap.recoveries)
        assertEquals(1, r.restored.recoveryEvents.size)
        // even a definition that forbids pausing comes back paused: the time since is not counted and the recovery is visible
        assertEquals(false, s.definition.allowPause)
        // a stage that completed never runs again: a late sample of the run stage is stale
        assertTrue(s.resume(170_000).accepted)
        // the manual source is not allowed for the row stage, and the run stage is over for good
        assertEquals(Refusal.SOURCE_NOT_ALLOWED, s.onDelta("manual", "again", 5.0, 171_000).refusal)
    }

    @Test fun aMeasurementThatWasAlreadyCountedIsNotCountedAgainAfterARestart() {
        val (_, lines) = workout()
        val s = assertNotNull(ChallengeJournal.recover(lines)).restored.session
        s.resume(160_000)
        val before = s.snapshot(160_000).stageProgress
        // the first sample after a restart is only a baseline (nothing durable about baselines): nothing is double counted
        s.onCounter("pm5-rower", 2, 100.0 + 50 * 8, 160_000)
        assertEquals(before, s.snapshot(160_000).stageProgress, 1e-9)
        s.onCounter("pm5-rower", 2, 100.0 + 50 * 8 + 8, 161_000)
        assertEquals(before + 8.0, s.snapshot(161_000).stageProgress, 1e-9)
        // a manual tap that the host retries after the restart has the same event id: refused
        val r = s.onDelta("manual", "tap|1", 50.0, 162_000)
        assertTrue(!r.accepted)
    }

    @Test fun replayingTwiceOrWithRepeatedLinesGivesTheSameChallenge() {
        val (_, lines) = workout()
        val once = assertNotNull(ChallengeJournal.recover(lines)).restored.session.snapshot(200_000)
        val doubled = assertNotNull(ChallengeJournal.recover(lines + lines)).restored.session.snapshot(200_000)
        val reversed = assertNotNull(ChallengeJournal.recover(lines + lines.reversed())).restored.session.snapshot(200_000)
        for (d in listOf(doubled, reversed)) {
            assertEquals(once.stageProgress, d.stageProgress, 0.0)
            assertEquals(once.completed.size, d.completed.size)
            assertEquals(once.totalElapsedMs, d.totalElapsedMs)
            assertEquals(once.recoveries, d.recoveries)
        }
    }

    @Test fun theJournalOfARestoredChallengeKeepsGrowingConsistently() {
        val (_, lines) = workout()
        val first = assertNotNull(ChallengeJournal.recover(lines))
        val s = first.restored.session
        val all = ArrayList(lines)
        first.restored.recoveryEvents.forEach { all += ChallengeJournal.encode(it) }
        val more = ArrayList<ChallengeEvent>()
        more += s.resume(170_000).events
        more += s.confirm(CompletionEvidence.MANUAL, 171_000).events
        more.forEach { all += ChallengeJournal.encode(it) }
        val final = assertNotNull(ChallengeJournal.recover(all)).restored.session.snapshot(300_000)
        assertEquals(ChallengeState.COMPLETED, final.state)
        assertEquals(3, final.completed.size)
        assertEquals(1, final.recoveries)
        assertEquals(s.snapshot(300_000).totalElapsedMs, final.totalElapsedMs)
    }

    @Test fun aTransitionThatWasInProgressComesBackPausedAndResumesIntoTheTransition() {
        val s = ChallengeSession(def, "s1")
        val lines = ArrayList<String>()
        s.start(0).events.forEach { lines += ChallengeJournal.encode(it) }
        s.onCounter("gps-primary", 1, 0.0, 0)
        for (i in 1..100) s.onCounter("gps-primary", 1, i * 10.0, i * 1000L).events.forEach { lines += ChallengeJournal.encode(it) }
        assertEquals(ChallengeState.TRANSITION, s.currentState)
        val r = assertNotNull(ChallengeJournal.recover(lines))
        assertEquals(ChallengeState.PAUSED, r.restored.session.snapshot(150_000).state)
        r.restored.session.resume(150_000)
        assertEquals(ChallengeState.TRANSITION, r.restored.session.currentState)
        assertTrue(r.restored.session.nextStage(151_000).accepted)
    }

    @Test fun aCutLastLineIsRepairedAndADamagedMiddleKeepsOnlyThePrefix() {
        val (_, lines) = workout()
        val a = ChallengeJournal.read(lines.dropLast(1) + lines.last().dropLast(6))
        assertEquals(JournalStatus.TAIL_REPAIRED, a.status)
        assertEquals(lines.size - 1, a.events.size)
        val damaged = lines.toMutableList().also { it[10] = it[10].replace("|", "#") }
        val b = ChallengeJournal.read(damaged)
        assertEquals(JournalStatus.PARTIAL, b.status)
        assertEquals(10, b.events.size)
        assertNotNull(ChallengeJournal.recover(damaged))
    }

    @Test fun aJournalWithoutItsCreatedLineCannotBeRecovered() {
        val (_, lines) = workout()
        assertNull(ChallengeJournal.recover(lines.drop(1)))
        assertNull(ChallengeJournal.recover(emptyList()))
    }

    @Test fun aCompletedChallengeComesBackCompletedWithoutARecoveryEvent() {
        val d = ChallengeDefinition("x", 1, listOf(StageDefinition("a", ProgressMetric.REPS, 3.0, CompletionPolicy.AUTO, setOf("m"))))
        val s = ChallengeSession(d, "s")
        val lines = ArrayList<String>()
        s.start(0).events.forEach { lines += ChallengeJournal.encode(it) }
        s.onDelta("m", "1", 3.0, 1000).events.forEach { lines += ChallengeJournal.encode(it) }
        val r = assertNotNull(ChallengeJournal.recover(lines))
        assertEquals(ChallengeState.COMPLETED, r.restored.session.snapshot(9999).state)
        assertTrue(r.restored.recoveryEvents.isEmpty())
        assertEquals(StageStatus.COMPLETED, r.restored.session.snapshot(9999).stageStatus)
    }
}
