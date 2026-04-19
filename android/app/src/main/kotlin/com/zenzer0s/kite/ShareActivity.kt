@file:OptIn(
    androidx.compose.material3.ExperimentalMaterial3Api::class,
    androidx.compose.material3.ExperimentalMaterial3ExpressiveApi::class
)

package com.zenzer0s.kite

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.Environment
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Videocam
import androidx.compose.material.icons.rounded.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.googlefonts.Font
import androidx.compose.ui.text.googlefonts.GoogleFont
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.yausername.youtubedl_android.YoutubeDL
import com.yausername.youtubedl_android.YoutubeDLRequest
import com.zenzer0s.kite.ui.theme.KiteTheme
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

// ── Chakra Petch via Google Fonts ─────────────────────────────────────────────
// Requires: implementation("androidx.compose.ui:ui-text-google-fonts:<version>")
// And res/values/font_certs.xml with GMS certificates array.
private val fontProvider = GoogleFont.Provider(
    providerAuthority = "com.google.android.gms.fonts",
    providerPackage   = "com.google.android.gms",
    certificates      = R.array.com_google_android_gms_fonts_certs
)
private val chakraPetchGF = GoogleFont("Chakra Petch")
val ChakraPetch = FontFamily(
    Font(googleFont = chakraPetchGF, fontProvider = fontProvider, weight = FontWeight.Normal),
    Font(googleFont = chakraPetchGF, fontProvider = fontProvider, weight = FontWeight.Medium),
    Font(googleFont = chakraPetchGF, fontProvider = fontProvider, weight = FontWeight.SemiBold),
    Font(googleFont = chakraPetchGF, fontProvider = fontProvider, weight = FontWeight.Bold),
)

// ── Data models ───────────────────────────────────────────────────────────────
data class MediaFormat(
    val formatId: String,
    val ext: String,
    val resolution: String,
    val filesize: Long,
    val formatNote: String,
    val isAudioOnly: Boolean,
    val bitrate: Double = 0.0,
    val abr: Double = 0.0,
    val height: Int = 0
)

data class MediaInfo(
    val url: String,
    val title: String,
    val uploader: String,
    val duration: Int,
    val thumbnail: String,
    val videoFormats: List<MediaFormat>,
    val audioFormats: List<MediaFormat>
)

// ── Activity ──────────────────────────────────────────────────────────────────
class ShareActivity : ComponentActivity() {
    private var currentUrl = androidx.compose.runtime.mutableStateOf<String?>(null)

    private fun extractUrlFromIntent(intent: android.content.Intent?): String? {
        if (intent == null) return null
        val action = intent.action
        return when {
            android.content.Intent.ACTION_SEND == action && "text/plain" == intent.type ->
                intent.getStringExtra(android.content.Intent.EXTRA_TEXT) ?: intent.dataString
            android.content.Intent.ACTION_VIEW == action -> intent.dataString
            else -> intent.getStringExtra(android.content.Intent.EXTRA_TEXT) ?: intent.dataString
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val url = extractUrlFromIntent(intent)
        if (url.isNullOrBlank()) {
            android.widget.Toast.makeText(this, "No valid URL found", android.widget.Toast.LENGTH_SHORT).show()
            finish()
            return
        }
        currentUrl.value = url

        val prefs = getSharedPreferences("FlutterSharedPreferences", android.content.Context.MODE_PRIVATE)
        val defaultFormat = prefs.getString("flutter.settings_default_format", "auto")
        var outputDir = prefs.getString("flutter.settings_download_dir", "")
        if (outputDir.isNullOrBlank()) {
            outputDir = java.io.File(
                android.os.Environment.getExternalStoragePublicDirectory(android.os.Environment.DIRECTORY_DOWNLOADS),
                "Kite"
            ).absolutePath
        }

        if (defaultFormat == "auto") {
            android.widget.Toast.makeText(this, "Kite: Downloading...", android.widget.Toast.LENGTH_SHORT).show()
            DownloadService.startDownload(
                applicationContext, "T-${System.currentTimeMillis()}-${(100..999).random()}",
                url, false, null, null, outputDir!!
            )
            finish()
            return
        }

        setContent {
            KiteTheme {
                currentUrl.value?.let { 
                    ShareBottomSheet(it, outputDir!!)
                }
            }
        }
    }

    override fun onNewIntent(intent: android.content.Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val url = extractUrlFromIntent(intent)
        if (url != null) {
            currentUrl.value = url
        }
    }

    // ── Bottom sheet host ─────────────────────────────────────────────────────
    @Composable
    fun ShareBottomSheet(url: String, outputDir: String) {
        val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
        var mediaInfo    by remember { mutableStateOf<MediaInfo?>(null) }
        var errorMessage by remember { mutableStateOf<String?>(null) }

        LaunchedEffect(url) {
            try {
                mediaInfo = withContext(Dispatchers.IO) {
                    val info = KiteNative.fetchInfo(url)
                    val formats = info["formats"] as? List<Map<String, Any?>> ?: emptyList()

                    val videoList = mutableListOf<MediaFormat>()
                    val audioList = mutableListOf<MediaFormat>()

                    for (fmt in formats) {
                        val vcodec = fmt["vcodec"] as? String ?: "none"
                        val acodec = fmt["acodec"] as? String ?: "none"
                        if (vcodec == "none" && acodec == "none") continue

                        val mf = MediaFormat(
                            formatId    = fmt["format_id"] as? String ?: "",
                            ext         = fmt["ext"] as? String ?: "",
                            resolution  = fmt["resolution"] as? String ?: "",
                            filesize    = (fmt["filesize"] as? Double)?.toLong() ?: 0L,
                            formatNote  = fmt["format_note"] as? String ?: "",
                            isAudioOnly = vcodec == "none" && acodec != "none",
                            bitrate     = fmt["vbr"] as? Double ?: 0.0,
                            abr         = fmt["abr"] as? Double ?: 0.0,
                            height      = (fmt["height"] as? Double)?.toInt() ?: 0
                        )
                        if (mf.isAudioOnly) audioList.add(mf) else videoList.add(mf)
                    }

                    // Deduplicate and mirror Flutter logic
                    val seenH = mutableSetOf<Int>()
                    val dedupVideo = videoList
                        .filter { it.height > 0 }
                        .sortedByDescending { it.height }
                        .filter { seenH.add(it.height) }

                    val bestAudio = audioList
                        .sortedByDescending { it.abr }
                        .take(1)

                    MediaInfo(
                        url          = url,
                        title        = info["title"] as? String ?: "Unknown Video",
                        uploader     = info["uploader"] as? String ?: "Unknown",
                        duration     = info["duration"] as? Int ?: 0,
                        thumbnail    = info["thumbnail"] as? String ?: "",
                        videoFormats = dedupVideo,
                        audioFormats = bestAudio
                    )
                }
            } catch (e: Exception) {
                errorMessage = e.message
            }
        }

        ModalBottomSheet(
            onDismissRequest = { finish() },
            sheetState       = sheetState,
            containerColor   = MaterialTheme.colorScheme.surfaceContainerLow,
            scrimColor       = Color.Black.copy(alpha = 0.5f),
            shape            = RoundedCornerShape(topStart = 28.dp, topEnd = 28.dp),
            // Custom drag handle: 32×4dp pill, outline 40% alpha — matches Flutter
            dragHandle = {
                Box(
                    modifier = Modifier
                        .padding(top = 16.dp, bottom = 20.dp)
                        .size(width = 32.dp, height = 4.dp)
                        .clip(RoundedCornerShape(2.dp))
                        .background(MaterialTheme.colorScheme.outline.copy(alpha = 0.4f))
                )
            }
        ) {
            when {
                errorMessage != null -> ErrorState(errorMessage!!)
                mediaInfo    == null -> LoadingState()
                else                 -> MediaContent(mediaInfo!!, outputDir)
            }
        }
    }

    // ── States ────────────────────────────────────────────────────────────────

    @Composable
    fun LoadingState() {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(160.dp),
            contentAlignment = Alignment.Center
        ) {
            ContainedLoadingIndicator()
        }
    }

    @Composable
    fun ErrorState(message: String) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .padding(32.dp),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text       = "Error: $message",
                fontFamily = ChakraPetch,
                color      = MaterialTheme.colorScheme.error
            )
        }
    }

    // ── Main scrollable content ───────────────────────────────────────────────
    @Composable
    fun MediaContent(info: MediaInfo, outputDir: String) {
        val clipboard = LocalClipboardManager.current
        val uriHandler = LocalUriHandler.current
        val context    = LocalContext.current

        LazyColumn(
            modifier       = Modifier.fillMaxWidth(),
            // Matches Flutter: fromLTRB(20, 0, 20, 40)
            contentPadding = PaddingValues(start = 20.dp, end = 20.dp, bottom = 40.dp)
        ) {

            // ── MEDIA INFO ───────────────────────────────────────────────────
            item {
                FormatGroupCard(title = "MEDIA INFO") {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp),
                        horizontalArrangement = Arrangement.spacedBy(16.dp),
                        verticalAlignment     = Alignment.Top
                    ) {
                        // Thumbnail + duration overlay badge
                        Box(
                            modifier = Modifier
                                .size(width = 110.dp, height = 72.dp)
                                .clip(RoundedCornerShape(12.dp))
                        ) {
                            AsyncImage(
                                model              = info.thumbnail,
                                contentDescription = "Thumbnail",
                                modifier           = Modifier.matchParentSize(),
                                contentScale       = ContentScale.Crop
                            )
                            if (info.duration > 0) {
                                Box(
                                    modifier = Modifier
                                        .align(Alignment.BottomEnd)
                                        .padding(5.dp)
                                        .clip(RoundedCornerShape(4.dp))
                                        .background(Color.Black.copy(alpha = 0.7f))
                                        .padding(horizontal = 6.dp, vertical = 2.dp)
                                ) {
                                    Text(
                                        text          = formatDuration(info.duration),
                                        fontFamily    = ChakraPetch,
                                        fontSize      = 10.sp,
                                        fontWeight    = FontWeight.Bold,
                                        color         = Color.White,
                                        letterSpacing = 0.5.sp
                                    )
                                }
                            }
                        }

                        // Title + uploader
                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text       = info.title,
                                maxLines   = 2,
                                overflow   = TextOverflow.Ellipsis,
                                fontFamily = ChakraPetch,
                                fontSize   = 14.sp,
                                fontWeight = FontWeight.SemiBold,
                                lineHeight = 18.sp,
                                color      = MaterialTheme.colorScheme.onSurface
                            )
                            Spacer(Modifier.height(6.dp))
                            Text(
                                text       = info.uploader,
                                maxLines   = 1,
                                overflow   = TextOverflow.Ellipsis,
                                fontFamily = ChakraPetch,
                                fontSize   = 12.sp,
                                color      = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }
                Spacer(Modifier.height(24.dp))
            }

            // ── Copy / Open / Thumb ──────────────────────────────────────────
            item {
                Row(
                    modifier              = Modifier.fillMaxWidth().height(48.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    QuickActionButton(
                        modifier = Modifier.weight(1f),
                        icon     = Icons.Rounded.ContentCopy,
                        label    = "Copy",
                        onClick  = {
                            clipboard.setText(AnnotatedString(info.url))
                            Toast.makeText(context, "URL copied", Toast.LENGTH_SHORT).show()
                        }
                    )
                    QuickActionButton(
                        modifier = Modifier.weight(1f),
                        icon     = Icons.Rounded.OpenInNew,
                        label    = "Open",
                        onClick  = { uriHandler.openUri(info.url) }
                    )
                    if (info.thumbnail.isNotEmpty()) {
                        QuickActionButton(
                            modifier = Modifier.weight(1f),
                            icon     = Icons.Rounded.Image,
                            label    = "Thumb",
                            onClick  = { uriHandler.openUri(info.thumbnail) }
                        )
                    }
                }
                Spacer(Modifier.height(24.dp))
            }

            // ── VIDEO OPTIONS ────────────────────────────────────────────────
            if (info.videoFormats.isNotEmpty()) {
                item {
                    FormatGroupCard(title = "VIDEO OPTIONS") {
                        info.videoFormats.take(5).forEachIndexed { index, fmt ->
                            if (index > 0) {
                                HorizontalDivider(
                                    modifier  = Modifier.padding(start = 52.dp),
                                    thickness = 0.5.dp,
                                    color     = MaterialTheme.colorScheme.outlineVariant
                                )
                            }
                            // First item gets highlighted primaryContainer, rest are muted
                            val isFirst  = index == 0
                            FormatItem(
                                icon     = if (isFirst) Icons.Rounded.Videocam else Icons.Outlined.Videocam,
                                iconBg   = if (isFirst) MaterialTheme.colorScheme.primaryContainer
                                           else MaterialTheme.colorScheme.surfaceContainerHighest,
                                iconTint = if (isFirst) MaterialTheme.colorScheme.onPrimaryContainer
                                           else MaterialTheme.colorScheme.onSurface,
                                title    = qualityLabel(fmt),
                                subtitle = videoSubtitle(fmt),
                                onClick  = { startDownload(info.url, fmt.formatId, false, outputDir) }
                            )
                        }
                    }
                    Spacer(Modifier.height(24.dp))
                }
            }

            // ── AUDIO ONLY ───────────────────────────────────────────────────
            if (info.audioFormats.isNotEmpty()) {
                item {
                    FormatGroupCard(title = "AUDIO ONLY") {
                        info.audioFormats.forEach { fmt ->
                            FormatItem(
                                icon     = Icons.Rounded.MusicNote,
                                iconBg   = MaterialTheme.colorScheme.tertiaryContainer,
                                iconTint = MaterialTheme.colorScheme.tertiary,
                                title    = fmt.formatNote.ifEmpty { "Best Audio" },
                                subtitle = audioSubtitle(fmt),
                                onClick  = { startDownload(info.url, fmt.formatId, true, outputDir) }
                            )
                        }
                    }
                }
            }
        }
    }

    // ── Reusable composables ──────────────────────────────────────────────────

    /**
     * Section label + bordered surface card.
     * Mirrors Flutter's _FormatGroup widget exactly.
     */
    @Composable
    fun FormatGroupCard(title: String, content: @Composable ColumnScope.() -> Unit) {
        Column {
            Text(
                text          = title,
                modifier      = Modifier.padding(start = 4.dp, bottom = 10.dp),
                fontFamily    = ChakraPetch,
                fontSize      = 10.sp,
                fontWeight    = FontWeight.Bold,
                letterSpacing = 2.5.sp,
                color         = MaterialTheme.colorScheme.primary
            )
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape    = RoundedCornerShape(16.dp),
                color    = MaterialTheme.colorScheme.surface,
                border   = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant)
            ) {
                Column(content = content)
            }
        }
    }

    /**
     * Single tappable format row with icon, title, subtitle and download arrow.
     * Mirrors Flutter's _FormatItem widget exactly.
     */
    @Composable
    fun FormatItem(
        icon: ImageVector,
        iconBg: Color,
        iconTint: Color,
        title: String,
        subtitle: String,
        onClick: () -> Unit
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clickable(onClick = onClick)
                .padding(horizontal = 16.dp, vertical = 14.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // 36×36 icon box, rounded 10dp — matches Flutter exactly
            Box(
                modifier = Modifier
                    .size(36.dp)
                    .clip(RoundedCornerShape(10.dp))
                    .background(iconBg),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector        = icon,
                    contentDescription = null,
                    tint               = iconTint,
                    modifier           = Modifier.size(18.dp)
                )
            }
            Spacer(Modifier.width(14.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text       = title,
                    fontFamily = ChakraPetch,
                    fontSize   = 13.sp,
                    fontWeight = FontWeight.SemiBold,
                    color      = MaterialTheme.colorScheme.onSurface
                )
                Text(
                    text       = subtitle,
                    fontFamily = ChakraPetch,
                    fontSize   = 11.sp,
                    color      = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            Icon(
                imageVector        = Icons.Rounded.Download,
                contentDescription = "Download",
                tint               = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier           = Modifier.size(18.dp)
            )
        }
    }

    /** Copy / Open / Thumb pill button. */
    @Composable
    fun QuickActionButton(
        modifier: Modifier,
        icon: ImageVector,
        label: String,
        onClick: () -> Unit
    ) {
        OutlinedButton(
            onClick        = onClick,
            modifier       = modifier.fillMaxHeight(),
            shape          = RoundedCornerShape(12.dp),
            border         = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant),
            colors         = ButtonDefaults.outlinedButtonColors(
                containerColor = MaterialTheme.colorScheme.surface,
                contentColor   = MaterialTheme.colorScheme.onSurface
            ),
            contentPadding = PaddingValues(horizontal = 8.dp)
        ) {
            Icon(icon, contentDescription = null, modifier = Modifier.size(18.dp))
            Spacer(Modifier.width(6.dp))
            Text(
                text       = label,
                fontFamily = ChakraPetch,
                fontSize   = 12.sp,
                fontWeight = FontWeight.SemiBold
            )
        }
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private fun startDownload(url: String, formatId: String, audioOnly: Boolean, outputDir: String) {
        val taskId = "T-${System.currentTimeMillis()}-${(100..999).random()}"
        DownloadService.startDownload(
            applicationContext,
            taskId,
            url, audioOnly, formatId, null, outputDir!!
        )
        Toast.makeText(this, "Kite: 📡 Starting download...", Toast.LENGTH_SHORT).show()
        finish()
    }

    private fun formatDuration(seconds: Int): String {
        val h = seconds / 3600
        val m = (seconds % 3600) / 60
        val s = seconds % 60
        return if (h > 0) String.format("%d:%02d:%02d", h, m, s)
        else String.format("%02d:%02d", m, s)
    }
}

// ── Top-level helpers (mirror Flutter's _DataState methods) ──────────────────

private fun effectiveHeight(fmt: MediaFormat): Int {
    if (fmt.height > 0) return fmt.height
    Regex("""x(\d+)$""").find(fmt.resolution)?.groupValues?.get(1)?.toIntOrNull()?.let { return it }
    Regex("""^(\d+)p""").find(fmt.resolution)?.groupValues?.get(1)?.toIntOrNull()?.let { return it }
    return 0
}

fun qualityLabel(fmt: MediaFormat): String = when (val h = effectiveHeight(fmt)) {
    in 2160..Int.MAX_VALUE -> "4K Ultra HD"
    in 1440..2159          -> "1440p QHD"
    in 1080..1439          -> "1080p Full HD"
    in 720..1079           -> "720p HD"
    in 480..719            -> "480p SD"
    in 360..479            -> "360p"
    else -> if (h > 0) "${h}p" else fmt.formatNote.ifEmpty { fmt.resolution.ifEmpty { "Video" } }
}

fun videoSubtitle(fmt: MediaFormat): String {
    val parts = mutableListOf<String>()
    if (fmt.ext.isNotEmpty())  parts += fmt.ext.uppercase()
    if (fmt.bitrate > 0)       parts += "${fmt.bitrate.toInt()}kbps"
    if (fmt.filesize > 0)      parts += formatFileSize(fmt.filesize)
    return parts.joinToString(" · ").ifEmpty { fmt.formatNote.ifEmpty { "Video" } }
}

fun audioSubtitle(fmt: MediaFormat): String {
    val parts = mutableListOf<String>()
    if (fmt.ext.isNotEmpty())  parts += fmt.ext.uppercase()
    if (fmt.abr > 0)           parts += "${fmt.abr.toInt()}kbps"
    if (fmt.filesize > 0)      parts += formatFileSize(fmt.filesize)
    return parts.joinToString(" · ").ifEmpty { fmt.formatNote.ifEmpty { "Audio" } }
}

fun formatFileSize(bytes: Long): String = when {
    bytes <= 0                   -> ""
    bytes < 1024 * 1024          -> String.format("%.1f KB", bytes / 1024.0)
    bytes < 1024L * 1024 * 1024  -> String.format("%.1f MB", bytes / (1024.0 * 1024))
    else                         -> String.format("%.1f GB", bytes / (1024.0 * 1024 * 1024))
}