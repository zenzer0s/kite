@file:OptIn(androidx.compose.material3.ExperimentalMaterial3ExpressiveApi::class)

package com.zenzer0s.kite.expressive

import android.content.Context
import android.content.ContextWrapper
import android.graphics.Color
import android.os.Build
import android.view.View
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.*
import androidx.compose.ui.platform.ComposeView
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.ViewModelStoreOwner
import androidx.lifecycle.setViewTreeLifecycleOwner
import androidx.lifecycle.setViewTreeViewModelStoreOwner
import androidx.savedstate.SavedStateRegistryOwner
import androidx.savedstate.setViewTreeSavedStateRegistryOwner
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView

internal class ExpressiveView(
    private val context: Context,
    private val id: Int,
    private val messenger: BinaryMessenger,
    private val creationParams: Map<String, Any?>?
) : PlatformView {
    private val type = creationParams?.get("type") as? String ?: "loading"
    private val channel = MethodChannel(messenger, "com.zenzer0s.kite/expressive_$id")
    
    private var currentParams = androidx.compose.runtime.mutableStateOf<Map<String, Any?>?>(creationParams)

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "updateProgress" -> {
                    val newParams = currentParams.value?.toMutableMap() ?: mutableMapOf()
                    newParams["progress"] = (call.arguments as? Number)?.toFloat()
                    currentParams.value = newParams
                    result.success(null)
                }
                "updateParams" -> {
                    val args = call.arguments as? Map<String, Any?>
                    val newParams = currentParams.value?.toMutableMap() ?: mutableMapOf()
                    args?.let { newParams.putAll(it) }
                    currentParams.value = newParams
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private val composeView: ComposeView = ComposeView(context).apply {
        setBackgroundColor(Color.TRANSPARENT)
        
        // Find the host lifecycle/viewmodel/savedstate providers
        var currentContext = context
        while (currentContext is ContextWrapper) {
            if (currentContext is LifecycleOwner) setViewTreeLifecycleOwner(currentContext)
            if (currentContext is ViewModelStoreOwner) setViewTreeViewModelStoreOwner(currentContext)
            if (currentContext is SavedStateRegistryOwner) setViewTreeSavedStateRegistryOwner(currentContext)
            if (currentContext is android.app.Activity) break
            currentContext = currentContext.baseContext
        }
        
        setContent {
            val isDark = isSystemInDarkTheme()
            val colorScheme = when {
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
                    if (isDark) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
                }
                isDark -> darkColorScheme()
                else -> lightColorScheme()
            }
            MaterialTheme(colorScheme = colorScheme) {
                val params = currentParams.value
                val progress = (params?.get("progress") as? Number)?.toFloat()
                val label = params?.get("label") as? String

                when (type) {
                    "loading" -> ExpressiveCatalog.LoadingIndicator()
                    "quick_actions" -> {
                        val hasThumbnail = params?.get("hasThumbnail") as? Boolean ?: false
                        ExpressiveCatalog.QuickActions(hasThumbnail) { action ->
                            channel.invokeMethod("onAction", action)
                        }
                    }
                    "wavy_progress" -> {
                        ExpressiveCatalog.LinearWavyProgress(progress)
                    }
                    "square_button" -> {
                        val iconName = params?.get("iconName") as? String
                        ExpressiveCatalog.SquareButton(label, iconName) {
                            android.util.Log.d("ExpressiveView", "Button clicked: $type $iconName")
                            channel.invokeMethod("onAction", "click")
                        }
                    }
                    "queue_task_card" -> {
                        ExpressiveCatalog.QueueTaskCard(
                            title = params?.get("title") as? String ?: "",
                            uploader = params?.get("uploader") as? String ?: "",
                            thumbnail = params?.get("thumbnail") as? String ?: "",
                            progress = progress,
                            speed = params?.get("speed") as? String ?: "",
                            status = params?.get("status") as? String ?: "",
                            targetExt = params?.get("targetExt") as? String ?: "",
                            quality = params?.get("quality") as? String,
                            isCleaned = params?.get("isCleaned") as? Boolean ?: false,
                            isDone = params?.get("isDone") as? Boolean ?: false,
                            isCancelled = params?.get("isCancelled") as? Boolean ?: false,
                            isError = params?.get("isError") as? Boolean ?: false,
                            isQueued = params?.get("isQueued") as? Boolean ?: false
                        ) { action ->
                            channel.invokeMethod("onAction", action)
                        }
                    }
                }
            }
        }
    }

    override fun getView(): View = composeView
    override fun dispose() {
        channel.setMethodCallHandler(null)
    }
}
