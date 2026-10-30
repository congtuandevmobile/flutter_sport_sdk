import Flutter
import Foundation

/// Flutter entry point. Thin on purpose: every command and every sample is run on ONE serial queue, in the order it arrived, so the
/// journal is written and synced there and the main thread never waits for the disk (and two commands can never swap). The answer
/// goes back on the main thread, after the write. A `ChallengeError` becomes a `PigeonError` with its code.
///
/// The challenge (and its journal) belongs to the engine of this plugin instance: a challenge that must outlive the Flutter engine needs a
/// process-wide owner, which is not built yet.
public final class FlutterChallengePlugin: NSObject, FlutterPlugin, ChallengeHostApi, ChallengeSink {
    private var engine: ChallengeRunner?
    private var flutterApi: ChallengeFlutterApi?
    private let calls = DispatchQueue(label: "flutter_challenge.calls")

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = FlutterChallengePlugin()
        instance.flutterApi = ChallengeFlutterApi(binaryMessenger: registrar.messenger())
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("flutter_challenge", isDirectory: true)
        let engine = ChallengeRunner(store: FileChallengeJournalStore(dir: support), sink: instance)
        instance.engine = engine
        engine.startTicker()
        ChallengeHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
        registrar.publish(instance)
    }

    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        ChallengeHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: nil)
        engine?.stopTicker()
        engine = nil
        flutterApi = nil
    }

    /// Runs `block` on the calls queue; the completion gets the result on the main thread.
    private func command<T>(_ completion: @escaping (Result<T, Error>) -> Void, _ block: @escaping (ChallengeRunner) throws -> T) {
        calls.async { [weak self] in
            let result: Result<T, Error>
            if let engine = self?.engine {
                do { result = .success(try block(engine)) } catch let e as ChallengeError {
                    result = .failure(PigeonError(code: e.code, message: e.message, details: nil))
                } catch {
                    result = .failure(PigeonError(code: "CHALLENGE_FAILED", message: error.localizedDescription, details: nil))
                }
            } else {
                result = .failure(PigeonError(code: "DETACHED", message: "the plugin is detached", details: nil))
            }
            DispatchQueue.main.async { completion(result) }
        }
    }

    // MARK: - ChallengeHostApi

    func start(sessionId: String, definition: NativeChallengeDefinition, completion: @escaping (Result<NativeChallengeSnapshot, Error>) -> Void) {
        command(completion) { try $0.start(sessionId: sessionId, definition: definition) }
    }
    func confirm(sessionId: String, evidence: NativeCompletionEvidence, expectedStageActivation: Int64?, completion: @escaping (Result<NativeChallengeSnapshot, Error>) -> Void) {
        command(completion) { try $0.confirm(sessionId: sessionId, evidence: evidence, expectedStageActivation: expectedStageActivation) }
    }
    func nextStage(sessionId: String, completion: @escaping (Result<NativeChallengeSnapshot, Error>) -> Void) {
        command(completion) { try $0.nextStage(sessionId: sessionId) }
    }
    func pause(sessionId: String, completion: @escaping (Result<NativeChallengeSnapshot, Error>) -> Void) {
        command(completion) { try $0.pause(sessionId: sessionId) }
    }
    func resume(sessionId: String, completion: @escaping (Result<NativeChallengeSnapshot, Error>) -> Void) {
        command(completion) { try $0.resume(sessionId: sessionId) }
    }
    func snapshot(completion: @escaping (Result<NativeChallengeSnapshot, Error>) -> Void) {
        command(completion) { $0.snapshot() }
    }
    func restore(sessionId: String, completion: @escaping (Result<NativeChallengeSnapshot, Error>) -> Void) {
        command(completion) { try $0.restore(sessionId: sessionId) }
    }
    func activeSessionId(completion: @escaping (Result<String?, Error>) -> Void) {
        command(completion) { $0.activeSessionId() }
    }
    func clearSession(sessionId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        command(completion) { try $0.clearSession(sessionId: sessionId) }
    }

    /// A sample: queued behind the commands that came before it, never blocking the caller.
    func submitCounter(sessionId: String, sourceId: String, epoch: Int64, meters: Double, ageMs: Int64) throws {
        calls.async { [weak self] in
            self?.engine?.submitCounter(sessionId: sessionId, sourceId: sourceId, epoch: epoch, meters: meters, ageMs: ageMs)
        }
    }
    func submitDelta(sessionId: String, sourceId: String, eventId: String, delta: Double, ageMs: Int64, stageActivation: Int64?) throws {
        calls.async { [weak self] in
            self?.engine?.submitDelta(sessionId: sessionId, sourceId: sourceId, eventId: eventId, delta: delta, ageMs: ageMs, stageActivation: stageActivation)
        }
    }

    // MARK: - ChallengeSink (called from the engine queue; Flutter wants the main thread)

    func onSnapshot(_ snapshot: NativeChallengeSnapshot) {
        DispatchQueue.main.async { [weak self] in self?.flutterApi?.onSnapshot(snapshot: snapshot) { _ in } }
    }
}
