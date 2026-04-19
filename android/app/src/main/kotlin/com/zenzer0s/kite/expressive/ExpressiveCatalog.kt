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
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.sp
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

    @Composable
    fun QueueTaskCard(
        title: String,
        uploader: String,
        thumbnail: String,
        progress: Float?,
        speed: String,
        status: String,
        targetExt: String,
        quality: String?,
        isCleaned: Boolean,
        isDone: Boolean,
        isCancelled: Boolean,
        isError: Boolean,
        isQueued: Boolean,
        onAction: (String) -> Unit
    ) {
        androidx.compose.foundation.layout.Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(180.dp)
                .clip(RoundedCornerShape(28.dp))
                .background(MaterialTheme.colorScheme.surfaceContainerHigh)
        ) {
            if (thumbnail.isNotEmpty()) {
                coil.compose.AsyncImage(
                    model = thumbnail,
                    contentDescription = null,
                    contentScale = androidx.compose.ui.layout.ContentScale.Crop,
                    modifier = Modifier.fillMaxSize()
                )
            } else {
                androidx.compose.foundation.layout.Box(
                    modifier = Modifier.fillMaxSize().background(MaterialTheme.colorScheme.surfaceContainerHighest),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = androidx.compose.material.icons.Icons.Rounded.Image,
                        contentDescription = null,
                        modifier = Modifier.size(48.dp),
                        tint = MaterialTheme.colorScheme.outline.copy(alpha = 0.3f)
                    )
                }
            }

            androidx.compose.foundation.layout.Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(
                        androidx.compose.ui.graphics.Brush.linearGradient(
                            colors = listOf(
                                Color.Black.copy(alpha = 0.4f),
                                Color.Black.copy(alpha = 0.85f)
                            )
                        )
                    )
            )

            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(20.dp)
            ) {
                // Header
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Icon(
                        imageVector = if (targetExt == "mp3") androidx.compose.material.icons.Icons.Rounded.PlayArrow else androidx.compose.material.icons.Icons.Rounded.PlayArrow,
                        contentDescription = null,
                        modifier = Modifier.size(24.dp),
                        tint = MaterialTheme.colorScheme.primary
                    )
                    
                    val qualityLabel = if (status == "error") "Failed" else quality ?: if (targetExt == "mp3") "Best Audio" else "Best Video"
                    InfoChip(
                        iconName = if (targetExt == "mp3") "music" else "video",
                        label = qualityLabel
                    )
                }

                Spacer(modifier = Modifier.weight(1f))

                // Main Controls
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = title,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis,
                            color = Color.White,
                            style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold, fontSize = 18.sp, lineHeight = 20.sp)
                        )
                        Text(
                            text = uploader,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis,
                            color = Color.White.copy(alpha = 0.6f),
                            style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.Medium, fontSize = 13.sp)
                        )
                    }
                    Spacer(modifier = Modifier.width(12.dp))
                    
                    val mainIcon = when {
                        isDone && isCleaned -> "cloud"
                        isDone -> "play"
                        isCancelled || isError || isQueued -> "x"
                        else -> "stop"
                    }
                    val mainAction = when {
                        isDone && isCleaned -> "show_telegram"
                        isDone -> "open_file"
                        isCancelled || isError || isQueued -> "dismiss"
                        else -> "cancel"
                    }
                    
                    ActionButton(iconName = mainIcon) {
                        onAction(mainAction)
                    }
                }

                if (!isDone && !isCancelled && !isError) {
                    Spacer(modifier = Modifier.weight(1f))

                    // Footer
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        val progressInt = ((progress ?: 0f) * 100).toInt()
                        Text(
                            text = "$progressInt%",
                            color = Color.White,
                            style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.Bold, fontSize = 12.sp)
                        )
                        Spacer(modifier = Modifier.width(12.dp))
                        androidx.compose.foundation.layout.Box(modifier = Modifier.weight(1f).height(16.dp)) {
                            LinearWavyProgress(progress)
                        }
                        Spacer(modifier = Modifier.width(12.dp))
                        Text(
                            text = speed,
                            color = Color.White,
                            style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.Bold, fontSize = 12.sp)
                        )
                    }
                } else {
                    Spacer(modifier = Modifier.weight(1f))
                }
            }
        }
    }

    @Composable
    fun InfoChip(iconName: String, label: String? = null) {
        val icon = when (iconName) {
            "music" -> androidx.compose.material.icons.Icons.Rounded.PlayArrow
            "video" -> androidx.compose.material.icons.Icons.Rounded.PlayArrow
            else -> null
        }
        val modifier = if (label == null) {
            Modifier.size(32.dp)
        } else {
            Modifier.height(28.dp).padding(horizontal = 10.dp)
        }

        androidx.compose.foundation.layout.Box(
            modifier = Modifier
                .background(MaterialTheme.colorScheme.primary, RoundedCornerShape(20.dp))
                .then(modifier),
            contentAlignment = Alignment.Center
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                if (icon != null) {
                    Icon(
                        imageVector = icon,
                        contentDescription = null,
                        modifier = Modifier.size(16.dp),
                        tint = MaterialTheme.colorScheme.onPrimary
                    )
                }
                if (label != null) {
                    if (icon != null) Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = label,
                        color = MaterialTheme.colorScheme.onPrimary,
                        style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold, fontSize = 11.sp),
                        maxLines = 1
                    )
                }
            }
        }
    }

    @Composable
    fun ActionButton(iconName: String, onClick: () -> Unit) {
        val icon = when (iconName) {
            "play" -> androidx.compose.material.icons.Icons.Rounded.PlayArrow
            "stop" -> androidx.compose.material.icons.Icons.Rounded.Stop
            "x" -> androidx.compose.material.icons.Icons.Rounded.Close
            "cloud" -> androidx.compose.material.icons.Icons.Rounded.Cloud
            else -> androidx.compose.material.icons.Icons.Rounded.PlayArrow
        }
        androidx.compose.foundation.layout.Box(
            modifier = Modifier
                .size(44.dp)
                .clip(RoundedCornerShape(16.dp))
                .background(MaterialTheme.colorScheme.primary)
                .clickable(onClick = onClick),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                modifier = Modifier.size(24.dp),
                tint = MaterialTheme.colorScheme.onPrimary
            )
        }
    }
}
