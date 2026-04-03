import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DefaultFormat { auto, videoOnly, audioOnly }

class AppSettings {
  final String downloadDir;
  final DefaultFormat defaultFormat;
  final int concurrentDownloads;

  const AppSettings({
    required this.downloadDir,
    required this.defaultFormat,
    required this.concurrentDownloads,
  });

  AppSettings copyWith({
    String? downloadDir,
    DefaultFormat? defaultFormat,
    int? concurrentDownloads,
  }) {
    return AppSettings(
      downloadDir: downloadDir ?? this.downloadDir,
      defaultFormat: defaultFormat ?? this.defaultFormat,
      concurrentDownloads: concurrentDownloads ?? this.concurrentDownloads,
    );
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

class SettingsNotifier extends Notifier<AppSettings> {
  static const _dirKey = 'settings_download_dir';
  static const _formatKey = 'settings_default_format';
  static const _concurrentKey = 'settings_concurrent_downloads';

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
    final prefs = await SharedPreferences.getInstance();
    state = AppSettings(
      downloadDir: prefs.getString(_dirKey) ?? defaultDir,
      defaultFormat: DefaultFormat.values[prefs.getInt(_formatKey) ?? 0],
      concurrentDownloads: prefs.getInt(_concurrentKey) ?? 3,
    );
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
    await prefs.setInt(_formatKey, format.index);
    state = state.copyWith(defaultFormat: format);
  }

  Future<void> setConcurrentDownloads(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_concurrentKey, count);
    state = state.copyWith(concurrentDownloads: count);
  }
}
