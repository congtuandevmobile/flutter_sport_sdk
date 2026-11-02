import Flutter
import Foundation

/// Flutter entry point. Thin on purpose: every command and every sample is run on ONE serial queue, in the order it arrived, so the
/// journal is written and synced there and the main thread never waits for the disk (and two commands can never swap). The answer
/// goes back on the main thread, after the write. A `WorkoutError` becomes a `PigeonError` with its code.
///
/// The workout (and its journal) belongs to the engine of this plugin instance: a workout that must outlive the Flutter engine needs a
/// process-wide owner, which is not built yet.
public final class FlutterWorkoutPlugin: NSObject, FlutterPlugin, WorkoutHostApi, WorkoutSink {
    private var engine: WorkoutEngine?
    private var flutterApi: WorkoutFlutterApi?
    private var owner: WorkoutDirectoryOwner?

    /// True when another Flutter engine of the app already owns the journal directory: every command then fails, nothing is written.
    private var notOwner = false
    private let calls = DispatchQueue(label: "flutter_workout.calls")

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = FlutterWorkoutPlugin()
        instance.flutterApi = WorkoutFlutterApi(binaryMessenger: registrar.messenger())
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("flutter_workout", isDirectory: true)
        let owner = WorkoutDirectoryOwner(dir: support)
        if owner.tryAcquire() {
            instance.owner = owner
            let engine = WorkoutEngine(store: FileWorkoutJournalStore(dir: support), sink: instance)
            instance.engine = engine
            engine.startTicker()
        } else {
            instance.notOwner = true
        }
        WorkoutHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
        registrar.publish(instance)
    }

    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        WorkoutHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: nil)
        engine?.stopTicker()
        engine = nil
        owner?.release()
        owner = nil
        notOwner = false
        flutterApi = nil
    }

    /// Runs `block` on the calls queue; the completion gets the result on the main thread.
    private func command<T>(_ completion: @escaping (Result<T, Error>) -> Void, _ block: @escaping (WorkoutEngine) throws -> T) {
        calls.async { [weak self] in
            let result: Result<T, Error>
            if let engine = self?.engine {
                do { result = .success(try block(engine)) } catch let e as WorkoutError {
                    result = .failure(PigeonError(code: e.code, message: e.message, details: nil))
                } catch {
                    result = .failure(PigeonError(code: "WORKOUT_FAILED", message: error.localizedDescription, details: nil))
                }
            } else {
                if self?.notOwner == true {
                    result = .failure(PigeonError(code: "OWNED_BY_ANOTHER_ENGINE", message: "this plugin does not own the journal directory: another Flutter engine of the app already does (one engine at a time)", details: nil))
                } else {
                    result = .failure(PigeonError(code: "DETACHED", message: "the plugin is detached", details: nil))
                }
            }
            DispatchQueue.main.async { completion(result) }
        }
    }

    // MARK: - WorkoutHostApi

    func start(sessionId: String, mode: NativeWorkoutMode, completion: @escaping (Result<NativeWorkoutSnapshot, Error>) -> Void) {
        command(completion) { try $0.start(sessionId: sessionId, mode: mode) }
    }
    func pause(sessionId: String, completion: @escaping (Result<NativeWorkoutSnapshot, Error>) -> Void) {
        command(completion) { try $0.pause(sessionId: sessionId) }
    }
    func resume(sessionId: String, completion: @escaping (Result<NativeWorkoutSnapshot, Error>) -> Void) {
        command(completion) { try $0.resume(sessionId: sessionId) }
    }
    func finish(sessionId: String, completion: @escaping (Result<NativeWorkoutSnapshot, Error>) -> Void) {
        command(completion) { try $0.finish(sessionId: sessionId) }
    }
    func setPreferredSource(sessionId: String, source: NativeSourceRef?, completion: @escaping (Result<Void, Error>) -> Void) {
        command(completion) { try $0.setPreferred(sessionId: sessionId, source: source) }
    }
    func snapshot(completion: @escaping (Result<NativeWorkoutSnapshot, Error>) -> Void) {
        command(completion) { $0.snapshot() }
    }
    func restore(sessionId: String, completion: @escaping (Result<NativeWorkoutSnapshot, Error>) -> Void) {
        command(completion) { try $0.restore(sessionId: sessionId) }
    }
    func activeSessionId(completion: @escaping (Result<String?, Error>) -> Void) {
        command(completion) { $0.activeSessionId() }
    }
    func clearSession(sessionId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        command(completion) { try $0.clearSession(sessionId: sessionId) }
    }

    /// A sample: queued behind the commands that came before it, never blocking the caller.
    func submitCounter(sessionId: String, source: NativeSourceRef, epoch: Int64, meters: Double, ageMs: Int64) throws {
        let receivedAt = engine?.receivedAt() // stamped HERE, on arrival: not when the queue gets to it
        calls.async { [weak self] in
            self?.engine?.submitCounter(sessionId: sessionId, source: source, epoch: epoch, meters: meters, ageMs: ageMs, receivedMonotonicMs: receivedAt)
        }
    }
    func submitSpeed(sessionId: String, source: NativeSourceRef, epoch: Int64, mps: Double, ageMs: Int64) throws {
        let receivedAt = engine?.receivedAt()
        calls.async { [weak self] in
            self?.engine?.submitSpeed(sessionId: sessionId, source: source, epoch: epoch, mps: mps, ageMs: ageMs, receivedMonotonicMs: receivedAt)
        }
    }

    // MARK: - WorkoutSink (called from the engine queue; Flutter wants the main thread)

    func onSnapshot(_ snapshot: NativeWorkoutSnapshot) {
        DispatchQueue.main.async { [weak self] in self?.flutterApi?.onSnapshot(snapshot: snapshot) { _ in } }
    }
}
