package com.zenzer0s.kite

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.util.Log
import com.yausername.aria2c.Aria2c
import com.yausername.ffmpeg.FFmpeg
import com.yausername.youtubedl_android.YoutubeDL
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

class KiteApp : Application() {

    companion object {
        lateinit var instance: KiteApp
            private set
        const val DOWNLOAD_CHANNEL_ID = "kite_download"
        private val nativeInitResult = CompletableDeferred<Result<Unit>>()

        suspend fun awaitNativeToolsReady(): Result<Unit> {
            instance.startNativeWarmup()
            return nativeInitResult.await()
        }
    }

    private val appScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    @Volatile
    private var nativeWarmupStarted = false

    private fun startNativeWarmup() {
        if (nativeWarmupStarted) {
            return
        }
        synchronized(this) {
            if (nativeWarmupStarted) {
                return
            }
            nativeWarmupStarted = true
        }
        val startedAt = System.currentTimeMillis()
        appScope.launch(Dispatchers.IO) {
            val resYoutube = launch {
                val s = System.currentTimeMillis()
                runCatching { YoutubeDL.init(this@KiteApp) }
                Log.d("KiteApp", "YoutubeDL init took ${System.currentTimeMillis() - s}ms")
            }
            val resFFmpeg = launch {
                val s = System.currentTimeMillis()
                runCatching { FFmpeg.init(this@KiteApp) }
                Log.d("KiteApp", "FFmpeg init took ${System.currentTimeMillis() - s}ms")
            }
            val resAria2c = launch {
                val s = System.currentTimeMillis()
                runCatching { Aria2c.init(this@KiteApp) }
                Log.d("KiteApp", "Aria2c init took ${System.currentTimeMillis() - s}ms")
            }

            // Wait for all to finish for the overall global readiness state
            resYoutube.join()
            resFFmpeg.join()
            resAria2c.join()
            
            Log.d("KiteApp", "TOTAL Native tools ready in ${System.currentTimeMillis() - startedAt}ms")
            nativeInitResult.complete(Result.success(Unit))

            // Now pre-warm the Python interpreter in the background
            launch { KiteNative.warmup() }
        }
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        Log.d("KiteApp", "Application created")
        startNativeWarmup()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                DOWNLOAD_CHANNEL_ID,
                "Downloads",
                NotificationManager.IMPORTANCE_LOW,
            ).apply { description = "Kite download progress" }
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
    }
}
