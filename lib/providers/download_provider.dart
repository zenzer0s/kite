import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../services/download_service.dart';
import 'database_provider.dart';

enum DownloadStatus { idle, fetching, downloading, done, error }

class DownloadState {
  final DownloadStatus status;
  final VideoInfo? info;
  final double progress;
  final String? errorMessage;
  final String? currentLine;
  final String? activeTaskId;

  const DownloadState({
    this.status = DownloadStatus.idle,
    this.info,
    this.progress = 0,
    this.errorMessage,
    this.currentLine,
    this.activeTaskId,
  });

  DownloadState copyWith({
    DownloadStatus? status,
    VideoInfo? info,
    double? progress,
    String? errorMessage,
    String? currentLine,
    String? activeTaskId,
  }) =>
      DownloadState(
        status: status ?? this.status,
        info: info ?? this.info,
        progress: progress ?? this.progress,
        errorMessage: errorMessage ?? this.errorMessage,
        currentLine: currentLine ?? this.currentLine,
        activeTaskId: activeTaskId ?? this.activeTaskId,
      );
}

class DownloadNotifier extends Notifier<DownloadState> {
  StreamSubscription? _progressSub;

  @override
  DownloadState build() {
    ref.onDispose(() => _progressSub?.cancel());
    _listenProgress();
    return const DownloadState();
  }

  void _listenProgress() {
    _progressSub = DownloadService.progressStream.listen((p) {
      if (state.activeTaskId != p.taskId) return;
      if (p.error != null) {
        state = state.copyWith(status: DownloadStatus.error, errorMessage: p.error);
      } else if (p.done) {
        state = state.copyWith(status: DownloadStatus.done, progress: 100);
      } else {
        state = state.copyWith(
          status: DownloadStatus.downloading,
          progress: p.progress,
          currentLine: p.line,
        );
      }
    });
  }

  Future<void> fetchInfo(String url) async {
    state = state.copyWith(status: DownloadStatus.fetching, errorMessage: null);
    try {
      final info = await DownloadService.fetchInfo(url);
      state = state.copyWith(status: DownloadStatus.idle, info: info);
    } catch (e) {
      state = state.copyWith(status: DownloadStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> startDownload({required bool audioOnly}) async {
    final info = state.info;
    if (info == null) return;
    state = state.copyWith(status: DownloadStatus.downloading, progress: 0);
    try {
      final taskId = await DownloadService.startDownload(url: info.url, audioOnly: audioOnly);
      state = state.copyWith(activeTaskId: taskId);
    } catch (e) {
      state = state.copyWith(status: DownloadStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> cancelDownload() async {
    final taskId = state.activeTaskId;
    if (taskId == null) return;
    await DownloadService.cancelDownload(taskId);
    state = const DownloadState();
  }

  void reset() => state = const DownloadState();

  Future<void> saveToHistory(String filePath) async {
    final info = state.info;
    if (info == null) return;
    final db = ref.read(databaseProvider);
    await db.insertDownload(DownloadedItemsCompanion(
      title: Value(info.title),
      uploader: Value(info.uploader),
      url: Value(info.url),
      thumbnail: Value(info.thumbnail),
      filePath: Value(filePath),
      ext: Value(info.ext),
      duration: Value(info.duration),
      downloadedAt: Value(DateTime.now()),
    ));
  }
}

final downloadProvider = NotifierProvider<DownloadNotifier, DownloadState>(DownloadNotifier.new);
