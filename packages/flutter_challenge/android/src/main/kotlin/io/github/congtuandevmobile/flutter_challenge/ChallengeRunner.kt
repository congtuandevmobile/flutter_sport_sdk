package io.github.congtuandevmobile.flutter_challenge

import challenge.journal.ChallengeJournal
import challenge.journal.JournalStatus
import challenge.model.ChallengeDefinition
import challenge.model.ChallengeEvent
import challenge.model.ChallengeResult
import challenge.model.ChallengeState
import challenge.model.CompletionEvidence
import challenge.model.CompletionPolicy
import challenge.model.ProgressMetric
import challenge.model.StageDefinition
import challenge.session.ChallengeSession
import java.io.IOException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/** A failure with a stable code (the plugin turns it into a `FlutterError`). */
class ChallengeException(val code: String, message: String) : Exception(message)

/** What the runner tells the Flutter side (the plugin turns it into a Pigeon call on the main thread). */
interface ChallengeSink {
    fun onSnapshot(snapshot: NativeChallengeSnapshot)
}

/**
 * Owns ONE challenge: a [ChallengeSession] of the shared core and its journal. THE rule: every event the core returns is appended to
 * the journal (and synced) BEFORE the snapshot that shows its effect is published, so a number on the screen is never ahead of the
 * disk. A failed write does not stop the challenge but `journalFailed` becomes true and STAYS true; a challenge that cannot write its
 * first line is not started. A command the rules refuse fails with the reason as its code; a refused sample is dropped.
 *
 * Time is the phone's monotonic clock plus a shift: after a restore the clock continues from the last journal event even if the phone
 * rebooted. Samples are stamped with their real time (now minus their age). A sample for another session id is dropped. All state is
 * guarded by [lock]; the plugin calls it from one serial thread.
 */
class ChallengeRunner(
    private val store: ChallengeJournalStore,
    private val scope: CoroutineScope,
    private val monotonicMs: () -> Long,
    private val sink: ChallengeSink,
    private val snapshotEveryMs: Long = 1_000,
) {
    private val lock = Any()
    private var session: ChallengeSession? = null
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

    fun start(id: String, definition: NativeChallengeDefinition): NativeChallengeSnapshot {
        synchronized(lock) {
            val open = session
            if (open != null && open.currentState != ChallengeState.COMPLETED) {
                throw ChallengeException("SESSION_OPEN", "challenge $sessionId is still open")
            }
            if (id.isBlank()) throw ChallengeException("BAD_SESSION", "the session id is empty")
            // A session id is used ONCE: lines appended behind another challenge's journal would be restored as that challenge.
            val existing = try { store.read(id) } catch (e: IOException) { throw ChallengeException("JOURNAL_WRITE_FAILED", e.message ?: "I/O error") }
            if (existing.isNotEmpty()) throw ChallengeException("SESSION_EXISTS", "a journal already exists for $id: clear it or use another id")
            val core = try { toCore(definition) } catch (e: IllegalArgumentException) {
                throw ChallengeException("BAD_DEFINITION", e.message ?: "the definition breaks its rules")
            }
            val created = ChallengeSession(core, id)
            val result = created.start(now())
            try {
                store.append(id, result.events.map { ChallengeJournal.encode(it) })
                store.setActive(id)
            } catch (e: IOException) {
                // A challenge that cannot even write its first line is not started: nothing would survive the process dying.
                throw ChallengeException("JOURNAL_WRITE_FAILED", e.message ?: "I/O error")
            }
            session = created
            sessionId = id
            journalFailed = false
            error = null
            restoreStatus = NativeRestoreStatus.NOT_RESTORED
        }
        return publishedSnapshot()
    }

    fun confirm(id: String, evidence: NativeCompletionEvidence, expectedStageActivation: Long? = null): NativeChallengeSnapshot =
        command(id) { s, at ->
            s.confirm(CompletionEvidence.valueOf(evidence.name), at, expectedStageActivation ?: ChallengeSession.CURRENT_ACTIVATION)
        }

    fun nextStage(id: String): NativeChallengeSnapshot = command(id) { s, at -> s.nextStage(at) }
    fun pause(id: String): NativeChallengeSnapshot = command(id) { s, at -> s.pause(at) }
    fun resume(id: String): NativeChallengeSnapshot = command(id) { s, at -> s.resume(at) }

    fun submitCounter(id: String, sourceId: String, epoch: Long, meters: Double, ageMs: Long, receivedMonotonicMs: Long? = null) {
        feed(id, receivedMonotonicMs) { s, at -> s.onCounter(sourceId, epoch, meters, at - maxOf(0L, ageMs)) }
    }

    fun submitDelta(id: String, sourceId: String, eventId: String, delta: Double, ageMs: Long, stageActivation: Long? = null, receivedMonotonicMs: Long? = null) {
        feed(id, receivedMonotonicMs) { s, at ->
            s.onDelta(sourceId, eventId, delta, at - maxOf(0L, ageMs), stageActivation ?: ChallengeSession.CURRENT_ACTIVATION)
        }
    }

    fun snapshot(): NativeChallengeSnapshot = synchronized(lock) { makeSnapshot() }

    /** Rebuilds [id] from its journal. It comes back PAUSED; nothing is replayed when this runner already runs it. */
    fun restore(id: String): NativeChallengeSnapshot {
        synchronized(lock) {
            if (sessionId == id && session != null) return makeSnapshot()
            val open = session
            if (open != null && open.currentState != ChallengeState.COMPLETED) { // restoring another one would replace the open challenge
                throw ChallengeException("SESSION_OPEN", "challenge $sessionId is still open")
            }
            val lines = try { store.read(id) } catch (e: IOException) { throw ChallengeException("RESTORE_FAILED", e.message ?: "I/O error") }
            val recovered = ChallengeJournal.recover(lines) ?: throw ChallengeException("NOT_RESTORABLE", "no usable journal for $id")
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
            // A damaged journal is cut on the disk BEFORE anything is appended: new lines behind a damaged one would be hidden from the
            // next restore. The damaged original stays next to the journal. If the repair fails, nothing is appended.
            var repaired = true
            if (recovered.read.status != JournalStatus.INTACT) {
                try {
                    store.replaceKeepingOriginal(id, recovered.read.events.map { ChallengeJournal.encode(it) })
                } catch (e: IOException) {
                    repaired = false
                    journalFailed = true
                    error = "JOURNAL_REPAIR_FAILED: ${e.message ?: "I/O error"}"
                }
            }
            if (repaired) persist(recovered.restored.recoveryEvents)
            try {
                store.setActive(if (recovered.restored.session.currentState == ChallengeState.COMPLETED) null else id)
            } catch (e: IOException) {
                fail(e)
            }
        }
        return publishedSnapshot()
    }

    fun activeSessionId(): String? = store.activeSessionId()

    fun clearSession(id: String) {
        synchronized(lock) {
            val s = session
            if (sessionId == id && s != null && s.currentState != ChallengeState.COMPLETED) {
                throw ChallengeException("SESSION_OPEN", "challenge $id is still open")
            }
            try { store.clear(id) } catch (e: IOException) { throw ChallengeException("JOURNAL_WRITE_FAILED", e.message ?: "I/O error") }
            if (sessionId == id) {
                session = null
                sessionId = null
            }
        }
        publish()
    }

    // ── internals ───────────────────────────────────────────────────────────

    private fun now(): Long = monotonicMs() + shiftMs

    /** A command on the open challenge [id]: persists what it caused, publishes AFTER the write, and fails with the refusal's name. */
    private fun command(id: String, block: (ChallengeSession, Long) -> ChallengeResult): NativeChallengeSnapshot {
        synchronized(lock) {
            val s = session
            if (s == null || sessionId != id) throw ChallengeException("NO_SESSION", "no open challenge $id")
            val result = block(s, now())
            result.refusal?.let { throw ChallengeException(it.name, "the challenge refused: ${it.name}") }
            persist(result.events)
            releaseActiveIfCompleted(s)
        }
        return publishedSnapshot()
    }

    /** The phone's monotonic time NOW: the plugin takes it when a sample ARRIVES, before the sample waits in the queue. */
    fun receivedAt(): Long = monotonicMs()

    /**
     * A sample: dropped when it is not for the open session or when the rules refuse it. [receivedMonotonicMs] is when it arrived (see
     * [receivedAt]); its time is that minus its age, NOT the time the queue got to it, so a callback that waited behind a stage change
     * still belongs to the interval it was measured in.
     */
    private fun feed(id: String, receivedMonotonicMs: Long?, block: (ChallengeSession, Long) -> ChallengeResult) {
        val changed: Boolean
        synchronized(lock) {
            val s = session
            if (s == null || sessionId != id) return
            val result = block(s, receivedMonotonicMs?.let { it + shiftMs } ?: now())
            persist(result.events)
            releaseActiveIfCompleted(s)
            changed = result.events.isNotEmpty()
        }
        if (changed) publish()
    }

    /** A completed challenge is not the one to recover: the active pointer goes, but only once the completion is really on the disk. */
    private fun releaseActiveIfCompleted(s: ChallengeSession) {
        if (s.currentState != ChallengeState.COMPLETED || journalFailed) return
        try { store.setActive(null) } catch (e: IOException) { fail(e) }
    }

    private fun persist(events: List<ChallengeEvent>) {
        val id = sessionId ?: return
        if (events.isEmpty()) return
        try {
            store.append(id, events.map { ChallengeJournal.encode(it) })
        } catch (e: IOException) {
            fail(e)
        }
    }

    private fun fail(e: IOException) {
        journalFailed = true
        error = "JOURNAL_WRITE_FAILED: ${e.message ?: "I/O error"}"
    }

    private fun publishedSnapshot(): NativeChallengeSnapshot {
        val snap = snapshot()
        sink.onSnapshot(snap)
        return snap
    }

    private fun publish() = sink.onSnapshot(snapshot())

    private fun makeSnapshot(): NativeChallengeSnapshot {
        val s = session
        val at = now()
        if (s == null) {
            return NativeChallengeSnapshot(
                state = NativeChallengeState.IDLE, definitionVersion = 0, stageIndex = -1, stageActivation = 0,
                stageStatus = NativeStageStatus.PENDING, stageProgress = 0.0, stageTarget = 0.0, totalElapsedMs = 0, stageElapsedMs = 0,
                completed = emptyList(), lastSeq = 0, recoveries = 0, journalFailed = journalFailed, restoreStatus = restoreStatus,
                updatedAtMs = at, error = error,
            )
        }
        val snap = s.snapshot(at)
        return NativeChallengeSnapshot(
            sessionId = sessionId,
            state = NativeChallengeState.valueOf(snap.state.name),
            definitionId = snap.definitionId,
            definitionVersion = snap.definitionVersion.toLong(),
            stageIndex = snap.stageIndex.toLong(),
            stageId = snap.stageId,
            stageActivation = snap.stageActivation,
            stageStatus = NativeStageStatus.valueOf(snap.stageStatus.name),
            stageProgress = snap.stageProgress,
            stageTarget = snap.stageTarget,
            totalElapsedMs = snap.totalElapsedMs,
            stageElapsedMs = snap.stageElapsedMs,
            completed = snap.completed.map {
                NativeCompletedStage(it.stageId, it.durationMs, it.progress, NativeCompletionEvidence.valueOf(it.evidence.name))
            },
            lastSeq = snap.lastSeq,
            recoveries = snap.recoveries.toLong(),
            journalFailed = journalFailed,
            restoreStatus = restoreStatus,
            updatedAtMs = at,
            error = error,
        )
    }

    private fun toCore(d: NativeChallengeDefinition) = ChallengeDefinition(
        d.id, d.version.toInt(),
        d.stages.map {
            StageDefinition(
                it.id, ProgressMetric.valueOf(it.metric.name), it.target, CompletionPolicy.valueOf(it.policy.name), it.allowedSources.toSet(),
            )
        },
        d.allowPause,
    )
}
