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
            val result = runCatching {
                YoutubeDL.init(this@KiteApp)
                FFmpeg.init(this@KiteApp)
                Aria2c.init(this@KiteApp)
            }
            result
                .onSuccess {
                    Log.d("KiteApp", "Native tools initialized in ${System.currentTimeMillis() - startedAt}ms")
                }
                .onFailure {
                    Log.e("KiteApp", "Native init failed: ${it.message}")
                }
            nativeInitResult.complete(result)
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
