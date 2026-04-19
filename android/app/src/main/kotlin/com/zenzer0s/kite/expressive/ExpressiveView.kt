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
    
    private var currentProgress = androidx.compose.runtime.mutableStateOf<Float?>(
        (creationParams?.get("progress") as? Number)?.toFloat()
    )
    private var currentLabel = androidx.compose.runtime.mutableStateOf<String?>(
        creationParams?.get("label") as? String
    )

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "updateProgress" -> {
                    currentProgress.value = (call.arguments as? Number)?.toFloat()
                    result.success(null)
                }
                "updateParams" -> {
                    val args = call.arguments as? Map<String, Any?>
                    currentProgress.value = (args?.get("progress") as? Number)?.toFloat()
                    currentLabel.value = args?.get("label") as? String
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
                val progress = currentProgress.value
                val label = currentLabel.value

                when (type) {
                    "loading" -> ExpressiveCatalog.LoadingIndicator()
                    "quick_actions" -> {
                        val hasThumbnail = creationParams?.get("hasThumbnail") as? Boolean ?: false
                        ExpressiveCatalog.QuickActions(hasThumbnail) { action ->
                            channel.invokeMethod("onAction", action)
                        }
                    }
                    "wavy_progress" -> {
                        ExpressiveCatalog.LinearWavyProgress(progress)
                    }
                    "square_button" -> {
                        val iconName = creationParams?.get("iconName") as? String
                        ExpressiveCatalog.SquareButton(label, iconName) {
                            android.util.Log.d("ExpressiveView", "Button clicked: $type $iconName")
                            channel.invokeMethod("onAction", "click")
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
