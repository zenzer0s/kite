import 'package:flutter/material.dart';
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
    final isPaused = task.status == DownloadStatus.paused;
    final isCancelled = task.status == DownloadStatus.cancelled;
    final isActive = task.status == DownloadStatus.downloading;

    return Container(
      height: 150,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Thumbnail
          Positioned.fill(
            child: task.info.thumbnail.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: task.info.thumbnail,
                    fit: BoxFit.cover,
                    memCacheHeight: 300, // Optimized for 150 height card
                    placeholder: (context, url) => _Placeholder(cs: cs),
                    errorWidget: (context, url, error) => _Placeholder(cs: cs),
                  )
                : _Placeholder(cs: cs),
          ),

          // Dark Overlay Gradient
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Left Icon
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        task.targetExt == 'mp3'
                            ? PhosphorIcons.musicNote(PhosphorIconsStyle.fill)
                            : PhosphorIcons.videoCamera(PhosphorIconsStyle.fill),
                        size: 14,
                        color: Colors.white,
                      ),
                    ),

                    // "BEST QUALITY" Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        'BEST QUALITY',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.9),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.info.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                            Text(
                            '${task.info.uploader} \u2022 ${_formatDuration(task.info.duration)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Progress Info
                          Text(
                            _buildProgressString(task),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Action Button (X)
                    GestureDetector(
                      onTap: isDone
                          ? () {
                              if (task.filePath != null) {
                                DownloadService.openFile(task.filePath!);
                              }
                            }
                          : (isCancelled || isError)
                              ? onDismiss
                              : onCancel,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Icon(
                          isDone
                              ? PhosphorIcons.play(PhosphorIconsStyle.fill)
                              : PhosphorIcons.x(PhosphorIconsStyle.bold),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bottom Progress Bar
          if (isActive || isPaused)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: LinearProgressIndicator(
                value: task.progress / 100,
                minHeight: 3,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isPaused ? Colors.white38 : cs.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return 'Unknown';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _buildProgressString(DownloadTask task) {
    if (task.status == DownloadStatus.error) {
      return 'Error: ${task.errorMessage ?? 'Unknown'}';
    }
    if (task.status == DownloadStatus.cancelled) {
      return 'Cancelled';
    }
    if (task.status == DownloadStatus.done) {
      return 'Download Complete';
    }
    if (task.status == DownloadStatus.queued) {
      return 'In Queue...';
    }

    final prefix = task.status == DownloadStatus.paused ? '[paused]' : '[download]';
    final current = task.currentLine ?? '';
    if (current.contains('%')) {
      // Try to keep it clean like in the screenshot
      return '$prefix ${task.progress.toStringAsFixed(1)}% \u2022 ${current.split('%').last.trim()}';
    }
    return '$prefix ${task.progress.toStringAsFixed(1)}%';
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
