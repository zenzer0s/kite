package com.zenzer0s.kite

import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.database.sqlite.SQLiteDatabase
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
        val activeJobs = mutableMapOf<String, Job>()
        val canceledTaskIds = mutableSetOf<String>()
        val pausedTaskIds = mutableSetOf<String>()
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

        val notificationId = taskId.hashCode()
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val builder = NotificationCompat.Builder(this, KiteApp.DOWNLOAD_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.stat_sys_download)
            .setContentTitle("Initializing Download...")
            .setContentText(url)
            .setOngoing(true)
            .setOnlyAlertOnce(true)

        startForeground(notificationId, builder.build())

        val job = serviceScope.launch {
            try {
                KiteApp.awaitNativeToolsReady().getOrThrow()

                val infoReq = YoutubeDLRequest(url).apply {
                    addOption("--dump-single-json")
                    addOption("--no-playlist")
                    addOption("-R", "1")
                    addOption("--socket-timeout", "5")
                }
                
                val response = YoutubeDL.getInstance().execute(infoReq)
                val infoText = response.out
                var title = "Unknown Video"
                var uploader = "Unknown"
                var duration = 0
                var parsedExt = "mp4"
                var thumbnail = ""
                
                try {
                    val jsonObj = JSONObject(infoText)
                    title = jsonObj.optString("title", title)
                    uploader = jsonObj.optString("uploader", uploader)
                    duration = jsonObj.optInt("duration", 0)
                    parsedExt = jsonObj.optString("ext", parsedExt)
                    thumbnail = jsonObj.optString("thumbnail", "")
                } catch (e: Exception) {}

                val ext = if (audioOnly) "mp3" else parsedExt
                
                builder.setContentTitle("Downloading: $title")
                notificationManager.notify(notificationId, builder.build())

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

                var lastEmitAt = 0L
                YoutubeDL.getInstance().execute(req, taskId) { progress, _, line ->
                    val now = SystemClock.elapsedRealtime()
                    if (now - lastEmitAt >= 200L) {
                        lastEmitAt = now
                        builder.setProgress(100, progress.toInt(), false)
                        builder.setContentText(line)
                        notificationManager.notify(notificationId, builder.build())
                        
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

                if (!canceledTaskIds.contains(taskId)) {
                    builder.setContentTitle("Download Complete")
                        .setContentText(title)
                        .setProgress(0, 0, false)
                        .setOngoing(false)
                    notificationManager.notify(notificationId, builder.build())

                    val safeTitle = title.replace(Regex("[\\\\/:*?\"<>|]"), "_")
                    val filePath = "$outputDir/$safeTitle.$ext"
                    
                    // Always save natively to history.
                    insertToDatabase(title, uploader, url, thumbnail, filePath, ext, duration)
                    
                    if (MainActivity.globalProgressSink != null) {
                        MainActivity.sharedScope.launch {
                            MainActivity.globalProgressSink?.success(mapOf("taskId" to taskId, "progress" to 100.0, "done" to true))
                        }
                    }
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
                if (activeJobs.isEmpty()) stopSelf()
            }
        }
        activeJobs[taskId] = job
        return START_NOT_STICKY
    }

    private fun insertToDatabase(title: String, uploader: String, url: String, thumbnail: String, filePath: String, ext: String, duration: Int) {
        try {
            val dbFile = File(this.filesDir, "../app_flutter/kite.sqlite").canonicalFile
            if (!dbFile.exists()) return
            val db = SQLiteDatabase.openDatabase(dbFile.absolutePath, null, SQLiteDatabase.OPEN_READWRITE)
            val cv = android.content.ContentValues().apply {
                put("title", title)
                put("uploader", uploader)
                put("url", url)
                put("thumbnail", thumbnail)
                put("file_path", filePath)
                put("ext", ext)
                put("duration", duration)
                put("downloaded_at", System.currentTimeMillis() / 1000L)
            }
            db.insert("downloaded_items", null, cv)
            db.close()
        } catch (e: Exception) {
            Log.e("KiteDB", "Failed to natively save history", e)
        }
    }
}