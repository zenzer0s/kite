package com.zenzer0s.kite

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.util.Log
import com.yausername.youtubedl_android.YoutubeDL
import com.yausername.youtubedl_android.YoutubeDLRequest
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.io.File
import java.io.FileInputStream
import java.net.HttpURLConnection
import java.net.URL

/**
 * Centered logic for Kite's native "Heavy Lifting" engine.
 * Flutter should call this through MethodChannels.
 * This class ensures that core logic (downloads, history, metadata, cloud uploads) 
 * is shared between MainActivity (Flutter UI) and ShareActivity (Native UI).
 */
object KiteNative {

    private const val PREFS_NAME = "FlutterSharedPreferences"

    /**
     * Pre-warms the Python environment by running a small command.
     * This avoids the delay on the first real fetchInfo/startDownload call.
     */
    suspend fun warmup() {
        withContext(Dispatchers.IO) {
            try {
                KiteApp.awaitNativeToolsReady().getOrThrow()
                // Running a no-op command to spin up the Python interpreter
                YoutubeDL.getInstance().execute(YoutubeDLRequest("").apply {
                    addOption("--version")
                })
                Log.d("KiteNative", "Python pre-warm complete")
            } catch (e: Exception) {
                Log.w("KiteNative", "Python pre-warm skipped or failed: ${e.message}")
            }
        }
    }

    /**
     * Unified logic for fetching media information via yt-dlp.
     */
    suspend fun fetchInfo(url: String): Map<String, Any?> {
        val normalized = normalizeUrl(url)
        return withContext(Dispatchers.IO) {
            KiteApp.awaitNativeToolsReady().getOrThrow()
            val request = YoutubeDLRequest(normalized).apply {
                addOption("--dump-single-json")
                addOption("--no-playlist")
                addOption("-R", "1")
                addOption("--socket-timeout", "10")
            }
            val response = YoutubeDL.getInstance().execute(request)
            parseVideoInfo(response.out)
        }
    }

    /**
     * Standardizes URLs for YouTube and others.
     */
    fun normalizeUrl(url: String): String {
        val trimmed = url.trim()
        val low = trimmed.lowercase(java.util.Locale.ROOT)
        
        // Handle youtu.be links
        if (low.contains("youtu.be/")) {
            val videoId = trimmed.substringAfterLast("/")
                .substringBefore("?")
            if (videoId.isNotEmpty()) {
                val params = trimmed.substringAfter("?", "")
                    .split("&")
                    .filter { !it.startsWith("si=") && it.isNotBlank() }
                
                val builder = StringBuilder("https://www.youtube.com/watch?v=$videoId")
                params.forEach { builder.append("&$it") }
                return builder.toString()
            }
        }
        
        // Handle youtube.com links (clean tracking params)
        if (low.contains("youtube.com/")) {
            if (trimmed.contains("si=")) {
                return trimmed.replace(Regex("&?si=[^&]*"), "")
                    .replace("?&", "?")
                    .trimEnd('?', '&')
            }
        }
        
        return trimmed
    }

    /**
     * Parse raw yt-dlp JSON into a standardized Map for Flutter/Compose.
     */
    private fun parseVideoInfo(jsonStr: String): Map<String, Any?> {
        val json = JSONObject(jsonStr)
        val formatsArray = json.optJSONArray("formats")
        val formatsList = mutableListOf<Map<String, Any?>>()
        
        if (formatsArray != null) {
            for (i in 0 until formatsArray.length()) {
                val f = formatsArray.getJSONObject(i)
                formatsList.add(mapOf(
                    "format_id" to f.optString("format_id"),
                    "format_note" to f.optString("format_note").takeIf { it.isNotEmpty() },
                    "ext" to f.optString("ext").takeIf { it.isNotEmpty() },
                    "vcodec" to f.optString("vcodec").takeIf { it.isNotEmpty() },
                    "acodec" to f.optString("acodec").takeIf { it.isNotEmpty() },
                    "width" to if (!f.isNull("width")) f.optDouble("width") else null,
                    "height" to if (!f.isNull("height")) f.optDouble("height") else null,
                    "resolution" to f.optString("resolution").takeIf { it.isNotEmpty() },
                    "vbr" to if (!f.isNull("vbr")) f.optDouble("vbr") else null,
                    "abr" to if (!f.isNull("abr")) f.optDouble("abr") else null,
                    "filesize" to if (!f.isNull("filesize")) f.optLong("filesize").toDouble() else null,
                    "filesize_approx" to if (!f.isNull("filesize_approx")) f.optLong("filesize_approx").toDouble() else null,
                ))
            }
        }
        
        return mapOf(
            "id" to json.optString("id"),
            "title" to json.optString("title", "Unknown Title"),
            "uploader" to json.optString("uploader", "Unknown"),
            "thumbnail" to json.optString("thumbnail", ""),
            "duration" to if (json.has("duration") && !json.isNull("duration")) json.optInt("duration") else null,
            "webpage_url" to json.optString("webpage_url"),
            "ext" to json.optString("ext"),
            "formats" to formatsList,
        )
    }

    /**
     * Standardized way to save a completed download to the Kite history database.
     */
    fun saveToHistory(context: Context, info: DownloadMetadata) {
        try {
            val dbFile = File(context.filesDir, "../app_flutter/kite.sqlite").canonicalFile
            if (!dbFile.exists()) {
                Log.w("KiteNative", "Database file not found: $dbFile")
                return
            }
            
            val db = SQLiteDatabase.openDatabase(dbFile.absolutePath, null, SQLiteDatabase.OPEN_READWRITE)
            val cv = android.content.ContentValues().apply {
                put("title", info.title)
                put("uploader", info.uploader)
                put("url", info.url)
                put("thumbnail", info.thumbnail)
                put("file_path", info.filePath)
                put("ext", info.ext)
                put("duration", info.duration)
                put("downloaded_at", System.currentTimeMillis() / 1000L)
            }
            
            val id = db.insert("downloaded_items", null, cv)
            db.close()
            Log.d("KiteNative", "Saved to history: $id - ${info.title}")
        } catch (e: Exception) {
            Log.e("KiteNative", "Failed to save history", e)
        }
    }

    /**
     * Background uploader for Telegram.
     */
    suspend fun uploadToTelegram(context: Context, filePath: String, ext: String): Boolean {
        return withContext(Dispatchers.IO) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val enabled = prefs.getBoolean("flutter.telegram_upload", false)
            val token = prefs.getString("flutter.telegram_bot_token", "") ?: ""
            val chatId = prefs.getString("flutter.telegram_chat_id", "") ?: ""

            if (!enabled || token.isBlank() || chatId.isBlank()) {
                Log.d("KiteNative", "Telegram upload skipped: enabled=$enabled")
                return@withContext false
            }

            val file = File(filePath)
            if (!file.exists()) {
                Log.e("KiteNative", "Telegram upload failed: not found at $filePath")
                return@withContext false
            }

            if (file.length() > 50 * 1024 * 1024) {
                Log.w("KiteNative", "Telegram upload skipped: >50MB limit")
                return@withContext false
            }

            try {
                val endpoint = when (ext.lowercase()) {
                    "mp4", "mov" -> "sendVideo"
                    "mp3", "m4a", "opus", "flac", "wav", "ogg" -> "sendAudio"
                    else -> "sendDocument"
                }
                val fieldName = when (ext.lowercase()) {
                    "mp4", "mov" -> "video"
                    "mp3", "m4a", "opus", "flac", "wav", "ogg" -> "audio"
                    else -> "document"
                }

                val boundary = "Boundary-${System.currentTimeMillis()}"
                val url = URL("https://api.telegram.org/bot$token/$endpoint")
                val conn = (url.openConnection() as HttpURLConnection).apply {
                    doOutput = true
                    requestMethod = "POST"
                    connectTimeout = 30000
                    readTimeout = 300000
                    setRequestProperty("Content-Type", "multipart/form-data; boundary=$boundary")
                }

                conn.outputStream.use { out ->
                    out.write("--$boundary\r\n".toByteArray())
                    out.write("Content-Disposition: form-data; name=\"chat_id\"\r\n\r\n".toByteArray())
                    out.write("$chatId\r\n".toByteArray())

                    out.write("--$boundary\r\n".toByteArray())
                    out.write("Content-Disposition: form-data; name=\"$fieldName\"; filename=\"${file.name}\"\r\n".toByteArray())
                    out.write("Content-Type: application/octet-stream\r\n\r\n".toByteArray())
                    
                    FileInputStream(file).use { it.copyTo(out) }
                    out.write("\r\n".toByteArray())
                    out.write("--$boundary--\r\n".toByteArray())
                }

                val success = conn.responseCode == 200
                if (success) {
                    Log.d("KiteNative", "Telegram upload success: ${file.name}")
                } else {
                    Log.e("KiteNative", "Telegram failed: ${conn.responseCode}")
                }
                conn.disconnect()
                success
            } catch (e: Exception) {
                Log.e("KiteNative", "Telegram error: ${e.message}")
                false
            }
        }
    }

    /**
     * Tests a Telegram bot token and chat ID.
     */
    suspend fun testTelegramConnection(token: String, chatId: String): Result<String> {
        return withContext(Dispatchers.IO) {
            try {
                // 1. GetMe
                val getMeUrl = URL("https://api.telegram.org/bot$token/getMe")
                val getMeConn = (getMeUrl.openConnection() as HttpURLConnection).apply {
                    connectTimeout = 10000
                    readTimeout = 10000
                }
                if (getMeConn.responseCode != 200) {
                    return@withContext Result.failure(Exception("Invalid Bot Token"))
                }
                getMeConn.disconnect()

                // 2. SendMessage
                val sendUrl = URL("https://api.telegram.org/bot$token/sendMessage")
                val sendConn = (sendUrl.openConnection() as HttpURLConnection).apply {
                    doOutput = true
                    requestMethod = "POST"
                    connectTimeout = 10000
                    readTimeout = 10000
                    setRequestProperty("Content-Type", "application/x-www-form-urlencoded")
                }
                val body = "chat_id=$chatId&text=✅ Kite Connection Test Successful!"
                sendConn.outputStream.use { it.write(body.toByteArray()) }

                if (sendConn.responseCode == 200) {
                    Result.success("Success")
                } else {
                    val err = sendConn.errorStream?.bufferedReader()?.use { it.readText() }
                    Result.failure(Exception("Chat ID Error: $err"))
                }
            } catch (e: Exception) {
                Result.failure(e)
            }
        }
    }

    /**
     * Deletes a download from history AND the physical file on disk.
     */
    fun deleteHistoryItem(context: Context, id: Int) {
        try {
            val dbFile = File(context.filesDir, "../app_flutter/kite.sqlite").canonicalFile
            if (!dbFile.exists()) return
            val db = SQLiteDatabase.openDatabase(dbFile.absolutePath, null, SQLiteDatabase.OPEN_READWRITE)
            
            // 1. Get file path
            val cursor = db.query("downloaded_items", arrayOf("file_path"), "id = ?", arrayOf(id.toString()), null, null, null)
            var filePath: String? = null
            if (cursor.moveToFirst()) {
                filePath = cursor.getString(0)
            }
            cursor.close()

            // 2. Delete file
            if (filePath != null) {
                val file = File(filePath)
                if (file.exists()) {
                    val deleted = file.delete()
                    Log.d("KiteNative", "Deleted file: $filePath status=$deleted")
                }
            }

            // 3. Delete DB record
            db.delete("downloaded_items", "id = ?", arrayOf(id.toString()))
            db.close()
            Log.d("KiteNative", "Deleted DB record: $id")
        } catch (e: Exception) {
            Log.e("KiteNative", "Failed to delete history item", e)
        }
    }

    /**
     * Standardized filename sanitizer tool.
     */
    fun getSafeFilePath(outputDir: String, title: String, ext: String): String {
        val safe = title.replace(Regex("[\\\\/:*?\"<>|]"), "_")
        return "$outputDir/$safe.$ext"
    }

    /**
     * Guesses MIME type based on extension for more reliable file opening.
     */
    fun getMimeType(filePath: String): String {
        val ext = filePath.substringAfterLast(".", "").lowercase(java.util.Locale.ROOT)
        return when (ext) {
            "mp4", "mkv", "webm", "mov", "avi", "3gp", "flv" -> "video/*"
            "mp3", "m4a", "opus", "flac", "wav", "ogg", "aac" -> "audio/*"
            "pdf" -> "application/pdf"
            "txt" -> "text/plain"
            "jpg", "jpeg", "png", "webp", "gif" -> "image/*"
            else -> "application/octet-stream"
        }
    }

    data class DownloadMetadata(
        val title: String,
        val uploader: String,
        val url: String,
        val thumbnail: String,
        val filePath: String,
        val ext: String,
        val duration: Int
    )
}
