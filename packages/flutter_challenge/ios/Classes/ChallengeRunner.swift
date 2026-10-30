import ChallengeCore
import Darwin
import Flutter
import Foundation

/// What the runner tells the Flutter side (the plugin turns it into a Pigeon call on the main thread).
protocol ChallengeSink: AnyObject {
    func onSnapshot(_ snapshot: NativeChallengeSnapshot)
}

/// A failure with a stable code (the plugin turns it into a `PigeonError`).
struct ChallengeError: Error {
    let code: String
    let message: String
}

func challengeMonotonicNowMs() -> Int64 { Int64(clock_gettime_nsec_np(CLOCK_MONOTONIC) / 1_000_000) }

/// Owns ONE challenge: a `ChallengeSession` of the shared core (Kotlin/Native `ChallengeCore`) and its journal. THE rule: every event the
/// core returns is appended to the journal (and synced) BEFORE the snapshot that shows its effect is published, so a number on the screen
/// is never ahead of the disk. A failed write does not stop the challenge but `journalFailed` becomes true and STAYS true; a challenge that
/// cannot write its first line is not started. A command the rules refuse fails with the reason as its code; a refused sample is dropped.
///
/// Time is the phone's monotonic clock plus a shift: after a restore the clock continues from the last journal event even if the phone
/// rebooted. Samples are stamped with their real time (now minus their age). A sample for another session id is dropped. All state lives
/// on `queue`.
final class ChallengeRunner {
    private let store: ChallengeJournalStore
    private let monotonicMs: () -> Int64
    private weak var sink: ChallengeSink?
    private let queue = DispatchQueue(label: "flutter_challenge.runner")
    private let snapshotEvery: TimeInterval
    private var session: ChallengeSession?
    private var sessionId: String?
    private var shiftMs: Int64 = 0
    private var journalFailed = false
    private var error: String?
    private var restoreStatus: NativeRestoreStatus = .notRestored
    private var ticker: DispatchSourceTimer?

    init(
        store: ChallengeJournalStore, sink: ChallengeSink, monotonicMs: @escaping () -> Int64 = challengeMonotonicNowMs,
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
            timer.setEventHandler { [weak self] in self?.publish() }
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

    // MARK: - Calls from the host

    func start(sessionId id: String, definition: NativeChallengeDefinition) throws -> NativeChallengeSnapshot {
        try queue.sync {
            if let open = session, open.currentState != .completed {
                throw ChallengeError(code: "SESSION_OPEN", message: "challenge \(sessionId ?? "") is still open")
            }
            if id.trimmingCharacters(in: .whitespaces).isEmpty { throw ChallengeError(code: "BAD_SESSION", message: "the session id is empty") }
            guard let core = Self.coreDefinition(definition) else {
                throw ChallengeError(code: "BAD_DEFINITION", message: "the definition breaks its rules")
            }
            let created = ChallengeSession.Companion.shared.create(definition: core, sessionId: id)
            let result = created.start(atMs: now())
            do {
                try store.append(sessionId: id, lines: result.events.map { ChallengeJournal.shared.encode(e: $0) })
                try store.setActive(id)
            } catch {
                // A challenge that cannot even write its first line is not started: nothing would survive the process dying.
                throw ChallengeError(code: "JOURNAL_WRITE_FAILED", message: error.localizedDescription)
            }
            session = created
            sessionId = id
            journalFailed = false
            self.error = nil
            restoreStatus = .notRestored
            return publishedSnapshot()
        }
    }

    func confirm(sessionId id: String, evidence: NativeCompletionEvidence) throws -> NativeChallengeSnapshot {
        try command(id) { s, at in
            s.confirm(evidence: Self.coreEvidence(evidence), atMs: at)
        }
    }
    func nextStage(sessionId id: String) throws -> NativeChallengeSnapshot { try command(id) { $0.nextStage(atMs: $1) } }
    func pause(sessionId id: String) throws -> NativeChallengeSnapshot { try command(id) { $0.pause(atMs: $1) } }
    func resume(sessionId id: String) throws -> NativeChallengeSnapshot { try command(id) { $0.resume(atMs: $1) } }

    func submitCounter(sessionId id: String, sourceId: String, epoch: Int64, meters: Double, ageMs: Int64) {
        feed(id) { s, at in s.onCounter(sourceId: sourceId, epoch: epoch, counter: meters, atMs: at - max(0, ageMs)) }
    }

    func submitDelta(sessionId id: String, sourceId: String, eventId: String, delta: Double, ageMs: Int64) {
        feed(id) { s, at in s.onDelta(sourceId: sourceId, eventId: eventId, delta: delta, atMs: at - max(0, ageMs)) }
    }

    func snapshot() -> NativeChallengeSnapshot { queue.sync { makeSnapshot() } }

    /// Rebuilds `id` from its journal. It comes back PAUSED; nothing is replayed when this runner already runs it.
    func restore(sessionId id: String) throws -> NativeChallengeSnapshot {
        try queue.sync {
            if sessionId == id, session != nil { return makeSnapshot() }
            let lines: [String]
            do { lines = try store.read(sessionId: id) } catch {
                throw ChallengeError(code: "RESTORE_FAILED", message: error.localizedDescription)
            }
            guard let recovered = ChallengeJournal.shared.recover(lines: lines) else {
                throw ChallengeError(code: "NOT_RESTORABLE", message: "no usable journal for \(id)")
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
                        sessionId: id, lines: recovered.read.events.map { ChallengeJournal.shared.encode(e: $0) })
                } catch {
                    repaired = false
                    journalFailed = true
                    self.error = "JOURNAL_REPAIR_FAILED: \(error.localizedDescription)"
                }
            }
            if repaired { persist(recovered.restored.recoveryEvents) }
            do {
                try store.setActive(recovered.restored.session.currentState == .completed ? nil : id)
            } catch { fail(error) }
            return publishedSnapshot()
        }
    }

    func activeSessionId() -> String? { store.activeSessionId() }

    func clearSession(sessionId id: String) throws {
        try queue.sync {
            if sessionId == id, let s = session, s.currentState != .completed {
                throw ChallengeError(code: "SESSION_OPEN", message: "challenge \(id) is still open")
            }
            do { try store.clear(sessionId: id) } catch {
                throw ChallengeError(code: "JOURNAL_WRITE_FAILED", message: error.localizedDescription)
            }
            if sessionId == id {
                session = nil
                sessionId = nil
            }
            publish()
        }
    }

    // MARK: - Internals (queue)

    private func now() -> Int64 { monotonicMs() + shiftMs }

    /// A command on the open challenge `id`: persists what it caused, publishes AFTER the write, and fails with the refusal's name.
    private func command(_ id: String, _ block: (ChallengeSession, Int64) -> ChallengeResult) throws -> NativeChallengeSnapshot {
        try queue.sync {
            guard let s = session, sessionId == id else { throw ChallengeError(code: "NO_SESSION", message: "no open challenge \(id)") }
            let result = block(s, now())
            if let refusal = result.refusal {
                throw ChallengeError(code: Self.refusalCode(refusal), message: "the challenge refused: \(Self.refusalCode(refusal))")
            }
            persist(result.events)
            return publishedSnapshot()
        }
    }

    /// A sample: dropped when it is not for the open session or when the rules refuse it.
    private func feed(_ id: String, _ block: @escaping (ChallengeSession, Int64) -> ChallengeResult) {
        queue.async { [weak self] in
            guard let self = self, let s = self.session, self.sessionId == id else { return }
            let result = block(s, self.now())
            self.persist(result.events)
            if !result.events.isEmpty { self.publish() }
        }
    }

    private func persist(_ events: [ChallengeEvent]) {
        guard let id = sessionId, !events.isEmpty else { return }
        do {
            try store.append(sessionId: id, lines: events.map { ChallengeJournal.shared.encode(e: $0) })
        } catch {
            fail(error)
        }
    }

    private func fail(_ error: Error) {
        journalFailed = true
        self.error = "JOURNAL_WRITE_FAILED: \(error.localizedDescription)"
    }

    private func publishedSnapshot() -> NativeChallengeSnapshot {
        let snap = makeSnapshot()
        sink?.onSnapshot(snap)
        return snap
    }

    private func publish() { sink?.onSnapshot(makeSnapshot()) }

    private func makeSnapshot() -> NativeChallengeSnapshot {
        let at = now()
        guard let s = session else {
            return NativeChallengeSnapshot(
                state: .idle, definitionVersion: 0, stageIndex: -1, stageActivation: 0, stageStatus: .pending, stageProgress: 0,
                stageTarget: 0, totalElapsedMs: 0, stageElapsedMs: 0, completed: [], lastSeq: 0, recoveries: 0,
                journalFailed: journalFailed, restoreStatus: restoreStatus, updatedAtMs: at, error: error)
        }
        let snap = s.snapshot(atMs: at)
        return NativeChallengeSnapshot(
            sessionId: sessionId,
            state: NativeChallengeState(rawValue: Int(snap.state.ordinal)) ?? .idle,
            definitionId: snap.definitionId,
            definitionVersion: Int64(snap.definitionVersion),
            stageIndex: Int64(snap.stageIndex),
            stageId: snap.stageId,
            stageActivation: snap.stageActivation,
            stageStatus: NativeStageStatus(rawValue: Int(snap.stageStatus.ordinal)) ?? .pending,
            stageProgress: snap.stageProgress,
            stageTarget: snap.stageTarget,
            totalElapsedMs: snap.totalElapsedMs,
            stageElapsedMs: snap.stageElapsedMs,
            completed: snap.completed.map {
                NativeCompletedStage(
                    stageId: $0.stageId, durationMs: $0.durationMs, progress: $0.progress,
                    evidence: NativeCompletionEvidence(rawValue: Int($0.evidence.ordinal)) ?? .manual)
            },
            lastSeq: snap.lastSeq,
            recoveries: Int64(snap.recoveries),
            journalFailed: journalFailed,
            restoreStatus: restoreStatus,
            updatedAtMs: at,
            error: error)
    }

    private static func coreDefinition(_ d: NativeChallengeDefinition) -> ChallengeDefinition? {
        // The core's rules throw (an empty id, a target of 0, a duplicate stage): that is a bad definition, not a crash.
        guard !d.id.trimmingCharacters(in: .whitespaces).isEmpty, d.version > 0, !d.stages.isEmpty,
            Set(d.stages.map { $0.id }).count == d.stages.count
        else { return nil }
        var stages: [StageDefinition] = []
        for s in d.stages {
            guard !s.id.trimmingCharacters(in: .whitespaces).isEmpty, s.target.isFinite, s.target > 0, !s.allowedSources.isEmpty,
                s.allowedSources.allSatisfy({ !$0.trimmingCharacters(in: .whitespaces).isEmpty })
            else { return nil }
            stages.append(StageDefinition(
                id: s.id, metric: coreMetric(s.metric), target: s.target, policy: corePolicy(s.policy),
                allowedSources: Set(s.allowedSources)))
        }
        return ChallengeDefinition(id: d.id, version: Int32(d.version), stages: stages, allowPause: d.allowPause)
    }

    private static func coreMetric(_ m: NativeProgressMetric) -> ProgressMetric {
        switch m {
        case .runMeters: return .runMeters
        case .rowMeters: return .rowMeters
        case .skiMeters: return .skiMeters
        case .sledMeters: return .sledMeters
        case .swimMeters: return .swimMeters
        case .reps: return .reps
        }
    }

    private static func corePolicy(_ p: NativeCompletionPolicy) -> CompletionPolicy {
        switch p {
        case .auto: return .auto_
        case .manual: return .manual
        case .sensorOrManual: return .sensorOrManual
        case .judgeRequired: return .judgeRequired
        }
    }

    private static func coreEvidence(_ e: NativeCompletionEvidence) -> CompletionEvidence {
        switch e {
        case .sensor: return .sensor
        case .manual: return .manual
        case .judge: return .judge
        }
    }

    /// The refusal's name as the stable code ("NOT_ALLOWED", "WRONG_STATE", ...).
    private static func refusalCode(_ r: Refusal) -> String {
        switch r {
        case .wrongState: return "WRONG_STATE"
        case .notAllowed: return "NOT_ALLOWED"
        case .pauseNotAllowed: return "PAUSE_NOT_ALLOWED"
        case .timeBackwards: return "TIME_BACKWARDS"
        case .wrongSession: return "WRONG_SESSION"
        case .staleActivation: return "STALE_ACTIVATION"
        case .wrongMetric: return "WRONG_METRIC"
        case .sourceNotAllowed: return "SOURCE_NOT_ALLOWED"
        case .badEventId: return "BAD_EVENT_ID"
        case .duplicate: return "DUPLICATE"
        case .badDelta: return "BAD_DELTA"
        case .targetReached: return "TARGET_REACHED"
        default: return "REFUSED"
        }
    }
}
