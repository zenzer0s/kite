import 'package:flutter/services.dart';

class VideoInfo {
  final String id;
  final String title;
  final String uploader;
  final String thumbnail;
  final int duration;
  final String url;
  final String ext;

  const VideoInfo({
    required this.id,
    required this.title,
    required this.uploader,
    required this.thumbnail,
    required this.duration,
    required this.url,
    required this.ext,
  });

  factory VideoInfo.fromMap(Map map) => VideoInfo(
    id: map['id'] ?? '',
    title: map['title'] ?? 'Unknown Title',
    uploader: map['uploader'] ?? 'Unknown',
    thumbnail: map['thumbnail'] ?? '',
    duration: (map['duration'] as num?)?.toInt() ?? 0,
    url: map['webpage_url'] ?? '',
    ext: map['ext'] ?? 'mp4',
  );
}

class DownloadProgress {
  final String taskId;
  final double progress;
  final String line;
  final bool done;
  final String? error;

  const DownloadProgress({
    required this.taskId,
    required this.progress,
    this.line = '',
    this.done = false,
    this.error,
  });

  factory DownloadProgress.fromMap(Map map) => DownloadProgress(
    taskId: map['taskId'] ?? '',
    progress: (map['progress'] as num?)?.toDouble() ?? 0,
    line: map['line'] ?? '',
    done: map['done'] == true,
    error: map['error'] as String?,
  );
}

class DownloadService {
  static const _method = MethodChannel('com.zenzer0s.kite/downloader');
  static const _event = EventChannel('com.zenzer0s.kite/progress');

  static String normalizeUrl(String url) {
    final trimmed = url.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null) {
      return trimmed;
    }

    final host = uri.host.toLowerCase();
    if (host == 'youtu.be') {
      final videoId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
      if (videoId.isEmpty) {
        return trimmed;
      }
      final query = Map<String, String>.from(uri.queryParameters)..remove('si');
      query['v'] = videoId;
      return Uri(
        scheme: uri.scheme.isEmpty ? 'https' : uri.scheme,
        host: 'www.youtube.com',
        path: '/watch',
        queryParameters: query,
      ).toString();
    }

    if (host == 'youtube.com' ||
        host == 'www.youtube.com' ||
        host == 'm.youtube.com') {
      final query = Map<String, String>.from(uri.queryParameters);
      if (query.remove('si') != null) {
        return uri
            .replace(queryParameters: query.isEmpty ? null : query)
            .toString();
      }
    }

    return trimmed;
  }

  static Stream<DownloadProgress> get progressStream => _event
      .receiveBroadcastStream()
      .map((e) => DownloadProgress.fromMap(e as Map));

  static Future<VideoInfo> fetchInfo(String url) async {
    final result = await _method.invokeMapMethod<String, dynamic>('fetchInfo', {
      'url': normalizeUrl(url),
    });
    return VideoInfo.fromMap(result!);
  }

  static Future<String> startDownload({
    required String url,
    required bool audioOnly,
    String? outputDir,
  }) async {
    final taskId = await _method.invokeMethod<String>('startDownload', {
      'url': url,
      'audioOnly': audioOnly,
      'outputDir': ?outputDir,
    });
    return taskId!;
  }

  static Future<void> cancelDownload(String taskId) async {
    await _method.invokeMethod('cancelDownload', {'taskId': taskId});
  }

  static Future<String> updateYtDlp() async {
    final status = await _method.invokeMethod<String>('updateYtDlp');
    return status ?? 'ALREADY_UP_TO_DATE';
  }

  static Future<String> getYtDlpVersion() async {
    final version = await _method.invokeMethod<String>('getYtDlpVersion');
    return version ?? 'Unknown';
  }
}
