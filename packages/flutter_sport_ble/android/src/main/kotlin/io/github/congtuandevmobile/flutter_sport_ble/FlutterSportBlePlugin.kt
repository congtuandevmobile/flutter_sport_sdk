package io.github.congtuandevmobile.flutter_sport_ble

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import io.flutter.embedding.engine.plugins.FlutterPlugin
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel

/**
 * Flutter entry point. Thin on purpose: it forwards to the [SportBleEngine] and turns the engine's events into Pigeon calls on
 * the main thread. Bluetooth permissions are the HOST app's to request (see the README); without them the adapter state says
 * `unauthorized` and nothing throws.
 */
class FlutterSportBlePlugin : FlutterPlugin, SportBleHostApi, SportBleSink {
    private var engine: SportBleEngine? = null
    private var scope: CoroutineScope? = null
    private var flutterApi: SportBleFlutterApi? = null
    private val main = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val context: Context = binding.applicationContext
        val newScope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
        scope = newScope
        flutterApi = SportBleFlutterApi(binding.binaryMessenger)
        val newEngine = SportBleEngine(
            transport = AndroidBleTransport(context),
            scope = newScope,
            monotonicMs = { SystemClock.elapsedRealtime() },
            sink = this,
        )
        engine = newEngine
        newEngine.start()
        SportBleHostApi.setUp(binding.binaryMessenger, this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        SportBleHostApi.setUp(binding.binaryMessenger, null)
        // The links belong to this engine instance: they end with it (a background-capable owner is a later phase).
        engine?.stop()
        engine = null
        scope?.cancel()
        scope = null
        flutterApi = null
    }

    // ── SportBleHostApi ─────────────────────────────────────────────────────

    override fun adapterState(): NativeAdapterState = engine?.adapterState() ?: NativeAdapterState.UNKNOWN
    override fun startScan(timeoutMs: Long) { engine?.startScan(timeoutMs) }
    override fun stopScan() { engine?.stopScan() }

    override fun connect(deviceId: String, callback: (Result<Unit>) -> Unit) {
        val e = engine
        if (e == null) {
            callback(Result.failure(FlutterError("DETACHED", "the plugin is detached", null)))
            return
        }
        e.connect(deviceId) { result ->
            main.post {
                callback(result.fold(
                    onSuccess = { Result.success(Unit) },
                    onFailure = { Result.failure(FlutterError(errorCode(it), it.message ?: "connect failed", null)) },
                ))
            }
        }
    }

    override fun disconnect(deviceId: String) { engine?.disconnect(deviceId) }
    override fun forget(deviceId: String) { engine?.forget(deviceId) }
    override fun setPreferredSource(metric: NativeMetric, deviceId: String?) { engine?.setPreferred(metric, deviceId) }
    override fun snapshot(): NativeSensorSnapshot = engine?.snapshot()
        ?: NativeSensorSnapshot(metrics = emptyList(), devices = emptyList(), updatedAtMs = 0)

    // ── SportBleSink (called from any thread; Flutter wants the main one) ───

    override fun onDeviceFound(device: NativeBleDevice) { main.post { flutterApi?.onDeviceFound(device) {} } }
    override fun onScanStopped() { main.post { flutterApi?.onScanStopped {} } }
    override fun onSnapshot(snapshot: NativeSensorSnapshot) { main.post { flutterApi?.onSnapshot(snapshot) {} } }
    override fun onRawPacket(packet: NativeRawPacket) { main.post { flutterApi?.onRawPacket(packet) {} } }

    private fun errorCode(error: Throwable): String {
        val text = error.message ?: return "CONNECT_FAILED"
        val colon = text.indexOf(':')
        return if (colon in 1..24 && text.substring(0, colon).all { it.isUpperCase() || it == '_' || it.isDigit() }) text.substring(0, colon) else "CONNECT_FAILED"
    }
}
