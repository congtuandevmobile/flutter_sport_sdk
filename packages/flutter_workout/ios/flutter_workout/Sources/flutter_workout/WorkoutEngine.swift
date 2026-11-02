import Darwin
import Flutter
import Foundation
import WorkoutCore

/// What the engine tells the Flutter side (the plugin turns it into a Pigeon call on the main thread).
protocol WorkoutSink: AnyObject {
    func onSnapshot(_ snapshot: NativeWorkoutSnapshot)
}

/// A failure with a stable code (the plugin turns it into a `PigeonError`).
struct WorkoutError: Error {
    let code: String
    let message: String
}

func workoutMonotonicNowMs() -> Int64 { Int64(clock_gettime_nsec_np(CLOCK_MONOTONIC) / 1_000_000) }

/// Owns ONE workout: a `WorkoutSession` of the shared core and its journal. The rule that matters: every event the core returns is
/// appended to the journal (and synced) BEFORE the snapshot that shows its effect is published, so a number on the screen is never
/// ahead of the disk. A failed write does not stop the workout, but `journalFailed` becomes true and stays true.
///
/// Time is the phone's monotonic clock plus a shift: after a restore the clock continues from the last journal event even if the
/// phone rebooted (the monotonic clock then restarted lower), so a restored session can always resume. Samples are stamped with their
/// real time (now minus their age). A sample for another session id is dropped. All state lives on `queue`.
final class WorkoutEngine {
    private let store: WorkoutJournalStore
    private let monotonicMs: () -> Int64
    private weak var sink: WorkoutSink?
    private let queue = DispatchQueue(label: "flutter_workout.engine")
    private let snapshotEvery: TimeInterval
    private var session: WorkoutSession?
    private var sessionId: String?
    private var shiftMs: Int64 = 0
    private var journalFailed = false
    private var error: String?
    private var restoreStatus: NativeRestoreStatus = .notRestored
    private var ticker: DispatchSourceTimer?

    init(
        store: WorkoutJournalStore, sink: WorkoutSink, monotonicMs: @escaping () -> Int64 = workoutMonotonicNowMs,
        snapshotEvery: TimeInterval = 1
    ) {
        self.store = store
        self.sink = sink
        self.monotonicMs = monotonicMs
        self.snapshotEvery = snapshotEvery
    }

    func startTicker() {
        queue.async { [weak self] in
            guard let self = self, self.ticker == nil else { return }
            let timer = DispatchSource.makeTimerSource(queue: self.queue)
            timer.schedule(deadline: .now() + self.snapshotEvery, repeating: self.snapshotEvery)
            timer.setEventHandler { [weak self] in
                guard let self = self else { return }
                if let s = self.session, s.currentState == .running || s.currentState == .paused {
                    self.persist(s.tick(nowMs: self.now()))
                }
                self.publish()
            }
            timer.resume()
            self.ticker = timer
        }
    }

    func stopTicker() {
        queue.sync {
            ticker?.cancel()
            ticker = nil
        }
    }

    /// Waits until everything queued so far ran (tests).
    func flush() { queue.sync {} }

    // MARK: - Calls from the host (each waits for its answer; the journal write is part of it)

    func start(sessionId id: String, mode: NativeWorkoutMode) throws -> NativeWorkoutSnapshot {
        try queue.sync {
            if let open = session, open.currentState == .running || open.currentState == .paused {
                throw WorkoutError(code: "SESSION_OPEN", message: "workout \(sessionId ?? "") is still open")
            }
            // The previous workout finished in memory but its journal is NOT (fully) on the disk: the active pointer is the only way to
            // recover it, and a new workout would replace it. Recover it, or discard it on purpose with clearSession.
            if session != nil, journalFailed {
                throw WorkoutError(code: "RECOVERY_REQUIRED", message: "the previous workout \(sessionId ?? "") has a journal failure: recover it or clear it first")
            }
            if id.trimmingCharacters(in: .whitespaces).isEmpty { throw WorkoutError(code: "BAD_SESSION", message: "the session id is empty") }
            // A session id is used ONCE: lines appended behind another workout's journal would be restored as that workout.
            if store.exists(sessionId: id) { throw WorkoutError(code: "SESSION_EXISTS", message: "a journal already exists for \(id): clear it or use another id") }
            let created = WorkoutSession.Companion.shared.forMode(mode: Self.coreMode(mode))
            let events = created.start(nowMs: now())
            do {
                try store.append(sessionId: id, lines: events.map { WorkoutJournal.shared.encode(e: $0) })
                try store.setActive(id)
            } catch {
                // A workout that cannot even write its first line is not started: nothing would survive the process dying. What the
                // attempt left behind (an empty file) must not make the id look taken on the next try.
                try? store.clear(sessionId: id)
                throw WorkoutError(code: "JOURNAL_WRITE_FAILED", message: error.localizedDescription)
            }
            session = created
            sessionId = id
            journalFailed = false
            self.error = nil
            restoreStatus = .notRestored
            return publishedSnapshot()
        }
    }

    func pause(sessionId id: String) throws -> NativeWorkoutSnapshot { try change(id) { $0.pause(nowMs: self.now()) } }
    func resume(sessionId id: String) throws -> NativeWorkoutSnapshot { try change(id) { $0.resume(nowMs: self.now()) } }

    /// Finishes the workout. The Finished event is persisted and the active pointer released in ONE serialized step, BEFORE the snapshot
    /// is built, so the snapshot already shows a failed write. The pointer goes only when the Finished line is really on the disk: with a
    /// journal failure the journal may still say "running", and the pointer is what leads to it after a crash.
    func finish(sessionId id: String) throws -> NativeWorkoutSnapshot {
        try queue.sync {
            guard let s = session, sessionId == id else { throw WorkoutError(code: "NO_SESSION", message: "no open workout \(id)") }
            persist(s.finish(nowMs: now()))
            if s.currentState == .finished, !journalFailed {
                do { try store.setActive(nil) } catch { fail(error) }
            }
            return publishedSnapshot()
        }
    }

    /// The phone's monotonic time NOW: the plugin takes it when a sample ARRIVES, before the sample waits in the queue.
    func receivedAt() -> Int64 { monotonicMs() }

    func submitCounter(sessionId id: String, source: NativeSourceRef, epoch: Int64, meters: Double, ageMs: Int64, receivedMonotonicMs: Int64? = nil) {
        feed(id, ageMs: ageMs, receivedMonotonicMs: receivedMonotonicMs) { s, at in
            s.onCounter(source: Self.coreSource(source), epoch: epoch, meters: meters, atMs: at)
        }
    }

    func submitSpeed(sessionId id: String, source: NativeSourceRef, epoch: Int64, mps: Double, ageMs: Int64, receivedMonotonicMs: Int64? = nil) {
        feed(id, ageMs: ageMs, receivedMonotonicMs: receivedMonotonicMs) { s, at in
            s.onSpeed(source: Self.coreSource(source), epoch: epoch, mps: mps, atMs: at)
        }
    }

    func setPreferred(sessionId id: String, source: NativeSourceRef?) throws {
        _ = try change(id) { $0.setPreferredSource(source: source.map { Self.coreSource($0) }, nowMs: self.now()) }
    }

    func snapshot() -> NativeWorkoutSnapshot { queue.sync { makeSnapshot() } }

    /// Rebuilds `id` from its journal. It comes back PAUSED; nothing is replayed when this engine already runs it.
    func restore(sessionId id: String) throws -> NativeWorkoutSnapshot {
        try queue.sync {
            if sessionId == id, session != nil { return makeSnapshot() }
            if let open = session, open.currentState == .running || open.currentState == .paused { // restoring another one would replace it
                throw WorkoutError(code: "SESSION_OPEN", message: "workout \(sessionId ?? "") is still open")
            }
            let lines: [String]
            do { lines = try store.read(sessionId: id) } catch {
                throw WorkoutError(code: "RESTORE_FAILED", message: error.localizedDescription)
            }
            guard let recovered = WorkoutJournal.shared.recover(lines: lines) else {
                throw WorkoutError(code: "NOT_RESTORABLE", message: "no usable journal for \(id)")
            }
            let all = recovered.read.events + recovered.restored.recoveryEvents
            let lastAt = all.map { $0.atMs }.max() ?? 0
            shiftMs = max(0, lastAt - monotonicMs())
            session = recovered.restored.session
            sessionId = id
            journalFailed = false
            error = nil
            switch recovered.read.status {
            case .intact: restoreStatus = .intact
            case .tailRepaired: restoreStatus = .tailRepaired
            default: restoreStatus = .partial
            }
            // A damaged journal is cut on the disk BEFORE anything is appended: new lines behind a damaged one would be hidden from the
            // next restore. The damaged original stays next to the journal. If the repair fails, nothing is appended.
            var repaired = true
            if recovered.read.status != .intact {
                do {
                    _ = try store.replaceKeepingOriginal(
                        sessionId: id, lines: recovered.read.events.map { WorkoutJournal.shared.encode(e: $0) })
                } catch {
                    repaired = false
                    journalFailed = true
                    self.error = "JOURNAL_REPAIR_FAILED: \(error.localizedDescription)"
                }
            }
            if repaired { persist(recovered.restored.recoveryEvents) }
            do {
                try store.setActive(recovered.restored.session.currentState == .finished ? nil : id)
            } catch { fail(error) }
            return publishedSnapshot()
        }
    }

    func activeSessionId() -> String? { store.activeSessionId() }

    func clearSession(sessionId id: String) throws {
        try queue.sync {
            if sessionId == id, let s = session, s.currentState != .finished {
                throw WorkoutError(code: "SESSION_OPEN", message: "workout \(id) is still open")
            }
            do { try store.clear(sessionId: id) } catch {
                throw WorkoutError(code: "JOURNAL_WRITE_FAILED", message: error.localizedDescription)
            }
            if sessionId == id {
                session = nil
                sessionId = nil
                journalFailed = false
                error = nil
            }
            publish()
        }
    }

    // MARK: - Internals (queue)

    private func now() -> Int64 { monotonicMs() + shiftMs }

    /// Runs `block` on the open session `id`, persists what it caused, and publishes AFTER the write.
    private func change(_ id: String, _ block: (WorkoutSession) -> [WorkoutEvent]) throws -> NativeWorkoutSnapshot {
        try queue.sync {
            guard let s = session, sessionId == id else { throw WorkoutError(code: "NO_SESSION", message: "no open workout \(id)") }
            persist(block(s))
            return publishedSnapshot()
        }
    }

    /// A sample: dropped when it is not for the open session.
    private func feed(_ id: String, ageMs: Int64, receivedMonotonicMs: Int64?, _ block: @escaping (WorkoutSession, Int64) -> [WorkoutEvent]) {
        queue.async { [weak self] in
            guard let self = self, let s = self.session, self.sessionId == id else { return }
            // The time of a sample is when it ARRIVED minus its age, not when the queue got to it.
            let arrived = receivedMonotonicMs.map { $0 + self.shiftMs } ?? self.now()
            let events = block(s, arrived - max(0, ageMs))
            self.persist(events)
            if !events.isEmpty { self.publish() }
        }
    }

    private func persist(_ events: [WorkoutEvent]) {
        guard let id = sessionId, !events.isEmpty else { return }
        do {
            try store.append(sessionId: id, lines: events.map { WorkoutJournal.shared.encode(e: $0) })
        } catch {
            fail(error)
        }
    }

    private func fail(_ error: Error) {
        journalFailed = true
        self.error = "JOURNAL_WRITE_FAILED: \(error.localizedDescription)"
    }

    private func publishedSnapshot() -> NativeWorkoutSnapshot {
        let snap = makeSnapshot()
        sink?.onSnapshot(snap)
        return snap
    }

    private func publish() { sink?.onSnapshot(makeSnapshot()) }

    private func makeSnapshot() -> NativeWorkoutSnapshot {
        let at = now()
        guard let s = session else {
            return NativeWorkoutSnapshot(
                state: .idle, activeMs: 0, pausedMs: 0, distanceMeters: 0, lastSeq: 0,
                journalFailed: journalFailed, restoreStatus: restoreStatus, updatedAtMs: at, error: error)
        }
        let snap = s.snapshot(nowMs: at)
        return NativeWorkoutSnapshot(
            sessionId: sessionId,
            state: NativeWorkoutState(rawValue: Int(snap.state.ordinal)) ?? .idle,
            mode: snap.mode.flatMap { NativeWorkoutMode(rawValue: Int($0.ordinal)) },
            activeMs: snap.activeMs, pausedMs: snap.pausedMs, distanceMeters: snap.distanceMeters,
            distanceSource: snap.distanceSource.map {
                NativeSourceRef(id: $0.id, kind: NativeSourceKind(rawValue: Int($0.kind.ordinal)) ?? .counter)
            },
            lastDistanceSource: snap.lastDistanceSource.map {
                NativeSourceRef(id: $0.id, kind: NativeSourceKind(rawValue: Int($0.kind.ordinal)) ?? .counter)
            },
            lastSeq: snap.lastSeq, journalFailed: journalFailed, restoreStatus: restoreStatus, updatedAtMs: at, error: error)
    }

    private static func coreMode(_ mode: NativeWorkoutMode) -> WorkoutMode {
        switch mode {
        case .outdoorRunning: return .outdoorRunning
        case .indoorRunning: return .indoorRunning
        case .outdoorCycling: return .outdoorCycling
        case .indoorCycling: return .indoorCycling
        }
    }

    private static func coreSource(_ ref: NativeSourceRef) -> DistanceSource {
        let kind: DistanceSourceKind
        switch ref.kind {
        case .gps: kind = .gps
        case .counter: kind = .counter
        case .speed: kind = .speed
        }
        return DistanceSource(id: ref.id, kind: kind)
    }
}
