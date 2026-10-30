package io.github.congtuandevmobile.flutter_challenge

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
 * Flutter entry point. Thin on purpose: every command and every sample is run on ONE dedicated thread, in the order it arrived, so the
 * journal is written and synced there and the main thread never waits for the disk (and two commands can never swap). The answer goes
 * back on the main thread, after the write. A [ChallengeException] becomes a `FlutterError` with its code.
 *
 * The challenge (and its journal) belongs to the runner of this plugin instance: a challenge that must outlive the Flutter engine
 * needs a process-wide owner, which is not built yet.
 */
class FlutterChallengePlugin : FlutterPlugin, ChallengeHostApi, ChallengeSink {
    private var runner: ChallengeRunner? = null
    private var executor: ExecutorService? = null
    private var scope: CoroutineScope? = null
    private var flutterApi: ChallengeFlutterApi? = null
    private val main = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val thread = Executors.newSingleThreadExecutor { Thread(it, "flutter_challenge") }
        executor = thread
        val newScope = CoroutineScope(SupervisorJob() + thread.asCoroutineDispatcher())
        scope = newScope
        flutterApi = ChallengeFlutterApi(binding.binaryMessenger)
        val store = FileChallengeJournalStore(File(binding.applicationContext.filesDir, "flutter_challenge"))
        val newRunner = ChallengeRunner(store, newScope, { SystemClock.elapsedRealtime() }, this)
        runner = newRunner
        newRunner.start()
        ChallengeHostApi.setUp(binding.binaryMessenger, this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        ChallengeHostApi.setUp(binding.binaryMessenger, null)
        runner?.stop()
        runner = null
        scope?.cancel()
        scope = null
        executor?.shutdown()
        executor = null
        flutterApi = null
    }

    /** Runs [block] on the runner thread; the callback gets the result on the main thread. */
    private fun <T> command(callback: (Result<T>) -> Unit, block: (ChallengeRunner) -> T) {
        val thread = executor
        if (thread == null) {
            callback(Result.failure(FlutterError("DETACHED", "the plugin is detached", null)))
            return
        }
        thread.execute {
            val result: Result<T> = try {
                val r = runner ?: throw ChallengeException("DETACHED", "the plugin is detached")
                Result.success(block(r))
            } catch (ex: ChallengeException) {
                Result.failure(FlutterError(ex.code, ex.message, null))
            } catch (t: Throwable) {
                Result.failure(FlutterError("CHALLENGE_FAILED", t.message ?: t::class.java.simpleName, null))
            }
            main.post { callback(result) }
        }
    }

    override fun start(sessionId: String, definition: NativeChallengeDefinition, callback: (Result<NativeChallengeSnapshot>) -> Unit) =
        command(callback) { it.start(sessionId, definition) }
    override fun confirm(
        sessionId: String, evidence: NativeCompletionEvidence, expectedStageActivation: Long?, callback: (Result<NativeChallengeSnapshot>) -> Unit,
    ) = command(callback) { it.confirm(sessionId, evidence, expectedStageActivation) }
    override fun nextStage(sessionId: String, callback: (Result<NativeChallengeSnapshot>) -> Unit) =
        command(callback) { it.nextStage(sessionId) }
    override fun pause(sessionId: String, callback: (Result<NativeChallengeSnapshot>) -> Unit) =
        command(callback) { it.pause(sessionId) }
    override fun resume(sessionId: String, callback: (Result<NativeChallengeSnapshot>) -> Unit) =
        command(callback) { it.resume(sessionId) }
    override fun snapshot(callback: (Result<NativeChallengeSnapshot>) -> Unit) = command(callback) { it.snapshot() }
    override fun restore(sessionId: String, callback: (Result<NativeChallengeSnapshot>) -> Unit) =
        command(callback) { it.restore(sessionId) }
    override fun activeSessionId(callback: (Result<String?>) -> Unit) = command(callback) { it.activeSessionId() }
    override fun clearSession(sessionId: String, callback: (Result<Unit>) -> Unit) = command(callback) { it.clearSession(sessionId) }

    /** A sample: queued behind the commands that came before it, never blocking the caller. */
    override fun submitCounter(sessionId: String, sourceId: String, epoch: Long, meters: Double, ageMs: Long) {
        val receivedAt = runner?.receivedAt() // stamped HERE, on arrival: not when the queue gets to it
        executor?.execute { runner?.submitCounter(sessionId, sourceId, epoch, meters, ageMs, receivedAt) }
    }

    override fun submitDelta(sessionId: String, sourceId: String, eventId: String, delta: Double, ageMs: Long, stageActivation: Long?) {
        val receivedAt = runner?.receivedAt()
        executor?.execute { runner?.submitDelta(sessionId, sourceId, eventId, delta, ageMs, stageActivation, receivedAt) }
    }

    override fun onSnapshot(snapshot: NativeChallengeSnapshot) {
        main.post { flutterApi?.onSnapshot(snapshot) {} }
    }
}
