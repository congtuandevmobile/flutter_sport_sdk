package workout.session

import workout.distance.DistanceLedger
import workout.distance.DistanceLedgerConfig
import workout.model.DistanceSource
import workout.model.WorkoutEvent
import workout.model.WorkoutMode
import workout.model.WorkoutSnapshot
import workout.model.WorkoutState

/** A restored session and the events the recovery itself adds (to append to the journal). */
class RestoredSession(val session: WorkoutSession, val recoveryEvents: List<WorkoutEvent>, val ignoredEvents: Int)

/**
 * One workout: a state machine (IDLE, RUNNING, PAUSED, FINISHED), the active and paused time, and the [DistanceLedger]. It owns
 * the state of the SESSION; a sensor connection is not part of it, so a sensor that stays connected between two workouts never
 * puts the old workout's data into the new one, and a lost sensor never stops the clock.
 *
 * Every call returns the events it caused (with a sequence number): the journal stores them. Times are the phone's monotonic
 * clock. The pause is not in `activeMs`. An invalid transition (pause while paused, anything after finish) does nothing and
 * returns no event. Not thread-safe.
 */
class WorkoutSession(
    val mode: WorkoutMode,
    config: DistanceLedgerConfig = DistanceLedgerConfig.forMode(mode),
) {
    private var seq = 0L
    private val ledger = DistanceLedger(mode, config) { ++seq }
    private var state = WorkoutState.IDLE
    private var runningSinceMs = -1L
    private var pausedSinceMs = -1L
    private var activeMs = 0L
    private var pausedMs = 0L
    private var lastSeq = 0L

    val currentState: WorkoutState get() = state

    fun start(nowMs: Long): List<WorkoutEvent> {
        if (state != WorkoutState.IDLE || nowMs < 0L) return emptyList()
        state = WorkoutState.RUNNING
        runningSinceMs = nowMs
        ledger.activate("workout started")
        return record(listOf(WorkoutEvent.Started(++seq, nowMs, mode)) + ledger.tick(nowMs))
    }

    fun pause(nowMs: Long): List<WorkoutEvent> {
        if (state != WorkoutState.RUNNING || nowMs < runningSinceMs) return emptyList()
        activeMs += nowMs - runningSinceMs
        pausedSinceMs = nowMs
        state = WorkoutState.PAUSED
        ledger.deactivate()
        return record(listOf(WorkoutEvent.Paused(++seq, nowMs)))
    }

    fun resume(nowMs: Long): List<WorkoutEvent> {
        if (state != WorkoutState.PAUSED || nowMs < pausedSinceMs) return emptyList()
        pausedMs += nowMs - pausedSinceMs
        runningSinceMs = nowMs
        state = WorkoutState.RUNNING
        ledger.activate("resumed")
        return record(listOf(WorkoutEvent.Resumed(++seq, nowMs)) + ledger.tick(nowMs))
    }

    fun finish(nowMs: Long): List<WorkoutEvent> {
        when (state) {
            WorkoutState.RUNNING -> {
                if (nowMs < runningSinceMs) return emptyList()
                activeMs += nowMs - runningSinceMs
            }
            WorkoutState.PAUSED -> {
                if (nowMs < pausedSinceMs) return emptyList()
                pausedMs += nowMs - pausedSinceMs
            }
            else -> return emptyList()
        }
        state = WorkoutState.FINISHED
        ledger.deactivate()
        return record(listOf(WorkoutEvent.Finished(++seq, nowMs)))
    }

    /** A cumulative distance (a GPS total, a footpod, a treadmill). [epoch] grows with every new connection of the source. */
    fun onCounter(source: DistanceSource, epoch: Long, meters: Double, atMs: Long): List<WorkoutEvent> =
        if (!takesSamples()) emptyList() else record(ledger.onCounter(source, epoch, meters, atMs))

    /** An instantaneous speed in metres per second, integrated over time while the workout runs. */
    fun onSpeed(source: DistanceSource, epoch: Long, mps: Double, atMs: Long): List<WorkoutEvent> =
        if (!takesSamples()) emptyList() else record(ledger.onSpeed(source, epoch, mps, atMs))

    /** The user's choice of distance source (null clears it). */
    fun setPreferredSource(source: DistanceSource?, nowMs: Long): List<WorkoutEvent> =
        if (state == WorkoutState.FINISHED) emptyList() else record(ledger.setPreferred(source, nowMs))

    /** A sample before the workout started (a sensor that was already connected) or after it finished belongs to no workout. */
    private fun takesSamples() = state == WorkoutState.RUNNING || state == WorkoutState.PAUSED

    /** Lets a source that went quiet lose the distance to another one, without waiting for a sample. */
    fun tick(nowMs: Long): List<WorkoutEvent> =
        if (!takesSamples()) emptyList() else record(ledger.tick(nowMs))

    fun snapshot(nowMs: Long): WorkoutSnapshot {
        val active = activeMs + if (state == WorkoutState.RUNNING) maxOf(0L, nowMs - runningSinceMs) else 0L
        val paused = pausedMs + if (state == WorkoutState.PAUSED) maxOf(0L, nowMs - pausedSinceMs) else 0L
        return WorkoutSnapshot(state, mode, active, paused, ledger.distanceMeters, ledger.selected, lastSeq)
    }

    private fun record(events: List<WorkoutEvent>): List<WorkoutEvent> {
        if (events.isNotEmpty()) lastSeq = events.last().seq
        return events
    }

    companion object {
        /** A session with the default limits of [mode] (Swift cannot use Kotlin default arguments). */
        fun forMode(mode: WorkoutMode): WorkoutSession = WorkoutSession(mode)

        /**
         * Rebuilds a session from its journal events, in any order and with duplicates: an event whose sequence number was already
         * applied is ignored, so replaying twice (or a journal with a repeated line) gives the same session. A session that was
         * RUNNING when the process died comes back PAUSED at its last event: the time since is NOT credited as activity and no
         * distance is invented; the recovery adds a Paused event for the journal. Returns null when there is no Started event.
         */
        fun restore(events: List<WorkoutEvent>): RestoredSession? {
            val ordered = events.sortedBy { it.seq }
            val started = ordered.firstOrNull { it is WorkoutEvent.Started } as? WorkoutEvent.Started ?: return null
            val session = WorkoutSession(started.mode)
            var last = 0L
            var ignored = 0
            for (e in ordered) {
                if (e.seq <= last) { ignored += 1; continue }
                session.apply(e)
                last = e.seq
            }
            session.seq = last
            session.lastSeq = last
            val recovery = ArrayList<WorkoutEvent>(1)
            if (session.state == WorkoutState.RUNNING) {
                val at = ordered.last().atMs
                session.activeMs += maxOf(0L, at - session.runningSinceMs)
                session.pausedSinceMs = at
                session.state = WorkoutState.PAUSED
                session.ledger.deactivate()
                val paused = WorkoutEvent.Paused(++session.seq, at)
                session.lastSeq = paused.seq
                recovery.add(paused)
            }
            return RestoredSession(session, recovery, ignored)
        }
    }

    private fun apply(e: WorkoutEvent) {
        when (e) {
            is WorkoutEvent.Started -> {
                state = WorkoutState.RUNNING
                runningSinceMs = e.atMs
            }
            is WorkoutEvent.Paused -> if (state == WorkoutState.RUNNING) {
                activeMs += maxOf(0L, e.atMs - runningSinceMs)
                pausedSinceMs = e.atMs
                state = WorkoutState.PAUSED
            }
            is WorkoutEvent.Resumed -> if (state == WorkoutState.PAUSED) {
                pausedMs += maxOf(0L, e.atMs - pausedSinceMs)
                runningSinceMs = e.atMs
                state = WorkoutState.RUNNING
            }
            is WorkoutEvent.Finished -> {
                if (state == WorkoutState.RUNNING) activeMs += maxOf(0L, e.atMs - runningSinceMs)
                if (state == WorkoutState.PAUSED) pausedMs += maxOf(0L, e.atMs - pausedSinceMs)
                state = WorkoutState.FINISHED
            }
            is WorkoutEvent.DistanceAdvanced -> ledger.restoreDistance(e.deltaMeters)
            is WorkoutEvent.SourceSelected -> ledger.restoreSelected(e.source)
            is WorkoutEvent.BaselineEstablished -> Unit // baselines are never restored: every source starts a new one
        }
    }
}
