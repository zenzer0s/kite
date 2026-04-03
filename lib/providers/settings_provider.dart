import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DefaultFormat { auto, custom }

class AppSettings {
  final String downloadDir;
  final DefaultFormat defaultFormat;
  final int concurrentDownloads;

  // Telegram settings
  final String telegramBotToken;
  final String telegramChatId;
  final bool telegramUpload;
  final bool fastMode;

  const AppSettings({
    required this.downloadDir,
    required this.defaultFormat,
    required this.concurrentDownloads,
    this.telegramBotToken = '',
    this.telegramChatId = '',
    this.telegramUpload = false,
    this.fastMode = false,
  });

  AppSettings copyWith({
    String? downloadDir,
    DefaultFormat? defaultFormat,
    int? concurrentDownloads,
    String? telegramBotToken,
    String? telegramChatId,
    bool? telegramUpload,
    bool? fastMode,
  }) {
    return AppSettings(
      downloadDir: downloadDir ?? this.downloadDir,
      defaultFormat: defaultFormat ?? this.defaultFormat,
      concurrentDownloads: concurrentDownloads ?? this.concurrentDownloads,
      telegramBotToken: telegramBotToken ?? this.telegramBotToken,
      telegramChatId: telegramChatId ?? this.telegramChatId,
      telegramUpload: telegramUpload ?? this.telegramUpload,
      fastMode: fastMode ?? this.fastMode,
    );
  }

  bool get telegramFullyConfigured =>
      telegramBotToken.isNotEmpty && telegramChatId.isNotEmpty;
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

class SettingsNotifier extends Notifier<AppSettings> {
  static const _dirKey = 'settings_download_dir';
  static const _formatKey = 'settings_default_format';
  static const _concurrentKey = 'settings_concurrent_downloads';
  static const _telegramTokenKey = 'telegram_bot_token';
  static const _telegramChatIdKey = 'telegram_chat_id';
  static const _telegramUploadKey = 'telegram_upload';
  static const _fastModeKey = 'fast_mode';

  static const String defaultDir = '/storage/emulated/0/Download/Kite';

  @override
  AppSettings build() {
    Future<void>.microtask(_load);
    return const AppSettings(
      downloadDir: defaultDir,
      defaultFormat: DefaultFormat.auto,
      concurrentDownloads: 3,
    );
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load and parse default format safely
      DefaultFormat format;
      final formatStr = prefs.getString(_formatKey);
      if (formatStr == 'custom') {
        format = DefaultFormat.custom;
      } else if (formatStr == 'auto') {
        format = DefaultFormat.auto;
      } else {
        // Fallback for legacy int storage
        final legacyInt = prefs.getInt(_formatKey);
        format = legacyInt == 1 ? DefaultFormat.custom : DefaultFormat.auto;
      }

      state = AppSettings(
        downloadDir: prefs.getString(_dirKey) ?? defaultDir,
        defaultFormat: format,
        concurrentDownloads: prefs.getInt(_concurrentKey) ?? 3,
        telegramBotToken: prefs.getString(_telegramTokenKey) ?? '',
        telegramChatId: prefs.getString(_telegramChatIdKey) ?? '',
        telegramUpload: prefs.getBool(_telegramUploadKey) ?? false,
        fastMode: prefs.getBool(_fastModeKey) ?? false,
      );
    } catch (e) {
      // Silently fail or use defaults if error
    }
  }

  Future<void> setDownloadDir(String dir) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _dirKey,
      dir.trim().isEmpty ? defaultDir : dir.trim(),
    );
    state = state.copyWith(
      downloadDir: dir.trim().isEmpty ? defaultDir : dir.trim(),
    );
  }

  Future<void> setDefaultFormat(DefaultFormat format) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_formatKey, format.name); // Using name (auto/custom) for better stability
    state = state.copyWith(defaultFormat: format);
  }

  Future<void> setConcurrentDownloads(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_concurrentKey, count);
    state = state.copyWith(concurrentDownloads: count);
  }

  Future<void> setTelegramBotToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_telegramTokenKey, token.trim());
    state = state.copyWith(telegramBotToken: token.trim());
    // Disable upload if token cleared
    if (token.trim().isEmpty && state.telegramUpload) {
      await setTelegramUpload(false);
    }
  }

  Future<void> setTelegramChatId(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_telegramChatIdKey, chatId.trim());
    state = state.copyWith(telegramChatId: chatId.trim());
    // Disable upload if chat ID cleared
    if (chatId.trim().isEmpty && state.telegramUpload) {
      await setTelegramUpload(false);
    }
  }

  Future<void> setTelegramUpload(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_telegramUploadKey, enabled);
    state = state.copyWith(telegramUpload: enabled);
  }

  Future<void> setFastMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_fastModeKey, enabled);
    state = state.copyWith(fastMode: enabled);
  }
}
