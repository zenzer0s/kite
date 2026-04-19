import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../providers/download_provider.dart';
import '../services/download_service.dart';

class QueueTaskCard extends StatelessWidget {
  final DownloadTask task;
  final VoidCallback onCancel;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onDismiss;

  const QueueTaskCard({
    super.key,
    required this.task,
    required this.onCancel,
    this.onPause,
    this.onResume,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDone = task.status == DownloadStatus.done;
    final isError = task.status == DownloadStatus.error;
    final isCancelled = task.status == DownloadStatus.cancelled;
    final isQueued = task.status == DownloadStatus.queued;

    // Extract speed from currentLine if available
    final speed = _extractSpeed(task.currentLine);

    return Container(
      height: 180, // Reduced height for a more compact feel
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(
          28,
        ), // Slightly less rounded for better fit
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Thumbnail with Overlay
          Positioned.fill(
            child: task.info.thumbnail.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: task.info.thumbnail,
                    fit: BoxFit.cover,
                    memCacheHeight: 360,
                    placeholder: (context, url) => _Placeholder(cs: cs),
                    errorWidget: (context, url, error) => _Placeholder(cs: cs),
                  )
                : _Placeholder(cs: cs),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),
          ),

          // Main Layout
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Logo and Quality
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Media Logo
                    _ActionButton(
                      icon: task.targetExt == 'mp3'
                          ? PhosphorIcons.musicNote(PhosphorIconsStyle.fill)
                          : PhosphorIcons.videoCamera(PhosphorIconsStyle.fill),
                      cs: cs,
                    ),

                    // Quality Badge
                    _ActionButton(
                      icon: task.targetExt == 'mp3'
                          ? PhosphorIcons.speakerHigh(PhosphorIconsStyle.fill)
                          : PhosphorIcons.monitor(PhosphorIconsStyle.fill),
                      label: _getQualityLabel(task),
                      cs: cs,
                    ),
                  ],
                ),

                const Spacer(),

                // Main Controls: Title and Play on the same line
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.info.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.2,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            task.info.uploader,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w500,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Builder(
                      builder: (context) {
                        final fileExists =
                            task.filePath != null &&
                            File(task.filePath!).existsSync();
                        final isCleaned = !fileExists && task.nativeUploaded;

                        return _ActionButton(
                          icon: isDone
                              ? (isCleaned
                                    ? PhosphorIcons.cloudArrowUp(
                                        PhosphorIconsStyle.fill,
                                      )
                                    : PhosphorIcons.play(
                                        PhosphorIconsStyle.fill,
                                      ))
                              : (isCancelled || isError || isQueued)
                              ? PhosphorIcons.x(PhosphorIconsStyle.bold)
                              : PhosphorIcons.stop(PhosphorIconsStyle.fill),
                          onTap: isDone
                              ? () {
                                  if (isCleaned) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            Icon(
                                              PhosphorIcons.telegramLogo(
                                                PhosphorIconsStyle.fill,
                                              ),
                                              color: cs.primary,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Available on Telegram',
                                              style: GoogleFonts.outfit(
                                                color: cs.onSurface,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        backgroundColor:
                                            cs.surfaceContainerHighest,
                                        behavior: SnackBarBehavior.floating,
                                        width: 240, // Compact width
                                        elevation: 8,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  } else if (task.filePath != null) {
                                    DownloadService.openFile(task.filePath!);
                                  }
                                }
                              : (isCancelled || isError || isQueued)
                              ? onDismiss
                              : onCancel,
                          cs: cs,
                          isMain: true,
                        );
                      },
                    ),
                  ],
                ),

                const Spacer(),

                // Footer: Progress Percentage, Bar, and Speed
                Row(
                  children: [
                    Text(
                      '${task.progress.toInt()}%',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ExpressiveWavyProgress(
                        taskId: task.taskId,
                        progress: (task.status == DownloadStatus.downloading || task.status == DownloadStatus.paused)
                            ? task.progress / 100.0
                            : (task.status == DownloadStatus.fetching || task.status == DownloadStatus.queued ? null : 0.0),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      speed,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getQualityLabel(DownloadTask task) {
    if (task.status == DownloadStatus.error) return 'Failed';
    return task.quality ??
        (task.targetExt == 'mp3' ? 'Best Audio' : 'Best Video');
  }

  String _extractSpeed(String? currentLine) {
    if (currentLine == null) return '0 KB/s';
    final match = RegExp(r'(\d+\.?\d*)\s*([KM]i?B/s)').firstMatch(currentLine);
    if (match != null) return '${match.group(1)} ${match.group(2)}';
    return '0 KB/s';
  }
}

class _ExpressiveWavyProgress extends StatefulWidget {
  final String taskId;
  final double? progress;

  const _ExpressiveWavyProgress({required this.taskId, this.progress});

  @override
  State<_ExpressiveWavyProgress> createState() => _ExpressiveWavyProgressState();
}

class _ExpressiveWavyProgressState extends State<_ExpressiveWavyProgress> {
  MethodChannel? _channel;

  @override
  void didUpdateWidget(_ExpressiveWavyProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _channel?.invokeMethod('updateProgress', widget.progress);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      child: AndroidView(
        key: ValueKey('wavy_${widget.taskId}'),
        viewType: 'com.zenzer0s.kite/expressive_element',
        creationParams: {
          'type': 'wavy_progress',
          'progress': widget.progress,
        },
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: (id) {
          _channel = MethodChannel('com.zenzer0s.kite/expressive_$id');
        },
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData? icon;
  final String? label;
  final VoidCallback? onTap;
  final ColorScheme cs;
  final bool isMain;

  const _ActionButton({
    this.icon,
    this.label,
    this.onTap,
    required this.cs,
    this.isMain = false,
  });

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).platform != TargetPlatform.android) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: label != null ? const EdgeInsets.symmetric(horizontal: 10, vertical: 4) : null,
          width: label != null ? null : (isMain ? 56 : 44),
          height: isMain ? 56 : (label != null ? 28 : 44),
          decoration: BoxDecoration(
            color: isMain ? cs.primaryContainer.withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) Icon(
                icon,
                color: isMain ? cs.onPrimaryContainer : Colors.white,
                size: isMain ? 28 : 22,
              ),
              if (label != null) ...[
                if (icon != null) const SizedBox(width: 6),
                Text(
                  label!,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    String? iconName;
    if (icon != null) {
      if (icon == PhosphorIcons.play(PhosphorIconsStyle.fill)) iconName = 'play';
      else if (icon == PhosphorIcons.stop(PhosphorIconsStyle.fill)) iconName = 'stop';
      else if (icon == PhosphorIcons.x(PhosphorIconsStyle.bold)) iconName = 'x';
      else if (icon == PhosphorIcons.cloudArrowUp(PhosphorIconsStyle.fill)) iconName = 'cloud';
      else if (icon == PhosphorIcons.musicNote(PhosphorIconsStyle.fill)) iconName = 'music';
      else if (icon == PhosphorIcons.videoCamera(PhosphorIconsStyle.fill)) iconName = 'video';
    }

    return SizedBox(
      width: isMain ? 52 : (label != null ? 90 : 40),
      height: isMain ? 40 : (label != null ? 32 : 32),
      child: AndroidView(
        viewType: 'com.zenzer0s.kite/expressive_element',
        creationParams: {
          'type': 'square_button',
          'iconName': iconName,
          'label': label,
        },
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: (id) {
          final channel = MethodChannel('com.zenzer0s.kite/expressive_$id');
          channel.setMethodCallHandler((call) async {
            if (call.method == 'onAction' && call.arguments == 'click') {
              onTap?.call();
            }
          });
        },
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final ColorScheme cs;
  const _Placeholder({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: cs.surfaceContainerHighest,
      child: Center(
        child: Icon(
          PhosphorIcons.image(PhosphorIconsStyle.thin),
          size: 48,
          color: cs.outline.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
