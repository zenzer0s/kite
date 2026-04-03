package com.zenzer0s.kite.expressive

import android.os.Build
import android.content.Context
import android.content.ContextWrapper
import android.graphics.Color
import android.view.View
import androidx.compose.ui.platform.ComposeView
import io.flutter.plugin.platform.PlatformView
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.ViewModelStoreOwner
import androidx.lifecycle.setViewTreeLifecycleOwner
import androidx.lifecycle.setViewTreeViewModelStoreOwner
import androidx.savedstate.SavedStateRegistryOwner
import androidx.savedstate.setViewTreeSavedStateRegistryOwner
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.material3.samples.ContainedLoadingIndicatorSample

internal class ExpressiveLoadingView(context: Context, id: Int, creationParams: Map<String?, Any?>?) : PlatformView {
    private val composeView: ComposeView = ComposeView(context).apply {
        setBackgroundColor(Color.TRANSPARENT)
        
        var currentContext = context
        while (currentContext is ContextWrapper) {
            if (currentContext is LifecycleOwner) {
                setViewTreeLifecycleOwner(currentContext)
            }
            if (currentContext is ViewModelStoreOwner) {
                setViewTreeViewModelStoreOwner(currentContext)
            }
            if (currentContext is SavedStateRegistryOwner) {
                setViewTreeSavedStateRegistryOwner(currentContext)
            }
            if (currentContext is android.app.Activity) {
                break
            }
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
                ContainedLoadingIndicatorSample()
            }
        }
    }

    override fun getView(): View = composeView

    override fun dispose() {}
}