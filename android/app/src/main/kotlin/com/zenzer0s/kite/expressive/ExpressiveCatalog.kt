@file:OptIn(androidx.compose.material3.ExperimentalMaterial3ExpressiveApi::class)

package com.zenzer0s.kite.expressive

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Close
import androidx.compose.material.icons.rounded.Cloud
import androidx.compose.material.icons.rounded.ContentCopy
import androidx.compose.material.icons.rounded.Image
import androidx.compose.material.icons.rounded.OpenInBrowser
import androidx.compose.material.icons.rounded.OpenInNew
import androidx.compose.material.icons.rounded.PlayArrow
import androidx.compose.material.icons.rounded.Stop
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ButtonGroupDefaults
import androidx.compose.material3.ContainedLoadingIndicator
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearWavyProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp

data class QuickAction(val id: String, val label: String, val icon: ImageVector)

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
object ExpressiveCatalog {

    @Composable
    fun LoadingIndicator() {
        Column(
            modifier = Modifier.size(100.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            ContainedLoadingIndicator()
        }
    }

    @Composable
    fun QuickActions(hasThumbnail: Boolean, onAction: (String) -> Unit) {
        val actions = remember(hasThumbnail) {
            mutableListOf(
                QuickAction("copy", "Copy", Icons.Rounded.ContentCopy),
                QuickAction("open", "Open", Icons.Rounded.OpenInBrowser)
            ).apply {
                if (hasThumbnail) {
                    add(QuickAction("thumb", "Thumb", Icons.Rounded.Image))
                }
            }
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

    @Composable
    fun LinearWavyProgress(progress: Float?) {
        if (progress == null) {
            LinearWavyProgressIndicator()
        } else {
            LinearWavyProgressIndicator(progress = { progress })
        }
    }

    @Composable
    fun SquareButton(
        label: String?,
        iconName: String?,
        containerColor: Color? = null,
        contentColor: Color? = null,
        onClick: () -> Unit
    ) {
        val icon = when (iconName) {
            "play" -> androidx.compose.material.icons.Icons.Rounded.PlayArrow
            "stop" -> androidx.compose.material.icons.Icons.Rounded.Stop
            "x" -> androidx.compose.material.icons.Icons.Rounded.Close
            "open" -> androidx.compose.material.icons.Icons.Rounded.OpenInNew
            "cloud" -> androidx.compose.material.icons.Icons.Rounded.Cloud
            "video" -> androidx.compose.material.icons.Icons.Rounded.PlayArrow
            "music" -> androidx.compose.material.icons.Icons.Rounded.PlayArrow
            else -> null
        }

        val finalContainerColor = containerColor ?: MaterialTheme.colorScheme.primary
        val finalContentColor = contentColor ?: MaterialTheme.colorScheme.onPrimary

        Button(
            onClick = onClick,
            shape = RoundedCornerShape(10.dp),
            colors = ButtonDefaults.buttonColors(
                containerColor = finalContainerColor,
                contentColor = finalContentColor
            ),
            contentPadding = PaddingValues(horizontal = if (label == null) 6.dp else 10.dp, vertical = 2.dp)
        ) {
            if (icon != null) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    modifier = Modifier.size(14.dp)
                )
                if (label != null) Spacer(Modifier.width(4.dp))
            }
            if (label != null) {
                Text(
                    text = label,
                    style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold),
                    maxLines = 1
                )
            }
        }
    }
}
