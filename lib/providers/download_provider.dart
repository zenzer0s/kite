import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../services/download_service.dart';
import 'database_provider.dart';

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

  Future<void> fetchInfo(String url) async {
    state = state.copyWith(status: DownloadStatus.fetching, errorMessage: null);
    try {
      final info = await DownloadService.fetchInfo(url);
      state = state.copyWith(status: DownloadStatus.idle, info: info);
    } catch (e) {
      state = state.copyWith(
        status: DownloadStatus.error,
        errorMessage: e.toString(),
      );
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
      final task = state[p.taskId];
      if (task == null) return;
      if (p.error != null) {
        _update(
          p.taskId,
          task.copyWith(status: DownloadStatus.error, errorMessage: p.error),
        );
      } else if (p.done) {
        if (_savedTaskIds.add(p.taskId)) {
          await _saveToHistory(task);
        }
        _update(
          p.taskId,
          task.copyWith(status: DownloadStatus.done, progress: 100),
        );
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
        targetExt: audioOnly ? 'mp3' : info.ext,
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

  Future<void> _saveToHistory(DownloadTask task) async {
    final db = ref.read(databaseProvider);
    final safeTitle = task.info.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final ext = task.targetExt ?? task.info.ext;
    final filePath = '${task.outputDir}/$safeTitle.$ext';
    await db.insertDownload(
      DownloadedItemsCompanion(
        title: Value(task.info.title),
        uploader: Value(task.info.uploader),
        url: Value(task.info.url),
        thumbnail: Value(task.info.thumbnail),
        filePath: Value(filePath),
        ext: Value(ext),
        duration: Value(task.info.duration),
        downloadedAt: Value(DateTime.now()),
      ),
    );
  }
}

final downloadsProvider =
    NotifierProvider<DownloadsNotifier, Map<String, DownloadTask>>(
      DownloadsNotifier.new,
    );
