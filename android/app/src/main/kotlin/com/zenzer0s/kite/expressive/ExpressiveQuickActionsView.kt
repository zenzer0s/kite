package com.zenzer0s.kite.expressive

import android.content.Context
import android.content.ContextWrapper
import android.graphics.Color
import android.os.Build
import android.view.View
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.ContentCopy
import androidx.compose.material.icons.rounded.Image
import androidx.compose.material.icons.rounded.OpenInBrowser
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.ui.platform.ComposeView
import androidx.compose.ui.unit.dp
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.ViewModelStoreOwner
import androidx.lifecycle.setViewTreeLifecycleOwner
import androidx.lifecycle.setViewTreeViewModelStoreOwner
import androidx.savedstate.SavedStateRegistryOwner
import androidx.savedstate.setViewTreeSavedStateRegistryOwner
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView

internal class ExpressiveQuickActionsView(
    context: Context,
    id: Int,
    messenger: BinaryMessenger,
    creationParams: Map<String, Any?>?
) : PlatformView {
    private val channel = MethodChannel(messenger, "com.zenzer0s.kite/quick_actions_$id")
    private val hasThumbnail = creationParams?.get("hasThumbnail") as? Boolean ?: false

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
                QuickActionsGroup(hasThumbnail, onAction = { action ->
                    channel.invokeMethod("onAction", action)
                })
            }
        }
    }

    override fun getView(): View = composeView
    override fun dispose() {}
}

data class QuickAction(val id: String, val label: String, val icon: ImageVector)

@OptIn(ExperimentalMaterial3Api::class, ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun QuickActionsGroup(hasThumbnail: Boolean, onAction: (String) -> Unit) {
    val actions = mutableListOf(
        QuickAction("copy", "Copy", Icons.Rounded.ContentCopy),
        QuickAction("open", "Open", Icons.Rounded.OpenInBrowser)
    )
    if (hasThumbnail) {
        actions.add(QuickAction("thumb", "Thumb", Icons.Rounded.Image))
    }

    Row(
        modifier = Modifier.fillMaxWidth().height(48.dp),
        horizontalArrangement = Arrangement.spacedBy(ButtonGroupDefaults.ConnectedSpaceBetween),
    ) {
        actions.forEachIndexed { index, action ->
            Button(
                onClick = { onAction(action.id) },
                modifier = Modifier.weight(1f),
                shape = when (index) {
                    0 -> ButtonGroupDefaults.connectedLeadingButtonShapes().shape
                    actions.lastIndex -> ButtonGroupDefaults.connectedTrailingButtonShapes().shape
                    else -> ButtonGroupDefaults.connectedMiddleButtonShapes().shape
                },
                colors = ButtonDefaults.buttonColors(
                    containerColor = MaterialTheme.colorScheme.primary,
                    contentColor = MaterialTheme.colorScheme.onPrimary
                ),
                contentPadding = PaddingValues(horizontal = 4.dp, vertical = 0.dp)
            ) {
                Icon(
                    imageVector = action.icon,
                    contentDescription = null,
                    modifier = Modifier.size(16.dp)
                )
                Spacer(modifier = Modifier.width(4.dp))
                Text(
                    text = action.label,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.SemiBold)
                )
            }
        }
    }
}
