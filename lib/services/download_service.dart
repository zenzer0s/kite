import 'package:flutter/services.dart';

class VideoFormat {
  final String formatId;
  final String? formatNote;
  final String? ext;
  final String? vcodec;
  final String? acodec;
  final double? width;
  final double? height;
  final String? resolution;
  final double? vbr;
  final double? abr;
  final double? fileSize;
  final double? fileSizeApprox;

  const VideoFormat({
    required this.formatId,
    this.formatNote,
    this.ext,
    this.vcodec,
    this.acodec,
    this.width,
    this.height,
    this.resolution,
    this.vbr,
    this.abr,
    this.fileSize,
    this.fileSizeApprox,
  });

  bool get isAudioOnly => vcodec == null || vcodec == 'none';
  bool get containsAudio => acodec != null && acodec != 'none';

  double get effectiveSize => fileSize ?? fileSizeApprox ?? 0;

  factory VideoFormat.fromMap(Map map) => VideoFormat(
    formatId: map['format_id'] as String? ?? '',
    formatNote: map['format_note'] as String?,
    ext: map['ext'] as String?,
    vcodec: map['vcodec'] as String?,
    acodec: map['acodec'] as String?,
    width: (map['width'] as num?)?.toDouble(),
    height: (map['height'] as num?)?.toDouble(),
    resolution: map['resolution'] as String?,
    vbr: (map['vbr'] as num?)?.toDouble(),
    abr: (map['abr'] as num?)?.toDouble(),
    fileSize: (map['filesize'] as num?)?.toDouble(),
    fileSizeApprox: (map['filesize_approx'] as num?)?.toDouble(),
  );
}

class VideoInfo {
  final String id;
  final String title;
  final String uploader;
  final String thumbnail;
  final int duration;
  final String url;
  final String ext;
  final List<VideoFormat> formats;

  const VideoInfo({
    required this.id,
    required this.title,
    required this.uploader,
    required this.thumbnail,
    required this.duration,
    required this.url,
    required this.ext,
    this.formats = const [],
  });

  factory VideoInfo.fromMap(Map map) => VideoInfo(
    id: map['id'] ?? '',
    title: map['title'] ?? 'Unknown Title',
    uploader: map['uploader'] ?? 'Unknown',
    thumbnail: map['thumbnail'] ?? '',
    duration: (map['duration'] as num?)?.toInt() ?? 0,
    url: map['webpage_url'] ?? '',
    ext: map['ext'] ?? 'mp4',
    formats:
        ((map['formats'] as List?)
            ?.cast<Map>()
            .map(VideoFormat.fromMap)
            .toList()) ??
        [],
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
    String? formatId,
    String? outputDir,
  }) async {
    final taskId = await _method.invokeMethod<String>('startDownload', {
      'url': url,
      'audioOnly': audioOnly,
      'formatId': ?formatId,
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
