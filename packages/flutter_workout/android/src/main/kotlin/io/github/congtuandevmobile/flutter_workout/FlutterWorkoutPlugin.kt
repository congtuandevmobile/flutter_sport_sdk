package io.github.congtuandevmobile.flutter_workout

import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import io.flutter.embedding.engine.plugins.FlutterPlugin
import java.io.File
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel

/**
 * Flutter entry point. Thin on purpose: it forwards to the [WorkoutEngine], turns a [WorkoutException] into a `FlutterError` with
 * its code, and delivers the engine's snapshots on the main thread. The workout (and its journal) belongs to the engine of this
 * plugin instance: a workout that must outlive the Flutter engine needs a process-wide owner, which is not built yet.
 */
class FlutterWorkoutPlugin : FlutterPlugin, WorkoutHostApi, WorkoutSink {
    private var engine: WorkoutEngine? = null
    private var scope: CoroutineScope? = null
    private var flutterApi: WorkoutFlutterApi? = null
    private val main = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val newScope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
        scope = newScope
        flutterApi = WorkoutFlutterApi(binding.binaryMessenger)
        val store = FileWorkoutJournalStore(File(binding.applicationContext.filesDir, "flutter_workout"))
        val newEngine = WorkoutEngine(store, newScope, { SystemClock.elapsedRealtime() }, this)
        engine = newEngine
        newEngine.start()
        WorkoutHostApi.setUp(binding.binaryMessenger, this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        WorkoutHostApi.setUp(binding.binaryMessenger, null)
        engine?.stop()
        engine = null
        scope?.cancel()
        scope = null
        flutterApi = null
    }

    private fun <T> run(block: (WorkoutEngine) -> T): T {
        val e = engine ?: throw FlutterError("DETACHED", "the plugin is detached", null)
        try {
            return block(e)
        } catch (ex: WorkoutException) {
            throw FlutterError(ex.code, ex.message, null)
        }
    }

    override fun start(sessionId: String, mode: NativeWorkoutMode) = run { it.start(sessionId, mode) }
    override fun pause(sessionId: String) = run { it.pause(sessionId) }
    override fun resume(sessionId: String) = run { it.resume(sessionId) }
    override fun finish(sessionId: String) = run { it.finish(sessionId) }
    override fun submitCounter(sessionId: String, source: NativeSourceRef, epoch: Long, meters: Double, ageMs: Long) =
        run { it.submitCounter(sessionId, source, epoch, meters, ageMs) }
    override fun submitSpeed(sessionId: String, source: NativeSourceRef, epoch: Long, mps: Double, ageMs: Long) =
        run { it.submitSpeed(sessionId, source, epoch, mps, ageMs) }
    override fun setPreferredSource(sessionId: String, source: NativeSourceRef?) = run { it.setPreferred(sessionId, source) }
    override fun snapshot() = run { it.snapshot() }
    override fun restore(sessionId: String) = run { it.restore(sessionId) }
    override fun activeSessionId() = run { it.activeSessionId() }
    override fun clearSession(sessionId: String) = run { it.clearSession(sessionId) }

    override fun onSnapshot(snapshot: NativeWorkoutSnapshot) {
        main.post { flutterApi?.onSnapshot(snapshot) {} }
    }
}
