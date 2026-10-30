package io.github.congtuandevmobile.flutter_workout

import java.io.IOException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import workout.journal.JournalStatus
import workout.journal.WorkoutJournal
import workout.model.DistanceSource
import workout.model.DistanceSourceKind
import workout.model.WorkoutEvent
import workout.model.WorkoutMode
import workout.model.WorkoutState
import workout.session.WorkoutSession

/** A failure with a stable code (the plugin turns it into a `FlutterError`). */
class WorkoutException(val code: String, message: String) : Exception(message)

/** What the engine tells the Flutter side (the plugin turns it into a Pigeon call on the main thread). */
interface WorkoutSink {
    fun onSnapshot(snapshot: NativeWorkoutSnapshot)
}

/**
 * Owns ONE workout: a [WorkoutSession] of the shared core and its journal. The rule that matters: every event the core returns is
 * appended to the journal (and synced) BEFORE the snapshot that shows its effect is published, so a number on the screen is never
 * ahead of the disk. A failed write does not stop the workout, but `journalFailed` becomes true and stays true.
 *
 * Time is the phone's monotonic clock plus a shift: after a restore the clock continues from the last journal event even if the
 * phone rebooted (the monotonic clock then restarted lower), so a restored session can always resume. Samples are stamped with their
 * real time (now minus their age). A sample for another session id is dropped. All state is guarded by [lock].
 */
class WorkoutEngine(
    private val store: WorkoutJournalStore,
    private val scope: CoroutineScope,
    private val monotonicMs: () -> Long,
    private val sink: WorkoutSink,
    private val snapshotEveryMs: Long = 1_000,
) {
    private val lock = Any()
    private var session: WorkoutSession? = null
    private var sessionId: String? = null
    private var shiftMs = 0L
    private var journalFailed = false
    private var error: String? = null
    private var restoreStatus = NativeRestoreStatus.NOT_RESTORED
    private var ticker: Job? = null

    fun start() {
        synchronized(lock) {
            if (ticker != null) return
            ticker = scope.launch {
                while (true) {
                    delay(snapshotEveryMs)
                    synchronized(lock) { session?.let { persist(it.tick(now())) } }
                    publish()
                }
            }
        }
    }

    fun stop() {
        synchronized(lock) {
            ticker?.cancel()
            ticker = null
        }
    }

    fun start(id: String, mode: NativeWorkoutMode): NativeWorkoutSnapshot {
        synchronized(lock) {
            val open = session
            if (open != null && (open.currentState == WorkoutState.RUNNING || open.currentState == WorkoutState.PAUSED)) {
                throw WorkoutException("SESSION_OPEN", "workout $sessionId is still open")
            }
            // The previous workout finished in memory but its journal is NOT (fully) on the disk: the active pointer is the only way to
            // recover it, and a new workout would replace it. Recover it, or discard it on purpose with clearSession.
            if (open != null && journalFailed) {
                throw WorkoutException("RECOVERY_REQUIRED", "the previous workout $sessionId has a journal failure: recover it or clear it first")
            }
            if (id.isBlank()) throw WorkoutException("BAD_SESSION", "the session id is empty")
            // A session id is used ONCE: lines appended behind another workout's journal would be restored as that workout.
            if (store.exists(id)) throw WorkoutException("SESSION_EXISTS", "a journal already exists for $id: clear it or use another id")
            val created = WorkoutSession.forMode(WorkoutMode.valueOf(mode.name))
            val events = created.start(now())
            try {
                store.append(id, events.map { WorkoutJournal.encode(it) })
                store.setActive(id)
            } catch (e: IOException) {
                // A workout that cannot even write its first line is not started: nothing would survive the process dying. What the
                // attempt left behind (an empty file) must not make the id look taken on the next try.
                try { store.clear(id) } catch (_: IOException) {}
                throw WorkoutException("JOURNAL_WRITE_FAILED", e.message ?: "I/O error")
            }
            session = created
            sessionId = id
            journalFailed = false
            error = null
            restoreStatus = NativeRestoreStatus.NOT_RESTORED
        }
        return snapshotAndPublish()
    }

    fun pause(id: String): NativeWorkoutSnapshot = change(id) { it.pause(now()) }
    fun resume(id: String): NativeWorkoutSnapshot = change(id) { it.resume(now()) }

    /**
     * Finishes the workout. The Finished event is persisted and the active pointer released in ONE locked step, BEFORE the snapshot is
     * built, so the snapshot already shows a failed write. The pointer goes only when the Finished line is really on the disk: with a
     * journal failure the journal may still say "running", and the pointer is what leads to it after a crash.
     */
    fun finish(id: String): NativeWorkoutSnapshot {
        synchronized(lock) {
            val s = session
            if (s == null || sessionId != id) throw WorkoutException("NO_SESSION", "no open workout $id")
            persist(s.finish(now()))
            if (s.currentState == WorkoutState.FINISHED && !journalFailed) {
                try { store.setActive(null) } catch (e: IOException) { fail(e) }
            }
        }
        return snapshotAndPublish()
    }

    /** The phone's monotonic time NOW: the plugin takes it when a sample ARRIVES, before the sample waits in the queue. */
    fun receivedAt(): Long = monotonicMs()

    fun submitCounter(id: String, source: NativeSourceRef, epoch: Long, meters: Double, ageMs: Long, receivedMonotonicMs: Long? = null) {
        if (feed(id, ageMs, receivedMonotonicMs) { s, at -> s.onCounter(distanceSource(source), epoch, meters, at) }) publish()
    }

    fun submitSpeed(id: String, source: NativeSourceRef, epoch: Long, mps: Double, ageMs: Long, receivedMonotonicMs: Long? = null) {
        if (feed(id, ageMs, receivedMonotonicMs) { s, at -> s.onSpeed(distanceSource(source), epoch, mps, at) }) publish()
    }

    fun setPreferred(id: String, source: NativeSourceRef?) {
        change(id) { it.setPreferredSource(source?.let { s -> distanceSource(s) }, now()) }
    }

    fun snapshot(): NativeWorkoutSnapshot = synchronized(lock) { makeSnapshot() }

    /** Rebuilds [id] from its journal. It comes back PAUSED; nothing is replayed when this engine already runs it. */
    fun restore(id: String): NativeWorkoutSnapshot {
        synchronized(lock) {
            if (sessionId == id && session != null) return makeSnapshot()
            val open = session
            if (open != null && (open.currentState == WorkoutState.RUNNING || open.currentState == WorkoutState.PAUSED)) {
                throw WorkoutException("SESSION_OPEN", "workout $sessionId is still open") // restoring another one would replace it
            }
            val lines = try { store.read(id) } catch (e: IOException) { throw WorkoutException("RESTORE_FAILED", e.message ?: "I/O error") }
            val recovered = WorkoutJournal.recover(lines) ?: throw WorkoutException("NOT_RESTORABLE", "no usable journal for $id")
            val all = recovered.read.events + recovered.restored.recoveryEvents
            val lastAt = all.maxOfOrNull { it.atMs } ?: 0L
            shiftMs = maxOf(0L, lastAt - monotonicMs())
            session = recovered.restored.session
            sessionId = id
            journalFailed = false
            error = null
            restoreStatus = when (recovered.read.status) {
                JournalStatus.INTACT -> NativeRestoreStatus.INTACT
                JournalStatus.TAIL_REPAIRED -> NativeRestoreStatus.TAIL_REPAIRED
                JournalStatus.PARTIAL -> NativeRestoreStatus.PARTIAL
            }
            // A damaged journal is cut on the disk BEFORE anything is appended: new lines behind a damaged one would be hidden from
            // the next restore. The damaged original stays next to the journal. If the repair fails, nothing is appended.
            var repaired = true
            if (recovered.read.status != JournalStatus.INTACT) {
                try {
                    store.replaceKeepingOriginal(id, recovered.read.events.map { WorkoutJournal.encode(it) })
                } catch (e: IOException) {
                    repaired = false
                    journalFailed = true
                    error = "JOURNAL_REPAIR_FAILED: ${e.message ?: "I/O error"}"
                }
            }
            if (repaired) persist(recovered.restored.recoveryEvents)
            try {
                store.setActive(if (recovered.restored.session.currentState == WorkoutState.FINISHED) null else id)
            } catch (e: IOException) {
                fail(e)
            }
        }
        return snapshotAndPublish()
    }

    fun activeSessionId(): String? = store.activeSessionId()

    fun clearSession(id: String) {
        synchronized(lock) {
            if (sessionId == id && session != null && session!!.currentState != WorkoutState.FINISHED) {
                throw WorkoutException("SESSION_OPEN", "workout $id is still open")
            }
            try { store.clear(id) } catch (e: IOException) { throw WorkoutException("JOURNAL_WRITE_FAILED", e.message ?: "I/O error") }
            if (sessionId == id) {
                session = null
                sessionId = null
                journalFailed = false
                error = null
            }
        }
        publish()
    }

    // ── internals ───────────────────────────────────────────────────────────

    private fun now(): Long = monotonicMs() + shiftMs

    /** Runs [block] on the open session [id], persists what it caused, and publishes AFTER the write. */
    private fun change(id: String, block: (WorkoutSession) -> List<WorkoutEvent>): NativeWorkoutSnapshot {
        synchronized(lock) {
            val s = session
            if (s == null || sessionId != id) throw WorkoutException("NO_SESSION", "no open workout $id")
            persist(block(s))
        }
        return snapshotAndPublish()
    }

    /** A sample: dropped when it is not for the open session. Returns true when something changed. */
    private fun feed(id: String, ageMs: Long = 0L, receivedMonotonicMs: Long? = null, block: (WorkoutSession, Long) -> List<WorkoutEvent>): Boolean {
        synchronized(lock) {
            val s = session
            if (s == null || sessionId != id) return false
            // The time of a sample is when it ARRIVED minus its age, not when the queue got to it.
            val arrived = receivedMonotonicMs?.let { it + shiftMs } ?: now()
            val events = block(s, arrived - maxOf(0L, ageMs))
            persist(events)
            return events.isNotEmpty()
        }
    }

    private fun persist(events: List<WorkoutEvent>) {
        val id = sessionId ?: return
        if (events.isEmpty()) return
        try {
            store.append(id, events.map { WorkoutJournal.encode(it) })
        } catch (e: IOException) {
            fail(e)
        }
    }

    private fun fail(e: IOException) {
        journalFailed = true
        error = "JOURNAL_WRITE_FAILED: ${e.message ?: "I/O error"}"
    }

    private fun snapshotAndPublish(): NativeWorkoutSnapshot {
        val snapshot = snapshot()
        sink.onSnapshot(snapshot)
        return snapshot
    }

    private fun publish() {
        sink.onSnapshot(snapshot())
    }

    private fun makeSnapshot(): NativeWorkoutSnapshot {
        val s = session
        val now = now()
        if (s == null) {
            return NativeWorkoutSnapshot(
                state = NativeWorkoutState.IDLE, activeMs = 0, pausedMs = 0, distanceMeters = 0.0, lastSeq = 0,
                journalFailed = journalFailed, restoreStatus = restoreStatus, updatedAtMs = now, error = error,
            )
        }
        val snap = s.snapshot(now)
        return NativeWorkoutSnapshot(
            sessionId = sessionId,
            state = NativeWorkoutState.valueOf(snap.state.name),
            mode = snap.mode?.let { NativeWorkoutMode.valueOf(it.name) },
            activeMs = snap.activeMs,
            pausedMs = snap.pausedMs,
            distanceMeters = snap.distanceMeters,
            distanceSource = snap.distanceSource?.let { NativeSourceRef(it.id, NativeSourceKind.valueOf(it.kind.name)) },
            lastDistanceSource = snap.lastDistanceSource?.let { NativeSourceRef(it.id, NativeSourceKind.valueOf(it.kind.name)) },
            lastSeq = snap.lastSeq,
            journalFailed = journalFailed,
            restoreStatus = restoreStatus,
            updatedAtMs = now,
            error = error,
        )
    }

    private fun distanceSource(ref: NativeSourceRef) = DistanceSource(ref.id, DistanceSourceKind.valueOf(ref.kind.name))
}
