import Flutter
import WorkoutCore
import XCTest

@testable import flutter_workout

private final class MemoryStore: WorkoutJournalStore {
    var files: [String: [String]] = [:]
    var activeId: String?
    var failAppends = false
    func append(sessionId: String, lines: [String]) throws {
        if failAppends { throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "disk full"]) }
        files[sessionId, default: []].append(contentsOf: lines)
    }
    func exists(sessionId: String) -> Bool { files[sessionId] != nil }
    func read(sessionId: String) throws -> [String] { files[sessionId] ?? [] }
    func clear(sessionId: String) throws { files[sessionId] = nil; if activeId == sessionId { activeId = nil } }
    var failReplace = false
    var originals: [String: [String]] = [:]
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

private final class RecordingSink: WorkoutSink {
    private let store: MemoryStore
    var snapshots: [NativeWorkoutSnapshot] = []
    var linesAtPublish: [Int] = []
    init(_ store: MemoryStore) { self.store = store }
    func onSnapshot(_ snapshot: NativeWorkoutSnapshot) { snapshots.append(snapshot); linesAtPublish.append(store.totalLines) }
}

final class RunnerTests: XCTestCase {
    private var clock: Int64 = 1_000
    private let store = MemoryStore()
    private lazy var sink = RecordingSink(store)
    private let foot = NativeSourceRef(id: "footpod", kind: .counter)
    private let speed = NativeSourceRef(id: "foot-speed", kind: .speed)

    private func makeEngine(_ s: MemoryStore? = nil, _ k: RecordingSink? = nil, snapshotEvery: TimeInterval = 1) -> WorkoutEngine {
        WorkoutEngine(store: s ?? store, sink: k ?? sink, monotonicMs: { self.clock }, snapshotEvery: snapshotEvery)
    }

    private func counter(_ e: WorkoutEngine, _ meters: Double, id: String = "w1", source: NativeSourceRef? = nil, epoch: Int64 = 1, age: Int64 = 0) {
        e.submitCounter(sessionId: id, source: source ?? foot, epoch: epoch, meters: meters, ageMs: age)
        e.flush()
    }

    func testStartWritesTheFirstLineBeforeItReturns() throws {
        let e = makeEngine()
        let snap = try e.start(sessionId: "w1", mode: .indoorRunning)
        XCTAssertEqual(snap.state, .running)
        XCTAssertEqual(store.files["w1"]?.count, 1)
        XCTAssertEqual(store.activeSessionId(), "w1")
    }

    func testANumberIsNeverShownBeforeItIsOnTheDisk() throws {
        let e = makeEngine()
        _ = try e.start(sessionId: "w1", mode: .indoorRunning)
        counter(e, 0)
        clock += 3000
        counter(e, 10)
        XCTAssertEqual(sink.snapshots.last?.distanceMeters ?? 0, 10, accuracy: 1e-9)
        XCTAssertTrue(store.files["w1"]?.contains { $0.contains("|D|") } == true)
        XCTAssertEqual(sink.linesAtPublish.last, store.totalLines)
    }

    func testPauseAndResumeNeverCreditThePausedDistance() throws {
        let e = makeEngine()
        _ = try e.start(sessionId: "w1", mode: .indoorRunning)
        counter(e, 0)
        clock += 10_000; counter(e, 30)
        _ = try e.pause(sessionId: "w1")
        clock += 60_000; counter(e, 530)
        _ = try e.resume(sessionId: "w1")
        clock += 1000; counter(e, 531)
        clock += 3000; counter(e, 534)
        XCTAssertEqual(e.snapshot().distanceMeters, 33, accuracy: 1e-9)
    }

    func testASecondStartWhileOneIsOpenIsRefused() throws {
        let e = makeEngine()
        _ = try e.start(sessionId: "w1", mode: .indoorRunning)
        XCTAssertThrowsError(try e.start(sessionId: "w2", mode: .indoorRunning)) { error in
            XCTAssertEqual((error as? WorkoutError)?.code, "SESSION_OPEN")
        }
        _ = try e.finish(sessionId: "w1")
        _ = try e.start(sessionId: "w2", mode: .indoorRunning)
    }

    func testSamplesAndCommandsOfAnotherSessionAreDropped() throws {
        let e = makeEngine()
        _ = try e.start(sessionId: "w1", mode: .indoorRunning)
        counter(e, 0, id: "other")
        clock += 3000
        counter(e, 50, id: "other")
        XCTAssertEqual(e.snapshot().distanceMeters, 0)
        XCTAssertThrowsError(try e.pause(sessionId: "other")) { XCTAssertEqual(($0 as? WorkoutError)?.code, "NO_SESSION") }
    }

    func testASampleIsStampedWithItsRealTimeNotTheTimeOfTheCall() throws {
        let e = makeEngine()
        _ = try e.start(sessionId: "w1", mode: .indoorRunning)
        clock = 6_000
        e.submitSpeed(sessionId: "w1", source: speed, epoch: 1, mps: 3, ageMs: 4_000); e.flush()
        clock = 7_000
        e.submitSpeed(sessionId: "w1", source: speed, epoch: 1, mps: 3, ageMs: 4_000); e.flush()
        XCTAssertEqual(e.snapshot().distanceMeters, 3, accuracy: 1e-9)
    }

    func testAFailedWriteIsReportedAndStickyButTheWorkoutGoesOn() throws {
        let e = makeEngine()
        _ = try e.start(sessionId: "w1", mode: .indoorRunning)
        counter(e, 0)
        store.failAppends = true
        clock += 3000; counter(e, 10)
        var s = e.snapshot()
        XCTAssertTrue(s.journalFailed)
        XCTAssertEqual(s.error?.hasPrefix("JOURNAL_WRITE_FAILED"), true)
        XCTAssertEqual(s.distanceMeters, 10, accuracy: 1e-9)
        store.failAppends = false
        clock += 3000; counter(e, 20)
        s = e.snapshot()
        XCTAssertTrue(s.journalFailed, "sticky")
    }

    func testAWorkoutThatCannotWriteItsFirstLineIsNotStarted() {
        store.failAppends = true
        let e = makeEngine()
        XCTAssertThrowsError(try e.start(sessionId: "w1", mode: .indoorRunning)) {
            XCTAssertEqual(($0 as? WorkoutError)?.code, "JOURNAL_WRITE_FAILED")
        }
        XCTAssertEqual(e.snapshot().state, .idle)
    }

    /// A workout that ran and whose process "died": the engine is simply dropped.
    private func runWorkoutAndDie() throws -> Double {
        let e = makeEngine()
        _ = try e.start(sessionId: "w1", mode: .indoorRunning)
        counter(e, 100)
        for i in 1...4 { clock += 10_000; counter(e, 100 + Double(i) * 30) }
        return e.snapshot().distanceMeters
    }

    func testARestoredWorkoutComesBackPausedWithItsDistanceAndNothingInvented() throws {
        let distance = try runWorkoutAndDie()
        XCTAssertEqual(store.activeSessionId(), "w1")
        clock += 3_600_000
        let e2 = makeEngine(store, RecordingSink(store))
        let snap = try e2.restore(sessionId: "w1")
        XCTAssertEqual(snap.state, .paused)
        XCTAssertEqual(snap.distanceMeters, distance, accuracy: 1e-9)
        XCTAssertEqual(snap.restoreStatus, .intact)
        XCTAssertEqual(snap.activeMs, 40_000, "the hour the process was dead is not activity")
        XCTAssertNil(snap.distanceSource, "nothing is counting until a sensor speaks again")
        XCTAssertEqual(snap.lastDistanceSource?.kind, .counter)
        _ = try e2.resume(sessionId: "w1")
        counter(e2, 1000)
        clock += 3000; counter(e2, 1010)
        XCTAssertEqual(e2.snapshot().distanceMeters, distance + 10, accuracy: 1e-9)
    }

    func testRestoringTwiceDoesNotReplayAgainAndIsIdempotent() throws {
        let distance = try runWorkoutAndDie()
        let e2 = makeEngine()
        let first = try e2.restore(sessionId: "w1")
        let after = store.files["w1"]?.count
        let second = try e2.restore(sessionId: "w1")
        XCTAssertEqual(store.files["w1"]?.count, after, "no second replay, no second Paused line")
        XCTAssertEqual(first.distanceMeters, second.distanceMeters)
        XCTAssertEqual(second.distanceMeters, distance, accuracy: 1e-9)
        let e3 = makeEngine()
        XCTAssertEqual(try e3.restore(sessionId: "w1").distanceMeters, distance, accuracy: 1e-9)
    }

    func testARebootThatRestartedTheMonotonicClockLowerStillAllowsAResume() throws {
        _ = try runWorkoutAndDie()
        clock = 500
        let e2 = makeEngine()
        _ = try e2.restore(sessionId: "w1")
        let resumed = try e2.resume(sessionId: "w1")
        XCTAssertEqual(resumed.state, .running)
        clock += 5_000
        XCTAssertEqual(e2.snapshot().activeMs, 45_000)
    }

    func testACutLastLineIsRepairedAndADamagedMiddleKeepsOnlyThePrefix() throws {
        _ = try runWorkoutAndDie()
        var lines = store.files["w1"]!
        lines[lines.count - 1] = String(lines.last!.dropLast(7))
        store.files["w1"] = lines
        XCTAssertEqual(try makeEngine().restore(sessionId: "w1").restoreStatus, .tailRepaired)
        store.files["w1"]![3] = store.files["w1"]![3].replacingOccurrences(of: "|", with: "#")
        XCTAssertEqual(try makeEngine().restore(sessionId: "w1").restoreStatus, .partial)
    }

    func testADamagedTailIsCutOnTheDiskBeforeAnythingIsAppendedSoLaterLinesAreNeverHidden() throws {
        _ = try runWorkoutAndDie()
        var lines = store.files["w1"]!
        lines[lines.count - 1] = String(lines.last!.dropLast(7))
        store.files["w1"] = lines
        let damaged = lines
        let e2 = makeEngine()
        XCTAssertEqual(try e2.restore(sessionId: "w1").restoreStatus, .tailRepaired)
        XCTAssertEqual(store.originals["w1"], damaged, "the damaged original is kept for diagnosis")
        _ = try e2.resume(sessionId: "w1")
        counter(e2, 500)
        clock += 3000; counter(e2, 510)
        let again = try makeEngine().restore(sessionId: "w1")
        XCTAssertEqual(again.restoreStatus, .intact, "nothing is hidden behind a damaged line any more")
        XCTAssertEqual(again.distanceMeters, e2.snapshot().distanceMeters, accuracy: 1e-9)
    }

    func testADamagedMiddleIsCutToItsGoodPrefix() throws {
        _ = try runWorkoutAndDie()
        store.files["w1"]![3] = store.files["w1"]![3].replacingOccurrences(of: "|", with: "#")
        XCTAssertEqual(try makeEngine().restore(sessionId: "w1").restoreStatus, .partial)
        XCTAssertEqual(try makeEngine().restore(sessionId: "w1").restoreStatus, .intact)
    }

    func testIfTheRepairFailsNothingIsAppendedAndTheWorkoutIsNotDurable() throws {
        let local = MemoryStore()
        let e = WorkoutEngine(store: local, sink: RecordingSink(local), monotonicMs: { self.clock })
        _ = try e.start(sessionId: "w3", mode: .indoorRunning)
        counter(e, 0, id: "w3")
        var lines = local.files["w3"]!
        lines[lines.count - 1] = String(lines.last!.dropLast(7))
        local.files["w3"] = lines
        local.failReplace = true
        let before = lines.count
        let snap = try WorkoutEngine(store: local, sink: RecordingSink(local), monotonicMs: { self.clock }).restore(sessionId: "w3")
        XCTAssertTrue(snap.journalFailed)
        XCTAssertEqual(snap.error?.hasPrefix("JOURNAL_REPAIR_FAILED"), true)
        XCTAssertEqual(local.files["w3"]?.count, before, "no recovery line behind the damage")
        XCTAssertEqual(snap.state, .paused)
    }

    func testAnUnknownOrEmptyJournalIsNotRestorable() {
        XCTAssertThrowsError(try makeEngine().restore(sessionId: "nope")) {
            XCTAssertEqual(($0 as? WorkoutError)?.code, "NOT_RESTORABLE")
        }
    }

    func testAFinishedWorkoutClearsTheActivePointerAndRestoresAsFinished() throws {
        let e = makeEngine()
        _ = try e.start(sessionId: "w1", mode: .indoorRunning)
        _ = try e.finish(sessionId: "w1")
        XCTAssertNil(e.activeSessionId())
        XCTAssertEqual(try makeEngine().restore(sessionId: "w1").state, .finished)
        XCTAssertNil(store.activeSessionId())
    }

    func testClearSessionDeletesTheJournalButNotAnOpenWorkout() throws {
        let e = makeEngine()
        _ = try e.start(sessionId: "w1", mode: .indoorRunning)
        XCTAssertThrowsError(try e.clearSession(sessionId: "w1")) { XCTAssertEqual(($0 as? WorkoutError)?.code, "SESSION_OPEN") }
        _ = try e.finish(sessionId: "w1")
        try e.clearSession(sessionId: "w1")
        XCTAssertNil(store.files["w1"])
        XCTAssertEqual(e.snapshot().state, .idle)
    }

    func testTheSnapshotIsPublishedPeriodically() throws {
        let e = makeEngine(snapshotEvery: 0.05)
        _ = try e.start(sessionId: "w1", mode: .indoorRunning)
        e.startTicker()
        let waited = expectation(description: "ticks")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.4) { waited.fulfill() }
        wait(for: [waited], timeout: 3)
        e.stopTicker()
        XCTAssertGreaterThanOrEqual(sink.snapshots.count, 4)
    }

    func testEveryModeStateAndSourceKindOfTheCoreHasItsPigeonTwinInTheSameOrder() {
        XCTAssertEqual(WorkoutMode.values().size, Int32(NativeWorkoutMode.indoorCycling.rawValue + 1))
        XCTAssertEqual(WorkoutMode.indoorRunning.ordinal, Int32(NativeWorkoutMode.indoorRunning.rawValue))
        XCTAssertEqual(WorkoutState.paused.ordinal, Int32(NativeWorkoutState.paused.rawValue))
        XCTAssertEqual(WorkoutState.finished.ordinal, Int32(NativeWorkoutState.finished.rawValue))
        XCTAssertEqual(DistanceSourceKind.speed.ordinal, Int32(NativeSourceKind.speed.rawValue))
        XCTAssertEqual(DistanceSourceKind.counter.ordinal, Int32(NativeSourceKind.counter.rawValue))
    }

    func testTheFileStoreAppendsReadsClearsAndKeepsTheActivePointer() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("wf-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: dir) }
        let s = FileWorkoutJournalStore(dir: dir)
        try s.append(sessionId: "a/b c", lines: ["one", "two"])
        try s.append(sessionId: "a/b c", lines: ["three"])
        XCTAssertEqual(try s.read(sessionId: "a/b c"), ["one", "two", "three"])
        XCTAssertEqual(try s.read(sessionId: "missing"), [])
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
        do { try block() } catch { return (error as? WorkoutError)?.code }
        return nil
    }

    func testAFinishThatCannotBeWrittenKeepsTheActivePointerForRecovery() throws {
        let e = makeEngine()
        _ = try e.start(sessionId: "w1", mode: .indoorRunning)
        store.failAppends = true
        _ = try e.finish(sessionId: "w1")
        XCTAssertTrue(e.snapshot().journalFailed)
        XCTAssertEqual(e.activeSessionId(), "w1", "the journal still says the workout is open: the pointer must still lead to it")
    }

    func testAFinishThatWasWrittenReleasesThePointerAndTheSnapshotShowsIt() throws {
        let e = makeEngine()
        _ = try e.start(sessionId: "w1", mode: .indoorRunning)
        let snap = try e.finish(sessionId: "w1")
        XCTAssertEqual(snap.state, .finished)
        XCTAssertNil(e.activeSessionId())
    }

    func testANewWorkoutCannotReplaceTheRecoveryPointerOfOneWhoseFinishWasNotWritten() throws {
        let e = makeEngine()
        _ = try e.start(sessionId: "w1", mode: .indoorRunning)
        store.failAppends = true
        _ = try e.finish(sessionId: "w1")
        store.failAppends = false
        XCTAssertEqual(errorCode { _ = try e.start(sessionId: "w2", mode: .indoorRunning) }, "RECOVERY_REQUIRED")
        XCTAssertEqual(e.activeSessionId(), "w1")
        XCTAssertNil(store.files["w2"])
        try e.clearSession(sessionId: "w1") // discarding w1 on purpose frees the engine
        let w2 = try e.start(sessionId: "w2", mode: .indoorRunning)
        XCTAssertEqual(w2.sessionId, "w2")
        XCTAssertFalse(w2.journalFailed)
    }

    func testASessionIdCannotBeReusedWhileItsJournalExists() throws {
        let e = makeEngine()
        _ = try e.start(sessionId: "w1", mode: .indoorRunning)
        _ = try e.finish(sessionId: "w1")
        let lines = store.files["w1"]
        XCTAssertEqual(errorCode { _ = try e.start(sessionId: "w1", mode: .indoorRunning) }, "SESSION_EXISTS")
        XCTAssertEqual(store.files["w1"], lines, "nothing was appended behind the first workout's journal")
        try e.clearSession(sessionId: "w1")
        _ = try e.start(sessionId: "w1", mode: .indoorRunning) // the id is free again
    }

    func testAnEmptyJournalFileStillTakesTheId() throws {
        store.files["taken"] = []
        let e = makeEngine()
        XCTAssertEqual(errorCode { _ = try e.start(sessionId: "taken", mode: .indoorRunning) }, "SESSION_EXISTS")
    }

    func testAStartThatCannotWriteItsFirstLineLeavesTheIdFree() throws {
        let e = makeEngine()
        store.failAppends = true
        XCTAssertEqual(errorCode { _ = try e.start(sessionId: "retry", mode: .indoorRunning) }, "JOURNAL_WRITE_FAILED")
        store.failAppends = false
        _ = try e.start(sessionId: "retry", mode: .indoorRunning) // not SESSION_EXISTS
    }

    func testASampleIsTimedWhenItArrivedNotWhenTheQueueGetsToIt() throws {
        let e = makeEngine()
        _ = try e.start(sessionId: "w1", mode: .indoorRunning)
        counter(e, 0)
        clock += 1000; _ = try e.pause(sessionId: "w1")
        clock += 4000; _ = try e.resume(sessionId: "w1") // resumed at 6000
        // samples that ARRIVED during the pause, processed after the resume
        e.submitCounter(sessionId: "w1", source: foot, epoch: 1, meters: 100, ageMs: 0, receivedMonotonicMs: 3_000); e.flush()
        e.submitCounter(sessionId: "w1", source: foot, epoch: 1, meters: 110, ageMs: 0, receivedMonotonicMs: 3_500); e.flush()
        XCTAssertEqual(e.snapshot().distanceMeters, 0, accuracy: 1e-9)
        clock += 500; counter(e, 120)
        clock += 1000; counter(e, 125)
        XCTAssertEqual(e.snapshot().distanceMeters, 5, accuracy: 1e-9)
    }

    func testRestoringAnotherWorkoutWhileOneIsOpenIsRefusedAndChangesNothing() throws {
        let other = makeEngine()
        _ = try other.start(sessionId: "w2", mode: .indoorRunning)
        _ = try other.finish(sessionId: "w2") // w2 has a restorable journal
        let e = makeEngine()
        _ = try e.start(sessionId: "w1", mode: .indoorRunning)
        XCTAssertEqual(errorCode { _ = try e.restore(sessionId: "w2") }, "SESSION_OPEN")
        XCTAssertEqual(e.activeSessionId(), "w1")
        XCTAssertEqual(e.snapshot().state, .running)
    }

    func testOnlyOneEngineOwnsTheJournalDirectory() {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let first = WorkoutDirectoryOwner(dir: dir)
        let second = WorkoutDirectoryOwner(dir: dir)
        XCTAssertTrue(first.tryAcquire())
        XCTAssertTrue(first.tryAcquire(), "asking again is fine")
        XCTAssertFalse(second.tryAcquire(), "a second engine must not get it")
        first.release()
        XCTAssertTrue(second.tryAcquire(), "after the first engine detached")
        second.release()
    }
}
