import ChallengeCore
import Flutter
import XCTest

@testable import flutter_challenge

private final class MemoryStore: ChallengeJournalStore {
    var files: [String: [String]] = [:]
    var activeId: String?
    var failAppends = false
    var failReplace = false
    var originals: [String: [String]] = [:]
    func append(sessionId: String, lines: [String]) throws {
        if failAppends { throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "disk full"]) }
        files[sessionId, default: []].append(contentsOf: lines)
    }
    func exists(sessionId: String) -> Bool { files[sessionId] != nil }
    func read(sessionId: String) throws -> [String] { files[sessionId] ?? [] }
    func clear(sessionId: String) throws { files[sessionId] = nil; if activeId == sessionId { activeId = nil } }
    func replaceKeepingOriginal(sessionId: String, lines: [String]) throws -> String {
        if failReplace { throw NSError(domain: "test", code: 2, userInfo: [NSLocalizedDescriptionKey: "read-only"]) }
        originals[sessionId] = files[sessionId] ?? []
        files[sessionId] = lines
        return "kept"
    }
    func activeSessionId() -> String? { activeId }
    func setActive(_ sessionId: String?) throws { activeId = sessionId }
    var totalLines: Int { files.values.reduce(0) { $0 + $1.count } }
}

private final class RecordingSink: ChallengeSink {
    private let store: MemoryStore
    var snapshots: [NativeChallengeSnapshot] = []
    var linesAtPublish: [Int] = []
    init(_ store: MemoryStore) { self.store = store }
    func onSnapshot(_ snapshot: NativeChallengeSnapshot) { snapshots.append(snapshot); linesAtPublish.append(store.totalLines) }
}

final class RunnerTests: XCTestCase {
    private var clock: Int64 = 1_000
    private let store = MemoryStore()
    private lazy var sink = RecordingSink(store)

    private func stage(_ id: String, _ metric: NativeProgressMetric, _ target: Double, _ policy: NativeCompletionPolicy, _ sources: [String]) -> NativeStageDefinition {
        NativeStageDefinition(id: id, metric: metric, target: target, policy: policy, allowedSources: sources)
    }

    private func definition(allowPause: Bool = true) -> NativeChallengeDefinition {
        NativeChallengeDefinition(id: "hybrid", version: 1, allowPause: allowPause, stages: [
            stage("run-1", .runMeters, 1000, .auto, ["gps-primary"]),
            stage("sled", .sledMeters, 50, .manual, ["manual"]),
            stage("row", .rowMeters, 1000, .sensorOrManual, ["pm5-rower"]),
            stage("run-2", .runMeters, 1000, .auto, ["gps-primary"]),
        ])
    }

    private func makeRunner(_ s: MemoryStore? = nil, _ k: RecordingSink? = nil, snapshotEvery: TimeInterval = 1) -> ChallengeRunner {
        ChallengeRunner(store: s ?? store, sink: k ?? sink, monotonicMs: { self.clock }, snapshotEvery: snapshotEvery)
    }

    private func counter(_ r: ChallengeRunner, _ source: String, _ epoch: Int64, _ meters: Double, id: String = "s1", age: Int64 = 0) {
        r.submitCounter(sessionId: id, sourceId: source, epoch: epoch, meters: meters, ageMs: age)
        r.flush()
    }

    private func delta(_ r: ChallengeRunner, _ source: String, _ eventId: String, _ delta: Double) {
        r.submitDelta(sessionId: "s1", sourceId: source, eventId: eventId, delta: delta, ageMs: 0)
        r.flush()
    }

    private func gpsRun(_ r: ChallengeRunner, total: inout Double, seconds: Int) {
        for _ in 0..<seconds { clock += 1000; total += 10; counter(r, "gps-primary", 1, total) }
    }

    func testStartWritesTheDefinitionAndTheFirstLinesBeforeItReturns() throws {
        let r = makeRunner()
        let snap = try r.start(sessionId: "s1", definition: definition())
        XCTAssertEqual(snap.state, .active)
        XCTAssertEqual(snap.stageId, "run-1")
        XCTAssertEqual(store.files["s1"]?.count, 3)
        XCTAssertEqual(store.activeSessionId(), "s1")
    }

    func testANumberIsNeverShownBeforeItIsOnTheDisk() throws {
        let r = makeRunner()
        _ = try r.start(sessionId: "s1", definition: definition())
        var gps = 5000.0
        counter(r, "gps-primary", 1, gps)
        gpsRun(r, total: &gps, seconds: 3)
        XCTAssertEqual(sink.snapshots.last?.stageProgress ?? 0, 30, accuracy: 1e-9)
        XCTAssertEqual(sink.linesAtPublish.last, store.totalLines)
    }

    func testTheWholeChallengeRunsSledRowRunWithTheGpsCountingTheWholeTime() throws {
        let r = makeRunner()
        _ = try r.start(sessionId: "s1", definition: definition())
        var gps = 5000.0
        counter(r, "gps-primary", 1, gps)
        gpsRun(r, total: &gps, seconds: 100)
        XCTAssertEqual(r.snapshot().state, .transition)
        clock += 10_000; _ = try r.nextStage(sessionId: "s1")
        gpsRun(r, total: &gps, seconds: 60) // the GPS goes on at the sled station: counts for nothing
        XCTAssertEqual(r.snapshot().stageProgress, 0)
        delta(r, "manual", "tap-1", 25); delta(r, "manual", "tap-2", 25)
        delta(r, "manual", "tap-1", 25) // a retried tap: never counted twice
        XCTAssertEqual(r.snapshot().stageProgress, 50, accuracy: 1e-9)
        _ = try r.confirm(sessionId: "s1", evidence: .manual)
        clock += 20_000; _ = try r.nextStage(sessionId: "s1")
        counter(r, "pm5-rower", 5, 500)
        for i in 1...125 { clock += 1000; counter(r, "pm5-rower", 5, 500 + Double(i) * 8); gps += 10; counter(r, "gps-primary", 1, gps) }
        XCTAssertEqual(r.snapshot().stageProgress, 1000, accuracy: 1e-9)
        XCTAssertEqual(r.snapshot().stageStatus, .targetReached)
        _ = try r.confirm(sessionId: "s1", evidence: .manual)
        clock += 40_000; _ = try r.nextStage(sessionId: "s1")
        gps += 400 // covered between the stations: NOT credited to run 2
        counter(r, "gps-primary", 1, gps)
        gpsRun(r, total: &gps, seconds: 25)
        XCTAssertEqual(r.snapshot().stageProgress, 250, accuracy: 1e-9)
        gpsRun(r, total: &gps, seconds: 75)
        let end = r.snapshot()
        XCTAssertEqual(end.state, .completed)
        XCTAssertEqual(end.completed.map { $0.stageId }, ["run-1", "sled", "row", "run-2"])
        XCTAssertEqual(end.completed[0].progress, 1000, accuracy: 1e-9)
        XCTAssertEqual(end.completed[1].progress, 50, accuracy: 1e-9)
        _ = try makeRunner().start(sessionId: "s2", definition: definition())
    }

    func testACommandTheRulesRefuseFailsWithTheReasonAndNothingIsWritten() throws {
        let r = makeRunner()
        _ = try r.start(sessionId: "s1", definition: definition())
        let before = store.files["s1"]?.count
        func code(_ block: () throws -> Void) -> String? {
            do { try block() } catch { return (error as? ChallengeError)?.code }
            return nil
        }
        XCTAssertEqual(code { _ = try r.confirm(sessionId: "s1", evidence: .manual) }, "NOT_ALLOWED")
        XCTAssertEqual(code { _ = try r.nextStage(sessionId: "s1") }, "WRONG_STATE")
        XCTAssertEqual(code { _ = try r.resume(sessionId: "s1") }, "WRONG_STATE")
        XCTAssertEqual(code { _ = try r.pause(sessionId: "other") }, "NO_SESSION")
        XCTAssertEqual(store.files["s1"]?.count, before)
    }

    func testAPauseCanBeForbiddenAndABadDefinitionIsRefusedBeforeAnythingIsWritten() throws {
        let r = makeRunner()
        _ = try r.start(sessionId: "s1", definition: definition(allowPause: false))
        XCTAssertThrowsError(try r.pause(sessionId: "s1")) { XCTAssertEqual(($0 as? ChallengeError)?.code, "PAUSE_NOT_ALLOWED") }
        let other = MemoryStore()
        let bad = NativeChallengeDefinition(id: "x", version: 1, allowPause: true, stages: [stage("a", .reps, 0, .auto, ["m"])])
        XCTAssertThrowsError(try makeRunner(other, RecordingSink(other)).start(sessionId: "s9", definition: bad)) {
            XCTAssertEqual(($0 as? ChallengeError)?.code, "BAD_DEFINITION")
        }
        XCTAssertTrue(other.files.isEmpty)
    }

    func testASecondChallengeWhileOneIsOpenIsRefused() throws {
        let r = makeRunner()
        _ = try r.start(sessionId: "s1", definition: definition())
        XCTAssertThrowsError(try r.start(sessionId: "s2", definition: definition())) { XCTAssertEqual(($0 as? ChallengeError)?.code, "SESSION_OPEN") }
    }

    func testSamplesOfAnotherSessionAndOfASourceThatIsNotAllowedAreDropped() throws {
        let r = makeRunner()
        _ = try r.start(sessionId: "s1", definition: definition())
        counter(r, "gps-primary", 1, 0, id: "other")
        clock += 1000; counter(r, "gps-primary", 1, 50, id: "other")
        counter(r, "pm5-rower", 1, 0)
        clock += 1000; counter(r, "pm5-rower", 1, 8)
        XCTAssertEqual(r.snapshot().stageProgress, 0)
    }

    func testASampleIsStampedWithItsRealTimeNotTheTimeOfTheCall() throws {
        let r = makeRunner()
        _ = try r.start(sessionId: "s1", definition: definition())
        clock = 6_000; counter(r, "gps-primary", 1, 0, age: 4_000)
        clock = 7_000; counter(r, "gps-primary", 1, 10, age: 4_000)
        XCTAssertEqual(r.snapshot().stageProgress, 10, accuracy: 1e-9)
    }

    func testAFailedWriteIsReportedAndStickyAndAFirstLineThatCannotBeWrittenMeansNoStart() throws {
        let r = makeRunner()
        _ = try r.start(sessionId: "s1", definition: definition())
        var gps = 5000.0
        counter(r, "gps-primary", 1, gps)
        store.failAppends = true
        gpsRun(r, total: &gps, seconds: 2)
        var s = r.snapshot()
        XCTAssertTrue(s.journalFailed)
        XCTAssertEqual(s.error?.hasPrefix("JOURNAL_WRITE_FAILED"), true)
        XCTAssertEqual(s.stageProgress, 20, accuracy: 1e-9)
        store.failAppends = false
        gpsRun(r, total: &gps, seconds: 1)
        s = r.snapshot()
        XCTAssertTrue(s.journalFailed, "sticky")
        let blocked = MemoryStore(); blocked.failAppends = true
        let r2 = makeRunner(blocked, RecordingSink(blocked))
        XCTAssertThrowsError(try r2.start(sessionId: "s5", definition: definition())) { XCTAssertEqual(($0 as? ChallengeError)?.code, "JOURNAL_WRITE_FAILED") }
        XCTAssertEqual(r2.snapshot().state, .idle)
    }

    /// A challenge that ran until the row stage and whose process "died": the runner is simply dropped.
    private func runUntilTheRowStageAndDie() throws {
        let r = makeRunner()
        _ = try r.start(sessionId: "s1", definition: definition())
        var gps = 5000.0
        counter(r, "gps-primary", 1, gps)
        gpsRun(r, total: &gps, seconds: 100)
        clock += 1000; _ = try r.nextStage(sessionId: "s1")
        delta(r, "manual", "tap-1", 50)
        _ = try r.confirm(sessionId: "s1", evidence: .manual)
        clock += 1000; _ = try r.nextStage(sessionId: "s1")
        counter(r, "pm5-rower", 2, 100)
        for i in 1...50 { clock += 1000; counter(r, "pm5-rower", 2, 100 + Double(i) * 8) }
    }

    func testARestoredChallengeComesBackPausedWithItsStagesAndProgress() throws {
        try runUntilTheRowStageAndDie()
        XCTAssertEqual(store.activeSessionId(), "s1")
        clock += 3_600_000
        let snap = try makeRunner(store, RecordingSink(store)).restore(sessionId: "s1")
        XCTAssertEqual(snap.state, .paused)
        XCTAssertEqual(snap.completed.map { $0.stageId }, ["run-1", "sled"])
        XCTAssertEqual(snap.stageId, "row")
        XCTAssertEqual(snap.stageProgress, 400, accuracy: 1e-9)
        XCTAssertEqual(snap.recoveries, 1)
        XCTAssertEqual(snap.restoreStatus, .intact)
        XCTAssertLessThan(snap.totalElapsedMs, 3_600_000, "the hour the process was dead is not counted")
    }

    func testAfterARestoreAMeasurementIsNeverCountedTwice() throws {
        try runUntilTheRowStageAndDie()
        let r2 = makeRunner()
        _ = try r2.restore(sessionId: "s1")
        _ = try r2.resume(sessionId: "s1")
        counter(r2, "pm5-rower", 2, 100 + 50 * 8) // a baseline
        XCTAssertEqual(r2.snapshot().stageProgress, 400, accuracy: 1e-9)
        clock += 1000; counter(r2, "pm5-rower", 2, 100 + 51 * 8)
        XCTAssertEqual(r2.snapshot().stageProgress, 408, accuracy: 1e-9)
        delta(r2, "manual", "tap-1", 50) // the finished stage's tap can never come back
        XCTAssertEqual(r2.snapshot().stageProgress, 408, accuracy: 1e-9)
    }

    func testRestoringTwiceIsIdempotentAndARebootedClockStillAllowsAResume() throws {
        try runUntilTheRowStageAndDie()
        let r2 = makeRunner()
        let first = try r2.restore(sessionId: "s1")
        let lines = store.files["s1"]?.count
        let second = try r2.restore(sessionId: "s1")
        XCTAssertEqual(store.files["s1"]?.count, lines, "no second replay, no second Paused line")
        XCTAssertEqual(first.stageProgress, second.stageProgress)
        XCTAssertEqual(try makeRunner().restore(sessionId: "s1").recoveries, 1)
        clock = 500
        let r3 = makeRunner()
        _ = try r3.restore(sessionId: "s1")
        XCTAssertEqual(try r3.resume(sessionId: "s1").state, .active)
    }

    func testADamagedTailIsCutOnTheDiskAndADamagedMiddleKeepsOnlyThePrefix() throws {
        try runUntilTheRowStageAndDie()
        var lines = store.files["s1"]!
        lines[lines.count - 1] = String(lines.last!.dropLast(7))
        store.files["s1"] = lines
        let damaged = lines
        let r2 = makeRunner()
        XCTAssertEqual(try r2.restore(sessionId: "s1").restoreStatus, .tailRepaired)
        XCTAssertEqual(store.originals["s1"], damaged)
        _ = try r2.resume(sessionId: "s1")
        XCTAssertEqual(try makeRunner().restore(sessionId: "s1").restoreStatus, .intact)
        store.files["s1"]![10] = store.files["s1"]![10].replacingOccurrences(of: "|", with: "#")
        XCTAssertEqual(try makeRunner().restore(sessionId: "s1").restoreStatus, .partial)
    }

    func testIfTheRepairFailsNothingIsAppendedAndTheChallengeIsNotDurable() throws {
        try runUntilTheRowStageAndDie()
        var lines = store.files["s1"]!
        lines[lines.count - 1] = String(lines.last!.dropLast(7))
        store.files["s1"] = lines
        store.failReplace = true
        let before = lines.count
        let snap = try makeRunner().restore(sessionId: "s1")
        XCTAssertTrue(snap.journalFailed)
        XCTAssertEqual(snap.error?.hasPrefix("JOURNAL_REPAIR_FAILED"), true)
        XCTAssertEqual(store.files["s1"]?.count, before)
    }

    func testAnUnknownJournalIsNotRestorableAndACompletedChallengeRestoresCompleted() throws {
        XCTAssertThrowsError(try makeRunner().restore(sessionId: "nope")) { XCTAssertEqual(($0 as? ChallengeError)?.code, "NOT_RESTORABLE") }
        let d = NativeChallengeDefinition(id: "x", version: 1, allowPause: true, stages: [stage("a", .reps, 2, .auto, ["m"])])
        let r = makeRunner()
        _ = try r.start(sessionId: "done", definition: d)
        r.submitDelta(sessionId: "done", sourceId: "m", eventId: "1", delta: 2, ageMs: 0); r.flush()
        let snap = try makeRunner().restore(sessionId: "done")
        XCTAssertEqual(snap.state, .completed)
        XCTAssertEqual(snap.recoveries, 0)
        XCTAssertNil(makeRunner().activeSessionId())
    }

    func testClearSessionDeletesTheJournalButNotAnOpenChallenge() throws {
        let r = makeRunner()
        _ = try r.start(sessionId: "s1", definition: definition())
        XCTAssertThrowsError(try r.clearSession(sessionId: "s1")) { XCTAssertEqual(($0 as? ChallengeError)?.code, "SESSION_OPEN") }
    }

    func testTheSnapshotIsPublishedPeriodically() throws {
        let r = makeRunner(snapshotEvery: 0.05)
        _ = try r.start(sessionId: "s1", definition: definition())
        r.startTicker()
        let waited = expectation(description: "ticks")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.4) { waited.fulfill() }
        wait(for: [waited], timeout: 3)
        r.stopTicker()
        XCTAssertGreaterThanOrEqual(sink.snapshots.count, 4)
    }

    func testEveryEnumOfTheCoreHasItsPigeonTwinInTheSameOrder() {
        XCTAssertEqual(ProgressMetric.values().size, Int32(NativeProgressMetric.duration.rawValue + 1))
        XCTAssertEqual(ProgressMetric.reps.ordinal, Int32(NativeProgressMetric.reps.rawValue))
        XCTAssertEqual(ProgressMetric.duration.ordinal, Int32(NativeProgressMetric.duration.rawValue))
        XCTAssertEqual(CompletionPolicy.judgeRequired.ordinal, Int32(NativeCompletionPolicy.judgeRequired.rawValue))
        XCTAssertEqual(ChallengeState.paused.ordinal, Int32(NativeChallengeState.paused.rawValue))
        XCTAssertEqual(ChallengeState.completed.ordinal, Int32(NativeChallengeState.completed.rawValue))
        XCTAssertEqual(StageStatus.targetReached.ordinal, Int32(NativeStageStatus.targetReached.rawValue))
        XCTAssertEqual(CompletionEvidence.judge.ordinal, Int32(NativeCompletionEvidence.judge.rawValue))
        XCTAssertEqual(CompletionEvidence.timer.ordinal, Int32(NativeCompletionEvidence.timer.rawValue))
    }

    func testATimedStageNeedsNoSourcesAndCompletesByTheRunnersOwnTick() throws {
        let d = NativeChallengeDefinition(id: "x", version: 1, allowPause: true, stages: [
            stage("football", .duration, 0.2, .auto, []), // 0.2 s, no sources: the clock completes it
            stage("run", .runMeters, 100, .auto, ["gps"]),
        ])
        let r = makeRunner(snapshotEvery: 0.05)
        _ = try r.start(sessionId: "s1", definition: d)
        clock += 250 // the monotonic clock of the test jumps past the target
        r.startTicker()
        let waited = expectation(description: "ticks")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.4) { waited.fulfill() }
        wait(for: [waited], timeout: 3)
        r.stopTicker()
        let snap = r.snapshot()
        XCTAssertEqual(snap.state, .transition)
        XCTAssertEqual(snap.completed.first?.evidence, .timer)
        XCTAssertEqual(snap.completed.first?.durationMs, 200)
    }

    func testAStageThatIsNotTimedStillNeedsItsSources() {
        let d = NativeChallengeDefinition(id: "x", version: 1, allowPause: true, stages: [stage("run", .runMeters, 100, .auto, [])])
        let r = makeRunner()
        XCTAssertEqual(errorCode { _ = try r.start(sessionId: "s1", definition: d) }, "BAD_DEFINITION")
    }

    func testTheFileStoreAppendsReadsReplacesAtomicallyAndKeepsTheActivePointer() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("cf-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: dir) }
        let s = FileChallengeJournalStore(dir: dir)
        try s.append(sessionId: "a/b c", lines: ["one", "two"])
        try s.append(sessionId: "a/b c", lines: ["three"])
        XCTAssertEqual(try s.read(sessionId: "a/b c"), ["one", "two", "three"])
        try s.append(sessionId: "a_b_c", lines: ["x"])
        XCTAssertEqual(try s.read(sessionId: "a/b c"), ["one", "two", "three"])
        try s.setActive("a/b c")
        XCTAssertEqual(s.activeSessionId(), "a/b c")
        let kept = try s.replaceKeepingOriginal(sessionId: "a/b c", lines: ["one", "two"])
        XCTAssertEqual(try s.read(sessionId: "a/b c"), ["one", "two"])
        XCTAssertEqual(try String(contentsOf: dir.appendingPathComponent(kept), encoding: .utf8).split(separator: "\n").count, 3)
        try s.append(sessionId: "a/b c", lines: ["four"])
        XCTAssertEqual(try s.read(sessionId: "a/b c"), ["one", "two", "four"])
        try s.clear(sessionId: "a/b c")
        XCTAssertEqual(try s.read(sessionId: "a/b c"), [])
        XCTAssertNil(s.activeSessionId())
    }

    // MARK: - Session lifecycle contract (mirrors the Android tests)

    private func errorCode(_ block: () throws -> Void) -> String? {
        do { try block() } catch { return (error as? ChallengeError)?.code }
        return nil
    }

    private func singleRun() -> NativeChallengeDefinition {
        NativeChallengeDefinition(id: "race", version: 1, allowPause: true, stages: [stage("run", .runMeters, 5, .auto, ["gps"])])
    }

    func testASessionIdCannotBeReusedWhileItsJournalExists() throws {
        let r = makeRunner()
        _ = try r.start(sessionId: "race-001", definition: singleRun())
        counter(r, "gps", 1, 100, id: "race-001")
        clock += 1000
        counter(r, "gps", 1, 105, id: "race-001")
        let lines = store.files["race-001"]
        XCTAssertEqual(errorCode { _ = try r.start(sessionId: "race-001", definition: self.singleRun()) }, "SESSION_EXISTS")
        XCTAssertEqual(store.files["race-001"], lines, "nothing was appended behind the first challenge's journal")
        try r.clearSession(sessionId: "race-001")
        _ = try r.start(sessionId: "race-001", definition: singleRun()) // the id is free again
    }

    func testAnEmptyJournalFileStillTakesTheId() throws {
        store.files["taken"] = []
        let r = makeRunner()
        XCTAssertEqual(errorCode { _ = try r.start(sessionId: "taken", definition: self.singleRun()) }, "SESSION_EXISTS")
    }

    func testAStartThatCannotWriteItsFirstLineLeavesTheIdFree() throws {
        let r = makeRunner()
        store.failAppends = true
        XCTAssertEqual(errorCode { _ = try r.start(sessionId: "retry", definition: self.singleRun()) }, "JOURNAL_WRITE_FAILED")
        store.failAppends = false
        _ = try r.start(sessionId: "retry", definition: singleRun()) // not SESSION_EXISTS
    }

    func testACompletedChallengeReleasesTheActivePointerOnlyOnceItIsOnTheDisk() throws {
        let r = makeRunner()
        _ = try r.start(sessionId: "race-001", definition: singleRun())
        XCTAssertEqual(r.activeSessionId(), "race-001")
        counter(r, "gps", 1, 100, id: "race-001")
        clock += 1000
        counter(r, "gps", 1, 105, id: "race-001")
        XCTAssertEqual(r.snapshot().state, .completed)
        XCTAssertNil(r.activeSessionId())

        let r2 = makeRunner()
        _ = try r2.start(sessionId: "race-002", definition: singleRun())
        counter(r2, "gps", 1, 100, id: "race-002")
        clock += 1000
        store.failAppends = true // the completion cannot be written: the pointer that finds the challenge to recover must stay
        counter(r2, "gps", 1, 105, id: "race-002")
        XCTAssertEqual(r2.activeSessionId(), "race-002")
        XCTAssertTrue(r2.snapshot().journalFailed)
    }

    func testANewChallengeCannotReplaceTheRecoveryPointerOfOneWhoseCompletionWasNotWritten() throws {
        let r = makeRunner()
        _ = try r.start(sessionId: "A", definition: singleRun())
        counter(r, "gps", 1, 100, id: "A")
        clock += 1000
        store.failAppends = true
        counter(r, "gps", 1, 105, id: "A") // A completes in memory, the completion is not on the disk
        store.failAppends = false
        XCTAssertEqual(r.snapshot().state, .completed)
        XCTAssertTrue(r.snapshot().journalFailed)
        XCTAssertEqual(errorCode { _ = try r.start(sessionId: "B", definition: self.singleRun()) }, "RECOVERY_REQUIRED")
        XCTAssertEqual(r.activeSessionId(), "A")
        XCTAssertNil(store.files["B"])
        try r.clearSession(sessionId: "A") // discarding A on purpose frees the runner
        let b = try r.start(sessionId: "B", definition: singleRun())
        XCTAssertEqual(b.sessionId, "B")
        XCTAssertFalse(b.journalFailed)
    }

    func testASampleIsTimedWhenItArrivedNotWhenTheQueueGetsToIt() throws {
        let d = NativeChallengeDefinition(id: "x", version: 1, allowPause: true, stages: [stage("run", .runMeters, 1000, .auto, ["gps"])])
        let r = makeRunner()
        _ = try r.start(sessionId: "s1", definition: d)
        clock = 1_000; counter(r, "gps", 1, 100)
        clock = 2_000; _ = try r.pause(sessionId: "s1")
        clock = 5_000; _ = try r.resume(sessionId: "s1")
        // two samples that ARRIVED during the pause (3.0 s, 3.5 s) but are processed after the resume
        r.submitCounter(sessionId: "s1", sourceId: "gps", epoch: 1, meters: 120, ageMs: 0, receivedMonotonicMs: 3_000); r.flush()
        r.submitCounter(sessionId: "s1", sourceId: "gps", epoch: 1, meters: 125, ageMs: 0, receivedMonotonicMs: 3_500); r.flush()
        XCTAssertEqual(r.snapshot().stageProgress, 0, accuracy: 1e-9)
        clock = 5_500; counter(r, "gps", 1, 140) // the first sample after the resume: a baseline
        clock = 6_500; counter(r, "gps", 1, 145)
        XCTAssertEqual(r.snapshot().stageProgress, 5, accuracy: 1e-9)
    }

    func testATapOrConfirmationMadeForAnOldStageIsRefusedOrDropped() throws {
        let d = NativeChallengeDefinition(id: "x", version: 1, allowPause: true, stages: [
            stage("a", .reps, 2, .manual, ["tap"]),
            stage("b", .reps, 2, .manual, ["tap"]),
        ])
        let r = makeRunner()
        let first = try r.start(sessionId: "s1", definition: d)
        r.submitDelta(sessionId: "s1", sourceId: "tap", eventId: "t1", delta: 2, ageMs: 0, stageActivation: first.stageActivation); r.flush()
        _ = try r.confirm(sessionId: "s1", evidence: .manual, expectedStageActivation: first.stageActivation)
        _ = try r.nextStage(sessionId: "s1")
        r.submitDelta(sessionId: "s1", sourceId: "tap", eventId: "t2", delta: 1, ageMs: 0, stageActivation: first.stageActivation); r.flush() // the callback of stage a, in stage b
        XCTAssertEqual(r.snapshot().stageProgress, 0, accuracy: 1e-9)
        XCTAssertEqual(errorCode { _ = try r.confirm(sessionId: "s1", evidence: .manual, expectedStageActivation: first.stageActivation) }, "STALE_ACTIVATION")
        XCTAssertEqual(r.snapshot().state, .active)
    }

    func testRestoringAnotherChallengeWhileOneIsOpenIsRefusedAndChangesNothing() throws {
        let d = NativeChallengeDefinition(id: "x", version: 1, allowPause: true, stages: [stage("a", .reps, 1, .auto, ["m"])])
        let other = makeRunner()
        _ = try other.start(sessionId: "b", definition: d)
        other.submitDelta(sessionId: "b", sourceId: "m", eventId: "1", delta: 1, ageMs: 0); other.flush() // b is completed: restorable
        let r = makeRunner()
        _ = try r.start(sessionId: "s1", definition: definition())
        XCTAssertEqual(errorCode { _ = try r.restore(sessionId: "b") }, "SESSION_OPEN")
        XCTAssertEqual(r.activeSessionId(), "s1")
        XCTAssertEqual(r.snapshot().stageId, "run-1")
    }

    func testOnlyOneEngineOwnsTheJournalDirectory() {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let first = ChallengeDirectoryOwner(dir: dir)
        let second = ChallengeDirectoryOwner(dir: dir)
        XCTAssertTrue(first.tryAcquire())
        XCTAssertTrue(first.tryAcquire(), "asking again is fine")
        XCTAssertFalse(second.tryAcquire(), "a second engine must not get it")
        first.release()
        XCTAssertTrue(second.tryAcquire(), "after the first engine detached")
        second.release()
    }
}
