package com.zenzer0s.kite

import android.content.Context
import android.content.Intent
import android.os.Environment
import android.os.SystemClock
import android.system.Os
import android.system.OsConstants
import android.util.Log
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.android.RenderMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import com.yausername.youtubedl_android.YoutubeDL
import com.yausername.youtubedl_android.YoutubeDLRequest
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.cancel
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.io.File
import java.util.concurrent.CancellationException

import com.zenzer0s.kite.expressive.ExpressiveLoadingViewFactory
import com.zenzer0s.kite.expressive.ExpressiveQuickActionsViewFactory

open class MainActivity : FlutterFragmentActivity() {

    companion object {
        const val METHOD_CHANNEL = "com.zenzer0s.kite/downloader"
        const val EVENT_CHANNEL = "com.zenzer0s.kite/progress"
        const val SHARE_CHANNEL = "com.zenzer0s.kite/share"
        private const val PREFS_NAME = "kite_ytdlp"
        private const val PREF_VERSION_KEY = "yt_dlp_version"
        private const val DOWNLOAD_PROGRESS_INTERVAL_MS = 200L
        private const val CONCURRENT_FRAGMENTS = "8"

        val sharedScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
        val activeJobs = mutableMapOf<String, Job>()
        val canceledTaskIds = mutableSetOf<String>()
        val pausedTaskIds = mutableSetOf<String>()
        var globalProgressSink: EventChannel.EventSink? = null
    }

    private var shareSink: EventChannel.EventSink? = null
    private var pendingSharedUrl: String? = null
    private val initMutex = Mutex()
    private var ytDlpReady = false
    private val ytDlpPrefs by lazy {
        applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    override fun getRenderMode(): RenderMode {
        return RenderMode.texture
    }

    private fun getProcessPid(process: Process): Int {
        return try {
            val f = process.javaClass.getDeclaredField("pid")
            f.isAccessible = true
            f.getInt(process)
        } catch (_: Exception) {
            try {
                val m = process.javaClass.getDeclaredMethod("pid")
                m.isAccessible = true
                (m.invoke(process) as? Long)?.toInt() ?: -1
            } catch (e: Exception) {
                Log.w("KiteMain", "getProcessPid failed: ${e.message}")
                -1
            }
        }
    }

    private fun getProcessFromMap(taskId: String): Process? {
        return try {
            val field = YoutubeDL::class.java.getDeclaredField("idProcessMap")
            field.isAccessible = true
            @Suppress("UNCHECKED_CAST")
            val map = field.get(YoutubeDL) as? Map<String, Process>
            map?.get(taskId)
        } catch (e: Exception) {
            Log.w("KiteMain", "getProcessFromMap failed: ${e.message}")
            null
        }
    }

    private fun storeYtDlpVersion(version: String?) {
        if (!version.isNullOrBlank()) {
            ytDlpPrefs.edit().putString(PREF_VERSION_KEY, version).apply()
        }
    }

    private fun getStoredYtDlpVersion(): String? {
        return ytDlpPrefs.getString(PREF_VERSION_KEY, null)
    }

    private suspend fun ensureInit() {
        initMutex.withLock {
            if (ytDlpReady) return
            val startedAt = SystemClock.elapsedRealtime()
            Log.d("KiteMain", "ensureInit: awaiting native warmup...")
            KiteApp.awaitNativeToolsReady().getOrThrow()
            storeYtDlpVersion(YoutubeDL.getInstance().version(application.applicationContext))
            ytDlpReady = true
            Log.d("KiteMain", "ensureInit: done in ${SystemClock.elapsedRealtime() - startedAt}ms")
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.platformViewsController.registry.registerViewFactory("com.zenzer0s.kite/expressive_loading", ExpressiveLoadingViewFactory())
        flutterEngine.platformViewsController.registry.registerViewFactory("com.zenzer0s.kite/quick_actions", ExpressiveQuickActionsViewFactory(flutterEngine.dartExecutor.binaryMessenger))

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                    globalProgressSink = sink
                }
                override fun onCancel(arguments: Any?) {
                    globalProgressSink = null
                }
            })

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, SHARE_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                    shareSink = sink
                    pendingSharedUrl?.let { url ->
                        sink?.success(url)
                        pendingSharedUrl = null
                    }
                }
                override fun onCancel(arguments: Any?) {
                    shareSink = null
                }
            })

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "fetchInfo" -> {
                        val url = call.argument<String>("url") ?: return@setMethodCallHandler result.error("INVALID", "url required", null)
                        Log.d("KiteMain", "fetchInfo called url=$url")
                        sharedScope.launch {
                            try {
                                withContext(Dispatchers.IO) { ensureInit() }
                                Log.d("KiteMain", "fetchInfo: ready, fetching")
                                val startedAt = SystemClock.elapsedRealtime()
                                val info = withContext(Dispatchers.IO) {
                                    val requestStartedAt = SystemClock.elapsedRealtime()
                                    val req = YoutubeDLRequest(url).apply {
                                        addOption("--dump-single-json")
                                        addOption("--no-playlist")
                                        addOption("-R", "1")
                                        addOption("--socket-timeout", "5")
                                        addOption("--extractor-args", "youtube:player_skip=configs,js")
                                    }
                                    val requestBuiltAt = SystemClock.elapsedRealtime()
                                    Log.d("KiteMain", "fetchInfo: request built in ${requestBuiltAt - requestStartedAt}ms")
                                    val executeStartedAt = SystemClock.elapsedRealtime()
                                    val response = YoutubeDL.getInstance().execute(req)
                                    val executeFinishedAt = SystemClock.elapsedRealtime()
                                    Log.d("KiteMain", "fetchInfo: yt-dlp execute finished in ${executeFinishedAt - executeStartedAt}ms")
                                    val parsed = response.out.toVideoInfoMap()
                                    Log.d("KiteMain", "fetchInfo: formats=${(parsed["formats"] as? List<*>)?.size ?: 0} parse finished in ${SystemClock.elapsedRealtime() - executeFinishedAt}ms")
                                    parsed
                                }
                                Log.d("KiteMain", "fetchInfo: completed in ${SystemClock.elapsedRealtime() - startedAt}ms title=${info["title"]}")
                                result.success(info)
                            } catch (e: Exception) {
                                Log.e("KiteMain", "fetchInfo FAILED: ${e.javaClass.simpleName}: ${e.message}")
                                result.error("FETCH_ERROR", e.message, null)
                            }
                        }
                    }

                    "startDownload" -> {
                        val url = call.argument<String>("url") ?: return@setMethodCallHandler result.error("INVALID", "url required", null)
                        val audioOnly = call.argument<Boolean>("audioOnly") ?: false
                        val formatId = call.argument<String>("formatId")
                        val outputDir = call.argument<String>("outputDir")
                            ?: File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS), "Kite").absolutePath

                        File(outputDir).mkdirs()

                        val taskId = System.currentTimeMillis().toString()
                        Log.d("KiteMain", "startDownload taskId=$taskId audioOnly=$audioOnly formatId=$formatId url=$url")
                        val job = sharedScope.launch {
                            try {
                                withContext(Dispatchers.IO) { ensureInit() }
                                Log.d("KiteMain", "startDownload: ready, executing")
                                withContext(Dispatchers.IO) {
                                    val downloadStartedAt = SystemClock.elapsedRealtime()
                                    val requestStartedAt = SystemClock.elapsedRealtime()
                                    val req = YoutubeDLRequest(url).apply {
                                        addOption("-o", "$outputDir/%(title)s.%(ext)s")
                                        addOption("--downloader", "aria2c")
                                        addOption("--downloader-args", "aria2c:\"-x 16 -k 1M\"")
                                        addOption("--no-playlist")
                                        addOption("-R", "1")
                                        addOption("--socket-timeout", "5")
                                        addOption("--concurrent-fragments", CONCURRENT_FRAGMENTS)
                                        when {
                                            audioOnly -> {
                                                addOption("-x")
                                                addOption("--audio-format", "mp3")
                                            }
                                            formatId != null -> {
                                                addOption("-f", "$formatId+bestaudio[ext=m4a]/$formatId+bestaudio/bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best")
                                                addOption("--merge-output-format", "mp4")
                                            }
                                            else -> {
                                                addOption("-f", "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best")
                                                addOption("--merge-output-format", "mp4")
                                            }
                                        }
                                    }
                                    val requestBuiltAt = SystemClock.elapsedRealtime()
                                    Log.d("KiteMain", "startDownload: request built in ${requestBuiltAt - requestStartedAt}ms")
                                    var callbackCount = 0
                                    var emittedCount = 0
                                    var lastProgress = Double.NEGATIVE_INFINITY
                                    var lastLine = ""
                                    var lastEmitAt = 0L
                                    YoutubeDL.getInstance().execute(req, taskId) { progress, _, line ->
                                        callbackCount += 1
                                        val now = SystemClock.elapsedRealtime()
                                        val progressValue = progress.toDouble()
                                        val shouldEmit =
                                            emittedCount == 0 ||
                                                progressValue >= 100.0 ||
                                                progressValue - lastProgress >= 1.0 ||
                                                line != lastLine ||
                                                now - lastEmitAt >= DOWNLOAD_PROGRESS_INTERVAL_MS
                                        if (shouldEmit) {
                                            emittedCount += 1
                                            lastEmitAt = now
                                            lastProgress = progressValue
                                            lastLine = line
                                            sharedScope.launch {
                                                globalProgressSink?.success(mapOf(
                                                    "taskId" to taskId,
                                                    "progress" to progressValue,
                                                    "line" to line,
                                                ))
                                            }
                                        }
                                    }
                                    Log.d(
                                        "KiteMain",
                                        "startDownload: yt-dlp execute finished in ${SystemClock.elapsedRealtime() - requestBuiltAt}ms callbacks=$callbackCount emitted=$emittedCount total=${SystemClock.elapsedRealtime() - downloadStartedAt}ms"
                                    )
                                }
                                if (!canceledTaskIds.contains(taskId)) {
                                    globalProgressSink?.success(mapOf("taskId" to taskId, "progress" to 100.0, "done" to true))
                                }
                            } catch (e: CancellationException) {
                                Log.d("KiteMain", "startDownload: canceled taskId=$taskId")
                            } catch (e: Exception) {
                                if (canceledTaskIds.contains(taskId)) {
                                    Log.d("KiteMain", "startDownload: canceled during execute taskId=$taskId message=${e.message}")
                                } else {
                                    globalProgressSink?.success(mapOf("taskId" to taskId, "error" to (e.message ?: "Download failed")))
                                }
                            } finally {
                                activeJobs.remove(taskId)
                                canceledTaskIds.remove(taskId)
                            }
                        }
                        activeJobs[taskId] = job
                        result.success(taskId)
                    }

                    "pauseDownload" -> {
                        val taskId = call.argument<String>("taskId") ?: return@setMethodCallHandler result.error("INVALID", "taskId required", null)
                        try {
                            val process = getProcessFromMap(taskId)
                            if (process != null) {
                                val pid = getProcessPid(process)
                                if (pid != -1) {
                                    Os.kill(pid, OsConstants.SIGSTOP)
                                    pausedTaskIds.add(taskId)
                                    result.success(true)
                                } else {
                                    result.error("PAUSE_ERROR", "Could not get process PID", null)
                                }
                            } else {
                                result.error("PAUSE_ERROR", "Process not found for taskId=$taskId", null)
                            }
                        } catch (e: Exception) {
                            result.error("PAUSE_ERROR", e.message, null)
                        }
                    }

                    "resumeDownload" -> {
                        val taskId = call.argument<String>("taskId") ?: return@setMethodCallHandler result.error("INVALID", "taskId required", null)
                        try {
                            val process = getProcessFromMap(taskId)
                            if (process != null) {
                                val pid = getProcessPid(process)
                                if (pid != -1) {
                                    Os.kill(pid, OsConstants.SIGCONT)
                                    pausedTaskIds.remove(taskId)
                                    result.success(true)
                                } else {
                                    result.error("RESUME_ERROR", "Could not get process PID", null)
                                }
                            } else {
                                result.error("RESUME_ERROR", "Process not found for taskId=$taskId", null)
                            }
                        } catch (e: Exception) {
                            result.error("RESUME_ERROR", e.message, null)
                        }
                    }

                    "cancelDownload" -> {
                        val taskId = call.argument<String>("taskId") ?: return@setMethodCallHandler result.error("INVALID", "taskId required", null)
                        try {
                            if (pausedTaskIds.contains(taskId)) {
                                val process = getProcessFromMap(taskId)
                                if (process != null) {
                                    val pid = getProcessPid(process)
                                    if (pid != -1) Os.kill(pid, OsConstants.SIGCONT)
                                }
                                pausedTaskIds.remove(taskId)
                            }
                            canceledTaskIds.add(taskId)
                            activeJobs[taskId]?.cancel(CancellationException("task canceled"))
                            YoutubeDL.getInstance().destroyProcessById(taskId)
                            activeJobs.remove(taskId)
                            result.success(true)
                        } catch (e: Exception) {
                            canceledTaskIds.remove(taskId)
                            result.error("CANCEL_ERROR", e.message, null)
                        }
                    }

                    "updateYtDlp" -> {
                        sharedScope.launch {
                            try {
                                withContext(Dispatchers.IO) { ensureInit() }
                                val status = withContext(Dispatchers.IO) {
                                    YoutubeDL.getInstance().updateYoutubeDL(application, YoutubeDL.UpdateChannel.STABLE)
                                }
                                storeYtDlpVersion(
                                    withContext(Dispatchers.IO) {
                                        YoutubeDL.getInstance().version(application.applicationContext)
                                    }
                                )
                                result.success(status?.name ?: "ALREADY_UP_TO_DATE")
                            } catch (e: Exception) {
                                result.error("UPDATE_ERROR", e.message, null)
                            }
                        }
                    }

                    "getYtDlpVersion" -> {
                        sharedScope.launch {
                            try {
                                withContext(Dispatchers.IO) { ensureInit() }
                                val version = withContext(Dispatchers.IO) {
                                    YoutubeDL.getInstance().version(application.applicationContext)
                                        ?: getStoredYtDlpVersion()
                                }
                                result.success(version)
                            } catch (e: Exception) {
                                result.error("VERSION_ERROR", e.message, null)
                            }
                        }
                    }

                    "minimize" -> {
                        window.addFlags(
                            android.view.WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                            android.view.WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
                        )
                        moveTaskToBack(true)
                        result.success(true)
                    }

                    "makeUntouchable" -> {
                        window.addFlags(
                            android.view.WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                            android.view.WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
                        )
                        result.success(true)
                    }

                    "makeTouchable" -> {
                        window.clearFlags(
                            android.view.WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                            android.view.WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
                        )
                        result.success(true)
                    }

                    "isIgnoringBatteryOptimizations" -> {
                        val pm = getSystemService(android.content.Context.POWER_SERVICE) as android.os.PowerManager
                        result.success(pm.isIgnoringBatteryOptimizations(packageName))
                    }

                    "requestIgnoreBatteryOptimizations" -> {
                        val pm = getSystemService(android.content.Context.POWER_SERVICE) as android.os.PowerManager
                        if (!pm.isIgnoringBatteryOptimizations(packageName)) {
                            val intent = android.content.Intent(android.provider.Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                            intent.data = android.net.Uri.parse("package:$packageName")
                            startActivity(intent)
                        }
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        globalProgressSink = null
        shareSink = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onDestroy() {
        super.onDestroy()
        // Do not cancel sharedScope here anymore, downloads should continue!
    }

    private fun extractSharedUrl(intent: Intent?): String? {
        if (intent == null) return null
        return when (intent.action) {
            Intent.ACTION_SEND -> {
                if (intent.type == "text/plain") intent.getStringExtra(Intent.EXTRA_TEXT) else null
            }
            Intent.ACTION_VIEW -> intent.dataString
            else -> null
        }
    }

    override fun onNewIntent(intent: Intent) {
        window.clearFlags(
            android.view.WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
            android.view.WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
        )
        super.onNewIntent(intent)
        val url = extractSharedUrl(intent) ?: return
        if (shareSink != null) {
            shareSink?.success(url)
        } else {
            pendingSharedUrl = url
        }
    }

    override fun onResume() {
        window.clearFlags(
            android.view.WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
            android.view.WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
        )
        super.onResume()
        val url = extractSharedUrl(intent) ?: return
        intent.action = null
        if (shareSink != null) {
            shareSink?.success(url)
        } else {
            pendingSharedUrl = url
        }
    }

    private fun String.toVideoInfoMap(): Map<String, Any?> {
        val json = JSONObject(this)
        val formatsArray = json.optJSONArray("formats")
        val formats: List<Map<String, Any?>> = if (formatsArray != null) {
            (0 until formatsArray.length()).map { i ->
                val f = formatsArray.getJSONObject(i)
                mapOf(
                    "format_id" to f.optString("format_id"),
                    "format_note" to f.optString("format_note").takeIf { it.isNotEmpty() },
                    "ext" to f.optString("ext").takeIf { it.isNotEmpty() },
                    "vcodec" to f.optString("vcodec").takeIf { it.isNotEmpty() },
                    "acodec" to f.optString("acodec").takeIf { it.isNotEmpty() },
                    "width" to if (!f.isNull("width")) f.optDouble("width") else null,
                    "height" to if (!f.isNull("height")) f.optDouble("height") else null,
                    "resolution" to f.optString("resolution").takeIf { it.isNotEmpty() },
                    "vbr" to if (!f.isNull("vbr")) f.optDouble("vbr") else null,
                    "abr" to if (!f.isNull("abr")) f.optDouble("abr") else null,
                    "filesize" to if (!f.isNull("filesize")) f.optLong("filesize").toDouble() else null,
                    "filesize_approx" to if (!f.isNull("filesize_approx")) f.optLong("filesize_approx").toDouble() else null,
                )
            }
        } else emptyList()
        return mapOf(
            "id" to json.optString("id"),
            "title" to json.optString("title"),
            "uploader" to json.optString("uploader"),
            "thumbnail" to json.optString("thumbnail"),
            "duration" to if (json.has("duration") && !json.isNull("duration")) json.optInt("duration") else null,
            "webpage_url" to json.optString("webpage_url"),
            "ext" to json.optString("ext"),
            "formats" to formats,
        )
    }
}
