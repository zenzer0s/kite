package com.zenzer0s.kite

import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Environment
import android.os.IBinder
import android.os.SystemClock
import android.util.Log
import androidx.core.app.NotificationCompat
import com.yausername.youtubedl_android.YoutubeDL
import com.yausername.youtubedl_android.YoutubeDLRequest
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import org.json.JSONObject
import java.io.File
import java.util.concurrent.CancellationException

class DownloadService : Service() {

    companion object {
        private const val CONCURRENT_FRAGMENTS = "8"
        private const val FOREGROUND_ID = 1001
        var isForegroundStarted = false
        
        val activeJobs = java.util.concurrent.ConcurrentHashMap<String, Job>()
        val canceledTaskIds = java.util.Collections.synchronizedSet(mutableSetOf<String>())
        val pausedTaskIds = java.util.Collections.synchronizedSet(mutableSetOf<String>())
        val serviceScope = CoroutineScope(Dispatchers.IO + SupervisorJob())
        
        fun startDownload(context: Context, taskId: String, url: String, audioOnly: Boolean, formatId: String?, outputDir: String) {
            val intent = Intent(context, DownloadService::class.java).apply {
                putExtra("taskId", taskId)
                putExtra("url", url)
                putExtra("audioOnly", audioOnly)
                putExtra("formatId", formatId)
                putExtra("outputDir", outputDir)
            }
            context.startForegroundService(intent)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val taskId = intent?.getStringExtra("taskId") ?: return START_NOT_STICKY
        val url = intent.getStringExtra("url") ?: return START_NOT_STICKY
        val audioOnly = intent.getBooleanExtra("audioOnly", false)
        val formatId = intent.getStringExtra("formatId")
        var outputDir = intent.getStringExtra("outputDir")
        if (outputDir.isNullOrBlank()) {
            outputDir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS), "Kite").absolutePath
        }

        File(outputDir).mkdirs()

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        // Ensure service anchor is started once
        if (!isForegroundStarted) {
            val anchor = NotificationCompat.Builder(this, KiteApp.DOWNLOAD_CHANNEL_ID)
                .setContentTitle("Kite Manager")
                .setContentText("Active background tasks")
                .setSmallIcon(R.drawable.ic_download)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .build()
            startForeground(FOREGROUND_ID, anchor)
            isForegroundStarted = true
        }

        val notificationId = (taskId.hashCode() and 0x7FFFFFFF)
        val builder = NotificationCompat.Builder(this, KiteApp.DOWNLOAD_CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_download)
            .setContentTitle("Initializing...")
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .setOnlyAlertOnce(true)

        notificationManager.notify(notificationId, builder.build())

        val job = serviceScope.launch {
            try {
                KiteApp.awaitNativeToolsReady().getOrThrow()

                val infoMap = KiteNative.fetchInfo(url, this@DownloadService)
                val title = infoMap["title"] as? String ?: "Unknown Video"
                val uploader = infoMap["uploader"] as? String ?: "Unknown"
                val duration = infoMap["duration"] as? Int ?: 0
                val parsedExt = infoMap["ext"] as? String ?: "mp4"
                val thumbnail = infoMap["thumbnail"] as? String ?: ""

                val ext = if (audioOnly) "mp3" else parsedExt
                
                // Fast Mode Detection
                val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val fastMode = prefs.getBoolean("flutter.fast_mode", false)
                val targetDir = if (fastMode) cacheDir.absolutePath else outputDir!!
                
                builder.setContentTitle("Downloading: $title")
                notificationManager.notify(notificationId, builder.build())

                val req = YoutubeDLRequest(url).apply {
                    addOption("-o", "$targetDir/%(title)s.%(ext)s")
                    addOption("--downloader", "aria2c")
                    addOption("--downloader-args", "aria2c:\"-x 16 -k 1M\"")
                    addOption("--no-playlist")
                    addOption("-R", "1")
                    addOption("--socket-timeout", "5")
                    addOption("--concurrent-fragments", CONCURRENT_FRAGMENTS)
                    
                    // Add Cookies for Private Downloads
                    val cookieFile = KiteNative.writeCookiesFile(this@DownloadService)
                    if (cookieFile != null && cookieFile.exists()) {
                        addOption("--cookies", cookieFile.absolutePath)
                    }
                    
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

                var lastEmitAt = 0L
                YoutubeDL.getInstance().execute(req, taskId) { progress, _, line ->
                    val now = SystemClock.elapsedRealtime()
                    if (now - lastEmitAt >= 200L) {
                        lastEmitAt = now
                        builder.setContentTitle(title)
                        builder.setProgress(100, progress.toInt(), false)
                        builder.setContentText("${progress.toInt()}% • Downloading")
                        builder.setSmallIcon(R.drawable.ic_download)
                        notificationManager.notify(notificationId, builder.build())
                        
                        if (MainActivity.globalProgressSink != null) {
                            MainActivity.sharedScope.launch {
                                MainActivity.globalProgressSink?.success(mapOf(
                                    "taskId" to taskId,
                                    "progress" to progress.toDouble(),
                                    "line" to line,
                                    "title" to title,
                                    "uploader" to uploader,
                                    "thumbnail" to thumbnail,
                                    "url" to url,
                                    "duration" to duration,
                                    "ext" to ext
                                ))
                            }
                        }
                    }
                }

                if (!canceledTaskIds.contains(taskId)) {
                    builder.setContentTitle("Download Complete")
                        .setContentText(title)
                        .setProgress(0, 0, false)
                        .setOngoing(false)
                    notificationManager.notify(notificationId, builder.build())

                    val filePath = KiteNative.getSafeFilePath(targetDir, title, ext)
                    
                    // Always save natively to history.
                    val meta = KiteNative.DownloadMetadata(title, uploader, url, thumbnail, filePath, ext, duration)
                    KiteNative.saveToHistory(this@DownloadService, meta)
                    
                    // UI Sync
                    MainActivity.notifyHistoryChanged()
                    
                    // Switch to Upload Icon
                    builder.setContentText("Uploading to Telegram...")
                    builder.setProgress(0, 0, true)
                    builder.setSmallIcon(R.drawable.ic_upload)
                    notificationManager.notify(notificationId, builder.build())

                    // Trigger Telegram upload natively
                    val uploaded = KiteNative.uploadToTelegram(this@DownloadService, filePath, ext)
                    
                    // Fast Mode: Delete the temporary file ONLY if upload succeeded
                    if (fastMode && uploaded) {
                        try {
                            val f = File(filePath)
                            if (f.exists()) {
                                f.delete()
                                Log.d("KiteService", "Fast Mode: Cleaned up temp file $filePath")
                            }
                        } catch (e: Exception) {
                            Log.e("KiteService", "Fast Mode: Cleanup failed", e)
                        }
                    }
                    
                    // Final Clean Notification
                    notificationManager.cancel(notificationId)
                }
            } catch (e: CancellationException) {
                notificationManager.cancel(notificationId)
            } catch (e: Exception) {
                if (canceledTaskIds.contains(taskId)) {
                    notificationManager.cancel(notificationId)
                } else {
                    builder.setContentTitle("Download Failed")
                        .setContentText(e.message ?: "Unknown error")
                        .setProgress(0, 0, false)
                        .setOngoing(false)
                    notificationManager.notify(notificationId, builder.build())
                    
                    MainActivity.sharedScope.launch {
                        MainActivity.globalProgressSink?.success(mapOf("taskId" to taskId, "error" to (e.message ?: "Failed")))
                    }
                }
            } finally {
                activeJobs.remove(taskId)
                canceledTaskIds.remove(taskId)
                if (activeJobs.isEmpty()) {
                    stopForeground(STOP_FOREGROUND_REMOVE)
                    isForegroundStarted = false
                    stopSelf()
                }
            }
        }
        activeJobs[taskId] = job
        return START_NOT_STICKY
    }
}
