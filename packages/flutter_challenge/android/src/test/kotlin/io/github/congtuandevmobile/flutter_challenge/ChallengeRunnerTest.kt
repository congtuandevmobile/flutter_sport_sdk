package io.github.congtuandevmobile.flutter_challenge

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
import kotlin.test.assertNull
import kotlin.test.assertTrue

private class MemoryStore : ChallengeJournalStore {
    val files = HashMap<String, MutableList<String>>()
    var activeId: String? = null
    var failAppends = false
    var failReplace = false
    val originals = HashMap<String, List<String>>()
    override fun append(sessionId: String, lines: List<String>) {
        if (failAppends) throw IOException("disk full")
        files.getOrPut(sessionId) { ArrayList() }.addAll(lines)
    }
    override fun read(sessionId: String) = files[sessionId]?.toList() ?: emptyList()
    override fun clear(sessionId: String) { files.remove(sessionId); if (activeId == sessionId) activeId = null }
    override fun replaceKeepingOriginal(sessionId: String, lines: List<String>): String {
        if (failReplace) throw IOException("read-only")
        originals[sessionId] = files[sessionId]?.toList() ?: emptyList()
        files[sessionId] = lines.toMutableList()
        return "kept"
    }
    override fun activeSessionId() = activeId
    override fun setActive(sessionId: String?) { activeId = sessionId }
}

private class RecordingSink(private val store: MemoryStore) : ChallengeSink {
    val snapshots = ArrayList<NativeChallengeSnapshot>()
    val linesAtPublish = ArrayList<Int>()
    override fun onSnapshot(snapshot: NativeChallengeSnapshot) {
        snapshots += snapshot
        linesAtPublish += store.files.values.sumOf { it.size }
    }
}

@OptIn(ExperimentalCoroutinesApi::class)
class ChallengeRunnerTest {
    private var clock = 1_000L
    private val store = MemoryStore()
    private val sink = RecordingSink(store)

    private fun stage(id: String, metric: NativeProgressMetric, target: Double, policy: NativeCompletionPolicy, vararg sources: String) =
        NativeStageDefinition(id, metric, target, policy, sources.toList())

    private val def = NativeChallengeDefinition(
        "hybrid", 1, true,
        listOf(
            stage("run-1", NativeProgressMetric.RUN_METERS, 1000.0, NativeCompletionPolicy.AUTO, "gps-primary"),
            stage("sled", NativeProgressMetric.SLED_METERS, 50.0, NativeCompletionPolicy.MANUAL, "manual"),
            stage("row", NativeProgressMetric.ROW_METERS, 1000.0, NativeCompletionPolicy.SENSOR_OR_MANUAL, "pm5-rower"),
            stage("run-2", NativeProgressMetric.RUN_METERS, 1000.0, NativeCompletionPolicy.AUTO, "gps-primary"),
        ),
    )

    private fun TestScope.runner(s: ChallengeJournalStore = store, snk: ChallengeSink = sink) =
        ChallengeRunner(s, CoroutineScope(StandardTestDispatcher(testScheduler)), { clock }, snk)

    /** The GPS keeps counting: 10 m per second. */
    private class Gps(val r: ChallengeRunner, val clockOf: () -> Long, val setClock: (Long) -> Unit, var total: Double) {
        fun run(seconds: Int) { repeat(seconds) { setClock(clockOf() + 1000); total += 10.0; r.submitCounter("s1", "gps-primary", 1, total, 0) } }
    }

    private fun gps(r: ChallengeRunner, total: Double = 5000.0) = Gps(r, { clock }, { clock = it }, total)

    @Test
    fun startWritesTheDefinitionAndTheFirstLinesBeforeItReturns() = runTest {
        val r = runner()
        val snap = r.start("s1", def)
        assertEquals(NativeChallengeState.ACTIVE, snap.state)
        assertEquals("run-1", snap.stageId)
        assertEquals(3, store.files.getValue("s1").size, "Created, Started, StageActivated")
        assertEquals("s1", store.activeSessionId())
    }

    @Test
    fun aNumberIsNeverShownBeforeItIsOnTheDisk() = runTest {
        val r = runner()
        r.start("s1", def)
        val g = gps(r)
        r.submitCounter("s1", "gps-primary", 1, g.total, 0)
        g.run(3)
        val last = sink.snapshots.last()
        assertEquals(30.0, last.stageProgress, 1e-9)
        assertEquals(store.files.getValue("s1").size, sink.linesAtPublish.last())
    }

    @Test
    fun theWholeChallengeRunsSledRowRunWithTheGpsCountingTheWholeTime() = runTest {
        val r = runner()
        r.start("s1", def)
        val g = gps(r)
        r.submitCounter("s1", "gps-primary", 1, g.total, 0)
        g.run(100) // run 1: 1000 m
        assertEquals(NativeChallengeState.TRANSITION, r.snapshot().state)
        clock += 10_000; r.nextStage("s1")
        g.run(60) // the GPS goes on at the sled station: counts for nothing
        assertEquals(0.0, r.snapshot().stageProgress, 0.0)
        r.submitDelta("s1", "manual", "tap-1", 25.0, 0)
        r.submitDelta("s1", "manual", "tap-2", 25.0, 0)
        r.submitDelta("s1", "manual", "tap-1", 25.0, 0) // a retried tap: never counted twice
        assertEquals(50.0, r.snapshot().stageProgress, 1e-9)
        r.confirm("s1", NativeCompletionEvidence.MANUAL)
        clock += 20_000; r.nextStage("s1")
        r.submitCounter("s1", "pm5-rower", 5, 500.0, 0)
        for (i in 1..125) { clock += 1000; r.submitCounter("s1", "pm5-rower", 5, 500.0 + i * 8, 0); g.total += 10; r.submitCounter("s1", "gps-primary", 1, g.total, 0) }
        assertEquals(1000.0, r.snapshot().stageProgress, 1e-9)
        assertEquals(NativeStageStatus.TARGET_REACHED, r.snapshot().stageStatus, "a SENSOR_OR_MANUAL stage waits for the confirmation")
        r.confirm("s1", NativeCompletionEvidence.MANUAL)
        clock += 40_000; r.nextStage("s1")
        g.total += 400 // covered while moving between the stations: NOT credited to run 2
        r.submitCounter("s1", "gps-primary", 1, g.total, 0)
        g.run(25)
        assertEquals(250.0, r.snapshot().stageProgress, 1e-9)
        g.run(75)
        val end = r.snapshot()
        assertEquals(NativeChallengeState.COMPLETED, end.state)
        assertEquals(listOf("run-1", "sled", "row", "run-2"), end.completed.map { it.stageId })
        assertEquals(1000.0, end.completed[0].progress, 1e-9)
        assertEquals(50.0, end.completed[1].progress, 1e-9)
        assertEquals(1000.0, end.completed[3].progress, 1e-9)
        // the whole thing is in the journal, and a second challenge can start now
        assertTrue(store.files.getValue("s1").any { it.contains("|P|") })
        runner().start("s2", def)
    }

    @Test
    fun aCommandTheRulesRefuseFailsWithTheReasonAndNothingIsWritten() = runTest {
        val r = runner()
        r.start("s1", def)
        val before = store.files.getValue("s1").size
        assertEquals("NOT_ALLOWED", assertFailsWith<ChallengeException> { r.confirm("s1", NativeCompletionEvidence.MANUAL) }.code)
        assertEquals("WRONG_STATE", assertFailsWith<ChallengeException> { r.nextStage("s1") }.code)
        assertEquals("WRONG_STATE", assertFailsWith<ChallengeException> { r.resume("s1") }.code)
        assertEquals("NO_SESSION", assertFailsWith<ChallengeException> { r.pause("other") }.code)
        assertEquals(before, store.files.getValue("s1").size)
    }

    @Test
    fun aPauseCanBeForbiddenByTheDefinition() = runTest {
        val r = runner()
        r.start("s1", def.copy(allowPause = false))
        assertEquals("PAUSE_NOT_ALLOWED", assertFailsWith<ChallengeException> { r.pause("s1") }.code)
    }

    @Test
    fun aDefinitionThatBreaksItsRulesIsRefusedBeforeAnythingIsWritten() = runTest {
        val bad = def.copy(stages = listOf(stage("a", NativeProgressMetric.REPS, 0.0, NativeCompletionPolicy.AUTO, "m")))
        assertEquals("BAD_DEFINITION", assertFailsWith<ChallengeException> { runner().start("s1", bad) }.code)
        assertTrue(store.files.isEmpty())
    }

    @Test
    fun aSecondChallengeWhileOneIsOpenIsRefused() = runTest {
        val r = runner()
        r.start("s1", def)
        assertEquals("SESSION_OPEN", assertFailsWith<ChallengeException> { r.start("s2", def) }.code)
    }

    @Test
    fun samplesOfAnotherSessionAndOfASourceThatIsNotAllowedAreDropped() = runTest {
        val r = runner()
        r.start("s1", def)
        r.submitCounter("other", "gps-primary", 1, 0.0, 0)
        clock += 1000; r.submitCounter("other", "gps-primary", 1, 50.0, 0)
        r.submitCounter("s1", "pm5-rower", 1, 0.0, 0)
        clock += 1000; r.submitCounter("s1", "pm5-rower", 1, 8.0, 0)
        assertEquals(0.0, r.snapshot().stageProgress, 0.0)
    }

    @Test
    fun aSampleIsStampedWithItsRealTimeNotTheTimeOfTheCall() = runTest {
        val r = runner()
        r.start("s1", def) // at 1000
        clock = 6_000
        r.submitCounter("s1", "gps-primary", 1, 0.0, 4_000) // measured at 2000
        clock = 7_000
        r.submitCounter("s1", "gps-primary", 1, 10.0, 4_000) // measured at 3000: 1 s later, 10 m
        assertEquals(10.0, r.snapshot().stageProgress, 1e-9)
    }

    @Test
    fun aFailedWriteIsReportedAndStickyButTheChallengeGoesOn() = runTest {
        val r = runner()
        r.start("s1", def)
        val g = gps(r)
        r.submitCounter("s1", "gps-primary", 1, g.total, 0)
        store.failAppends = true
        g.run(2)
        val s = r.snapshot()
        assertTrue(s.journalFailed)
        assertTrue(s.error!!.startsWith("JOURNAL_WRITE_FAILED"))
        assertEquals(20.0, s.stageProgress, 1e-9)
        store.failAppends = false
        g.run(1)
        assertTrue(r.snapshot().journalFailed, "sticky")
    }

    @Test
    fun aChallengeThatCannotWriteItsFirstLinesIsNotStarted() = runTest {
        store.failAppends = true
        val r = runner()
        assertEquals("JOURNAL_WRITE_FAILED", assertFailsWith<ChallengeException> { r.start("s1", def) }.code)
        assertEquals(NativeChallengeState.IDLE, r.snapshot().state)
    }

    // ── the process dies ────────────────────────────────────────────────────

    private fun TestScope.runUntilTheRowStageAndDie() {
        val r = runner()
        r.start("s1", def)
        val g = gps(r)
        r.submitCounter("s1", "gps-primary", 1, g.total, 0)
        g.run(100)
        clock += 1000; r.nextStage("s1")
        r.submitDelta("s1", "manual", "tap-1", 50.0, 0)
        r.confirm("s1", NativeCompletionEvidence.MANUAL)
        clock += 1000; r.nextStage("s1")
        r.submitCounter("s1", "pm5-rower", 2, 100.0, 0)
        for (i in 1..50) { clock += 1000; r.submitCounter("s1", "pm5-rower", 2, 100.0 + i * 8, 0) }
        // ... and the process dies: this runner is simply dropped
    }

    @Test
    fun aRestoredChallengeComesBackPausedWithItsStagesAndProgress() = runTest {
        runUntilTheRowStageAndDie()
        assertEquals("s1", store.activeSessionId())
        clock += 3_600_000
        val snap = runner(store, RecordingSink(store)).restore("s1")
        assertEquals(NativeChallengeState.PAUSED, snap.state)
        assertEquals(listOf("run-1", "sled"), snap.completed.map { it.stageId })
        assertEquals("row", snap.stageId)
        assertEquals(400.0, snap.stageProgress, 1e-9)
        assertEquals(1L, snap.recoveries)
        assertEquals(NativeRestoreStatus.INTACT, snap.restoreStatus)
        assertTrue(snap.totalElapsedMs < 3_600_000, "the hour the process was dead is not counted")
    }

    @Test
    fun afterARestoreAMeasurementIsNeverCountedTwiceAndTheFirstSampleIsOnlyABaseline() = runTest {
        runUntilTheRowStageAndDie()
        val r2 = runner()
        r2.restore("s1")
        r2.resume("s1")
        r2.submitCounter("s1", "pm5-rower", 2, 100.0 + 50 * 8, 0) // a baseline
        assertEquals(400.0, r2.snapshot().stageProgress, 1e-9)
        clock += 1000
        r2.submitCounter("s1", "pm5-rower", 2, 100.0 + 51 * 8, 0)
        assertEquals(408.0, r2.snapshot().stageProgress, 1e-9)
        // the manual tap of the finished stage can never come back: the stage is not the active one
        r2.submitDelta("s1", "manual", "tap-1", 50.0, 0)
        assertEquals(408.0, r2.snapshot().stageProgress, 1e-9)
    }

    @Test
    fun restoringTwiceDoesNotReplayAgainAndIsIdempotent() = runTest {
        runUntilTheRowStageAndDie()
        val r2 = runner()
        val first = r2.restore("s1")
        val lines = store.files.getValue("s1").size
        val second = r2.restore("s1")
        assertEquals(lines, store.files.getValue("s1").size, "no second replay, no second Paused line")
        assertEquals(first.stageProgress, second.stageProgress, 0.0)
        assertEquals(1L, runner().restore("s1").recoveries, "a third engine restores the extended journal to the same challenge")
    }

    @Test
    fun aRebootThatRestartedTheMonotonicClockLowerStillAllowsAResume() = runTest {
        runUntilTheRowStageAndDie()
        clock = 500
        val r2 = runner()
        r2.restore("s1")
        assertEquals(NativeChallengeState.ACTIVE, r2.resume("s1").state)
    }

    @Test
    fun aDamagedTailIsCutOnTheDiskBeforeAnythingIsAppended() = runTest {
        runUntilTheRowStageAndDie()
        val lines = store.files.getValue("s1")
        lines[lines.lastIndex] = lines.last().dropLast(7)
        val damaged = lines.toList()
        val r2 = runner()
        assertEquals(NativeRestoreStatus.TAIL_REPAIRED, r2.restore("s1").restoreStatus)
        assertEquals(damaged, store.originals["s1"], "the damaged original is kept for diagnosis")
        r2.resume("s1")
        assertEquals(NativeRestoreStatus.INTACT, runner().restore("s1").restoreStatus, "nothing is hidden behind a damaged line")
    }

    @Test
    fun aDamagedMiddleKeepsOnlyThePrefixAndARepairThatFailsAppendsNothing() = runTest {
        runUntilTheRowStageAndDie()
        val lines = store.files.getValue("s1")
        lines[10] = lines[10].replace("|", "#")
        store.failReplace = true
        val before = lines.size
        val snap = runner().restore("s1")
        assertEquals(NativeRestoreStatus.PARTIAL, snap.restoreStatus)
        assertTrue(snap.journalFailed)
        assertTrue(snap.error!!.startsWith("JOURNAL_REPAIR_FAILED"))
        assertEquals(before, store.files.getValue("s1").size)
    }

    @Test
    fun anUnknownJournalIsNotRestorableAndACompletedChallengeRestoresCompleted() = runTest {
        assertEquals("NOT_RESTORABLE", assertFailsWith<ChallengeException> { runner().restore("nope") }.code)
        val d = NativeChallengeDefinition("x", 1, true, listOf(stage("a", NativeProgressMetric.REPS, 2.0, NativeCompletionPolicy.AUTO, "m")))
        val r = runner()
        r.start("done", d)
        r.submitDelta("done", "m", "1", 2.0, 0)
        val snap = runner().restore("done")
        assertEquals(NativeChallengeState.COMPLETED, snap.state)
        assertEquals(0L, snap.recoveries)
        assertNull(runner().activeSessionId())
    }

    @Test
    fun clearSessionDeletesTheJournalButNotAnOpenChallenge() = runTest {
        val r = runner()
        r.start("s1", def)
        assertEquals("SESSION_OPEN", assertFailsWith<ChallengeException> { r.clearSession("s1") }.code)
        val d = NativeChallengeDefinition("x", 1, true, listOf(stage("a", NativeProgressMetric.REPS, 1.0, NativeCompletionPolicy.AUTO, "m")))
        val r2 = runner()
        r2.start("s2", d)
        r2.submitDelta("s2", "m", "1", 1.0, 0)
        r2.clearSession("s2")
        assertTrue(store.files["s2"] == null)
    }

    @Test
    fun theSnapshotIsPublishedAboutOncePerSecond() = runTest {
        val r = runner()
        r.start()
        r.start("s1", def)
        val before = sink.snapshots.size
        advanceTimeBy(3_500)
        assertEquals(before + 3, sink.snapshots.size)
        r.stop()
    }

    @Test
    fun everyEnumOfTheCoreHasItsPigeonTwinInTheSameOrder() = runTest {
        assertEquals(challenge.model.ProgressMetric.values().map { it.name }, NativeProgressMetric.values().map { it.name })
        assertEquals(challenge.model.CompletionPolicy.values().map { it.name }, NativeCompletionPolicy.values().map { it.name })
        assertEquals(challenge.model.ChallengeState.values().map { it.name }, NativeChallengeState.values().map { it.name })
        assertEquals(challenge.model.StageStatus.values().map { it.name }, NativeStageStatus.values().map { it.name })
        assertEquals(challenge.model.CompletionEvidence.values().map { it.name }, NativeCompletionEvidence.values().map { it.name })
    }

    @Test
    fun theFileStoreAppendsReadsReplacesAtomicallyAndKeepsTheActivePointer() {
        val dir = File(System.getProperty("java.io.tmpdir"), "cf-" + System.nanoTime())
        val s = FileChallengeJournalStore(dir)
        s.append("a/b c", listOf("one", "two"))
        s.append("a/b c", listOf("three"))
        assertEquals(listOf("one", "two", "three"), s.read("a/b c"))
        s.append("a_b_c", listOf("x"))
        assertEquals(listOf("one", "two", "three"), s.read("a/b c"))
        s.setActive("a/b c")
        assertEquals("a/b c", s.activeSessionId())
        val kept = s.replaceKeepingOriginal("a/b c", listOf("one", "two"))
        assertEquals(listOf("one", "two"), s.read("a/b c"))
        assertEquals(3, File(dir, kept).readText().split('\n').count { it.isNotBlank() })
        s.append("a/b c", listOf("four"))
        assertEquals(listOf("one", "two", "four"), s.read("a/b c"))
        s.clear("a/b c")
        assertEquals(emptyList(), s.read("a/b c"))
        assertNull(s.activeSessionId())
        dir.deleteRecursively()
    }
}
