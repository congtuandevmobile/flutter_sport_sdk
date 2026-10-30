package io.github.congtuandevmobile.flutter_workout

import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import io.flutter.embedding.engine.plugins.FlutterPlugin
import java.io.File
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.asCoroutineDispatcher
import kotlinx.coroutines.cancel

/**
 * Flutter entry point. Thin on purpose: every command and every sample is run on ONE dedicated thread, in the order it arrived,
 * so the journal is written and synced there and the main thread never waits for the disk (and two commands can never swap). The
 * answer goes back on the main thread, after the write. A [WorkoutException] becomes a `FlutterError` with its code.
 *
 * The workout (and its journal) belongs to the engine of this plugin instance: a workout that must outlive the Flutter engine needs
 * a process-wide owner, which is not built yet.
 */
class FlutterWorkoutPlugin : FlutterPlugin, WorkoutHostApi, WorkoutSink {
    private var engine: WorkoutEngine? = null
    private var executor: ExecutorService? = null
    private var scope: CoroutineScope? = null
    private var flutterApi: WorkoutFlutterApi? = null
    private val main = Handler(Looper.getMainLooper())
    private var owner: JournalDirectoryOwner? = null

    /** True when another Flutter engine of the app already owns the journal directory: every command then fails, nothing is written. */
    private var notOwner = false

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val thread = Executors.newSingleThreadExecutor { Thread(it, "flutter_workout") }
        executor = thread
        val newScope = CoroutineScope(SupervisorJob() + thread.asCoroutineDispatcher())
        scope = newScope
        flutterApi = WorkoutFlutterApi(binding.binaryMessenger)
        val dir = File(binding.applicationContext.filesDir, "flutter_workout")
        val newOwner = JournalDirectoryOwner(dir)
        notOwner = !newOwner.tryAcquire()
        if (!notOwner) {
            owner = newOwner
            val newEngine = WorkoutEngine(FileWorkoutJournalStore(dir), newScope, { SystemClock.elapsedRealtime() }, this)
            engine = newEngine
            newEngine.start()
        }
        WorkoutHostApi.setUp(binding.binaryMessenger, this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        WorkoutHostApi.setUp(binding.binaryMessenger, null)
        engine?.stop()
        engine = null
        owner?.release()
        owner = null
        notOwner = false
        scope?.cancel()
        scope = null
        executor?.shutdown()
        executor = null
        flutterApi = null
    }

    /** Runs [block] on the engine thread; the callback gets the result on the main thread. */
    private fun <T> command(callback: (Result<T>) -> Unit, block: (WorkoutEngine) -> T) {
        val thread = executor
        if (thread == null) {
            callback(Result.failure(FlutterError("DETACHED", "the plugin is detached", null)))
            return
        }
        thread.execute {
            val result: Result<T> = try {
                val e = engine ?: throw (if (notOwner) WorkoutException("OWNED_BY_ANOTHER_ENGINE", "this plugin does not own the journal directory: another Flutter engine of the app already does (one engine at a time)")
                    else WorkoutException("DETACHED", "the plugin is detached"))
                Result.success(block(e))
            } catch (ex: WorkoutException) {
                Result.failure(FlutterError(ex.code, ex.message, null))
            } catch (t: Throwable) {
                Result.failure(FlutterError("WORKOUT_FAILED", t.message ?: t::class.java.simpleName, null))
            }
            main.post { callback(result) }
        }
    }

    override fun start(sessionId: String, mode: NativeWorkoutMode, callback: (Result<NativeWorkoutSnapshot>) -> Unit) =
        command(callback) { it.start(sessionId, mode) }
    override fun pause(sessionId: String, callback: (Result<NativeWorkoutSnapshot>) -> Unit) =
        command(callback) { it.pause(sessionId) }
    override fun resume(sessionId: String, callback: (Result<NativeWorkoutSnapshot>) -> Unit) =
        command(callback) { it.resume(sessionId) }
    override fun finish(sessionId: String, callback: (Result<NativeWorkoutSnapshot>) -> Unit) =
        command(callback) { it.finish(sessionId) }
    override fun setPreferredSource(sessionId: String, source: NativeSourceRef?, callback: (Result<Unit>) -> Unit) =
        command(callback) { it.setPreferred(sessionId, source) }
    override fun snapshot(callback: (Result<NativeWorkoutSnapshot>) -> Unit) = command(callback) { it.snapshot() }
    override fun restore(sessionId: String, callback: (Result<NativeWorkoutSnapshot>) -> Unit) =
        command(callback) { it.restore(sessionId) }
    override fun activeSessionId(callback: (Result<String?>) -> Unit) = command(callback) { it.activeSessionId() }
    override fun clearSession(sessionId: String, callback: (Result<Unit>) -> Unit) = command(callback) { it.clearSession(sessionId) }

    /** A sample: queued behind the commands that came before it, never blocking the caller. */
    override fun submitCounter(sessionId: String, source: NativeSourceRef, epoch: Long, meters: Double, ageMs: Long) {
        val receivedAt = engine?.receivedAt() // stamped HERE, on arrival: not when the queue gets to it
        executor?.execute { engine?.submitCounter(sessionId, source, epoch, meters, ageMs, receivedAt) }
    }

    override fun submitSpeed(sessionId: String, source: NativeSourceRef, epoch: Long, mps: Double, ageMs: Long) {
        val receivedAt = engine?.receivedAt()
        executor?.execute { engine?.submitSpeed(sessionId, source, epoch, mps, ageMs, receivedAt) }
    }

    override fun onSnapshot(snapshot: NativeWorkoutSnapshot) {
        main.post { flutterApi?.onSnapshot(snapshot) {} }
    }
}
