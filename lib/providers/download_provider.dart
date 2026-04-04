import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/download_service.dart';
import '../services/telegram_service.dart';
import 'settings_provider.dart';

enum DownloadStatus { idle, fetching, downloading, paused, done, error }

class DownloadState {
  final DownloadStatus status;
  final VideoInfo? info;
  final double progress;
  final String? errorMessage;
  final String? currentLine;
  final String? activeTaskId;
  final String? outputDir;
  final String? targetExt;

  const DownloadState({
    this.status = DownloadStatus.idle,
    this.info,
    this.progress = 0,
    this.errorMessage,
    this.currentLine,
    this.activeTaskId,
    this.outputDir,
    this.targetExt,
  });

  DownloadState copyWith({
    DownloadStatus? status,
    VideoInfo? info,
    double? progress,
    String? errorMessage,
    String? currentLine,
    String? activeTaskId,
    String? outputDir,
    String? targetExt,
  }) => DownloadState(
    status: status ?? this.status,
    info: info ?? this.info,
    progress: progress ?? this.progress,
    errorMessage: errorMessage ?? this.errorMessage,
    currentLine: currentLine ?? this.currentLine,
    activeTaskId: activeTaskId ?? this.activeTaskId,
    outputDir: outputDir ?? this.outputDir,
    targetExt: targetExt ?? this.targetExt,
  );
}

class DownloadNotifier extends Notifier<DownloadState> {
  @override
  DownloadState build() => const DownloadState();

  Future<VideoInfo?> fetchInfo(String url) async {
    try {
      state = state.copyWith(status: DownloadStatus.fetching, info: null);
      final info = await DownloadService.fetchInfo(url);
      state = state.copyWith(status: DownloadStatus.idle, info: info);
      return info;
    } catch (e) {
      state = state.copyWith(
        status: DownloadStatus.error,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  void reset() => state = const DownloadState();
}

final downloadProvider = NotifierProvider<DownloadNotifier, DownloadState>(
  DownloadNotifier.new,
);

class DownloadTask {
  final String taskId;
  final VideoInfo info;
  final DownloadStatus status;
  final double progress;
  final String? currentLine;
  final String? errorMessage;
  final String? targetExt;
  final String outputDir;

  const DownloadTask({
    required this.taskId,
    required this.info,
    this.status = DownloadStatus.downloading,
    this.progress = 0,
    this.currentLine,
    this.errorMessage,
    this.targetExt,
    this.outputDir = '/storage/emulated/0/Download/Kite',
  });

  DownloadTask copyWith({
    DownloadStatus? status,
    double? progress,
    String? currentLine,
    String? errorMessage,
  }) => DownloadTask(
    taskId: taskId,
    info: info,
    status: status ?? this.status,
    progress: progress ?? this.progress,
    currentLine: currentLine ?? this.currentLine,
    errorMessage: errorMessage ?? this.errorMessage,
    targetExt: targetExt,
    outputDir: outputDir,
  );
}

class DownloadsNotifier extends Notifier<Map<String, DownloadTask>> {
  StreamSubscription? _progressSub;
  final Set<String> _savedTaskIds = <String>{};

  @override
  Map<String, DownloadTask> build() {
    ref.onDispose(() => _progressSub?.cancel());
    _listenProgress();
    return const {};
  }

  void _listenProgress() {
    _progressSub = DownloadService.progressStream.listen((p) async {
      var task = state[p.taskId];
      if (task == null) {
        // If we don't know about this task (e.g. started via Share sheet), create it!
        if (p.title != null) {
          task = DownloadTask(
            taskId: p.taskId,
            info: VideoInfo(
              id: '', // Not mission critical
              title: p.title!,
              uploader: p.uploader ?? 'Unknown',
              thumbnail: p.thumbnail ?? '',
              duration: p.duration ?? 0,
              url: p.url ?? '',
              ext: p.ext ?? 'mp4',
            ),
            targetExt: p.ext ?? 'mp4',
            status: DownloadStatus.downloading,
            progress: p.progress,
            currentLine: p.line,
          );
          _update(p.taskId, task);
        } else {
          return; // Still don't have enough metadata
        }
      }
      if (p.error != null) {
        debugPrint('Kite: Download error from native: ${p.error}');
        _update(
          p.taskId,
          task.copyWith(status: DownloadStatus.error, errorMessage: p.error),
        );
      } else if (p.done) {
        debugPrint('Kite: Download done native! Saving to history and Telegram: ${p.taskId}');
        if (_savedTaskIds.add(p.taskId)) {
          debugPrint('Kite: Native already saved to history. Triggering Telegram...');
          await _maybeUploadToTelegram(task);
          debugPrint('Kite: Telegram finished.');
        }
        
        // Only set status to done if it wasn't already set to error by the Telegram uploader
        final currentTask = state[p.taskId];
        if (currentTask != null && currentTask.status != DownloadStatus.error) {
          _update(
            p.taskId,
            currentTask.copyWith(status: DownloadStatus.done, progress: 100),
          );
        }
      } else {
        _update(
          p.taskId,
          task.copyWith(
            status: DownloadStatus.downloading,
            progress: p.progress,
            currentLine: p.line,
          ),
        );
      }
    });
  }

  void _update(String taskId, DownloadTask task) {
    state = {...state, taskId: task};
  }

  Future<void> startDownload({
    required VideoInfo info,
    required bool audioOnly,
    String? formatId,
  }) async {
    try {
      final taskId = await DownloadService.startDownload(
        url: info.url,
        audioOnly: audioOnly,
        formatId: formatId,
      );
      final task = DownloadTask(
        taskId: taskId,
        info: info,
        status: DownloadStatus.downloading,
        targetExt: audioOnly ? 'mp3' : 'mp4',
      );
      state = {...state, taskId: task};
    } catch (e) {
      final errorTaskId = 'error_${DateTime.now().millisecondsSinceEpoch}';
      state = {
        ...state,
        errorTaskId: DownloadTask(
          taskId: errorTaskId,
          info: info,
          status: DownloadStatus.error,
          errorMessage: e.toString(),
        ),
      };
    }
  }

  Future<void> cancelTask(String taskId) async {
    _savedTaskIds.remove(taskId);
    await DownloadService.cancelDownload(taskId);
    final updated = Map<String, DownloadTask>.from(state);
    updated.remove(taskId);
    state = updated;
  }

  Future<void> pauseTask(String taskId) async {
    final task = state[taskId];
    if (task == null) return;
    await DownloadService.pauseDownload(taskId);
    _update(taskId, task.copyWith(status: DownloadStatus.paused));
  }

  Future<void> resumeTask(String taskId) async {
    final task = state[taskId];
    if (task == null) return;
    await DownloadService.resumeDownload(taskId);
    _update(taskId, task.copyWith(status: DownloadStatus.downloading));
  }

  void dismissTask(String taskId) {
    final updated = Map<String, DownloadTask>.from(state);
    updated.remove(taskId);
    state = updated;
  }


  Future<void> _maybeUploadToTelegram(DownloadTask task) async {
    debugPrint('Kite: _maybeUploadToTelegram checking settings...');
    final settings = ref.read(settingsProvider);
    if (!settings.telegramUpload || !settings.telegramFullyConfigured) {
      debugPrint('Kite: Telegram not configured. Skipping upload.');
      return;
    }

    final safeTitle = task.info.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final ext = task.targetExt ?? task.info.ext;
    String filePath = '${task.outputDir}/$safeTitle.$ext';
    debugPrint('Kite: Telegram targeting filePath: $filePath');

    // Fallback search if the predicted path is not exact
    if (!File(filePath).existsSync()) {
      debugPrint('Kite: Predicted path missing, searching in dir: ${task.outputDir}');
      try {
        final dir = Directory(task.outputDir);
        final files = dir.listSync().whereType<File>().toList()
          ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
        for (var f in files) {
          if (f.path.contains(safeTitle)) {
            filePath = f.path;
            break;
          }
        }
      } catch (_) {}
    }

    final result = await TelegramService.uploadFile(
        filePath: filePath,
        token: settings.telegramBotToken,
        chatId: settings.telegramChatId,
    );

    if (!result.isSuccess) {
      final currentTask = state[task.taskId];
      if (currentTask != null) {
        _update(
          task.taskId,
          currentTask.copyWith(
            status: DownloadStatus.error,
            errorMessage: 'Telegram Upload: ${result.error}',
          ),
        );
      }
    }
  }
}

final downloadsProvider =
    NotifierProvider<DownloadsNotifier, Map<String, DownloadTask>>(
      DownloadsNotifier.new,
    );
