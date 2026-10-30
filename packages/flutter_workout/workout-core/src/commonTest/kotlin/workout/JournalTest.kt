package workout

import workout.journal.JournalStatus
import workout.journal.WorkoutJournal
import workout.model.DistanceSource
import workout.model.DistanceSourceKind
import workout.model.WorkoutEvent
import workout.model.WorkoutMode
import workout.model.WorkoutState
import workout.session.WorkoutSession
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class JournalTest {
    private val foot = DistanceSource("foot|pod 100%", DistanceSourceKind.COUNTER) // an id with the separators
    private val tread = DistanceSource("treadmill", DistanceSourceKind.COUNTER)

    /** A workout with a pause and a change of source, as the lines a journal would hold. */
    private fun workout(): Pair<WorkoutSession, List<String>> {
        val s = WorkoutSession(WorkoutMode.INDOOR_RUNNING)
        val events = ArrayList<WorkoutEvent>()
        events += s.start(0)
        events += s.onCounter(foot, 1, 100.0, 0)
        for (i in 1..4) events += s.onCounter(foot, 1, 100.0 + i * 30, i * 10_000L)
        events += s.pause(41_000)
        events += s.resume(50_000)
        events += s.onCounter(foot, 1, 300.0, 51_000)
        events += s.onCounter(foot, 1, 330.0, 61_000)
        events += s.setPreferredSource(tread, 62_000)
        events += s.onCounter(tread, 1, 5000.0, 62_000)
        events += s.onCounter(tread, 1, 5030.0, 72_000)
        return s to events.map { WorkoutJournal.encode(it) }
    }

    @Test fun everyEventSurvivesTheTextForm() {
        val (_, lines) = workout()
        val read = WorkoutJournal.read(lines)
        assertEquals(JournalStatus.INTACT, read.status)
        assertEquals(lines, read.events.map { WorkoutJournal.encode(it) })
    }

    @Test fun aLineWithTheSeparatorsInTheSourceIdIsEscaped() {
        val e = WorkoutEvent.DistanceAdvanced(7, 100, foot, 12.5)
        val line = WorkoutJournal.encode(e)
        assertEquals(1, line.count { it == '\n' } + 1)
        val back = WorkoutJournal.decode(line) as WorkoutEvent.DistanceAdvanced
        assertEquals(foot, back.source)
        assertEquals(12.5, back.deltaMeters, 0.0)
    }

    @Test fun aDamagedOrCutLineIsRecognised() {
        val line = WorkoutJournal.encode(WorkoutEvent.Paused(3, 1000))
        assertNotNull(WorkoutJournal.decode(line))
        assertNull(WorkoutJournal.decode(line.dropLast(3)))
        assertNull(WorkoutJournal.decode(line.replace("1000", "1001")))
        assertNull(WorkoutJournal.decode(""))
        assertNull(WorkoutJournal.decode("garbage"))
        assertNull(WorkoutJournal.decode(WorkoutJournal.encode(WorkoutEvent.Paused(3, 1000)).replace("W1", "W9")))
    }

    @Test fun aNonPositiveDistanceOrNonFiniteValueIsRejected() {
        fun forged(body: String) = body + "|" + crc(body)
        assertNull(WorkoutJournal.decode(forged("W1|1|D|10|COUNTER:x|-5.0")))
        assertNull(WorkoutJournal.decode(forged("W1|1|D|10|COUNTER:x|NaN")))
        assertNull(WorkoutJournal.decode(forged("W1|0|P|10")))
        assertNull(WorkoutJournal.decode(forged("W1|1|S|10|NOT_A_MODE")))
    }

    private fun crc(text: String): String = workout.journal.Crc32Probe.hex(text)

    @Test fun replayRebuildsTheSessionAndComesBackPausedWithTheDistanceKept() {
        val (live, lines) = workout()
        val recovered = assertNotNull(WorkoutJournal.recover(lines))
        val s = recovered.restored.session
        val snap = s.snapshot(72_000)
        assertEquals(WorkoutState.PAUSED, snap.state, "it was running when the process died")
        assertEquals(live.snapshot(72_000).distanceMeters, snap.distanceMeters, 1e-9)
        assertEquals(tread, snap.lastDistanceSource, "the source that credited last is remembered")
        assertNull(snap.distanceSource, "but nothing is counting until a sensor speaks again")
        assertEquals(1, recovered.restored.recoveryEvents.size)
        assertTrue(recovered.restored.recoveryEvents.single() is WorkoutEvent.Paused)
    }

    @Test fun theTimeTheProcessWasDeadIsNotActivityAndNoDistanceIsInvented() {
        val (_, lines) = workout()
        val s = assertNotNull(WorkoutJournal.recover(lines)).restored.session
        val atDeath = s.snapshot(72_000)
        val muchLater = s.snapshot(72_000 + 3_600_000)
        assertEquals(atDeath.activeMs, muchLater.activeMs - 0, "paused: the clock of activity does not run")
        assertEquals(atDeath.distanceMeters, muchLater.distanceMeters, 0.0)
        s.resume(72_000 + 600_000)
        assertEquals(atDeath.activeMs, s.snapshot(72_000 + 600_000).activeMs)
    }

    @Test fun replayingTwiceOrWithRepeatedLinesGivesTheSameSession() {
        val (_, lines) = workout()
        val once = assertNotNull(WorkoutJournal.recover(lines)).restored.session.snapshot(80_000)
        val doubled = assertNotNull(WorkoutJournal.recover(lines + lines)).restored.session.snapshot(80_000)
        val shuffledTwice = assertNotNull(WorkoutJournal.recover(lines + lines.reversed())).restored.session.snapshot(80_000)
        assertEquals(once.distanceMeters, doubled.distanceMeters, 0.0)
        assertEquals(once.activeMs, doubled.activeMs)
        assertEquals(once.distanceMeters, shuffledTwice.distanceMeters, 0.0, "a repeated sequence number is applied once")
    }

    @Test fun theJournalOfARestoredSessionKeepsGrowingConsistently() {
        val (_, lines) = workout()
        val first = assertNotNull(WorkoutJournal.recover(lines))
        val s = first.restored.session
        val appended = ArrayList(lines)
        first.restored.recoveryEvents.forEach { appended += WorkoutJournal.encode(it) }
        val more = ArrayList<WorkoutEvent>()
        more += s.resume(100_000)
        more += s.onCounter(tread, 2, 0.0, 100_500) // the treadmill is a new connection
        more += s.onCounter(tread, 2, 25.0, 108_000)
        more += s.finish(110_000)
        more.forEach { appended += WorkoutJournal.encode(it) }
        val final = assertNotNull(WorkoutJournal.recover(appended)).restored.session.snapshot(200_000)
        assertEquals(WorkoutState.FINISHED, final.state)
        assertEquals(s.snapshot(200_000).distanceMeters, final.distanceMeters, 1e-9)
        assertEquals(s.snapshot(200_000).activeMs, final.activeMs)
    }

    @Test fun aCutLastLineIsRepairedAndADamagedMiddleKeepsOnlyThePrefix() {
        val (_, lines) = workout()
        val cutTail = lines.dropLast(1) + lines.last().dropLast(6)
        val a = WorkoutJournal.read(cutTail)
        assertEquals(JournalStatus.TAIL_REPAIRED, a.status)
        assertEquals(lines.size - 1, a.events.size)
        val damagedMiddle = lines.toMutableList().also { it[5] = it[5].replace("|", "#") }
        val b = WorkoutJournal.read(damagedMiddle)
        assertEquals(JournalStatus.PARTIAL, b.status)
        assertEquals(5, b.events.size)
        assertEquals(lines.size - 5, b.droppedLines)
        assertNotNull(WorkoutJournal.recover(damagedMiddle))
    }

    @Test fun aJournalWithoutAStartedLineCannotBeRecovered() {
        val (_, lines) = workout()
        assertNull(WorkoutJournal.recover(lines.drop(1)))
        assertNull(WorkoutJournal.recover(emptyList()))
    }

    @Test fun aFinishedWorkoutComesBackFinished() {
        val s = WorkoutSession(WorkoutMode.INDOOR_RUNNING)
        val lines = ArrayList<String>()
        s.start(0).forEach { lines += WorkoutJournal.encode(it) }
        s.onCounter(foot, 1, 0.0, 0).forEach { lines += WorkoutJournal.encode(it) }
        s.onCounter(foot, 1, 30.0, 10_000).forEach { lines += WorkoutJournal.encode(it) }
        s.finish(20_000).forEach { lines += WorkoutJournal.encode(it) }
        val r = assertNotNull(WorkoutJournal.recover(lines))
        assertEquals(WorkoutState.FINISHED, r.restored.session.snapshot(99_999).state)
        assertTrue(r.restored.recoveryEvents.isEmpty())
        assertEquals(30.0, r.restored.session.snapshot(99_999).distanceMeters, 1e-9)
    }
}
