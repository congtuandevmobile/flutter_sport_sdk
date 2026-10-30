package workout

import workout.distance.DistanceLedger
import workout.distance.DistanceLedgerConfig
import workout.model.DistanceSource
import workout.model.DistanceSourceKind
import workout.model.WorkoutEvent
import workout.model.WorkoutMode
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNull
import kotlin.test.assertTrue

class LedgerTest {
    private val gps = DistanceSource("gps", DistanceSourceKind.GPS)
    private val foot = DistanceSource("footpod", DistanceSourceKind.COUNTER)
    private val tread = DistanceSource("treadmill", DistanceSourceKind.COUNTER)
    private val speed = DistanceSource("footpod-speed", DistanceSourceKind.SPEED)

    private var seq = 0L
    private fun ledger(mode: WorkoutMode = WorkoutMode.INDOOR_RUNNING, config: DistanceLedgerConfig = DistanceLedgerConfig.forMode(mode)): DistanceLedger {
        seq = 0
        return DistanceLedger(mode, config) { ++seq }.also { it.activate("workout started") }
    }

    private fun List<WorkoutEvent>.advances() = filterIsInstance<WorkoutEvent.DistanceAdvanced>()

    @Test fun theFirstSampleIsABaselineAndCreditsNothing() {
        val l = ledger()
        val events = l.onCounter(foot, 1, 1200.0, 0)
        assertEquals(0.0, l.distanceMeters, 0.0)
        assertTrue(events.any { it is WorkoutEvent.SourceSelected })
        assertTrue(events.any { it is WorkoutEvent.BaselineEstablished })
    }

    @Test fun onlyTheDifferencesAreAdded() {
        val l = ledger()
        l.onCounter(foot, 1, 1200.0, 0)
        l.onCounter(foot, 1, 1210.0, 3000)
        l.onCounter(foot, 1, 1220.0, 6000)
        assertEquals(20.0, l.distanceMeters, 1e-9)
    }

    @Test fun aReconnectedCounterThatRestartsAtZeroAddsNothingAndIsNeverNegative() {
        val l = ledger()
        l.onCounter(foot, 1, 1200.0, 0)
        l.onCounter(foot, 1, 1220.0, 6000)
        l.onCounter(foot, 2, 0.0, 9000) // a new connection: a new epoch, a new baseline
        l.onCounter(foot, 2, 12.0, 12_000)
        assertEquals(20.0 + 12.0, l.distanceMeters, 1e-9)
    }

    @Test fun aCounterThatGoesBackWithoutANewEpochTakesANewBaseline() {
        val l = ledger()
        l.onCounter(foot, 1, 1000.0, 0)
        l.onCounter(foot, 1, 1010.0, 3000)
        val e = l.onCounter(foot, 1, 5.0, 6000)
        assertEquals(10.0, l.distanceMeters, 1e-9)
        assertEquals("the counter went back", (e.single() as WorkoutEvent.BaselineEstablished).reason)
        l.onCounter(foot, 1, 15.0, 9000)
        assertEquals(20.0, l.distanceMeters, 1e-9)
    }

    @Test fun aJumpTheTimeCannotExplainIsASpikeNotDistance() {
        val l = ledger()
        l.onCounter(foot, 1, 0.0, 0)
        l.onCounter(foot, 1, 10.0, 3000)
        l.onCounter(foot, 1, 5000.0, 6000) // 4990 m in 3 s
        assertEquals(10.0, l.distanceMeters, 1e-9)
        l.onCounter(foot, 1, 5010.0, 9000)
        assertEquals(20.0, l.distanceMeters, 1e-9)
    }

    @Test fun pauseAndResumeNeverCreditThePausedDistance() {
        val l = ledger()
        l.onCounter(foot, 1, 0.0, 0)
        l.onCounter(foot, 1, 1000.0, 300_000) // 1000 m in 5 min (3.3 m/s: plausible)
        // hmm: that is a legal 1000 m over 300 s; then pause
        l.deactivate()
        l.onCounter(foot, 1, 1500.0, 480_000) // the machine counted 500 m while paused
        l.activate("resumed")
        l.onCounter(foot, 1, 1501.0, 481_000)
        l.onCounter(foot, 1, 1504.0, 484_000)
        assertEquals(1000.0 + 3.0, l.distanceMeters, 1e-9)
    }

    @Test fun switchingTheSourceKeepsTheDistanceAndNeverAssignsTheNewTotal() {
        val l = ledger()
        l.onCounter(foot, 1, 0.0, 0)
        for (i in 1..10) l.onCounter(foot, 1, i * 100.0, i * 30_000L) // 1000 m
        assertEquals(1000.0, l.distanceMeters, 1e-9)
        l.setPreferred(tread, 300_000)
        l.onCounter(tread, 1, 2500.0, 300_000) // its own total: only a baseline
        assertEquals(1000.0, l.distanceMeters, 1e-9)
        assertEquals(tread, l.selected)
        l.onCounter(tread, 1, 2510.0, 303_000)
        l.onCounter(foot, 1, 1010.0, 303_000) // the old source keeps talking: ignored
        assertEquals(1010.0, l.distanceMeters, 1e-9)
    }

    @Test fun twoSourcesAreNeverAdded() {
        val l = ledger()
        l.onCounter(foot, 1, 0.0, 0)
        l.onCounter(tread, 1, 0.0, 0)
        for (i in 1..5) {
            l.onCounter(foot, 1, i * 10.0, i * 3000L)
            l.onCounter(tread, 1, i * 12.0, i * 3000L)
        }
        assertEquals(foot, l.selected, "the first source stays")
        assertEquals(50.0, l.distanceMeters, 1e-9)
    }

    @Test fun aQuietSourceLosesTheDistanceAndDoesNotTakeItBackWhenItReturns() {
        val l = ledger()
        l.onCounter(foot, 1, 0.0, 0)
        l.onCounter(foot, 1, 10.0, 3000)
        l.onCounter(tread, 1, 100.0, 4000)
        l.onCounter(tread, 1, 110.0, 8000)
        l.onCounter(tread, 1, 120.0, 12_000)
        l.onCounter(tread, 1, 130.0, 16_000) // the footpod was last seen at 3 s: stale at 16 s
        assertEquals(tread, l.selected)
        val before = l.distanceMeters
        l.onCounter(foot, 1, 20.0, 18_000) // it is back
        l.onCounter(tread, 1, 140.0, 20_000)
        assertEquals(tread, l.selected, "no pulling back, no flapping")
        assertTrue(l.distanceMeters > before)
        // 10 m from the footpod; the treadmill's sample that took over (130) is a baseline, then +10 at 20 s: the quiet gap is not credited
        assertEquals(10.0 + 10.0, l.distanceMeters, 1e-9)
    }

    @Test fun theUserPreferenceWinsWhileItIsFreshAndFallsBackWhenItIsNot() {
        val l = ledger()
        l.onCounter(foot, 1, 0.0, 0)
        l.onCounter(tread, 1, 0.0, 0)
        l.setPreferred(tread, 1000)
        assertEquals(tread, l.selected)
        l.onCounter(foot, 1, 10.0, 20_000)
        l.tick(20_000) // the treadmill has been quiet for 20 s
        assertEquals(foot, l.selected)
        l.setPreferred(null, 20_000)
    }

    @Test fun whenTheChosenSourceGoesQuietTheBestKindForTheModeTakesOver() {
        // outdoors: GPS before a counter before a speed
        val out = ledger(WorkoutMode.OUTDOOR_RUNNING)
        out.onCounter(tread, 1, 0.0, 0) // the first source is chosen as it arrives and stays while it is fresh
        out.onSpeed(speed, 1, 3.0, 5_000)
        out.onCounter(gps, 1, 0.0, 5_000)
        assertEquals(tread, out.selected)
        out.tick(12_000) // the treadmill has been quiet for 12 s; a speed and a GPS are both fresh
        assertEquals(gps, out.selected)
        // indoors: a counter before a speed before GPS
        val ind = ledger(WorkoutMode.INDOOR_RUNNING)
        ind.onSpeed(speed, 1, 3.0, 0)
        ind.onCounter(gps, 1, 0.0, 5_000)
        ind.onCounter(foot, 1, 0.0, 5_000)
        ind.tick(12_000)
        assertEquals(foot, ind.selected)
    }

    @Test fun anOlderSampleAndAnOlderEpochAreIgnored() {
        val l = ledger()
        l.onCounter(foot, 2, 0.0, 5000)
        l.onCounter(foot, 2, 10.0, 8000)
        assertTrue(l.onCounter(foot, 2, 99.0, 7000).isEmpty())
        assertTrue(l.onCounter(foot, 1, 99.0, 9000).isEmpty())
        assertEquals(10.0, l.distanceMeters, 1e-9)
    }

    @Test fun invalidInputIsIgnored() {
        val l = ledger()
        assertTrue(l.onCounter(foot, 1, Double.NaN, 0).isEmpty())
        assertTrue(l.onCounter(foot, 1, -5.0, 0).isEmpty())
        assertTrue(l.onCounter(foot, 1, 5.0, -1).isEmpty())
        assertTrue(l.onCounter(speed, 1, 5.0, 0).isEmpty(), "a speed source is not a counter")
        assertTrue(l.onSpeed(foot, 1, 5.0, 0).isEmpty(), "a counter source is not a speed")
        assertNull(l.selected)
    }

    // ---- speed integration ----

    @Test fun aSpeedIsIntegratedOverTime() {
        val l = ledger()
        l.onSpeed(speed, 1, 3.0, 0)
        for (t in 1..10) l.onSpeed(speed, 1, 3.0, t * 1000L)
        assertEquals(30.0, l.distanceMeters, 1e-9) // 3 m/s for 10 s
    }

    @Test fun aSpeedIsNotIntegratedAcrossAGapOfLostData() {
        val l = ledger()
        l.onSpeed(speed, 1, 3.0, 0)
        l.onSpeed(speed, 1, 3.0, 1000)
        l.onSpeed(speed, 1, 3.0, 61_000) // a minute of silence: not 180 m
        l.onSpeed(speed, 1, 3.0, 62_000)
        assertEquals(3.0 + 3.0, l.distanceMeters, 1e-9)
    }

    @Test fun aSpeedIsNotIntegratedAcrossAPause() {
        val l = ledger()
        l.onSpeed(speed, 1, 3.0, 0)
        l.onSpeed(speed, 1, 3.0, 1000)
        l.deactivate()
        l.onSpeed(speed, 1, 3.0, 2000)
        l.onSpeed(speed, 1, 3.0, 3000)
        l.activate("resumed")
        l.onSpeed(speed, 1, 3.0, 4000) // baseline
        l.onSpeed(speed, 1, 3.0, 5000)
        assertEquals(3.0 + 3.0, l.distanceMeters, 1e-9)
    }

    @Test fun anImpossibleSpeedIsDroppedAndTheNextOneStartsOver() {
        val l = ledger()
        l.onSpeed(speed, 1, 3.0, 0)
        l.onSpeed(speed, 1, 3.0, 1000)
        l.onSpeed(speed, 1, 99.0, 2000)
        l.onSpeed(speed, 1, 3.0, 3000) // a baseline again
        l.onSpeed(speed, 1, 3.0, 4000)
        assertEquals(3.0 + 3.0, l.distanceMeters, 1e-9)
    }

    @Test fun aTrapezoidUsesTheAverageOfTwoSpeeds() {
        val l = ledger()
        l.onSpeed(speed, 1, 2.0, 0)
        l.onSpeed(speed, 1, 4.0, 2000)
        assertEquals(6.0, l.distanceMeters, 1e-9)
    }

    @Test fun cyclingAllowsFasterSpeedsThanRunning() {
        val run = DistanceLedgerConfig.forMode(WorkoutMode.INDOOR_RUNNING)
        val bike = DistanceLedgerConfig.forMode(WorkoutMode.INDOOR_CYCLING)
        assertTrue(bike.maxSpeedMps > run.maxSpeedMps)
        assertFailsWith<IllegalArgumentException> { DistanceLedgerConfig(staleAfterMs = 0) }
    }

    @Test fun theDistanceIsKeptWhenAllSourcesGoQuiet() {
        val l = ledger()
        l.onCounter(foot, 1, 0.0, 0)
        l.onCounter(foot, 1, 30.0, 6000)
        l.tick(600_000)
        assertEquals(30.0, l.distanceMeters, 1e-9)
    }

    @Test fun everyEventHasANewIncreasingSequenceNumber() {
        val l = ledger()
        val events = ArrayList<WorkoutEvent>()
        events += l.onCounter(foot, 1, 0.0, 0)
        for (i in 1..5) events += l.onCounter(foot, 1, i * 10.0, i * 3000L)
        assertEquals(events.map { it.seq }, events.map { it.seq }.sorted())
        assertEquals(events.size, events.map { it.seq }.toSet().size)
        assertEquals(5, events.advances().size)
    }

    @Test fun aCounterThatChangesAtTheSameInstantCreditsNothing() {
        val l = ledger()
        l.onCounter(foot, 1, 1200.0, 0)
        l.onCounter(foot, 1, 1210.0, 3000)
        val events = l.onCounter(foot, 1, 1214.0, 3000) // same timestamp: 0 s elapsed must not let the spike slack credit 4 m
        assertEquals(10.0, l.distanceMeters, 1e-9)
        assertTrue(events.advances().isEmpty())
        l.onCounter(foot, 1, 1220.0, 6000) // the next real sample is still measured from the last credited one
        assertEquals(20.0, l.distanceMeters, 1e-9)
    }
}
