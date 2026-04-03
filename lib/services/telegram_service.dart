import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

const String _baseUrl = 'https://api.telegram.org';
const int _maxBotApiSizeBytes = 50 * 1024 * 1024; // 50 MB

class TelegramService {
  static String _guessMimeType(String ext) {
    switch (ext.toLowerCase()) {
      case 'mp4':
      case 'mkv':
      case 'webm':
      case 'mov':
      case 'avi':
        return 'video/mp4';
      case 'mp3':
        return 'audio/mpeg';
      case 'm4a':
        return 'audio/mp4';
      case 'opus':
        return 'audio/ogg';
      case 'flac':
        return 'audio/flac';
      case 'wav':
        return 'audio/wav';
      case 'ogg':
        return 'audio/ogg';
      default:
        return 'application/octet-stream';
    }
  }

  static String _guessEndpoint(String ext) {
    switch (ext.toLowerCase()) {
      case 'mp4':
      case 'mov':
        return 'sendVideo';
      case 'mp3':
      case 'm4a':
      case 'opus':
      case 'flac':
      case 'wav':
      case 'ogg':
        return 'sendAudio';
      default:
        return 'sendDocument';
    }
  }

  static String _guessFieldName(String ext) {
    switch (ext.toLowerCase()) {
      case 'mp4':
      case 'mov':
        return 'video';
      case 'mp3':
      case 'm4a':
      case 'opus':
      case 'flac':
      case 'wav':
      case 'ogg':
        return 'audio';
      default:
        return 'document';
    }
  }

  /// Uploads a downloaded file to Telegram.
  static Future<TelegramResult> uploadFile({
    required String filePath,
    required String token,
    required String chatId,
  }) async {
    if (token.isEmpty || chatId.isEmpty) {
      return TelegramResult.failure(
        'Telegram is not configured. Please set your bot token and chat ID in Settings → Telegram.',
      );
    }

    final file = File(filePath);
    if (!file.existsSync()) {
      return TelegramResult.failure('File not found: $filePath');
    }

    final size = file.lengthSync();
    if (size > _maxBotApiSizeBytes) {
      return TelegramResult.failure(
        'File exceeds the 50 MB Telegram Bot API limit and cannot be uploaded.',
      );
    }

    final ext = filePath.contains('.') ? filePath.split('.').last : '';
    final endpoint = _guessEndpoint(ext);
    final fieldName = _guessFieldName(ext);
    final mimeType = _guessMimeType(ext);
    final fileName = filePath.split('/').last;

    try {
      final uri = Uri.parse('$_baseUrl/bot$token/$endpoint');
      final request = http.MultipartRequest('POST', uri)
        ..fields['chat_id'] = chatId
        ..files.add(await http.MultipartFile.fromPath(
          fieldName,
          filePath,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        ));

      final streamedResponse = await request.send().timeout(const Duration(minutes: 5));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return const TelegramResult.success();
      } else {
        return TelegramResult.failure(
          'Telegram API error ${response.statusCode}: ${response.body}',
        );
      }
    } on SocketException catch (e) {
      return TelegramResult.failure('Network error: ${e.message}');
    } catch (e) {
      return TelegramResult.failure('Upload failed: $e');
    }
  }

  /// Tests the connection by calling getMe and sending a test message.
  static Future<TelegramResult> testConnection({
    required String token,
    required String chatId,
  }) async {
    try {
      // Step 1: validate bot token
      final getMeUri = Uri.parse('$_baseUrl/bot$token/getMe');
      final getMeResp = await http.get(getMeUri).timeout(const Duration(seconds: 15));
      if (getMeResp.statusCode != 200) {
        return TelegramResult.failure(
          'Invalid bot token. Double-check your token from @BotFather.',
        );
      }

      // Step 2: send a test message to the chat
      final msgUri = Uri.parse('$_baseUrl/bot$token/sendMessage');
      final msgResp = await http.post(
        msgUri,
        body: {
          'chat_id': chatId,
          'text':
              '✅ Kite is connected! Completed downloads will be automatically uploaded to this chat.',
        },
      ).timeout(const Duration(seconds: 15));

      if (msgResp.statusCode == 200) {
        return const TelegramResult.success();
      } else {
        return TelegramResult.failure(
          'Invalid chat ID or bot not in chat. Response: ${msgResp.body}',
        );
      }
    } on SocketException catch (e) {
      return TelegramResult.failure('Network error: ${e.message}');
    } catch (e) {
      return TelegramResult.failure('Connection test failed: $e');
    }
  }
}

class TelegramResult {
  final bool isSuccess;
  final String? error;

  const TelegramResult.success()
      : isSuccess = true,
        error = null;

  const TelegramResult.failure(this.error) : isSuccess = false;
}
