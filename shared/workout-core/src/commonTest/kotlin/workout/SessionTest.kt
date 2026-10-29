package workout

import workout.model.DistanceSource
import workout.model.DistanceSourceKind
import workout.model.WorkoutEvent
import workout.model.WorkoutMode
import workout.model.WorkoutState
import workout.session.WorkoutSession
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

class SessionTest {
    private val foot = DistanceSource("footpod", DistanceSourceKind.COUNTER)
    private val tread = DistanceSource("treadmill", DistanceSourceKind.COUNTER)

    @Test fun theLifecycleAndItsTimes() {
        val s = WorkoutSession(WorkoutMode.INDOOR_RUNNING)
        assertEquals(WorkoutState.IDLE, s.snapshot(0).state)
        s.start(1000)
        assertEquals(WorkoutState.RUNNING, s.snapshot(1000).state)
        assertEquals(4000L, s.snapshot(5000).activeMs)
        s.pause(5000)
        assertEquals(4000L, s.snapshot(9000).activeMs, "a pause is not activity")
        assertEquals(4000L, s.snapshot(9000).pausedMs)
        s.resume(9000)
        assertEquals(6000L, s.snapshot(11_000).activeMs)
        s.finish(11_000)
        val end = s.snapshot(999_999)
        assertEquals(WorkoutState.FINISHED, end.state)
        assertEquals(6000L, end.activeMs)
        assertEquals(4000L, end.pausedMs)
    }

    @Test fun invalidTransitionsDoNothing() {
        val s = WorkoutSession(WorkoutMode.INDOOR_RUNNING)
        assertTrue(s.pause(0).isEmpty())
        assertTrue(s.resume(0).isEmpty())
        assertTrue(s.finish(0).isEmpty())
        s.start(0)
        assertTrue(s.start(10).isEmpty())
        assertTrue(s.resume(10).isEmpty())
        s.pause(100)
        assertTrue(s.pause(200).isEmpty())
        s.finish(300)
        assertTrue(s.start(400).isEmpty())
        assertTrue(s.pause(500).isEmpty())
        assertTrue(s.onCounter(foot, 1, 10.0, 600).isEmpty())
    }

    @Test fun finishingWhilePausedKeepsThePausedTime() {
        val s = WorkoutSession(WorkoutMode.INDOOR_RUNNING)
        s.start(0); s.pause(1000); s.finish(5000)
        val e = s.snapshot(10_000)
        assertEquals(1000L, e.activeMs)
        assertEquals(4000L, e.pausedMs)
    }

    @Test fun aSensorThatWasConnectedBeforeTheStartDoesNotPutOldDataInTheWorkout() {
        val s = WorkoutSession(WorkoutMode.INDOOR_RUNNING)
        assertTrue(s.onCounter(foot, 1, 5000.0, 0).isEmpty(), "before the start: no workout yet")
        s.start(1000)
        s.onCounter(foot, 1, 5010.0, 2000) // the first sample of the workout is a baseline
        s.onCounter(foot, 1, 5020.0, 5000)
        assertEquals(10.0, s.snapshot(5000).distanceMeters, 1e-9)
    }

    @Test fun theExampleOfTheReportWithAPause() {
        // 05:00 1000 m; 05:01 pause; 08:00 resume; 08:01 the footpod reports 1500 m: the 500 m of the pause are not credited
        val s = WorkoutSession(WorkoutMode.INDOOR_RUNNING)
        s.start(0)
        s.onCounter(foot, 1, 0.0, 0)
        for (i in 1..10) s.onCounter(foot, 1, i * 100.0, i * 30_000L)
        s.pause(301_000)
        s.onCounter(foot, 1, 1500.0, 480_000)
        s.resume(480_500)
        s.onCounter(foot, 1, 1501.0, 481_000)
        s.onCounter(foot, 1, 1504.0, 484_000)
        assertEquals(1003.0, s.snapshot(484_000).distanceMeters, 1e-9)
    }

    @Test fun theSensorLostInTheMiddleDoesNotStopTheClock() {
        val s = WorkoutSession(WorkoutMode.INDOOR_RUNNING)
        s.start(0)
        s.onCounter(foot, 1, 0.0, 0)
        s.onCounter(foot, 1, 30.0, 10_000)
        val after = s.snapshot(120_000)
        assertEquals(120_000L, after.activeMs)
        assertEquals(30.0, after.distanceMeters, 1e-9, "the distance is kept, not invented")
    }

    @Test fun noSourceMeansDistanceZeroAndNoSourceNotAGuess() {
        val s = WorkoutSession(WorkoutMode.INDOOR_RUNNING)
        s.start(0)
        val snap = s.snapshot(60_000)
        assertEquals(0.0, snap.distanceMeters, 0.0)
        assertNull(snap.distanceSource)
    }

    @Test fun theStartedEventCarriesTheModeAndEverySequenceIsOneMore() {
        val s = WorkoutSession(WorkoutMode.OUTDOOR_CYCLING)
        val all = ArrayList<WorkoutEvent>()
        all += s.start(0)
        all += s.onCounter(foot, 1, 0.0, 100)
        all += s.onCounter(foot, 1, 5.0, 2000)
        all += s.pause(3000)
        all += s.resume(4000)
        all += s.finish(5000)
        assertEquals((1L..all.size).toList(), all.map { it.seq })
        assertEquals(WorkoutMode.OUTDOOR_CYCLING, (all.first() as WorkoutEvent.Started).mode)
    }

    @Test fun theDistanceSourceInTheSnapshotIsTheChosenOne() {
        val s = WorkoutSession(WorkoutMode.INDOOR_RUNNING)
        s.start(0)
        s.onCounter(foot, 1, 0.0, 0)
        s.onCounter(tread, 1, 0.0, 0)
        assertEquals(foot, s.snapshot(0).distanceSource)
        s.setPreferredSource(tread, 100)
        assertEquals(tread, s.snapshot(100).distanceSource)
    }
}
