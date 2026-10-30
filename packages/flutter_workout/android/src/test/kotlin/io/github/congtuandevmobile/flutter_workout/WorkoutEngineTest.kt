package io.github.congtuandevmobile.flutter_workout

import java.io.File
import java.io.IOException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

private class MemoryStore : WorkoutJournalStore {
    val files = HashMap<String, MutableList<String>>()
    var activeId: String? = null
    var failAppends = false
    val log = ArrayList<String>() // "append:<n>" in order, to prove the write came before the snapshot
    override fun append(sessionId: String, lines: List<String>) {
        if (failAppends) throw IOException("disk full")
        files.getOrPut(sessionId) { ArrayList() }.addAll(lines)
        log += "append:${lines.size}"
    }
    override fun read(sessionId: String) = files[sessionId]?.toList() ?: emptyList()
    override fun clear(sessionId: String) { files.remove(sessionId); if (activeId == sessionId) activeId = null }
    var failReplace = false
    val originals = HashMap<String, List<String>>()
    override fun replaceKeepingOriginal(sessionId: String, lines: List<String>): String {
        if (failReplace) throw IOException("read-only")
        originals[sessionId] = files[sessionId]?.toList() ?: emptyList()
        files[sessionId] = lines.toMutableList()
        return "kept"
    }
    override fun activeSessionId() = activeId
    override fun setActive(sessionId: String?) { activeId = sessionId }
}

private class RecordingSink(private val store: MemoryStore) : WorkoutSink {
    val snapshots = ArrayList<NativeWorkoutSnapshot>()
    /** How many lines were on the "disk" when each snapshot was published. */
    val linesAtPublish = ArrayList<Int>()
    override fun onSnapshot(snapshot: NativeWorkoutSnapshot) {
        snapshots += snapshot
        linesAtPublish += store.files.values.sumOf { it.size }
    }
}

@OptIn(ExperimentalCoroutinesApi::class)
class WorkoutEngineTest {
    private var clock = 1_000L
    private val store = MemoryStore()
    private val sink = RecordingSink(store)
    private val foot = NativeSourceRef("footpod", NativeSourceKind.COUNTER)
    private val tread = NativeSourceRef("treadmill", NativeSourceKind.COUNTER)
    private val speed = NativeSourceRef("foot-speed", NativeSourceKind.SPEED)

    private fun TestScope.engine(s: WorkoutJournalStore = store, snk: WorkoutSink = sink) =
        WorkoutEngine(s, CoroutineScope(StandardTestDispatcher(testScheduler)), { clock }, snk)

    @Test
    fun startWritesTheFirstLineBeforeItReturns() = runTest {
        val e = engine()
        val snap = e.start("w1", NativeWorkoutMode.INDOOR_RUNNING)
        assertEquals(NativeWorkoutState.RUNNING, snap.state)
        assertEquals(1, store.files.getValue("w1").size)
        assertEquals("w1", store.activeSessionId())
    }

    @Test
    fun aNumberIsNeverShownBeforeItIsOnTheDisk() = runTest {
        val e = engine()
        e.start("w1", NativeWorkoutMode.INDOOR_RUNNING)
        e.submitCounter("w1", foot, 1, 0.0, 0)
        clock += 3000
        e.submitCounter("w1", foot, 1, 10.0, 0)
        val last = sink.snapshots.last()
        assertEquals(10.0, last.distanceMeters, 1e-9)
        // when the snapshot with 10 m went out, its DistanceAdvanced line was already stored
        val lines = store.files.getValue("w1")
        assertTrue(lines.any { it.contains("|D|") })
        assertEquals(lines.size, sink.linesAtPublish.last())
    }

    @Test
    fun pauseAndResumeNeverCreditThePausedDistance() = runTest {
        val e = engine()
        e.start("w1", NativeWorkoutMode.INDOOR_RUNNING)
        e.submitCounter("w1", foot, 1, 0.0, 0)
        clock += 10_000
        e.submitCounter("w1", foot, 1, 30.0, 0)
        e.pause("w1")
        clock += 60_000
        e.submitCounter("w1", foot, 1, 530.0, 0) // the machine counted 500 m while paused
        e.resume("w1")
        clock += 1000
        e.submitCounter("w1", foot, 1, 531.0, 0)
        clock += 3000
        e.submitCounter("w1", foot, 1, 534.0, 0)
        assertEquals(33.0, e.snapshot().distanceMeters, 1e-9)
    }

    @Test
    fun aSecondStartWhileOneIsOpenIsRefused() = runTest {
        val e = engine()
        e.start("w1", NativeWorkoutMode.INDOOR_RUNNING)
        assertEquals("SESSION_OPEN", assertFailsWith<WorkoutException> { e.start("w2", NativeWorkoutMode.INDOOR_RUNNING) }.code)
        e.finish("w1")
        e.start("w2", NativeWorkoutMode.INDOOR_RUNNING)
    }

    @Test
    fun samplesAndCommandsOfAnotherSessionAreDropped() = runTest {
        val e = engine()
        e.start("w1", NativeWorkoutMode.INDOOR_RUNNING)
        e.submitCounter("other", foot, 1, 0.0, 0)
        clock += 3000
        e.submitCounter("other", foot, 1, 50.0, 0)
        assertEquals(0.0, e.snapshot().distanceMeters, 0.0)
        assertEquals("NO_SESSION", assertFailsWith<WorkoutException> { e.pause("other") }.code)
    }

    @Test
    fun aSampleIsStampedWithItsRealTimeNotTheTimeOfTheCall() = runTest {
        val e = engine()
        e.start("w1", NativeWorkoutMode.INDOOR_RUNNING) // at 1000
        clock = 6_000
        e.submitSpeed("w1", speed, 1, 3.0, 4_000) // measured at 2000
        clock = 7_000
        e.submitSpeed("w1", speed, 1, 3.0, 4_000) // measured at 3000: 1 s apart, not 1 s since the call
        assertEquals(3.0, e.snapshot().distanceMeters, 1e-9)
    }

    @Test
    fun aFailedWriteIsReportedAndStickyButTheWorkoutGoesOn() = runTest {
        val e = engine()
        e.start("w1", NativeWorkoutMode.INDOOR_RUNNING)
        e.submitCounter("w1", foot, 1, 0.0, 0)
        store.failAppends = true
        clock += 3000
        e.submitCounter("w1", foot, 1, 10.0, 0)
        val s = e.snapshot()
        assertTrue(s.journalFailed)
        assertTrue(s.error!!.startsWith("JOURNAL_WRITE_FAILED"))
        assertEquals(10.0, s.distanceMeters, 1e-9)
        store.failAppends = false
        clock += 3000
        e.submitCounter("w1", foot, 1, 20.0, 0)
        assertTrue(e.snapshot().journalFailed, "sticky: a later good write does not make the earlier loss durable")
    }

    @Test
    fun aWorkoutThatCannotWriteItsFirstLineIsNotStarted() = runTest {
        store.failAppends = true
        val e = engine()
        assertEquals("JOURNAL_WRITE_FAILED", assertFailsWith<WorkoutException> { e.start("w1", NativeWorkoutMode.INDOOR_RUNNING) }.code)
        assertEquals(NativeWorkoutState.IDLE, e.snapshot().state)
    }

    // ── the process dies ────────────────────────────────────────────────────

    private fun TestScope.runWorkoutAndDie(): Double {
        val e = engine()
        e.start("w1", NativeWorkoutMode.INDOOR_RUNNING)
        e.submitCounter("w1", foot, 1, 100.0, 0)
        for (i in 1..4) { clock += 10_000; e.submitCounter("w1", foot, 1, 100.0 + i * 30, 0) }
        return e.snapshot().distanceMeters // 120 m; then the process dies: this engine is simply dropped
    }

    @Test
    fun aRestoredWorkoutComesBackPausedWithItsDistanceAndNothingInvented() = runTest {
        val distance = runWorkoutAndDie()
        assertEquals("w1", store.activeSessionId())
        clock += 3_600_000 // an hour later the app is opened again
        val sink2 = RecordingSink(store)
        val e2 = engine(store, sink2)
        val snap = e2.restore("w1")
        assertEquals(NativeWorkoutState.PAUSED, snap.state)
        assertEquals(distance, snap.distanceMeters, 1e-9)
        assertEquals(NativeRestoreStatus.INTACT, snap.restoreStatus)
        assertEquals(40_000L, snap.activeMs, "the hour the process was dead is not activity")
        assertNull(snap.distanceSource, "nothing is counting until a sensor speaks again")
        assertEquals(NativeSourceKind.COUNTER, snap.lastDistanceSource!!.kind)
        // resume: the first sample is a baseline, nothing is credited for the dead time
        e2.resume("w1")
        e2.submitCounter("w1", foot, 1, 1000.0, 0)
        clock += 3000
        e2.submitCounter("w1", foot, 1, 1010.0, 0)
        assertEquals(distance + 10.0, e2.snapshot().distanceMeters, 1e-9)
    }

    @Test
    fun aSessionIdCannotBeReusedWhileItsJournalExists() = runTest {
        val e = engine()
        e.start("w1", NativeWorkoutMode.INDOOR_RUNNING)
        e.finish("w1")
        val lines = store.files.getValue("w1").toList()
        assertEquals("SESSION_EXISTS", assertFailsWith<WorkoutException> { e.start("w1", NativeWorkoutMode.INDOOR_RUNNING) }.code)
        assertEquals(lines, store.files.getValue("w1"), "nothing was appended behind the first workout's journal")
        e.clearSession("w1")
        e.start("w1", NativeWorkoutMode.INDOOR_RUNNING) // after the journal is cleared the id is free again
    }

    @Test
    fun aSampleIsTimedWhenItArrivedNotWhenTheQueueGetsToIt() = runTest {
        val e = engine()
        e.start("w1", NativeWorkoutMode.INDOOR_RUNNING)
        e.submitCounter("w1", foot, 1, 0.0, 0)
        clock += 1000; e.pause("w1")
        clock += 4000; e.resume("w1") // resumed at 6000
        // samples that ARRIVED during the pause, processed after the resume
        e.submitCounter("w1", foot, 1, 100.0, 0, 3_000)
        e.submitCounter("w1", foot, 1, 110.0, 0, 3_500)
        assertEquals(0.0, e.snapshot().distanceMeters, 1e-9)
        clock += 500; e.submitCounter("w1", foot, 1, 120.0, 0)
        clock += 1000; e.submitCounter("w1", foot, 1, 125.0, 0)
        assertEquals(5.0, e.snapshot().distanceMeters, 1e-9)
    }

    @Test
    fun restoringAnotherWorkoutWhileOneIsOpenIsRefusedAndChangesNothing() = runTest {
        val other = engine()
        other.start("w2", NativeWorkoutMode.INDOOR_RUNNING)
        other.finish("w2") // w2 has a restorable journal
        val e = engine()
        e.start("w1", NativeWorkoutMode.INDOOR_RUNNING)
        assertEquals("SESSION_OPEN", assertFailsWith<WorkoutException> { e.restore("w2") }.code)
        assertEquals("w1", e.activeSessionId())
        assertEquals(NativeWorkoutState.RUNNING, e.snapshot().state, "w1 is still the open workout")
    }

    @Test
    fun restoringTwiceDoesNotReplayAgainAndIsIdempotent() = runTest {
        val distance = runWorkoutAndDie()
        val e2 = engine()
        val first = e2.restore("w1")
        val linesAfterFirst = store.files.getValue("w1").size
        val second = e2.restore("w1")
        assertEquals(linesAfterFirst, store.files.getValue("w1").size, "no second replay, no second Paused line")
        assertEquals(first.distanceMeters, second.distanceMeters, 0.0)
        assertEquals(distance, second.distanceMeters, 1e-9)
        // a THIRD engine (another crash) restores the extended journal to the same workout
        val e3 = engine()
        assertEquals(distance, e3.restore("w1").distanceMeters, 1e-9)
    }

    @Test
    fun aRebootThatRestartedTheMonotonicClockLowerStillAllowsAResume() = runTest {
        runWorkoutAndDie() // last event at about 41_000
        clock = 500 // the phone rebooted: the monotonic clock starts again from a small number
        val e2 = engine()
        e2.restore("w1")
        val resumed = e2.resume("w1")
        assertEquals(NativeWorkoutState.RUNNING, resumed.state)
        clock += 5_000
        assertEquals(40_000L + 5_000L, e2.snapshot().activeMs)
    }

    @Test
    fun aCutLastLineIsRepairedAndSaid() = runTest {
        runWorkoutAndDie()
        val lines = store.files.getValue("w1")
        lines[lines.lastIndex] = lines.last().dropLast(7)
        val snap = engine().restore("w1")
        assertEquals(NativeRestoreStatus.TAIL_REPAIRED, snap.restoreStatus)
        assertEquals(NativeWorkoutState.PAUSED, snap.state)
    }

    @Test
    fun aDamagedMiddleKeepsOnlyThePrefix() = runTest {
        runWorkoutAndDie()
        val lines = store.files.getValue("w1")
        lines[3] = lines[3].replace("|", "#")
        assertEquals(NativeRestoreStatus.PARTIAL, engine().restore("w1").restoreStatus)
    }

    @Test
    fun aDamagedTailIsCutOnTheDiskBeforeAnythingIsAppendedSoLaterLinesAreNeverHidden() = runTest {
        runWorkoutAndDie()
        val lines = store.files.getValue("w1")
        lines[lines.lastIndex] = lines.last().dropLast(7) // the last write was cut
        val damagedCopy = lines.toList()
        val e2 = engine()
        assertEquals(NativeRestoreStatus.TAIL_REPAIRED, e2.restore("w1").restoreStatus)
        assertEquals(damagedCopy, store.originals["w1"], "the damaged original is kept for diagnosis")
        e2.resume("w1")
        e2.submitCounter("w1", foot, 1, 500.0, 0)
        clock += 3000
        e2.submitCounter("w1", foot, 1, 510.0, 0)
        val again = engine().restore("w1")
        assertEquals(NativeRestoreStatus.INTACT, again.restoreStatus, "nothing is hidden behind a damaged line any more")
        assertEquals(e2.snapshot().distanceMeters, again.distanceMeters, 1e-9)
    }

    @Test
    fun aDamagedMiddleIsCutToItsGoodPrefixAndTheOriginalIsKept() = runTest {
        runWorkoutAndDie()
        val lines = store.files.getValue("w1")
        lines[3] = lines[3].replace("|", "#")
        val original = lines.toList()
        assertEquals(NativeRestoreStatus.PARTIAL, engine().restore("w1").restoreStatus)
        assertEquals(original, store.originals["w1"])
        assertEquals(NativeRestoreStatus.INTACT, engine().restore("w1").restoreStatus)
    }

    @Test
    fun ifTheRepairFailsNothingIsAppendedAndTheWorkoutIsNotDurable() = runTest {
        runWorkoutAndDie()
        val lines = store.files.getValue("w1")
        lines[lines.lastIndex] = lines.last().dropLast(7)
        store.failReplace = true
        val before = lines.size
        val snap = engine().restore("w1")
        assertTrue(snap.journalFailed)
        assertTrue(snap.error!!.startsWith("JOURNAL_REPAIR_FAILED"))
        assertEquals(before, store.files.getValue("w1").size, "no recovery line behind the damage")
        assertEquals(NativeWorkoutState.PAUSED, snap.state)
    }

    @Test
    fun anUnknownOrEmptyJournalIsNotRestorable() = runTest {
        assertEquals("NOT_RESTORABLE", assertFailsWith<WorkoutException> { engine().restore("nope") }.code)
    }

    @Test
    fun aFinishedWorkoutClearsTheActivePointerAndRestoresAsFinished() = runTest {
        val e = engine()
        e.start("w1", NativeWorkoutMode.INDOOR_RUNNING)
        e.finish("w1")
        assertNull(e.activeSessionId())
        val snap = engine().restore("w1")
        assertEquals(NativeWorkoutState.FINISHED, snap.state)
        assertNull(store.activeSessionId())
    }

    @Test
    fun clearSessionDeletesTheJournalButNotAnOpenWorkout() = runTest {
        val e = engine()
        e.start("w1", NativeWorkoutMode.INDOOR_RUNNING)
        assertEquals("SESSION_OPEN", assertFailsWith<WorkoutException> { e.clearSession("w1") }.code)
        e.finish("w1")
        e.clearSession("w1")
        assertTrue(store.files["w1"] == null)
        assertEquals(NativeWorkoutState.IDLE, e.snapshot().state)
    }

    @Test
    fun theSnapshotIsPublishedAboutOncePerSecond() = runTest {
        val e = engine()
        e.start()
        e.start("w1", NativeWorkoutMode.INDOOR_RUNNING)
        val before = sink.snapshots.size
        advanceTimeBy(3_500)
        assertEquals(before + 3, sink.snapshots.size)
        e.stop()
    }

    @Test
    fun everyModeStateAndSourceKindOfTheCoreHasItsPigeonTwinInTheSameOrder() = runTest {
        assertEquals(workout.model.WorkoutMode.values().map { it.name }, NativeWorkoutMode.values().map { it.name })
        assertEquals(workout.model.WorkoutState.values().map { it.name }, NativeWorkoutState.values().map { it.name })
        assertEquals(workout.model.DistanceSourceKind.values().map { it.name }, NativeSourceKind.values().map { it.name })
    }

    // ── the file store ──────────────────────────────────────────────────────

    @Test
    fun theFileStoreAppendsReadsClearsAndKeepsTheActivePointer() {
        val dir = File(System.getProperty("java.io.tmpdir"), "wf-" + System.nanoTime())
        val s = FileWorkoutJournalStore(dir)
        s.append("a/b c", listOf("one", "two"))
        s.append("a/b c", listOf("three"))
        assertEquals(listOf("one", "two", "three"), s.read("a/b c"))
        assertEquals(emptyList(), s.read("missing"))
        // ids that differ only in characters a naive name would strip do not collide
        s.append("a_b_c", listOf("x"))
        assertEquals(listOf("one", "two", "three"), s.read("a/b c"))
        s.setActive("a/b c")
        assertEquals("a/b c", s.activeSessionId())
        val kept = s.replaceKeepingOriginal("a/b c", listOf("one", "two"))
        assertEquals(listOf("one", "two"), s.read("a/b c"))
        assertEquals(listOf("one", "two", "three"), File(dir, kept).readText().split('\n').filter { it.isNotBlank() })
        s.append("a/b c", listOf("four"))
        assertEquals(listOf("one", "two", "four"), s.read("a/b c"))
        s.clear("a/b c")
        assertEquals(emptyList(), s.read("a/b c"))
        assertNull(s.activeSessionId())
        dir.deleteRecursively()
    }
}
