package workout

import kotlin.test.Test
import kotlin.test.assertEquals
import workout.model.DistanceSource
import workout.model.DistanceSourceKind
import workout.model.WorkoutMode
import workout.session.WorkoutSession

/**
 * Additional RED tests against 47e98d2. Place in:
 * packages/flutter_workout/workout-core/src/commonTest/kotlin/workout/WorkoutLateSampleRegressionTest.kt
 */
class WorkoutLateSampleRegressionTest {
    @Test
    fun counterMeasuredBeforeWorkoutStartCannotSeedWorkAfterStart() {
        val workout = WorkoutSession(WorkoutMode.INDOOR_RUNNING)
        val footpod = DistanceSource("footpod", DistanceSourceKind.COUNTER)
        workout.start(1_000)
        workout.onCounter(footpod, 1, 100.0, 500) // old callback delivered after workout.start
        workout.onCounter(footpod, 1, 110.0, 1_500) // first post-start reading
        assertEquals(0.0, workout.snapshot(1_500).distanceMeters, 0.0)
        workout.onCounter(footpod, 1, 115.0, 2_500)
        assertEquals(5.0, workout.snapshot(2_500).distanceMeters, 1e-9)
    }

    @Test
    fun oldCounterCallbacksArrivingAfterResumeMustNotCreditPausedTime() {
        val workout = WorkoutSession(WorkoutMode.INDOOR_RUNNING)
        val footpod = DistanceSource("footpod", DistanceSourceKind.COUNTER)
        workout.start(0)
        workout.onCounter(footpod, 1, 0.0, 0)
        workout.pause(1_000)
        workout.resume(5_000)
        workout.onCounter(footpod, 1, 100.0, 2_500)
        workout.onCounter(footpod, 1, 110.0, 3_500)
        assertEquals(0.0, workout.snapshot(5_000).distanceMeters, 0.0)
        workout.onCounter(footpod, 1, 120.0, 5_500)
        workout.onCounter(footpod, 1, 125.0, 6_500)
        assertEquals(5.0, workout.snapshot(6_500).distanceMeters, 1e-9)
    }

    @Test
    fun oldSpeedCallbacksArrivingAfterResumeMustNotIntegratePausedTime() {
        val workout = WorkoutSession(WorkoutMode.INDOOR_RUNNING)
        val speed = DistanceSource("treadmill", DistanceSourceKind.SPEED)
        workout.start(0)
        workout.onSpeed(speed, 1, 2.0, 0)
        workout.pause(1_000)
        workout.resume(5_000)
        workout.onSpeed(speed, 1, 2.0, 2_500)
        workout.onSpeed(speed, 1, 2.0, 3_500)
        assertEquals(0.0, workout.snapshot(5_000).distanceMeters, 0.0)
        workout.onSpeed(speed, 1, 2.0, 5_500)
        workout.onSpeed(speed, 1, 2.0, 6_500)
        assertEquals(2.0, workout.snapshot(6_500).distanceMeters, 1e-9)
    }
}
