import Flutter
import Foundation

/// Flutter entry point. Thin on purpose: it forwards to the `WorkoutEngine`, turns a `WorkoutError` into a `PigeonError` with its
/// code, and delivers the engine's snapshots on the main thread. The workout (and its journal) belongs to the engine of this plugin
/// instance: a workout that must outlive the Flutter engine needs a process-wide owner, which is not built yet.
public final class FlutterWorkoutPlugin: NSObject, FlutterPlugin, WorkoutHostApi, WorkoutSink {
    private var engine: WorkoutEngine?
    private var flutterApi: WorkoutFlutterApi?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = FlutterWorkoutPlugin()
        instance.flutterApi = WorkoutFlutterApi(binaryMessenger: registrar.messenger())
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("flutter_workout", isDirectory: true)
        let engine = WorkoutEngine(store: FileWorkoutJournalStore(dir: support), sink: instance)
        instance.engine = engine
        engine.startTicker()
        WorkoutHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
        registrar.publish(instance)
    }

    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        WorkoutHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: nil)
        engine?.stopTicker()
        engine = nil
        flutterApi = nil
    }

    private func use<T>(_ block: (WorkoutEngine) throws -> T) throws -> T {
        guard let engine = engine else { throw PigeonError(code: "DETACHED", message: "the plugin is detached", details: nil) }
        do { return try block(engine) } catch let e as WorkoutError {
            throw PigeonError(code: e.code, message: e.message, details: nil)
        }
    }

    // MARK: - WorkoutHostApi

    func start(sessionId: String, mode: NativeWorkoutMode) throws -> NativeWorkoutSnapshot { try use { try $0.start(sessionId: sessionId, mode: mode) } }
    func pause(sessionId: String) throws -> NativeWorkoutSnapshot { try use { try $0.pause(sessionId: sessionId) } }
    func resume(sessionId: String) throws -> NativeWorkoutSnapshot { try use { try $0.resume(sessionId: sessionId) } }
    func finish(sessionId: String) throws -> NativeWorkoutSnapshot { try use { try $0.finish(sessionId: sessionId) } }
    func submitCounter(sessionId: String, source: NativeSourceRef, epoch: Int64, meters: Double, ageMs: Int64) throws {
        try use { $0.submitCounter(sessionId: sessionId, source: source, epoch: epoch, meters: meters, ageMs: ageMs) }
    }
    func submitSpeed(sessionId: String, source: NativeSourceRef, epoch: Int64, mps: Double, ageMs: Int64) throws {
        try use { $0.submitSpeed(sessionId: sessionId, source: source, epoch: epoch, mps: mps, ageMs: ageMs) }
    }
    func setPreferredSource(sessionId: String, source: NativeSourceRef?) throws {
        try use { try $0.setPreferred(sessionId: sessionId, source: source) }
    }
    func snapshot() throws -> NativeWorkoutSnapshot { try use { $0.snapshot() } }
    func restore(sessionId: String) throws -> NativeWorkoutSnapshot { try use { try $0.restore(sessionId: sessionId) } }
    func activeSessionId() throws -> String? { try use { $0.activeSessionId() } }
    func clearSession(sessionId: String) throws { try use { try $0.clearSession(sessionId: sessionId) } }

    // MARK: - WorkoutSink (called from the engine queue; Flutter wants the main thread)

    func onSnapshot(_ snapshot: NativeWorkoutSnapshot) {
        DispatchQueue.main.async { [weak self] in self?.flutterApi?.onSnapshot(snapshot: snapshot) { _ in } }
    }
}
