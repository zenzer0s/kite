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
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import java.io.File

import android.os.Bundle
import androidx.lifecycle.setViewTreeLifecycleOwner
import androidx.lifecycle.setViewTreeViewModelStoreOwner
import androidx.savedstate.setViewTreeSavedStateRegistryOwner

import com.zenzer0s.kite.expressive.ExpressiveLoadingViewFactory
import com.zenzer0s.kite.expressive.ExpressiveQuickActionsViewFactory

open class MainActivity : FlutterFragmentActivity() {
    companion object {
        const val METHOD_CHANNEL = "com.zenzer0s.kite/downloader"
        const val EVENT_CHANNEL = "com.zenzer0s.kite/progress"
        const val SHARE_CHANNEL = "com.zenzer0s.kite/share"
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val PREF_VERSION_KEY = "yt_dlp_version"

        var globalProgressSink: EventChannel.EventSink? = null
        var shareSink: EventChannel.EventSink? = null
        var pendingSharedUrl: String? = null
        val sharedScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
        
        private var methodChannel: MethodChannel? = null

        fun setMethodChannel(channel: MethodChannel) {
            methodChannel = channel
        }

        fun notifyHistoryChanged() {
            sharedScope.launch {
                methodChannel?.invokeMethod("onHistoryChanged", null)
            }
        }
    }

    private val initMutex = Mutex()
    private var ytDlpReady = false
    private val ytDlpPrefs by lazy {
        applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Fix for ComposeView within Flutter "IllegalStateException: ViewTreeLifecycleOwner not found"
        window.decorView.setViewTreeLifecycleOwner(this)
        window.decorView.setViewTreeViewModelStoreOwner(this)
        window.decorView.setViewTreeSavedStateRegistryOwner(this)

        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
            if (checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) != android.content.pm.PackageManager.PERMISSION_GRANTED) {
                requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 101)
            }
        }
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

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
        methodChannel = channel
        channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "fetchInfo" -> {
                        val url = call.argument<String>("url") ?: return@setMethodCallHandler result.error("INVALID", "url required", null)
                        Log.d("KiteMain", "fetchInfo called url=$url")
                        sharedScope.launch {
                            try {
                                val info = KiteNative.fetchInfo(url)
                                result.success(info)
                            } catch (e: Exception) {
                                Log.e("KiteMain", "fetchInfo FAILED: ${e.message}")
                                result.error("FETCH_ERROR", e.message, null)
                            }
                        }
                    }

                    "normalizeUrl" -> {
                        val url = call.argument<String>("url") ?: return@setMethodCallHandler result.error("INVALID", "url required", null)
                        result.success(KiteNative.normalizeUrl(url))
                    }

                    "deleteHistoryItem" -> {
                        val id = call.argument<Int>("id") ?: return@setMethodCallHandler result.error("INVALID", "id required", null)
                        KiteNative.deleteHistoryItem(this, id)
                        result.success(true)
                    }

                    "testTelegramConnection" -> {
                        val token = call.argument<String>("token") ?: return@setMethodCallHandler result.error("INVALID", "token required", null)
                        val chatId = call.argument<String>("chatId") ?: return@setMethodCallHandler result.error("INVALID", "chatId required", null)
                        sharedScope.launch {
                            val res = KiteNative.testTelegramConnection(token, chatId)
                            if (res.isSuccess) {
                                result.success(mapOf("success" to true))
                            } else {
                                result.success(mapOf("success" to false, "error" to res.exceptionOrNull()?.message))
                            }
                        }
                    }

                    "startDownload" -> {
                        val url = call.argument<String>("url") ?: return@setMethodCallHandler result.error("INVALID", "url required", null)
                        val audioOnly = call.argument<Boolean>("audioOnly") ?: false
                        val formatId = call.argument<String>("formatId")
                        val outputDir = call.argument<String>("outputDir")
                            ?: File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS), "Kite").absolutePath

                        val taskId = "T-${System.currentTimeMillis()}-${(100..999).random()}"
                        DownloadService.startDownload(applicationContext, taskId, url, audioOnly, formatId, outputDir)
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
                                    DownloadService.pausedTaskIds.add(taskId)
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
                                    DownloadService.pausedTaskIds.remove(taskId)
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
                            if (DownloadService.pausedTaskIds.contains(taskId)) {
                                val process = getProcessFromMap(taskId)
                                if (process != null) {
                                    val pid = getProcessPid(process)
                                    if (pid != -1) Os.kill(pid, OsConstants.SIGCONT)
                                }
                                DownloadService.pausedTaskIds.remove(taskId)
                            }
                            DownloadService.canceledTaskIds.add(taskId)
                            DownloadService.activeJobs[taskId]?.cancel(CancellationException("task canceled"))
                            YoutubeDL.getInstance().destroyProcessById(taskId)
                            DownloadService.activeJobs.remove(taskId)
                            result.success(true)
                        } catch (e: Exception) {
                            DownloadService.canceledTaskIds.remove(taskId)
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
                    
                    "openFile" -> {
                        val path = call.argument<String>("path") ?: return@setMethodCallHandler result.error("INVALID", "path required", null)
                        val file = File(path)
                        if (!file.exists()) return@setMethodCallHandler result.error("NOT_FOUND", "file does not exist", null)
                        
                        try {
                            val uri = androidx.core.content.FileProvider.getUriForFile(applicationContext, "${packageName}.fileprovider", file)
                            val mime = KiteNative.getMimeType(path)
                            
                            val intent = Intent(Intent.ACTION_VIEW).apply {
                                setDataAndType(uri, mime)
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(Intent.createChooser(intent, "Open with..."))
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("OPEN_ERROR", e.message, null)
                        }
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

}
